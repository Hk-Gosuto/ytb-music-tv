FROM node:22-slim

ENV NODE_ENV=production
WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

COPY src ./src

EXPOSE 4174
EXPOSE 4175/udp
CMD ["node", "src/index.js"]
