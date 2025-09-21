import requests
from config import OPENROUTER_KEY, OPENROUTER_MODEL, REQUEST_TIMEOUT
from tenacity import retry, stop_after_attempt, wait_exponential

BASE = "https://openrouter.ai/api/v1"

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def call_openrouter(prompt, model=None, system_prompt=None, max_tokens=4000):
    """
    Call OpenRouter API for chat completions with retry logic
    
    Args:
        prompt: User prompt/input text
        model: Model to use (defaults to configured model)
        system_prompt: System prompt for context
        max_tokens: Maximum tokens in response
    
    Returns:
        JSON response from OpenRouter API
    """
    if not OPENROUTER_KEY:
        raise ValueError("OPENROUTER_API_KEY not configured")
    
    headers = {
        "Authorization": f"Bearer {OPENROUTER_KEY}",
        "Content-Type": "application/json"
    }
    
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})
    
    payload = {
        "model": model or OPENROUTER_MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": 0.7
    }
    
    response = requests.post(
        f"{BASE}/chat/completions", 
        json=payload, 
        headers=headers, 
        timeout=REQUEST_TIMEOUT
    )
    response.raise_for_status()
    return response.json()

def extract_content(response):
    """Extract content from OpenRouter response"""
    try:
        return response["choices"][0]["message"]["content"]
    except (KeyError, IndexError) as e:
        raise ValueError(f"Invalid response format: {e}")

def generate_policy_content(module_prompt, system_prompt):
    """Generate policy content using OpenRouter"""
    response = call_openrouter(module_prompt, system_prompt=system_prompt)
    return extract_content(response)