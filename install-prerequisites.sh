#!/bin/bash

echo "🚀 Codex Sanctium Enterprise Stack Setup"
echo "========================================="

# Phase 1: .NET 9 Installation
echo "📦 Installing .NET 9 SDK..."
./install-dotnet.sh

# Phase 2: Node.js and Svelte Setup
echo "🟢 Setting up Node.js and Svelte..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Phase 3: Elixir and Phoenix LiveView
echo "💜 Installing Elixir and Phoenix LiveView..."
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt-get update
sudo apt-get install -y elixir erlang-dev erlang-xmerl

# Install Phoenix
mix local.hex --force
mix archive.install hex phx_new --force

# Phase 4: Docker and Kubernetes
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install kubectl
echo "☸️ Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
echo "🎯 Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

echo "✅ All prerequisites installed!"
echo "Next: Run './setup-projects.sh' to create the project structure"