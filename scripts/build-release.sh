#!/usr/bin/env bash
set -euo pipefail

# Builds agent skills release artifacts per the Agent Skills Discovery RFC v0.2.0.
#
# Usage:
#   ./scripts/build-release.sh <github-release-url-prefix>
#
# Example:
#   ./scripts/build-release.sh https://github.com/zuplo/skills/releases/download/v1.0.0
#
# Output:
#   dist/
#     index.json                     — discovery index
#     zuplo-cli/SKILL.md             — skill-md artifacts
#     zuplo-guide.tar.gz             — archive artifacts
#     ...

RELEASE_URL_PREFIX="${1:?Usage: build-release.sh <github-release-url-prefix>}"
SKILLS_SRC="skills"
DIST="dist"
SCHEMA="https://schemas.agentskills.io/discovery/0.2.0/schema.json"

if [ ! -d "$SKILLS_SRC" ]; then
  echo "Error: Skills directory not found at $SKILLS_SRC" >&2
  exit 1
fi

rm -rf "$DIST"
mkdir -p "$DIST"

index_entries=()

for skill_dir in "$SKILLS_SRC"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")

  if [ ! -f "$skill_dir/SKILL.md" ]; then
    echo "Warning: Skipping $name — no SKILL.md found" >&2
    continue
  fi

  # Extract description from YAML frontmatter
  description=$(awk '
    /^---$/ { fm++; next }
    fm == 1 && /^description:/ {
      sub(/^description:[[:space:]]*/, "")
      gsub(/^["'\''"]|["'\''"]$/, "")
      print
      exit
    }
  ' "$skill_dir/SKILL.md")

  if [ -z "$description" ]; then
    echo "Warning: No description found in $name/SKILL.md frontmatter" >&2
    description="$name skill"
  fi

  # Determine type: archive if there are extra directories, skill-md otherwise
  has_extras=false
  for sub in "$skill_dir"*/; do
    [ -d "$sub" ] && has_extras=true && break
  done

  if [ "$has_extras" = true ]; then
    # Archive type — create tar.gz
    tar -czf "$DIST/${name}.tar.gz" -C "$SKILLS_SRC" "$name"
    digest="sha256:$(shasum -a 256 "$DIST/${name}.tar.gz" | cut -d' ' -f1)"
    url="${RELEASE_URL_PREFIX}/${name}.tar.gz"
    type="archive"
  else
    # skill-md type — copy SKILL.md
    mkdir -p "$DIST/$name"
    cp "$skill_dir/SKILL.md" "$DIST/$name/SKILL.md"
    digest="sha256:$(shasum -a 256 "$DIST/$name/SKILL.md" | cut -d' ' -f1)"
    url="${RELEASE_URL_PREFIX}/${name}-SKILL.md"
    type="skill-md"
  fi

  json_description=$(printf '%s' "$description" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()), end="")')
  index_entries+=("{\"name\":\"${name}\",\"type\":\"${type}\",\"description\":${json_description},\"url\":\"${url}\",\"digest\":\"${digest}\"}")

  echo "Processed: $name ($type)"
done

# Generate index.json
{
  printf '{\n  "$schema": "%s",\n  "skills": [\n' "$SCHEMA"
  for i in "${!index_entries[@]}"; do
    if [ "$i" -lt $((${#index_entries[@]} - 1)) ]; then
      printf '    %s,\n' "${index_entries[$i]}"
    else
      printf '    %s\n' "${index_entries[$i]}"
    fi
  done
  printf '  ]\n}\n'
} > "$DIST/index.json"

python3 -m json.tool "$DIST/index.json" > "$DIST/index.json.tmp"
mv "$DIST/index.json.tmp" "$DIST/index.json"

echo ""
echo "Built ${#index_entries[@]} skills into $DIST/"
