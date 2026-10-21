FROM openresty/openresty:alpine

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# OpenResty runs as an unprivileged UID; all writable paths are under /tmp.
RUN mkdir -p \
      /tmp/client_body \
      /tmp/proxy_temp \
      /tmp/fastcgi_temp \
      /tmp/uwsgi_temp \
      /tmp/scgi_temp \
    && chown -R 101:101 /tmp/client_body /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp \
    && chmod 755 /usr/local/openresty/nginx/conf/nginx.conf

USER 101:101

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
