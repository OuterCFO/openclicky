# Contributing

Read the repository's `AGENTS.md` and [setup guide](docs/SETUP.md) first.
Keep changes focused, preserve upstream attribution, and explain what behavior changes.
Do not commit credentials, private conversations, recordings, signing material, generated runtimes, or Xcode user state.

## Checks

```sh
scripts/run-source-checks.sh
```

Use Xcode for native builds and app tests.
The source checks do not replace a full native build or live acceptance test.
For UI changes, record the exact final build and user-visible steps that were tested.
Do not claim a visual fix from compilation alone.

Submit a pull request with the problem, resulting behavior, checks, and remaining limitations.
Include a regression test for a meaningful contract when practical.
Use public or synthetic screen content in examples.
Never manually edit generated files or changelogs.

The legacy release scripts and updater feed are retained for upstream history, but are not this fork's supported publication workflow.
Do not publish artifacts using the upstream maintainer's signing identity or release URLs.
