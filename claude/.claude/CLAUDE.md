
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

## Other

- Avoid em-dashes (`---`) and en-dashes (`--`) for parenthetical explanation. Use a comma, or split into two sentences.
- No emojis or em-dashes.
- Do not guess APIs, versions, flags, commit SHAs, or package names. Verify by reading code or docs before asserting.
- If a job takes too long, send a slack notification via skill when the job is finished.

