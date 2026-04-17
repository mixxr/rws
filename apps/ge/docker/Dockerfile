# FROM rust:1.93

# WORKDIR /workspaces/rws/crates/format2
# COPY . .
# RUN cargo install --path ./crates/format2

FROM europe-west1-docker.pkg.dev/invcerts/ghcr/mixxr/gemini-cert:latest
WORKDIR .
ARG APPNAME=wc
ARG APP_TYPE=isin
ENV MOUNT_DIR="/data"
ENV APP_TYPE=$APP_TYPE
ENV APPNAME=$APPNAME
ENV MOUNT_BUCKET="gs://rws-data"
ENV RUST_LOG="info"
COPY ./*.sh ./
RUN chmod +x ./*.sh
CMD ["./setup.sh"]
