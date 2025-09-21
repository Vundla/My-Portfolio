import os
from dotenv import load_dotenv

load_dotenv()

def get_env(key, default=None):
    """Get environment variable with optional vault fallback"""
    v = os.getenv(key)
    if v:
        return v
    # TODO: implement vault fetch here for production
    # Example vault integration:
    # import hvac
    # client = hvac.Client(url=os.getenv('VAULT_ADDR'))
    # client.token = os.getenv('VAULT_TOKEN')
    # secret = client.secrets.kv.v2.read_secret_version(path=f'config/{key}')
    # return secret['data']['data'].get(key, default)
    return default

# API Configuration
OPENROUTER_KEY = get_env("OPENROUTER_API_KEY")
OPENROUTER_MODEL = get_env("OPENROUTER_MODEL", "gpt-4o-mini")
ALPHAVANTAGE_KEY = get_env("ALPHAVANTAGE_KEY")
MASTERCARD_CLIENT_ID = get_env("MASTERCARD_CLIENT_ID")
MASTERCARD_CLIENT_SECRET = get_env("MASTERCARD_CLIENT_SECRET")
WEATHER_KEY = get_env("WEATHER_API_KEY")

# Vault Configuration
VAULT_ADDR = get_env("VAULT_ADDR")
VAULT_TOKEN = get_env("VAULT_TOKEN")

# Application Configuration
MAX_TOKENS = 4000
REQUEST_TIMEOUT = 120
RETRY_ATTEMPTS = 3