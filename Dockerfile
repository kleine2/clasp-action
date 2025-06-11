FROM alpine:latest

COPY entrypoint.sh /entrypoint.sh

RUN apk add --update npm curl jq

RUN npm install -g @google/clasp

ENTRYPOINT ["/entrypoint.sh"]
