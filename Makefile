.PHONY: install lint format format-check typecheck test testcov all

install:
	uv sync --extra dev

lint:
	uv run ruff check .

format:
	uv run ruff format .

format-check:
	uv run ruff format --check .

typecheck:
	uv run pyright

test:
	uv run pytest -q

testcov:
	uv run pytest --cov -q

all: lint format-check typecheck testcov
