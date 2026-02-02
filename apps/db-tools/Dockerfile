FROM docker.io/mysql:8.0

WORKDIR /usr/src/scripts

RUN microdnf install -y python3 postgresql
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86.tar.gz && \
  tar -xf google-cloud-cli-linux-x86.tar.gz && \
  ./google-cloud-sdk/install.sh
ENV PATH="/usr/src/scripts/google-cloud-sdk/bin:${PATH}"

COPY scripts/ /usr/src/scripts/

ENTRYPOINT ["/bin/sh"]
