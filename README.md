# CPU-LLM-Docker

> **Production-ready, self-provisioning LLM API for CPU-only environments.**

Deploys **Qwen 3 (4B)** with **6-bit quantization (XL)** for optimal CPU accuracy/speed balance (fully configurable via `.env`). Includes a secure Nginx sidecar for authentication and connects to an external `proxy` network for instant reverse proxy integration.

## 🚀 Quick Start

**1. Setup**
```bash
cp .env.example .env
cp compose.example.yaml compose.yml
```

**2. Configure**

Edit `.env` to set your `SERVICE_DOMAIN` and `API_SECRET_KEY`.

Configure your proxy network in compose.yaml.
```yaml
# E.g. Caddy / Reverse Proxy Integration
labels:
   caddy_0: ${SERVICE_DOMAIN}
   caddy_0.reverse_proxy: "{{upstreams 80}}"
```

**3. Deploy**

```bash
docker compose up -d
# Monitor auto-provisioning (Model download ~3.7 GB)
docker compose logs -f llm-api
```

## 🔌 API Usage

Standard OpenAI-compatible endpoint protected by Bearer Token.

```bash
curl [https://ai.your-domain.com/api/chat](https://ai.your-domain.com/api/chat) \
  -H "Authorization: Bearer <YOUR_SECRET_KEY>" \
  -d '{
    "model": "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:Q6_K_XL",
    "messages": [
      { "role": "user", "content": "Extract JSON from this text..." }
    ],
    "stream": false
  }'
```

## ⚙️ Configuration

| Variable | Description |
| --- | --- |
| `API_SECRET_KEY` | **Required.** Bearer token for access. |
| `AI_MODEL_NAME` | Defaults to `Q6_K_XL` |
| `PRELOAD_MODEL` | Keeps model in RAM for instant responses (`true`). |
