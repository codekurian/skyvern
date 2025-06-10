$env:ENV = "local"
python -m alembic upgrade head
python -m alembic check 