FROM europe-west1-docker.pkg.dev/invcerts/ghcr/0xmassi/webclaw:latest
WORKDIR .
ENV MOUNT_DIR="/data"
ENV MOUNT_BUCKET="gs://rws-data"
ENV RUST_LOG="info"
# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    jq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
COPY ./setup.sh .
RUN chmod +x ./setup.sh
RUN ls -la
CMD ["./setup.sh"]
