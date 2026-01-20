# SearXNG with Traefik Integration - Complete Documentation

This repository contains a complete, production-ready setup for SearXNG with Traefik reverse proxy integration, featuring enhanced security, rate limiting, and comprehensive configuration.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Security Features](#security-features)
3. [Configuration Files](#configuration-files)
4. [Getting Started](#getting-started)
5. [API Usage](#api-usage)
6. [Troubleshooting](#troubleshooting)
7. [Maintenance](#maintenance)

## Architecture Overview

The setup consists of three main services:

### 1. SearXNG Service
- Main search engine service
- Runs on port 8080 internally
- Exposed on configurable host port (default: 4300)
- Includes comprehensive security hardening

### 2. SearXNG-MCP Service
- Microservice Communication Protocol service
- Facilitates communication between services
- Runs on internal Docker network

### 3. SearXNG-MCP-HTTP Service
- HTTP wrapper for MCP service
- Provides HTTP interface for MCP functionality
- Runs on port 5000

## Security Features

### Container Hardening
- Read-only filesystem
- No new privileges
- All capabilities dropped
- Temporary directories on tmpfs

### Network Security
- Bridge networking with port mapping
- HTTPS enforcement with automatic redirects
- Comprehensive security headers
- Rate limiting to prevent abuse

### Traefik Integration
- Dual routing for HTTP/HTTPS
- Let's Encrypt certificate management
- Content Security Policy (CSP)
- Strict Transport Security (HSTS)
- Additional security headers (X-Frame-Options, X-Content-Type-Options, etc.)

## Configuration Files

### Main Configuration
- `docker-compose.yml` - Service definitions and Traefik configuration
- `.env` - Environment variables and settings
- `searxng_settings_fixed.yml` - SearXNG specific settings

### Documentation
- `README.md` - General overview and usage
- `QUICKSTART.md` - Quick setup guide
- `searxng_traefik_config.md` - Detailed Traefik configuration
- `TROUBLESHOOTING.md` - Problem-solving guide
- `SECURITY.md` - Security configuration details

## Getting Started

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+

### Quick Setup
1. Clone the repository
2. Customize the `.env` file as needed
3. Start services: `docker compose up -d`
4. Access at http://localhost:4300

### Customization Options
- Change port with `SEARXNG_PORT` in `.env`
- Modify domain with `TRAEFIK_HOST` in `.env`
- Adjust security settings in `docker-compose.yml`
- Configure SearXNG settings in `searxng_settings_fixed.yml`

## API Usage

### Search API
Send POST requests to `/search` with form-encoded parameters:

```bash
curl -X POST -d "q=search term&format=json" "http://localhost:4300/search"
```

### Response Format
API returns JSON with:
- Query information
- Search results with metadata
- Result statistics
- Engine information

### Supported Formats
- JSON (format=json)
- RSS, Atom, HTML (depending on configuration)

## Troubleshooting

### Common Issues
- **Port conflicts**: Check `netstat -tulpn | grep :4300`
- **Container restarts**: Review logs with `docker logs searxng`
- **SSL issues**: Verify domain resolution and certificate settings
- **Performance**: Check resource usage with `docker stats`

### Diagnostic Commands
```bash
# Check service status
docker ps | grep searxng

# View logs
docker logs searxng

# Monitor resources
docker stats searxng

# Test connectivity
curl -I http://localhost:4300
```

## Maintenance

### Regular Tasks
- Update container images: `docker compose pull && docker compose up -d`
- Monitor logs for errors
- Check resource usage
- Verify SSL certificate validity

### Backup Strategy
- Backup configuration files regularly
- Export container volumes if needed
- Document custom configurations

### Security Updates
- Monitor SearXNG releases
- Update Traefik if needed
- Review security configurations periodically

## Performance Tuning

### Resource Allocation
- Adjust memory and CPU limits in docker-compose.yml if needed
- Monitor with `docker stats`
- Scale based on usage patterns

### Rate Limiting
- Adjust rate limiting parameters based on usage
- Monitor for legitimate traffic being blocked
- Balance between protection and usability

## Support

For issues not covered in the documentation:
1. Check the troubleshooting guide
2. Review container logs
3. Verify configuration files
4. Consult the SearXNG and Traefik documentation

## Contributing

This setup is designed to be secure, efficient, and easy to maintain. Contributions to improve security, performance, or usability are welcome.

## License

SearXNG is licensed under the GNU Affero General Public License v3.0.
Documentation is provided as-is for educational and operational purposes.