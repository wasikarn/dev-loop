#!/usr/bin/env bash
# devflow metrics dashboard
# Usage: bash scripts/dashboard.sh
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
METRICS_FILE="$CLAUDE_DIR/devflow-metrics.jsonl"
CALIBRATION_FILE="$CLAUDE_DIR/devflow-reviewer-calibration.jsonl"

# plugin_data_dir — mirrors hooks/lib/common.sh logic
plugin_data_dir() { echo "${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/devflow-devflow}"; }

SKILL_USAGE_FILE="$(plugin_data_dir)/skill-usage.tsv"

# Colors
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

section() { printf "\n${BOLD}${CYAN}%s${NC}\n" "$1"; printf "────────────────────────────\n"; }
alert()   { printf "  ${RED}⚠${NC}  %s\n" "$1"; }
warn()    { printf "  ${YELLOW}!${NC}  %s\n" "$1"; }
ok()      { printf "  ${GREEN}✓${NC}  %s\n" "$1"; }
info()    { printf "  %s\n" "$1"; }

printf '%bdevflow Dashboard%b\n' "${BOLD}" "${NC}"
printf "%s\n" "$(date '+%Y-%m-%d %H:%M')"

# ---------------------------------------------------------------------------
# 1. Session Summary (last 10 from metrics.jsonl)
# ---------------------------------------------------------------------------
section "Session Summary (last 10)"

if [ ! -f "$METRICS_FILE" ]; then
  info "No metrics data — run /build or /debug at least once."
else
  # Total sessions
  TOTAL=$(wc -l < "$METRICS_FILE" | tr -d ' ')
  info "Total sessions recorded: ${TOTAL}"

  # Mode breakdown (last 10)
  MODE_BREAKDOWN=$(tail -10 "$METRICS_FILE" | jq -r '.mode // "unknown"' 2>/dev/null | sort | uniq -c | sort -rn | awk '{printf "    %-10s %s\n", $2, $1}')
  if [ -n "$MODE_BREAKDOWN" ]; then
    info "Mode breakdown (last 10):"
    printf "%s\n" "$MODE_BREAKDOWN"
  fi

  # Avg iterations (last 10)
  AVG_ITER=$(tail -10 "$METRICS_FILE" | jq -s 'if length == 0 then "N/A" else ([.[].iterations // 0] | add / length | . * 10 | round / 10 | tostring) end' 2>/dev/null)
  info "Avg iterations (last 10): ${AVG_ITER}"

  # Critical findings shipped (last 10)
  CRITICAL_SHIPPED=$(tail -10 "$METRICS_FILE" | jq -s '[.[] | select((.final_critical // 0) > 0)] | length' 2>/dev/null)
  if [ "${CRITICAL_SHIPPED}" -gt 0 ]; then
    warn "Sessions shipped with critical findings (last 10): ${CRITICAL_SHIPPED}"
  else
    ok "No sessions shipped with critical findings (last 10)"
  fi
fi

# ---------------------------------------------------------------------------
# 2. Anomaly Alerts
# ---------------------------------------------------------------------------
section "Anomaly Alerts"

if [ ! -f "$METRICS_FILE" ]; then
  info "No data to check."
else
  ANOMALY_COUNT=0

  # Alert: avg iterations > 3.0 in last 10
  AVG_ITER_RAW=$(tail -10 "$METRICS_FILE" | jq -s 'if length == 0 then 0 else ([.[].iterations // 0] | add / length) end' 2>/dev/null)
  AVG_GT3=$(echo "$AVG_ITER_RAW" | awk '{print ($1 > 3.0) ? "1" : "0"}')
  if [ "$AVG_GT3" = "1" ]; then
    alert "High avg iterations: ${AVG_ITER_RAW} (threshold: 3.0) — repeated rework detected"
    ANOMALY_COUNT=$((ANOMALY_COUNT + 1))
  fi

  # Alert: any session in last 5 with final_critical > 0
  LAST5_CRITICAL=$(tail -5 "$METRICS_FILE" | jq -s '[.[] | select((.final_critical // 0) > 0)] | length' 2>/dev/null)
  if [ "${LAST5_CRITICAL}" -gt 0 ]; then
    alert "Recent critical findings shipped: ${LAST5_CRITICAL} of last 5 sessions — review quality gap"
    ANOMALY_COUNT=$((ANOMALY_COUNT + 1))
  fi

  # Alert: avg findings_reversed > 2 in last 5
  AVG_REVERSED=$(tail -5 "$METRICS_FILE" | jq -s 'if length == 0 then 0 else ([.[].findings_reversed // 0] | add / length) end' 2>/dev/null)
  AVG_REV_GT2=$(echo "$AVG_REVERSED" | awk '{print ($1 > 2.0) ? "1" : "0"}')
  if [ "$AVG_REV_GT2" = "1" ]; then
    alert "High findings reversed: avg ${AVG_REVERSED}/session (last 5) — possible reviewer overconfidence"
    ANOMALY_COUNT=$((ANOMALY_COUNT + 1))
  fi

  if [ "$ANOMALY_COUNT" -eq 0 ]; then
    ok "No anomalies detected"
  fi
