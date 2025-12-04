# Quick Start Deployment Guide

## 🚀 Quick Reference

### Local Testing (First)

1. **Set up environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Configure .env:**
   ```bash
   cp env.example .env
   # Edit .env and add your API keys
   ```

3. **Test locally:**
   ```bash
   ./start.sh
   # Or: python app/application.py
   ```

4. **Access:** `http://localhost:5000`

### GCP Deployment

1. **Create VM in GCP Console:**
   - Machine type: `e2-medium` (or higher)
   - OS: Debian 12
   - Enable HTTP/HTTPS traffic
   - Create firewall rule for port 5000

2. **SSH into VM:**
   ```bash
   gcloud compute ssh YOUR_VM_NAME --zone=YOUR_ZONE
   ```

3. **Deploy:**
   ```bash
   # Clone or upload your code
   git clone YOUR_REPO
   cd RAG-MEDICAL-CHATBOT
   
   # Run deployment
   chmod +x deploy.sh start.sh
   ./deploy.sh
   ```

4. **Start application:**
   ```bash
   ./start.sh
   ```

5. **Access:** `http://YOUR_VM_EXTERNAL_IP:5000`

## 📋 Required Environment Variables

Create `.env` file with:

```env
HF_TOKEN=your_huggingface_token
GROQ_API_KEY=your_groq_api_key
```

## 🔧 Scripts

- **`deploy.sh`**: Sets up environment, installs dependencies
- **`start.sh`**: Starts the application with Gunicorn

## 📚 Full Documentation

- **Local Testing**: See `LOCAL_TESTING.md`
- **GCP Deployment**: See `GCP_DEPLOYMENT.md`

## ⚠️ Important Notes

1. **Firewall**: Must allow port 5000 on GCP VM
2. **Vector Store**: Ensure `vectorstore/db_faiss/` exists or run data loader
3. **API Keys**: Never commit `.env` file to Git
4. **Python Version**: Requires Python 3.8+

## 🆘 Troubleshooting

- **Port in use**: Change `FLASK_PORT` in `.env` or kill process
- **Import errors**: Run `pip install -r requirements.txt` again
- **Vector store missing**: Run `python -m app.components.data_loader`

