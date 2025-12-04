# GCP VM Deployment Guide

This guide will walk you through deploying the RAG Medical Chatbot to a Google Cloud Platform (GCP) Virtual Machine.

## Prerequisites

1. **Google Cloud Account**: You need a GCP account with billing enabled
2. **Google Cloud SDK**: Install `gcloud` CLI (optional, but recommended)
3. **API Keys**: 
   - Hugging Face token: https://huggingface.co/settings/tokens
   - Groq API key: https://console.groq.com/keys

## Step 1: Create GCP Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click on the project dropdown at the top
3. Click "New Project"
4. Enter project name (e.g., "rag-medical-chatbot")
5. Click "Create"
6. Wait for the project to be created and select it

## Step 2: Enable Required APIs

1. Navigate to **APIs & Services** > **Library**
2. Search for and enable the following APIs:
   - **Compute Engine API**
   - **Cloud Resource Manager API**

## Step 3: Create VM Instance

### Using Google Cloud Console:

1. Navigate to **Compute Engine** > **VM instances**
2. Click **"Create Instance"**

### VM Configuration:

**Basic Settings:**
- **Name**: `rag-chatbot-vm` (or your preferred name)
- **Region**: Choose closest to you (e.g., `us-central1`, `us-east1`)
- **Zone**: Select any zone in your chosen region

**Machine Configuration:**
- **Machine family**: General-purpose
- **Machine type**: 
  - **Recommended**: `e2-medium` (2 vCPU, 4 GB RAM) - Good for testing
  - **For production**: `e2-standard-4` (4 vCPU, 16 GB RAM) or higher
  - **Budget option**: `e2-small` (2 vCPU, 2 GB RAM) - Minimum recommended

**Boot Disk:**
- **Operating System**: Debian
- **Version**: Debian 12 (Bookworm) or Debian 11 (Bullseye)
- **Boot disk type**: Standard persistent disk
- **Size**: 30 GB (minimum) - 50 GB recommended

**Firewall:**
- ✅ **Allow HTTP traffic** (enables port 80)
- ✅ **Allow HTTPS traffic** (enables port 443)
- ⚠️ **Note**: We'll also need to allow port 5000 for Flask

**Advanced Options (Optional):**
- Under **Networking**, you can add network tags: `http-server`, `flask-app`

Click **"Create"** and wait for the VM to be created (1-2 minutes).

## Step 4: Configure Firewall Rules

We need to allow traffic on port 5000 for the Flask application.

### Option A: Using Google Cloud Console

1. Navigate to **VPC network** > **Firewall**
2. Click **"Create Firewall Rule"**
3. Configure:
   - **Name**: `allow-flask-5000`
   - **Direction**: Ingress
   - **Targets**: Specified target tags
   - **Target tags**: `flask-app` (or leave blank for all instances)
   - **Source IP ranges**: `0.0.0.0/0` (or restrict to your IP for security)
   - **Protocols and ports**: 
     - Select **TCP**
     - Enter **5000**
4. Click **"Create"**

### Option B: Using gcloud CLI

```bash
gcloud compute firewall-rules create allow-flask-5000 \
    --allow tcp:5000 \
    --source-ranges 0.0.0.0/0 \
    --target-tags flask-app \
    --description "Allow Flask app on port 5000"
```

**Security Note**: For production, restrict `--source-ranges` to specific IP addresses or use a load balancer.

## Step 5: Connect to VM

### Using Google Cloud Console:

1. Go to **Compute Engine** > **VM instances**
2. Find your VM instance
3. Click **"SSH"** button (opens browser-based SSH)

### Using gcloud CLI:

```bash
gcloud compute ssh rag-chatbot-vm --zone=YOUR_ZONE
```

Replace `YOUR_ZONE` with your VM's zone (e.g., `us-central1-a`).

## Step 6: Set Up VM Environment

Once connected to the VM via SSH, run the following commands:

```bash
# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Python 3 and pip
sudo apt-get install -y python3 python3-pip python3-venv git

# Install build dependencies (needed for some Python packages)
sudo apt-get install -y build-essential

# Verify Python installation
python3 --version
pip3 --version
```

## Step 7: Deploy Application Code

### Option A: Using Git (Recommended)

If your code is in a Git repository:

```bash
# Clone your repository
git clone YOUR_REPO_URL
cd RAG-MEDICAL-CHATBOT

# Or if using SSH
git clone git@github.com:YOUR_USERNAME/YOUR_REPO.git
cd RAG-MEDICAL-CHATBOT
```

### Option B: Using SCP (Local to VM)

From your local machine:

