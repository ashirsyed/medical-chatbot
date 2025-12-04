#!/bin/bash

# RAG Medical Chatbot - Deployment Script
# This script sets up the application environment on a fresh VM

set -e  # Exit on any error

echo "========================================="
echo "RAG Medical Chatbot - Deployment Script"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${GREEN}Current directory: $(pwd)${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Warning: .env file not found!${NC}"
    echo -e "${YELLOW}Creating .env from env.example...${NC}"
    if [ -f env.example ]; then
        cp env.example .env
        echo -e "${RED}Please edit .env file and add your API keys before continuing!${NC}"
        echo -e "${RED}Required keys: HF_TOKEN, GROQ_API_KEY${NC}"
        read -p "Press Enter after you've updated .env file..."
    else
        echo -e "${RED}Error: env.example not found. Please create .env file manually.${NC}"
        exit 1
    fi
fi

# Check Python version
echo -e "${GREEN}Checking Python version...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 is not installed. Please install Python 3.8 or higher.${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo -e "${GREEN}Python version: $(python3 --version)${NC}"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${GREEN}Creating virtual environment...${NC}"
    python3 -m venv venv
else
    echo -e "${GREEN}Virtual environment already exists.${NC}"
fi

# Activate virtual environment
echo -e "${GREEN}Activating virtual environment...${NC}"
source venv/bin/activate

# Upgrade pip
echo -e "${GREEN}Upgrading pip...${NC}"
pip install --upgrade pip setuptools wheel

# Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
pip install -r requirements.txt

# Check if vectorstore exists
if [ ! -d "vectorstore/db_faiss" ]; then
    echo -e "${YELLOW}Warning: Vector store not found!${NC}"
    echo -e "${YELLOW}Checking if data directory exists...${NC}"
    if [ -d "data" ] && [ "$(ls -A data/*.pdf 2>/dev/null)" ]; then
        echo -e "${GREEN}PDF files found. Creating vector store...${NC}"
        python -m app.components.data_loader
    else
        echo -e "${YELLOW}No PDF files found in data/ directory.${NC}"
        echo -e "${YELLOW}Vector store will be created on first run if data is available.${NC}"
    fi
else
    echo -e "${GREEN}Vector store found.${NC}"
fi

# Verify installation
echo -e "${GREEN}Verifying installation...${NC}"
python3 -c "import flask; import langchain; print('✓ Core dependencies installed')" || {
    echo -e "${RED}Error: Installation verification failed!${NC}"
    exit 1
}

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Ensure your .env file has correct API keys"
echo "2. Run './start.sh' to start the application"
echo "3. Or use: source venv/bin/activate && gunicorn -w 2 -b 0.0.0.0:5000 app.application:app"
echo ""

