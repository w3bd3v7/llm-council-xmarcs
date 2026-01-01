# XMARCS LLM Council - Deployment Guide

## Step-by-Step VPS Deployment

### Prerequisites Checklist

- [x] VPS running Ubuntu 22.04+ (your Hetzner VPS)
- [x] Docker and Docker Compose installed
- [x] Dokploy installed and running
- [x] All 5 API keys obtained
- [x] Domain name (optional but recommended)

### Step 1: Prepare API Keys

**You need 5 API keys total:**

1. **Anthropic (Claude Sonnet 4.5)**
   - Go to: https://console.anthropic.com/
   - Navigate to API Keys
   - Create new key
   - Copy: `sk-ant-...`

2. **OpenAI (GPT-4)**
   - Go to: https://platform.openai.com/api-keys
   - Create new secret key
   - Copy: `sk-...`

3. **Google (Gemini Pro)**
   - Go to: https://makersuite.google.com/app/apikey
   - Create API key
   - Copy key

4. **xAI (Grok)**
   - Go to: https://console.x.ai/
   - API Keys section
   - Create new key
   - Copy: `xai-...`

5. **Zhipu AI (GLM-4.7)**
   - Go to: https://open.bigmodel.cn/
   - Navigate to API Keys (past the subscription pages)
   - Create API key
   - Copy key

**Save all 5 keys in a secure text file temporarily.**

---

### Step 2: Upload Project to VPS

**Option A: Using SCP (from your local machine)**

```bash
# Compress the project
cd /path/to/llm-council-xmarcs
tar -czf llm-council.tar.gz .

# Upload to VPS
scp llm-council.tar.gz root@YOUR_VPS_IP:/opt/

# SSH into VPS and extract
ssh root@YOUR_VPS_IP
cd /opt
mkdir -p llm-council-xmarcs
tar -xzf llm-council.tar.gz -C llm-council-xmarcs
cd llm-council-xmarcs
```

**Option B: Using Git (if you have a private repo)**

```bash
ssh root@YOUR_VPS_IP
cd /opt
git clone YOUR_PRIVATE_REPO_URL llm-council-xmarcs
cd llm-council-xmarcs
```

---

### Step 3: Configure Environment Variables

```bash
# Still in /opt/llm-council-xmarcs on your VPS
cp .env.example .env
nano .env
```

**Fill in your API keys:**

```env
# XMARCS LLM Council - Environment Variables

# API Keys for Council Members
ANTHROPIC_API_KEY=sk-ant-YOUR-ACTUAL-KEY-HERE
OPENAI_API_KEY=sk-YOUR-ACTUAL-KEY-HERE
GOOGLE_API_KEY=YOUR-GOOGLE-API-KEY-HERE
XAI_API_KEY=xai-YOUR-ACTUAL-KEY-HERE

# API Key for Chairman (GLM-4.7)
ZHIPU_API_KEY=YOUR-ZHIPU-API-KEY-HERE

# Frontend URL (update if using custom domain)
FRONTEND_URL=http://YOUR_VPS_IP:5173

# Database URL (leave as-is)
DATABASE_URL=postgresql://llmcouncil:llmcouncil_password@postgres:5432/llmcouncil
```

**Save and exit** (Ctrl+X, Y, Enter in nano)

---

### Step 4: Deploy with Docker Compose

```bash
# Build and start all services
docker-compose up -d --build

# This will:
# 1. Pull PostgreSQL 17 Alpine
# 2. Build backend image with Python dependencies
# 3. Build frontend image with Node.js dependencies
# 4. Start all 3 containers
# 
# First build takes 3-5 minutes

# Watch the logs
docker-compose logs -f

# Wait for these messages:
# - postgres: database system is ready to accept connections
# - backend: Application startup complete
# - frontend: Local: http://0.0.0.0:5173/
```

**When you see all 3 services running:**

```bash
# Check status
docker-compose ps

# Should show:
# NAME        STATUS      PORTS
# postgres    Up          5432/tcp
# backend     Up          0.0.0.0:8001->8001/tcp
# frontend    Up          0.0.0.0:5173->5173/tcp
```

---

### Step 5: Test the Application

**1. Backend Health Check:**

```bash
curl http://localhost:8001/
# Should return: {"status":"ok","service":"XMARCS LLM Council API",...}
```

**2. Frontend Access:**

Open browser to: `http://YOUR_VPS_IP:5173`

**3. Create First Conversation:**

- Click "+ New Conversation"
- Type a question: "What are the key considerations for pricing a high-ticket coaching program?"
- Click Send
- Watch the 3 stages process in real-time

---

### Step 6: Configure Firewall (Security)

```bash
# Allow only necessary ports
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw allow 5173/tcp    # Frontend (temporary - will use nginx later)
ufw allow 8001/tcp    # Backend API (temporary - will use nginx later)
ufw enable

# Check status
ufw status
```

---

### Step 7: Setup Domain & SSL (Optional but Recommended)

**If you have a domain (e.g., council.xmarcsforge.com):**

**A. Install Nginx:**

```bash
apt update
apt install nginx certbot python3-certbot-nginx -y
```

**B. Create Nginx Config:**

```bash
nano /etc/nginx/sites-available/llm-council
```

**Add this configuration:**

```nginx
# Frontend
server {
    listen 80;
    server_name council.xmarcsforge.com;

    location / {
        proxy_pass http://localhost:5173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Backend API
server {
    listen 80;
    server_name api-council.xmarcsforge.com;

    location / {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**C. Enable and Get SSL:**

```bash
# Enable site
ln -s /etc/nginx/sites-available/llm-council /etc/nginx/sites-enabled/
nginx -t  # Test config
systemctl restart nginx

