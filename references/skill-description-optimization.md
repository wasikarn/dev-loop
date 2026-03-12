# Skill Description Optimization

Guide สำหรับ optimize descriptions ของ auto-invocable skills — ทั้ง manual approach และ automated (skill-creator eval framework)

---

## Step 0: ระบุ skills ที่ต้อง optimize

**Only auto-invocable skills matter.** Skills ที่มี `disable-model-invocation: true` ใน frontmatter จะถูกลบ description ออกจาก context ทั้งหมด — optimize ไปก็ไม่มีผล

```bash
# หา skills ที่ไม่มี disable-model-invocation: true
grep -rL "disable-model-invocation" skills/*/SKILL.md
```

---

## Step 1: Manual Optimization Checklist

จาก [blog.anthropic.com: Improving skill-creator](../references/blog-improving-skill-creator.md) — ทำก่อน run eval เสมอ

### Pushiness (สำคัญที่สุด)

| ❌ Undertriggering | ✅ Aggressive |
| --- | --- |
| "Use when user mentions X" | "Use this skill whenever X" |
| "Can be used for Y" | "Always trigger when Y" |
| "Helpful for Z" | "Invoke immediately when Z" |

### Trigger Keywords

- ใส่ exact phrases ที่ user จะพิมพ์จริง ในรูป `'phrase'`
- ครอบคลุม synonyms: "research" / "analyze" / "understand" / "plan first"
- ใส่ near-miss phrases ที่ควร trigger แม้ไม่ explicit

### Structure ที่ดี

```text
<verb> + <what it does>. Use when/whenever <trigger conditions>.
Triggers: '<phrase1>', '<phrase2>', '<phrase3>'.
<what it produces/outputs>.
```

### Limits

- Max **1024 chars** สำหรับ `description:` field
- อย่าซ้ำกับ skill อื่น — เช็ค near-miss ที่ควร trigger skill อื่น

---

## Step 2: Eval Set Generation

สร้าง 20 queries สำหรับ test (ทำผ่าน skill-creator หรือ manual):

| กลุ่ม | จำนวน | หลัก |
| --- | --- | --- |
| `should_trigger: true` | 10 | Diverse phrasings, near-misses ที่ควรยิง |
| `should_trigger: false` | 10 | Near-misses ที่ควร trigger skill อื่น หรือไม่ควร trigger เลย |

**Tips:**

- ใช้ภาษาที่ user จริงๆ จะพิมพ์ (ไม่ formal เกินไป)
- รวม cases ที่ explicit ("research first please") และ implicit ("i want to add a notification system")
- should-NOT-trigger ควรมี keyword คล้ายกันแต่ intent ต่าง (เช่น "explain the codebase" vs "research before implementing")

**Format:**

```json
[
  { "query": "research first please — ...", "should_trigger": true },
  { "query": "fix the null pointer in ...", "should_trigger": false }
]
```

---

## Step 3: Run Eval Framework

### Prerequisites

```bash
# Install anthropic ใน venv (ต้องการสำหรับ run_loop.py เท่านั้น)
PLUGIN_DIR=~/.claude/plugins/cache/claude-plugins-official/skill-creator
VERSION=$(ls $PLUGIN_DIR | head -1)
uv venv $PLUGIN_DIR/venv --python 3.12
uv pip install anthropic --python $PLUGIN_DIR/venv/bin/python

# Set ANTHROPIC_API_KEY (ต้องการสำหรับ improve_description.py)
export ANTHROPIC_API_KEY=sk-ant-...
```

### Run eval only (วัด recall/precision ของ description ปัจจุบัน)

```bash
SC=$PLUGIN_DIR/$VERSION/skills/skill-creator

# ⚠️ Unlink real skill ก่อน (ดู Known Limitations ข้างล่าง)
mv ~/.claude/skills/<skill-name> ~/.claude/skills/<skill-name>.bak

(cd $SC && PYTHONPATH="$SC" $PLUGIN_DIR/venv/bin/python -m scripts.run_eval \
  --eval-set path/to/eval-set.json \
  --skill-path path/to/skills/<skill-name> \
  --runs-per-query 1 \
  --num-workers 5 \
  --timeout 45 \
  --verbose)

# Restore
mv ~/.claude/skills/<skill-name>.bak ~/.claude/skills/<skill-name>
```

### Run full optimization loop (ต้องการ API key)

```bash
(cd $SC && PYTHONPATH="$SC" $PLUGIN_DIR/venv/bin/python -m scripts.run_loop \
  --eval-set path/to/eval-set.json \
  --skill-path path/to/skills/<skill-name> \
  --model claude-sonnet-4-6 \
  --max-iterations 5 \
  --verbose 2>&1 | tee run_loop_output.txt)
```

Loop จะ:

1. Split 60% train / 40% test (holdout)
2. Run 3 queries per eval per iteration
3. ใช้ extended thinking เพื่อ propose improved description
4. Select best by test score (ไม่ใช่ train — ป้องกัน overfitting)

---

## Known Limitations

### 1. `superpowers:using-superpowers` masks detection ⚠️

**ปัญหา:** eval detection ตรวจ first Skill tool call — ถ้า `superpowers:using-superpowers` อยู่ใน context, Claude จะ invoke มันก่อนเสมอ (`"Use when starting any conversation"`) → detection return False → recall=0% เสมอ

**Workaround:** ยังไม่มี workaround ที่ดี options:

- ทำ manual optimization แทน (ไม่ใช้ eval)
- Run eval จาก clean environment ที่ไม่มี superpowers plugin

### 2. Installed skill conflict

**ปัญหา:** ถ้า skill ที่กำลัง test ถูก install ใน `~/.claude/skills/` แล้ว, Claude จะ invoke real skill (`Skill("deep-research-workflow")`) แทน temp eval command (`Skill("deep-research-workflow-skill-XXXXXXXX")`) → detection miss

**Workaround:** Unlink ก่อน run eval เสมอ (ดู command ข้างบน)

### 3. No ANTHROPIC_API_KEY in Claude Code session

**ปัญหา:** Claude Code ใช้ OAuth ไม่ใช่ API key → `ANTHROPIC_API_KEY` ไม่ถูก set → `improve_description.py` fail

**Workaround:** Export API key ด้วยตัวเอง หรือใช้ `run_eval.py` เพื่อวัดผลเฉยๆ แล้ว improve description manually

---

## Metrics to Track

| Metric | Target |
| --- | --- |
| Recall (should-trigger) | ≥ 70% |
| Precision (should-not-trigger) | ≥ 90% |
| Description length | ≤ 1024 chars |

**recall=0% หมายความว่าอะไร:**

- Description ไม่ pushy พอ → เพิ่ม "whenever", "always trigger"
- Trigger keywords ไม่ครบ → เพิ่ม synonyms
- หรือ Known Limitation ข้อ 1-2 ข้างบน

---

## Quick Checklist Before Committing

- [ ] Description เริ่มด้วย action verb
- [ ] มี "whenever" หรือ "always trigger when" (ไม่ใช่แค่ "use when")
- [ ] Trigger phrases ครอบคลุม explicit + implicit phrasings
- [ ] ระบุ output/artifact ที่ skill จะสร้าง (ช่วย Claude ตัดสินใจ invoke)
- [ ] ไม่ซ้อนกับ skill อื่น (ทดสอบ near-miss ด้วยมือ)
- [ ] ≤ 1024 chars
