#!/usr/bin/env bash
# Run a command across every package in the pub workspace, with the same
# filters `test` (only where a test/ dir exists) and `build_runner` (only
# where the package depends on it) need. Dependency linking is native pub
# workspace behavior (`dart pub get` at the repo root); this just loops.
#
# Usage: tool/workspace.sh {analyze|format|test|build_runner}
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES=(app packages/core packages/notes)

case "${1:-}" in
  analyze|format|test|build_runner) ;;
  *)
    echo "Usage: $0 {analyze|format|test|build_runner}" >&2
    exit 1
    ;;
esac

for pkg in "${PACKAGES[@]}"; do
  dir="$ROOT_DIR/$pkg"
  case "$1" in
    analyze)
      (cd "$dir" && flutter analyze)
      ;;
    format)
      (cd "$dir" && dart format --set-exit-if-changed .)
      ;;
    test)
      [[ -d "$dir/test" ]] && (cd "$dir" && flutter test)
      ;;
    build_runner)
      grep -qF 'build_runner' "$dir/pubspec.yaml" \
        && (cd "$dir" && dart run build_runner build --delete-conflicting-outputs)
      ;;
  esac
done
