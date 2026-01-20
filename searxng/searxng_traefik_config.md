# SearXNG Traefik Configuration Guide

This document details the Traefik configuration for the SearXNG service, including security features, routing rules, and middleware configurations.

## Traefik Labels Configuration

The SearXNG service is configured with the following Traefik labels:

### Router Configuration

#### HTTP Router (Redirect to HTTPS)
```yaml
- "traefik.http.routers.searxng-http.rule=Host(`${TRAEFIK_HOST:-searxng.localhost}`)"
- "traefik.http.routers.searxng-http.entrypoints=web"
- "traefik.http.routers.searxng-http.middlewares=searxng-https-redirect"
```

This router listens for HTTP requests on the configured host and redirects them to HTTPS using the `searxng-https-redirect` middleware.

#### HTTPS Router
```yaml
- "traefik.http.routers.searxng-secure.rule=Host(`${TRAEFIK_HOST:-searxng.localhost}`)"
- "traefik.http.routers.searxng-secure.entrypoints=websecure"
- "traefik.http.routers.searxng-secure.tls=true"
- "traefik.http.routers.searxng-secure.tls.certresolver=letsencrypt"
- "traefik.http.routers.searxng-secure.service=searxng"
- "traefik.http.routers.searxng-secure.middlewares=searxng-compress,searxng-headers,searxng-ratelimit"
```

This router handles HTTPS traffic with TLS termination and applies compression, security headers, and rate limiting middleware in sequence.

### Service Definition
```yaml
- "traefik.http.services.searxng.loadbalancer.server.port=8080"
```

Defines the internal service port for the SearXNG container.

### Middleware Configuration

#### HTTPS Redirect Middleware
```yaml
- "traefik.http.middlewares.searxng-https-redirect.redirectscheme.scheme=https"
- "traefik.http.middlewares.searxng-https-redirect.redirectscheme.permanent=true"
- "traefik.http.middlewares.searxng-https-redirect.redirectscheme.port=443"
```

Forces HTTP to HTTPS redirect with a 301 redirect.

#### Compression Middleware
```yaml
- "traefik.http.middlewares.searxng-compress.compress=true"
```

Enables compression to reduce bandwidth usage and improve response times.

#### Security Headers Middleware
```yaml
- "traefik.http.middlewares.searxng-headers.headers.accessControlAllowMethods=GET, POST, OPTIONS"
- "traefik.http.middlewares.searxng-headers.headers.accessControlMaxAge=100"
- "traefik.http.middlewares.searxng-headers.headers.addVaryHeader=true"
- "traefik.http.middlewares.searxng-headers.headers.customFrameOptionsValue=SAMEORIGIN"
- "traefik.http.middlewares.searxng-headers.headers.sslRedirect=true"
- "traefik.http.middlewares.searxng-headers.headers.stsSeconds=63072000" # 2 years
- "traefik.http.middlewares.searxng-headers.headers.stsIncludeSubdomains=true"
- "traefik.http.middlewares.searxng-headers.headers.stsPreload=true"
- "traefik.http.middlewares.searxng-headers.headers.forceSTSHeader=true"
- "traefik.http.middlewares.searxng-headers.headers.customResponseHeaders.X-Content-Type-Options=nosniff"
- "traefik.http.middlewares.searxng-headers.headers.customResponseHeaders.X-Frame-Options=SAMEORIGIN"
- "traefik.http.middlewares.searxng-headers.headers.customResponseHeaders.X-XSS-Protection=1; mode=block"
- "traefik.http.middlewares.searxng-headers.headers.customResponseHeaders.X-Permitted-Cross-Domain-Policies=none"
- "traefik.http.middlewares.searxng-headers.headers.customResponseHeaders.Referrer-Policy=strict-origin-when-cross-origin"
- "traefik.http.middlewares.searxng-headers.headers.contentSecurityPolicy=default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-ancestors 'self'; object-src 'none'; base-uri 'self';"
- "traefik.http.middlewares.searxng-headers.headers.featurePolicy=camera 'none'; geolocation 'none'; microphone 'none'; payment 'none'; usb 'none'"
- "traefik.http.middlewares.searxng-headers.headers.permissionsPolicy=geolocation=(self), microphone=(), camera=(), payment=(self)"
```

Applies comprehensive security headers to protect against various web vulnerabilities.

#### Rate Limiting Middleware
```yaml
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.average=50"
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.burst=100"
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.period=30s"
- "traefik.http.middlewares.searxng-ratelimit.ratelimit.sourceCriterion.ipStrategy.excludedIPs=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
```

Limits requests to 50 per 30 seconds with a burst capacity of 100 requests, excluding private IP ranges from rate limiting.

## Security Features

### HTTPS Enforcement
All HTTP requests are redirected to HTTPS using a 301 redirect. This ensures all traffic is encrypted.

### Certificate Management
The configuration uses Let's Encrypt for automatic SSL certificate management:
- `certresolver=letsencrypt` enables automatic certificate acquisition
- STS headers (`stsSeconds`, `stsIncludeSubdomains`, `stsPreload`) enforce HTTPS for the domain and subdomains

### Content Security Policy (CSP)
The CSP header restricts resource loading to trusted sources:
- `default-src 'self'` - Only load resources from the same origin
- `script-src 'self' 'unsafe-inline' 'unsafe-eval'` - Allow inline scripts and eval (needed for SearXNG)
- `style-src 'self' 'unsafe-inline'` - Allow inline styles
- `img-src 'self' data: https:` - Allow images from same origin, data URIs, and HTTPS
- `frame-ancestors 'self'` - Prevent clickjacking by disallowing framing from other origins

### Additional Security Headers
- `X-Frame-Options: SAMEORIGIN` - Prevents clickjacking
- `X-Content-Type-Options: nosniff` - Prevents MIME type sniffing
- `X-XSS-Protection: 1; mode=block` - Enables browser XSS protection
- `Referrer-Policy: no-referrer-when-downgrade` - Controls referrer information

## Rate Limiting

The rate limiting middleware protects against abuse by limiting requests:
- Average: 100 requests per minute
- Burst: Allows 200 requests in a short period
- Period: Resets the counter every minute

This configuration allows for normal usage while preventing excessive requests that could impact performance.

## Configuration Variables

The configuration uses environment variables with defaults:

- `${TRAEFIK_HOST:-searxng.localhost}` - The host domain for the service
- `${TRAEFIK_TLS:-true}` - Whether to enable TLS
- `${TRAEFIK_SSL_REDIRECT:-true}` - Whether to force HTTPS redirects

## Troubleshooting

### Certificate Issues
If you encounter certificate errors:
1. Verify that your domain points to the server's IP
2. Check that ports 80 and 443 are accessible
3. Review Traefik logs for certificate acquisition errors

### Middleware Order
The order of middlewares matters. In this configuration:
1. Rate limiting is applied first
2. Security headers are applied second
3. HTTPS redirect is applied for HTTP requests

### Testing Configuration
To test the configuration:
1. Access the service via HTTP (should redirect to HTTPS)
2. Check response headers for security headers
3. Verify that the service responds correctly to requests