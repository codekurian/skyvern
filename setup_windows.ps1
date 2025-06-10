# Skyvern Windows PowerShell Setup Script

Write-Host "=== Skyvern Windows Setup ==="

function Check-Command($cmd) {
    $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

# 1. Check for required commands
$required = @("python", "pip", "npm", "psql")
foreach ($cmd in $required) {
    if (-not (Check-Command $cmd)) {
        Write-Host "Error: $cmd is not installed or not in your PATH." -ForegroundColor Red
        if ($cmd -eq "psql") {
            Write-Host "Please install PostgreSQL from https://www.postgresql.org/download/windows/ and add its bin directory to your PATH."
        }
        exit 1
    }
}

# 2. Check if PostgreSQL is running
try {
    & pg_isready | Out-Null
} catch {
    Write-Host "PostgreSQL does not appear to be running."
    Write-Host "Start it from the Start Menu or Services, then rerun this script."
    exit 1
}

# 3. Create user and database if needed
try {
    & psql -U skyvern -d skyvern -c "\q" 2>$null
    Write-Host "Database and user 'skyvern' already exist."
} catch {
    Write-Host "Creating user and database 'skyvern'..."
    try { & createuser -U postgres skyvern } catch {}
    try { & createdb -U postgres -O skyvern skyvern } catch {}
}

# 4. Set DATABASE_STRING in .env
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
}

$envContent = Get-Content ".env"
$found = $false
for ($i = 0; $i -lt $envContent.Count; $i++) {
    if ($envContent[$i] -match "^DATABASE_STRING=") {
        $envContent[$i] = "DATABASE_STRING=postgresql+psycopg://skyvern:skyvern@localhost:5432/skyvern"
        $found = $true
    }
}
if (-not $found) {
    Add-Content ".env" "DATABASE_STRING=postgresql+psycopg://skyvern:skyvern@localhost:5432/skyvern"
} else {
    $envContent | Set-Content ".env"
}
Write-Host "DATABASE_STRING set in .env"

# 5. Install Python and Node.js dependencies
Write-Host "Installing Python dependencies with pip..."
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) { Write-Host "pip install failed"; exit 1 }

Write-Host "Installing frontend dependencies with npm..."
Push-Location skyvern-frontend
npm install
Pop-Location

# 6. Run Alembic migrations
Write-Host "Running Alembic migrations..."
python -m alembic upgrade head
python -m alembic check

# 7. (Optional) Create organization and API token
if (Test-Path "scripts/create_organization.py") {
    python scripts/create_organization.py Skyvern-Open-Source
}

Write-Host "=== Skyvern Windows setup complete! ==="
Write-Host "You can now run the backend and frontend as usual." 