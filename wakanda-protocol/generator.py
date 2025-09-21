from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
import os
import json
from datetime import datetime
from openrouter_client import generate_policy_content
from prediction_model import MineralInvestmentPredictor
import uvicorn

app = FastAPI(
    title="Wakanda Protocol - SA Digital Government Generator",
    description="AI-powered generator for South African public sector digitalization strategies",
    version="1.0.0"
)

# Global instances
predictor = MineralInvestmentPredictor()

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    # Create outputs directory
    os.makedirs("outputs", exist_ok=True)
    
    # Initialize and train prediction model
    print("Initializing mineral investment prediction model...")
    df = predictor.create_synthetic_dataset(200)
    predictor.train_model(df)
    print("Prediction model ready!")

@app.get("/")
async def root():
    """API root endpoint"""
    return {
        "message": "Wakanda Protocol - Digital Government AI Generator",
        "version": "1.0.0",
        "endpoints": {
            "generate_policy": "/generate/{module}",
            "predict_investment": "/predict/mineral-investment",
            "list_modules": "/modules",
            "health": "/health"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/modules")
async def list_modules():
    """List available policy generation modules"""
    modules_dir = "prompts"
    if not os.path.exists(modules_dir):
        return {"modules": [], "error": "Prompts directory not found"}
    
    modules = []
    for file in os.listdir(modules_dir):
        if file.endswith('.txt') and file != 'system.txt':
            module_name = file.replace('.txt', '')
            modules.append({
                "name": module_name,
                "endpoint": f"/generate/{module_name}",
                "description": f"Generate {module_name.replace('_', ' ').title()} policy documentation"
            })
    
    return {"modules": modules}

@app.post("/generate/{module}")
async def generate_policy(module: str, background_tasks: BackgroundTasks):
    """
    Generate comprehensive policy documentation for a specific module
    
    Available modules:
    - assessment_policy: National Digital Government Policy
    - core_services: Citizen Services Digitalization 
    - infra_connectivity: Infrastructure and Connectivity
    - data_privacy_security: Data, Privacy & Security
    - skills_change_management: Skills & Change Management
    - inclusion_disability: Inclusion & Disability Access
    """
    try:
        # Load system prompt
        system_prompt_path = "prompts/system.txt"
        if not os.path.exists(system_prompt_path):
            raise HTTPException(status_code=500, detail="System prompt not found")
        
        with open(system_prompt_path, 'r') as f:
            system_prompt = f.read()
        
        # Load module prompt
        module_prompt_path = f"prompts/{module}.txt"
        if not os.path.exists(module_prompt_path):
            available_modules = [f.replace('.txt', '') for f in os.listdir('prompts') 
                               if f.endswith('.txt') and f != 'system.txt']
            raise HTTPException(
                status_code=404, 
                detail=f"Module '{module}' not found. Available modules: {available_modules}"
            )
        
        with open(module_prompt_path, 'r') as f:
            module_prompt = f.read()
        
        # Generate content using AI
        print(f"Generating policy content for module: {module}")
        content = generate_policy_content(module_prompt, system_prompt)
        
        # Create response
        response_data = {
            "module": module,
            "generated_at": datetime.now().isoformat(),
            "content": content,
            "word_count": len(content.split()),
            "character_count": len(content)
        }
        
        # Save to file in background
        def save_output():
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"outputs/{module}_{timestamp}.json"
            with open(filename, 'w') as f:
                json.dump(response_data, f, indent=2)
            print(f"Output saved to {filename}")
        
        background_tasks.add_task(save_output)
        
        return response_data
        
    except Exception as e:
        print(f"Error generating policy for {module}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")

@app.post("/predict/mineral-investment")
async def predict_mineral_investment(site_data: dict):
    """
    Predict investment score for a mineral site
    
    Expected input format:
    {
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
    """
    try:
        # Validate required fields
        required_fields = predictor.feature_names
        missing_fields = [field for field in required_fields if field not in site_data]
        
        if missing_fields:
            raise HTTPException(
                status_code=400, 
                detail=f"Missing required fields: {missing_fields}"
            )
        
        # Make prediction
        investment_score = predictor.predict_investment_score(site_data)
        
        # Classify investment attractiveness
        if investment_score >= 0.8:
            rating = "Highly Attractive"
        elif investment_score >= 0.6:
            rating = "Attractive"
        elif investment_score >= 0.4:
            rating = "Moderate"
        elif investment_score >= 0.2:
            rating = "Low Potential"
        else:
            rating = "Not Recommended"
        
        return {
            "investment_score": round(investment_score, 3),
            "rating": rating,
            "confidence": "High" if 0.2 <= investment_score <= 0.8 else "Medium",
            "features_analyzed": len(required_fields),
            "generated_at": datetime.now().isoformat(),
            "recommendations": {
                "proceed": investment_score >= 0.5,
                "key_factors": "governance_score, logistics_score, reserve_tonnes",
                "risk_factors": "political_risk, extraction_cost, transport_cost"
            }
        }
        
    except Exception as e:
        print(f"Error in mineral investment prediction: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.get("/outputs")
async def list_outputs():
    """List generated policy outputs"""
    outputs_dir = "outputs"
    if not os.path.exists(outputs_dir):
        return {"outputs": []}
    
    outputs = []
    for file in os.listdir(outputs_dir):
        if file.endswith('.json'):
            file_path = os.path.join(outputs_dir, file)
            file_stat = os.stat(file_path)
            outputs.append({
                "filename": file,
                "size_bytes": file_stat.st_size,
                "created_at": datetime.fromtimestamp(file_stat.st_ctime).isoformat(),
                "download_url": f"/outputs/{file}"
            })
    
    return {"outputs": outputs}

@app.get("/outputs/{filename}")
async def download_output(filename: str):
    """Download a specific output file"""
    file_path = os.path.join("outputs", filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    
    with open(file_path, 'r') as f:
        content = json.load(f)
    
    return content

if __name__ == "__main__":
    print("Starting Wakanda Protocol AI Generator...")
    print("Available endpoints:")
    print("- GET /: API documentation")
    print("- GET /modules: List available policy modules")
    print("- POST /generate/{module}: Generate policy content")
    print("- POST /predict/mineral-investment: Predict mineral investment score")
    print("- GET /outputs: List generated outputs")
    
    uvicorn.run(
        "generator:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=True,
        log_level="info"
    )