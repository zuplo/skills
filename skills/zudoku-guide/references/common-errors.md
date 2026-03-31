# Common errors and troubleshooting

Comprehensive guide to common Zudoku errors and their solutions.

## Quickstart

In most cases, debugging starts with running the development server and checking the browser console and terminal output:

```bash
npm run dev
```

Open `http://localhost:3000` in your browser and check the console for errors.

## Build and configuration errors

### "Cannot find module 'zudoku'" or import errors

**Symptoms**:

```bash
Error: Cannot find module 'zudoku'
```

**Causes**:

- Zudoku not installed
- Incorrect import path

**Solutions**:

1. Install Zudoku:

   ```bash
   npm install zudoku
   ```

2. Verify import:

   ```typescript
   import type { ZudokuConfig } from "zudoku";
   ```

### Config type errors

**Symptoms**:

```bash
Type '{ ... }' is not assignable to type 'ZudokuConfig'
Property 'X' does not exist on type 'ZudokuConfig'
```

**Causes**:

- Outdated config options (Zudoku is actively developed)
- Incorrect property name or type
- Version mismatch between docs and installed package

**Solutions**:

1. Check embedded docs (see `embedded-docs.md`) to verify current config type
2. Verify package version: `npm list zudoku`
3. Update package: `npm update zudoku`
4. Check type definitions:

   ```bash
   grep -r "ZudokuConfig" node_modules/zudoku/dist/ --include="*.d.ts"
   ```

### Vite build errors

**Symptoms**:

```bash
[vite] Internal server error: ...
Build failed with errors
```

**Causes**:

- Invalid config syntax
- Missing dependencies
- Incompatible plugin

**Solutions**:

1. Check `zudoku.config.ts` for syntax errors
2. Ensure all imports are valid
3. Check Vite config if using `vite.config.ts` overrides — see [Vite Config docs](https://zudoku.dev/docs/configuration/vite-config)

## OpenAPI / API Reference errors

### OpenAPI spec not loading

**Symptoms**:

- API reference page shows no operations
- "Failed to fetch" errors in console
- Blank API reference section

**Causes**:

- Incorrect file path or URL in `apis` config
- Invalid OpenAPI spec
- CORS issues when loading from URL

**Solutions**:

1. Verify the path in `zudoku.config.ts`:

   ```typescript
   apis: {
     type: "file",
     input: "./apis/openapi.yaml", // Check this path exists
     path: "/api",
   },
   ```

2. Validate your OpenAPI spec:

   ```bash
   npx @redocly/cli lint ./apis/openapi.yaml
   ```

3. For URL-based specs, check CORS headers on the remote server

### OpenAPI spec parsing errors

**Symptoms**:

```bash
Error parsing OpenAPI specification
Invalid $ref: ...
```

**Causes**:

- Invalid YAML/JSON syntax
- Broken `$ref` references
- Unsupported OpenAPI features

**Solutions**:

1. Validate YAML syntax
2. Ensure all `$ref` paths are correct
3. Check that you're using OpenAPI 3.0+ (Swagger 2.0 may need conversion)

## Navigation errors

### Pages not showing in sidebar

**Symptoms**:

- Documentation pages exist but don't appear in navigation
- 404 errors when navigating to pages

**Causes**:

- Pages not listed in `navigation` config
- Incorrect `docs.files` glob pattern
- File path doesn't match navigation item ID

**Solutions**:

1. Ensure pages are referenced in `navigation`:

   ```typescript
   navigation: [
     {
       type: "category",
       label: "Documentation",
       items: ["introduction", "getting-started"], // Must match filenames
     },
   ],
   ```

2. Verify the `docs.files` glob matches your file structure:

   ```typescript
   docs: {
     files: "/pages/**/*.{md,mdx}",
   },
   ```

3. Check that filenames match the IDs used in navigation items

## Authentication errors

### Auth provider not working

**Symptoms**:

- Login button doesn't appear
- Authentication redirects fail
- "Unauthorized" errors

**Causes**:

- Incorrect auth provider configuration
- Missing or wrong client ID / domain
- Redirect URIs not configured in provider

**Solutions**:

1. Verify auth configuration in `zudoku.config.ts`
2. Check that redirect URIs are registered with your auth provider
3. Use environment variables for sensitive values (don't hardcode in config)
4. See provider-specific docs:
   - [Auth0](https://zudoku.dev/docs/configuration/authentication-auth0)
   - [Clerk](https://zudoku.dev/docs/configuration/authentication-clerk)
   - [Supabase](https://zudoku.dev/docs/configuration/authentication-supabase)

## Plugin errors

### Custom plugin not loading

**Symptoms**:

- Plugin features don't appear
- Console errors about plugin initialization

**Causes**:

- Plugin not properly exported
- Plugin interface not correctly implemented
- Plugin not added to config

**Solutions**:

1. Ensure plugin implements the correct interface
2. Add plugin to config:

   ```typescript
   import { myPlugin } from "./plugins/my-plugin";

   const config: ZudokuConfig = {
     // ...
     plugins: [myPlugin()],
   };
   ```

3. See [Custom Plugins docs](https://zudoku.dev/docs/custom-plugins) for the plugin API

## Theme/styling errors

### Custom theme not applying

**Symptoms**:

- Colors don't change
- Theme looks wrong in dark/light mode

**Causes**:

- Incorrect HSL format for theme values
- Theme config in wrong location

**Solutions**:

1. Use correct HSL format (without `hsl()` wrapper):

   ```typescript
   theme: {
     light: {
       primary: "316 100% 50%",       // Correct: just HSL values
       primaryForeground: "360 100% 100%",
     },
     dark: {
       primary: "316 100% 50%",
       primaryForeground: "360 100% 100%",
     },
   },
   ```

2. See [Theme docs](https://zudoku.dev/docs/customization/colors-theme) for all available variables

## Development server errors

### Port already in use

**Symptoms**:

```bash
Error: Port 3000 is already in use
```

**Solutions**:

1. Set a different port in config:

   ```typescript
   { port: 9001 }
   ```

2. Or pass via CLI: `npx zudoku dev --port 9001`

3. Kill the process using the port:

   ```bash
   lsof -i :3000 | grep LISTEN
   kill -9 <PID>
   ```

### Hot reload not working

**Symptoms**:

- Changes to files don't reflect in browser
- Need to manually restart dev server

**Solutions**:

1. Ensure you're editing files within the project directory
2. Check that your file watcher limit isn't exceeded (Linux):

   ```bash
   echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

3. Restart the dev server

## Debugging tips

### Check package version

```bash
npm list zudoku
```

### Validate config

```bash
npx tsc --noEmit  # If using TypeScript config
```

### Check browser console

Open DevTools (F12) and check the Console tab for runtime errors.

### Enable verbose Vite output

```bash
npx zudoku dev --debug
```

## Getting help

1. **Check embedded docs**: See `embedded-docs.md`
2. **Search documentation**: [zudoku.dev/docs](https://zudoku.dev/docs)
3. **Check examples**: [github.com/zuplo/zudoku/tree/main/examples](https://github.com/zuplo/zudoku/tree/main/examples)
4. **Join Discord**: [discord.zudoku.dev](https://discord.zudoku.dev)
5. **File an issue**: [github.com/zuplo/zudoku/issues](https://github.com/zuplo/zudoku/issues)
