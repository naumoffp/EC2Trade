FROM golang:alpine3.16

LABEL author="Peter Naumoff"
LABEL org.opencontainers.image.source https://github.com/naumoffp/EC2Trade

# Copy all of the application files into the container
WORKDIR /EC2Trade
COPY core/ ./core
COPY tf/ ./tf

# Install the application dependencies
COPY go.mod ./
COPY go.sum ./
RUN go mod download

# Build the application
COPY *.go ./

ENTRYPOINT ["go", "run", "main.go"]
