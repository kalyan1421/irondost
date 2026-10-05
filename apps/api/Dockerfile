# Build from the repo root:  docker build -f apps/api/Dockerfile -t laundry-api .
FROM node:24-alpine AS build
RUN corepack enable
WORKDIR /repo
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/api/package.json apps/api/
RUN pnpm install --frozen-lockfile --filter @laundry/api --ignore-scripts
COPY apps/api apps/api
# `prisma generate` reads prisma.config.ts, which requires DATABASE_URL to exist, but it never connects. This placeholder
# lives only in the build stage; the runtime image below does not inherit it, and the real URL comes from the service settings.
ENV DATABASE_URL=postgresql://build:build@localhost:5432/build
RUN pnpm --filter @laundry/api build \
 && pnpm --filter @laundry/api deploy --prod --legacy /out \
 && cp -r apps/api/dist apps/api/prisma apps/api/prisma.config.ts /out/

FROM node:24-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /out .
USER node
EXPOSE 4000
# Apply pending migrations, then start. Prisma takes a lock, so several instances can start at once.
CMD ["sh", "-c", "node_modules/.bin/prisma migrate deploy && node dist/main.js"]
