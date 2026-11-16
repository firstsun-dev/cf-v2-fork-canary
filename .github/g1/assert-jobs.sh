#!/usr/bin/env bash
# assert-jobs.sh "<job name>=<conclusion>" ...   Asserts the conclusion of INNER jobs of THIS run attempt (jobs of called reusable workflows are named
# "<caller job> / <job>"). This is how a deliberate negative test turns an EXPECTED inner failure into a green, explained result:
# the caller job fails by design, and this script verifies it failed in exactly the expected job and that the jobs that must not run did not.
# A name may end in '*' (prefix match). Needs GH_TOKEN and `permissions: actions: read`.
set -euo pipefail
jobs="$(gh api --paginate "repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID/attempts/$GITHUB_RUN_ATTEMPT/jobs?per_page=100" --jq '.jobs[] | [.name, (.conclusion // "running")] | @tsv')"
rc=0
for want in "$@"; do
  name="${want%=*}"; exp="${want##*=}"
  if [[ "$name" == *'*' ]]; then got="$(printf '%s\n' "$jobs" | awk -F'\t' -v p="${name%\*}" 'index($1,p)==1 {print $2}' | sort -u | paste -sd,)"
  else got="$(printf '%s\n' "$jobs" | awk -F'\t' -v n="$name" '$1==n {print $2}' | paste -sd,)"; fi
  if [ "$got" = "$exp" ]; then echo "ok   $name = $exp"; else echo "FAIL $name: expected '$exp', got '${got:-<no such job>}'"; rc=1; fi
done
[ "$rc" = 0 ] || { echo "--- jobs of this run ---"; printf '%s\n' "$jobs" | sort; }
exit "$rc"
