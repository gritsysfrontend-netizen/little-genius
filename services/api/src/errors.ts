import type { FastifyReply } from 'fastify';

export const errorCodes = [
  'UNAUTHENTICATED',
  'VALIDATION_ERROR',
  'PROFILE_NOT_FOUND',
  'CONTENT_NOT_FOUND',
  'CONTENT_VERSION_UNAVAILABLE',
  'ASSET_NOT_FOUND',
  'REVISION_CONFLICT',
  'IDEMPOTENCY_KEY_REUSE',
  'PROFILE_ID_CONFLICT',
  'PAYLOAD_TOO_LARGE',
  'RATE_LIMITED',
  'INTERNAL',
] as const;

export type ErrorCode = (typeof errorCodes)[number];

export function errorBody(code: ErrorCode, message: string, requestId: string, retryable: boolean) {
  return {
    error: {
      code,
      message: message.slice(0, 200),
      requestId,
      retryable,
    },
  };
}

export function sendError(
  reply: FastifyReply,
  status: number,
  code: ErrorCode,
  message: string,
  retryable: boolean,
) {
  const requestId = String(reply.request.id);
  return reply.code(status).send(errorBody(code, message, requestId, retryable));
}
