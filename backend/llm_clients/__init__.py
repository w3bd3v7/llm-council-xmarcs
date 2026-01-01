"""Unified LLM client router."""

from typing import List, Dict, Any, Optional
from .anthropic_client import query_claude
from .openai_client import query_gpt
from .google_client import query_gemini
from .xai_client import query_grok
from .zhipu_client import query_glm


async def query_model(
    provider: str,
    model_id: str,
    messages: List[Dict[str, str]],
    timeout: float = 120.0
) -> Optional[Dict[str, Any]]:
    """
    Route query to the appropriate LLM client based on provider.

    Args:
        provider: Provider name (anthropic, openai, google, xai, zhipu)
        model_id: Model identifier for the provider
        messages: List of message dicts with 'role' and 'content'
        timeout: Request timeout in seconds

    Returns:
        Response dict with 'content', or None if failed
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
    """
    Query multiple models in parallel.

    Args:
        models: List of model config dicts with 'name', 'provider', 'model_id'
        messages: List of message dicts to send to each model

    Returns:
        Dict mapping model name to response dict (or None if failed)
    """
    import asyncio

    # Create tasks for all models
    tasks = [
        query_model(model['provider'], model['model_id'], messages)
        for model in models
    ]

    # Wait for all to complete
    responses = await asyncio.gather(*tasks)

    # Map model names to their responses
    return {
        model['name']: response
        for model, response in zip(models, responses)
    }
