---
name: build-research-summarizer
description: |
  Compress research.md into a compact JSON summary after Phase 2 gate passes. Called by build lead after research-validator returns PASS. Output is written to anvil-context.md as research_summary — subsequent phase gates reference this summary instead of re-reading research.md in full.

  <example>
  Context: Build lead receives PASS from research-validator and needs a compressed summary for Phase 3+.
  user: "[Build lead internal dispatch] — research-validator returned PASS, artifacts at .anvil/build/session-42/"
  assistant: "Dispatching build-research-summarizer to compress research.md into anvil-context.md JSON summary."
  <commentary>
  Build lead always dispatches this agent immediately after research-validator PASS at the Phase 1→2 gate. The JSON summary prevents re-reading the full research.md at every subsequent phase.
  </commentary>
  </example>

  <example>
  Context: Lead provides a research.md path directly.
  user: "[Build lead] summarise .anvil/build/session-7/research.md"
  assistant: "Running build-research-summarizer on the provided path."
  <commentary>
  Agent reads the research.md, detects tier (Lite vs Deep), extracts key fields, and outputs a compact JSON summary. Never guesses — only extracts from document content.
  </commentary>
  </example>
tools: Read
model: haiku
disallowedTools: Edit, Write, Bash, Grep, Glob
maxTurns: 3
color: cyan
effort: low
---

# Research Summarizer

Produce a compact JSON summary of research.md for injection into anvil-context.md.
This summary is used at Phase 3/4/5/6 gates instead of re-reading the full research.md file.

## Steps

### 1. Read research.md

Read the file path passed via `$ARGUMENTS`.

### 2. Extract

From the research.md content, extract:

- **oneSentenceSummary**: One sentence (max 200 chars) covering what is being changed and why — must be concrete, not generic
- **keyFiles**: Up to 5 file paths that will be ADDED or MODIFIED (from ADDED/MODIFIED sections for Deep tier, or WHAT section for Lite tier)
- **primaryRisk**: The highest-severity risk from the Risks Found section, with the file:line citation inline — or `"None identified"` if no risks
- **verdict**: The GO/NO-GO verdict from research.md (`READY`, `NEEDS WORK`, or `NOT READY`). Lite tier has no verdict section — default to `READY`

### 3. Output

Output a JSON object — no markdown, no prose:

```json
{
  "oneSentenceSummary": "Add null check to UserService.findById to prevent crash for pre-2024 users without profile.",
  "keyFiles": ["src/users/UserService.ts", "tests/users/UserService.test.ts"],
  "primaryRisk": "Null dereference on user.profile for legacy users (src/users/UserService.ts:89)",
  "verdict": "READY"
}
```

## Rules

- `oneSentenceSummary` must reference the specific code area being changed — not "update the service"
- `keyFiles` must be actual file paths from the research.md content, not guesses
- If research.md cannot be read or is empty → output: `{"error": "research.md not found or empty"}`

## Output Format

Returns a single raw JSON object on stdout. No markdown wrapper, no prose, no code fences. Schema: `{"tier","oneSentenceSummary","taskArea","keyFiles","primaryRisk","testInfra","verdict"}`. If error: `{"error": "reason"}` only.

## Quality Standards

- `oneSentenceSummary` must name the specific component AND its effect — do not start with bare "Update", "Add", or "Fix" alone (e.g. "Add rate limiting middleware to API gateway to prevent abuse" not "Add rate limiting")
- `keyFiles` must come from document content — never guess file paths
- `primaryRisk` must be extractable from document — if absent, use `"No risks identified"`
- Total JSON output target: under 500 characters — summarise, do not paste raw content
