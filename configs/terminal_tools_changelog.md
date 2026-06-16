# Dotfiles Features

## .bashrc

- **Menu completion** — Tab completes to the longest common prefix, then cycles through candidates; Shift+Tab cycles backward (`menu-complete`, `menu-complete-display-prefix`)
- **Completion settings** — case-insensitive matching, colored file-type icons (`colored-stats`), candidates shown immediately on ambiguity
- **History** — 50 000 commands in memory, 100 000 in file; `ignoreboth:erasedups` skips duplicates and lines starting with space; `histappend` never overwrites the history file
- **Collapsed path in prompt** — `_collapsed_pwd` via Perl: intermediate directories are shortened to their first letter (`~/p/my/project`)
- **Ctrl+W by delimiters** — `_kill_back_to_delim` deletes backward to the nearest `/`, `_`, `.`, `,`, or space instead of only whitespace (stock `werase` is disabled)
- **Colored prompt** — username and path highlighted in green
- **History search with arrows** — Up/Down search history by the prefix already typed on the command line

---

## .vimrc

> No plugins. Requires Vim 8.2.1381+ (matchfuzzy + popup).

### Navigation & UI
- **Line numbers**, current-line highlight, always-visible statusbar
- **Buffer tabline instead of tabs** — custom `tabline` lists all open buffers; active buffer is highlighted, modified ones marked with `+`
- **Tab / Shift+Tab** — switch between buffers
- **`<Leader>x`** — close current buffer without closing the window
- **Ctrl+N** — toggle netrw sidebar (tree view, 25% width, files open in the main window)

### File operations in netrw
- **`a`** — create a new file from within netrw (prompts for path, opens the file immediately)
- **`d`** — delete file or directory
- **`<Leader>d`** — duplicate current file with a new name of your choice
- **`<Leader>o`** (visual) — open visually selected text as a file path

### Search
- **`<Leader>fa`** — async fuzzy file-name search (`find` + `matchfuzzy` + `job_start`), popup opens instantly while indexing streams in the background
- **`<Leader>fw`** — async fuzzy grep through file contents (`grep -rn` + `job_start`), same streaming behavior
- **`<Leader>fb`** — fuzzy buffer picker (sync, searches by name and path)
- In the popup: typing filters results in real time; Ctrl+J/K or arrow keys to navigate; `...` in title while indexing
- **Incremental search** with highlighting, case-insensitive / smart-case
- **Ctrl+L** — clear search highlight

### Editing
- **`<Leader>/`** — toggle comment on current line or selection (normal and visual mode); comment character is detected automatically by filetype:

  | Filetype | Character |
  |---|---|
  | python, sh, bash, yaml, ruby | `#` |
  | vim | `"` |
  | lua | `--` |
  | js, ts, c, cpp, java, go, rust | `//` |
  | everything else | `#` |

- **Autocomplete popup** — triggers automatically after 3+ characters (`<C-n>`); Tab / Shift+Tab / Enter control the popup
- **Persistent undo** — undo history survives across sessions, stored in `~/.vim/undodir` (`set undofile`). The directory is created automatically on first launch if it does not exist.
- **Centralized swap files** — stored in `~/.vim/swapdir//` (auto-created); `//` encodes full path to avoid collisions between files with the same name
- **Fast Esc** — `ttimeoutlen=25` for near-instant mode switching
- **wildignore** — `.git`, `node_modules`, `__pycache__`, `.mypy_cache`, `.venv`, compiled objects excluded from all file listings
- **No auto-comment continuation** — `formatoptions-=o -=r +=j`
- **Indentation** — 4 spaces, `expandtab`

### Clipboard
- **Ctrl+Y** — copy to system clipboard: native (`+clipboard`) locally, **OSC 52** over SSH (with tmux/screen escape wrapping)
- **Ctrl+P** — copy the absolute path of the current file

### Running files
- **`:RunThis`** / **`:runthis`** — save the file, make it executable (`chmod u+x`), and run `./file` from its directory
- If the file has no shebang, one is added automatically based on filetype using `which`: `python3` for Python, `bash`/`sh` for shell, `node` for JS, `lua`, `ruby`, `perl`
- Filetypes with no interpreter (html, css, json, etc.) print `Not runnable file` instead of running

---

## .tmux.conf

- **1-based indexing** — windows and panes start at 1; windows are renumbered automatically on close
- **True color** — `terminal-overrides` for proper 24-bit color support in xterm
- **Splits inherit cwd** — `"` and `%` open a new pane in the current pane's directory; `c` opens a new window in the session directory
- **Auto-session naming** — on creation, the session is automatically renamed to the basename of its starting directory (only when no explicit `-s` name was given)
- **Theme** — monochrome gray palette with a muted brown accent (`#af875f`) on the active window index; dark statusbar (`#1c1c1c`), neutral pane borders; session name truncated at 25 chars

