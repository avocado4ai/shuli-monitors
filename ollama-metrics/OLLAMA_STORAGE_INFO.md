# Ollama Storage and Configuration Information

**Last Updated**: 2025-11-27 05:27 IST

## System Overview

- **Ollama Version**: 0.11.4
- **Service Status**: Active (systemd service)
- **Port**: 11434 (listening on 0.0.0.0)
- **User**: ollama
- **Auto-start**: Enabled

---

## Model Storage Location

### Primary Storage Directory
```
/usr/share/ollama/.ollama/models/
```

**Total Storage Used**: **104 GB**

### Directory Structure

```
/usr/share/ollama/.ollama/
├── id_ed25519          (SSH key for registry auth)
├── id_ed25519.pub      (SSH public key)
└── models/             (104 GB total)
    ├── blobs/          (Model binary files - 99 files)
    │   └── sha256-*    (GGUF model weights, configs, embeddings)
    └── manifests/      (Model metadata)
        └── registry.ollama.ai/
            └── library/
                ├── codellama/
                ├── deepseek-coder-v2/
                ├── deepseek-r1/
                ├── gemma3/
                ├── gpt-oss/
                ├── granite3.2/
                ├── llama3/
                ├── llama3.2/
                ├── llama3-groq-tool-use/
                ├── llava/
                ├── mistral/
                ├── nomic-embed-text/
                ├── qwen2.5-coder/
                ├── qwen2.5vl/
                ├── qwen3/
                ├── stable-code/
                ├── starcoder2/
                └── starling-lm/
```

---

## How Storage Works

### 1. Blobs Directory
**Location**: `/usr/share/ollama/.ollama/models/blobs/`

- Contains **99 files** stored by SHA256 hash
- Actual model weights in GGUF format
- Model configurations and embeddings
- **Deduplication**: Shared layers between models stored only once
- File sizes:
  - Large files (1-4 GB): Model weights
  - Small files (few KB): Configs and metadata

### 2. Manifests Directory
**Location**: `/usr/share/ollama/.ollama/models/manifests/`

- Model metadata for each installed model
- Points to blob files needed for each model
- Organized by model name and version

### 3. Temporary/Runtime
**Location**: `/tmp/ollama/`

- Runner processes (configured in systemd override)
- Temporary files during model loading
- CUDA cache: `/tmp/cuda-cache`

---

## Installed Models (22 Total)

| Model Name | Size | Parameters | Quantization | Modified |
|------------|------|------------|--------------|----------|
| qwen3:latest | 5.2 GB | 8.2B | Q4_K_M | 2025-11-27 (Active) |
| deepseek-r1:14b | 9.0 GB | 14.8B | Q4_K_M | 3 months ago |
| qwen3:14b | 9.3 GB | 14.8B | Q4_K_M | 3 months ago |
| qwen2.5-coder:7b | 4.7 GB | 7.6B | Q4_K_M | 3 months ago |
| deepseek-coder-v2:16b | 8.9 GB | 15.7B | Q4_0 | 3 months ago |
| llava:13b | 8.0 GB | 13B | Q4_0 | 3 weeks ago |
| qwen2.5vl:7b | 6.0 GB | 8.3B | Q4_K_M | 7 weeks ago |
| gemma3:12b | 8.1 GB | 12.2B | Q4_K_M | 3 months ago |
| granite3.2:8b | 4.9 GB | 8.2B | Q4_K_M | 2 months ago |
| llava:latest | 4.7 GB | 7B | Q4_0 | 2 months ago |
| llama3:latest | 4.7 GB | 8.0B | Q4_0 | 2 months ago |
| llama3.2:3b | 2.0 GB | 3.2B | Q4_K_M | 2 months ago |
| llama3-groq-tool-use:latest | 4.7 GB | 8.0B | Q4_0 | 3 months ago |
| mistral:7b | 4.4 GB | 7.2B | Q4_K_M | 3 months ago |
| codellama:latest | 3.8 GB | 7B | Q4_0 | 2 months ago |
| starling-lm:latest | 4.1 GB | 7B | Q4_0 | 2 months ago |
| gpt-oss:latest | 13 GB | 20.9B | MXFP4 | 3 months ago |
| stable-code:3b | 1.6 GB | 3B | Q4_0 | 3 months ago |
| starcoder2:latest | 1.7 GB | 3B | Q4_0 | 3 months ago |
| bge-m3:latest | 1.2 GB | 566.70M | F16 | 3 months ago |
| nomic-embed-text:latest | 274 MB | 137M | F16 | 2 weeks ago |
| nomic-embed-text:v1.5 | 274 MB | 137M | F16 | 3 months ago |

### Currently Loaded in Memory
- **Model**: qwen3:latest (8.2B parameters)
- **VRAM Usage**: 7.5 GB
- **Context Length**: 4096 tokens
- **Expires**: 2025-11-27 08:32:37 (3h idle timeout)

---

## GPU Configuration

### Hardware
- **GPU**: NVIDIA GeForce RTX 5070 Ti
- **Total VRAM**: 16 GB (16,303 MiB)
- **Used VRAM**: 6,453 MiB (~40%)
- **Free VRAM**: 9,379 MiB (~58%)
- **GPU Utilization**: 0% (idle, model in memory)

### Optimization Settings
From `/etc/systemd/system/ollama.service.d/override.conf`:

