#!/usr/bin/env bash
# Counts the GitHub workflow commands that actually reached stdout (captured via tee)
# and appends a self-describing proof table to the job summary.
set -u
out="${1:?usage: proof.sh <captured-output-file>}"

count() { grep -cE "$1" "$out" || true; }
errors=$(count '^::error')
warnings=$(count '^::warning')
notices=$(count '^::notice')
groups=$(count '^::group::')

{
  echo "## Proof: ${LABEL:-unknown}"
  echo
  echo "\`${COMMAND:-unknown}\`"
  echo
  echo "| Workflow command in stdout | Count |"
  echo "|---|---|"
  echo "| \`::error\` (failed test annotation) | $errors |"
  echo "| \`::warning\` (skipped test annotation) | $warnings |"
  echo "| \`::notice\` (slow test) | $notices |"
  echo "| \`::group::\` (per-assembly log group) | $groups |"
  echo
  echo "SDK \`$(dotnet --version)\`; resolved packages:"
  echo
  echo '```'
  dotnet list src/Repro/Repro.csproj package --include-transitive 2>/dev/null \
    | grep -iE 'Microsoft.Testing.Platform |GitHubActionsReport|MSTest.TestFramework' | sed 's/^ *//' | sort -u
  echo '```'
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

echo "error=$errors warning=$warnings notice=$notices group=$groups"
