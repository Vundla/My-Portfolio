# Mastercard API client - safe pattern using OAuth 2.0
# Note: For production use, follow Mastercard's official SDK and onboarding process
# This is a reference implementation for educational purposes

import requests
import base64
from config import MASTERCARD_CLIENT_ID, MASTERCARD_CLIENT_SECRET, REQUEST_TIMEOUT
from tenacity import retry, stop_after_attempt, wait_exponential
import time

TOKEN_URL = "https://api.mastercard.com/oauth/token"
BASE_URL = "https://api.mastercard.com"

class MastercardTokenManager:
    def __init__(self):
        self.access_token = None
        self.token_expires_at = 0
    
    def get_token(self):
        """Get OAuth 2.0 access token with caching"""
        if self.access_token and time.time() < self.token_expires_at - 300:  # 5 min buffer
            return self.access_token
        
        if not MASTERCARD_CLIENT_ID or not MASTERCARD_CLIENT_SECRET:
            raise ValueError("Mastercard credentials not configured")
        
        # Create basic auth header
        credentials = f"{MASTERCARD_CLIENT_ID}:{MASTERCARD_CLIENT_SECRET}"
        encoded_credentials = base64.b64encode(credentials.encode()).decode()
        
        headers = {
            "Authorization": f"Basic {encoded_credentials}",
            "Content-Type": "application/x-www-form-urlencoded"
        }
        
        data = {"grant_type": "client_credentials"}
        
        response = requests.post(TOKEN_URL, data=data, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        
        token_data = response.json()
        self.access_token = token_data["access_token"]
        expires_in = token_data.get("expires_in", 3600)  # Default 1 hour
        self.token_expires_at = time.time() + expires_in
        
        return self.access_token

token_manager = MastercardTokenManager()

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def call_mastercard_api(endpoint, params=None, method="GET", data=None):
    """
    Make authenticated requests to Mastercard APIs
    
    Args:
        endpoint: API endpoint (e.g., 'locations/merchants')
        params: Query parameters
        method: HTTP method
        data: Request body for POST/PUT
    
    Returns:
        JSON response from Mastercard API
    """
    token = token_manager.get_token()
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    
    url = f"{BASE_URL}/{endpoint}"
    
    if method.upper() == "GET":
        response = requests.get(url, headers=headers, params=params, timeout=REQUEST_TIMEOUT)
    elif method.upper() == "POST":
        response = requests.post(url, headers=headers, params=params, json=data, timeout=REQUEST_TIMEOUT)
    else:
        raise ValueError(f"Unsupported HTTP method: {method}")
    
    response.raise_for_status()
    return response.json()

def get_merchant_locations(latitude, longitude, radius_miles=5, merchant_type=None):
    """
    Get merchant locations near coordinates
    
    Example usage for economic analysis and payment infrastructure mapping
    """
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "radiusSearch": radius_miles
    }
    
    if merchant_type:
        params["merchantType"] = merchant_type
    
    return call_mastercard_api("locations/merchants", params=params)

def get_spending_insights(country_code="ZA", category=None):
    """
    Get consumer spending insights (if available in sandbox)
    Note: This requires specific API access and may not be available in basic sandbox
    """
    params = {"countryCode": country_code}
    if category:
        params["category"] = category
    
    try:
        return call_mastercard_api("insights/spending", params=params)
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 403:
            return {"error": "API access restricted - requires partner onboarding"}
        raise

# Important security note:
# For production applications handling encrypted credentials or partner-specific APIs:
# 1. Use Mastercard's official SDKs
# 2. Follow their secure onboarding process
# 3. Never attempt to decrypt encrypted keys manually
# 4. Use proper HSM/secure enclave for key storage