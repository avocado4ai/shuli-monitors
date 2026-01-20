# SearXNG MCP Search - n8n Workflow

## Overview

This n8n workflow demonstrates how to integrate with the SearXNG MCP server to perform searches and process results. The workflow uses the HTTP wrapper to communicate with the MCP server and provides a complete search pipeline.

## Workflow Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SearXNG MCP Search Workflow                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐       ┌─────────────────────┐       ┌─────────────────┐  │
│  │   Start     │──────▶│ Set Search         │──────▶│ SearXNG MCP    │  │
│  │             │       │ Parameters         │       │ Search          │  │
│  └─────────────┘       └─────────────────────┘       └─────────────────┘  │
│                                                                             │
│  ┌─────────────────────┐       ┌─────────────┐       ┌─────────────┐    │
│  │ Process Results     │──────▶│ Has Results? │──────▶│ Success     │    │
│  │                     │       │             │       │ Response    │    │
│  └─────────────────────┘       └─────────────┘       └─────────────┘    │
│                                            │                          │
│                                            ▼                          │
│                                      ┌─────────────┐                  │
│                                      │ Error       │                  │
│                                      │ Response    │                  │
│                                      └─────────────┘                  │
│                                            │                          │
│                                            ▼                          │
│                                      ┌─────────────┐                  │
│                                      │ Final       │                  │
│                                      │ Output      │                  │
│                                      └─────────────┘                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Workflow Nodes

### 1. Start Node
- **Type**: `n8n-nodes-base.start`
- **Purpose**: Entry point for the workflow
- **Configuration**: No parameters needed

### 2. Set Search Parameters
- **Type**: `n8n-nodes-base.set`
- **Purpose**: Define search parameters
- **Parameters**:
  - `query`: Search query (default: "open source search engines")
  - `categories`: Search categories (default: "general")
  - `language`: Language filter (default: "en")

### 3. SearXNG MCP Search
- **Type**: `n8n-nodes-base.httpRequest`
- **Purpose**: Send search request to MCP server via HTTP wrapper
- **Configuration**:
  - **URL**: `http://searxng-mcp-http:5000/api/search`
  - **Method**: POST
  - **Body Parameters**:
    - `query`: From previous node
    - `categories`: From previous node
    - `language`: From previous node

### 4. Process Results
- **Type**: `n8n-nodes-base.function`
- **Purpose**: Format and process search results
- **JavaScript Code**:
  ```javascript
  // Process SearXNG MCP results
  const results = $input.all()[0].json.result.results;

  return results.map((result, index) => ({
    json: {
      id: index + 1,
      title: result.title,
      url: result.url,
      content: result.content.substring(0, 200) + (result.content.length > 200 ? '...' : ''),
      engine: result.engine,
      score: result.score,
      query: $input.all()[0].json.result.query
    }
  }));
  ```

### 5. Has Results?
- **Type**: `n8n-nodes-base.if`
- **Purpose**: Check if search returned any results
- **Condition**: `total_results > 0`

### 6. Success Response
- **Type**: `n8n-nodes-base.set`
- **Purpose**: Create success response
- **Parameters**:
  - `status`: "SUCCESS"
  - `message`: Success message with results count

### 7. Error Response
- **Type**: `n8n-nodes-base.set`
- **Purpose**: Create error response for no results
- **Parameters**:
  - `status`: "ERROR"
  - `message`: Error message with query information

### 8. Final Output
- **Type**: `n8n-nodes-base.set`
- **Purpose**: Consolidate final workflow output
- **Parameters**:
  - `workflowStatus`: Status from previous node
  - `workflowMessage`: Message from previous node
  - `query`: Original search query
  - `resultsCount`: Number of results found

## Prerequisites

### Required Services
1. **SearXNG MCP Server**: `searxng-mcp` container must be running
2. **HTTP Wrapper**: `searxng-mcp-http` container must be running on port 5000
3. **n8n**: Must be running and connected to the `n8n_net` network

### Network Configuration
- All containers must be on the same Docker network (`n8n_net`)
- The HTTP wrapper must be accessible at `http://searxng-mcp-http:5000`

## Installation

### 1. Start Required Services
```bash
cd /path/to/searxng-project
docker compose up -d --build
```

### 2. Import Workflow into n8n
1. Open your n8n instance
2. Click "Add Workflow" → "Import from File"
3. Select the `n8n-searxng-mcp-workflow.json` file
4. Click "Import"

### 3. Activate the Workflow
1. Open the imported workflow
2. Click "Activate" to enable the workflow
3. Click "Execute Workflow" to test it

## Usage Examples

### Basic Search
```json
{
  "query": "open source search engines",
  "categories": "general",
  "language": "en"
}
```

