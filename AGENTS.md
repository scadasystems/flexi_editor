# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

FlexiEditor is a Flutter plugin (package) for building interactive diagrams, flowcharts, and node-based interfaces. It is **not** a standalone application — it is consumed as a dependency. There is no example app in the repository (previously removed).

### Environment

- **Flutter SDK**: Installed at `/opt/flutter` (3.32.2, Dart 3.8.1). PATH is configured in `~/.bashrc`.
- **Linux desktop build deps**: `libgtk-3-dev`, `ninja-build`, `libstdc++-14-dev` are required for `flutter build linux`.
- The `libstdc++.so` symlink at `/usr/lib/x86_64-linux-gnu/libstdc++.so` must point to GCC's libstdc++ for clang-based builds to link correctly.

### Key commands (see also `CLAUDE.md`)

| Task | Command |
|---|---|
| Get dependencies | `flutter pub get` |
| Lint / static analysis | `flutter analyze` |
| Format check | `dart format --set-exit-if-changed .` |
| Format fix | `dart format .` |
| Build (Linux debug) | `flutter build linux --debug` (from a Flutter app that depends on this package) |

### Gotchas

- **No tests**: The repo has no test files. `flutter test` will simply exit with no tests found.
- **No example app**: The `example/` directory only contains leftover iOS/macOS ephemeral files. To test the plugin visually, create a separate Flutter app (e.g., in `/tmp`) that depends on this package via `path: /workspace`.
- **`CanvasControlPolicy` mixin**: When creating a custom `PolicySet` subclass for a demo app, you must add `with CanvasControlPolicy` for the canvas to render correctly. The canvas widget casts the policy to `CanvasControlPolicy` at runtime.
- **`flutter_lints ^6.0.0`** requires Dart SDK ^3.8.0, which means Flutter >=3.32.x is needed. Older Flutter versions (e.g., 3.24.x with Dart 3.5.4) will fail `pub get`.