```bash
# Create a tarball of your project
cd /path/to/RAG-MEDICAL-CHATBOT
tar -czf rag-chatbot.tar.gz --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' .

# Copy to VM
gcloud compute scp rag-chatbot.tar.gz rag-chatbot-vm:~/ --zone=YOUR_ZONE

# On VM, extract
ssh rag-chatbot-vm
tar -xzf rag-chatbot.tar.gz
cd RAG-MEDICAL-CHATBOT
```

### Option C: Using Cloud Storage

1. Upload your code to Google Cloud Storage
2. Download it on the VM using `gsutil`

## Step 8: Configure Environment Variables

On the VM:

```bash
# Navigate to project directory
cd ~/RAG-MEDICAL-CHATBOT

# Create .env file
nano .env
```

Add your environment variables:

```env
HF_TOKEN=your_actual_huggingface_token
GROQ_API_KEY=your_actual_groq_api_key
FLASK_ENV=production
FLASK_DEBUG=False
```

Save and exit (Ctrl+X, then Y, then Enter).

## Step 9: Run Deployment Script

Make the deployment script executable and run it:

```bash
chmod +x deploy.sh
./deploy.sh
```

This script will:
- Create a virtual environment
- Install all dependencies
- Set up the application

## Step 10: Start the Application

### Option A: Using the Start Script

```bash
chmod +x start.sh
./start.sh
```

### Option B: Manual Start

```bash
# Activate virtual environment
source venv/bin/activate

# Start with Gunicorn (production)
gunicorn -w 2 -b 0.0.0.0:5000 app.application:app

# Or start with Flask (development)
python app/application.py
```

### Option C: Run as a Service (Recommended for Production)

Create a systemd service for automatic startup:

```bash
sudo nano /etc/systemd/system/rag-chatbot.service
```

Add the following content:

```ini
[Unit]
Description=RAG Medical Chatbot
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME/RAG-MEDICAL-CHATBOT
Environment="PATH=/home/YOUR_USERNAME/RAG-MEDICAL-CHATBOT/venv/bin"
ExecStart=/home/YOUR_USERNAME/RAG-MEDICAL-CHATBOT/venv/bin/gunicorn -w 2 -b 0.0.0.0:5000 app.application:app
Restart=always

[Install]
WantedBy=multi-user.target
```

Replace `YOUR_USERNAME` with your actual username.

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rag-chatbot
sudo systemctl start rag-chatbot
sudo systemctl status rag-chatbot
```

## Step 11: Access Your Application

1. Get your VM's external IP:
   - Go to **Compute Engine** > **VM instances**
   - Find your VM and note the **External IP**

2. Access the application:
   - Open browser: `http://YOUR_EXTERNAL_IP:5000`
   - Or: `http://YOUR_EXTERNAL_IP:5000/`

## Step 12: Set Up Static IP (Optional but Recommended)

By default, external IPs are ephemeral. To get a static IP:

1. Go to **VPC network** > **External IP addresses**
2. Click **"Reserve Static Address"**
3. Name: `rag-chatbot-ip`
4. Attach to your VM instance
5. Click **"Reserve"**

## Troubleshooting

### Application Not Accessible

1. **Check firewall rules**: Ensure port 5000 is allowed
2. **Check VM status**: Ensure VM is running
3. **Check application logs**: 
   ```bash
   sudo journalctl -u rag-chatbot -f
   # Or if running manually
   tail -f /var/log/app.log
   ```

### Application Crashes

1. **Check Python version**: Should be Python 3.8+
2. **Check dependencies**: Run `pip install -r requirements.txt` again
3. **Check environment variables**: Ensure `.env` file is correct
4. **Check disk space**: `df -h`

### Vector Store Issues

If vector store is missing:
```bash
source venv/bin/activate
python -m app.components.data_loader
```

### Port Already in Use

```bash
# Find process using port 5000
sudo lsof -i :5000

# Kill the process
sudo kill -9 PID
```

## Security Recommendations

1. **Restrict Firewall**: Only allow your IP or use a VPN
2. **Use HTTPS**: Set up a reverse proxy (Nginx) with SSL certificate
3. **Update Regularly**: Keep system and packages updated
4. **Use Secrets Manager**: Store API keys in GCP Secret Manager instead of .env
5. **Enable Logging**: Set up Cloud Logging for monitoring

## Cost Optimization

1. **Use Preemptible VMs**: For testing (up to 80% cheaper)
2. **Stop VM When Not in Use**: VMs only charge for compute time
3. **Right-size VM**: Monitor usage and adjust machine type
4. **Use Committed Use Discounts**: For long-term usage

## Next Steps

- Set up domain name and DNS
- Configure Nginx as reverse proxy
- Set up SSL certificate (Let's Encrypt)
- Configure automated backups
- Set up monitoring and alerts

## Support

For issues, check:
- Application logs: `sudo journalctl -u rag-chatbot`
- System logs: `/var/log/syslog`
- GCP Console: Compute Engine > Logs

