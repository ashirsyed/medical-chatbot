#!/bin/bash

# RAG Medical Chatbot - Start Script
# This script starts the Flask application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}RAG Medical Chatbot - Start Script${NC}"
echo -e "${GREEN}=========================================${NC}"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${RED}Error: Virtual environment not found!${NC}"
    echo -e "${YELLOW}Please run ./deploy.sh first to set up the environment.${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "${YELLOW}Please create .env file with required environment variables.${NC}"
    echo -e "${YELLOW}You can copy env.example to .env and update it.${NC}"
    exit 1
fi

# Activate virtual environment
echo -e "${GREEN}Activating virtual environment...${NC}"
source venv/bin/activate

# Check if gunicorn is installed
if ! command -v gunicorn &> /dev/null; then
    echo -e "${YELLOW}Gunicorn not found. Installing...${NC}"
    pip install gunicorn
fi

# Check if vectorstore exists
if [ ! -d "vectorstore/db_faiss" ]; then
    echo -e "${YELLOW}Warning: Vector store not found!${NC}"
    echo -e "${YELLOW}The application may not work correctly without a vector store.${NC}"
    echo -e "${YELLOW}Run: python -m app.components.data_loader to create it.${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get host and port from environment or use defaults
HOST=${FLASK_HOST:-0.0.0.0}
PORT=${FLASK_PORT:-5000}

# Detect macOS and adjust workers (Metal/MPS has issues with multiprocessing)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use single worker to avoid Metal/MPS multiprocessing issues
    WORKERS=${GUNICORN_WORKERS:-1}
    echo -e "${YELLOW}macOS detected: Using single worker to avoid Metal/MPS issues${NC}"
    # Disable Metal Performance Shaders
    export PYTORCH_ENABLE_MPS_FALLBACK=1
    export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
else
    WORKERS=${GUNICORN_WORKERS:-2}
fi

# Disable GPU/MPS for sentence-transformers
export CUDA_VISIBLE_DEVICES=""
export PYTORCH_ENABLE_MPS_FALLBACK=1

echo -e "${GREEN}Starting application...${NC}"
echo -e "${GREEN}Host: ${HOST}${NC}"
echo -e "${GREEN}Port: ${PORT}${NC}"
echo -e "${GREEN}Workers: ${WORKERS}${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the application${NC}"
echo ""

# Start the application with Gunicorn
exec gunicorn \
    --bind "${HOST}:${PORT}" \
    --workers "${WORKERS}" \
    --timeout 120 \
    --access-logfile - \
    --error-logfile - \
    --log-level info \
    app.application:app