fi

# ---------------------------------------------------------------------------
# 3. Reviewer Calibration (from calibration.jsonl)
# ---------------------------------------------------------------------------
section "Reviewer Calibration"

if [ ! -f "$CALIBRATION_FILE" ]; then
  info "No calibration data — reviewer accuracy is tracked after /review sessions."
else
  CALIB_COUNT=$(wc -l < "$CALIBRATION_FILE" | tr -d ' ')
  if [ "$CALIB_COUNT" -eq 0 ]; then
    info "Calibration file is empty."
  else
    info "Records: ${CALIB_COUNT}"
    printf "\n"
    # Per-reviewer aggregates (role, submitted, sustained, rejected, downgraded, accuracy%)
    # Only show roles with >= 3 records
    tail -200 "$CALIBRATION_FILE" | jq -r '
      .role // "unknown"
    ' 2>/dev/null | sort -u | while IFS= read -r ROLE; do
      STATS=$(tail -200 "$CALIBRATION_FILE" | jq -r --arg role "$ROLE" '
        [.[] | select(.role == $role)] |
        if length < 3 then empty
        else
          . as $entries |
          {
            role: $role,
            submitted: ([$entries[].submitted // 0] | add),
            sustained: ([$entries[].sustained // 0] | add),
            rejected:  ([$entries[].rejected  // 0] | add),
            downgraded:([$entries[].downgraded // 0] | add),
            records:   ($entries | length)
          } |
          . + {
            accuracy: (if .submitted > 0 then (.sustained / .submitted * 100 | round) else 0 end),
            rej_rate: (if .submitted > 0 then (.rejected  / .submitted * 100 | round) else 0 end)
          } |
          "\(.role)\t\(.records)\t\(.submitted)\t\(.sustained)\t\(.rejected)\t\(.downgraded)\t\(.accuracy)%\t\(.rej_rate)%"
        end
      ' 2>/dev/null)
      if [ -n "$STATS" ]; then
        printf "  %-28s  recs=%-4s sub=%-4s sus=%-4s rej=%-4s dg=%-4s acc=%-6s rej%%=%s\n" \
          "$(printf '%s' "$STATS" | cut -f1)" \
          "$(printf '%s' "$STATS" | cut -f2)" \
          "$(printf '%s' "$STATS" | cut -f3)" \
          "$(printf '%s' "$STATS" | cut -f4)" \
          "$(printf '%s' "$STATS" | cut -f5)" \
          "$(printf '%s' "$STATS" | cut -f6)" \
          "$(printf '%s' "$STATS" | cut -f7)" \
          "$(printf '%s' "$STATS" | cut -f8)"
      fi
    done

    # Flag noisy reviewers (rej_rate > 40%) and high accuracy (> 90%)
    tail -200 "$CALIBRATION_FILE" | jq -r '
      group_by(.role) |
      .[] |
      . as $g |
      ($g | length) as $count |
      if $count < 3 then empty
      else
        ($g[0].role // "unknown") as $role |
        ([$g[].submitted // 0] | add) as $sub |
        ([$g[].rejected  // 0] | add) as $rej |
        ([$g[].sustained // 0] | add) as $sus |
        if $sub > 0 then
          (($rej / $sub) * 100 | round) as $rej_pct |
          (($sus / $sub) * 100 | round) as $acc_pct |
          if   $rej_pct > 40 then "NOISY|\($role)|\($rej_pct)"
          elif $acc_pct > 90 then "ACCURATE|\($role)|\($acc_pct)"
          else empty
          end
        else empty
        end
      end
    ' 2>/dev/null | while IFS='|' read -r FLAG ROLE PCT; do
      case "$FLAG" in
        NOISY)    warn "Noisy reviewer: ${ROLE} (rejection rate ${PCT}% > 40%)" ;;
        ACCURATE) ok   "High accuracy: ${ROLE} (accuracy ${PCT}% > 90%)" ;;
      esac
    done
  fi
fi

# ---------------------------------------------------------------------------
# 4. Skill Usage (from skill-usage.tsv)
# ---------------------------------------------------------------------------
section "Top 10 Skill Usage"

if [ ! -f "$SKILL_USAGE_FILE" ]; then
  info "No skill usage data — run any skill to start tracking."
  info "(Expected at: ${SKILL_USAGE_FILE})"
else
  USAGE_COUNT=$(wc -l < "$SKILL_USAGE_FILE" | tr -d ' ')
  info "Total invocations logged: ${USAGE_COUNT}"
  printf "\n"
  # TSV: TIMESTAMP<TAB>SKILL_NAME — count by skill, top 10
  awk -F'\t' '{print $2}' "$SKILL_USAGE_FILE" | sort | uniq -c | sort -rn | head -10 | \
    awk '{printf "  %-5s %s\n", $1, $2}'
fi

printf "\n"
