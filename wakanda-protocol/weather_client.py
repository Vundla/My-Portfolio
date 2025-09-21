import requests
from config import WEATHER_KEY, REQUEST_TIMEOUT
from tenacity import retry, stop_after_attempt, wait_exponential

def get_weather(lat, lon, units="metric"):
    """
    Get current weather data from OpenWeatherMap
    
    Args:
        lat: Latitude
        lon: Longitude  
        units: Temperature units (metric, imperial, kelvin)
    
    Returns:
        JSON response with weather data
    """
    if not WEATHER_KEY:
        raise ValueError("WEATHER_API_KEY not configured")
    
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": WEATHER_KEY,
        "units": units
    }
    
    response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
    response.raise_for_status()
    return response.json()

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def get_forecast(lat, lon, units="metric", cnt=5):
    """Get 5-day weather forecast"""
    if not WEATHER_KEY:
        raise ValueError("WEATHER_API_KEY not configured")
    
    url = "https://api.openweathermap.org/data/2.5/forecast"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": WEATHER_KEY,
        "units": units,
        "cnt": cnt
    }
    
    response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
    response.raise_for_status()
    return response.json()

def get_weather_by_city(city_name, country_code=None, units="metric"):
    """Get weather by city name"""
    if not WEATHER_KEY:
        raise ValueError("WEATHER_API_KEY not configured")
    
    url = "https://api.openweathermap.org/data/2.5/weather"
    
    if country_code:
        city_query = f"{city_name},{country_code}"
    else:
        city_query = city_name
    
    params = {
        "q": city_query,
        "appid": WEATHER_KEY,
        "units": units
    }
    
    response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
    response.raise_for_status()
    return response.json()

# South African major cities coordinates for quick reference
SA_CITIES = {
    "johannesburg": (-26.2041, 28.0473),
    "cape_town": (-33.9249, 18.4241),
    "durban": (-29.8587, 31.0218),
    "pretoria": (-25.7479, 28.2293),
    "port_elizabeth": (-33.9608, 25.6022),
    "bloemfontein": (-29.0852, 26.1596),
    "east_london": (-33.0153, 27.9116),
    "pietermaritzburg": (-29.6036, 30.3794),
    "polokwane": (-23.9045, 29.4689),
    "kimberley": (-28.7282, 24.7499)
}

def get_sa_city_weather(city_name, units="metric"):
    """Get weather for South African cities"""
    city_lower = city_name.lower().replace(" ", "_")
    if city_lower in SA_CITIES:
        lat, lon = SA_CITIES[city_lower]
        return get_weather(lat, lon, units)
    else:
        return get_weather_by_city(city_name, "ZA", units)