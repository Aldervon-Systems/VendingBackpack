FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN npm run build
RUN mkdir -p /Deploy/admin-center && cp -R out/* /Deploy/admin-center/

FROM nginx:stable-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /Deploy/admin-center/ /usr/share/nginx/html/
