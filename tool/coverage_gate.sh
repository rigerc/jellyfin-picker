#!/bin/bash
# Enforce the aggregate LCOV line-coverage threshold.

set -euo pipefail

readonly COVERAGE_THRESHOLD=80

die() {
  printf 'coverage gate: %s\n' "$1" >&2
  return 1
}

check_coverage() {
  local lcov_file="$1"
  local totals
  local lines_hit
  local lines_found
  local percentage

  if [[ ! -f "${lcov_file}" ]]; then
    die "LCOV file not found: ${lcov_file}"
  fi

  totals="$(awk -F: '
    /^(LF|LH):/ {
      if ($1 == "LF") lines_found += $2
      if ($1 == "LH") lines_hit += $2
    }
    END {
      if (lines_found == 0) exit 2
      printf "%d %d", lines_hit, lines_found
    }
  ' "${lcov_file}")" || die "LCOV file contains no line metrics"

  read -r lines_hit lines_found <<<"${totals}"
  percentage="$(awk -v hit="${lines_hit}" -v found="${lines_found}" \
    'BEGIN { printf "%.1f", (hit / found) * 100 }')"

  if ! awk -v hit="${lines_hit}" -v found="${lines_found}" \
    -v threshold="${COVERAGE_THRESHOLD}" \
    'BEGIN { exit ((hit / found) * 100 >= threshold) ? 0 : 1 }'; then
    die "line coverage ${percentage}% is below ${COVERAGE_THRESHOLD}%"
  fi

  printf 'coverage gate: line coverage %s%% (%d/%d)\n' \
    "${percentage}" "${lines_hit}" "${lines_found}"
}

main() {
  local lcov_file="${1:-coverage/lcov.info}"
  check_coverage "${lcov_file}"
}

main "$@"
