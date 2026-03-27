# dlc-respond — Good/Bad Examples

Examples of what high-quality thread responses look like vs low-quality, and fix approach quality.

---

## Thread Reply Quality

A good reply has: acknowledgment, fix commit reference, and what was changed.

### ✅ Good reply — addresses reviewer intent, specific commit

```markdown
issue: (ต้องแก้) Fixed in commit `a3f2d1c` —
เพิ่ม null check ก่อน access `user.profile.name`:
`return user.profile?.name ?? null`
ครอบคลุม pre-2024 users ที่ profile ยังไม่มีด้วยครับ
```

```markdown
suggestion: (แนะนำ) Done in `b82c4e9` —
เปลี่ยนจาก for-loop เป็น `.preload('user')` แล้วครับ
ลด query จาก N+1 เหลือ 2 queries
```

```markdown
nitpick: (เล็กน้อย) Fixed in `c91f5a2` —
rename `d` → `daysUntilExpiry` แล้วครับ
```

### ❌ Bad reply — vague, no commit, doesn't address what was changed

```markdown
Fixed.
```

```markdown
Done, thanks.
```

```markdown
Fixed the issue as requested.
```

---

## Addressing Intent vs Literal Wording

The key test: does the fix eliminate the root problem the reviewer was pointing at?

### ✅ Addresses intent

**Reviewer comment:**
> `userService.findById` returns null but line 42 dereferences without check

**Bad interpretation (literal):** Add null check only at line 42
**Good interpretation (intent):** Understand WHY it's null — is `findOrFail` the right call?
If callers must handle null → change return type and add null checks everywhere.
If null should never happen → use `findOrFail` and let it throw with a proper error.

```typescript
// ✅ Addresses intent: callers now handle null explicitly
async getUserProfile(id: string): Promise<UserProfile | null> {
  const user = await User.find(id)
  return user?.profile ?? null
}

// ❌ Literal fix: silently swallows the null case
async getUserProfile(id: string) {
  const user = await User.find(id)
  if (!user) return  // ← returns undefined, not null — caller type mismatch
  return user.profile.name
}
```

---

## Fix Scope — Thread Scope Only

### ✅ Good fix — stays within thread scope

Thread: "Missing null check on `user.profile` at line 42"

```typescript
// Fix: exactly what was asked, nothing more
- return user.profile.name
+ return user.profile?.name ?? null
```

Commit: `fix(users): add null guard on user.profile in getUserProfile`

### ❌ Bad fix — scope creep outside thread

```typescript
// Thread was about 1 null check but fix also:
// - Rewrites entire function
// - Adds a UserProfileService class
// - Refactors 3 other methods
// - Adds logging throughout
// → reviewer can't tell what was changed for their comment
```

---

## Triage Table Quality

### ✅ Good triage — file:line, clear issue, severity assigned

```markdown
## Thread Triage

| # | File | Line | GROUP | Reviewer | Severity | Issue Summary | Status | AC |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | src/auth/user.service.ts | 42 | GROUP-1 | reviewer-a | 🔴 Critical | Missing null check on `user.profile` — crash for pre-2024 users | Open | AC2 |
| 2 | src/auth/user.service.ts | 91 | GROUP-1 | reviewer-a | 🟡 Important | Error message doesn't include userId — hard to debug | Open | — |
| 3 | src/utils/format.ts | 15 | — | reviewer-b | 🟡 Important | Date format `MM/DD/YYYY` — project standard is `YYYY-MM-DD` | Open | — |
| 4 | src/utils/format.ts | 28 | — | reviewer-b | 🔵 Suggestion | `fn` → rename to `formatUserDate` | Open | — |
```

### ❌ Bad triage — no line, vague summary, no severity

```markdown
## Threads

| # | File | Issue | Status |
| --- | --- | --- | --- |
| 1 | user.service | reviewer wants changes | Open |
| 2 | format.ts | formatting issues | Open |
```

---

## Thread Grouping Logic

### ✅ Good grouping — same file → 1 Fixer, parallel for different files

```markdown
GROUP-1 (auth.service.ts: 2 threads) → 1 Fixer (sequential)
GROUP-2 (payment.service.ts: 3 threads) → 1 Fixer (sequential)
user.mapper.ts (1 thread, unique file) → parallel Fixer
```

**Why sequential within group:** avoids concurrent writes to same file causing conflicts.

### ❌ Bad grouping — parallel Fixers on same file

```markdown
Fixer A: fix auth.service.ts:42 (null check)
Fixer B: fix auth.service.ts:91 (error message)  ← concurrent writes to same file
→ Race condition: one fixer's changes overwrite the other's
```

---

## PR Summary After Responding

### ✅ Good summary — all fields filled, all threads accounted for

```markdown
## Respond Review Complete

**PR:** #42
**Threads addressed:** 4 (🔴 1, 🟡 2, 🔵 1)
**Commits made:** 3
**Validate:** ✅ passes (`node ace test` — 47 passed)
**Re-review requested:** reviewer-a

Changes:
- fix: null check on user.profile (resolves thread 1) `a3f2d1c`
- fix: add userId to error context in auth.service (resolves thread 2) `b82c4e9`
- fix: standardize date format to YYYY-MM-DD (resolves thread 3) `c91f5a2`
- (thread 4 accepted as-is: rename deferred to follow-up — noted in reply)
```

### ❌ Bad summary — placeholders not filled, no commit list

```markdown
## Done

PR responded to. Tests pass.
```

---

## When to Skip a Suggestion Thread

Never skip silently. If a Suggestion thread is deferred:

✅ **Good — explain the skip with a reply**

```markdown
nitpick: (เล็กน้อย) ขอ defer ไปก่อนนะครับ — rename ตรงนี้กระทบ 12 call sites
จะทำใน follow-up ticket เพื่อไม่ให้ PR นี้ scope creep ครับ
```

❌ **Bad — silently skip with no reply**

```text
(Thread 4 not addressed — Fixer skipped it)
```