---

## Changelog

### 2026-06-15
- **open-webui**: Installed via Docker (`ghcr.io/open-webui/open-webui:main`), container `open-webui`, host port **3000**, volume `open-webui:/app/backend/data`, `CORS_ALLOW_ORIGIN=https://chat.chameleon-lizard.ru`
- **dns**: Added A-record `chat.chameleon-lizard.ru` → `82.202.136.87` on reg.ru
- **nginx**: New server block for `chat.chameleon-lizard.ru` proxying to `127.0.0.1:3000` (HTTPS via Let's Encrypt, WebSocket, SSE streaming with buffering off, 100MB upload limit). Old `/chat` location removed; `chameleon-lizard.ru/chat` now 301-redirects to `https://chat.chameleon-lizard.ru/`

### 2026-06-01
- **java**: Installed `openjdk-25-jre-headless` and switched default Java from 21 to 25 via `update-java-alternatives` — required for Minecraft server 26.1 (`java_version: 25`)
- **minecraft**: Upgraded server from 1.21.4 to 26.1; old jar kept as `server_1.21.4.jar`; world upgraded successfully, libraries unpacked
- **systemd**: Created `/etc/systemd/system/minecraft.service` — auto-starts server as `chameleon`, restarts on failure after 10s, logs to journalctl

### 2026-03-15
- **bashrc**: arrow Up/Down now do `history-search-backward`/`history-search-forward` — searches history by typed prefix instead of just cycling
- **vimrc**: added `set autoindent` — new lines preserve indentation from the previous line
- **tmux.conf**: auto-session rename now only triggers when the session name is a default number (`0`, `1`, ...); explicit `-s name` is no longer overwritten

### 2026-03-14
- **bashrc**: extracted all custom additions (completion bindings, prompt, Ctrl+W handler) into `~/.bashrc.d/custom.sh`; `.bashrc` now sources all `*.sh` files from `~/.bashrc.d/` via a loop — drop the file on any server, add the loader snippet, done
- **bashrc**: increased `HISTSIZE` to 50 000 and `HISTFILESIZE` to 100 000; added `erasedups` to `HISTCONTROL`
- **vimrc**: custom statusline — mode indicator (NORMAL/INSERT/VISUAL/REPLACE) in a colored block, filename in a dark gray section, `l%d : c%d` position on the right; `set noshowmode` hides the default mode text below the statusbar
- **vimrc**: tabline no longer shows empty unnamed buffers; leftover `[No Name]` buffers are auto-wiped on file open (`BufReadPost`)
- **vimrc**: netrw window gets a minimal local statusline (`netrw`) instead of the full mode/file/position bar
- **vimrc**: fuzzy finder (`<Leader>fa`, `<Leader>fw`) is now async — popup opens instantly, `find`/`grep` run in background via `job_start()`, results stream in every 100ms; title shows `...` while indexing
- **vimrc**: added `<Leader>fb` — fuzzy buffer picker (sync, reuses existing popup infrastructure)
- **vimrc**: swap files moved to `~/.vim/swapdir//` (auto-created, `//` encodes full path to avoid collisions)
- **vimrc**: `set ttimeoutlen=25` — near-instant Esc in insert mode without affecting mapping timeouts
- **vimrc**: `wildignore` excludes `.git`, `node_modules`, `__pycache__`, `.mypy_cache`, `.venv`, compiled objects, swap files
- **vimrc**: `formatoptions-=o -=r +=j` via autocmd — disables auto-comment continuation on `o`/`O`/Enter, enables comment leader removal on `J`
- **tmux.conf**: switched to a monochrome gray palette — neutral borders (`#767676`/`#3a3a3a`), dark statusbar (`#1c1c1c`), muted brown accent (`#af875f`) only for the active window index
- **tmux.conf**: session name is hard-truncated to 18 chars via `#{=18:session_name}` (plus `status-left-length 25`) so it doesn't overflow into window list
- **vimrc**: `:RunThis` now auto-inserts a shebang via `which` when missing; prints `Not runnable file` for html/css/json/etc.
- **vimrc**: added persistent undo via `set undofile` + `~/.vim/undodir` (auto-created)
- **vimrc**: replaced hardcoded `#` comment character with a filetype map covering Python, Shell, YAML, Ruby, Vim, Lua, JavaScript, TypeScript, C, C++, Java, Go, Rust
