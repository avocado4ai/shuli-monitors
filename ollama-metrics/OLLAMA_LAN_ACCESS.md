# Ollama LAN Access Guide

**Server**: shuli
**LAN IP**: 192.168.1.118
**Port**: 11434
**Status**: ✅ Listening on all interfaces (*:11434)

---

## Quick Access URLs

From any machine on your LAN, Ollama is accessible at:

- **By IP**: `http://192.168.1.118:11434`
- **By Hostname**: `http://shuli:11434`
- **Localhost** (on shuli): `http://localhost:11434`

---

## Command Line Examples

### 1. Check Ollama Version
```bash
curl http://192.168.1.118:11434/api/version
```

**Expected Output**:
```json
{"version":"0.11.4"}
```

---

### 2. List Available Models
```bash
curl http://192.168.1.118:11434/api/tags | jq .
```

**Expected Output**: JSON list of 22 models including qwen3, deepseek-r1, llama3, etc.

---

### 3. Check Running Models
```bash
curl http://192.168.1.118:11434/api/ps | jq .
```

---

### 4. Generate Text (Simple)
```bash
curl -X POST http://192.168.1.118:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:latest",
    "prompt": "Why is the sky blue?",
    "stream": false
  }' | jq -r '.response'
```

---

### 5. Chat Completion
```bash
curl -X POST http://192.168.1.118:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:latest",
    "messages": [
      {"role": "user", "content": "Hello! How are you?"}
    ],
    "stream": false
  }' | jq -r '.message.content'
```

---

### 6. Streaming Response
```bash
curl -X POST http://192.168.1.118:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:latest",
    "messages": [
      {"role": "user", "content": "Write a short poem about coding"}
    ],
    "stream": true
  }'
```

---

### 7. Multi-turn Conversation
```bash
curl -X POST http://192.168.1.118:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:latest",
    "messages": [
      {"role": "user", "content": "What is Python?"},
      {"role": "assistant", "content": "Python is a high-level programming language..."},
      {"role": "user", "content": "What are its main features?"}
    ],
    "stream": false
  }'
```

---

### 8. Generate with Parameters
```bash
curl -X POST http://192.168.1.118:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:latest",
    "prompt": "Explain Docker in simple terms",
    "stream": false,
    "options": {
      "temperature": 0.7,
      "top_p": 0.9,
      "top_k": 40,
      "num_predict": 200
    }
  }'
```

---

### 9. Code Generation (Using Code Model)
```bash
curl -X POST http://192.168.1.118:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b",
    "prompt": "Write a Python function to check if a number is prime",
    "stream": false
  }' | jq -r '.response'
```

---

### 10. Vision Model (with Image)
```bash
# First, encode image to base64
IMAGE_BASE64=$(base64 -w 0 image.jpg)

curl -X POST http://192.168.1.118:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"llava:latest\",
    \"prompt\": \"Describe this image\",
    \"images\": [\"$IMAGE_BASE64\"],
    \"stream\": false
  }" | jq -r '.response'
```

---

## Using Ollama CLI from Remote Machine

### Install Ollama CLI on Remote Machine
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### Set Remote Server
```bash
export OLLAMA_HOST=http://192.168.1.118:11434
```

### Use Ollama CLI
```bash
# List models
ollama list

# Run a model
ollama run qwen3:latest

# Chat interactively
ollama run qwen3:latest "Tell me a joke"

# Show model info
ollama show qwen3:latest

# Check server status
ollama ps
```

### Make OLLAMA_HOST Permanent
Add to `~/.bashrc` or `~/.zshrc`:
```bash
echo 'export OLLAMA_HOST=http://192.168.1.118:11434' >> ~/.bashrc
source ~/.bashrc
```

---

## Python Examples

### Install Python Client
```bash
pip install ollama
```

### Basic Usage
```python
import ollama

# Set server
client = ollama.Client(host='http://192.168.1.118:11434')

# Generate text
response = client.generate(
    model='qwen3:latest',
    prompt='Why is the sky blue?'
)
print(response['response'])

# Chat
messages = [
    {'role': 'user', 'content': 'Hello!'}
]
response = client.chat(model='qwen3:latest', messages=messages)
print(response['message']['content'])

# List models
models = client.list()
for model in models['models']:
    print(f"{model['name']} - {model['size']}")
```

### Streaming Example
```python
import ollama

client = ollama.Client(host='http://192.168.1.118:11434')

stream = client.chat(
    model='qwen3:latest',
    messages=[{'role': 'user', 'content': 'Tell me a story'}],
    stream=True
)

for chunk in stream:
    print(chunk['message']['content'], end='', flush=True)
```

---

## JavaScript/Node.js Examples

### Install Client
```bash
npm install ollama
```

### Basic Usage
```javascript
import { Ollama } from 'ollama';

const ollama = new Ollama({ host: 'http://192.168.1.118:11434' });

// Generate text
const response = await ollama.generate({
  model: 'qwen3:latest',
  prompt: 'Why is the sky blue?',
});
console.log(response.response);

// Chat
const chatResponse = await ollama.chat({
  model: 'qwen3:latest',
  messages: [{ role: 'user', content: 'Hello!' }],
});
console.log(chatResponse.message.content);

// List models
const models = await ollama.list();
console.log(models);
```

---

## Available Models on Server

