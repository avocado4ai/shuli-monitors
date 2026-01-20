#!/usr/bin/env python3
"""
MCP Server for SearXNG
Wraps the existing SearXNG service and exposes a single MCP tool called searxng_search
"""

import os
import json
import requests
from typing import Dict, Any, List

# MCP Python SDK - using stdio transport
import sys
import json

class MCPServer:
    def __init__(self):
        self.searxng_base = os.environ.get('SEARXNG_BASE', 'http://searxng:8080')
        
    def searxng_search(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Perform a search using SearXNG and return results in MCP format
        
        Args:
            params: Dictionary containing search parameters
                - q (required): Search query
                - format: Always json (default)
                - categories: Optional search categories
                - language: Optional language
                - pageno: Optional page number
                - num_results: Optional number of results per page
        
        Returns:
            Dictionary with results containing only: title, url, content, engine, score
            Max 20 results
        """
        # Validate required parameter
        if 'q' not in params or not params['q']:
            return {
                'error': 'Missing required parameter: q'
            }
        
        # Build query parameters
        search_params = {
            'q': params['q'],
            'format': 'json'
        }
        
        # Add optional parameters if provided
        if 'categories' in params and params['categories']:
            search_params['categories'] = params['categories']
        if 'language' in params and params['language']:
            search_params['language'] = params['language']
        if 'pageno' in params and params['pageno']:
            search_params['pageno'] = params['pageno']
        if 'num_results' in params and params['num_results']:
            search_params['num_results'] = params['num_results']
        
        try:
            # Make request to SearXNG
            response = requests.get(f"{self.searxng_base}/search", params=search_params, timeout=30)
            response.raise_for_status()
            
            # Parse JSON response
            data = response.json()
            
            # Extract and format results
            results = []
            if 'results' in data:
                for result in data['results'][:20]:  # Cap at 20 results
                    formatted_result = {
                        'title': result.get('title', ''),
                        'url': result.get('url', ''),
                        'content': result.get('content', ''),
                        'engine': result.get('engine', ''),
                        'score': result.get('score', 0)
                    }
                    results.append(formatted_result)
            
            return {
                'success': True,
                'query': params['q'],
                'results': results,
                'total_results': len(results)
            }
            
        except requests.exceptions.RequestException as e:
            return {
                'error': f'Request failed: {str(e)}'
            }
        except json.JSONDecodeError as e:
            return {
                'error': f'JSON decode error: {str(e)}'
            }
        except Exception as e:
            return {
                'error': f'Unexpected error: {str(e)}'
            }
    
    def handle_mcp_request(self):
        """
        Handle MCP requests using stdio transport
        """
        while True:
            try:
                # Read MCP request from stdin
                request_data = sys.stdin.readline().strip()
                if not request_data:
                    continue
                    
                # Parse JSON request
                request = json.loads(request_data)
                
                # Handle the searxng_search tool
                if request.get('tool') == 'searxng_search':
                    result = self.searxng_search(request.get('params', {}))
                    
                    # Send response to stdout
                    response = {
                        'tool': 'searxng_search',
                        'result': result
                    }
                    print(json.dumps(response))
                    sys.stdout.flush()
                else:
                    # Unknown tool
                    error_response = {
                        'error': f'Unknown tool: {request.get("tool", "unknown")}'
                    }
                    print(json.dumps(error_response))
                    sys.stdout.flush()
                    
            except json.JSONDecodeError:
                error_response = {
                    'error': 'Invalid JSON request'
                }
                print(json.dumps(error_response))
                sys.stdout.flush()
            except Exception as e:
                error_response = {
                    'error': f'Server error: {str(e)}'
                }
                print(json.dumps(error_response))
                sys.stdout.flush()

if __name__ == '__main__':
    server = MCPServer()
    print("SearXNG MCP Server started...")
    print("Listening for MCP requests on stdin...")
    print("Available tool: searxng_search")
    sys.stdout.flush()
    
    server.handle_mcp_request()