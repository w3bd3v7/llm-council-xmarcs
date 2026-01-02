"""Google (Gemini) API client."""

import httpx
from typing import List, Dict, Any, Optional
from config import GOOGLE_API_KEY, GOOGLE_API_URL

MAX_OUTPUT_TOKENS = 8192


async def query_gemini(model_id: str, messages: List[Dict[str, str]], timeout: float = 180.0) -> Optional[Dict[str, Any]]:
    gemini_parts = []
    for msg in messages:
        gemini_parts.append({"text": msg["content"]})

    payload = {"contents": [{"parts": gemini_parts}], "generationConfig": {"temperature": 0.3, "maxOutputTokens": MAX_OUTPUT_TOKENS}}
    url = f"{GOOGLE_API_URL}/{model_id}:generateContent?key={GOOGLE_API_KEY}"

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(url, headers={"Content-Type": "application/json"}, json=payload)
            response.raise_for_status()
            data = response.json()
            usage = data.get('usageMetadata', {})
            return {
                'content': data['candidates'][0]['content']['parts'][0]['text'],
                'usage': {'prompt_tokens': usage.get('promptTokenCount', 0), 'completion_tokens': usage.get('candidatesTokenCount', 0), 'total_tokens': usage.get('totalTokenCount', 0), 'max_tokens': MAX_OUTPUT_TOKENS}
            }
    except Exception as e:
        print(f"Error querying Gemini {model_id}: {e}")
        return None
