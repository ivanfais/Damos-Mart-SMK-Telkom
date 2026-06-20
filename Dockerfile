# Monorepo deploy — builds Backend/damos-mart-backend when Railway root is repo root
FROM node:20-alpine AS builder

WORKDIR /app

COPY Backend/damos-mart-backend/package.json Backend/damos-mart-backend/package-lock.json ./
COPY Backend/damos-mart-backend/prisma ./prisma/

RUN npm ci

COPY Backend/damos-mart-backend/tsconfig.json ./
COPY Backend/damos-mart-backend/src ./src/

RUN npm run build && npx prisma generate

FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY Backend/damos-mart-backend/package.json Backend/damos-mart-backend/package-lock.json ./
COPY Backend/damos-mart-backend/prisma ./prisma/
COPY Backend/damos-mart-backend/docker-entrypoint.sh ./

RUN npm ci --omit=dev && npm install prisma@5.14.0 --no-save

COPY --from=builder /app/dist ./dist
RUN npx prisma generate

RUN chmod +x docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["node", "dist/index.js"]
