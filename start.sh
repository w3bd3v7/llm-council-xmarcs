#!/bin/bash

# XMARCS LLM Council - Quick Start Script

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         XMARCS LLM Council - Quick Start Setup            ║"
echo "║                                                            ║"
echo "║  Your AI Board of Directors                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found!"
    echo ""
    echo "Creating .env from template..."
    cp .env.example .env
    echo "✅ Created .env file"
    echo ""
    echo "❌ IMPORTANT: You must edit .env and add your API keys before continuing!"
    echo ""
    echo "Required API keys:"
    echo "  1. ANTHROPIC_API_KEY (Claude Sonnet 4.5)"
    echo "  2. OPENAI_API_KEY (GPT-4)"
    echo "  3. GOOGLE_API_KEY (Gemini Pro)"
    echo "  4. XAI_API_KEY (Grok)"
    echo "  5. ZHIPU_API_KEY (GLM-4.7)"
    echo ""
    echo "Edit the file with: nano .env"
    echo "Then run this script again."
    exit 1
fi

# Verify API keys are set
echo "🔍 Checking API keys..."
MISSING_KEYS=0

if ! grep -q "ANTHROPIC_API_KEY=sk-ant-" .env; then
    echo "❌ ANTHROPIC_API_KEY not set or invalid"
    MISSING_KEYS=1
fi

if ! grep -q "OPENAI_API_KEY=sk-" .env; then
    echo "❌ OPENAI_API_KEY not set or invalid"
    MISSING_KEYS=1
fi

if ! grep -q "GOOGLE_API_KEY=" .env && ! grep -q "your-google-api-key-here" .env; then
    echo "⚠️  GOOGLE_API_KEY may not be set"
fi

if ! grep -q "XAI_API_KEY=xai-" .env && ! grep -q "XAI_API_KEY=" .env; then
    echo "⚠️  XAI_API_KEY may not be set"
fi

if ! grep -q "ZHIPU_API_KEY=" .env && ! grep -q "your-zhipu-api-key-here" .env; then
    echo "❌ ZHIPU_API_KEY not set"
    MISSING_KEYS=1
fi

if [ $MISSING_KEYS -eq 1 ]; then
    echo ""
    echo "❌ Please add all required API keys to .env file"
    echo "Edit with: nano .env"
    exit 1
fi

echo "✅ API keys configured"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running!"
    echo "Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Check if services are already running
if docker-compose ps | grep -q "Up"; then
    echo "⚠️  Services are already running"
    echo ""
    read -p "Restart services? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping services..."
        docker-compose down
    else
        echo "Keeping existing services running"
        echo ""
        echo "Access your LLM Council at:"
        echo "  Frontend: http://localhost:5173"
        echo "  Backend:  http://localhost:8001"
        echo "  API Docs: http://localhost:8001/docs"
        exit 0
    fi
fi

# Build and start services
echo "🚀 Building and starting services..."
echo "This may take 3-5 minutes on first run..."
echo ""

docker-compose up -d --build

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up.*Up.*Up"; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                  🎉 SUCCESS! 🎉                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "✅ All services are running!"
    echo ""
    echo "Access your LLM Council:"
    echo "  📱 Frontend:  http://localhost:5173"
    echo "  🔧 Backend:   http://localhost:8001"
    echo "  📚 API Docs:  http://localhost:8001/docs"
    echo ""
    echo "To view logs:"
    echo "  docker-compose logs -f"
    echo ""
    echo "To stop services:"
    echo "  docker-compose down"
    echo ""
    echo "Ready to make strategic decisions! 🧠💡"
else
    echo ""
    echo "❌ Some services failed to start"
    echo ""
    echo "Check logs with:"
    echo "  docker-compose logs"
    echo ""
    exit 1
fi