```bash
# GPU Optimization for RTX 5070 Ti (16GB VRAM)
CUDA_VISIBLE_DEVICES=0
OLLAMA_GPU_OVERHEAD=0.2
OLLAMA_VRAM_THRESHOLD=155000
OLLAMA_MAX_LOADED_MODELS=3
OLLAMA_MAX_VRAM=155000
OLLAMA_NUM_PARALLEL=2

# Performance optimization
OLLAMA_FLASH_ATTENTION=1
OLLAMA_KV_CACHE_TYPE=f16
OLLAMA_KEEP_ALIVE=180m

# CUDA optimization
CUDA_CACHE_PATH=/tmp/cuda-cache
CUDA_LAUNCH_BLOCKING=0
CUDA_DEVICE_ORDER=PCI_BUS_ID
CUDA_DEVICE_MAX_CONNECTIONS=4
```

### Model Loading
- **GPU Layers**: 41 layers offloaded to GPU
- **Threads**: 8
- **Batch Size**: 512
- **Context Size**: 8192
- **Parallel Requests**: 2

---

## Disk Storage Summary

### System Disk
- **Device**: /dev/mapper/ubuntu--2T--disk-ubuntu--lv
- **Total**: 1.8 TB
- **Used**: 887 GB (52%)
- **Available**: 821 GB
- **Ollama Models**: 104 GB (~12% of used space)

---

## Service Configuration

### Systemd Service
**File**: `/etc/systemd/system/ollama.service`

```ini
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"

[Install]
WantedBy=default.target
```

### Service Override
**File**: `/etc/systemd/system/ollama.service.d/override.conf`

- External access enabled (0.0.0.0:11434)
- GPU optimizations for RTX 5070 Ti
- Performance tuning for large models
- CUDA optimizations

---

## API Endpoints

### Base URL
```
http://localhost:11434
```

### Available Endpoints
- `GET /api/version` - Get Ollama version
- `GET /api/tags` - List all models
- `GET /api/ps` - List running models
- `POST /api/generate` - Generate text
- `POST /api/chat` - Chat completion
- `POST /api/pull` - Download a model
- `POST /api/push` - Upload a model
- `DELETE /api/delete` - Delete a model

### Example Usage
```bash
# List models
curl http://localhost:11434/api/tags

# Generate text
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "qwen3:latest",
  "prompt": "Why is the sky blue?",
  "stream": false
}'

# Chat
curl -X POST http://localhost:11434/api/chat -d '{
  "model": "qwen3:latest",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ]
}'
```

---

## Docker Configuration Note

The Docker Compose file in this directory (`docker-compose.yml`) defines an Ollama container, but it's currently **disabled** (profile-based start, restart: "no").

**Actual Setup**: Ollama runs as a **systemd service** directly on the host (not in Docker) to optimize GPU access and performance.

### Docker Volume (Not Used)
- Volume defined: `ollama_data:/root/.ollama`
- Not currently in use (service runs on host)

---

## Management Commands

### Service Control
```bash
# Check status
systemctl status ollama

# Start/stop/restart
sudo systemctl start ollama
sudo systemctl stop ollama
sudo systemctl restart ollama

# Enable/disable auto-start
sudo systemctl enable ollama
sudo systemctl disable ollama

# View logs
journalctl -u ollama -f
```

### Model Management
```bash
# List models
ollama list

# Pull a new model
ollama pull llama3:latest

# Remove a model
ollama rm llama3:latest

# Show model info
ollama show llama3:latest

# Run a model interactively
ollama run llama3:latest
```

### Storage Management
```bash
# Check total storage
du -sh /usr/share/ollama/.ollama/models/

# Count model files
find /usr/share/ollama/.ollama/models/blobs/ -type f | wc -l

# List largest files
sudo find /usr/share/ollama/.ollama/models/blobs/ -type f -exec ls -lh {} \; | sort -k5 -hr | head -20
```

---

## Recent Activity

### API Requests
Recent requests from Docker container (172.24.0.15):
- Chat completions: ✓
- Model listings: ✓
- Version checks: ✓
- Process status: ✓

### Service Health
- **Uptime**: ~2 hours
- **Memory**: 9.2 GB
- **CPU**: 9.5s total
- **Tasks**: 25 active
- **Status**: Healthy and responding

---

## Troubleshooting

### Port Already in Use
If you see "port 11434 already in use":
```bash
# Find process using port
sudo lsof -i :11434

# Check if systemd service is running
systemctl status ollama

# Stop the service if needed
sudo systemctl stop ollama
```

### Model Not Loading
```bash
# Check available VRAM
nvidia-smi

# Check service logs
journalctl -u ollama -n 100

# Restart service
sudo systemctl restart ollama
```

### Storage Issues
```bash
# Check disk space
df -h /usr/share/ollama

# Clean up old models
ollama rm <model-name>

# Check blob deduplication
find /usr/share/ollama/.ollama/models/blobs/ -type f -links +1
```

---

## Additional Resources

- Official Ollama Docs: https://github.com/ollama/ollama/tree/main/docs
- Model Library: https://ollama.com/library
- API Reference: https://github.com/ollama/ollama/blob/main/docs/api.md
- GPU Optimization: https://github.com/ollama/ollama/blob/main/docs/gpu.md
