
# CLAUDE.md

Behavioral guidelines to merge with project-specific instructions.

## Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## Academic Paper Writing (LaTeX)

**Direct, concise prose. Consistent notation.**

When writing or editing academic manuscripts in `.tex`:
- Avoid em-dashes (`---`) and en-dashes (`--`) for parenthetical explanation. Use a comma, or split into two sentences.
- Minimize parentheses. If a point matters, state it as a sentence; if it doesn't, drop it.
- Write simple, direct sentences. Avoid nested clauses where a period would do.
- Keep notation consistent throughout the manuscript: each symbol defined once, used the same way everywhere.
- Every sentence should earn its place. Cut filler, hedges, and restatements.

## Storage Policy on the ai2 Slurm Cluster

Applies when working on `ai2` (`gsai-login-2`). Ignore elsewhere.

| Path | Purpose | Limit |
|------|---------|-------|
| `/home1/dongwookim` | Home dir. Work environment, IDE, Slurm jobs only. | **500GB** |
| `/home/dongwookim` | Data storage. Datasets, models, checkpoints. | No limit (request expansion) |
| `/public-dataset` | Read-only large datasets. | No limit |
| `/scratch` | Temporary downloads and staging. | Small, clean up immediately |
| `/local-data/user-data` | GPU node temp storage. Auto-deleted after the Slurm job ends. | ~3.5-7T |

1. Never store large data in the home directory. Datasets, checkpoints, and models go in `/home/dongwookim`, not `/home1/dongwookim`.
2. Download external data to `/scratch` first, then move it to the right location. Delete from `/scratch` immediately after.
3. Minimize file count. Bundle small files with `tar`. Many small files degrade NFS performance for every user.
4. Warn the user if an operation risks exceeding the 500GB home directory limit.
5. GPU node temp data in `/local-data/user-data` is deleted after each Slurm job. Copy results out before the job ends.
6. Prefer `/home/dongwookim` over `/home1/dongwookim` when suggesting locations for data files.

