import type { Prisma, PrismaClient } from '@prisma/client';

type PickedJob = {
  job_id: string;
  job_type: string;
  parent_account_id: string;
};

export async function drainOneJob(prisma: PrismaClient): Promise<string | null> {
  const picked = await prisma.$queryRaw<PickedJob[]>`
    WITH picked AS (
      SELECT job_id
      FROM job_outbox
      WHERE status = 'pending' AND available_at <= NOW()
      ORDER BY available_at
      FOR UPDATE SKIP LOCKED
      LIMIT 1
    )
    UPDATE job_outbox AS job
    SET status = 'running', attempts = job.attempts + 1
    FROM picked
    WHERE job.job_id = picked.job_id
    RETURNING job.job_id::text, job.job_type, job.parent_account_id::text
  `;
  const job = picked[0];
  if (!job) return null;
  try {
    const result =
      job.job_type === 'delete_account'
        ? await deleteAccountData(prisma, job.parent_account_id)
        : job.job_type === 'export_account'
          ? await exportAccountData(prisma, job.parent_account_id)
          : { reason: 'unknown job' };
    const failed = job.job_type !== 'delete_account' && job.job_type !== 'export_account';
    await prisma.jobOutbox.update({
      where: { jobId: job.job_id },
      data: {
        status: failed ? 'failed' : 'completed',
        finishedAt: new Date(),
        result: result as Prisma.InputJsonValue,
      },
    });
  } catch {
    await prisma.jobOutbox.update({
      where: { jobId: job.job_id },
      data: {
        status: 'failed',
        finishedAt: new Date(),
        result: { reason: 'failed' },
      },
    });
  }
  return job.job_id;
}

async function deleteAccountData(prisma: PrismaClient, parentAccountId: string) {
  const profiles = await prisma.childProfile.findMany({
    where: { parentAccountId },
    select: { id: true },
  });
  await prisma.$transaction(async (tx) => {
    for (const profile of profiles) {
      await tx.learningEvent.deleteMany({ where: { profileId: profile.id } });
      await tx.progressSummary.deleteMany({ where: { profileId: profile.id } });
      await tx.childProfile.update({
        where: { id: profile.id },
        data: { deletedAt: new Date(), nickname: '' },
      });
    }
  });
  return { profilesCleared: profiles.length };
}

async function exportAccountData(prisma: PrismaClient, parentAccountId: string) {
  const profiles = await prisma.childProfile.findMany({
    where: { parentAccountId, deletedAt: null },
  });
  const profileIds = profiles.map((profile) => profile.id);
  const events =
    profileIds.length === 0
      ? []
      : await prisma.learningEvent.findMany({ where: { profileId: { in: profileIds } } });
  const consentCount = await prisma.consentRecord.count({ where: { parentAccountId } });
  return {
    profileCount: profiles.length,
    profiles: profiles.map((profile) => ({
      profileId: profile.id,
      nickname: profile.nickname,
      avatarId: profile.avatarId,
      ageBand: profile.ageBand,
      preferredLocale: profile.preferredLocale,
      bilingualMode: profile.bilingualMode,
    })),
    events: events.map((event) => ({
      eventId: event.eventId,
      profileId: event.profileId,
      contentId: event.contentId,
      contentVersion: event.contentVersion,
      eventType: event.eventType,
      occurredAt: event.occurredAt.toISOString(),
      ...(event.durationBucket ? { durationBucket: event.durationBucket } : {}),
    })),
    consentCount,
    delivery: 'database-job-row-only',
  };
}
