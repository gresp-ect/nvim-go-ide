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
nvim-go update --version v1.1.0
nvim-go doctor
nvim-go rollback
nvim-go version
```

Updates use stable GitHub Releases, verify the release checksum, stage and
validate the new configuration, and only then switch the active symlink. The
three most recent releases are retained for rollback.

## Go workflow

Open Neovim from a directory containing `go.mod`. Run and build commands save
modified buffers and display output in a bottom task terminal. Run, build and
test tasks report a clear success or failure notification with elapsed time.
Focused test commands run asynchronously and report results in-place.

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
| `:GoDebugFile` | Debug the current Go file with project settings |
| `:GoDebugPackage` | Debug the current Go package with project settings |
| `:GoDebugTest` | Debug the test function under the cursor with project settings |
| `:GoSaveCheckOutput` | Show output from the latest save-time test or vet run |
| `:GoVet` | Vet all packages |
| `:GoLint` | Run golangci-lint |
| `:GoTidy` | Tidy the module |
| `:GoGenerate` | Run Go code generation |
| `:GoAddJSONTags` | Add snake_case JSON tags to the struct under the cursor |
| `:GoRemoveJSONTags` | Remove JSON tags from the struct under the cursor |
| `:GoImpl [receiver] [interface]` | Generate interface method stubs and append them to the current file |
| `:Run command` | Run any shell command in the bottom task terminal |
| `:TaskRerun` | Run the most recent task again in its original context |

`F5` runs the current package. The same actions are available below the
`Space r` key group. Use `Space r .` to run the most recent task again.

For Go-specific code generation, place the cursor anywhere in a struct and use
`Space r j` to add snake_case JSON tags to its exported fields, or `Space r J`
to remove its JSON tags. Use `Space r m` to enter a receiver (for example,
`s *Server`) and an interface (for example, `io.Reader`); the generated method
stubs are appended to the current file. The equivalent command can also take
arguments directly, as in `:GoImpl s *Server io.Reader`.

`Space t n` runs the test function under the cursor and `Space t p` tests its
package. A failed run jumps directly to the first source location reported by
Go and also fills the quickfix list for subsequent failures. Each run reports
the statement coverage percentage and highlights uncovered lines. Use
`Space t o` to inspect the complete output and `Space t c` to clear coverage.

## Project debugging

The debugger includes templates for the current file, the package containing
the current file, and the test function under the cursor. Start them with
`:GoDebugFile`, `:GoDebugPackage`, and `:GoDebugTest`, or use `Space d d f`,
`Space d d p`, and `Space d d t`. They are also available in the standard DAP
configuration picker.

Add `.nvim-go-debug.json` next to the project's `go.mod` to supply environment
variables and startup arguments. This is useful for Web and API services that
need a port, development mode, or a configuration path:

```json
{
  "env": {
    "APP_ENV": "development",
    "HTTP_PORT": "8080"
  },
  "args": ["serve", "--config", "config/dev.yaml"],
  "current_package": {
    "args": ["--log-level", "debug"],
    "env": {
      "COMPONENT": "api"
    }
  },
  "current_test": {
    "args": ["-test.v"]
  }
}
```

Top-level `env` and `args` apply to all three templates. Optional
`current_file`, `current_package`, and `current_test` objects add arguments and
override environment variables for one template. Environment keys and values,
and every argument, must be strings. The debugger reloads the file before each
session and runs from the module root. Do not commit secrets in this file.

## Terminal sessions

`:terminal`, `:term` and `Ctrl-/` toggle one persistent shell session in a
bottom split. Its directory and history remain available while Neovim is open.

Task commands such as `:Run` and `:GoRunPackage` use a separate bottom terminal
so running a program never replaces the persistent shell session.

## Git workflow

Git changes are marked in the sign column, including changes in untracked
files. The current line also shows a short blame annotation after a brief
delay. LazyVim's built-in GitSigns actions provide the rest of the workflow:

| Key | Action |
| --- | --- |
| `]h` / `[h` | Jump to the next / previous changed hunk |
| `Space g h p` | Preview the current hunk inline |
| `Space g h b` | Show full blame details for the current line |
| `Space g h d` | Diff the current file against the index |
| `Space g h D` | Diff the current file against the previous commit |

Use `Space u G` to toggle sign-column markers and
`:Gitsigns toggle_current_line_blame` to toggle inline blame annotations.

## Language features

- Completion and signature help: Insert mode or `Ctrl-Space`
- Hover documentation: `K`
- Definition and references: `gd` and `gr`
- Rename and code actions: `Space c r` and `Space c a`
- Organize imports and format: `Space c o` and `Space c f`
- Breakpoint and debugger: `Space d b` and `Space d c`
- Project debug templates: `Space d d f`, `Space d d p` and `Space d d t`
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
