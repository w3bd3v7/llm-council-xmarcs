"""xAI (Grok) API client."""

import httpx
from typing import List, Dict, Any, Optional
from config import XAI_API_KEY, XAI_API_URL

MAX_OUTPUT_TOKENS = 16384


async def query_grok(model_id: str, messages: List[Dict[str, str]], timeout: float = 180.0) -> Optional[Dict[str, Any]]:
    headers = {"Authorization": f"Bearer {XAI_API_KEY}", "Content-Type": "application/json"}
    payload = {"model": model_id, "messages": messages, "max_tokens": MAX_OUTPUT_TOKENS, "temperature": 0.3}

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(XAI_API_URL, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            usage = data.get('usage', {})
            return {
                'content': data['choices'][0]['message']['content'],
                'usage': {'prompt_tokens': usage.get('prompt_tokens', 0), 'completion_tokens': usage.get('completion_tokens', 0), 'total_tokens': usage.get('total_tokens', 0), 'max_tokens': MAX_OUTPUT_TOKENS}
            }
    except Exception as e:
        print(f"Error querying Grok {model_id}: {e}")
        return None
