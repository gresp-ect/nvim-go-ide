# nvim-go-ide

A reproducible, fast Go development environment for Neovim, designed for
Ubuntu, Debian and WSL on amd64 or arm64.

The project installs pinned versions of Neovim, Go, Go development tools and
LazyVim plugins into the current user's home directory. System administrator
access is used only when an apt package is missing.

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
nvim-go update --version v1.0.0
nvim-go doctor
nvim-go rollback
nvim-go version
```

Updates use stable GitHub Releases, verify the release checksum, stage and
validate the new configuration, and only then switch the active symlink. The
three most recent releases are retained for rollback.

## Go workflow

Open Neovim from a directory containing `go.mod`. Commands save modified
buffers and display output in a bottom task terminal until any key is pressed.

| Command | Action |
| --- | --- |
| `:GoRunPackage` | Run the package containing the current Go file |
| `:GoRunFile` | Run only the current Go file |
| `:GoRun` | Run the module root package |
| `:GoBuild` | Build all packages |
| `:GoTest` | Test all packages |
| `:GoTestVerbose` | Test all packages verbosely |
| `:GoVet` | Vet all packages |
| `:GoLint` | Run golangci-lint |
| `:GoTidy` | Tidy the module |
| `:GoGenerate` | Run Go code generation |
| `:Run command` | Run any shell command in the bottom task terminal |

`F5` runs the current package. The same actions are available below the
`Space r` key group.

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
- Nearest test and test summary: `Space t r` and `Space t s`

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
