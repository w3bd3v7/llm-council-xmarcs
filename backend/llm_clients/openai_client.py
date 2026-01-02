"""OpenAI (GPT-4) API client."""

import httpx
from typing import List, Dict, Any, Optional
from config import OPENAI_API_KEY, OPENAI_API_URL

MAX_OUTPUT_TOKENS = 16384


async def query_gpt(model_id: str, messages: List[Dict[str, str]], timeout: float = 180.0) -> Optional[Dict[str, Any]]:
    headers = {"Authorization": f"Bearer {OPENAI_API_KEY}", "Content-Type": "application/json"}
    payload = {"model": model_id, "messages": messages, "max_tokens": MAX_OUTPUT_TOKENS, "temperature": 0.3}

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(OPENAI_API_URL, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            usage = data.get('usage', {})
            return {
                'content': data['choices'][0]['message']['content'],
                'usage': {'prompt_tokens': usage.get('prompt_tokens', 0), 'completion_tokens': usage.get('completion_tokens', 0), 'total_tokens': usage.get('total_tokens', 0), 'max_tokens': MAX_OUTPUT_TOKENS}
            }
    except Exception as e:
        print(f"Error querying GPT {model_id}: {e}")
        return None
