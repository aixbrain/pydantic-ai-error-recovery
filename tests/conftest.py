import pytest
from pydantic_ai import models

# No test may hit a real model API.
models.ALLOW_MODEL_REQUESTS = False


@pytest.fixture
def anyio_backend() -> str:
    return 'asyncio'
