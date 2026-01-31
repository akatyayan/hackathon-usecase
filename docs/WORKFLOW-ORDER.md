# How the GitHub Actions Workflows Work

## Flow: Build → Terraform → Deploy (all 3 workflows chained)

The three workflows are chained so they run in this order:

1. **Build and Push Images** runs first (when you push app code or run it manually).
2. When Build **completes successfully** → **Terraform** runs.
3. When Terraform **completes successfully** → **Deploy to GKE** runs.

So: **Build** (first) → **Terraform** (second) → **Deploy** (third).

### First-time only

Build pushes to **Artifact Registry**, which is created by Terraform. So the **very first time** you need to run **Terraform** once manually so the registry and GKE cluster exist:

1. **Actions** → **Terraform** → **Run workflow** (branch: main) → wait for it to finish.
2. After that, the flow works: push app code (or run **Build and Push Images**) → Build runs → Terraform runs → Deploy runs.

---

## When you push to `main`

GitHub runs **only the workflows whose `paths` match your changed files**. So **which workflow runs first** depends on **what you changed** in the push.

---

## Trigger rules (what starts each workflow)

| Workflow | Runs when… | Then triggers… |
|----------|------------|----------------|
| **Build and Push Images** | You push app paths or run it manually | When it **succeeds** → **Terraform** runs |
| **Terraform** | You push `Terraform/**`, or **after Build and Push Images completes successfully**, or run it manually | When it **succeeds** → **Deploy to GKE** runs |
| **Deploy to GKE** | **After Terraform completes successfully** (on main), or run it manually | — |

So on a single push (app code):

- **Build and Push Images** runs first.
- When Build **succeeds**, **Terraform** runs.
- When Terraform **succeeds**, **Deploy to GKE** runs.

---

## Flow in practice

### Push only Terraform

```
You push (e.g. change Terraform/environments/dev/main.tf)
    → Terraform workflow runs (push trigger)
    → Build and Push does NOT run (no app paths changed)
    → Deploy does NOT run (Deploy only runs after Terraform; it will run after this Terraform run succeeds)
```

### Push only application code

```
You push (e.g. change application-service/src/index.js)
    → Build and Push Images runs (first)
    → When Build succeeds → Terraform runs (second)
    → When Terraform succeeds → Deploy to GKE runs (third)
```

### Push both Terraform and application code

```
You push (e.g. change Terraform/... and patient-service/...)
    → Build and Push Images runs (app paths changed)
    → Terraform also runs (Terraform paths changed) — two workflows start
    → When Build succeeds → Terraform runs again (workflow_run trigger)
    → When Terraform succeeds → Deploy runs
```

### Push something else (e.g. docs, README)

```
You push (e.g. change docs/GKE-DEPLOYMENT.md)
    → No workflow runs (no path matches)
    → You can still run any workflow manually from the Actions tab
```

---

## Order of execution (when multiple run)

- **Same push:** Terraform and Build and Push Images start **at the same time** (both triggered by the push). There is no “Terraform first” or “Build first” for that push — they are independent.
- **Deploy** always comes **after** Build and Push Images, and only if Build and Push **succeeded**. So the sequence is:

```
[ Push to main ]
       │
       ├── If paths match Terraform/**     → Terraform workflow runs
       │
       └── If paths match app paths        → Build and Push Images runs
                    │
                    └── When it completes successfully
                                │
                                └── Deploy to GKE runs
```

---

## Recommended order (first-time / infra change)

If you are setting things up or changing infra, run in this order **manually** (or by pushing in two steps):

1. **Terraform** – so the GKE cluster and Artifact Registry exist.
2. **Build and Push Images** – so images are in the registry (trigger by pushing app code or Run workflow).
3. **Deploy to GKE** – runs automatically after step 2 succeeds, or run it manually.

So: **Terraform first** (once), then **Build and Push** (on app changes or manual), then **Deploy** (auto after build or manual).

---

## Summary

| Question | Answer |
|----------|--------|
| Which runs **first**? |’s `paths` **Build and Push Images** (when you push app code or run it manually). |
| Then what? | When Build **succeeds** → **Terraform** runs. When Terraform **succeeds** → **Deploy** runs. |
| If I push only app code? | Build runs → Terraform runs (after Build succeeds) → Deploy runs (after Terraform succeeds). |
| If I push only Terraform? | **Terraform** runs (push trigger). Deploy runs after that Terraform run succeeds. |
