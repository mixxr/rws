FROM europe-west1-docker.pkg.dev/invcerts/ghcr/0xmassi/webclaw:latest
WORKDIR .
ENV MOUNT_DIR="/data"
ENV MOUNT_BUCKET="gs://rws-data"
ENV RUST_LOG="info"
COPY ./setup.sh .
RUN chmod +x ./setup.sh
RUN ls -la
CMD ["./setup.sh"]
