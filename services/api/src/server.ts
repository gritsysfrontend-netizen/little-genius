import { PrismaClient } from '@prisma/client';
import { buildApp } from './app.js';
import { loadConfig } from './config.js';

const config = loadConfig();
const prisma = new PrismaClient();
const app = await buildApp({
  prisma,
  config,
  logger: {
    level: 'info',
    redact: ['req.headers.authorization', 'req.headers.cookie'],
  },
});

const shutdown = async () => {
  await app.close();
  await prisma.$disconnect();
};

process.on('SIGTERM', () => {
  void shutdown();
});
process.on('SIGINT', () => {
  void shutdown();
});

await app.listen({ host: config.host, port: config.port });
