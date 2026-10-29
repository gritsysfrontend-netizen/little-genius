import type { FastifyInstance } from 'fastify';
import { sendError } from '../../errors.js';

export type ReadinessCheck = () => Promise<unknown>;

export function registerHealthRoutes(app: FastifyInstance, ready: ReadinessCheck): void {
  app.get('/health', async (_request, reply) => {
    return reply.send({ status: 'ok' });
  });

  app.get('/health/ready', async (_request, reply) => {
    try {
      await ready();
      return reply.send({ status: 'ok' });
    } catch {
      return sendError(reply, 503, 'INTERNAL', 'Database is not ready.', true);
    }
  });
}
