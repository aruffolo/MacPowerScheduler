# dependencies-testing.md

## Dependency Isolation (Swift Testing and snapshots)
- Prefer constructor injection via protocols/closures.
- Tests override only what they need (fakes/stubs), keep defaults safe.
- Do not rely on global state, clocks, randomness, or filesystem unless explicitly controlled.

## Where to put fakes
- Test-only fakes live in `Package/Tests/...` alongside the tests.
- If a fake is broadly reused, consider `Package/Tests/.../TestSupport/`.
