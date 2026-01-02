"""Configuration for XMARCS LLM Council."""

import os
from dotenv import load_dotenv

load_dotenv()

# API Keys - loaded from environment variables
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
XAI_API_KEY = os.getenv("XAI_API_KEY")
ZHIPU_API_KEY = os.getenv("ZHIPU_API_KEY")

# API Endpoints
ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
GOOGLE_API_URL = "https://generativelanguage.googleapis.com/v1beta/models"
XAI_API_URL = "https://api.x.ai/v1/chat/completions"
ZHIPU_API_URL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"

# Council Members (4 debaters)
COUNCIL_MODELS = [
    {
        "name": "Claude Sonnet 4.5",
        "provider": "anthropic",
        "model_id": "claude-3-5-sonnet-20241022",
        "role": "Careful, nuanced reasoning and analysis"
    },
    {
        "name": "GPT-4",
        "provider": "openai",
        "model_id": "gpt-4",
        "role": "Creative, broad thinking and innovative solutions"
    },
    {
        "name": "Gemini Pro",
        "provider": "google",
        "model_id": "gemini-pro",
        "role": "Analytical, data-driven insights"
    },
    {
        "name": "Grok",
        "provider": "xai",
        "model_id": "grok-beta",
        "role": "Contrarian perspective and devil's advocate"
    }
]

# Chairman Model (synthesizer)
CHAIRMAN_MODEL = {
    "name": "GLM-4",
    "provider": "zhipu",
    "model_id": "glm-4",
    "role": "Synthesis and final decision-making with strong reasoning"
}

# PostgreSQL Database Configuration
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://llmcouncil:llmcouncil_password@postgres:5432/llmcouncil"
)

# Server Configuration
HOST = "0.0.0.0"
PORT = 8001
CORS_ORIGINS = [
    "http://localhost:5173", "http://72.60.126.230:5173",
    "http://localhost:3000",
    os.getenv("FRONTEND_URL", "")
]
