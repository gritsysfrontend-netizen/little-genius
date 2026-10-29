import { randomUUID } from 'node:crypto';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import type { PrismaClient } from '@prisma/client';
import Fastify, { type FastifyInstance, type FastifyServerOptions } from 'fastify';
import type { AppConfig } from './config.js';
import { errorBody } from './errors.js';
import { registerAdminRoutes } from './modules/admin/routes.js';
import {
  DenyIdentityProvider,
  TestIdentityProvider,
  type IdentityProvider,
} from './modules/admin/identity.js';
import { registerContentRoutes } from './modules/content/routes.js';
import { registerHealthRoutes, type ReadinessCheck } from './modules/health/routes.js';

export type BuildAppOptions = {
  prisma: PrismaClient;
  config: AppConfig;
  ready?: ReadinessCheck;
  identity?: IdentityProvider;
  logger?: FastifyServerOptions['logger'];
};

export async function buildApp(options: BuildAppOptions): Promise<FastifyInstance> {
  const app = Fastify({
    logger: options.logger ?? false,
    genReqId: (request) => {
      const header = request.headers['x-request-id'];
      if (typeof header === 'string' && /^[A-Za-z0-9._-]{1,80}$/.test(header)) {
        return header;
      }
      return randomUUID();
    },
  });

  await app.register(cors, {
    origin: true,
    credentials: false,
    methods: ['GET', 'HEAD', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['authorization', 'content-type', 'x-request-id', 'x-asset-id'],
  });

  await app.register(rateLimit, {
    global: false,
    addHeaders: {
      'x-ratelimit-limit': false,
      'x-ratelimit-remaining': false,
      'x-ratelimit-reset': false,
      'retry-after': true,
    },
    errorResponseBuilder: (_request, context) => {
      const error = new Error('Too many requests.') as Error & { statusCode: number };
      error.statusCode = context.statusCode;
      return error;
    },
  });

  app.addHook('onRequest', async (request, reply) => {
    reply.header('X-Request-Id', request.id);
  });

  app.setErrorHandler((error, request, reply) => {
    const known = error as { message?: string; statusCode?: number };
    request.log.error(
      { err: { message: known.message, statusCode: known.statusCode } },
      'request failed',
    );
    const status = known.statusCode ?? 500;
    if (status === 429) {
      return reply
        .code(429)
        .send(errorBody('RATE_LIMITED', 'Too many requests.', String(request.id), true));
    }
    if (status >= 400 && status < 500) {
      return reply
        .code(status)
        .send(errorBody('VALIDATION_ERROR', 'Request is not valid.', String(request.id), false));
    }
    return reply
      .code(500)
      .send(errorBody('INTERNAL', 'Something went wrong.', String(request.id), true));
  });

  const ready =
    options.ready ??
    (async () => {
      await options.prisma.$queryRaw`SELECT 1`;
    });

  await app.register(
    async (scope) => {
      registerHealthRoutes(scope, ready);
    },
    { prefix: '/api/v1' },
  );

  await app.register(
    async (scope) => {
      registerContentRoutes(scope, options.prisma, options.config);
    },
    { prefix: '/api/v1' },
  );

  const identity =
    options.identity ??
    (options.config.identityProvider === 'test'
      ? new TestIdentityProvider()
      : new DenyIdentityProvider());

  await app.register(
    async (scope) => {
      registerAdminRoutes(scope, options.prisma, options.config, identity);
    },
    { prefix: '/admin/v1' },
  );

  return app;
}
