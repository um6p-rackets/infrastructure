FROM nginx:1.30.5-alpine3.24

RUN apk add --no-cache openssl

COPY ./conf/nginx.conf /etc/nginx/conf.d/default.conf

COPY --chmod=755 ./tools/init.sh /init.sh

ENTRYPOINT ["/init.sh"]