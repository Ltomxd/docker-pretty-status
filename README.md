# 🐳 docker-pretty-status

> Tired of `docker ps`? This is what it should look like.

![bash](https://img.shields.io/badge/bash-4%2B-green?style=flat-square&logo=gnubash)
![docker](https://img.shields.io/badge/docker-required-blue?style=flat-square&logo=docker)
![license](https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square)
![GitHub stars](https://img.shields.io/github/stars/Ltomxd/docker-pretty-status?style=flat-square)
![CI](https://img.shields.io/github/actions/workflow/status/Ltomxd/docker-pretty-status/ci.yml?style=flat-square&label=CI)
[![npm](https://img.shields.io/npm/v/docker-pretty-status?style=flat-square&color=cb3837&logo=npm)](https://www.npmjs.com/package/docker-pretty-status)

<!--
  To regenerate this as a real GIF: install https://github.com/charmbracelet/vhs
  and run `vhs demo.tape`, then replace this <img> with the generated demo.gif
  (upload it via a GitHub issue/PR comment to get a user-attachments URL, or
  commit it to the repo and reference it with a relative path).
-->
<img width="1430" height="636" alt="dps screenshot" src="https://github.com/user-attachments/assets/9e15193e-44e7-4e68-9e2b-95bd5871b006" />

---

## 🤔 Why?

`docker ps` is fine — until you have 12 containers running and it spits out a wall of truncated text. `dps` gives you a live, navigable, color-coded table with CPU & memory stats, and lets you stop, restart, or inspect containers without memorizing IDs or typing long commands.

---

## ✨ Features

- 📊 **Beautiful table** with borders that never overflow your terminal
- 🌍 **Bilingual** — choose English or Spanish on first run (saved forever)
- 🚀 **Interactive TUI** — navigate with arrow keys, act with single keypresses
- 🔄 **Live auto-refresh** — `watch` mode updates every N seconds
- 🏆 **`top` mode** — live view sorted by CPU usage
- 📦 **Docker Compose grouping** — `--group` clusters containers by compose project
- 💻 **CPU & Memory stats** per container in real time, with configurable red-alert threshold
- 🤖 **JSON output** (`--json`) — pipe into `jq`, dashboards, or other scripts
- 🔍 **Filters** — `--running`, `--name`, `--image`
- 🛠️ **Direct subcommands** — `logs`, `stop`, `restart`, `clean`
- 🎨 **Color-coded rows** — green running, dim stopped, red crashed
- ♿ **`--no-color`** / respects `NO_COLOR` — clean output for scripts & CI logs

---

## 📦 Install

**Script (recommended, no dependencies beyond bash + docker):**

```bash
curl -fsSL https://raw.githubusercontent.com/Ltomxd/docker-pretty-status/main/install.sh | bash
```

**Requires:** `bash 4+`, `docker`, `curl`, `tput`

> **WSL / Ubuntu users:** works out of the box.
> **macOS users:** install bash 4+ via `brew install bash` first.

**Homebrew:**

```bash
brew tap Ltomxd/dps
brew install dps
```

**pnpm** (requires Node.js, runs the same bash script under the hood):

```bash
pnpm add -g docker-pretty-status
```

---

## 🚀 Usage

```bash
dps                      # Show table once
dps watch                # Auto-refresh every 2s
dps watch 5              # Auto-refresh every 5s
dps top                  # Live view sorted by CPU usage
dps -i                   # Interactive TUI mode
```

### Subcommands

```bash
dps logs <name>          # Stream logs
dps stop <name>          # Stop container
dps restart <name>       # Restart container
dps clean                # Remove stopped containers + orphan images
dps config               # Change language
```

### Filters & output

```bash
dps --running            # Only running containers
dps --name api           # Filter by name pattern
dps --image nginx        # Filter by image
dps --no-stats           # Skip CPU/MEM (faster)
dps --group              # Group by docker-compose project
dps --cpu-alert 50       # Highlight containers over 50% CPU in red
dps --json               # Machine-readable JSON, e.g. `dps --json | jq '.[].name'`
dps --no-color           # Disable ANSI colors (also honors NO_COLOR env var)
```

---

## ⌨️ Interactive Mode Keys

| Key | Action |
|-----|--------|
| `↑` `↓` | Navigate |
| `l` | Stream logs |
| `s` | Stop |
| `r` | Restart |
| `d` | Delete (force) |
| `c` | Clean all stopped + orphans |
| `f` | Toggle running-only filter |
| `w` | Manual refresh |
| `q` | Quit |

---

## ⚖️ vs. other tools

| | `dps` | `docker ps` | lazydocker | ctop |
|---|---|---|---|---|
| Zero deps beyond bash+docker | ✅ | ✅ | ❌ (Go binary) | ❌ (Go binary) |
| Colorized, self-sizing table | ✅ | ❌ | ✅ | ✅ |
| Interactive TUI | ✅ | ❌ | ✅ | ✅ |
| Bilingual (EN/ES) | ✅ | ❌ | ❌ | ❌ |
| Compose project grouping | ✅ | ❌ | ✅ | ❌ |
| JSON output | ✅ | ✅ | ❌ | ❌ |
| Single readable bash file | ✅ | — | ❌ | ❌ |

`dps` isn't trying to replace full TUI managers like lazydocker — it's the tool you reach for when you just want a fast, pretty `docker ps` without installing a Go binary.

---

## 🌍 Language

On first run you'll be asked to choose your language. To change it later:

```bash
dps config
```

Config is stored at `~/.config/dps/dps.conf`.

---

## 🤝 Contributing

PRs and issues are welcome! If you find a bug or have a feature idea, open an issue. First-time contributors: look for issues tagged [`good first issue`](https://github.com/Ltomxd/docker-pretty-status/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

<details>
<summary>Maintainer: publishing a new release</summary>

1. Bump `VERSION` in `dps.sh` and `pnpm-package/package.json`, commit, tag (`git tag v1.2.0 && git push --tags`), then create a GitHub Release from that tag.
2. **Homebrew:** compute the release tarball's sha256 (`shasum -a 256 <(curl -fsSL .../v1.2.0.tar.gz)`), update it in `Formula/dps.rb`, then copy that file into a separate `Ltomxd/homebrew-dps` repo (Homebrew taps must live in a repo named `homebrew-<tap>`) so `brew tap Ltomxd/dps` works.
3. **pnpm:** from `pnpm-package/`, run `pnpm publish --access public` (requires being logged in with `pnpm login`).
4. Regenerate the demo GIF with [VHS](https://github.com/charmbracelet/vhs): `vhs demo.tape`, then update the README image.

</details>

---

## 📄 License

MIT © [Ltomxd](https://github.com/Ltomxd/docker-pretty-status)
