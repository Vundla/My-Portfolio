import requests
from config import ALPHAVANTAGE_KEY, REQUEST_TIMEOUT
from tenacity import retry, stop_after_attempt, wait_exponential
import time

BASE = "https://www.alphavantage.co/query"

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def get_stock_data(symbol, function="TIME_SERIES_DAILY"):
    """
    Get stock market data from Alpha Vantage API
    
    Args:
        symbol: Stock symbol (e.g., 'AAPL', 'JSE:AGL')
        function: API function to call
    
    Returns:
        JSON response with stock data
    """
    if not ALPHAVANTAGE_KEY:
        raise ValueError("ALPHAVANTAGE_KEY not configured")
    
    params = {
        "function": function,
        "symbol": symbol,
        "apikey": ALPHAVANTAGE_KEY,
        "outputsize": "compact"
    }
    
    response = requests.get(BASE, params=params, timeout=REQUEST_TIMEOUT)
    response.raise_for_status()
    return response.json()

def get_forex_data(from_currency, to_currency):
    """Get forex exchange rates"""
    return get_stock_data(
        symbol=f"{from_currency}{to_currency}",
        function="FX_DAILY"
    )

def get_crypto_data(symbol):
    """Get cryptocurrency data"""
    return get_stock_data(
        symbol=symbol,
        function="DIGITAL_CURRENCY_DAILY"
    )

def get_economic_indicators(indicator="REAL_GDP"):
    """
    Get economic indicators for investment analysis
    
    Common indicators:
    - REAL_GDP: Real GDP
    - INFLATION: Inflation rate
    - UNEMPLOYMENT: Unemployment rate
    """
    params = {
        "function": indicator,
        "interval": "annual",
        "apikey": ALPHAVANTAGE_KEY
    }
    
    response = requests.get(BASE, params=params, timeout=REQUEST_TIMEOUT)
    response.raise_for_status()
    return response.json()

# Rate limiting helper for Alpha Vantage (5 API requests per minute for free tier)
class RateLimiter:
    def __init__(self, calls_per_minute=5):
        self.calls_per_minute = calls_per_minute
        self.calls = []
    
    def wait_if_needed(self):
        now = time.time()
        # Remove calls older than 1 minute
        self.calls = [call_time for call_time in self.calls if now - call_time < 60]
        
        if len(self.calls) >= self.calls_per_minute:
            sleep_time = 60 - (now - self.calls[0])
            if sleep_time > 0:
                time.sleep(sleep_time)
        
        self.calls.append(now)

rate_limiter = RateLimiter()