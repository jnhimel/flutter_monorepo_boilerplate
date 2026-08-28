#!/usr/bin/env bash
# Scaffold a new feature package by copying packages/notes and substituting
# names, then wire it into app/lib/bootstrap.dart and app/lib/router/app_router.dart
# at the `// GENERATOR:` marker comments.
#
# Usage: tool/new_feature.sh todos
#
# ponytail: singular form is derived by naively stripping a trailing "s"
# (todos -> todo). Pass an irregular plural (e.g. "people") and you'll get a
# wrong singular ("people" -> "peopl") — fix the generated file/class names
# by hand in that case, or upgrade this script to take an explicit singular
# as a second argument.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <feature-name-plural-lowercase>" >&2
  echo "Example: $0 todos" >&2
  exit 1
fi

PLURAL_LOWER=$1
SINGULAR_LOWER=${PLURAL_LOWER%s}
PLURAL_UPPER="$(tr '[:lower:]' '[:upper:]' <<<"${PLURAL_LOWER:0:1}")${PLURAL_LOWER:1}"
SINGULAR_UPPER="$(tr '[:lower:]' '[:upper:]' <<<"${SINGULAR_LOWER:0:1}")${SINGULAR_LOWER:1}"

# GNU sed takes `-i suffix` (empty string included in the next arg), BSD/macOS
# sed requires the suffix as its own arg (`-i ''`). Detect which one we have.
if sed --version >/dev/null 2>&1; then
  sed_i() { sed -i "$@"; }
else
  sed_i() { sed -i '' "$@"; }
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT_DIR/packages/notes"
DEST="$ROOT_DIR/packages/$PLURAL_LOWER"

if [[ -d "$DEST" ]]; then
  echo "packages/$PLURAL_LOWER already exists." >&2
  exit 1
fi

echo "Scaffolding packages/$PLURAL_LOWER from packages/notes ..."
rsync -a --exclude='.dart_tool' --exclude='build' --exclude='pubspec.lock' \
  --exclude='pubspec_overrides.yaml' --exclude='.DS_Store' --exclude='*.iml' \
  --exclude='*.g.dart' --exclude='*.freezed.dart' "$SRC/" "$DEST/"

# Substitute names in file contents. Order matters: the plural forms must be
# rewritten before the singular ones, or "Notes"/"notes" would partially
# match the singular pattern first.
substitute_content() {
  local file=$1
  sed_i \
    -e "s/Notes/${PLURAL_UPPER}/g" \
    -e "s/notes/${PLURAL_LOWER}/g" \
    -e "s/Note/${SINGULAR_UPPER}/g" \
    -e "s/note/${SINGULAR_LOWER}/g" \
    "$file"
}

find "$DEST" -type f \( -name '*.dart' -o -name '*.yaml' \) -print0 | while IFS= read -r -d '' f; do
  substitute_content "$f"
done

# Substitute names in file/directory names, deepest paths first so renaming
# a directory doesn't invalidate paths queued below it.
find "$DEST" -depth -name '*note*' -o -depth -name '*Note*' | sort -r | while read -r path; do
  new_path=$(basename "$path" \
    | sed -e "s/Notes/${PLURAL_UPPER}/g" -e "s/notes/${PLURAL_LOWER}/g" \
          -e "s/Note/${SINGULAR_UPPER}/g" -e "s/note/${SINGULAR_LOWER}/g")
  if [[ "$new_path" != "$(basename "$path")" ]]; then
    mv "$path" "$(dirname "$path")/$new_path"
  fi
done

# Insert $2 as a new import line right after an existing "package:notes/notes.dart"
# import if present, otherwise before the first import line. No-op if $2 is
# already present. Plain awk — no GNU-only sed/awk extensions, so this works
# the same on BSD (macOS) and GNU (Linux CI) alike.
insert_import() {
  local file=$1 import_line=$2
  grep -qF "$import_line" "$file" && return 0
  if grep -qF "import 'package:notes/notes.dart';" "$file"; then
    awk -v after="import 'package:notes/notes.dart';" -v newimp="$import_line" \
      'index($0, after) { print; print newimp; next } { print }' "$file" >"$file.tmp"
  else
    awk -v newimp="$import_line" \
      '!done && /^import /{ print newimp; done=1 } { print }' "$file" >"$file.tmp"
  fi
  mv "$file.tmp" "$file"
}

