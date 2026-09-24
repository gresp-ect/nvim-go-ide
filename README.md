# nvim-go-ide

A reproducible, fast Go development environment for Neovim, designed for
**Ubuntu 24.04 LTS** and **WSL Ubuntu 24.04 LTS** on amd64 or arm64.

The project installs pinned versions of Neovim, Go, tree-sitter, Go development tools and
LazyVim plugins into the current user's home directory. System administrator
access is used only when an apt package is missing.

Other Ubuntu releases, Debian and other Linux distributions are intentionally
rejected so the tested installation remains deterministic.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/gresp-ect/nvim-go-ide/main/bootstrap.sh | bash
```

Restart the shell and open a project:

```bash
cd ~/projects/my-project
nvim .
```

## Management command

```bash
nvim-go install
nvim-go update
nvim-go update --check
nvim-go update --dry-run
nvim-go update --version v1.0.1
nvim-go doctor
nvim-go rollback
nvim-go version
```

Updates use stable GitHub Releases, verify the release checksum, stage and
validate the new configuration, and only then switch the active symlink. The
three most recent releases are retained for rollback.

## Go workflow

Open Neovim from a directory containing `go.mod`. Run and build commands save
modified buffers and display output in a bottom task terminal until any key is
pressed. Focused test commands run asynchronously and report results in-place.

| Command | Action |
| --- | --- |
| `:GoRunPackage` | Run the package containing the current Go file |
| `:GoRunFile` | Run only the current Go file |
| `:GoRun` | Run the module root package |
| `:GoBuild` | Build all packages |
| `:GoTest` | Test all packages |
| `:GoTestVerbose` | Test all packages verbosely |
| `:GoTestNearest` | Test the function under the cursor and show coverage |
| `:GoTestPackage` | Test the current package and show coverage |
| `:GoTestOutput` | Show the latest structured test output |
| `:GoCoverageClear` | Clear uncovered-line markers |
| `:GoSaveCheckOutput` | Show output from the latest save-time test or vet run |
| `:GoVet` | Vet all packages |
| `:GoLint` | Run golangci-lint |
| `:GoTidy` | Tidy the module |
| `:GoGenerate` | Run Go code generation |
| `:Run command` | Run any shell command in the bottom task terminal |

`F5` runs the current package. The same actions are available below the
`Space r` key group.

`Space t n` runs the test function under the cursor and `Space t p` tests its
package. A failed run jumps directly to the first source location reported by
Go and also fills the quickfix list for subsequent failures. Each run reports
the statement coverage percentage and highlights uncovered lines. Use
`Space t o` to inspect the complete output and `Space t c` to clear coverage.

## Terminal sessions

`:terminal`, `:term` and `Ctrl-/` toggle one persistent shell session in a
bottom split. Its directory and history remain available while Neovim is open.

Task commands such as `:Run` and `:GoRunPackage` use a separate bottom terminal
so running a program never replaces the persistent shell session.

## Language features

- Completion and signature help: Insert mode or `Ctrl-Space`
- Hover documentation: `K`
- Definition and references: `gd` and `gr`
- Rename and code actions: `Space c r` and `Space c a`
- Organize imports and format: `Space c o` and `Space c f`
- Breakpoint and debugger: `Space d b` and `Space d c`
- Current test function and package: `Space t n` and `Space t p`
- Neotest nearest test and test summary: `Space t r` and `Space t s`

### Checks on save

Saving a Go file automatically runs `goimports` followed by `gofumpt`, so
imports and formatting are updated before the file is written. Full
`golangci-lint` runs remain manual through `:GoLint` because they can be slow
on large projects.

An additional asynchronous check of only the current package can be enabled in
`~/.config/nvim-go-ide/local.lua`:

```lua
vim.g.nvim_go_save_check = "test" -- go test .
-- vim.g.nvim_go_save_check = "vet" -- go vet .
```

Leave the option unset (the default) to disable the extra check. Failed checks
show a notification; use `:GoSaveCheckOutput` to inspect their complete output.

## Personal configuration

Managed files are replaced only by stable project releases. Put personal
changes in files that the updater never overwrites:

```text
~/.config/nvim-go-ide/local.lua
~/.config/nvim-go-ide/plugins.lua
```

`local.lua` is for options, mappings and autocommands. `plugins.lua` must
return a list of lazy.nvim plugin specifications.

## Files and backups

```text
~/.config/nvim                         active managed configuration
~/.config/nvim-go-ide/                 personal overrides
~/.local/bin/nvim-go                   management command
~/.local/opt/nvim-go-ide/              managed tool versions
~/.local/share/nvim-go-ide/releases/   installed project releases
~/.local/state/nvim-go-ide/backups/    replaced files and symlinks
```

Run `nvim-go doctor` after installation. Windows Terminal fonts cannot be
changed from WSL; select **JetBrainsMono Nerd Font** in the terminal profile.

## Development

```bash
bash tests/test.sh
```

All user-facing project text is English and all source files are UTF-8.

## License

MIT
