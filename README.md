# homebrew-tap

Homebrew formulae for [Agentiik](https://agentiik.github.io/docs).

```
brew trust agentiik/tap                    # once: Homebrew 7 loads a third-party tap's formulae only when trusted
brew install agentiik/tap/agk              # the command line alone
brew install agentiik/tap/agentiik         # the server programs, with the command line
```

| Formula | Installs | Built from |
| --- | --- | --- |
| `agk` | `agk`, with the static helper a script step mounts at `/agk/bin/agk` embedded for linux/amd64 and linux/arm64 | the tagged source of `agentiik/agentiik` |
| `agentiik` | `agentiik-api`, `agentiik-controller` and `agk-runner`, and `agk` through a dependency | the tagged source of `agentiik/agentiik` |

Both build from source with Go, so what runs is what the tag names. `agentiik` does not pull in PostgreSQL or NATS, which are as often on another machine as on this one; its caveats say how to run both locally.

## Releasing

Every repository of the organisation carries the same version and is tagged at the same moment. A formula clones `agentiik/agentiik` at a tag and pins the commit it points at, so it can only be bumped once that tag exists:

1. Tag every repository, this one included.
2. In each formula, set `tag` to the new tag and `revision` to `git ls-remote https://github.com/agentiik/agentiik.git refs/tags/<tag>`, and open a pull request.

It clones rather than fetching an archive because `go build` stamps the version from the tag, so `agk --version` names the release.

CI builds and tests both formulae on macOS for every pull request.

## Licence

Apache-2.0, see [LICENSE](LICENSE): the formulae are configuration people copy, like the deployment stacks. The programs they build are AGPL-3.0-or-later.
