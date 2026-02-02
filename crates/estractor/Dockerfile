FROM rust:1.93

WORKDIR /workspaces/rws
COPY . .

RUN cargo install --path .

CMD ["rws"]
