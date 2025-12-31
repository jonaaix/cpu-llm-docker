#!/bin/bash
# -----------------------------------------------------------------------------
# Ollama Auto-Provisioning Entrypoint
# -----------------------------------------------------------------------------

set -e

# Process ID variable for graceful shutdown
SERVER_PID=0

# Handler for SIGTERM/SIGINT
cleanup() {
    echo "[Entrypoint] Received shutdown signal. Stopping Ollama server..."
    if [ $SERVER_PID -ne 0 ]; then
        kill -SIGTERM "$SERVER_PID"
        wait "$SERVER_PID"
    fi
    echo "[Entrypoint] Shutdown complete."
    exit 0
}

# Trap system signals
trap cleanup SIGTERM SIGINT

echo "[Entrypoint] Starting Ollama Server..."
/bin/ollama serve &
SERVER_PID=$!

echo "[Entrypoint] Waiting for Ollama API socket..."
# Loop until the server responds
until curl -s http://localhost:11434/api/tags >/dev/null; do
    sleep 2
done
echo "[Entrypoint] Ollama API is active."

# -----------------------------------------------------------------------------
# MODEL PROVISIONING
# -----------------------------------------------------------------------------
if [ -n "$MODEL_NAME" ]; then
    echo "[Entrypoint] Verifying model availability: $MODEL_NAME"

    # Check if model exists in local registry
    if curl -s http://localhost:11434/api/tags | grep -q "\"$MODEL_NAME\""; then
        echo "[Entrypoint] Model '$MODEL_NAME' is already cached. Skipping pull."
    else
        echo "[Entrypoint] Model '$MODEL_NAME' not found. Initiating download..."
        echo "[Entrypoint] NOTE: This depends on internet speed and CPU decompression."

        if /bin/ollama pull "$MODEL_NAME"; then
            echo "[Entrypoint] Successfully pulled model."
        else
            echo "[Entrypoint] ERROR: Failed to pull model '$MODEL_NAME'. Check network/tag."
        fi
    fi

    # Optional: Warm-up
    if [ "$PRELOAD_MODEL" = "true" ]; then
        echo "[Entrypoint] Pre-loading model into RAM..."
        curl -s -X POST http://localhost:11434/api/generate \
            -d "{\"model\": \"$MODEL_NAME\", \"prompt\": \"\", \"keep_alive\": -1}" >/dev/null
        echo "[Entrypoint] Model pre-loaded."
    fi
fi

# Keep script running to monitor child process
wait "$SERVER_PID"
