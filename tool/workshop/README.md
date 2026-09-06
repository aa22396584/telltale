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
