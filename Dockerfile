# Both base images are pinned by digest: a tag can be moved to other content, a digest cannot.
# Dependabot proposes digest updates.
FROM golang:1.27.4-alpine3.24@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS build
WORKDIR /src
COPY go.mod ./
COPY cmd ./cmd
COPY internal ./internal
ARG VERSION=dev
ARG COMMIT=unknown
# Static binary (no libc needed at runtime); -trimpath removes local paths from the binary
RUN CGO_ENABLED=0 go build -trimpath \
    -ldflags "-s -w -X main.version=${VERSION} -X main.commit=${COMMIT}" \
    -o /out/server ./cmd/server

# distroless/static: no shell, no package manager, almost nothing for an attacker to use
# or for a scanner to flag. "nonroot" runs as UID 65532.
FROM gcr.io/distroless/static-debian13:nonroot@sha256:25ac8f0c3b2334a9eb05452266bd4697864a8c8ef0ef71e5e6480d7f92868329
COPY --from=build /out/server /server
USER nonroot:nonroot
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD ["/server", "healthcheck"]
ENTRYPOINT ["/server"]
