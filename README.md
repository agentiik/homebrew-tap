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
| `agentiik` | `agentiik-api`, `agentiik-controller` and, on Linux, `agk-runner`, and `agk` through a dependency | the tagged source of `agentiik/agentiik` |

Both build from source with Go, so what runs is what the tag names. `agentiik` also installs `agentiik-setup`, `agentiik-server` and the service below, and pulls in `nats-server`, which that service runs; PostgreSQL is left to you.

## Run a server with Homebrew

A server on this Mac alone: PostgreSQL and NATS from Homebrew, the API on `https://localhost:8443`.

```
brew install agentiik/tap/agentiik postgresql@17
brew services start postgresql@17
agentiik-setup                                  # once: prints the bootstrap token
brew services start agentiik/tap/agentiik       # migrate, then the bus, the API and the controller, again at every login

export AGENTIIK_SERVER=https://localhost:8443
export AGENTIIK_TOKEN=<the token agentiik-setup printed>
curl --cacert "$(brew --prefix)/etc/agentiik/tls/ca.pem" -H "Authorization: Bearer $AGENTIIK_TOKEN" "$AGENTIIK_SERVER/api/v1/runner-pools"
agk push --namespace demo                       # from a workflow's repository
agk user create <login> --admin                 # the first administrator: open the link it answers

brew upgrade agentiik/tap/agentiik              # upgrade: the service migrates as it starts again
brew services restart agentiik/tap/agentiik
brew services stop agentiik/tap/agentiik        # stop
agentiik-setup remove --yes                     # uninstall: the database, the secrets, the keychain entry
brew uninstall agentiik/tap/agentiik
rm -rf "$(brew --prefix)/etc/agentiik" "$(brew --prefix)/var/log/agentiik"
```

| Step | Does |
| --- | --- |
| `agentiik-setup` | Writes the secret files, readable by their owner alone; a certificate for `localhost`, signed by an authority it adds to the System keychain (it asks for your password) and whose key it then deletes; the bootstrap token, in `operator-token.env`, readable by you alone; the database, and `agentiik-api migrate` given that token; the namespace `demo` with `agentiik-api namespace create` where the server holds none (`--namespace` to create another); the bus identity with `agentiik-api bus-init`. Run again, it keeps all of that and repairs what is missing. |
| `brew services start agentiik/tap/agentiik` | Runs `agentiik-server`, which runs `agentiik-api migrate` with `api.env` and `operator-token.env`, then starts `nats-server`, `agentiik-api serve` and `agentiik-controller`, stops all three if one ends so that launchd starts them again, and stops them at `brew services stop`. |
| `agk user create <login> --admin` | Creates the [first administrator](https://agentiik.github.io/docs/#first-run) with the bootstrap token, which is its one lasting use, gives them every namespace nobody owns, and answers the link on which they enrol; the token works until they have signed in. |

The settings are in `$(brew --prefix)/etc/agentiik`: `api.env` and `controller.env`, one per program since each reads its own [settings](https://agentiik.github.io/docs/#configuration), `nats-server.conf`, and `operator-token.env`, which only `migrate` is given, since every other program refuses the token. An upgrade leaves them as they are, Homebrew writing a newer default beside a settings file as `name.default`. The logs are in `$(brew --prefix)/var/log/agentiik`.

The namespace is `demo`, as in the Compose installation: logins and namespaces share one name space, and one named after you would take the login you want. A server set up by v0.2 keeps its namespace, and the token it printed: the first start after `brew upgrade` imports that token's hash as the bootstrap token's.

The certificate is trusted through the keychain because the programs, `agk` included, trust what macOS trusts, and Go reads no `SSL_CERT_FILE` on macOS. `curl` reads its own list, hence `--cacert`.

Nothing runs a workflow until a runner joins, and a runner is a Linux host: [Installing a runner](https://agentiik.github.io/docs/#installing-a-runner), or the single-host installation in [agentiik/deploy](https://github.com/agentiik/deploy). A runner on another host needs an address it reaches, in `AGK_PUBLIC_URL`, `AGK_BUS_URL` and both listen addresses, and a certificate naming it; this setup listens on loopback alone.

## Releasing

Every repository of the organisation carries the same version and is tagged at the same moment. A formula clones `agentiik/agentiik` at a tag and pins the commit it points at, so it can only be bumped once that tag exists, and this repository is tagged on the bump, since the upgrade job of the next release installs the tap at this tag and needs its formulae to build the release it names:

1. Tag `agentiik/agentiik`.
2. In each formula, set `tag` to the new tag and `revision` to `git ls-remote https://github.com/agentiik/agentiik.git refs/tags/<tag>`, and merge that pull request.
3. Tag this repository on that commit, with the rest of the organisation.

It clones rather than fetching an archive because `go build` stamps the version from the tag, so `agk --version` names the release.

CI builds and tests both formulae on macOS for every pull request, runs the server as [Run a server with Homebrew](#run-a-server-with-homebrew) says, and upgrades a server the previous release's tap set up to this checkout's. Until the formulae name the tag of the release `CHANGELOG.md` names last, the server jobs build the engine's `main` with `--HEAD`, so that the scripts are tested against the programs they will be released with.

## Licence

Apache-2.0, see [LICENSE](LICENSE): the formulae are configuration people copy, like the deployment stacks. The programs they build are AGPL-3.0-or-later.
