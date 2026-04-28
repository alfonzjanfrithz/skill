# Feedback Loops

Detect the project's tech stack, then run the appropriate commands before committing.

## Stack Detection

Check for files in the project root:

| Files | Stack |
|-------|-------|
| `pom.xml`, `build.gradle` | Java |
| `pyproject.toml`, `requirements.txt`, `setup.py` | Python |
| `package.json` | Node.js / TypeScript |
| `Cargo.toml` | Rust |
| `go.mod` | Go |

## Commands by Stack

| Stack | Tests | Compile / Typecheck / Static Analysis |
|-------|-------|--------------------------------------|
| Java | `./gradlew test` or `mvn test` | `./gradlew compileJava` or `mvn compile` |
| Python | `pytest` or `python -m pytest` | `mypy`, `pyright`, or `ruff check` (if configured) |
| Node.js / TypeScript | `npm run test` or `yarn test` | `npm run typecheck` or `tsc --noEmit` |
| Rust | `cargo test` | `cargo check` |
| Go | `go test ./...` | `go build ./...` |

If the project lacks these commands, propose adding them to the build config.
