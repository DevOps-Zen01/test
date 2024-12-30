# Stage 1: Build the application
FROM golang:1.21.4-alpine AS builder

# Add git for fetching dependencies
RUN apk add --no-cache git

# Install security updates and curl for healthcheck
RUN apk update && apk upgrade 

# Create non-root user
RUN adduser -D -g '' appuser

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application with security flags
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags=-static' \
    -tags=netgo \
    -a \
    -o main .

# Stage 2: Create minimal runtime image
FROM alpine:3.18 

# Add necessary security updates
RUN apk update && \
    apk upgrade && \
    apk add --no-cache ca-certificates tzdata && \
    rm -rf /var/cache/apk/*

# Import non-root user
COPY --from=builder /etc/passwd /etc/passwd

# Copy binary from builder
COPY --from=builder /app/main /app/main

# Set working directory
WORKDIR /app

# Use non-root user
USER appuser

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Expose port
EXPOSE 8080

# Run binary
CMD ["./main"]