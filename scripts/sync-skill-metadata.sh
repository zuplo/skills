#!/usr/bin/env bash
set -euo pipefail

# Syncs marketplace.json with the current skills directory.
# Ensures every skill is assigned to the appropriate Claude plugin bundle.
#
# Usage:
#   ./scripts/sync-skill-metadata.sh [--check]
#
# --check: Exit with code 1 if files are out of date (dry run)

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then
  CHECK_ONLY=true
fi

SKILLS_DIR="skills"
MARKETPLACE=".claude-plugin/marketplace.json"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "Error: Skills directory not found" >&2
  exit 1
fi

marketplace_output="$MARKETPLACE"
temporary_marketplace=""
if [ "$CHECK_ONLY" = true ]; then
  temporary_marketplace=$(mktemp)
  marketplace_output="$temporary_marketplace"
  trap 'rm -f "$temporary_marketplace"' EXIT
fi

# --- Collect skill metadata ---

zuplo_skills=()
zudoku_skills=()

for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  name=$(basename "$skill_dir")

  if [[ "$name" == zudoku-* ]]; then
    zudoku_skills+=("$name")
  else
    zuplo_skills+=("$name")
  fi
done

echo "Found ${#zuplo_skills[@]} Zuplo skills: ${zuplo_skills[*]}"
echo "Found ${#zudoku_skills[@]} Zudoku skills: ${zudoku_skills[*]}"

# --- Update marketplace.json ---

# Build the skills arrays as JSON
zuplo_paths=""
for s in "${zuplo_skills[@]}"; do
  [ -n "$zuplo_paths" ] && zuplo_paths+=","
  zuplo_paths+="\"./skills/$s\""
done

zudoku_paths=""
for s in "${zudoku_skills[@]}"; do
  [ -n "$zudoku_paths" ] && zudoku_paths+=","
  zudoku_paths+="\"./skills/$s\""
done

# Read current version
current_version=$(python3 -c "
import json
with open('$MARKETPLACE') as f:
    print(json.load(f)['metadata']['version'])
" 2>/dev/null || echo "1.0.0")

python3 -c "
import json

data = {
    '\$schema': 'https://anthropic.com/claude-code/marketplace.schema.json',
    'name': 'zuplo-tools',
    'description': 'Official Zuplo and Zudoku skills for building API gateways and developer portals with Claude.',
    'owner': {
        'name': 'Zuplo',
        'email': 'support@zuplo.com'
    },
    'metadata': {
        'version': '$current_version'
    },
    'plugins': [
        {
            'name': 'zuplo-skills',
            'displayName': 'Zuplo',
            'description': 'Official Zuplo API gateway skills. Includes guides for gateway configuration, project setup, policies, handlers, monetization, and CLI usage.',
            'author': {
                'name': 'Zuplo',
                'url': 'https://zuplo.com'
            },
            'category': 'development',
            'homepage': 'https://zuplo.com/docs',
            'repository': 'https://github.com/zuplo/tools',
            'skills': [${zuplo_paths}],
            'source': './',
            'strict': False
        },
        {
            'name': 'zudoku-skills',
            'displayName': 'Zudoku',
            'description': 'Comprehensive Zudoku developer portal framework skill. Covers setup, configuration, OpenAPI integration, plugins, auth, theming, troubleshooting, and migrations.',
            'author': {
                'name': 'Zuplo',
                'url': 'https://zuplo.com'
            },
            'category': 'development',
            'homepage': 'https://zudoku.dev/docs',
            'repository': 'https://github.com/zuplo/tools',
            'skills': [${zudoku_paths}],
            'source': './',
            'strict': False
        }
    ]
}

with open('$marketplace_output', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"

if [ "$CHECK_ONLY" = true ]; then
  if cmp -s "$MARKETPLACE" "$temporary_marketplace"; then
    echo "Marketplace metadata is up to date."
  else
    echo "Files are out of date. Run ./scripts/sync-skill-metadata.sh to update."
    diff -u "$MARKETPLACE" "$temporary_marketplace" || true
    exit 1
  fi
else
  echo "Updated $MARKETPLACE"
fi

echo "Metadata sync complete."
