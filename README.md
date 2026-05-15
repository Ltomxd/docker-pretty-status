# 🐳 docker-pretty-status

> Tired of `docker ps`? This is what it should look like.

![bash](https://img.shields.io/badge/bash-4%2B-green?style=flat-square&logo=gnubash)
![docker](https://img.shields.io/badge/docker-required-blue?style=flat-square&logo=docker)
![license](https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square)
![GitHub stars](https://img.shields.io/github/stars/Ltomxd/docker-pretty-status?style=flat-square)

<!-- Replace with a GIF recording of `dps -i` in action -->
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
- 💻 **CPU & Memory stats** per container in real time
- 🔍 **Filters** — `--running`, `--name`, `--image`
- 🛠️ **Direct subcommands** — `logs`, `stop`, `restart`, `clean`
- 🎨 **Color-coded rows** — green running, dim stopped, red crashed

---

## 📦 Install

```bash
curl -fsSL https://raw.githubusercontent.com/Ltomxd/docker-pretty-status/main/install.sh | bash
```

**Requires:** `bash 4+`, `docker`, `curl`, `tput`

> **WSL / Ubuntu users:** works out of the box.
> **macOS users:** install bash 4+ via `brew install bash` first.

---

## 🚀 Usage

```bash
dps                      # Show table once
dps watch                # Auto-refresh every 2s
dps watch 5              # Auto-refresh every 5s
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

### Filters

```bash
dps --running            # Only running containers
dps --name api           # Filter by name pattern
dps --image nginx        # Filter by image
dps --no-stats           # Skip CPU/MEM (faster)
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

## 🌍 Language

On first run you'll be asked to choose your language. To change it later:

```bash
dps config
```

Config is stored at `~/.config/dps/dps.conf`.

---

## 🤝 Contributing

PRs and issues are welcome! If you find a bug or have a feature idea, open an issue. First-time contributors: look for issues tagged [`good first issue`](https://github.com/Ltomxd/docker-pretty-status/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

---

## 📄 License

MIT © [Ltomxd](https://github.com/Ltomxd/docker-pretty-status)