# Insert $3 (matching the marker line's indentation) directly above the first
# line containing marker $2 in file $1.
insert_before_marker() {
  local file=$1 marker=$2 new_line=$3
  awk -v marker="$marker" -v newline="$new_line" '
    index($0, marker) {
      match($0, /^[ \t]*/)
      print substr($0, RSTART, RLENGTH) newline
    }
    { print }
  ' "$file" >"$file.tmp"
  mv "$file.tmp" "$file"
}

# Wire DI: app/lib/bootstrap.dart
BOOTSTRAP="$ROOT_DIR/app/lib/bootstrap.dart"
MARKER="// GENERATOR: register feature dependencies above this line"
if grep -qF "$MARKER" "$BOOTSTRAP"; then
  insert_import "$BOOTSTRAP" "import 'package:${PLURAL_LOWER}/${PLURAL_LOWER}.dart';"
  insert_before_marker "$BOOTSTRAP" "$MARKER" "register${PLURAL_UPPER}Dependencies(getIt);"
  if grep -qF "register${PLURAL_UPPER}Dependencies(getIt);" "$BOOTSTRAP"; then
    echo "Wired register${PLURAL_UPPER}Dependencies(getIt) into app/lib/bootstrap.dart"
  else
    echo "WARNING: failed to insert DI registration — wire it by hand in $BOOTSTRAP" >&2
  fi
else
  echo "WARNING: marker not found in $BOOTSTRAP — wire DI by hand." >&2
fi

# Wire routes: app/lib/router/app_router.dart
ROUTER="$ROOT_DIR/app/lib/router/app_router.dart"
ROUTE_MARKER="// GENERATOR: register feature routes above this line"
if grep -qF "$ROUTE_MARKER" "$ROUTER"; then
  insert_import "$ROUTER" "import 'package:${PLURAL_LOWER}/${PLURAL_LOWER}.dart';"
  insert_before_marker "$ROUTER" "$ROUTE_MARKER" "${PLURAL_LOWER}ShellBranch(getIt),"
  if grep -qF "${PLURAL_LOWER}ShellBranch(getIt)," "$ROUTER"; then
    echo "Wired ${PLURAL_LOWER}ShellBranch(getIt) into app/lib/router/app_router.dart"
  else
    echo "WARNING: failed to insert route branch — wire it by hand in $ROUTER" >&2
  fi
else
  echo "WARNING: marker not found in $ROUTER — wire routes by hand." >&2
fi

cat <<EOF

Done. packages/$PLURAL_LOWER created and wired into DI + routes.

Next manual steps (packages/$PLURAL_LOWER won't analyze clean until you do
these — it still points at notes' table/route constant in packages/core):
  1. Add a path dependency in app/pubspec.yaml:
       $PLURAL_LOWER:
         path: ../packages/$PLURAL_LOWER
  2. Add a "$PLURAL_LOWER" table + DAO methods to packages/core's AppDatabase
     (Notes/watchAllNotes/createNote/etc. were copied by name, not
     regenerated — packages/$PLURAL_LOWER/lib/src/repository/${PLURAL_LOWER}_repository_impl.dart
     still calls the notes ones).
  3. Add 'static const $PLURAL_LOWER = "/$PLURAL_LOWER";' to
     packages/core/lib/src/routing/app_route_paths.dart, and a bottom-nav
     destination in AppShellScaffold if this feature gets its own tab.
  4. Run: dart pub get (from the repo root)
  5. Run: dart run build_runner build --delete-conflicting-outputs
     (from packages/$PLURAL_LOWER)
  6. Review the naive singular/plural substitution above — fix any names
     the script guessed wrong.
EOF
