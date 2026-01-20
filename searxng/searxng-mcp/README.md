# SearXNG MCP Server

## Overview

This MCP (Mistral Communication Protocol) server wraps the existing SearXNG service and exposes a single MCP tool called `searxng_search`. The server runs as a sidecar container alongside the main SearXNG service, allowing external systems to query SearXNG using the MCP protocol.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SearXNG MCP Server                      │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   MCP Server (Python)                  │  │
│  │                                                       │  │
│  │  - Listens on stdin for MCP requests                 │  │
│  │  - Exposes tool: searxng_search                       │  │
│  │  - Uses stdio transport                               │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   SearXNG Service                    │  │
│  │                                                       │  │
│  │  - Running on http://searxng:8080                    │  │
│  │  - Provides search functionality                      │  │
│  │  - Returns JSON responses                             │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Features

- **Single MCP Tool**: `searxng_search` - performs searches using SearXNG
- **Parameter Support**:
  - `q` (required): Search query
  - `categories`: Optional search categories
  - `language`: Optional language filter
  - `pageno`: Optional page number
  - `num_results`: Optional results per page
- **Result Formatting**: Returns only essential fields (title, url, content, engine, score)
- **Result Limiting**: Maximum 20 results per query
- **Error Handling**: Comprehensive error handling and validation

## How It Works

1. **MCP Request**: External systems send MCP requests via stdin
2. **Tool Invocation**: The `searxng_search` tool is called with parameters
3. **SearXNG Query**: The server makes an HTTP GET request to `http://searxng:8080/search`
4. **Response Processing**: The JSON response is parsed and filtered
5. **MCP Response**: Formatted results are returned via stdout

## Installation & Usage

### Prerequisites

- Docker and Docker Compose installed
- Existing SearXNG service running
- n8n_net network available (for n8n integration)

### Running the Stack

1. **Build and start the services**:

```bash
docker compose up -d --build
```

2. **Verify services are running**:

```bash
docker compose ps
```

### Testing SearXNG JSON on Port 4300

The original SearXNG service continues to work on port 4300:

```bash
curl "http://localhost:4300/search?q=test&format=json"
```

### Using the MCP Tool

The MCP server exposes a single tool that can be used by MCP clients:

**Tool Name**: `searxng_search`

**Parameters**:
- `q` (string, required): Search query
- `categories` (string, optional): Search categories
- `language` (string, optional): Language filter
- `pageno` (integer, optional): Page number
- `num_results` (integer, optional): Results per page

**Example MCP Request**:
```json
{
  "tool": "searxng_search",
  "params": {
    "q": "open source search engines",
    "categories": "general",
    "language": "en",
    "pageno": 1,
    "num_results": 10
  }
}
```

**Example MCP Response**:
```json
{
  "tool": "searxng_search",
  "result": {
    "success": true,
    "query": "open source search engines",
    "results": [
      {
        "title": "SearXNG - A privacy-respecting, hackable metasearch engine",
        "url": "https://github.com/searxng/searxng",
        "content": "SearXNG is a free internet metasearch engine which aggregates results from various search services and databases.",
        "engine": "github",
        "score": 0.95
      },
      {
        "title": "What is SearXNG?",
        "url": "https://docs.searxng.org/",
        "content": "SearXNG is a fork of SearX, a privacy-respecting metasearch engine.",
        "engine": "duckduckgo",
        "score": 0.87
      }
    ],
    "total_results": 2
  }
}
```

## Configuration

The MCP server uses the following environment variables:

- `SEARXNG_BASE`: Base URL for SearXNG service (default: `http://searxng:8080`)

## Network Configuration

The MCP server connects to two networks:

1. **searxng_network**: Internal network for communication with SearXNG
2. **n8n_net**: External network for integration with n8n workflow automation

## Security

- No ports are exposed for the MCP server
- All communication happens internally via Docker networks
- The MCP server only communicates with the SearXNG service
- No external HTTP listeners are created

## Development

### Building the MCP Server

```bash
cd searxng-mcp
docker build -t searxng-mcp .
```

### Running Tests

```bash
./scripts/test-searxng-mcp.sh
```

### Debugging

To see MCP server logs:

```bash
docker logs searxng-mcp
```

## Troubleshooting

**Issue**: MCP server not responding
- **Solution**: Check if the SearXNG service is running and accessible at `http://searxng:8080`

**Issue**: Invalid JSON responses
- **Solution**: Verify the SearXNG API is returning valid JSON

**Issue**: Connection refused
- **Solution**: Ensure both containers are on the same Docker networks

## License

This MCP server is provided as-is and follows the same licensing as the main SearXNG project.