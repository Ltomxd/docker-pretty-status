# 🐳 docker-pretty-status

> A beautiful, interactive Docker container status viewer for your terminal.

![bash](https://img.shields.io/badge/bash-4%2B-green?style=flat-square&logo=gnubash)
![docker](https://img.shields.io/badge/docker-required-blue?style=flat-square&logo=docker)
![license](https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square)

```
╔══════════╦══════════════╦═══════════════════╦══════════╦══════════════╦═══════╦═════════╦══════════════╗
║ 🆔 ID    ║ 📛 NAME      ║ 🖼️  IMAGE          ║ ⏱️  AGE   ║ 🔋 STATUS    ║ 💻CPU ║ 🧠 MEM  ║ 📡 PORTS     ║
╠══════════╬══════════════╬═══════════════════╬══════════╬══════════════╬═══════╬═════════╬══════════════╣
║ 8168d2c2 ║ minio        ║ quay.io/minio     ║ 2 hours  ║ 🚀 running   ║ 0.02% ║ 112MiB  ║ 9000-9001    ║
╟──────────╫──────────────╫───────────────────╫──────────╫──────────────╫───────╫─────────╫──────────────╢
║ c6215fd2 ║ mailpit      ║ axllent/mailpit   ║ 2 hours  ║ 🟢 healthy   ║ 0.00% ║ 18MiB   ║ 1025, 8025   ║
╚══════════╩══════════════╩═══════════════════╩══════════╩══════════════╩═══════╩═════════╩══════════════╝
```

## ✨ Features

- 📊 **Beautiful table** with borders that never overflow your terminal
- 🌍 **Bilingual** — choose English or Spanish on first run (saved forever)
- 🚀 **Interactive TUI** — navigate with arrow keys, act with single keypresses
- 🔄 **Live auto-refresh** — `watch` mode updates every N seconds
- 💻 **CPU & Memory stats** per container in real time
- 🔍 **Filters** — `--running`, `--name`, `--image`
- 🛠️ **Direct subcommands** — `logs`, `stop`, `restart`, `clean`
- 🎨 **Color-coded rows** — green running, dim stopped, red crashed

## 📦 Install

```bash
curl -fsSL https://raw.githubusercontent.com/Ltomxd/docker-pretty-status/main/install.sh | bash
```

Requires: `bash 4+`, `docker`, `curl`, `tput`

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

| Key | Action        |
|-----|---------------|
| `↑` `↓` | Navigate |
| `l` | Stream logs   |
| `s` | Stop          |
| `r` | Restart       |
| `d` | Delete (force)|
| `c` | Clean all stopped + orphans |
| `f` | Toggle running-only filter |
| `w` | Manual refresh |
| `q` | Quit          |

---

## 🌍 Language

On first run you'll be asked to choose your language. To change it later:

```bash
dps config
```

Config is stored at `~/.config/dps/dps.conf`.

---

## 📁 Repository Structure

```
docker-pretty-status/
├── dps.sh          # Main script
├── install.sh      # One-line installer
└── README.md
```

---

## 📄 License

MIT © Ltomxd