### Advanced Search with Parameters
```json
{
  "query": "machine learning frameworks 2024",
  "categories": "it",
  "language": "en",
  "pageno": 1,
  "num_results": 5
}
```

## Expected Output

### Success Response
```json
{
  "workflowStatus": "SUCCESS",
  "workflowMessage": "Found 5 results for query: open source search engines",
  "query": "open source search engines",
  "resultsCount": 5,
  "results": [
    {
      "id": 1,
      "title": "SearXNG - A privacy-respecting, hackable metasearch engine",
      "url": "https://github.com/searxng/searxng",
      "content": "SearXNG is a free internet metasearch engine which aggregates results from various search services and databases.",
      "engine": "github",
      "score": 0.95,
      "query": "open source search engines"
    },
    {
      "id": 2,
      "title": "What is SearXNG?",
      "url": "https://docs.searxng.org/",
      "content": "SearXNG is a fork of SearX, a privacy-respecting metasearch engine.",
      "engine": "duckduckgo",
      "score": 0.87,
      "query": "open source search engines"
    }
  ]
}
```

### Error Response (No Results)
```json
{
  "workflowStatus": "ERROR",
  "workflowMessage": "No results found for query: very specific query with no results",
  "query": "very specific query with no results",
  "resultsCount": 0
}
```

## Customization

### Modify Search Parameters
1. Open the "Set Search Parameters" node
2. Change the default values:
   - `query`: Your default search term
   - `categories`: Default category (general, images, videos, etc.)
   - `language`: Default language code

### Add More Parameters
To add additional search parameters:
1. Open the "Set Search Parameters" node
2. Add new string parameters:
   ```json
   {
     "name": "pageno",
     "value": "1"
   },
   {
     "name": "num_results",
     "value": "10"
   }
   ```
3. Update the HTTP Request node to include these parameters

### Modify Result Processing
To change how results are processed:
1. Open the "Process Results" node
2. Modify the JavaScript code:
   - Change the content truncation length
   - Add additional fields from the SearXNG response
   - Filter or sort results differently

## Troubleshooting

### Common Issues

**Issue**: Workflow fails with connection error
- **Solution**: Verify that `searxng-mcp-http` container is running
- **Check**: `docker ps | grep searxng-mcp-http`
- **Fix**: `docker compose up -d searxng-mcp-http`

**Issue**: No results returned
- **Solution**: Check if SearXNG service is running and accessible
- **Check**: `curl "http://localhost:4300/search?q=test&format=json"`
- **Fix**: `docker compose restart searxng`

**Issue**: HTTP 500 error from wrapper
- **Solution**: Check HTTP wrapper logs
- **Check**: `docker logs searxng-mcp-http`
- **Fix**: Verify Docker socket permissions and container connectivity

### Debugging Tips

1. **Check Container Logs**:
   ```bash
   docker logs searxng-mcp
   docker logs searxng-mcp-http
   docker logs searxng
   ```

2. **Test HTTP Wrapper Directly**:
   ```bash
   curl -X POST http://localhost:5000/api/search \
     -H "Content-Type: application/json" \
     -d '{"query": "test", "categories": "general"}'
   ```

3. **Test n8n Connectivity**:
   - Create a simple HTTP request workflow to test connectivity
   - Use `http://searxng-mcp-http:5000/health` for health check

## Advanced Integration

### Trigger-Based Workflow
To make this workflow trigger-based (e.g., from a webhook):
1. Add a "Webhook" node at the beginning
2. Connect it to the "Set Search Parameters" node
3. Configure the webhook to accept JSON payload with search parameters

### Error Handling Enhancement
Add a "Error Trigger" node to handle workflow failures:
1. Add "Error Trigger" node
2. Connect it to send notifications (email, Slack, etc.)
3. Configure error handling logic

### Result Caching
Add caching to avoid duplicate searches:
1. Add a "Redis" or "Memory Cache" node
2. Cache results based on query parameters
3. Implement cache invalidation logic

## Performance Considerations

- **Rate Limiting**: Consider adding rate limiting to the HTTP wrapper
- **Timeout Settings**: Adjust HTTP request timeouts based on your needs
- **Result Limiting**: The MCP server already limits to 20 results per query
- **Concurrent Requests**: n8n handles concurrency well, but monitor your SearXNG instance

## Security Best Practices

- **Network Isolation**: Keep the MCP server on internal networks only
- **Authentication**: Add API keys to the HTTP wrapper for production use
- **Input Validation**: The workflow already validates required parameters
- **Error Handling**: Sensitive error details are not exposed to end users

## License

This workflow is provided as-is and can be used freely with your SearXNG and n8n installations.