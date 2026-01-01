"""OpenAI (GPT-4) API client."""

import httpx
from typing import List, Dict, Any, Optional
from ..config import OPENAI_API_KEY, OPENAI_API_URL


async def query_gpt(
    model_id: str,
    messages: List[Dict[str, str]],
    timeout: float = 120.0
) -> Optional[Dict[str, Any]]:
    """
    Query GPT via OpenAI API.

    Args:
        model_id: OpenAI model identifier
        messages: List of message dicts with 'role' and 'content'
        timeout: Request timeout in seconds

    Returns:
        Response dict with 'content', or None if failed
    """
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": model_id,
        "messages": messages,
        "max_tokens": 2048,
        "temperature": 0.7,
    }

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(
                OPENAI_API_URL,
                headers=headers,
                json=payload
            )
            response.raise_for_status()

            data = response.json()
            
            return {
                'content': data['choices'][0]['message']['content']
            }

    except Exception as e:
        print(f"Error querying GPT {model_id}: {e}")
        return None
