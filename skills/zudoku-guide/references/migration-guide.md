# Migration Guide

Guide for upgrading Zudoku versions using official documentation and current API verification.

## Migration strategy

For version upgrades, follow this process:

### 1. Check official migration docs

**Always start with the official documentation:** `https://zudoku.dev/llms.txt`

Look for migration or changelog sections which will have:

- Breaking changes for each version
- Step-by-step upgrade instructions
- New features and deprecations

Also check:

- `https://zudoku.dev/docs/guides/navigation-migration`
- [GitHub releases](https://github.com/zuplo/zudoku/releases)

### 2. Use embedded docs for current APIs

After identifying breaking changes, verify the new APIs:

**Check your installed version:**

```bash
cat node_modules/zudoku/package.json | grep '"version"'
```

**Look up current types:**

```bash
grep -r "ZudokuConfig" node_modules/zudoku/dist/ --include="*.d.ts"
```

See [`embedded-docs.md`](embedded-docs.md) for detailed lookup instructions.

### 3. Use remote docs for latest info

If packages aren't updated yet, check what APIs will look like:

`https://zudoku.dev/docs/configuration/overview`

See [`remote-docs.md`](remote-docs.md) for detailed lookup instructions.

## Quick migration workflow

```bash
# 1. Check current version
npm list zudoku

# 2. Fetch migration guide from official docs
# Use WebFetch: https://zudoku.dev/llms.txt
# Check GitHub releases: https://github.com/zuplo/zudoku/releases

# 3. Update dependency
npm install zudoku@latest

# 4. Check embedded docs for new config types
grep -r "ZudokuConfig" node_modules/zudoku/dist/ --include="*.d.ts"

# 5. Fix breaking changes using type definitions
cat node_modules/zudoku/dist/config.d.ts

# 6. Test
npm run dev
npm run build
```

## Common migration patterns

### Finding what changed

**Check GitHub releases:** `https://github.com/zuplo/zudoku/releases`

This will list:

- Breaking changes
- Deprecated config options
- New features
- Bug fixes

### Updating config

**For each breaking change:**

1. **Find the old config** in your `zudoku.config.ts`
2. **Look up the new type** using embedded docs:
   ```bash
   cat node_modules/zudoku/dist/config.d.ts
   ```
3. **Update your config** based on the type signatures
4. **Test** the change

### Example: Navigation config change

**Official docs say:** "Navigation format changed"

**Look up current type:**

```bash
grep -r "Navigation" node_modules/zudoku/dist/ --include="*.d.ts"
```

**Update based on type definition:**

```typescript
// Old format
navigation: [{ label: "Docs", items: ["intro"] }];

// New format (example)
navigation: [{ type: "category", label: "Docs", items: ["intro"] }];
```

See also: [Navigation Migration Guide](https://zudoku.dev/docs/guides/navigation-migration)

## Pre-migration checklist

- [ ] Backup code (git commit)
- [ ] Check official migration docs / GitHub releases
- [ ] Note current version: `npm list zudoku`
- [ ] Read breaking changes list
- [ ] Site builds successfully: `npm run build`

## Post-migration checklist

- [ ] Dependency updated
- [ ] TypeScript compiles (if applicable): `npx tsc --noEmit`
- [ ] Site builds: `npm run build`
- [ ] Dev server works: `npm run dev`
- [ ] All pages render correctly
- [ ] API reference works
- [ ] Navigation is correct
- [ ] Authentication works (if configured)

## Migration resources

| Resource                                                   | Use For                                       |
| ---------------------------------------------------------- | --------------------------------------------- |
| `https://zudoku.dev/llms.txt`                              | Finding migration guides and breaking changes |
| [GitHub Releases](https://github.com/zuplo/zudoku/releases) | Detailed changelogs                          |
| [`embedded-docs.md`](embedded-docs.md)                     | Looking up new config types after updating    |
| [`remote-docs.md`](remote-docs.md)                        | Checking latest docs before updating          |
| [`common-errors.md`](common-errors.md)                     | Fixing migration errors                       |

## Key principles

1. **Official docs are source of truth** — Start with `https://zudoku.dev/llms.txt` and GitHub releases
2. **Verify with embedded docs** — Check installed version types
3. **Test thoroughly** — Run both dev server and production build after migrating
4. **Check all pages** — Navigation, API reference, and auth may all be affected

## Getting help

1. **Check official migration docs**: `https://zudoku.dev/llms.txt` → Migration section
2. **Look up new APIs**: See [`embedded-docs.md`](embedded-docs.md)
3. **Check for errors**: See [`common-errors.md`](common-errors.md)
4. **Ask in Discord**: https://discord.zudoku.dev
5. **File issues**: https://github.com/zuplo/zudoku/issues
