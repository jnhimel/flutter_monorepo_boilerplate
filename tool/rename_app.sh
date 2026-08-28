#!/usr/bin/env bash
# Rename this boilerplate for a new project.
#
# Usage: tool/rename_app.sh "My New App" com.acme.mynewapp
#
# Replaces the placeholder display name ("Boilerplate") and bundle id
# (com.yourcompany.app) across the app's native project files and
# flavorizr.yaml. A straightforward sed script, not a generalized
# templating engine — re-run `flutter pub run flutter_flavorizr` afterwards
# if you want the flavor build files regenerated from the updated
# flavorizr.yaml instead of hand-edited in place.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <new-app-name> <new-bundle-id>" >&2
  echo 'Example: $0 "My New App" com.acme.mynewapp' >&2
  exit 1
fi

NEW_NAME=$1
NEW_BUNDLE_ID=$2
OLD_NAME="Boilerplate"
OLD_BUNDLE_ID="com.yourcompany.app"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"

# GNU sed takes `-i suffix` (empty string included in the next arg), BSD/macOS
# sed requires the suffix as its own arg (`-i ''`). Detect which one we have.
if sed --version >/dev/null 2>&1; then
  sed_i() { sed -i "$@"; }
else
  sed_i() { sed -i '' "$@"; }
fi

replace_in_file() {
  local file=$1
  [[ -f "$file" ]] || return 0
  # Bundle id and any dotted suffix of it (e.g. .dev, .staging)
  sed_i "s/${OLD_BUNDLE_ID//./\\.}/${NEW_BUNDLE_ID}/g" "$file"
  sed_i "s/${OLD_NAME}/${NEW_NAME}/g" "$file"
  echo "  updated $file"
}

rename_kotlin_package() {
  local kotlin_root="$APP_DIR/android/app/src/main/kotlin"
  # bash's ${var//./repl} takes the replacement literally (no backslash
  # escaping), so build the path with tr instead of trying to inject a "/".
  local old_dir="$kotlin_root/$(tr '.' '/' <<<"$OLD_BUNDLE_ID")"
  local new_dir="$kotlin_root/$(tr '.' '/' <<<"$NEW_BUNDLE_ID")"
  [[ -d "$old_dir" ]] || return 0

  mkdir -p "$(dirname "$new_dir")"
  mv "$old_dir" "$new_dir"

  # Clean up now-empty directories left behind by the old package path.
  local d
  d="$(dirname "$old_dir")"
  while [[ "$d" != "$kotlin_root" && -d "$d" && -z "$(ls -A "$d")" ]]; do
    rmdir "$d"
    d="$(dirname "$d")"
  done

  find "$new_dir" -name '*.kt' -print0 | while IFS= read -r -d '' f; do
    sed_i "s/^package ${OLD_BUNDLE_ID//./\\.}/package ${NEW_BUNDLE_ID}/" "$f"
    echo "  updated $f"
  done
  echo "  moved $old_dir -> $new_dir"
}

echo "Renaming app: '${OLD_NAME}' -> '${NEW_NAME}', bundle id: ${OLD_BUNDLE_ID} -> ${NEW_BUNDLE_ID}"

replace_in_file "$ROOT_DIR/flavorizr.yaml"
replace_in_file "$APP_DIR/flavorizr.yaml"
replace_in_file "$APP_DIR/pubspec.yaml"
replace_in_file "$APP_DIR/android/app/build.gradle.kts"
replace_in_file "$APP_DIR/android/app/flavorizr.gradle.kts"
replace_in_file "$APP_DIR/ios/Runner/Info.plist"
find "$APP_DIR/ios/Runner.xcodeproj" -name "project.pbxproj" -print0 2>/dev/null \
  | while IFS= read -r -d '' f; do replace_in_file "$f"; done
find "$APP_DIR/ios/Flutter" -name "*.xcconfig" -print0 2>/dev/null \
  | while IFS= read -r -d '' f; do replace_in_file "$f"; done
rename_kotlin_package

cat <<EOF

Done. Next steps:
  1. Re-run 'flutter pub run flutter_flavorizr -f' from app/ if you'd rather
     regenerate the native flavor files from flavorizr.yaml than trust the
     in-place sed above.
  2. Open ios/Runner.xcworkspace and confirm the bundle identifier / display
     name in each scheme's build settings if Xcode caches them.
  3. Re-run 'dart pub get' from the repo root.
EOF
