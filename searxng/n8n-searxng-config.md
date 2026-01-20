# n8n HTTP Request Configurations for SearXNG

This file contains the configurations needed to connect n8n to your SearXNG instance.

## Method 1: Internal Docker Network (Recommended for Performance)

### Simple Search Request:
```
Method: GET
URL: http://searxng:8080/search
Parameters:
  - q: {{ $json.query }}  # Search query from input
  - format: json          # Response format
  - language: en          # Language (optional, defaults to configured default)
```

### Advanced Search Request:
```
Method: GET
URL: http://searxng:8080/search
Parameters:
  - q: {{ $json.query }}     # Search query
  - format: json             # Response format
  - categories: {{ $json.categories || 'general' }}  # Categories (general, images, videos, etc.)
  - language: {{ $json.language || 'en' }}          # Language code
  - safesearch: {{ $json.safesearch || 0 }}         # Safe search (0=none, 1=moderate, 2=strict)
  - pageno: {{ $json.page || 1 }}                   # Page number
```

### POST Request Example:
```
Method: POST
URL: http://searxng:8080/search
Body (Form):
  - q: {{ $json.query }}
  - format: json
  - categories: {{ $json.categories || 'general' }}
  - language: {{ $json.language || 'en' }}
```

### Headers:
```
Content-Type: application/x-www-form-urlencoded
User-Agent: n8n-SearXNG-Integration
Accept: application/json
```

## Method 2: Using Traefik Endpoint

### Direct Traefik Endpoint:
```
Method: GET
URL: http://searxng.localhost/search
Parameters:
  - q: {{ $json.query }}     # Search query
  - format: json             # Response format
  - categories: {{ $json.categories || 'general' }}  # Categories (general, images, videos, etc.)
  - language: {{ $json.language || 'en' }}          # Language code
  - safesearch: {{ $json.safesearch || 0 }}         # Safe search (0=none, 1=moderate, 2=strict)
  - pageno: {{ $json.page || 1 }}                   # Page number
```

## n8n HTTP Request Node JSON Configuration

### Internal Network Configuration:
```json
{
  "method": "GET",
  "url": "http://searxng:8080/search",
  "qs": {
    "q": "={{ $json.query }}",
    "format": "json",
    "categories": "={{ $json.categories || 'general' }}",
    "language": "={{ $json.language || 'en' }}",
    "safesearch": "={{ $json.safesearch || 0 }}"
  },
  "headers": {
    "accept": "application/json",
    "user-agent": "n8n-SearXNG-Integration"
  },
  "options": {
    "response": "autodetect"
  }
}
```

### Traefik Configuration:
```json
{
  "method": "GET",
  "url": "http://searxng.localhost/search",
  "qs": {
    "q": "={{ $json.query }}",
    "format": "json",
    "categories": "={{ $json.categories || 'general' }}",
    "language": "={{ $json.language || 'en' }}",
    "safesearch": "={{ $json.safesearch || 0 }}"
  },
  "headers": {
    "accept": "application/json",
    "user-agent": "n8n-SearXNG-Integration"
  },
  "options": {
    "response": "autodetect"
  }
}
```

### HTTPS with Traefik (if TLS is enabled):
```json
{
  "method": "GET",
  "url": "https://searxng.localhost/search",
  "qs": {
    "q": "={{ $json.query }}",
    "format": "json",
    "categories": "={{ $json.categories || 'general' }}",
    "language": "={{ $json.language || 'en' }}",
    "safesearch": "={{ $json.safesearch || 0 }}"
  },
  "headers": {
    "accept": "application/json",
    "user-agent": "n8n-SearXNG-Integration"
  },
  "options": {
    "response": "autodetect",
    "allowUnauthorizedCerts": true  // Only if using self-signed certificates
  }
}
```

## Example for Specific Categories

For images: `http://searxng:8080/search?q={{ $json.query }}&format=json&categories=images`
For news: `http://searxng:8080/search?q={{ $json.query }}&format=json&categories=news`
For videos: `http://searxng:8080/search?q={{ $json.query }}&format=json&categories=videos`

## Processing Results in n8n

After the HTTP Request node, you can use a Function node to process the results:
```javascript
// Extract just the results from SearXNG response
const searxngResults = $input.all()[0].json.results;
return searxngResults.map(result => ({
  title: result.title,
  url: result.url,
  content: result.content,
  engine: result.engine,
  template: result.template
}));
```

## Notes

1. Since both containers are connected to the n8n network, internal communication (Method 1) is faster and more efficient.
2. Using Traefik (Method 2) provides additional benefits like SSL termination and centralized routing.
3. Make sure your TRAEFIK_HOST in the .env file matches the domain you use in n8n requests.
4. If using a custom domain, update TRAEFIK_HOST in the .env file accordingly.