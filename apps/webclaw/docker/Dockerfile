FROM europe-west1-docker.pkg.dev/invcerts/ghcr/0xmassi/webclaw:latest
WORKDIR .
COPY COPY --chmod=+x ./setup.sh .
ENV MOUNT_DIR="/data"
CMD ["./setup.sh"]
