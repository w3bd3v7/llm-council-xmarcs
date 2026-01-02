"""xAI (Grok) API client."""

import httpx
from typing import List, Dict, Any, Optional
from config import XAI_API_KEY, XAI_API_URL


async def query_grok(
    model_id: str,
    messages: List[Dict[str, str]],
    timeout: float = 120.0
) -> Optional[Dict[str, Any]]:
    """
    Query Grok via xAI API.

    Args:
        model_id: xAI model identifier
        messages: List of message dicts with 'role' and 'content'
        timeout: Request timeout in seconds

    Returns:
        Response dict with 'content', or None if failed
    """
    headers = {
        "Authorization": f"Bearer {XAI_API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": model_id,
        "messages": messages,
        "max_tokens": 2048,
        "temperature": 0.8,
    }

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(
                XAI_API_URL,
                headers=headers,
                json=payload
            )
            response.raise_for_status()

            data = response.json()
            
            return {
                'content': data['choices'][0]['message']['content']
            }

    except Exception as e:
        print(f"Error querying Grok {model_id}: {e}")
        return None
