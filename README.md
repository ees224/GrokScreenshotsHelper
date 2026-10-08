# SkeenShot

Low-friction screenshot sharing for **Grok Build TUI** on macOS.

**Repository:** https://github.com/ees224/GrokScreenshotsHelper

Capture natively, tag with session context, save locally, and analyze with vision — no cloud upload.

## Features

- **Share Extension** — "Send to Grok (SkeenShot)" in macOS screenshot preview Share sheet
- **Menubar canvas app** — paste, drag-drop, optional note, submit
- **Grok skill `/skeenshot`** — context tagging, folder watcher, vision analysis
- **Local-only** — `~/GrokScreenshots/` with PNG + JSON sidecar metadata
- **Configurable analyze modes** — `queue` (default), `headless`, or `both`

## Quick start

```bash
cd ~/GrokScreenshotsHelper
chmod +x install.sh
./install.sh
```

Then in Grok TUI:

```
/skeenshot
```

### Workflows

| Path | Steps |
|------|-------|
| **Screenshot Share** | Cmd+Shift+4/5 → thumbnail → Share → **Send to Grok (SkeenShot)** |
| **Canvas** | `/skeenshot` → menubar app → paste/drop → Submit |
| **Analyze** | `/skeenshot analyze` or `/skeenshot analyze skeenshot_*.png` |

## Project layout

```
GrokScreenshotsHelper/
├── install.sh
├── SkeenShot/              # Xcode app + Share Extension
├── skill/skeenshot/        # Grok skill (symlinked to ~/.grok/skills/)
├── hooks/                  # Optional SessionStart hook
├── config/                 # Example TOML config
└── shortcuts/              # Shortcuts.app recipes
```

## Configuration

Edit `~/GrokScreenshots/config.toml`. Start from [`config/skeenshot.toml.example`](config/skeenshot.toml.example).

## File naming

```
skeenshot_{sessionShort}_{yyyyMMdd_HHmmss}.png
skeenshot_{sessionShort}_{yyyyMMdd_HHmmss}.json
```

`sessionShort` = first 8 chars of Grok session ID, or hash of project `cwd`.

## Session tagging

- **SessionStart hook** (installed by `install.sh`) writes `~/GrokScreenshots/.context.json`
- **`/skeenshot`** refreshes context before saves
- App/Share Extension read context when saving

## Analyze modes

| Mode | Behavior |
|------|----------|
| `queue` | macOS notification + `inbox.jsonl`; analyze on `/skeenshot` |
| `headless` | Watcher runs `grok -p` locally, writes `.analysis.md` sidecar |
| `both` | Queue notify always + headless when enabled |

## Build manually

```bash
cd ~/GrokScreenshotsHelper/SkeenShot
xcodebuild -scheme SkeenShot -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

Open in Xcode: `open SkeenShot.xcodeproj`

## Permissions

- **Notifications** — requested on first launch (optional)
- **Share Extension** — enable in System Settings → Privacy & Security → Extensions → Sharing
- No Accessibility or Full Disk Access required

## Integrations

See [shortcuts/README.md](shortcuts/README.md) for Share sheet, Raycast, Obsidian, and OmniFocus tips.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Share option missing | Run `./install.sh`; enable extension in System Settings |
| Build fails signing | Use `CODE_SIGNING_ALLOWED=NO` flags in install.sh |
| Watcher not running | `~/.grok/skills/skeenshot/scripts/watcher.sh --daemon` |
| Stop watcher | `~/.grok/skills/skeenshot/scripts/watcher.sh --stop` |
| Archive old shots | `~/.grok/skills/skeenshot/scripts/cleanup.sh --days 30` |

## Privacy

All screenshots and metadata stay on disk under `~/GrokScreenshots/`. Headless analyze uses your local `grok` CLI and existing authentication only.