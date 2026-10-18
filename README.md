# Sproozi Homebrew tap

Install the Sproozi CLI on macOS or Linux:

```sh
brew install andrewmccall/tap/sproozi
sproozi --version
```

The formula builds from the published source bundle. Go is a build dependency.
Installation does not start a service or configure credentials.
See [Sproozi setup](https://github.com/andrewmccall/sproozi/tree/main/docs).

The tap checks for stable Sproozi releases every hour. Maintainers can also run
the **Update Sproozi** workflow. It checks the source checksum, builds and tests
the formula, then commits the update using this repository's workflow token.
