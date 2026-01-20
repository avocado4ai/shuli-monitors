# Dockerfile for SearXNG MCP Server
FROM python:3.12-slim

# Install required packages
RUN pip install --no-cache-dir requests

# Copy the server code
WORKDIR /app
COPY server.py .

# Set environment variable
ENV SEARXNG_BASE=http://searxng:8080

# Make the script executable
RUN chmod +x server.py

# Default command to start the MCP server
CMD ["python3", "server.py"]