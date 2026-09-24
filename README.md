# homebrew-tap

Homebrew formulae for [Agentiik](https://agentiik.github.io/docs).

```
brew install agentiik/tap/agk              # the command line alone
brew install --HEAD agentiik/tap/agentiik  # the server programs, with the command line
```

| Formula | Installs | Built from |
| --- | --- | --- |
| `agk` | `agk`, with the static helper a script step mounts at `/agk/bin/agk` embedded for linux/amd64 and linux/arm64 | the tagged source of `agentiik/agentiik` |
| `agentiik` | `agentiik-api`, `agentiik-controller` and `agk-runner`, and `agk` through a dependency | `main` until `v0.2.0` is tagged, since no release holds the server programs yet |

Both build from source with Go, so what runs is what the tag names. `agentiik` does not pull in PostgreSQL or NATS, which are as often on another machine as on this one; its caveats say how to run both locally.

## Releasing

Every repository of the organisation carries the same version and is tagged at the same moment. A formula names the source archive of `agentiik/agentiik` by its SHA-256, so it can only be bumped once that tag exists:

1. Tag every repository, this one included.
2. Point `url` at the new tag's archive in each formula, set `sha256` to `curl -sL <url> | shasum -a 256`, and open a pull request.
3. From `v0.2.0` on, `agentiik` gets a stable `url` and loses its `--HEAD` only status.

CI builds and tests both formulae on macOS for every pull request.

## Licence

Apache-2.0, see [LICENSE](LICENSE): the formulae are configuration people copy, like the deployment stacks. The programs they build are AGPL-3.0-or-later.
