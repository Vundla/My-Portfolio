#!/bin/bash

# .NET 9 Installation Script for Ubuntu/WSL
echo "🔧 Installing .NET 9 SDK..."

# Add Microsoft package signing key and repository
wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package list
sudo apt-get update

# Install .NET 9 SDK
sudo apt-get install -y dotnet-sdk-9.0

# Verify installation
echo "✅ .NET 9 Installation Complete!"
dotnet --version
dotnet --info