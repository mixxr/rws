FROM rust:1.75 as builder

WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/target/release/jobmonitor /usr/local/bin/app

ENV PORT=8080
EXPOSE 8080

CMD ["app"]
