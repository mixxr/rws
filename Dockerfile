FROM rust:1.93

WORKDIR /workspaces/rws/crates/format2
COPY . .
RUN cargo install --path ./crates/format2

ENV MOUNT_DIR="/data"
ENV RUST_LOG="info"
COPY ./setup-format2.sh ./setup.sh
CMD ["./setup.sh"]
