# Skill Registry

**Delegator use only.** Any agent that launches sub-agents reads this registry to resolve compact rules, then injects them directly into sub-agent prompts. Sub-agents do NOT read this registry or individual SKILL.md files.

## User Skills

| Trigger | Skill | Path |
|---------|-------|------|
| UI/UX design, create interface, build dashboard | ui-ux-pro-max | C:\Users\kitom\.config\opencode\skills\ui-ux-pro-max\SKILL.md |
| Next.js 15, App Router, Server Components | nextjs-15 | C:\Users\kitom\.config\opencode\skills\nextjs-15\SKILL.md |
| Drizzle ORM, database queries, schema | drizzle-orm | C:\Users\kitom\.config\opencode\skills\drizzle-orm\SKILL.md |
| Cloudflare Workers, wrangler, deployment | cloudflare-workers | C:\Users\kitom\.config\opencode\skills\cloudflare-workers\SKILL.md |
| TanStack Query, useQuery, data fetching | tanstack-query | C:\Users\kitom\.config\opencode\skills\tanstack-query\SKILL.md |
| Cloudflare D1, SQLite database | cloudflare-d1 | C:\Users\kitom\.config\opencode\skills\cloudflare-d1\SKILL.md |
| Firebase, Firestore, authentication | firebase-cli | C:\Users\kitom\.config\opencode\skills\firebase-cli\SKILL.md |
| Go testing, Bubbletea TUI | go-testing | C:\Users\kitom\.config\opencode\skills\go-testing\SKILL.md |
| Playwright, browser testing, automation | playwright-cli | C:\Users\kitom\.config\opencode\skills\playwright-cli\SKILL.md |
| GitHub PR, pull request creation | branch-pr | C:\Users\kitom\.config\opencode\skills\branch-pr\SKILL.md |
| GitHub issue, bug report | issue-creation | C:\Users\kitom\.config\opencode\skills\issue-creation\SKILL.md |
| Skill creation, agent instructions | skill-creator | C:\Users\kitom\.config\opencode\skills\skill-creator\SKILL.md |
| Wrangler CLI, Cloudflare KV/R2 | wrangler | C:\Users\kitom\.agents\skills\wrangler\SKILL.md |
| Find skills, discover capabilities | find-skills | C:\Users\kitom\.agents\skills\find-skills\SKILL.md |

## Compact Rules

Pre-digested rules per skill. Delegators copy matching blocks into sub-agent prompts as `## Project Standards (auto-resolved)`.

### ui-ux-pro-max
- Analyze user requirements: product type, style keywords, industry, target audience
- Generate 3 different design options with rationale
- Use searchable design database for priority-based recommendations
- Include accessibility considerations (WCAG 2.1 AA minimum)
- Provide color palettes, typography, spacing, and component recommendations

### nextjs-15
- Server Components by default, add 'use client' only for interactivity/hooks
- Use Server Actions for mutations with 'use server' directive
- File-based routing: app/[slug]/page.tsx for dynamic routes
- Layouts wrap children automatically — use for shared state
- Server Actions: use useActionState for form mutations
- Metadata: export metadata object from page/layout (no &lt;Head&gt;)

### drizzle-orm
- Define schema in drizzle/schema.ts with sqliteTable
- Use relations() for foreign key relationships
- Queries return fully typed results
- Migrations: drizzle-kit push (dev), drizzle-kit migrate (prod)
- Repositories pattern for data access layer

### cloudflare-workers
- Use wrangler.toml for configuration
- Add 'nodejs_compat' compatibility flag for Node APIs
- Environment variables via wrangler secret put
- D1/R2/KV bindings in wrangler.toml, access via env.* in workers
- Deploy with wrangler deploy

### tanstack-query
- useQuery for data fetching, useMutation for writes
- Use queryKey arrays: [&#39;key&#39;, params]
- Invalidate queries with queryClient.invalidateQueries()
- Optimistic updates via onMutate/onSettled
- Prefetch with queryClient.prefetchQuery

### cloudflare-d1
- SQLite via D1 in Cloudflare Workers
- Use drizzle-orm for type-safe queries
- Database binding via D1 database ID in wrangler.toml
- SQL migrations via wrangler d1 execute

### firebase-cli
- Use firebase emulators for local development
- Firestore security rules in firestore.rules
- Auth: use Firebase Auth SDK
- Deploy with firebase deploy

### go-testing
- Use testing package (built-in)
- For TUI: use teatest for Bubbletea
- Table-driven tests preferred
- Coverage with go test -cover

### playwright-cli
- Use Playwright for E2E tests
- Run against localhost for dev, production for smoke tests
- Auto-wait for elements before actions
- Screenshot on failure for debugging

### branch-pr
- Create branch first: git checkout -b feature/xyz
- Commit with conventional commits: feat:, fix:, docs:
- Push: git push -u origin feature/xyz
- Create PR via gh pr create
- Link issue in PR body with Closes #123

### issue-creation
- Use issue-first workflow before any code
- Title: clear description of problem/feature
- Body: context, steps to reproduce, expected vs actual
- Labels: bug, feature, enhancement

### skill-creator
- Follow Agent Skills spec format
- Include frontmatter: name, description, trigger, version
- Document when-to-use and critical patterns
- Provide code examples with explanations

## Project Conventions

| File | Path | Notes |
|------|------|-------|
| AGENTS.md | C:\Users\kitom\OneDrive\Documents\Colmado SAAS\AGENTS.md | Index — reglas del agente para ColmadoAI |
| PROMPT_MAESTRO.md | C:\Users\kitom\OneDrive\Documents\Colmado SAAS\PROMPT_MAESTRO.md | Protocolo de inicio de sesión |

Read the convention files listed above for project-specific patterns and rules.