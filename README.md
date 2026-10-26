# Sproozi Homebrew tap

Install the Sproozi CLI on macOS or Linux:

```sh
brew install andrewmccall/tap/sproozi
sproozi --version
```

The formula installs tested bottles on macOS and Linux (ARM64 and x86-64).
Go is not a runtime dependency. To compile from the published source bundle:

```sh
brew install --build-from-source andrewmccall/tap/sproozi
```

Go is a build dependency for source installs, including systems without a
compatible bottle.
It also installs the release source, without vendored modules, in
`$(brew --prefix)/share/sproozi`, so `sproozi images build` can build the
container images without downloading it.
Installation does not start a service or configure credentials.
See [Sproozi setup](https://github.com/andrewmccall/sproozi/tree/main/docs).

The tap checks for stable Sproozi releases every hour. Maintainers can also run
the **Update Sproozi** workflow. It checks the source checksum, builds and tests
the formula on all four platforms, builds and reinstalls each bottle, publishes
the archives to a release in this repository, then commits their checksums with
the formula using this repository's workflow token. A failed build leaves the
previous formula intact. Unchanged releases retain their bottle metadata.
