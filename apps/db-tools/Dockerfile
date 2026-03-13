FROM mysql:8.0 as mysql_source

FROM python:3.14-slim-bookworm

WORKDIR /usr/src/scripts

# Copy mysql binaries from official image
COPY --from=mysql_source /usr/bin/mysql /usr/bin/mysql
COPY --from=mysql_source /usr/bin/mysqldump /usr/bin/mysqldump

# Install dependencies and PostgreSQL 17 client from official PG repo
RUN apt-get update && apt-get install -y curl gnupg procps libncurses6 && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && apt-get install -y postgresql-client-17 && \
    rm -rf /var/lib/apt/lists/*

# Install google-cloud-cli
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update -y && apt-get install google-cloud-cli -y && \
    rm -rf /var/lib/apt/lists/*

COPY scripts/ /usr/src/scripts/

CMD ["/bin/bash"]

