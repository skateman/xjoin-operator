FROM registry.access.redhat.com/ubi8/go-toolset:1.17.12 as builder

USER 0
WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

RUN microdnf install --setopt=tsflags=nodocs -y go-toolset-1.18.9 && \
    microdnf install -y rsync tar procps-ng && \
    microdnf upgrade -y && \
    microdnf clean all

WORKDIR /
COPY --from=builder /workspace/manager .
USER nonroot:nonroot

ENTRYPOINT ["/manager"]
