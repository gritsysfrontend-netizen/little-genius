import { PrismaClient } from '@prisma/client';
import { pathToFileURL } from 'node:url';
import { drainOneJob } from './modules/accounts/jobs.js';

async function main(): Promise<void> {
  const prisma = new PrismaClient();
  try {
    const jobId = await drainOneJob(prisma);
    console.log(jobId ? 'drained one job' : 'no job');
  } finally {
    await prisma.$disconnect();
  }
}

const isMain =
  process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isMain) {
  await main();
}
