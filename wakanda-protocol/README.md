# Wakanda Protocol - AI Generator for SA Digital Government

A comprehensive AI-powered system for generating detailed digitalization strategies for the South African public sector.

## 🚀 Features

- **AI Policy Generation**: Generates 2000+ word policy documents using OpenRouter API
- **Mineral Investment Prediction**: ML model for scoring mineral investment opportunities
- **Multiple API Integrations**: OpenRouter, Alpha Vantage, Weather, Mastercard clients
- **Secure Configuration**: Environment-based secrets management with Vault support
- **FastAPI Service**: RESTful API with automatic documentation
- **Comprehensive Modules**: 6 key digitalization areas covered

## 📁 Project Structure

```
wakanda-protocol/
├── services/                 # Microservices architecture
│   ├── knowledge_hub/       # AI content generation
│   ├── finance/             # Financial analysis
│   ├── minerals/            # Investment prediction
│   └── drones/              # Humanitarian logistics
├── infra/                   # Infrastructure as Code
│   ├── docker/              # Container configurations
│   ├── k8s/                 # Kubernetes manifests
│   └── terraform/           # Infrastructure provisioning
├── prompts/                 # AI prompt templates
├── outputs/                 # Generated policy documents
├── scripts/                 # Deployment and utility scripts
├── config.py               # Configuration management
├── generator.py            # Main FastAPI application
├── prediction_model.py     # ML model for mineral investment
├── *_client.py            # API client stubs
└── requirements.txt        # Python dependencies
```

## 🔧 Installation

1. **Clone and Setup**:
```bash
cd wakanda-protocol
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. **Environment Configuration**:
```bash
cp .env.example .env
# Edit .env with your API keys
```

3. **Run the Service**:
```bash
python generator.py
```

The API will be available at `http://localhost:8000` with automatic documentation at `/docs`.

## 🔑 API Keys Setup

### OpenRouter (Required for AI generation)
1. Sign up at [openrouter.ai](https://openrouter.ai)
2. Create API key
3. Add to `.env`: `OPENROUTER_API_KEY=sk-...`

### Alpha Vantage (Economic data)
1. Register at [alphavantage.co](https://alphavantage.co)
2. Get free API key
3. Add to `.env`: `ALPHAVANTAGE_KEY=your_key`

### Weather API (OpenWeatherMap)
1. Sign up at [openweathermap.org](https://openweathermap.org)
2. Generate API key
3. Add to `.env`: `WEATHER_API_KEY=your_key`

### Mastercard (Partner APIs - Optional)
1. Join [Mastercard Developers](https://developer.mastercard.com)
2. Request sandbox credentials
3. Add to `.env`: Client ID and Secret

## 📊 Usage Examples

### 1. Generate Policy Documentation
```bash
curl -X POST "http://localhost:8000/generate/assessment_policy" \
     -H "Content-Type: application/json"
```

### 2. Predict Mineral Investment Score
```bash
curl -X POST "http://localhost:8000/predict/mineral-investment" \
     -H "Content-Type: application/json" \
     -d '{
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
     }'
```

### 3. List Available Modules
```bash
curl "http://localhost:8000/modules"
```

## 🏛️ Policy Generation Modules

1. **Assessment & Policy**: National Digital Government Strategy
2. **Core Services**: Citizen services digitalization (ID, grants, licenses)
3. **Infrastructure**: Connectivity, cloud, security architecture
4. **Data & Privacy**: POPIA compliance, security controls
5. **Skills & Change**: Capacity building and training programs
6. **Inclusion & Disability**: Accessibility and digital inclusion

Each module generates 2000+ words of detailed, actionable policy content.

## 🤖 AI System Prompts

The system uses carefully crafted prompts to ensure:
- **Comprehensive Output**: 2000+ word detailed responses
- **SA Context**: References to POPIA, DPSA, SA Connect
- **Practical Focus**: Implementation checklists and timelines
- **Legal Compliance**: Regulatory alignment and risk mitigation
- **Technical Depth**: Architecture diagrams and API specifications

## 🔒 Security & Compliance

- **Environment Variables**: No secrets in code
- **Vault Integration**: Production-ready secret management
- **POPIA Compliance**: Privacy-by-design principles
- **API Security**: Rate limiting, authentication, input validation
- **Audit Logging**: Full request/response tracking

## 📈 Mineral Investment Prediction

The ML model analyzes 11 key factors:
- Reserve tonnage and price trends
- Governance and political risk scores
- Logistics and transport costs
- Environmental compliance
- Local processing capabilities

**Model Performance**:
- Algorithm: Random Forest Regressor
- Features: 11 economic and risk indicators
- Output: Investment score (0-1) with risk rating
- Accuracy: R² > 0.85 on synthetic data

## 🚀 Deployment

### Docker (Recommended)
```bash
# Build image
docker build -t wakanda-protocol .

# Run container
docker run -p 8000:8000 --env-file .env wakanda-protocol
```

### Kubernetes
```bash
kubectl apply -f infra/k8s/
```

### Production Considerations
- Use Gunicorn + Uvicorn for production ASGI
- Configure Prometheus monitoring
- Set up Grafana dashboards
- Implement rate limiting and caching
- Use managed databases for persistence

## 🔍 Monitoring & Observability

- **Health Checks**: `/health` endpoint
- **Metrics**: Request latency, error rates, model performance
- **Logging**: Structured JSON logs with correlation IDs
- **Alerts**: Policy generation failures, model degradation

## 🌍 South African Context

This system is specifically designed for South African digitalization:

- **Legal Framework**: POPIA, DPSA guidelines, provincial coordination
- **Infrastructure**: SA Connect, SITA integration, rural connectivity
- **Languages**: 11 official languages support planning
- **Economic Focus**: Mineral resources, skills development, inclusion
- **Government Structure**: National, provincial, municipal coordination

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-module`
3. Add comprehensive tests
4. Update documentation
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 🆘 Support

For technical support or feature requests:
- Create an issue in the repository
- Refer to API documentation at `/docs`
- Check the troubleshooting guide

## 🔮 Roadmap

- [ ] Additional AI models (Claude, Gemini integration)
- [ ] Real-time economic data feeds
- [ ] Multi-language policy generation
- [ ] Advanced visualization dashboards
- [ ] Municipal-level planning tools
- [ ] Citizen feedback integration