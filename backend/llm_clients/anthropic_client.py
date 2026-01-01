"""Anthropic (Claude) API client."""

import httpx
from typing import List, Dict, Any, Optional
from ..config import ANTHROPIC_API_KEY, ANTHROPIC_API_URL


async def query_claude(
    model_id: str,
    messages: List[Dict[str, str]],
    timeout: float = 120.0
) -> Optional[Dict[str, Any]]:
    """
    Query Claude via Anthropic API.

    Args:
        model_id: Anthropic model identifier
        messages: List of message dicts with 'role' and 'content'
        timeout: Request timeout in seconds

    Returns:
        Response dict with 'content', or None if failed
    """
    headers = {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
    }

    payload = {
        "model": model_id,
        "max_tokens": 2048,
        "messages": messages,
    }

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(
                ANTHROPIC_API_URL,
                headers=headers,
                json=payload
            )
            response.raise_for_status()

            data = response.json()
            
            return {
                'content': data['content'][0]['text']
            }

    except Exception as e:
        print(f"Error querying Claude {model_id}: {e}")
        return None
