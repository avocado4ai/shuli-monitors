# SearXNG with Traefik - Troubleshooting Guide

This guide provides solutions for common issues encountered when running SearXNG with Traefik integration.

## Common Issues and Solutions

### 1. Service Won't Start

#### Symptoms
- Container keeps restarting
- Error message: "Address already in use (os error 98)"

#### Solutions
1. **Check for port conflicts**:
   ```bash
   netstat -tulpn | grep :4300
   ```
   
2. **Change the port** in `.env` file:
   ```bash
   SEARXNG_PORT=4301  # Use a different port
   ```
   
3. **Stop conflicting services** that might be using the port

4. **Check Docker logs** for specific errors:
   ```bash
   docker logs searxng
   ```

### 2. Cannot Access via Web Browser

#### Symptoms
- Connection refused or timeout
- Page not found errors

#### Solutions
1. **Verify the service is running**:
   ```bash
   docker ps | grep searxng
   ```
   
2. **Check if the port is accessible**:
   ```bash
   curl -I http://localhost:4300
   ```
   
3. **Verify the port mapping** in `docker-compose.yml`
4. **Check firewall settings** to ensure port 4300 is open

### 3. API Requests Return HTML Instead of JSON

#### Symptoms
- API calls return HTML pages instead of JSON
- Expected JSON response but getting web interface

#### Solutions
1. **Use POST requests** for API calls:
   ```bash
   curl -X POST -d "q=search&format=json" "http://localhost:4300/search"
   ```
   
2. **Verify the request format** - API expects form-encoded data

### 4. SSL/TLS Certificate Issues

#### Symptoms
- Certificate errors in browser
- HTTPS not working
- Let's Encrypt certificate acquisition failures

#### Solutions
1. **Verify domain resolution**:
   ```bash
   nslookup your-domain.com
   ```
   
2. **Check if ports 80 and 443 are accessible**:
   ```bash
   netstat -tulpn | grep :80
   netstat -tulpn | grep :443
   ```
   
3. **Verify Traefik configuration** for certificate resolver
4. **Check Traefik logs** for certificate errors:
   ```bash
   docker logs traefik
   ```

### 5. High Memory Usage

#### Symptoms
- Container consuming excessive memory
- System slowdown
- Out of memory errors

#### Solutions
1. **Monitor memory usage**:
   ```bash
   docker stats searxng
   ```
   
2. **Adjust SearXNG settings** in `searxng_settings_fixed.yml` to limit concurrent requests
3. **Reduce the number of enabled engines** in the SearXNG configuration

### 6. Rate Limiting Issues

#### Symptoms
- Requests being blocked
- 429 (Too Many Requests) errors
- API calls failing intermittently

#### Solutions
1. **Adjust rate limiting** in `docker-compose.yml`:
   ```yaml
   - "traefik.http.middlewares.searxng-ratelimit.ratelimit.average=200"  # Increase average
   - "traefik.http.middlewares.searxng-ratelimit.ratelimit.burst=400"    # Increase burst
   ```
   
2. **Temporarily disable rate limiting** for debugging:
   ```yaml
   # Comment out the rate limit middleware
   # - "traefik.http.routers.searxng-secure.middlewares=searxng-headers,searxng-ratelimit"
   - "traefik.http.routers.searxng-secure.middlewares=searxng-headers"
   ```

### 7. Security Header Issues

#### Symptoms
- Content not loading due to CSP violations
- Mixed content warnings
- Frame embedding issues

#### Solutions
1. **Review security headers** in `docker-compose.yml`
2. **Adjust CSP policy** if needed for specific functionality
3. **Check browser console** for specific CSP violation details

### 8. MCP Services Not Working

#### Symptoms
- MCP services not responding
- Connection errors between services
- MCP HTTP wrapper not accessible

#### Solutions
1. **Check MCP service logs**:
   ```bash
   docker logs searxng-mcp
   docker logs searxng-mcp-http
   ```
   
2. **Verify network connectivity** between services
3. **Check environment variables** for MCP configuration

## Diagnostic Commands

### Check Overall System Status
```bash
docker ps
docker compose ps
```

### Detailed Container Information
```bash
docker inspect searxng
docker stats searxng
```

### Log Analysis
```bash
# SearXNG logs
docker logs searxng

# Last 50 lines of logs
docker logs --tail 50 searxng

# Follow logs in real-time
docker logs -f searxng
```

### Network Connectivity Tests
```bash
# Test internal connectivity
docker exec searxng wget --spider http://localhost:8080

# Test external connectivity
curl -I http://localhost:4300
curl -H "Host: searxng.localhost" http://localhost:4300
```

### Configuration Verification
```bash
# Verify environment variables
docker exec searxng env | grep SEARXNG

# Check settings file
docker exec searxng cat /etc/searxng/settings.yml
```

## Performance Tuning

### Memory Optimization
1. **Limit memory usage** in docker-compose.yml:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 1G
       reservations:
         memory: 512M
   ```

### CPU Optimization
1. **Limit CPU usage** if needed:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
   ```

## Recovery Procedures

### Complete Reset
If experiencing persistent issues:

1. **Stop all services**:
   ```bash
   docker compose down
   ```

2. **Remove volumes** (this will reset settings):
   ```bash
   docker volume prune
   ```

3. **Pull fresh images**:
   ```bash
   docker compose pull
   ```

4. **Start services**:
   ```bash
   docker compose up -d
   ```

### Configuration Rollback
1. **Backup current config**:
   ```bash
   cp docker-compose.yml docker-compose.yml.backup
   ```

2. **Restore from backup** if needed:
   ```bash
   cp docker-compose.yml.backup docker-compose.yml
   ```

## Monitoring

### Health Checks
The SearXNG container includes health checks. Check status with:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Resource Monitoring
```bash
# Monitor all containers
docker stats

# Monitor specific container
docker stats searxng
```

## When to Seek Help

Contact support or community when:
- Issues persist after trying all troubleshooting steps
- Encountering security-related errors
- Need help with custom configurations
- Performance issues continue after optimization attempts