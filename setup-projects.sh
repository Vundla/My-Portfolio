#!/bin/bash

echo "🏗️ Creating Codex Sanctium Project Structure..."

# Create .NET Backend
echo "🔷 Setting up .NET 9 Backend..."
cd backend
dotnet restore
dotnet build

# Create Svelte Frontend 
echo "🟠 Setting up Svelte Frontend..."
cd ../frontend
npm install

# Create Phoenix LiveView Sidecar
echo "💜 Setting up Phoenix LiveView..."
cd ..
mix phx.new live_sidecar --live
cd live_sidecar

# Add LiveSvelte to Phoenix
echo "Adding LiveSvelte integration..."
cat >> mix.exs << 'EOF'
  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.2"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.2"},
      {:live_svelte, "~> 0.13.0"}
    ]
  end
EOF

mix deps.get

echo "✅ Project structure created successfully!"
echo ""
echo "🚀 Next steps:"
echo "1. Run: docker compose up --build"
echo "2. Or run individual services:"
echo "   - Backend: cd backend && dotnet run"
echo "   - Frontend: cd frontend && npm run dev"  
echo "   - LiveView: cd live_sidecar && mix phx.server"