# Get SSL certificates
certbot --nginx -d council.xmarcsforge.com -d api-council.xmarcsforge.com

# Auto-renewal is set up automatically
```

**D. Update .env with new URL:**

```bash
cd /opt/llm-council-xmarcs
nano .env

# Change:
FRONTEND_URL=https://council.xmarcsforge.com

# Restart backend to pick up change
docker-compose restart backend
```

---

### Step 8: Alternative - Deploy via Dokploy

**If you prefer Dokploy's UI:**

1. **In Dokploy Dashboard:**
   - Create New Application
   - Type: Docker Compose
   - Name: llm-council

2. **Upload docker-compose.yml:**
   - Paste contents of docker-compose.yml
   - OR point to `/opt/llm-council-xmarcs/docker-compose.yml`

3. **Add Environment Variables:**
   - In Dokploy, go to application settings
   - Add all 5 API keys as environment variables
   - Add FRONTEND_URL

4. **Deploy:**
   - Click Deploy
   - Monitor logs in Dokploy

5. **Configure Domain:**
   - In Dokploy, add domain: council.yourdomain.com
   - Point to frontend service (port 5173)
   - Add subdomain: api.yourdomain.com → backend (port 8001)
   - Enable SSL

---

## Verification Checklist

After deployment, verify:

- [ ] `http://YOUR_VPS_IP:8001/` returns API health check
- [ ] `http://YOUR_VPS_IP:8001/docs` shows API documentation
- [ ] `http://YOUR_VPS_IP:5173` loads frontend UI
- [ ] Can create new conversation
- [ ] Can send message and get response
- [ ] All 3 stages display correctly
- [ ] PostgreSQL is storing conversations
- [ ] No errors in `docker-compose logs`

---

## Maintenance

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres

# Last 100 lines
docker-compose logs --tail=100
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart backend

# Stop all
docker-compose down

# Start all
docker-compose up -d
```

### Update Application

```bash
# Pull latest changes (if using git)
cd /opt/llm-council-xmarcs
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Database Backup

```bash
# Backup
docker-compose exec postgres pg_dump -U llmcouncil llmcouncil > backup_$(date +%Y%m%d).sql

# Restore
docker-compose exec -T postgres psql -U llmcouncil llmcouncil < backup_20241230.sql
```

### Monitor Resource Usage

```bash
# Docker stats
docker stats

# Disk usage
docker system df

# Container resource usage
docker-compose ps
docker inspect <container-id> | grep -i memory
```

---

## Troubleshooting

### Issue: Backend won't start

**Check logs:**
```bash
docker-compose logs backend
```

**Common causes:**
1. Missing API keys in .env
2. PostgreSQL not ready (increase healthcheck wait time)
3. Port 8001 already in use

**Solutions:**
```bash
# Check .env file
cat .env | grep API_KEY

# Check port availability
netstat -tuln | grep 8001

# Restart with fresh build
docker-compose down -v
docker-compose up -d --build
```

### Issue: Frontend can't connect to backend

**Check:**
1. CORS settings in backend/config.py
2. API_URL in frontend .env
3. Network between containers

**Solution:**
```bash
# Check if backend is accessible
curl http://localhost:8001/

# Check Docker network
docker network inspect llm-council-xmarcs_council-network

# Restart both services
docker-compose restart frontend backend
```

### Issue: Database connection failed

**Check:**
```bash
# PostgreSQL logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres psql -U llmcouncil -d llmcouncil

# If that fails, check credentials in docker-compose.yml match .env
```

---

## Performance Tuning

### For Production Use:

**1. Increase Worker Processes (backend/main.py):**

```python
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8001,
        workers=4  # Add this for production
    )
```

**2. Add Connection Pool Settings (backend/storage.py):**

```python
engine = create_engine(
    DATABASE_URL,
    pool_size=10,        # Add these
    max_overflow=20,     # for production
    pool_pre_ping=True
)
```

**3. Enable Nginx Caching:**

Add to nginx config:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m;

server {
    # ... existing config ...
    
    location /api/ {
        proxy_cache my_cache;
        proxy_cache_valid 200 5m;
        # ... rest of proxy config ...
    }
}
```

---

## Cost Monitoring

**Track API Usage:**

```bash
# View backend logs for API calls
docker-compose logs backend | grep "querying"

# Count total API calls today
docker-compose logs backend --since 24h | grep "querying" | wc -l

# Estimate costs
# Each council meeting = 5 API calls (4 models + chairman)
# Average cost per call: ~$0.015
# Monthly costs = (meetings per day × 30 × $0.10)
```

**Set up usage alerts:**
- Monitor API provider dashboards
- Set spending limits in each provider's console
- Track PostgreSQL conversation count as proxy for usage

---

## Security Hardening

**Production Checklist:**

- [ ] All API keys in environment variables (never in code)
- [ ] PostgreSQL password changed from default
- [ ] Firewall configured (only 80, 443, 22)
- [ ] SSL certificates installed
- [ ] Regular backups scheduled
- [ ] API rate limiting enabled
- [ ] CORS configured for production domain only
- [ ] Docker containers running as non-root user
- [ ] Fail2ban installed for SSH protection

---

**Deployment complete! Your LLM Council is now running.**

Access at: `http://YOUR_VPS_IP:5173` or `https://council.yourdomain.com`

Questions? support@xmarcsforge.com
