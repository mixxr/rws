# FROM rust:1.93

# WORKDIR /workspaces/rws/crates/format2
# COPY . .
# RUN cargo install --path ./crates/format2

FROM europe-west1-docker.pkg.dev/invcerts/ghcr/mixxr/format2:latest
WORKDIR .
ENV MOUNT_DIR="/data"
ENV RUST_LOG="info"
COPY ./setup.sh .
RUN chmod +x ./setup.sh
CMD ["./setup.sh"]
