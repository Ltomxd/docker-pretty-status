# 🐳 docker-pretty-status

> A beautiful, interactive Docker container status viewer for your terminal.

![bash](https://img.shields.io/badge/bash-4%2B-green?style=flat-square&logo=gnubash)
![docker](https://img.shields.io/badge/docker-required-blue?style=flat-square&logo=docker)
![license](https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square)


<img width="1445" height="196" alt="{9040994B-0302-48D7-B4C6-82996EE2B931}" src="https://github.com/user-attachments/assets/cb50b006-dcbc-47bf-81d9-466079b6a7fa" />




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
