$env:ENV = "local"
poetry install
./run_alembic_check.ps1
python -m skyvern.forge.app $args 