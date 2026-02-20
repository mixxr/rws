FROM rust:1.93

WORKDIR /workspaces/rws/crates/estractor
COPY . .

RUN cargo install --path .

CMD ["estractor"]
