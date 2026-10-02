# Changelog

The releases of `homebrew-tap`. Every repository carries the same version and is tagged at the same moment, so an entry may say that nothing changed; [Versioning](https://agentiik.github.io/docs#versioning) says why. `0.y.z` promises nothing beyond itself.

## v0.6.0, 2026-10-02

- `agk` and `agentiik` build from `v0.6.0`.
- `agentiik` builds the web console, with Node as a build dependency, before `agentiik-api`, which serves it from its own binary at `https://localhost:8443`, where the source holds one, from v0.6.0. It is named with the version the programs record, as the engine's release names the console of its images, and `brew test` checks that `agentiik-api` carries it.
- `agentiik` installs `agk-runner` on Linux alone. A runner is a Linux host, and on a Mac the program could only refuse to join, as it now says it does.
- `etc/agentiik/api.env` names `AGK_CONSOLE`, commented out: `off` serves the API alone, the sign-in page included.
- CI checks a server's console at the root of its address, an address of its own below it and the files its page names, then its absence with `AGK_CONSOLE=off` in `api.env` while the sign-in page still answers, where `agentiik-api` carries one. A `CHANGELOG.md` opening on Unreleased builds the engine's `main` with `--HEAD` in the server jobs, as one naming a release the formulae do not build yet does, so that what the next release changes is tested before its tag.

## v0.5.0, 2026-09-30

- `agk` and `agentiik` build from `v0.5.0`.

## v0.4.0, 2026-09-30

- `agk` and `agentiik` build from `v0.4.0`.

## v0.3.0, 2026-09-28

- `agk` and `agentiik` build from `v0.3.0`.
- `agentiik-server` runs `agentiik-api migrate` at every start, before the bus, the API and the controller, so that `brew upgrade` and `brew services restart` are the whole of an upgrade. It migrates as the role Homebrew's PostgreSQL made for you, unless `api.env` sets `AGK_MIGRATE_DATABASE_URL`, which `agentiik-setup` now refuses from the shell, since the service could not read it there.
- `agentiik-setup` keeps the bootstrap token in `etc/agentiik/operator-token.env`, mode 0600, which `migrate` alone is given. A server set up by v0.2 keeps the token it printed: the first start imports its hash, once.
- `agentiik-setup` creates the namespace `demo` rather than one named after you, and only where the server holds none, since logins and namespaces share one name space.
- `agentiik-setup`, the caveats and the README name the bootstrap token, and end at creating the first administrator with `agk user create LOGIN --admin`.
- CI upgrades a server the previous release's tap set up, and checks that its token is the bootstrap token and creates the first administrator. Until the formulae name the release's tag, the server jobs build the engine's `main` with `--HEAD`.

## v0.2.5, 2026-09-26

- `agk` and `agentiik` build from `v0.2.5`.

## v0.2.4, 2026-09-26

- `agk` and `agentiik` build from `v0.2.4`.

## v0.2.3, 2026-09-26

- `agk` and `agentiik` build from `v0.2.3`.

## v0.2.2, 2026-09-26

- `agk` and `agentiik` build from `v0.2.2`.

## v0.2.1, 2026-09-26

- `agk` and `agentiik` build from `v0.2.1`.
- `agentiik`: a service, `brew services start agentiik/tap/agentiik`, running the bus, the API and the controller on this Mac; `agentiik-setup` prepares them once, the settings are in `etc/agentiik`, and the README says how in order. CI runs it on macOS.

## v0.2.0, 2026-09-26

- `agk`: the command line, built from the tagged source with the static helper embedded for both Linux architectures.
- `agentiik`: `agentiik-api`, `agentiik-controller` and `agk-runner`, built from the tagged source, with `agk` as a dependency.
- The README says to `brew trust agentiik/tap` first, which Homebrew 7 asks of a third-party tap.
- CI installs both formulae as a person does, from the tap on GitHub, on every push to `main` and every tag, and checks each program names the tag.
