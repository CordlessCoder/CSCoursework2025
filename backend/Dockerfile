FROM rust:1.85 AS base
RUN cargo install sccache --version ^0.10
RUN cargo install cargo-chef --version ^0.1
ENV RUSTC_WRAPPER=sccache SCCACHE_DIR=/sccache
 
FROM base AS prepare
WORKDIR /app
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=$SCCACHE_DIR,sharing=locked \
    cargo chef prepare --recipe-path recipe.json

FROM base AS build
WORKDIR /app
COPY --from=prepare /app/recipe.json recipe.json
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=$SCCACHE_DIR,sharing=locked \
    cargo chef cook --release --recipe-path recipe.json
COPY . .
COPY .sqlx .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=$SCCACHE_DIR,sharing=locked \
    SQLX_OFFLINE=true cargo build --release

# Use Alpine Linux as the base image for the final stage
# FROM alpine:latest AS runner
FROM base AS run
WORKDIR /app
WORKDIR /app

# # Install system dependencies using apk
# RUN apk add --no-cache libssl1.1

COPY . .
# Copy the compiled binary from the build stage
COPY --from=build /app/target/release/cs2025_coursework_backend /app/cs2025_coursework_backend

CMD ["/app/cs2025_coursework_backend"]
