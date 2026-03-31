# Embedded Docs Reference

Look up API signatures and config types from installed Zudoku package in `node_modules/zudoku/` — these match the installed version.

**Use this FIRST** when Zudoku is installed locally. Embedded types are always accurate for the installed version.

## Why use embedded docs

- **Version accuracy**: Types match the exact installed version
- **No network required**: All types are local in `node_modules/`
- **Zudoku evolves quickly**: Config options and APIs change, embedded types stay in sync
- **TypeScript definitions**: Includes full type signatures and JSDoc

## Key type files

```
node_modules/zudoku/
├── dist/
│   ├── config.d.ts          # ZudokuConfig type definition
│   └── ...                  # Other type definitions
├── package.json
└── ...
```

## Lookup process

### 1. Check if package is installed

```bash
ls node_modules/zudoku/
```

If the `zudoku` directory exists, proceed with embedded docs lookup.

### 2. Look up config types

The most common lookup is the `ZudokuConfig` type:

```bash
grep -r "ZudokuConfig" node_modules/zudoku/dist/ --include="*.d.ts" -l
```

Then read the relevant type file:

```bash
cat node_modules/zudoku/dist/config.d.ts
```

### 3. Search for specific types or interfaces

```bash
grep -r "NavigationItem\|ApiConfig\|ThemeConfig" node_modules/zudoku/dist/ --include="*.d.ts"
```

### 4. Check exported types

```bash
grep "export" node_modules/zudoku/dist/index.d.ts
```

## Common lookups

| What you need              | Command                                                                    |
| -------------------------- | -------------------------------------------------------------------------- |
| Full config type           | `cat node_modules/zudoku/dist/config.d.ts`                                 |
| Navigation types           | `grep -r "Navigation" node_modules/zudoku/dist/ --include="*.d.ts"`        |
| API config types           | `grep -r "ApiConfig\|apis" node_modules/zudoku/dist/ --include="*.d.ts"`   |
| Theme types                | `grep -r "Theme" node_modules/zudoku/dist/ --include="*.d.ts"`             |
| Plugin types               | `grep -r "Plugin" node_modules/zudoku/dist/ --include="*.d.ts"`            |
| Auth types                 | `grep -r "Auth" node_modules/zudoku/dist/ --include="*.d.ts"`              |
| All exports                | `grep "export" node_modules/zudoku/dist/index.d.ts`                        |

## Quick commands reference

```bash
# Check installed version
cat node_modules/zudoku/package.json | grep '"version"'

# List type definition files
find node_modules/zudoku/dist -name "*.d.ts" | head -20

# Search for any type/interface
grep -r "TypeName" node_modules/zudoku/dist/ --include="*.d.ts"

# Read a specific type file
cat node_modules/zudoku/dist/[path-to-file].d.ts
```

## When embedded docs are not available

If the package isn't installed or type files don't exist:

1. **Recommend installation**: Suggest installing with `npm install zudoku`
2. **Fall back to remote docs**: See `references/remote-docs.md`

## Best Practices

1. **Check type definitions** for exact config options and their types
2. **Search for interfaces** if the exact type name is unknown
3. **Verify imports** match what's exported from the package
