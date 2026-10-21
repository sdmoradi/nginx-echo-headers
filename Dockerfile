FROM openresty/openresty:alpine

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

# Run as a non-root UID. The service listens on an unprivileged port and writes
# its PID and request-body temporary files under /tmp.
RUN mkdir -p /tmp/client_body \
    && chown -R 101:101 /tmp/client_body \
    && chmod 755 /usr/local/openresty/nginx/conf/nginx.conf

USER 101:101

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