| Model | Size | Use Case | Command |
|-------|------|----------|---------|
| qwen3:latest | 5.2 GB | General purpose (Currently loaded) | `qwen3:latest` |
| deepseek-r1:14b | 9.0 GB | Reasoning | `deepseek-r1:14b` |
| qwen2.5-coder:7b | 4.7 GB | Code generation | `qwen2.5-coder:7b` |
| deepseek-coder-v2:16b | 8.9 GB | Advanced coding | `deepseek-coder-v2:16b` |
| llava:13b | 8.0 GB | Vision + text | `llava:13b` |
| qwen2.5vl:7b | 6.0 GB | Vision + text | `qwen2.5vl:7b` |
| llama3:latest | 4.7 GB | General purpose | `llama3:latest` |
| mistral:7b | 4.4 GB | General purpose | `mistral:7b` |
| gemma3:12b | 8.1 GB | General purpose | `gemma3:12b` |
| codellama:latest | 3.8 GB | Code generation | `codellama:latest` |

*See OLLAMA_STORAGE_INFO.md for complete list of 22 models*

---

## Firewall Check

Verify port 11434 is accessible:

```bash
# From remote machine, test connectivity
nc -zv 192.168.1.118 11434

# Or use telnet
telnet 192.168.1.118 11434

# Or use curl
curl -v http://192.168.1.118:11434/api/version
```

If connection fails, check firewall on shuli:
```bash
# Check if firewall is active
sudo ufw status

# Allow port 11434 if needed
sudo ufw allow 11434/tcp
```

---

## Health Check from Remote

```bash
# Simple health check
curl -f http://192.168.1.118:11434/api/tags && echo "✅ Ollama is healthy" || echo "❌ Ollama is down"

# Detailed health check
curl -s http://192.168.1.118:11434/api/version && \
curl -s http://192.168.1.118:11434/api/tags > /dev/null && \
echo "✅ Server responding" || echo "❌ Server not responding"
```

---

## Performance Tips

### For Better Response Times:
1. **Model Selection**: Use smaller models for faster responses
   - Fast: `llama3.2:3b`, `stable-code:3b`, `starcoder2:latest`
   - Medium: `qwen3:latest`, `mistral:7b`, `llama3:latest`
   - Large: `deepseek-r1:14b`, `gemma3:12b`, `llava:13b`

2. **Streaming**: Use `"stream": true` for progressive output

3. **Keep Alive**: Models stay in memory for 180 minutes (configurable)

4. **Parallel Requests**: Server supports 2 parallel requests (configured)

---

## API Parameter Reference

### Common Options:
```json
{
  "temperature": 0.7,     // Randomness (0.0-2.0, default: 0.8)
  "top_p": 0.9,          // Nucleus sampling (0.0-1.0)
  "top_k": 40,           // Top-k sampling (1-100)
  "num_predict": 128,    // Max tokens to generate
  "stop": ["\n"],        // Stop sequences
  "repeat_penalty": 1.1, // Penalize repetition (1.0 = no penalty)
  "seed": 42             // Random seed for reproducibility
}
```

### Example with All Options:
```bash
curl -X POST http://192.168.1.118:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:latest",
    "prompt": "Write a haiku about programming",
    "stream": false,
    "options": {
      "temperature": 0.7,
      "top_p": 0.9,
      "top_k": 40,
      "num_predict": 100,
      "repeat_penalty": 1.1,
      "seed": 42
    }
  }'
```

---

## Troubleshooting

### Connection Refused
```bash
# Check if service is running on server
curl http://192.168.1.118:11434/api/version

# If fails, check service on shuli
ssh shuli "systemctl status ollama"
```

### Slow Responses
- Check GPU usage on server: `nvidia-smi`
- Use smaller model
- Enable streaming

### Model Not Found
```bash
# List available models
curl http://192.168.1.118:11434/api/tags | jq -r '.models[].name'
```

### Port Conflict
If you see errors about port 11434:
```bash
# On shuli, check what's using the port
sudo lsof -i :11434
```

---

## Security Considerations

⚠️ **Important**: Ollama has NO built-in authentication!

### Recommendations:
1. **Firewall**: Only allow LAN access
2. **VPN**: Use VPN for remote access
3. **Reverse Proxy**: Add authentication via nginx/apache
4. **Network Segmentation**: Keep on trusted network only

### Example nginx with Basic Auth:
```nginx
server {
    listen 80;
    server_name ollama.local;

    auth_basic "Ollama API";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://192.168.1.118:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Integration Examples

### Use in n8n Workflow
```
HTTP Request Node:
- Method: POST
- URL: http://192.168.1.118:11434/api/chat
- Body:
{
  "model": "qwen3:latest",
  "messages": [{"role": "user", "content": "{{$json.prompt}}"}],
  "stream": false
}
```

### Use in Shell Scripts
```bash
#!/bin/bash
OLLAMA_HOST="http://192.168.1.118:11434"

ask_ollama() {
    local prompt="$1"
    curl -s -X POST "$OLLAMA_HOST/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"qwen3:latest\",\"prompt\":\"$prompt\",\"stream\":false}" \
        | jq -r '.response'
}

# Usage
ask_ollama "What is Docker?"
```

---

## Quick Reference Card

```bash
# Server Details
HOST: 192.168.1.118
PORT: 11434
URL:  http://192.168.1.118:11434

# Test Connection
curl http://192.168.1.118:11434/api/version

# List Models
curl http://192.168.1.118:11434/api/tags

# Quick Chat
curl -X POST http://192.168.1.118:11434/api/chat \
  -d '{"model":"qwen3:latest","messages":[{"role":"user","content":"Hi"}],"stream":false}'

# Set CLI Host
export OLLAMA_HOST=http://192.168.1.118:11434
```

---

**Last Updated**: 2025-11-27 05:55 IST
**Server Status**: ✅ Online and accessible on LAN
