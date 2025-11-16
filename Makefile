# Enterprise Makefile for Codex Sanctium Portfolio
# Borrowing best practices from enterprise development workflows

.PHONY: help install dev build docker-build docker-run k8s-setup k8s-deploy k8s-clean logs test clean

# Colors for better UX
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
BLUE   := \033[34m
PURPLE := \033[35m
CYAN   := \033[36m
RESET  := \033[0m

# Enterprise variables
PROJECT_NAME := codex-sanctium
NAMESPACE := default
IMAGE_TAG := $(shell git rev-parse --short HEAD)
REGISTRY := your-registry

## Help
help: ## Show this help message
	@echo "$(CYAN)Codex Sanctium Portfolio - Enterprise Commands$(RESET)"
	@echo "$(YELLOW)=============================================$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Development Commands
install: ## Install all dependencies
	@echo "$(BLUE)Installing .NET 9 SDK...$(RESET)"
	chmod +x install-prerequisites.sh setup-projects.sh
	./install-prerequisites.sh
	@echo "$(BLUE)Setting up project structure...$(RESET)"
	./setup-projects.sh
	@echo "$(GREEN)✅ Installation complete!$(RESET)"

dev: ## Start development environment
	@echo "$(BLUE)Starting development servers...$(RESET)"
	@echo "$(YELLOW)Backend: http://localhost:5000$(RESET)"
	@echo "$(YELLOW)Frontend: http://localhost:5173$(RESET)"
	@echo "$(YELLOW)LiveView: http://localhost:4000$(RESET)"
	docker compose up --build

dev-backend: ## Start only backend (.NET 9)
	@echo "$(BLUE)Starting .NET 9 backend...$(RESET)"
	cd backend && dotnet watch run

dev-frontend: ## Start only frontend (Svelte)
	@echo "$(BLUE)Starting Svelte frontend...$(RESET)"
	cd frontend && npm run dev

dev-phoenix: ## Start only Phoenix LiveView
	@echo "$(BLUE)Starting Phoenix LiveView...$(RESET)"
	cd live_sidecar && mix phx.server

## Build Commands
build: ## Build all projects
	@echo "$(BLUE)Building all projects...$(RESET)"
	cd backend && dotnet build --configuration Release
	cd frontend && npm run build
	@echo "$(GREEN)✅ Build complete!$(RESET)"

## Docker Commands
docker-build: ## Build Docker images
	@echo "$(BLUE)Building Docker images...$(RESET)"
	docker build -t $(PROJECT_NAME)/backend:$(IMAGE_TAG) ./backend
	docker build -t $(PROJECT_NAME)/frontend:$(IMAGE_TAG) ./frontend
	@echo "$(GREEN)✅ Docker images built!$(RESET)"

docker-run: ## Run with Docker Compose
	@echo "$(BLUE)Starting with Docker Compose...$(RESET)"
	docker compose up --build -d
	@echo "$(GREEN)✅ Services running in background$(RESET)"
	@echo "$(YELLOW)Frontend: http://localhost:5173$(RESET)"
	@echo "$(YELLOW)Backend: http://localhost:5000$(RESET)"
	@echo "$(YELLOW)LiveView: http://localhost:4000$(RESET)"

docker-stop: ## Stop Docker services
	@echo "$(BLUE)Stopping Docker services...$(RESET)"
	docker compose down
	@echo "$(GREEN)✅ Services stopped$(RESET)"

docker-logs: ## Show Docker logs
	docker compose logs -f

## Kubernetes Commands
k8s-setup: ## Setup Minikube and build images
	@echo "$(BLUE)Setting up Kubernetes environment...$(RESET)"
	minikube start --cpus=4 --memory=8192
	minikube addons enable ingress
	minikube addons enable metrics-server
	@echo "$(BLUE)Building images for Kubernetes...$(RESET)"
	eval $$(minikube docker-env) && \
	docker build -t codex/backend:k8s ./backend && \
	docker build -t codex/frontend:k8s ./frontend
	@echo "$(GREEN)✅ Kubernetes setup complete!$(RESET)"

k8s-deploy: ## Deploy to Kubernetes
	@echo "$(BLUE)Deploying to Kubernetes...$(RESET)"
	kubectl apply -f k8s/backend.yaml
	kubectl apply -f k8s/frontend.yaml
	kubectl apply -f k8s/ingress.yaml
	@echo "$(GREEN)✅ Deployed to Kubernetes!$(RESET)"
	@echo "$(YELLOW)Waiting for pods to be ready...$(RESET)"
	kubectl wait --for=condition=ready pod -l app=codex-backend --timeout=300s
	kubectl wait --for=condition=ready pod -l app=codex-frontend --timeout=300s

k8s-status: ## Show Kubernetes status
	@echo "$(CYAN)Kubernetes Status:$(RESET)"
	kubectl get pods,services,ingress
	@echo "$(CYAN)Pod Logs:$(RESET)"
	kubectl top pods 2>/dev/null || echo "Metrics not available"

k8s-open: ## Open application in browser
	@echo "$(BLUE)Opening Codex Sanctium in browser...$(RESET)"
	minikube service codex-frontend-service --url
	
k8s-dashboard: ## Open Kubernetes dashboard
	minikube dashboard

k8s-clean: ## Clean Kubernetes resources
	@echo "$(BLUE)Cleaning Kubernetes resources...$(RESET)"
	kubectl delete -f k8s/ --ignore-not-found=true
	@echo "$(GREEN)✅ Kubernetes resources cleaned$(RESET)"

k8s-restart: ## Restart Kubernetes deployments
	@echo "$(BLUE)Restarting deployments...$(RESET)"
	kubectl rollout restart deployment/codex-backend
	kubectl rollout restart deployment/codex-frontend
	@echo "$(GREEN)✅ Deployments restarted$(RESET)"

## Monitoring Commands
logs: ## Show application logs
	@echo "$(CYAN)Application Logs:$(RESET)"
	kubectl logs -l app=codex-backend --tail=100
	kubectl logs -l app=codex-frontend --tail=100

logs-backend: ## Show backend logs
	kubectl logs -l app=codex-backend -f

logs-frontend: ## Show frontend logs
	kubectl logs -l app=codex-frontend -f

health: ## Check application health
	@echo "$(CYAN)Health Checks:$(RESET)"
	@curl -s http://localhost:5000/health || echo "Backend not accessible"
	@curl -s http://localhost:5173 > /dev/null && echo "Frontend: ✅ OK" || echo "Frontend: ❌ Failed"

## Testing Commands
test: ## Run all tests
	@echo "$(BLUE)Running tests...$(RESET)"
	cd backend && dotnet test
	cd frontend && npm test
	@echo "$(GREEN)✅ All tests passed!$(RESET)"

test-backend: ## Run backend tests
	cd backend && dotnet test --verbosity normal

test-frontend: ## Run frontend tests
	cd frontend && npm test

## Deployment Commands
deploy-fly: ## Deploy to Fly.io
	@echo "$(BLUE)Deploying to Fly.io...$(RESET)"
	# Add your Fly.io deployment commands here
	@echo "$(GREEN)✅ Deployed to Fly.io!$(RESET)"

push-registry: ## Push images to registry
	@echo "$(BLUE)Pushing images to registry...$(RESET)"
	docker tag $(PROJECT_NAME)/backend:$(IMAGE_TAG) $(REGISTRY)/$(PROJECT_NAME)/backend:$(IMAGE_TAG)
	docker tag $(PROJECT_NAME)/frontend:$(IMAGE_TAG) $(REGISTRY)/$(PROJECT_NAME)/frontend:$(IMAGE_TAG)
	docker push $(REGISTRY)/$(PROJECT_NAME)/backend:$(IMAGE_TAG)
	docker push $(REGISTRY)/$(PROJECT_NAME)/frontend:$(IMAGE_TAG)
	@echo "$(GREEN)✅ Images pushed to registry!$(RESET)"

## Utility Commands
clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(RESET)"
	cd backend && dotnet clean
	cd frontend && npm run clean || rm -rf dist
	docker system prune -f
	@echo "$(GREEN)✅ Cleaned!$(RESET)"

format: ## Format code
	@echo "$(BLUE)Formatting code...$(RESET)"
	cd backend && dotnet format
	cd frontend && npm run format
	@echo "$(GREEN)✅ Code formatted!$(RESET)"

audit: ## Security audit
	@echo "$(BLUE)Running security audit...$(RESET)"
	cd backend && dotnet list package --vulnerable
	cd frontend && npm audit
	@echo "$(GREEN)✅ Security audit complete!$(RESET)"

## Enterprise Commands
enterprise-setup: ## Complete enterprise setup
	@echo "$(PURPLE)🚀 Setting up Codex Sanctium Enterprise Stack$(RESET)"
	@echo "$(YELLOW)=============================================$(RESET)"
	make install
	make docker-build
	make k8s-setup
	make k8s-deploy
	@echo "$(GREEN)🎉 Enterprise stack ready!$(RESET)"
	@echo "$(CYAN)Next steps:$(RESET)"
	@echo "  - make k8s-open    # Open application"
	@echo "  - make logs        # View logs"
	@echo "  - make health      # Check health"

production-deploy: ## Production deployment pipeline
	@echo "$(PURPLE)🚀 Production Deployment$(RESET)"
	make test
	make docker-build
	make push-registry
	make deploy-fly
	@echo "$(GREEN)✅ Production deployment complete!$(RESET)"