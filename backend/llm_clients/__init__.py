"""LLM client modules for The Board Room."""

import asyncio
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
    timeout: float = 180.0
) -> Optional[Dict[str, Any]]:
    """Query a single model."""
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
        return None


async def query_models_parallel(
    models: List[Dict[str, str]],
    messages: List[Dict[str, str]],
    timeout: float = 180.0
) -> Dict[str, Dict[str, Any]]:
    """Query multiple models in parallel."""
    tasks = []
    model_names = []
    
    for model_config in models:
        task = query_model(model_config['provider'], model_config['model_id'], messages, timeout)
        tasks.append(task)
        model_names.append(model_config['name'])
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    return {name: result for name, result in zip(model_names, results) if not isinstance(result, Exception) and result is not None}
