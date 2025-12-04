# Local Testing Guide

Before deploying to GCP, test your application locally to ensure everything works correctly.

## Prerequisites

1. Python 3.8 or higher installed
2. API keys ready:
   - Hugging Face token
   - Groq API key

## Step 1: Set Up Environment

```bash
# Navigate to project directory
cd /path/to/RAG-MEDICAL-CHATBOT

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate
```

## Step 2: Install Dependencies

```bash
# Upgrade pip
pip install --upgrade pip setuptools wheel

# Install requirements
pip install -r requirements.txt
```

## Step 3: Configure Environment Variables

```bash
# Copy example env file
cp env.example .env

# Edit .env file and add your actual API keys
nano .env  # or use your preferred editor
```

Required variables:
- `HF_TOKEN`: Your Hugging Face token
- `GROQ_API_KEY`: Your Groq API key

## Step 4: Verify Vector Store

Check if vector store exists:

```bash
ls -la vectorstore/db_faiss/
```

If vector store doesn't exist or you want to recreate it:

```bash
# Ensure PDF files are in data/ directory
ls data/*.pdf

# Create vector store
python -m app.components.data_loader
```

## Step 5: Test Application

### Option A: Using the Start Script

```bash
# Make script executable (if not already)
chmod +x start.sh

# Start application
./start.sh
```

### Option B: Using Gunicorn Directly

```bash
# Activate virtual environment
source venv/bin/activate

# Start with Gunicorn
gunicorn -w 2 -b 0.0.0.0:5000 app.application:app
```

### Option C: Using Flask Development Server

```bash
# Activate virtual environment
source venv/bin/activate

# Start Flask app
python app/application.py
```

## Step 6: Access Application

Open your browser and navigate to:
- `http://localhost:5000`
- Or `http://127.0.0.1:5000`

## Step 7: Test Functionality

1. **Test Chat Interface**: 
   - Enter a medical question
   - Verify response is generated
   - Check that responses are relevant

2. **Test Error Handling**:
   - Try clearing the chat
   - Test with empty input
   - Verify error messages display correctly

3. **Check Logs**:
   - Monitor console output for errors
   - Check application logs

## Troubleshooting

### Import Errors

If you see import errors related to `langchain_text_splitters`:

```bash
pip install langchain-text-splitters
```

### Vector Store Errors

If vector store fails to load:

```bash
# Recreate vector store
python -m app.components.data_loader
```

### API Key Errors

If you see authentication errors:

1. Verify `.env` file exists and has correct keys
2. Check that keys are not wrapped in quotes
3. Restart the application after updating `.env`

### Port Already in Use

If port 5000 is already in use:

```bash
# Find process using port 5000
lsof -i :5000

# Kill the process
kill -9 PID

# Or use a different port
export FLASK_PORT=5001
./start.sh
```

## Verify Dependencies

Check that all packages are installed correctly:

```bash
python3 -c "import flask; import langchain; import langchain_text_splitters; import langchain_groq; import langchain_huggingface; print('✓ All dependencies installed')"
```

## Next Steps

Once local testing is successful:

1. Review the `GCP_DEPLOYMENT.md` guide
2. Prepare your GCP project
3. Deploy using the provided scripts

## Common Issues

### Issue: "ModuleNotFoundError: No module named 'langchain_text_splitters'"

**Solution**: 
```bash
pip install langchain-text-splitters
```

### Issue: "ModuleNotFoundError: No module named 'langchain.chains'"

**Solution**: 
```bash
pip install langchain-classic
```
The `RetrievalQA` class is now in the `langchain-classic` package.

### Issue: "HF_TOKEN not found"

**Solution**: 
- Check `.env` file exists
- Verify `HF_TOKEN` is set correctly
- Restart application after updating `.env`

### Issue: "Vector store not found"

**Solution**:
```bash
python -m app.components.data_loader
```

### Issue: "Connection timeout" or "API errors"

**Solution**:
- Verify API keys are correct
- Check internet connection
- Verify API service is accessible

### Issue: Metal/MPS errors on macOS (SIGABRT, XPC_ERROR_CONNECTION_INVALID)

**Solution**:
- This is a known issue with Metal Performance Shaders on macOS
- The start script automatically uses single worker on macOS
- GPU/MPS is automatically disabled for compatibility
- If issues persist, run with single worker manually:
  ```bash
  GUNICORN_WORKERS=1 ./start.sh
  ```

