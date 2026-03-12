# Improving skill-creator: Test, measure, and refine Agent Skills

**Source:** <https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills>
**Published:** March 3, 2026

## Overview

Skill-creator now includes tools to help authors verify their skills function properly, detect regressions, and improve descriptions without requiring coding expertise.

## Two Categories of Skills

**Capability uplift skills** enhance Claude's baseline abilities through encoded techniques and patterns. Document creation skills exemplify this category—they produce superior results compared to prompting alone.

**Encoded preference skills** organize existing Claude capabilities into sequences matching team workflows. Examples include skills for NDA review processes or weekly update drafting from multiple data sources.

This distinction matters because testing needs differ:

- Capability uplift skills may become unnecessary as models advance
- Encoded preference skills remain valuable if they accurately reflect actual workflows

## Testing Through Evaluations

Skill-creator now enables writing evals—tests checking whether Claude performs as expected for given prompts. The PDF skill previously struggled with non-fillable forms; evals isolated this failure, enabling a coordinate-anchoring fix.

Evals serve two critical purposes:

- **Catching quality regressions**: Model infrastructure changes can alter skill behavior, making early detection crucial before team impact.
- **Recognizing capability obsolescence**: When base models pass evals without the skill loaded, the skill's techniques may have been incorporated into default behavior.

**Benchmark mode** provides standardized assessment tracking pass rates, elapsed time, and token usage after model updates or during skill iteration.

## Multi-Agent Evaluation Support

Sequential eval execution creates bottlenecks and context contamination. The new multi-agent support spins up independent agents running evals in parallel, each with clean context and separate metrics—eliminating cross-contamination while accelerating results.

**Comparator agents** enable A/B testing between skill versions or skill versus baseline, judging outputs blindly for objective improvement assessment.

## Skill Description Optimization

Output quality matters only if skills trigger appropriately. As skill counts grow, description precision becomes critical:

- Overly broad descriptions → false triggers
- Overly narrow descriptions → prevent activation

Skill-creator analyzes current descriptions against sample prompts, suggesting refinements reducing both false positives and false negatives. Testing across document-creation skills improved triggering performance on 5 of 6 public skills.

## Future Direction

The distinction between "skill" and "specification" may blur as models advance. Currently, SKILL.md files function as implementation plans providing detailed instructions. Eventually, natural-language descriptions of desired outcomes may suffice, with models determining execution approaches independently.

The released eval framework represents progress toward this goal, as evals already articulate the "what"—potentially becoming the skill itself eventually.

## Getting Started

All updates are available on Claude.ai and Cowork. Users can request Claude utilize skill-creator directly. Claude Code users can install the plugin or download from the official repository.
