# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added

- Run the Go test function under the cursor or the current package with one command.
- Jump to the first reported failure and keep all failure locations in quickfix.
- Report statement coverage and highlight uncovered Go source lines.

## [1.0.1] - 2026-09-19

### Fixed

- Install and verify the pinned tree-sitter CLI on fresh systems.
- Prevent headless plugin setup from depending on an unfinished Mason install.
- Declare Ubuntu 24.04 LTS as the exact supported platform.

## [1.0.0] - 2026-09-18

### Added

- Reproducible LazyVim-based Go development environment.
- `nvim-go` installer, stable updater, diagnostics and rollback commands.
- Pinned Neovim, Go, Go tools and plugin versions.
- Persistent bottom shell session and separate bottom task terminal.
- Go completion, formatting, linting, testing and debugging support.
- User-local configuration and plugin override files.
