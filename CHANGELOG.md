# Changelog

The releases of `homebrew-tap`. Every repository carries the same version and is tagged at the same moment, so an entry may say that nothing changed; [Versioning](https://agentiik.github.io/docs#versioning) says why. `0.y.z` promises nothing beyond itself.

## Unreleased

- `agentiik`: a service, `brew services start agentiik/tap/agentiik`, running the bus, the API and the controller on this Mac; `agentiik-setup` prepares them once, the settings are in `etc/agentiik`, and the README says how in order. CI runs it on macOS.

## v0.2.0, 2026-09-26

- `agk`: the command line, built from the tagged source with the static helper embedded for both Linux architectures.
- `agentiik`: `agentiik-api`, `agentiik-controller` and `agk-runner`, built from the tagged source, with `agk` as a dependency.
- The README says to `brew trust agentiik/tap` first, which Homebrew 7 asks of a third-party tap.
- CI installs both formulae as a person does, from the tap on GitHub, on every push to `main` and every tag, and checks each program names the tag.
