## Mode Check

ถ้า `--quick` flag ระบุมา → **skip Phase 4 entirely** (ข้ามทั้ง debate round ไปยัง Phase 5).
ถ้า `--focused` flag ระบุมา → **skip Phase 4** (specialist ไม่มี debate ระหว่าง reviewer อื่น).

---

# Phase 4: Adversarial Debate

Follow [debate-protocol](../../debate-protocol/SKILL.md) exactly:

1. **Pre-Debate Triage:** Auto-pass (Hard Rule + conf ≥90), auto-drop (Info + conf <80), must-debate (all others). Only must-debate findings enter round-robin.
2. **Broadcast** must-debate findings to teammates in compact format — one line per finding: `[T{n}-F{n}] file:line — issue summary (conf:{score})`. Omit full evidence and fix suggestion from broadcast; teammates re-read code at file:line as needed during their debate response.
3. **Round-robin:** Correctness reviews Architecture's findings · Architecture reviews DX's · DX reviews Correctness's.
4. **Consensus check:** Proceed if consensus, else Round 2 on unresolved only. After Round 2, lead decides on evidence quality. Max 2 rounds.
5. **Output:** Debate summary table — Finding / Raised By / Challenged By / Outcome. Show: Consensus (N/3), Dropped (reason), Lead decided (rationale).
