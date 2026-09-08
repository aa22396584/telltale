# Public oracle workshop

`run_public_oracles.sh` is the token-free matrix for a clean public checkout.

It binds loopback only, owns PIDs in a private directory, and on EXIT kills the
Ircama child, the chaos proxy, and the freeze-frame reference.

```bash
bash tool/workshop/run_public_oracles.sh
```

Expected counts come from `count_dart_tests.py`. Reports are judged by
`tool/oracle_guard/assert_no_skips.py` (skip ≡ fail). Chaos JSONL must show the
injected fault and the consumed command prefix. `skip_manifest.json` lists
`skipUnless` tests that are legitimate-nonapplicable on other platforms;
undeclared skips fail `assert_skip_manifest.py`.

## Task plan (#11.A)

`plan.json` is the WS-01…WS-29 DAG plus USABILITY-R2 policy. It is not a claim
that those GitHub issues are finished, and it is not the full agent runner
(#11.B).

```bash
python3 tool/workshop/validate_plan.py tool/workshop/plan.json
python3 tool/workshop/validate_plan.py tool/workshop/plan.json --ready
python3 -m unittest discover -s test/tool -p '*workshop*plan*.py' -v
```

The validator refuses missing dependencies, cycles, duplicate ids, path
escape, stale SHAs, missing artifacts, hash mismatch, and skip-as-required-pass.
Ready tasks are those whose issue-number dependencies are `completed` and that
do not share a writable directory with a lower-id peer (lease, not last-writer
wins). Hardware/license blockers stay visible and never become PASS. Commands
are an argv allowlist; issue/comment URLs are not shell.

## Task runner (#11.B)

`run_task.py` executes **one** ready pending task from that plan. It reuses the
validator's argv allowlist, refuses lease conflicts, strips secret environment
variables, and writes `handoff.json`. A failed command cannot be labelled
completed.

`--isolate` adds a detached git worktree at `--base-sha` (or `HEAD`) and runs
the argv there. Combined with `--dry-run` it does not create a worktree, but
still rejects a missing `--base-sha`. Required evidence is checked in that
checkout, not the caller's dirty tree.
The default location is `<git-root>/.worktrees/ws-<task>`, outside `docs/`.
The caller's checkout is not reset. An existing isolate path is a refusal,
not a `git reset`. Handoff and lease stay under the original
`docs/workshop/ws/<task>/` directory.

```bash
python3 tool/workshop/run_task.py tool/workshop/plan.json --task WS-01 --dry-run
python3 tool/workshop/run_task.py tool/workshop/plan.json --task WS-01 --isolate
python3 -m unittest discover -s test/tool -p 'test_workshop_runner.py' -v
```
