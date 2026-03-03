# Spec Quality Review Criteria

Use when the user asks to review or improve a `spec.md`, or before recommending `/speckit.plan`.

## Quick Review Checklist

Run through these checks and report findings grouped by severity.

### CRITICAL — Spec cannot proceed to plan

- [ ] **Tech stack contamination** — spec mentions specific frameworks, languages, or databases
  - Look for: React, Next.js, Django, PostgreSQL, Redis, REST, GraphQL, etc.
  - Fix: move to `/speckit.plan` prompt; replace with behavior description
- [ ] **No acceptance scenarios** — user stories exist but have no Given/When/Then
  - A spec with only "As a user I want X" is not executable
- [ ] **Missing success criteria** — no SC-NNN entries
  - Without measurable criteria, "done" is undefined
- [ ] **No P1 stories** — all stories are P2/P3
  - There must be a clear MVP scope

### HIGH — Will cause plan/task problems

- [ ] **Vague acceptance criteria** — scenarios lack specificity
  - BAD: "Then: the user sees a success message"
  - GOOD: "Then: a toast notification appears with text 'Photo saved' and disappears after 3 seconds"
- [ ] **Missing error/edge case scenarios** — only happy path covered
  - Every user story needs at least one failure/edge scenario
- [ ] **Overlapping functional requirements** — FR entries duplicate each other or contradict
- [ ] **Out of Scope section missing** — without it, scope creep is inevitable
- [ ] **Acceptance scenarios not independently testable** — scenario requires running 3 other scenarios first

### MEDIUM — Reduces plan quality

- [ ] **User stories not prioritized** — no P1/P2/P3 labels
- [ ] **FR entries not traceable to stories** — functional requirements that no user story references
- [ ] **SC entries not measurable** — "system is fast" is not a success criterion
  - GOOD: "SC-003: Search returns results within 500ms for datasets up to 10,000 items"
- [ ] **Clarifications section empty** — if `/speckit.clarify` was skipped, flag ambiguities manually

### LOW — Polish issues

- [ ] Overview section is a single sentence — expand to 2-3 sentences explaining context and value
- [ ] User story titles are too generic ("User Story 1: Basic Functionality")
- [ ] No explicit actor defined in stories (who is the "user"? admin? guest? API consumer?)

---

## Spec Draft Assistant

When user says "help me write a spec" or "create a spec for X", gather this information before drafting:

### Required information (ask if missing)

1. **What does it do?** — Core user action in one sentence
2. **Who uses it?** — Primary actor(s) (end user, admin, external API, cron job, etc.)
3. **Why does it matter?** — Business/user value; what problem does it solve?
4. **What are the main flows?** — 2-5 key scenarios the user cares about most
5. **What's explicitly OUT of scope?** — At least 2-3 items to prevent scope creep

### Inferred automatically (do not ask)

- Tech stack → deferred to `/speckit.plan`
- Implementation details → deferred to `/speckit.plan`
- Task breakdown → deferred to `/speckit.tasks`

### Draft process

1. Write Overview (what + why, no tech)
2. Convert flows → User Stories with P1/P2/P3 priority
   - P1 = minimum viable; app is broken without this
   - P2 = important but shippable without
   - P3 = nice-to-have
3. Expand each story → Given/When/Then scenarios (happy path + at least 1 error case)
4. Extract cross-cutting Functional Requirements (FR-001...) — things that apply to multiple stories
5. Define Success Criteria (SC-001...) — measurable, not vague
6. Write Out of Scope — be specific and explicit
7. Leave Clarifications empty (for `/speckit.clarify`)

### Example: turning a vague request into a spec

**User says:** "I want to add photo albums to my app"

**Ask:**

- "Who creates albums? Only the logged-in user, or can others share albums?"
- "What happens when a photo is added to an album that already has 100 photos?"
- "Should albums be private by default or public?"

**Then draft:**

```markdown
# Spec: Photo Albums

## Overview
Allow authenticated users to organize their uploaded photos into named albums.
Albums provide a way to group related photos for sharing and personal organization.

## User Stories

### User Story 1: Create and manage albums [P1]
**As a** logged-in user, **I want** to create named photo albums and add photos to them,
**so that** I can organize my photos by event or theme.

#### Acceptance Scenarios

**Scenario 1: Create a new album**
- Given: I am on the Photos page
- When: I click "New Album" and enter the name "Summer 2024"
- Then: A new empty album appears in my album list with the name "Summer 2024"

**Scenario 2: Duplicate album name**
- Given: I already have an album named "Summer 2024"
- When: I try to create another album with the same name
- Then: An error message appears: "You already have an album with this name"
...
```

---

## Common Spec Anti-Patterns

| Anti-Pattern | Example |
| --- | --- |
| Implementation leak | "Use a modal dialog for confirmation" |
| Tech stack leak | "Store in PostgreSQL" |
| Non-testable scenario | "Then: everything works correctly" |
| Infinite scope | "Users can manage all their data" |
| Missing actor | "When submitted" |
| Untestable SC | "SC-001: System is performant" |
