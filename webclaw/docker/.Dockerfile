FROM ghcr.io/0xmassi/webclaw:latest
WORKDIR .
COPY setup.sh
CMD ["setup.sh", "run.sh"]
