# SearXNG with Traefik Integration

This repository contains a Docker Compose setup for SearXNG (a privacy-respecting, open metasearch engine) with Traefik reverse proxy integration.

## Overview

SearXNG is a free internet metasearch engine which aggregates results from various search services and databases. This setup includes:

- SearXNG service with enhanced security features
- Traefik reverse proxy with HTTPS support
- Rate limiting for protection against abuse
- Security headers for enhanced protection
- MCP (Microservice Communication Protocol) services for extended functionality

## Architecture

The setup consists of three main services:

1. **searxng**: The main SearXNG search engine
2. **searxng-mcp**: Microservice Communication Protocol service
3. **searxng-mcp-http**: HTTP wrapper for MCP service

## Configuration

### Environment Variables

The configuration is managed through the `.env` file:

```bash
UID=1000
GID=1000
SEARXNG_BASE_URL=http://0.0.0.0:4300/
SEARXNG_PORT=4300
SEARXNG_SECRET_KEY=f300b5855629ad303da6a94d18814fbdf2ab5387c09e7773f8868051371334da
SEARXNG_IMAGE_PROXY=true
SEARXNG_LIMETER=true
SEARXNG_PUBLIC_INSTANCE=false

# Traefik configuration
TRAEFIK_HOST=searxng.localhost
TRAEFIK_TLS=true
TRAEFIK_SSL_REDIRECT=true
TRAEFIK_SSL_HOST=
```

### Traefik Labels

The SearXNG service is configured with the following Traefik labels for enhanced functionality:

- **Dual routing**: Separate routers for HTTP and HTTPS with automatic redirect
- **Security headers**: CSP, X-Content-Type-Options, X-XSS-Protection, and more
- **Rate limiting**: Protection against abuse with configurable limits
- **HTTPS support**: Automatic redirect from HTTP to HTTPS with Let's Encrypt integration

## Usage

### Starting the Services

```bash
docker compose up -d
```

### Accessing the Service

- Web Interface: http://localhost:4300 or http://searxng.localhost:4300
- API: POST requests to http://localhost:4300/search with format=json

### API Usage

To use the API, send a POST request:

```bash
curl -X POST -d "q=search term&format=json" "http://localhost:4300/search"
```

## Security Features

The setup includes several security enhancements:

- **HTTPS enforcement**: Automatic redirect from HTTP to HTTPS
- **Content Security Policy**: Prevents XSS attacks
- **Security headers**: X-Content-Type-Options, X-XSS-Protection, Referrer-Policy
- **Rate limiting**: Limits requests to prevent abuse
- **Read-only filesystem**: Container runs with read-only filesystem for security

## Networking

The SearXNG service uses bridge networking with port mapping to avoid conflicts with other services on the host. The service is accessible on port 4300 on the host, mapped to port 8080 in the container.

## Troubleshooting

### Common Issues

1. **Port conflicts**: If port 4300 is already in use, modify the `SEARXNG_PORT` in the `.env` file
2. **Traefik routing**: Ensure your hosts file includes an entry for `searxng.localhost` pointing to 127.0.0.1
3. **Container restarts**: Check logs with `docker logs searxng` for specific error messages

### Useful Commands

```bash
# View logs
docker logs searxng

# Check service status
docker ps | grep searxng

# Restart services
docker compose restart

# Stop services
docker compose down
```

## Customization

### Changing the Domain

To use a different domain:

1. Update `TRAEFIK_HOST` in the `.env` file
2. Update your DNS or hosts file to point the domain to your server's IP

### Adjusting Rate Limits

Modify the rate limiting parameters in the `docker-compose.yml` file:

```yaml
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.average=100"
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.burst=200"
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.period=1m"
```

## Updating

To update to the latest version of SearXNG:

1. Pull the latest image: `docker pull searxng/searxng:latest`
2. Restart the services: `docker compose down && docker compose up -d`

## License

SearXNG is licensed under the GNU Affero General Public License v3.0.