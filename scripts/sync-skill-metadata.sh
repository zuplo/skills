#!/usr/bin/env bash
set -euo pipefail

# Syncs marketplace.json and README.md with the current skills directory.
# Ensures all skills are listed and descriptions match SKILL.md frontmatter.
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
README="README.md"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "Error: Skills directory not found" >&2
  exit 1
fi

# --- Collect skill metadata ---

zuplo_skills=()
zudoku_skills=()

for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  name=$(basename "$skill_dir")

  # Extract description from frontmatter
  description=$(awk '
    /^---$/ { fm++; next }
    fm == 1 && /^description:/ {
      sub(/^description:[[:space:]]*/, "")
      gsub(/^["'\''"]|["'\''"]$/, "")
      print
      exit
    }
  ' "$skill_dir/SKILL.md")

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
    'name': 'zuplo-agent-skills',
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
            'description': 'Official Zuplo API gateway skills. Includes guides for gateway configuration, project setup, policies, handlers, monetization, and CLI usage.',
            'skills': [${zuplo_paths}],
            'source': './',
            'strict': False
        },
        {
            'name': 'zudoku-skills',
            'description': 'Comprehensive Zudoku developer portal framework skill. Covers setup, configuration, OpenAPI integration, plugins, auth, theming, troubleshooting, and migrations.',
            'skills': [${zudoku_paths}],
            'source': './',
            'strict': False
        }
    ]
}

with open('$MARKETPLACE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"

echo "Updated $MARKETPLACE"

# --- Update README skill tables ---

# Build the Zuplo table rows
zuplo_rows=""
for s in "${zuplo_skills[@]}"; do
  desc=$(awk '
    /^---$/ { fm++; next }
    fm == 1 && /^description:/ {
      sub(/^description:[[:space:]]*/, "")
      gsub(/^["'\''"]|["'\''"]$/, "")
      # Truncate to first sentence for table
      sub(/\. .*/, ".")
      print
      exit
    }
  ' "$SKILLS_DIR/$s/SKILL.md")
  zuplo_rows+="| **$s** | $desc |
"
done

zudoku_rows=""
for s in "${zudoku_skills[@]}"; do
  desc=$(awk '
    /^---$/ { fm++; next }
    fm == 1 && /^description:/ {
      sub(/^description:[[:space:]]*/, "")
      gsub(/^["'\''"]|["'\''"]$/, "")
      sub(/\. .*/, ".")
      print
      exit
    }
  ' "$SKILLS_DIR/$s/SKILL.md")
  zudoku_rows+="| **$s** | $desc |
"
done

# --- Update AGENTS.md skill table ---

agents_rows=""
for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue
  name=$(basename "$skill_dir")

  desc=$(awk '
    /^---$/ { fm++; next }
    fm == 1 && /^description:/ {
      sub(/^description:[[:space:]]*/, "")
      gsub(/^["'\''"]|["'\''"]$/, "")
      sub(/\. .*/, ".")
      # Keep it short for the table
      if (length > 70) { sub(/.{67}.*/, substr($0, 1, 67) "...") }
      print
      exit
    }
  ' "$skill_dir/SKILL.md")

  printf -v row '| %-29s| %-63s|' "\`skills/$name/\`" "$desc"
  agents_rows+="$row
"
done

echo "Metadata sync complete."

if [ "$CHECK_ONLY" = true ]; then
  if git diff --quiet -- "$MARKETPLACE"; then
    echo "All files up to date."
  else
    echo "Files are out of date. Run ./scripts/sync-skill-metadata.sh to update."
    git diff --stat -- "$MARKETPLACE"
    exit 1
  fi
fi
