FROM docker.io/mysql:8.4

WORKDIR /usr/src/scripts

RUN microdnf install -y python3.12 tar gzip && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    microdnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    microdnf install -y postgresql17 && \
    microdnf clean all

ENV PATH="/usr/pgsql-17/bin:${PATH}"

RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86.tar.gz && \
  tar -xf google-cloud-cli-linux-x86.tar.gz && \
  ./google-cloud-sdk/install.sh --quiet && \
  ./google-cloud-sdk/bin/gcloud components install gke-gcloud-auth-plugin --quiet
ENV PATH="/usr/src/scripts/google-cloud-sdk/bin:${PATH}"

COPY scripts/ /usr/src/scripts/

ENTRYPOINT ["/bin/sh"]
