FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build

WORKDIR /app/client
COPY client/pubspec.yaml client/pubspec.lock ./
RUN flutter pub get
COPY client .
RUN flutter build web --no-web-resources-cdn --no-wasm-dry-run

FROM node:24-alpine AS api-build

WORKDIR /app
COPY package.json package-lock.json ./
COPY server/package.json server/package.json
RUN npm ci
COPY server server
RUN npm run build:api

FROM node:24-alpine AS runtime

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=4000

COPY package.json package-lock.json ./
COPY server/package.json server/package.json
RUN npm ci --omit=dev
COPY --from=api-build /app/server/dist server/dist
COPY --from=flutter-build /app/client/build/web client/build/web

EXPOSE 4000
CMD ["npm", "start"]
