export function buildReviewer2Prompt(config: {
  diffContent: string
  sharedRules: string
  hardRules: string
  lensContent: string
  dismissedPatterns: string
}): string {
  return `You are reviewing code changes for architecture and performance issues.

YOUR FOCUS: N+1 prevention (#3), DRY & simplicity (#4), flatten structure (#5), small functions & SOLID (#6), performance (#7), and all Hard Rules.

DRY & SIMPLICITY (#4): Flag copy-paste variation, parallel conditionals, re-implementing framework built-ins, over-abstraction.

FLATTEN STRUCTURE (#5): Flag nesting > 1 level, callback pyramid, ternary nesting, else-after-return.

SOLID (#6): Flag Single Responsibility violations, Open/Closed violations, Dependency Inversion issues, God objects.

PERFORMANCE (#7): Flag sequential await on independent ops, re-computation in hot path, unbounded collection loaded before filter.

SQL PERFORMANCE: Check index coverage, pagination pattern (keyset > OFFSET), batch operations, migration safety (DROP without backup, NOT NULL without DEFAULT, FK without index).

${config.sharedRules}

HARD RULES:
${config.hardRules}

${config.lensContent ? `DOMAIN LENSES:\n${config.lensContent}` : ''}

KNOWN FALSE POSITIVES (do not re-raise without new evidence):
${config.dismissedPatterns || 'None'}

EXAMPLES:

VALID FINDING — sequential awaits on independent operations:
\`\`\`
Citation: src/orders/checkout.service.ts:52 — const inventory = await checkInventory(id); const price = await fetchPrice(id);
Pre-existing: no — introduced in this diff
Assumption: checkInventory and fetchPrice have no data dependency on each other
Confidence: C:90
\`\`\`
Finding: warning | sequential-await | src/orders/checkout.service.ts:52 — two independent async calls run sequentially; checkInventory and fetchPrice have no dependency so both ops pay full round-trip latency in sequence
Fix: \`const [inventory, price] = await Promise.all([checkInventory(id), fetchPrice(id)])\`

NOT A FINDING — orchestrator function with multiple method calls:
Code: \`async function processCheckout(order) { await validateOrder(order); await reserveInventory(order); await chargePayment(order); await sendConfirmation(order); }\`
Why not flagged: Not a Single Responsibility violation — this IS the SRP-correct orchestrator whose single responsibility is to sequence the checkout steps. Each step is in its own service. Flagging this as a God object or SRP violation would be wrong.

DIFF TO REVIEW:
${config.diffContent}
`
}
