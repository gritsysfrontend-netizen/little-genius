FROM node:24-bookworm-slim AS build
WORKDIR /app
COPY services/api/package.json services/api/package-lock.json ./
RUN npm ci
COPY services/api/tsconfig.json ./
COPY services/api/src ./src
COPY services/api/prisma ./prisma
RUN npx prisma generate && npm run build && npm prune --omit=dev

FROM node:24-bookworm-slim
RUN apt-get update \
  && apt-get install -y --no-install-recommends openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && useradd --create-home --uid 10001 --shell /usr/sbin/nologin app
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/package.json ./
COPY infrastructure/fixtures /fixtures
COPY packages/content_schema /packages/content_schema
COPY infrastructure/docker/api-entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh && chown -R app:app /app /fixtures /packages/content_schema
USER app
ENV NODE_ENV=production
ENV FIXTURE_DIR=/fixtures
ENV CONTENT_SCHEMA_PATH=/packages/content_schema/lesson-document.schema.json
ENV HOST=0.0.0.0
ENV PORT=3000
EXPOSE 3000
ENTRYPOINT ["/entrypoint.sh"]
