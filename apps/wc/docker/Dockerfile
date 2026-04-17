FROM europe-west1-docker.pkg.dev/invcerts/ghcr/0xmassi/webclaw:latest
WORKDIR .
COPY ./setup.sh .
RUN chmod +x ./setup.sh
ARG APPNAME=wc
ARG APP_TYPE=details
ENV MOUNT_DIR="/data"
ENV APP_TYPE=$APP_TYPE
ENV APPNAME=$APPNAME
ENV RUST_LOG="info"
CMD ["./setup.sh"]
