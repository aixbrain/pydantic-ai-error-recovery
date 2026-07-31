.PHONY: install lint format typecheck test testcov all

install:
	uv sync --extra dev

lint:
	uv run ruff check .

format:
	uv run ruff format .

typecheck:
	uv run pyright

test:
	uv run pytest -q

testcov:
	uv run pytest --cov -q

all: lint typecheck testcov
