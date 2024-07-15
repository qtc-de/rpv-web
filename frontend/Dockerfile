###########################################
###             Build Stage             ###
###########################################
FROM node:lts-alpine AS frontend-builder

WORKDIR /app
COPY package*.json .

RUN adduser --gecos '' --disabled-password rpv       \
 && chown -R rpv:rpv /app                            \
 && su rpv -c "npm install"                          \
 && su rpv -c "npm install http-server"

COPY . .

RUN chown -R rpv:rpv /app                         \
 && su rpv -c "npm run build"


###########################################
###            Deploy Stage             ###
###########################################
FROM nginx:alpine-slim

COPY --from=frontend-builder /app/dist/. /usr/share/nginx/html
