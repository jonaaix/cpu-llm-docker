#!/bin/bash
set -e

# --- FIX: CURL INSTALLATION ---
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    apt-get update && apt-get install -y curl
fi
# ------------------------------

SERVER_PID=0

cleanup() {
    echo "Stopping Ollama..."
    if [ $SERVER_PID -ne 0 ]; then
        kill -SIGTERM "$SERVER_PID"
        wait "$SERVER_PID"
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT

echo "Starting Ollama Server..."
/bin/ollama serve &
SERVER_PID=$!

echo "Waiting for Ollama API..."
until curl -s http://localhost:11434/api/tags >/dev/null; do
    sleep 2
done
echo "Ollama API ready."

if [ -n "$MODEL_NAME" ]; then
    if curl -s http://localhost:11434/api/tags | grep -q "\"$MODEL_NAME\""; then
        echo "Model '$MODEL_NAME' exists."
    else
        echo "Pulling model '$MODEL_NAME'..."
        /bin/ollama pull "$MODEL_NAME"
    fi

    if [ "$PRELOAD_MODEL" = "true" ]; then
        echo "Pre-loading model..."
        curl -s -X POST http://localhost:11434/api/generate -d "{\"model\": \"$MODEL_NAME\", \"prompt\": \"\", \"keep_alive\": -1}" >/dev/null
    fi
fi

wait "$SERVER_PID"
