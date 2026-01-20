#!/usr/bin/env python3
"""
HTTP Wrapper for SearXNG MCP Server
Exposes the MCP functionality via HTTP for easier integration with n8n and other tools
"""

import os
import json
import subprocess
import tempfile
from flask import Flask, request, jsonify
from typing import Dict, Any
import logging
from logging.handlers import RotatingFileHandler

# Configure logging
app = Flask(__name__)
logger = logging.getLogger('searxng_mcp_http_wrapper')
logger.setLevel(logging.INFO)

# Create logs directory if it doesn't exist
os.makedirs('logs', exist_ok=True)

# Set up file handler
file_handler = RotatingFileHandler(
    'logs/http_wrapper.log', 
    maxBytes=1024 * 1024,  # 1MB
    backupCount=3
)
file_handler.setFormatter(logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
))
logger.addHandler(file_handler)

class SearxngMcpHttpWrapper:
    def __init__(self):
        self.container_name = os.environ.get('SEARXNG_MCP_CONTAINER', 'searxng-mcp')
        self.max_retries = 3
        self.retry_delay = 1
        logger.info(f"HTTP Wrapper initialized with container: {self.container_name}")
    
    def execute_mcp_command(self, mcp_request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute an MCP command by communicating with the container via Docker exec
        
        Args:
            mcp_request: Dictionary containing the MCP request
                - tool: MCP tool name (e.g., 'searxng_search')
                - params: Dictionary of parameters for the tool
        
        Returns:
            Dictionary containing the MCP response or error information
        """
        logger.debug(f"Executing MCP command: {json.dumps(mcp_request, indent=2)}")
        
        for attempt in range(self.max_retries):
            try:
                # Convert request to JSON string
                request_json = json.dumps(mcp_request)
                logger.debug(f"MCP request JSON: {request_json}")
                
                # Create a temporary file for the request
                with tempfile.NamedTemporaryFile(mode='w+', delete=False, suffix='.json') as temp_file:
                    temp_file.write(request_json)
                    temp_file_path = temp_file.name
                
                logger.debug(f"Created temporary file: {temp_file_path}")
                
                # Build the Docker exec command
                # We use a here-document approach to pass the JSON to the container
                cmd = [
                    'docker', 'exec', '-i', self.container_name,
                    'bash', '-c', f'cat <<EOF | python3 server.py\n{request_json}\nEOF'
                ]
                
                logger.debug(f"Executing command: {' '.join(cmd)}")
                
                # Execute the command
                result = subprocess.run(
                    cmd, 
                    capture_output=True, 
                    text=True, 
                    timeout=30
                )
                
                # Clean up the temporary file
                try:
                    os.unlink(temp_file_path)
                    logger.debug(f"Removed temporary file: {temp_file_path}")
                except Exception as e:
                    logger.warning(f"Failed to remove temp file {temp_file_path}: {str(e)}")
                
                # Check return code
                if result.returncode != 0:
                    error_msg = f'Docker exec failed (attempt {attempt + 1}/{self.max_retries}): {result.stderr}'
                    logger.error(error_msg)
                    
                    if attempt < self.max_retries - 1:
                        import time
                        time.sleep(self.retry_delay)
                        continue
                    
                    return {
                        'error': error_msg,
                        'returncode': result.returncode,
                        'stderr': result.stderr
                    }
                
                # Process the output
                logger.debug(f"Raw output: {result.stdout}")
                
                # The MCP server outputs multiple lines, we want the JSON response
                output_lines = result.stdout.strip().split('\n')
                
                for line in output_lines:
                    line = line.strip()
                    if line and line.startswith('{'):
                        try:
                            response = json.loads(line)
                            logger.debug(f"Parsed response: {json.dumps(response, indent=2)}")
                            return response
                        except json.JSONDecodeError as e:
                            logger.error(f'Failed to parse JSON response: {str(e)}')
                            logger.error(f'Line content: {line}')
                            continue
                
                # If we get here, no valid JSON was found
                error_msg = 'No valid JSON response received from MCP server'
                logger.error(error_msg)
                logger.error(f'Full output: {result.stdout}')
                
                if attempt < self.max_retries - 1:
                    import time
                    time.sleep(self.retry_delay)
                    continue
                
                return {
                    'error': error_msg,
                    'raw_output': result.stdout
                }
                
            except subprocess.TimeoutExpired as e:
                error_msg = f'Docker exec timed out (attempt {attempt + 1}/{self.max_retries}): {str(e)}'
                logger.error(error_msg)
                
                if attempt < self.max_retries - 1:
                    import time
                    time.sleep(self.retry_delay)
                    continue
                
                return {
                    'error': error_msg
                }
                
            except Exception as e:
                error_msg = f'Unexpected error (attempt {attempt + 1}/{self.max_retries}): {str(e)}'
                logger.error(error_msg)
                
                if attempt < self.max_retries - 1:
                    import time
                    time.sleep(self.retry_delay)
                    continue
                
                return {
                    'error': error_msg
                }
        
        # If we exhausted all retries
        return {
            'error': f'Failed after {self.max_retries} attempts'
        }

@app.route('/api/search', methods=['POST'])
def search():
    """
    Search endpoint for SearXNG MCP
    
    Expected JSON body:
    {
        "query": "search term",
        "categories": "general",  # optional
        "language": "en",        # optional
        "pageno": 1,             # optional
        "num_results": 10        # optional
    }
    """
    wrapper = SearxngMcpHttpWrapper()
    
    try:
        # Validate content type
        if not request.is_json:
            logger.warn('Non-JSON request received')
            return jsonify({'error': 'Content-Type must be application/json'}), 415
        
        data = request.get_json()
        logger.info(f'Received search request: {json.dumps(data, indent=2)}')
        
        # Validate required parameter
        if not data or 'query' not in data or not data['query']:
            logger.warn('Missing query parameter')
            return jsonify({'error': 'Missing required parameter: query'}), 400
        
        # Build MCP request
        mcp_request = {
            'tool': 'searxng_search',
            'params': {
                'q': data['query'],
                'categories': data.get('categories', 'general'),
                'language': data.get('language', 'en'),
                'pageno': data.get('pageno', 1),
                'num_results': data.get('num_results', 10)
            }
        }
        
        logger.info(f'Built MCP request: {json.dumps(mcp_request, indent=2)}')
        
        # Execute MCP command
        result = wrapper.execute_mcp_command(mcp_request)
        
        logger.info(f'MCP command result: {json.dumps(result, indent=2)}')
        
        # Check for errors
        if 'error' in result:
            logger.error(f'MCP error: {result["error"]}')
            return jsonify({'error': result['error']}), 500
        
        # Add some metadata to the response
        response = {
            'success': True,
            'query': data['query'],
            'timestamp': json.dumps(None),  # Will be replaced by Flask
            'mcp_response': result
        }
        
        return jsonify(response)
        
    except Exception as e:
        error_msg = f'HTTP wrapper error: {str(e)}'
        logger.error(error_msg, exc_info=True)
        return jsonify({'error': error_msg}), 500

@app.route('/health', methods=['GET'])
def health():
    """
    Health check endpoint
    """
    try:
        # Test if we can communicate with the MCP container
        wrapper = SearxngMcpHttpWrapper()
        
        # Simple test request
        test_request = {
            'tool': 'searxng_search',
            'params': {
                'q': 'test'
            }
        }
        
        result = wrapper.execute_mcp_command(test_request)
        
        if 'error' in result:
            return jsonify({
                'status': 'degraded',
                'service': 'searxng-mcp-http-wrapper',
                'mcp_status': 'unhealthy',
                'error': result['error']
            }), 503
        
        return jsonify({
            'status': 'healthy',
            'service': 'searxng-mcp-http-wrapper',
            'mcp_status': 'healthy',
            'version': '1.0.0'
        })
        
    except Exception as e:
        logger.error(f'Health check failed: {str(e)}', exc_info=True)
        return jsonify({
            'status': 'unhealthy',
            'service': 'searxng-mcp-http-wrapper',
            'error': str(e)
        }), 500

@app.route('/info', methods=['GET'])
def info():
    """
    Info endpoint - provides information about the service
    """
    return jsonify({
        'service': 'SearXNG MCP HTTP Wrapper',
        'version': '1.0.0',
        'description': 'HTTP interface for SearXNG MCP server',
        'endpoints': {
            '/api/search': {
                'method': 'POST',
                'description': 'Perform a search using SearXNG MCP',
                'parameters': {
                    'query': 'Search query (required)',
                    'categories': 'Search categories (optional, default: general)',
                    'language': 'Language filter (optional, default: en)',
                    'pageno': 'Page number (optional, default: 1)',
                    'num_results': 'Results per page (optional, default: 10)'
                }
            },
            '/health': {
                'method': 'GET',
                'description': 'Health check endpoint'
            },
            '/info': {
                'method': 'GET',
                'description': 'Service information endpoint'
            }
        },
        'mcp_container': os.environ.get('SEARXNG_MCP_CONTAINER', 'searxng-mcp')
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f'Internal server error: {str(error)}', exc_info=True)
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    logger.info('Starting SearXNG MCP HTTP Wrapper...')
    logger.info(f'MCP Container: {os.environ.get("SEARXNG_MCP_CONTAINER", "searxng-mcp")}')
    logger.info('Listening on 0.0.0.0:5000')
    
    # Start the Flask application
    app.run(host='0.0.0.0', port=5000, debug=False)