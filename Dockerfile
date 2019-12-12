FROM golang:1.9 AS builder

WORKDIR /go/src/github.com/oliver006/redis_exporter/

ADD config/main.go /go/src/github.com/oliver006/redis_exporter/
ADD config/exporter /go/src/github.com/oliver006/redis_exporter/exporter
ADD config/vendor /go/src/github.com/oliver006/redis_exporter/vendor

RUN apt-get update \
    && apt-get install ca-certificates \
    && env CGO_ENABLED=0 \
	GOOS=linux \
    go build -o /redis_exporter -ldflags "-s -w -extldflags \"-static\"" .

FROM scratch

# Redis Exporter image for OpenShift Origin

LABEL io.k8s.description="Redis Prometheus Exporter." \
      io.k8s.display-name="Redis Exporter" \
      io.openshift.expose-services="9113:http" \
      io.openshift.tags="redis,exporter,prometheus" \
      io.openshift.non-scalable="true" \
      help="For more information visit https://github.com/Worteks/docker-redisexporter" \
      maintainer="Samuel MARTIN MORO <faust64@gmail.com>" \
      version="1.0"

COPY --from=builder /redis_exporter /redis_exporter
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

ENTRYPOINT [ "/redis_exporter" ]
