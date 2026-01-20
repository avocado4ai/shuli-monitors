# SearXNG Quick Start Guide

This guide will help you get the SearXNG service with Traefik integration up and running quickly.

## Prerequisites

- Docker Engine (version 20.10.0 or later)
- Docker Compose (version 2.0.0 or later)
- Ports 80 and 443 available for Traefik (or modify the configuration to use different ports)

## Quick Setup

### 1. Clone or Download the Repository

If you haven't already, clone or download this repository to your local machine.

### 2. Configure Environment Variables

Create or modify the `.env` file to set your preferences:

```bash
# Set the port for SearXNG (default: 4300)
SEARXNG_PORT=4300

# Set the domain for Traefik routing (default: searxng.localhost)
TRAEFIK_HOST=searxng.localhost

# Enable/disable TLS (default: true)
TRAEFIK_TLS=true

# Enable/disable SSL redirect (default: true)
TRAEFIK_SSL_REDIRECT=true
```

Generate a new secret key for SearXNG:
```bash
openssl rand -hex 32
```

Add this to your `.env` file as `SEARXNG_SECRET_KEY`.

### 3. Start the Services

Run the following command to start all services:

```bash
docker compose up -d
```

### 4. Wait for Initialization

The services may take a minute to fully initialize. You can check the status with:

```bash
docker ps
```

The SearXNG container should show as "healthy".

## Accessing the Service

### Local Access

Access the service at:
- Web Interface: http://localhost:4300
- Or via configured hostname: http://searxng.localhost:4300 (add entry to hosts file if needed)

### External Access

If you want to access from other devices on your network:
- Use the server's IP address instead of localhost: http://[SERVER_IP]:4300
- Ensure firewall rules allow access to port 4300

## API Usage

### Search API

Send a POST request to get search results in JSON format:

```bash
curl -X POST -d "q=search terms&format=json" "http://localhost:4300/search"
```

### Example Response

The API returns a JSON object with:
- `query`: The search query
- `results`: Array of search results
- `number_of_results`: Total estimated results
- Additional metadata

## Configuration Options

### Changing the Port

To use a different port:

1. Modify `SEARXNG_PORT` in the `.env` file
2. Restart the services: `docker compose down && docker compose up -d`

### Using a Different Domain

To use a custom domain:

1. Update `TRAEFIK_HOST` in the `.env` file
2. Update your DNS or hosts file to point the domain to your server's IP
3. Restart the services

### Disabling TLS (Not Recommended)

To disable TLS for development purposes:

1. Set `TRAEFIK_TLS=false` and `TRAEFIK_SSL_REDIRECT=false` in the `.env` file
2. Restart the services

## Common Tasks

### View Logs

Check logs for the SearXNG service:
```bash
docker logs searxng
```

Check logs for all services:
```bash
docker compose logs
```

### Restart Services

Restart all services:
```bash
docker compose restart
```

Restart a specific service:
```bash
docker compose restart searxng
```

### Update Images

Pull the latest images and restart:
```bash
docker compose pull
docker compose down
docker compose up -d
```

### Stop Services

Stop all services:
```bash
docker compose down
```

## Troubleshooting

### Service Won't Start

1. Check if required ports are available:
   ```bash
   netstat -tulpn | grep :4300
   ```

2. Check container logs:
   ```bash
   docker logs searxng
   ```

3. Verify your `.env` file has correct values

### Slow Response Times

1. Check system resources (CPU, memory)
2. Verify network connectivity
3. Consider adjusting rate limiting in the configuration

### SSL/TLS Issues

1. Ensure your domain resolves to the correct IP
2. Check that ports 80 and 443 are accessible
3. Review Traefik logs for certificate errors

## Security Notes

- The service runs with read-only filesystem for security
- Security headers are automatically applied
- Rate limiting is enabled to prevent abuse
- HTTPS is enforced by default

## Next Steps

1. Customize the SearXNG settings by modifying `searxng_settings_fixed.yml`
2. Set up proper DNS records for your domain
3. Configure SSL certificates properly for production use
4. Set up monitoring and backup procedures