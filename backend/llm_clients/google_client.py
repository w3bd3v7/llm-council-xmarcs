"""Google (Gemini) API client."""

import httpx
from typing import List, Dict, Any, Optional
from ..config import GOOGLE_API_KEY, GOOGLE_API_URL


async def query_gemini(
    model_id: str,
    messages: List[Dict[str, str]],
    timeout: float = 120.0
) -> Optional[Dict[str, Any]]:
    """
    Query Gemini via Google API.

    Args:
        model_id: Google model identifier
        messages: List of message dicts with 'role' and 'content'
        timeout: Request timeout in seconds

    Returns:
        Response dict with 'content', or None if failed
    """
    # Convert messages to Gemini format
    # Gemini uses a different message format than OpenAI/Anthropic
    gemini_parts = []
    for msg in messages:
        gemini_parts.append({"text": msg["content"]})

    payload = {
        "contents": [{
            "parts": gemini_parts
        }],
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 2048,
        }
    }

    url = f"{GOOGLE_API_URL}/{model_id}:generateContent?key={GOOGLE_API_KEY}"

    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(
                url,
                headers={"Content-Type": "application/json"},
                json=payload
            )
            response.raise_for_status()

            data = response.json()
            
            return {
                'content': data['candidates'][0]['content']['parts'][0]['text']
            }

    except Exception as e:
        print(f"Error querying Gemini {model_id}: {e}")
        return None
