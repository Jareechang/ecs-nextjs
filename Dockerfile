FROM node:alpine AS runner
RUN mkdir -p /opt/app

WORKDIR /opt/app

ENV NODE_ENV production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# You only need to copy next.config.js if you are NOT using the default configuration
#COPY /app/next.config.js ./
COPY ./public /opt/app/public
COPY --chown=nextjs:nodejs ./.next /opt/app/.next
COPY ./node_modules /opt/app/node_modules
COPY ./package.json /opt/app/package.json

USER nextjs

ENV NEXT_TELEMETRY_DISABLED 1

CMD ["yarn", "start"]
