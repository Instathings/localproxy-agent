FROM node:16-alpine as builder

WORKDIR /build
COPY package.json package.json
COPY tsconfig.json tsconfig.json
COPY src src
RUN yarn install
RUN yarn run build

FROM node:16-alpine
WORKDIR /app
COPY --from=builder /build/package.json package.json
COPY --from=builder /build/build build
RUN yarn install --prod