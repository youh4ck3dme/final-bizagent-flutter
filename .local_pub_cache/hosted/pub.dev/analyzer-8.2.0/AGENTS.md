# Repository Guidelines

This package implements Dart’s static analyzer. Use these concise guidelines to contribute effectively within `pkg/analyzer`.

## Project Structure & Module Organization
- `lib/` public API; internal code under `lib/src/` (avoid exporting `src/`).
- `test/` unit and integration tests (reflective suites, `*_test.dart`).
- `tool/` maintenance and generators (e.g., `api/`, `messages/`, `stable_analysis.dart`).
- `example/`, `doc/`, `coverage/`; human‑edited data files like `messages.yaml` and generated `api.txt`.

## Build, Test, and Development Commands
- Setup: `dart --version` (>= 3.9), then `dart pub get`.
- Lints/analysis: `dart analyze .` (honors `analysis_options.yaml`).
- Tests: `dart test -j4` (filter by path/name, e.g., `dart test test/src/...`).
- Format: `dart format -o write .`.
- Public API manifest: `dart run tool/api/generate.dart` (updates `api.txt`).
- Error/message codegen: `dart run tool/messages/generate.dart` after changing `messages.yaml`.

## Coding Style & Naming Conventions
- Follow Dart style: 2‑space indent; use `dart format`.
- Follow the Effective Dart Documentation Style Guide: https://dart.dev/effective-dart/documentation
- Imports: prefer package imports (`package:analyzer/...`) — enforced by `always_use_package_imports`.
- Names: types UpperCamelCase; members/variables lowerCamelCase. Legacy SCREAMING_CAPS constants exist; avoid introducing new ones unless matching surrounding code.
- Strict analysis: project enables `strict-casts` and `strict-inference`. Fix lints unless explicitly suppressed in `analysis_options.yaml`.

## Testing Guidelines
- Framework: `package:test` with `test_reflective_loader` helpers. Name files `*_test.dart`.
- Keep expectations stable. For presubmit, ensure `NodeTextExpectationsCollector.updatingIsEnabled` remains `false` (see `PRESUBMIT.py`).
- Add targeted tests for parser/resolver/element changes under the corresponding `test/src/...` area.

## Commit & Pull Request Guidelines
- Commits: imperative mood (“Fix …”), concise subject; reference issues (e.g., `Fixes dart-lang/sdk#NNN`). Optional scope tags are used in history (e.g., `[analyzer]`, `[messages]`).
- PRs: include motivation, approach, and risk. Run `dart analyze` and `dart test` locally. Update docs/examples as needed.
- Public API changes: regenerate `api.txt` and update `CHANGELOG.md`; highlight breaking changes clearly.

