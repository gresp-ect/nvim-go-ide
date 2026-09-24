# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [1.1.0] - 2026-09-25

### Added

- Automatically organize imports and format Go files before saving.
- Optionally run asynchronous tests or `go vet` for the current package after saving.
- Keep save-time checks responsive by running `golangci-lint` only on demand.
- Run the Go test function under the cursor or the current package with one command.
- Jump to the first reported failure and keep all failure locations in quickfix.
- Report statement coverage and highlight uncovered Go source lines.
- Show consistent success or failure notifications with elapsed time for run, build and test tasks.
- Re-run the most recent task with `:TaskRerun` or `Space r .`.
- Show Git change markers and current-line blame annotations while editing.
- Preview and navigate changed hunks or open file diffs with LazyVim's built-in GitSigns actions.
- Add or remove JSON struct tags and generate interface method stubs from dedicated Go shortcuts.
- Debug the current Go file, package, or test with project-level environment variables and startup arguments.

### Fixed

- Exit cleanly when a Go debug template is selected without a valid Go project or configuration.

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
