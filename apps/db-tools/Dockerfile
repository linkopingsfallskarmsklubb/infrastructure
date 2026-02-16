FROM mysql:8.0 as mysql_source

FROM python:3.12-slim-bookworm

WORKDIR /usr/src/scripts

# Copy mysql binaries from official image
COPY --from=mysql_source /usr/bin/mysql /usr/bin/mysql
COPY --from=mysql_source /usr/bin/mysqldump /usr/bin/mysqldump

# Install dependencies for gcloud, postgres, and the mysql binaries
RUN apt-get update && apt-get install -y \
  postgresql-client \
  curl \
  gnupg \
  procps \
  libncurses6 \
  && rm -rf /var/lib/apt/lists/*

# Install google-cloud-cli
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  apt-get update -y && apt-get install google-cloud-cli -y && \
  rm -rf /var/lib/apt/lists/*

COPY scripts/ /usr/src/scripts/

CMD ["/bin/bash"]
