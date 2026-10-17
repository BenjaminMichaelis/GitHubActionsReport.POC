# GitHubActionsReport.POC

Does `--report-gh` (`Microsoft.Testing.Extensions.GitHubActionsReport` 2.4.1) emit its GitHub workflow
commands (log groups, error/skipped annotations, slow-test notices) when the tests run through
`dotnet test`, or only when the test exe is run directly?

## What the docs say
[MS Learn: GitHub Actions reports](https://learn.microsoft.com/en-us/dotnet/core/testing/microsoft-testing-platform-test-reports#github-actions-reports)
says that with `GITHUB_ACTIONS=true` and `--report-gh`, a run produces per-assembly log groups,
failed/skipped test annotations, a Markdown job summary and slow-test notices. It does not distinguish
`dotnet test` from running the exe.

## Hypothesis
Under `dotnet test` (MTP pipe mode) the output device forwards only a fixed set of message kinds,
so the extension's plain-text `::error` / `::group::` lines are dropped. The job summary survives
because the extension writes it straight to the `GITHUB_STEP_SUMMARY` file.

## Layout
- `src/Repro`: MSTest.Sdk project with a passing, failing, skipped and slow (3s) test.
- `src/Repro2`: second test project, so the solution run has two test modules.
- `.github/workflows/exe-direct.yml`: control. Runs the built exe with `--report-gh`.
- `.github/workflows/dotnet-test.yml`: suspect path. Matrix over `dotnet test --project`, `--solution`, and bare `dotnet test`.
- `.github/scripts/proof.sh`: counts workflow commands in the captured stdout and writes a table to each job's summary.

Each test step `tee`s its combined output to `out.txt` (uploaded as an artifact). The runner parses
workflow commands from that same stdout stream, so a command absent from `out.txt` never reached the runner.
The `failed` test is red on purpose; the test step uses `continue-on-error`.

## Local pre-check (SDK 10.0.402, Windows, `GITHUB_ACTIONS=true`)
| Invocation | `::group::` | `::error` | `::warning` (skipped) | `::notice` (slow) | Summary file |
|---|---|---|---|---|---|
| exe directly | yes | yes | yes | yes | written |
| `dotnet test --project` | 0 | 0 | 0 | 0 | written |
| `dotnet test --solution` | 0 | 0 | 0 | 0 | written (one section per project) |

## CI results
Run on `ubuntu-latest`, SDK 10.0.x. Counts are from the captured stdout ([run: exe-direct](https://github.com/BenjaminMichaelis/GitHubActionsReport.POC/actions/runs/38999967966), [run: dotnet-test](https://github.com/BenjaminMichaelis/GitHubActionsReport.POC/actions/runs/38999967971)).

| Invocation | `::group::` | `::error` | `::warning` (skipped) | `::notice` (slow) | Job summary | Annotations from the extension |
|---|---|---|---|---|---|---|
| exe directly | 1 | 1 | 1 | 2 | written | failed test (`Tests.cs:12`), skipped test (`Tests.cs:14`), 2 slow-test notices |
| `dotnet test --project` | 0 | 0 | 0 | 0 | written | none |
| `dotnet test --solution` | 0 | 0 | 0 | 0 | written | none |
| bare `dotnet test` | 0 | 0 | 0 | 0 | written | none |

Solution level behaved the same as project level. The exe-direct control confirms the repro is valid
(all documented outputs appear), and every `dotnet test` leg drops all of them while still writing the summary.

Two unrelated annotations appear on every job and do not come from the extension: the MSTEST0025 analyzer
warning on `Tests.cs:12` (from `dotnet build`, via the runner's problem matcher) and runner/Node deprecation notices.

This matches the hypothesis but does not by itself prove the cause (the passthrough output device);
that part still rests on reading the testfx source.
