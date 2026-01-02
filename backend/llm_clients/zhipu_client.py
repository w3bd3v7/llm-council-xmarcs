"""Zhipu AI (GLM-4) API client."""

import httpx
from typing import List, Dict, Any, Optional
from config import ZAI_GLM_XO_API_KEY, ZHIPU_API_URL


async def query_glm(
    model_id: str,
    messages: List[Dict[str, str]],
    timeout: float = 120.0
) -> Optional[Dict[str, Any]]:
    """
    Query GLM-4 via Zhipu AI API.

    Args:
        model_id: Zhipu model identifier
        messages: List of message dicts with 'role' and 'content'
        timeout: Request timeout in seconds

    Returns:
        Response dict with 'content', or None if failed
    """
    headers = {
        "Authorization": f"Bearer {ZAI_GLM_XO_API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": model_id,
        "messages": messages,
        "max_tokens": 16384,
        "temperature": 0.3,  # Lower temp for chairman synthesis
    }

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(
                ZHIPU_API_URL,
                headers=headers,
                json=payload
            )
            response.raise_for_status()

            data = response.json()
            
            return {
                'content': data['choices'][0]['message']['content']
            }

    except Exception as e:
        print(f"Error querying GLM {model_id}: {e}")
        return None
