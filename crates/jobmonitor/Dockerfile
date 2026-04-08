FROM rust:1.93 as builder

WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
COPY --from=builder /app/target/release/jobmonitor /usr/local/bin/app
WORKDIR /usr/local/bin/app
ENV LISTEN_PORT=8080
ENV BUCKET_NAME="projects/_/buckets/rws-data"
ENV MOUNT_DIR="/data"
ENV QUOTES_PATH="/quotes/jobs/"
ENV LOG_LEVEL="debug"

EXPOSE 8080

CMD ["app"]
