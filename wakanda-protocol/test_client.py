#!/usr/bin/env python3
"""
Simple CLI client for testing the Wakanda Protocol AI Generator
"""

import requests
import json
import sys
import time
from typing import Dict, Any

BASE_URL = "http://localhost:8000"

def test_connection():
    """Test if the API is running"""
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        response.raise_for_status()
        print("✅ API is running and healthy")
        return True
    except requests.exceptions.RequestException as e:
        print(f"❌ API connection failed: {e}")
        return False

def list_modules():
    """List available policy generation modules"""
    try:
        response = requests.get(f"{BASE_URL}/modules")
        response.raise_for_status()
        data = response.json()
        
        print("\n📋 Available Policy Modules:")
        print("-" * 50)
        for module in data["modules"]:
            print(f"• {module['name']}: {module['description']}")
        return data["modules"]
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to list modules: {e}")
        return []

def generate_policy(module_name: str):
    """Generate policy content for a specific module"""
    print(f"\n🤖 Generating policy content for: {module_name}")
    print("This may take 30-60 seconds...")
    
    try:
        start_time = time.time()
        response = requests.post(f"{BASE_URL}/generate/{module_name}", timeout=120)
        response.raise_for_status()
        
        data = response.json()
        generation_time = time.time() - start_time
        
        print(f"✅ Generation completed in {generation_time:.1f} seconds")
        print(f"📄 Content length: {data['word_count']} words ({data['character_count']} characters)")
        print(f"🕒 Generated at: {data['generated_at']}")
        
        # Save to file
        filename = f"{module_name}_policy.txt"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(data['content'])
        print(f"💾 Content saved to: {filename}")
        
        # Show preview
        preview = data['content'][:500] + "..." if len(data['content']) > 500 else data['content']
        print(f"\n📖 Preview:\n{preview}")
        
        return data
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Policy generation failed: {e}")
        return None

def predict_investment():
    """Test mineral investment prediction with sample data"""
    sample_data = {
        "reserve_tonnes": 5000,
        "price_trend": 0.08,
        "logistics_score": 0.7,
        "governance_score": 0.6,
        "extraction_cost": 80,
        "transport_cost": 45,
        "political_risk": 0.3,
        "environmental_score": 0.8,
        "proximity_to_ports": 150,
        "energy_cost_index": 1.2,
        "local_refining_capacity": 0.4
    }
    
    print("\n💎 Testing mineral investment prediction...")
    print(f"Input data: {json.dumps(sample_data, indent=2)}")
    
    try:
        response = requests.post(f"{BASE_URL}/predict/mineral-investment", json=sample_data)
        response.raise_for_status()
        
        data = response.json()
        print(f"\n📊 Investment Analysis Results:")
        print(f"• Score: {data['investment_score']} ({data['rating']})")
        print(f"• Confidence: {data['confidence']}")
        print(f"• Recommendation: {'Proceed' if data['recommendations']['proceed'] else 'Caution'}")
        print(f"• Key Factors: {data['recommendations']['key_factors']}")
        print(f"• Risk Factors: {data['recommendations']['risk_factors']}")
        
        return data
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Investment prediction failed: {e}")
        return None

def list_outputs():
    """List generated policy outputs"""
    try:
        response = requests.get(f"{BASE_URL}/outputs")
        response.raise_for_status()
        data = response.json()
        
        if not data["outputs"]:
            print("\n📂 No outputs found")
            return
        
        print("\n📁 Generated Outputs:")
        print("-" * 60)
        for output in data["outputs"]:
            size_kb = output["size_bytes"] / 1024
            print(f"• {output['filename']} ({size_kb:.1f} KB) - {output['created_at']}")
        
        return data["outputs"]
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to list outputs: {e}")
        return []

def main():
    """Main CLI interface"""
    print("🌍 Wakanda Protocol - AI Generator CLI")
    print("=====================================")
    
    # Check connection
    if not test_connection():
        print("\n💡 Make sure the API is running: python generator.py")
        sys.exit(1)
    
    # Show menu
    while True:
        print("\n🔧 Available Actions:")
        print("1. List available modules")
        print("2. Generate policy content")
        print("3. Test investment prediction")
        print("4. List generated outputs")
        print("5. Exit")
        
        choice = input("\nSelect an option (1-5): ").strip()
        
        if choice == "1":
            list_modules()
        
        elif choice == "2":
            modules = list_modules()
            if modules:
                print("\nEnter module name from the list above:")
                module_name = input("Module: ").strip()
                if module_name:
                    generate_policy(module_name)
        
        elif choice == "3":
            predict_investment()
        
        elif choice == "4":
            list_outputs()
        
        elif choice == "5":
            print("👋 Goodbye!")
            break
        
        else:
            print("❌ Invalid choice. Please select 1-5.")

if __name__ == "__main__":
    main()