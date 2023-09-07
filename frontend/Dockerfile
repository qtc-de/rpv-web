FROM node:lts-alpine

WORKDIR /app
COPY package*.json .

RUN adduser --gecos '' --disabled-password rpv       \
 && chown -R rpv:rpv /app                            \
 && su rpv -c "npm install"                          \
 && su rpv -c "npm install http-server"

COPY . .

RUN chown -R rpv:rpv /app                         \
 && su rpv -c "npm run build -- --mode offline"

USER rpv:rpv
EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host"]
