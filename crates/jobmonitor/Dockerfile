FROM rust:1.93

WORKDIR /app
COPY . .

ENV LISTEN_PORT=8080
ENV BUCKET_NAME="projects/_/buckets/rws-data"
ENV MOUNT_DIR="/data"
ENV QUOTES_PATH="/quotes/jobs/"
ENV LOG_LEVEL="debug"

EXPOSE 8080

RUN cargo install --path .

CMD ["jobmonitor"]