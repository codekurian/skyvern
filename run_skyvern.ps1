# Set environment variable
$env:ENV = "local"

# Kill any process using port 8000
$port = 8000
$pid = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -First 1).OwningProcess
if ($pid) {
    try {
        Stop-Process -Id $pid -Force
        Write-Host "Stopped process on port $port (PID: $pid)"
    } catch {
        Write-Host "Failed to stop process on port $port (PID: $pid)"
    }
}

# Ensure .env exists
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Please add your api keys to the .env file."
}

# Install dependencies
poetry install

# Run Alembic migrations and check
./run_alembic_check.ps1

# Start backend using poetry run
poetry run python -m skyvern.forge.app $args 