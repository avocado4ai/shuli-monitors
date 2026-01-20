# NVIDIA GPU Exporter

This service exposes NVIDIA GPU metrics in Prometheus format using the utkuozdemir/nvidia_gpu_exporter, which leverages nvidia-smi to gather metrics.

## Configuration

- Port: 9835
- Metrics endpoint: http://localhost:9835/metrics
- Containerized with proper GPU access via Docker

## Metrics

The exporter provides various GPU metrics including:
- GPU utilization
- Memory utilization
- Temperature
- Power usage
- Clock speeds
- Memory usage
- Performance state
- Processes using GPU
- And many more auto-discovered metrics from nvidia-smi

## Requirements

- NVIDIA GPU(s)
- NVIDIA drivers installed
- nvidia-docker2 package
- Docker with nvidia runtime configured

## Usage

The service runs in the background and exposes metrics that can be scraped by Prometheus or viewed directly at the metrics endpoint.