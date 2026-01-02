"""Anthropic (Claude) API client."""

import httpx
from typing import List, Dict, Any, Optional
from config import ANTHROPIC_API_KEY, ANTHROPIC_API_URL

MAX_OUTPUT_TOKENS = 16384


async def query_claude(model_id: str, messages: List[Dict[str, str]], timeout: float = 180.0) -> Optional[Dict[str, Any]]:
    headers = {"x-api-key": ANTHROPIC_API_KEY, "anthropic-version": "2023-06-01", "Content-Type": "application/json"}
    
    system_msg = None
    chat_messages = []
    for msg in messages:
        if msg["role"] == "system":
            system_msg = msg["content"]
        else:
            chat_messages.append(msg)
    
    payload = {"model": model_id, "max_tokens": MAX_OUTPUT_TOKENS, "messages": chat_messages}
    if system_msg:
        payload["system"] = system_msg

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(ANTHROPIC_API_URL, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            usage = data.get('usage', {})
            return {
                'content': data['content'][0]['text'],
                'usage': {'prompt_tokens': usage.get('input_tokens', 0), 'completion_tokens': usage.get('output_tokens', 0), 'total_tokens': usage.get('input_tokens', 0) + usage.get('output_tokens', 0), 'max_tokens': MAX_OUTPUT_TOKENS}
            }
    except Exception as e:
        print(f"Error querying Claude {model_id}: {e}")
        return None
