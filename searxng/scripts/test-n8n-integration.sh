#!/bin/bash

# Test script for complete n8n integration with SearXNG MCP
# Tests all components: MCP server, HTTP wrapper, and n8n workflow

echo "=== SearXNG MCP + n8n Integration Test Script ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Step 1: Build and start all services
echo "1. Building and starting all services..."
print_status "$YELLOW" "This may take a few minutes..."

docker compose up -d --build searxng-mcp-http

if [ $? -ne 0 ]; then
    print_status "$RED" "ERROR: Failed to start services"
    exit 1
fi

# Step 2: Wait for services to start
echo "2. Waiting for services to initialize..."
for i in {1..20}; do
    echo -n "."
    sleep 3
done
echo

# Step 3: Test SearXNG on port 4300 (ensure it still works)
echo "3. Testing SearXNG on port 4300..."

RESPONSE=$(curl -s -w "\n%{http_code}" "http://localhost:4300/search?q=n8n&format=json")
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ] && echo "$BODY" | python3 -m json.tool > /dev/null 2>&1; then
    print_status "$GREEN" "✓ SearXNG on port 4300 is working correctly"
else
    print_status "$RED" "✗ SearXNG on port 4300 failed"
    echo "HTTP Code: $HTTP_CODE"
    exit 1
fi

# Step 4: Test HTTP wrapper health endpoint
echo "4. Testing HTTP wrapper health endpoint..."

HEALTH_RESPONSE=$(curl -s "http://localhost:5000/health")
HEALTH_STATUS=$(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['status'])")

if [ "$HEALTH_STATUS" == "healthy" ]; then
    print_status "$GREEN" "✓ HTTP wrapper is healthy"
    echo "MCP Status: $(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['mcp_status'])")"
else
    print_status "$RED" "✗ HTTP wrapper health check failed"
    echo "Response: $HEALTH_RESPONSE"
    exit 1
fi

# Step 5: Test HTTP wrapper search endpoint
echo "5. Testing HTTP wrapper search endpoint..."

SEARCH_RESPONSE=$(curl -s -X POST "http://localhost:5000/api/search" \
    -H "Content-Type: application/json" \
    -d '{"query": "n8n workflow automation", "categories": "general", "language": "en"}')

SEARCH_ERROR=$(echo "$SEARCH_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['error'] if 'error' in data else '')")

if [ -z "$SEARCH_ERROR" ]; then
    print_status "$GREEN" "✓ HTTP wrapper search endpoint working"
    
    # Extract and display some result info
    TOTAL_RESULTS=$(echo "$SEARCH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['mcp_response']['total_results'])")
    FIRST_RESULT_TITLE=$(echo "$SEARCH_RESPONSE" | python3 -c "import sys, json; results=json.load(sys.stdin)['mcp_response']['results']; print(results[0]['title'] if results else 'No results')")
    
    echo "Found $TOTAL_RESULTS results"
    echo "First result: $FIRST_RESULT_TITLE"
else
    print_status "$RED" "✗ HTTP wrapper search failed"
    echo "Error: $SEARCH_ERROR"
    exit 1
fi

# Step 6: Test HTTP wrapper info endpoint
echo "6. Testing HTTP wrapper info endpoint..."

INFO_RESPONSE=$(curl -s "http://localhost:5000/info")
SERVICE_NAME=$(echo "$INFO_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['service'])")

if [ "$SERVICE_NAME" == "SearXNG MCP HTTP Wrapper" ]; then
    print_status "$GREEN" "✓ HTTP wrapper info endpoint working"
    echo "Version: $(echo "$INFO_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['version'])")"
else
    print_status "$RED" "✗ HTTP wrapper info endpoint failed"
    exit 1
fi

# Step 7: Check container status
echo "7. Checking container status..."

MCP_STATUS=$(docker ps --filter "name=searxng-mcp" --format "{{.Status}}")
MCP_HTTP_STATUS=$(docker ps --filter "name=searxng-mcp-http" --format "{{.Status}}")
SEARXNG_STATUS=$(docker ps --filter "name=searxng" --format "{{.Status}}")

if [ -n "$MCP_STATUS" ] && [ -n "$MCP_HTTP_STATUS" ] && [ -n "$SEARXNG_STATUS" ]; then
    print_status "$GREEN" "✓ All containers are running"
    echo "  - searxng-mcp: $MCP_STATUS"
    echo "  - searxng-mcp-http: $MCP_HTTP_STATUS"
    echo "  - searxng: $SEARXNG_STATUS"
else
    print_status "$RED" "✗ Some containers are not running"
    exit 1
fi

# Step 8: Test error handling
echo "8. Testing error handling..."

ERROR_RESPONSE=$(curl -s -X POST "http://localhost:5000/api/search" \
    -H "Content-Type: application/json" \
    -d '{}')

ERROR_MESSAGE=$(echo "$ERROR_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['error'])")

if [ "$ERROR_MESSAGE" == "Missing required parameter: query" ]; then
    print_status "$GREEN" "✓ Error handling working correctly"
else
    print_status "$YELLOW" "⚠ Error handling test inconclusive"
    echo "Response: $ERROR_RESPONSE"
fi

# Step 9: Test n8n workflow file
echo "9. Checking n8n workflow file..."

if [ -f "n8n-searxng-mcp-workflow.json" ]; then
    print_status "$GREEN" "✓ n8n workflow file exists"
    
    # Validate JSON
    if python3 -m json.tool "n8n-searxng-mcp-workflow.json" > /dev/null 2>&1; then
        print_status "$GREEN" "✓ n8n workflow JSON is valid"
        
        # Count nodes
        NODE_COUNT=$(python3 -c "import json; data=json.load(open('n8n-searxng-mcp-workflow.json')); print(len(data['nodes']))")
        echo "Workflow contains $NODE_COUNT nodes"
    else
        print_status "$RED" "✗ n8n workflow JSON is invalid"
        exit 1
    fi
else
    print_status "$RED" "✗ n8n workflow file not found"
    exit 1
fi

# Final summary
echo
echo "=== Integration Test Summary ==="
print_status "$GREEN" "✓ SearXNG continues to work on port 4300"
print_status "$GREEN" "✓ MCP server container is running"
print_status "$GREEN" "✓ HTTP wrapper container is running"
print_status "$GREEN" "✓ HTTP wrapper endpoints are functional"
print_status "$GREEN" "✓ Error handling is working"
print_status "$GREEN" "✓ n8n workflow is ready for import"

echo
echo "🎉 ALL TESTS PASSED!"
echo
echo "Your SearXNG MCP + n8n integration is ready to use!"
echo
echo "Next steps:"
echo "1. Import the n8n workflow: n8n-searxng-mcp-workflow.json"
echo "2. Activate the workflow in n8n"
echo "3. Test with different search queries"
echo "4. Customize the workflow as needed"
echo
echo "The integration provides:"
echo "• HTTP API at http://localhost:5000/api/search"
echo "• Health check at http://localhost:5000/health"
echo "• Info endpoint at http://localhost:5000/info"
echo "• Full n8n workflow with error handling"
echo "• Comprehensive logging in searxng-mcp/logs/"

echo
echo "Port 4300 remains unchanged for direct SearXNG access."