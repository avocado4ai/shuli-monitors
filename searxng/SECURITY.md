# SearXNG Security Configuration Guide

This document outlines the security measures implemented in the SearXNG setup with Traefik integration.

## Overview

The SearXNG deployment includes multiple layers of security to protect against various threats and ensure privacy. This guide details each security measure and how to customize them.

## Container Security

### Read-Only Filesystem
The SearXNG container runs with a read-only filesystem for security:
```yaml
read_only: true
```

This prevents malicious code from modifying the container's filesystem.

### Security Options
```yaml
security_opt:
  - no-new-privileges:true
```

Prevents processes from gaining additional privileges.

### Capability Dropping
```yaml
cap_drop:
  - ALL
```

Removes all Linux capabilities except those explicitly required.

### Temporary Filesystems
```yaml
tmpfs:
  - /tmp
  - /var/tmp
  - /run
  - /var/run
```

Mounts temporary directories as tmpfs to prevent persistent storage in these locations.

## Network Security

### Bridge Networking
The service uses bridge networking instead of host networking to isolate the container:
```yaml
ports:
  - "0.0.0.0:${SEARXNG_PORT:-4300}:8080"
```

This avoids port conflicts and provides network isolation.

## Traefik Security Configuration

### HTTPS Enforcement
All HTTP traffic is redirected to HTTPS:
```yaml
- "traefik.http.middlewares.searxng-https-redirect.redirectscheme.scheme=https"
- "traefik.http.middlewares.searxng-https-redirect.redirectscheme.permanent=true"
```

### Strict Transport Security (HSTS)
```yaml
- "traefik.http.middlewares.searxng-headers.headers.stsSeconds=31536000"
- "traefik.http.middlewares.searxng-headers.headers.stsIncludeSubdomains=true"
- "traefik.http.middlewares.searxng-headers.headers.stsPreload=true"
- "traefik.http.middlewares.searxng-headers.headers.forceSTSHeader=true"
```

Enforces HTTPS for the domain and subdomains for a year.

### Content Security Policy (CSP)
```yaml
- "traefik.http.middlewares.searxng-headers.headers.contentSecurityPolicy=default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'self';"
```

Restricts resource loading to prevent XSS attacks.

### Additional Security Headers
```yaml
- "traefik.http.middlewares.searxng-headers.headers.customFrameOptionsValue=SAMEORIGIN"
- "traefik.http.middlewares.searxng-headers.headers.customResponseHeaders.X-Content-Type-Options=nosniff"
- "traefik.http.middlewares.searxng-headers.headers.customResponseHeaders.X-XSS-Protection=1; mode=block"
- "traefik.http.middlewares.searxng-headers.headers.customResponseHeaders.Referrer-Policy=no-referrer-when-downgrade"
```

Provides protection against clickjacking, MIME type sniffing, XSS, and controls referrer information.

## Rate Limiting

### Request Throttling
```yaml
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.average=100"
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.burst=200"
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.period=1m"
```

Limits requests to 100 per minute with a burst allowance of 200 requests to prevent abuse.

## SearXNG Internal Security

### Secret Key
The `.env` file should contain a strong secret key:
```bash
SEARXNG_SECRET_KEY=your-very-long-secret-key-here
```

Generate with:
```bash
openssl rand -hex 32
```

### Image Proxy
Enable image proxy to prevent direct connections to external servers:
```bash
SEARXNG_IMAGE_PROXY=true
```

### Limiter
Enable rate limiting within SearXNG:
```bash
SEARXNG_LIMETER=true
```

## Authentication and Authorization

### No Default Authentication
By default, SearXNG is publicly accessible. For private deployments, consider:

1. **Network-level access control** using firewall rules
2. **Reverse proxy authentication** before Traefik
3. **IP whitelisting** in Traefik configuration

Example IP whitelist middleware:
```yaml
- "traefik.http.middlewares.ip-whitelist.ipWhiteList.sourceRange=192.168.1.0/24,10.0.0.0/8"
```

## Privacy Considerations

### Data Collection
SearXNG is configured to respect user privacy:
- No user tracking by default
- Query anonymization
- No persistent user data storage

### Logging
The configuration minimizes logging of sensitive information.

## Security Best Practices

### Regular Updates
Keep the SearXNG image updated:
```bash
docker compose pull
docker compose up -d
```

### Monitoring
Monitor access logs for suspicious activity:
```bash
docker logs searxng --tail 100 -f
```

### Backup
Regularly backup configuration files:
- `docker-compose.yml`
- `.env`
- `searxng_settings_fixed.yml`

### Firewall
Configure firewall to limit access if needed:
```bash
# Example for UFW
ufw allow 4300/tcp
ufw allow from 192.168.1.0/24 to any port 4300
```

## Security Auditing

### Configuration Review
Regularly review the security configuration:
1. Check for unnecessary open ports
2. Verify security headers are active
3. Confirm rate limiting is appropriate
4. Review access logs for anomalies

### Vulnerability Scanning
Consider scanning the container image for vulnerabilities:
```bash
docker scan searxng/searxng:latest
```

## Incident Response

### Suspicious Activity
If you detect suspicious activity:

1. **Check logs** for unusual patterns
2. **Temporarily restrict access** if needed
3. **Update security configurations** as necessary
4. **Consider blocking specific IPs** if attacks are targeted

### Compromise Response
If a compromise is suspected:

1. **Isolate the service** temporarily
2. **Change all secrets** (SECRET_KEY, etc.)
3. **Review all configurations** for unauthorized changes
4. **Scan the host system** for compromise indicators
5. **Restore from clean backups** if necessary

## Compliance Considerations

### GDPR
The setup respects user privacy by default, but consider:
- Data retention policies
- Right to deletion procedures
- Consent mechanisms if required

### Other Regulations
Depending on your jurisdiction, additional compliance measures may be required.

## Security Testing

### Penetration Testing
Before deploying to production, consider security testing:
- Vulnerability scanning
- Penetration testing
- Load testing to verify rate limiting effectiveness

### Security Headers Verification
Verify security headers are working:
```bash
curl -I http://your-domain.com
```

Look for security headers in the response.

## Conclusion

This security configuration provides multiple layers of protection for your SearXNG deployment. Regular maintenance and monitoring are essential to maintain security over time. Always stay updated with the latest security best practices for both SearXNG and Traefik.