$env:ENV = "local"
cd skyvern-frontend
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "[ERROR] Please add your api keys to the skyvern-frontend/.env file."
}
npm install
npm run dev $args 