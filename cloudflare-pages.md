# Cloudflare Pages Configuration for ColmadoAI Admin

## Deploy Flutter Web from FlutterFlow

### Option 1: CLI Deploy (Manual)

```bash
# 1. Export from FlutterFlow and build locally
flutter build web --release
# Output: build/web/

# 2. Deploy with Wrangler
wrangler pages deploy build/web/ \
  --project-name=colmado-saas-admin
```

### Option 2: GitHub Integration (Automatic)

In Cloudflare Dashboard → Pages → Create project → Connect to GitHub:

| Setting | Value |
|---------|-------|
| Repository | kitomc/colmado-saas |
| Production branch | main |
| Build command | (empty - use FlutterFlow hosting) |
| Build output | (empty - use FlutterFlow hosting) |

**Note:** FlutterFlow has built-in hosting. Connect your FlutterFlow project to GitHub for automatic deploys.

---

## Redirect Rule (Critical)

This redirect is required for Flutter Web to work properly:

```json
{
  "from": "/*",
  "to": "/index.html",
  "status": 200
}
```

Without this, direct navigation to routes like `/dashboard` will return 404.

---

## Environment Variables

If using Cloudflare Workers for WhatsApp relay:

```bash
# In Cloudflare Dashboard → Workers → Settings → Variables
CONVEX_URL = "https://your-project.convex.cloud"
VERIFY_TOKEN = "your_webhook_verify_token"
```

---

## Related Files

- `workers/whatsapp-relay/` - Cloudflare Worker for WhatsApp webhook
- `convex/http.ts` - Convex HTTP Action endpoints
- `docs/flutterflow-admin-guide.md` - FlutterFlow implementation guide