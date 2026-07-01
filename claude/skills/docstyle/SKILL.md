---
name: docstyle
description: >-
  Audit, rewrite, or edit a document to my house style and strip AI tells.
  Use when drafting or editing any prose document (incident report, runbook,
  ADR, Confluence page, Jira ticket, status update, README, PR body) or when
  asked to de-slop, humanize, or proofread text. Three modes: detect (flag
  only), rewrite (fix and show the diff), edit (minimal in-place fixes).
---

# docstyle

Make a document read like a careful engineer wrote it, not a model. House rules below are the source of truth (they mirror `style.md`, which governs all my output); the vocabulary and structural checks are the long tail.

These are signals, not proof. A single flagged word is not a crime. Do not over-correct: applying every rule at maximum strictness produces its own robotic uniformity, which is the thing you are trying to avoid. Fix what reads as machine-generated; leave what already sounds human.

Attribution: the pattern library and tiered vocabulary are adapted from [`avoid-ai-writing`](https://github.com/conorbronsdon/avoid-ai-writing) by Conor Bronsdon (MIT), trimmed and merged with my house style.

## Modes

- **detect** — flag issues, no rewrite. Group by severity (P0/P1/P2), mark each as a clear problem or a judgment call. Use when auditing text you do not want altered.
- **rewrite** (default) — fix the issues, output the clean version, then a short "what changed", then run one corrective second pass to catch tells the first pass introduced. Stop after two passes.
- **edit** — minimal, targeted in-place edits to the flagged spans only. Preserve passages that are already human, plus quotes and code. Re-read after to verify.

## House rules (source of truth, override everything below)

- No em-dashes. Use commas, periods, parentheses, or "to" for ranges. Rephrase the sentence if that is what it takes. This is absolute; do not relax it for any document type.
- "and", not `+` or `&`, to join words in prose and headings. Carve-out: `+` or `/` inside a technical token stays (`4xx/5xx`, `p50/p95`, `CPU/mem`).
- Do not over-bold. Bold a term when it earns emphasis, not every other phrase. Single-word bold spans are almost always wrong.
- No emoji unless the user used them first.
- Answer first. Lead with the result. No preamble, no "I'll now", no recaps of the question, no sign-offs ("let me know if...").
- Assume an expert reader. Skip basics and boilerplate.
- Cite code as `path:line`.
- Banned phrases (never ship these): "it's worth noting", "delve", "boasts", "a testament to", "rest assured", "in today's fast-paced", "not only X but also Y", and reflexive rule-of-three lists.

## Artifact registers (match the document)

Write each type in its native register. The register decides which checks below relax.

- **Incident / postmortem** — formal, narrative where it aids understanding (timeline, impact, root cause, what we would do differently). Honest about what went wrong.
- **Runbook / SOP** — terse, numbered, imperative steps. Commands in code blocks. Assume a competent operator under pressure. Relax the bullet, hedging, and uniform-length checks; a runbook is supposed to be a list.
- **Jira / Slack / status update** — short and scoped. Lint only the worst offenders (P0). Lead with what changed and the link; no redundant timestamps (the platform stamps it); outcome over mechanism (don't explain how it was made unless it changes what the reader does).
- **Confluence / shared doc** — structured and scannable. TL;DR up top, headers, bullets, tables for reference data.
- **ADR / design doc** — context, decision, consequences. State the trade-offs.

Technical carve-out: in runbooks, ADRs, and infra docs, words like `robust`, `comprehensive`, `ecosystem`, `leverage` (financial), and `streamline` can be literal and correct. Do not flag them there unless they are clearly filler.

## AI vocabulary, tiered

Match inflected forms (`-ly`, `-ing`, plurals, conjugations).

**Tier 1 — always replace.** These are 5-20x more common in AI text.

| Word | Replace with |
|---|---|
| delve / delve into | explore, dig into, look at |
| landscape (metaphor) | field, space, industry |
| tapestry | (describe the actual complexity) |
| realm | area, field, domain |
| paradigm | model, approach, framework |
| embark | start, begin |
| testament to | shows, proves, demonstrates |
| robust | strong, reliable, solid |
| comprehensive | thorough, complete, full |
| cutting-edge | latest, newest, advanced |
| leverage (verb) | use |
| pivotal | important, key, critical |
| underscores | highlights, shows |
| meticulous(ly) | careful, detailed, precise |
| seamless(ly) | smooth, easy, without friction |
| game-changer / game-changing | (say what specifically changed) |
| utilize | use |
| watershed moment | turning point, shift |
| nestled | is located, sits, is in |
| vibrant / thriving | growing, active (or cite a number) |
| showcasing | showing, demonstrating (or cut) |
| deep dive / dive into | look at, examine |
| unpack / unpacking | explain, break down, walk through |
| intricate / intricacies | complex, detailed |
| ever-evolving | changing, growing |
| daunting | hard, difficult |
| holistic(ally) | complete, full, whole |
| actionable | practical, useful, concrete |
| impactful | effective, significant |
| learnings | lessons, findings, takeaways |
| thought leader(ship) | expert, authority |
| best practices | what works, proven methods |
| at its core | (cut) |
| synergy / synergies | (describe the combined effect) |
| interplay | relationship, connection |
| in order to | to |
| due to the fact that | because |
| serves as | is |
| features (verb) | has, includes |
| boasts | has |
| presents (inflated) | is, shows, gives |
| commence | start, begin |
| ascertain | find out, determine |
| endeavor | effort, attempt, try |
| embrace (metaphor) | adopt, accept, use |

**Tier 2 — flag when 2 or more appear in one paragraph.**

`harness, navigate, foster, elevate, unleash, streamline, empower, bolster, spearhead, resonate, revolutionize, facilitate, underpin, nuanced, crucial, multifaceted, ecosystem, myriad, plethora, encompass, catalyze, reimagine, galvanize, augment, cultivate, illuminate, elucidate, juxtapose, transformative, cornerstone, paramount, poised (to), burgeoning, nascent, quintessential, overarching, underpinning`

**Tier 3 — flag only at density (~3% of words, or many clustered).**

`significant, innovative, effective, dynamic, scalable, compelling, unprecedented, exceptional, remarkable, sophisticated, instrumental, world-class, state-of-the-art, best-in-class`

## Structural and rhetorical checks

- **Copula avoidance** — "serves as / features / boasts / presents / represents" where "is / has" is meant.
- **Negation frames** — "It's not X, it's Y", "This isn't about X, it's about Y". Max one per piece.
- **Compulsive triads** — the reflexive "adjective, adjective, and adjective". Vary it: use two items, four, or a full sentence.
- **Hedging** — "perhaps", "could potentially", "it's important to note that". State it plainly or cut it.
- **Vague attribution** — "experts believe", "studies show" with no source. Name the source or drop the claim.
- **Significance / novelty inflation** — "a significant milestone", "a groundbreaking approach". Say what happened.
- **False concession** — "While X is impressive, Y remains a challenge".
- **Sentence and paragraph uniformity** — vary length and rhythm. Read it aloud.
- **Low information density** — paragraphs you could reshuffle without changing the meaning. Cut them.

## Formatting tells

- Title-case headings where sentence case is meant.
- List-label period: `**Intros.**` where a human writes `**Intros:**`.
- Inline-header repetition: `**Performance:** Performance improved...`.
- Excessive structure: many headings or bullets in a short span; formulaic "Overview / Summary / Conclusion" scaffolding.

## AI-tool fingerprints (P0, always fix)

These mean text was pasted from a chat UI. Near-zero false positives.

- Cutoff or self-ID disclaimers: "as of my last update", "as an AI language model", "I don't have real-time data".
- Unfilled placeholders: `[Your Name]`, `[Insert X]`, `2025-XX-XX`.
- Citation-markup leaks: `citeturn0search0`, `oai_citation`, `contentReference[oaicite...]`.
- Chat-UI URL params: `utm_source=chatgpt.com` and similar.

## Severity

- **P0** — fingerprints above, and any banned phrase. Always fix.
- **P1** — Tier 1 vocabulary, copula avoidance, negation frames, hedging.
- **P2** — Tier 2/3 vocabulary, uniformity, polish. Fix by judgment and register.

The deterministic lint hook (`hooks/docstyle-lint.sh`) covers the greppable P0 subset plus em-dashes and single-word bold on every `.md` write. This skill is the deeper, on-demand pass.

## Self-reference escape hatch

Do not flag text inside code blocks, inline-code backticks, or blockquotes, and do not flag a phrase that a document is deliberately quoting as an example (a doc about these rules will name the banned words). Otherwise the skill flags its own documentation.

## Output format

- **detect** — issues grouped P0/P1/P2, each marked clear-problem or judgment-call. No rewrite.
- **rewrite** — the issues found, then the rewritten text, then a short "what changed", then the second-pass result.
- **edit** — a before/after list of the spans changed, then a one-line verification that nothing else moved.
