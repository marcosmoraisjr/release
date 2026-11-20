# Espelho de atualização (release.autvs.com): serve por HTTPS os mesmos arquivos das Releases deste repositório.
# O contêiner PUXA do GitHub a cada SYNC_INTERVAL segundos (padrão 300) e guarda em /data (volume persistente).
FROM nginx:alpine

RUN apk add --no-cache curl jq

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY sync.sh entrypoint.sh /usr/local/bin/
RUN sed -i 's/\r$//' /usr/local/bin/sync.sh /usr/local/bin/entrypoint.sh \
 && chmod +x /usr/local/bin/sync.sh /usr/local/bin/entrypoint.sh \
 && mkdir -p /data

ENV REPO=marcosmoraisjr/release \
    DATA=/data \
    SYNC_INTERVAL=300

VOLUME /data
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
  CMD wget -qO- http://127.0.0.1/health >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
