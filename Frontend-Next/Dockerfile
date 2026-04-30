FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN npm run build
RUN mkdir -p /Deploy/frontend && cp -R out/* /Deploy/frontend/

FROM nginx:stable-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /Deploy/frontend/ /usr/share/nginx/html/
