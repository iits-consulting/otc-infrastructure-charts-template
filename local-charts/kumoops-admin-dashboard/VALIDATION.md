# Chart Validation & Robustness

This chart includes multiple layers of validation to ensure robust deployments.

## Validation Layers

### 1. **JSON Schema Validation** (Helm 3+)
Located in `values.schema.json`, this provides:
- Type checking for all values
- Required field validation
- String length constraints
- URL format validation
- Conditional validation (enabled tiles must have all fields)

**When it runs:** During `helm install`, `helm upgrade`, and `helm template`

**Example error:**
```
Error: values don't meet the specifications of the schema(s):
- at '/defaultDashboard/tiles/myTile': missing property 'href'
```

### 2. **Template Validation**
The HTML template (`files/index.html`) includes defensive checks:
- Validates tile objects before rendering
- Skips tiles with missing required fields
- Provides fallback values for optional fields
- Shows helpful message when no tiles are configured

**Protection provided:**
- Missing `enabled` field → Tile skipped
- Missing `href` → Tile skipped
- Missing `imgSrc` → Tile skipped
- Missing `imgAlt` → Tile skipped
- Missing `category` → Tile skipped
- Missing `description` → Gracefully handled (optional field)

### 3. **Helm Test**
Located in `templates/tests/test-values.yaml`:
```bash
helm test <release-name>
```

Validates:
- Required dashboard configuration
- Tile count and validation
- Missing required fields

### 4. **Helper Functions**
Located in `templates/_helpers.tpl`:

```yaml
{{- include "kumoops-dashboard.getTitle" . }}        # Safe title with fallback
{{- include "kumoops-dashboard.getLogoSrc" . }}      # Safe logo URL with fallback
{{- include "kumoops-dashboard.getLogoAlt" . }}      # Safe logo alt with fallback
{{- include "kumoops-dashboard.getTileProp" (dict "tile" .tile "prop" "description" "default" "") }}
```

### 5. **Deployment NOTES**
After deployment, `helm install` shows:
- Configuration summary
- Warnings for invalid tiles
- Warnings for missing configuration
- Instructions to fix issues

## Required Fields

### Dashboard Configuration
```yaml
defaultDashboard:
  title: "Dashboard Title"          # Required (fallback: "Admin Dashboard")
  logoSrc: "https://example.com"    # Required (fallback: placeholder)
  logoAlt: "Logo"                   # Optional (fallback: "Dashboard Logo")
  subtitle: "Optional subtitle"     # Optional
```

### Tile Configuration
```yaml
tiles:
  myTile:
    enabled: true                   # Required
    href: "https://example.com"     # Required if enabled=true
    imgSrc: "https://img.png"       # Required if enabled=true
    imgAlt: "Tile Name"             # Required if enabled=true
    category: "Category Name"       # Required if enabled=true
    description: "Description"      # Optional (for tooltips)
```

## Testing Validation

### Test with valid values:
```bash
helm template . --debug
helm lint .
```

### Test with invalid values:
```bash
helm template . -f test-invalid-values.yaml
# Should fail with schema validation errors
```

### Test after deployment:
```bash
helm test <release-name>
```

## Common Errors & Solutions

### ❌ "missing property 'href'"
**Problem:** Enabled tile is missing the `href` field
**Solution:** Add `href` field or set `enabled: false`

```yaml
tiles:
  myTile:
    enabled: true
    href: "https://example.com"  # ← Add this
```

### ❌ "got null, want string"
**Problem:** Required string field is set to `null` or empty
**Solution:** Provide a valid string value

```yaml
defaultDashboard:
  title: "My Dashboard"  # ← Don't use null or empty string
```

### ⚠️ "WARNING: X tile(s) have missing required fields"
**Problem:** Some tiles are enabled but missing fields
**Solution:** Either:
1. Add missing fields to the tiles
2. Set `enabled: false` for incomplete tiles
3. Remove the incomplete tiles

### ⚠️ "WARNING: No tiles configured"
**Problem:** No tiles defined in values.yaml
**Solution:** Add tiles to `defaultDashboard.tiles`

## Disabling Tiles Safely

To disable a tile, you can either:

**Option 1: Set enabled=false (fields not required)**
```yaml
tiles:
  myTile:
    enabled: false
    # Other fields are optional when disabled
```

**Option 2: Comment it out**
```yaml
tiles:
  # myTile:
  #   enabled: true
  #   href: "..."
```

**Option 3: Remove it completely**
```yaml
tiles:
  # (removed myTile)
```

## Best Practices

1. **Always set enabled field** explicitly (`enabled: true` or `enabled: false`)
2. **Validate before deploying** using `helm template . --debug`
3. **Run helm test** after deployment to verify configuration
4. **Check NOTES.txt** after installation for warnings
5. **Use the schema** - it will catch errors before deployment
6. **Keep descriptions short** (max 150 characters) for good UX

## Fallback Behavior

If validation fails at runtime (edge cases):

| Field | Fallback Value |
|-------|---------------|
| Dashboard title | "Admin Dashboard" |
| Logo source | Placeholder image URL |
| Logo alt | "Dashboard Logo" |
| Tile description | Empty (no tooltip) |
| Missing tiles | "No tiles configured" message shown |
| Invalid tiles | Skipped silently |

## Schema Validation Disable

If you need to bypass schema validation (not recommended):
```bash
helm install --no-hooks <release-name> .
```

Or disable it in Chart.yaml:
```yaml
# Not recommended - removes protection
```
