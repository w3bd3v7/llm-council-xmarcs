# XMARCS LLM Council

**Your AI Board of Directors - Multi-Model Strategic Decision Making**

![LLM Council](https://via.placeholder.com/1200x300/4a90e2/ffffff?text=XMARCS+LLM+Council)

## Overview

XMARCS LLM Council is a production-ready web application that orchestrates multiple AI models to provide strategic business insights. Instead of relying on a single AI's perspective, the council:

1. **Stage 1**: Collects independent responses from 4 premium AI models
2. **Stage 2**: Each model critiques and ranks others' responses (anonymously)
3. **Stage 3**: GLM-4.7 synthesizes all perspectives into one final, battle-tested recommendation

## Architecture

### Council Members (4 Debaters):
1. **Claude Sonnet 4.5** (Anthropic) - Careful, nuanced reasoning
2. **GPT-4** (OpenAI) - Creative, broad thinking
3. **Gemini Pro** (Google) - Analytical, data-driven insights
4. **Grok** (xAI) - Contrarian perspective, devil's advocate

### Chairman (Synthesizer):
5. **GLM-4.7** (Zhipu AI) - Final synthesis with strong reasoning capabilities

### Tech Stack:
- **Backend**: FastAPI (Python 3.11+), async httpx, SQLAlchemy
- **Frontend**: React 19 + Vite, react-markdown
- **Database**: PostgreSQL 17
- **Deployment**: Docker Compose
- **APIs**: Direct integration with 5 AI providers (no OpenRouter)

## Cost per Council Meeting

**Estimated: $0.08 - $0.12 per strategic decision**

- Claude Sonnet 4.5: ~$0.02-0.03
- GPT-4: ~$0.03-0.04
- Gemini Pro: ~$0.01-0.02
- Grok: ~$0.01-0.02
- GLM-4.7 (Chairman): ~$0.01-0.01

**Monthly cost for 10 decisions/day**: ~$24-36

Much cheaper than consulting fees or making wrong strategic decisions!

## Quick Start

### Prerequisites

- Docker & Docker Compose installed
- API keys for all 5 providers (see below)

### 1. Clone/Download Project

```bash
# If you received this as a zip file, extract it
# Otherwise clone from your repository
cd llm-council-xmarcs
```

### 2. Configure API Keys

```bash
# Copy the environment template
cp .env.example .env

# Edit .env and add your API keys
nano .env  # or use any text editor
```

**Required API Keys:**

1. **Anthropic (Claude)**: https://console.anthropic.com/
2. **OpenAI (GPT-4)**: https://platform.openai.com/api-keys
3. **Google (Gemini)**: https://makersuite.google.com/app/apikey
4. **xAI (Grok)**: https://console.x.ai/
5. **Zhipu AI (GLM-4.7)**: https://open.bigmodel.cn/

### 3. Build and Run

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 4. Access the Application

Open your browser to:
- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8001
- **API Docs**: http://localhost:8001/docs

## Production Deployment on VPS

### Deploy with Dokploy

1. **Upload Project to VPS**:
```bash
scp -r llm-council-xmarcs root@your-vps-ip:/opt/
```

2. **In Dokploy**:
   - Create new Docker Compose application
   - Point to `/opt/llm-council-xmarcs`
   - Add environment variables from .env
   - Deploy

3. **Configure Domain** (optional):
   - Add domain in Dokploy
   - Update FRONTEND_URL in .env
   - Redeploy

### Manual VPS Deployment

```bash
# SSH into your VPS
ssh root@your-vps-ip

# Navigate to project
cd /opt/llm-council-xmarcs

# Create .env with your API keys
nano .env

# Build and start
docker-compose up -d --build

# Set up reverse proxy (nginx example)
# Point council.yourdomain.com to localhost:5173
# Point api.yourdomain.com to localhost:8001
```

## Usage Examples

### Strategic Business Questions:

**Pricing Decisions**:
> "Should we price our Pathfinder program at $16,000 or $20,000? Consider market positioning, value perception, and conversion rates."

**Market Entry**:
> "We're considering expanding into the commercial lending broker training market. What are the key risks and opportunities?"

**Product Strategy**:
> "Should we build our AI platform in-house or use existing SaaS tools? Factor in time-to-market, control, and scalability."

**Hiring Decisions**:
> "We need to hire for a critical VP of Sales role. What compensation structure maximizes talent attraction while controlling costs?"

### How It Works:

1. **Ask your question** in the web interface
2. **Wait 30-60 seconds** as the council deliberates:
   - Stage 1: All 4 models respond independently (~15s)
   - Stage 2: Each model ranks the others (~20s)
   - Stage 3: Chairman synthesizes final answer (~15s)
3. **Review the results**:
   - See each model's individual response (tabs)
   - Read peer critiques and rankings
   - Get the final synthesized recommendation

## Development

### Local Development Setup

```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install -r requirements.txt
python -m backend.main

# Frontend (separate terminal)
cd frontend
npm install
npm run dev
```

### Project Structure

```
llm-council-xmarcs/
├── backend/
│   ├── llm_clients/          # API clients for each provider
│   │   ├── anthropic_client.py
│   │   ├── openai_client.py
│   │   ├── google_client.py
│   │   ├── xai_client.py
│   │   └── zhipu_client.py
│   ├── config.py             # Configuration and API keys
│   ├── council.py            # 3-stage orchestration logic
│   ├── storage.py            # PostgreSQL database layer
│   ├── main.py               # FastAPI application
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── components/       # React components
│   │   │   ├── Sidebar.jsx
│   │   │   ├── ChatInterface.jsx
│   │   │   ├── Stage1.jsx    # Individual responses
│   │   │   ├── Stage2.jsx    # Rankings & critiques
│   │   │   └── Stage3.jsx    # Final synthesis
│   │   ├── App.jsx
│   │   ├── api.js            # Backend API client
│   │   └── main.jsx
│   ├── package.json
│   ├── vite.config.js
│   └── Dockerfile
├── docker-compose.yml
├── .env.example
└── README.md
```

## API Documentation

### Endpoints

**GET** `/api/conversations`
- List all conversations

**POST** `/api/conversations`
- Create new conversation

**GET** `/api/conversations/{id}`
- Get conversation details

**POST** `/api/conversations/{id}/message`
- Send message (synchronous)

**POST** `/api/conversations/{id}/message/stream`
- Send message (streaming, real-time updates)

### Example API Usage

```python
import httpx

# Create conversation
response = httpx.post("http://localhost:8001/api/conversations")
conversation_id = response.json()["id"]

# Ask question
message = {
    "content": "Should we raise prices by 20% or introduce a premium tier?"
}
response = httpx.post(
    f"http://localhost:8001/api/conversations/{conversation_id}/message",
    json=message
)

result = response.json()
print(f"Final Answer: {result['stage3']['response']}")
```

## Troubleshooting

### Common Issues

**1. API Key Errors**
```
Error: Anthropic API returned 401
```
**Solution**: Double-check API key in .env file, ensure no extra spaces

**2. Database Connection Failed**
```
Error: could not connect to server
```
**Solution**: Ensure PostgreSQL container is running:
```bash
docker-compose ps postgres
docker-compose logs postgres
```

**3. CORS Errors in Browser**
```
Access to fetch blocked by CORS policy
```
**Solution**: Add your frontend URL to CORS_ORIGINS in backend/config.py

**4. Models Timeout**
```
Error querying Claude: timeout
```
**Solution**: Increase timeout in llm_clients (default 120s may be too short for complex queries)

## Customization

### Change Council Members

Edit `backend/config.py`:

```python
COUNCIL_MODELS = [
    {
        "name": "Claude Opus 4",
        "provider": "anthropic",
        "model_id": "claude-opus-4",
        "role": "Deep analytical reasoning"
    },
    # Add or modify models here
]
```

### Change Chairman

```python
CHAIRMAN_MODEL = {
    "name": "GPT-4",
    "provider": "openai",
    "model_id": "gpt-4",
    "role": "Synthesis and decision-making"
}
```

### Modify Debate Prompts

Edit `backend/council.py`:
- `stage1_collect_responses()` - Initial prompt to models
- `stage2_collect_rankings()` - Ranking instructions
- `stage3_synthesize_final()` - Chairman synthesis prompt

## Security Best Practices

1. **Never commit .env file** - already in .gitignore
2. **Rotate API keys regularly** - especially if exposed
3. **Use environment variables** - don't hardcode keys
4. **Enable rate limiting** - prevent abuse (TODO: add to FastAPI)
5. **HTTPS in production** - use reverse proxy (nginx)

## Performance Optimization

### For High Volume Usage:

1. **Redis Caching** (optional):
```yaml
# Add to docker-compose.yml
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
```

2. **Connection Pooling**:
Already configured in SQLAlchemy (see storage.py)

3. **Async Everywhere**:
All LLM calls are async/parallel - no sequential bottlenecks

## Monitoring

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f postgres

# Last 100 lines
docker-compose logs --tail=100 backend
```

### Database Access

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U llmcouncil -d llmcouncil

# Example queries
SELECT COUNT(*) FROM conversations;
SELECT id, title, created_at FROM conversations ORDER BY created_at DESC LIMIT 10;
```

## Roadmap

- [ ] Add conversation export (PDF/Markdown)
- [ ] Historical decision tracking & analytics
- [ ] Custom council configurations per user
- [ ] Integration with Slack/Teams
- [ ] Voice input support
- [ ] Multi-language support
- [ ] Cost tracking dashboard

## Support

For issues, questions, or feature requests:
- Email: support@xmarcsforge.com
- Documentation: (link to your docs)

## License

Proprietary - XMARCS Digital Forge, Inc.

## Acknowledgments

- Inspired by Andre Karpathy's LLM Council concept
- Built for SpringBoard ecosystem by XMARCS Digital Forge
- Powered by Claude, GPT-4, Gemini, Grok, and GLM-4.7

---

**Built with ❤️ by XMARCS Digital Forge, Inc.**

*Turning AI debates into strategic clarity.*
