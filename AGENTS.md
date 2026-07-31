# pydantic-ai-error-recovery

## Repository purpose

`pydantic-ai-error-recovery` is a standalone capability package for Pydantic AI:
tool-call error recovery (`ToolErrorRecovery`). It turns tool failures into
graceful degradation without hiding bugs.

Pydantic AI core owns the primitive runtime (agent loop, hooks, models,
toolsets). This package is a policy composition over those primitives. When a
change needs new core semantics, propose it to Pydantic AI core instead of
working around it here.

Style and conventions follow the official capability library,
[pydantic-ai-harness](https://github.com/pydantic/pydantic-ai-harness)
(`guardrails` is the closest reference capability).

## Design rules

- The governing principle: recovery makes the user surface quieter and the
  operator surface louder. Every recovery is logged; a bug is never disguised
  as success.
- Control-flow exceptions (`ModelRetry`/`ToolRetryError`, `ToolFailed`/`ToolFailedError`,
  `CallDeferred`, `ApprovalRequired`, `SkipToolExecution`) must always propagate
  untouched, regardless of classifier configuration.
- All tool-recovery logic lives in the single `wrap_tool_execute` hook;
  `on_tool_execute_error` is deliberately not implemented (one counter path,
  no double counting).
- The recovery budget counts final recoveries, not retry attempts, and is
  checked before recovering.
- Retry eligibility is `classify`'s job alone. It is re-invoked on every attempt,
  so a changed error type ends the retrying through its own branch; the outcome
  carries no second type filter.
- User callables (`classify`) may be sync or async and may take an optional
  leading `RunContext`, detected from the parameters the call fills. Nothing they
  raise is intended, so a bug in one stays fatal and is chained to the failure it
  was handling, never substituted for it.
- The model-facing default text names the exception type but never includes
  `str(error)` -- exception messages can carry secrets and would reach the user
  through the model. The full message stays on the operator surface (log).
  Exposing more is opt-in (`label`, `format_error`, `include_traceback`).

## Coding standards

- Python 3.11+ (`assert_never`, `match`)
- pyright strict; avoid `Any` in public signatures where practical
- ruff: line-length 120, single quotes, max-complexity 15
- 100% branch coverage, enforced by `make testcov`
- docstrings use single backticks (markdown), not RST double backticks
- no em-dashes in prose, docstrings, comments, or commit messages; use `--`
- document the why and the non-obvious; don't restate what the code says

## Commands

```bash
make install    # uv sync --extra dev
make format     # ruff format
make lint       # ruff check
make typecheck  # pyright strict
make test       # pytest
make testcov    # pytest with 100% branch coverage
make all        # lint + typecheck + testcov
```

Run `make all` before every commit.

## File structure

Each capability owns its module and its support units; the public API lives only
in `__init__.py`. Names inside private modules stay plain (module privacy is the
boundary, matching the harness `_shared.py` pattern).

Inside a capability module, methods are grouped with `# --- ... ---` markers
(pydantic-ai core's own in-class style), helpers separated from the recovery
paths. Keep new methods inside the group they belong to.

- `pydantic_ai_error_recovery/__init__.py` -- public exports (sorted `__all__`)
- `pydantic_ai_error_recovery/_capability.py` -- `ToolErrorRecovery` (+ control-flow set)
- `pydantic_ai_error_recovery/_outcome.py` -- `RecoveryOutcome` + default error classifications
- `pydantic_ai_error_recovery/_policy.py` -- classifier types, `RecoveryPolicy`, `required_positionals`
- `tests/_agents.py` -- agent builders the test module uses
- `tests/test_tool_error_recovery.py` -- behaviour tests through
  `Agent(..., capabilities=[...])` with `FunctionModel`

## Testing patterns

- No real model calls: `ALLOW_MODEL_REQUESTS = False` in `tests/conftest.py`
- `pytest.mark.anyio` for async tests (anyio's built-in pytest plugin)
- Standalone test functions, not test classes
- Drive behaviour through `Agent(..., capabilities=[...])`; don't import
  private helpers into tests -- mark genuinely unreachable branches
  `# pragma: no cover` instead
- `FunctionModel` scripts model behaviour (tool calls, failures, streams)

## Package management

- Use `uv` for dependency operations (`uv add`, `uv remove`)
- Dependency: `pydantic-ai-slim>=2.16,<3` (needs `get_model`, `ToolFailed`)
