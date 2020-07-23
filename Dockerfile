FROM golang:1.14-alpine AS builder

RUN apk --no-cache add git gcc musl-dev ca-certificates && update-ca-certificates

WORKDIR /usr/src/app

# Download module deps (for caching)
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s"

# Dummy /etc/passwd
RUN echo "nobody:x:65534:65534:Nobody:/:" > /etc_passwd

# Assemble dist image
FROM scratch

VOLUME ["/etc/nomatctld"]
VOLUME ["/etc/ssh"]

COPY --from=builder /etc_passwd /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/src/app/nomadctld /
COPY --from=builder /usr/src/app/nomadctld.toml.example /etc/nomadctld/

ENTRYPOINT ["/nomadctld"]
