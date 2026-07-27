#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=00-common.sh
source "$SCRIPT_DIR/00-common.sh"

before_file="${1:-${MOUNTSTATS_DIR}/${MOUNTSTATS_LABEL}-before.txt}"
after_file="${2:-${MOUNTSTATS_DIR}/${MOUNTSTATS_LABEL}-after.txt}"

[[ -f "$before_file" ]] || die "Before snapshot not found: $before_file"
[[ -f "$after_file" ]] || die "After snapshot not found: $after_file"

declare -A before_values=()
declare -A after_values=()
declare -A operations=()

parse_per_op_stats() {
  local file="$1"
  local target_name="$2"
  local -n target="$target_name"
  local in_per_op=0
  local line operation payload
  local -a values
  local index

  while IFS= read -r line; do
    if [[ "$line" == "per-op statistics"* ]]; then
      in_per_op=1
      continue
    fi

    if (( in_per_op )) && [[ "$line" =~ ^[[:space:]]*([A-Z0-9_]+):[[:space:]]+(.+)$ ]]; then
      operation="${BASH_REMATCH[1]}"
      payload="${BASH_REMATCH[2]}"
      read -r -a values <<< "$payload"
      operations["$operation"]=1
      for index in "${!values[@]}"; do
        target["${operation}:${index}"]="${values[$index]}"
      done
    fi
  done < "$file"
}

number_or_zero() {
  local value="${1:-0}"
  [[ "$value" =~ ^[0-9]+$ ]] && printf '%s' "$value" || printf '0'
}

average() {
  local total="$1"
  local count="$2"
  awk -v total="$total" -v count="$count" 'BEGIN {
    if (count > 0) {
      printf "%.3f", total / count
    } else {
      printf "0.000"
    }
  }'
}

parse_per_op_stats "$before_file" before_values
parse_per_op_stats "$after_file" after_values

printf 'operation\tops\ttransmissions\tmajor_timeouts\tbytes_sent\tbytes_received\tavg_queue_ms\tavg_rtt_ms\tavg_execute_ms\n'

while IFS= read -r operation; do
  before_ops="$(number_or_zero "${before_values[${operation}:0]:-0}")"
  after_ops="$(number_or_zero "${after_values[${operation}:0]:-0}")"
  delta_ops=$((after_ops - before_ops))

  (( delta_ops > 0 )) || continue

  before_trans="$(number_or_zero "${before_values[${operation}:1]:-0}")"
  after_trans="$(number_or_zero "${after_values[${operation}:1]:-0}")"
  before_timeouts="$(number_or_zero "${before_values[${operation}:2]:-0}")"
  after_timeouts="$(number_or_zero "${after_values[${operation}:2]:-0}")"
  before_sent="$(number_or_zero "${before_values[${operation}:3]:-0}")"
  after_sent="$(number_or_zero "${after_values[${operation}:3]:-0}")"
  before_received="$(number_or_zero "${before_values[${operation}:4]:-0}")"
  after_received="$(number_or_zero "${after_values[${operation}:4]:-0}")"
  before_queue="$(number_or_zero "${before_values[${operation}:5]:-0}")"
  after_queue="$(number_or_zero "${after_values[${operation}:5]:-0}")"
  before_rtt="$(number_or_zero "${before_values[${operation}:6]:-0}")"
  after_rtt="$(number_or_zero "${after_values[${operation}:6]:-0}")"
  before_execute="$(number_or_zero "${before_values[${operation}:7]:-0}")"
  after_execute="$(number_or_zero "${after_values[${operation}:7]:-0}")"

  delta_trans=$((after_trans - before_trans))
  delta_timeouts=$((after_timeouts - before_timeouts))
  delta_sent=$((after_sent - before_sent))
  delta_received=$((after_received - before_received))
  delta_queue=$((after_queue - before_queue))
  delta_rtt=$((after_rtt - before_rtt))
  delta_execute=$((after_execute - before_execute))

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$operation" \
    "$delta_ops" \
    "$delta_trans" \
    "$delta_timeouts" \
    "$delta_sent" \
    "$delta_received" \
    "$(average "$delta_queue" "$delta_ops")" \
    "$(average "$delta_rtt" "$delta_ops")" \
    "$(average "$delta_execute" "$delta_ops")"
done < <(printf '%s\n' "${!operations[@]}" | sort)
