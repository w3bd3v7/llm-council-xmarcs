"""Unified LLM client router."""

from typing import List, Dict, Any, Optional
from llm_clients.anthropic_client import query_claude
from llm_clients.openai_client import query_gpt
from llm_clients.google_client import query_gemini
from llm_clients.xai_client import query_grok
from llm_clients.zhipu_client import query_glm


async def query_model(
    provider: str,
    model_id: str,
    messages: List[Dict[str, str]],
    timeout: float = 120.0
) -> Optional[Dict[str, Any]]:
    """
    Route query to the appropriate LLM client based on provider.
    """
    if provider == "anthropic":
        return await query_claude(model_id, messages, timeout)
    elif provider == "openai":
        return await query_gpt(model_id, messages, timeout)
    elif provider == "google":
        return await query_gemini(model_id, messages, timeout)
    elif provider == "xai":
        return await query_grok(model_id, messages, timeout)
    elif provider == "zhipu":
        return await query_glm(model_id, messages, timeout)
    else:
        print(f"Unknown provider: {provider}")
        return None


async def query_models_parallel(
    models: List[Dict[str, str]],
    messages: List[Dict[str, str]]
) -> Dict[str, Optional[Dict[str, Any]]]:
    """Query multiple models in parallel."""
    import asyncio

    tasks = [
        query_model(model['provider'], model['model_id'], messages)
        for model in models
    ]

    responses = await asyncio.gather(*tasks)

    return {
        model['name']: response
        for model, response in zip(models, responses)
    }
