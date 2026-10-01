FROM postgres:18.6-alpine3.24

# 1. Copy the initialization script to the magic folder
COPY ./tools/init.sql /docker-entrypoint-initdb.d/init.sql

# 2. Copy the custom configuration file
COPY ./config/postgresql.conf /etc/postgresql/postgresql.conf

# 3. Security: Change ownership of these files to the default 'postgres' user
RUN chown -R postgres:postgres /docker-entrypoint-initdb.d/ \
    && chown postgres:postgres /etc/postgresql/postgresql.conf \
    && chmod 644 /etc/postgresql/postgresql.conf

# 4. Expose the default port (Documentation & networking)
EXPOSE 5432

# 5. Tell Postgres to boot using your custom configuration file
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
