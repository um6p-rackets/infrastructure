FROM alpine:3.24

# Install RabbitMQ and su-exec
RUN apk add --no-cache rabbitmq-server su-exec

# FIX 1: Create the directory BEFORE enabling the plugin
RUN mkdir -p /var/lib/rabbitmq /var/log/rabbitmq /etc/rabbitmq

# Enable the Management UI
RUN rabbitmq-plugins enable rabbitmq_management

# Copy your script
COPY ./tools/init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 5672 15672

# FIX 2: Point the entrypoint to the actual script name you copied
ENTRYPOINT ["init.sh"]

CMD ["rabbitmq-server"]
