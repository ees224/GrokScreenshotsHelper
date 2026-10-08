---
name: skeenshot
description: >
  Screenshot sharing for Grok Build on macOS. Use for /skeenshot, skeenshot,
  screenshot to Grok, analyze screenshot, ~/GrokScreenshots watcher, Send to Grok.
argument-hint: "[analyze <filename>]"
metadata:
  short-description: "Capture, tag, and analyze screenshots"
---

# /skeenshot — Screenshot Sharing for Grok Build

Local-only screenshot pipeline: macOS capture → tagged files in `~/GrokScreenshots/` → vision analysis in Grok.

Scripts live at `~/.grok/skills/skeenshot/scripts/` (symlink to `~/GrokScreenshotsHelper/skill/skeenshot`).

## Commands

| Invocation | Action |
|------------|--------|
| `/skeenshot` | Refresh session context, launch helper app, start watcher, drain inbox |
| `/skeenshot analyze [file]` | Vision-analyze a specific PNG (or latest pending) |
| User mentions new skeenshot | Read image + sidecar JSON, respond with analysis |

## /skeenshot (default)

Run these steps in order:

1. **Write session context**
   ```bash
   ~/.grok/skills/skeenshot/scripts/write_context.sh
   ```

2. **Launch helper app** (menubar canvas; optional if using Share Extension only)
   ```bash
   ~/.grok/skills/skeenshot/scripts/launch_app.sh
   ```

3. **Start folder watcher** as a background shell task (`block_until_ms: 0`):
   ```bash
   ~/.grok/skills/skeenshot/scripts/watcher.sh --daemon
   ```

4. **Drain inbox** — read `~/GrokScreenshots/inbox.jsonl` for entries with `"status": "pending"`. For each, run the analyze flow below.

5. Tell the user:
   - Screenshots folder: `~/GrokScreenshots/`
   - Share sheet: **Send to Grok (SkeenShot)**
   - Watcher is running; new files trigger macOS notifications

## /skeenshot analyze [filename]

1. Resolve image path:
   - If filename given: `~/GrokScreenshots/<filename>` (or absolute path)
   - Else: latest pending entry from `inbox.jsonl`

2. **Read** the PNG with the Read tool (vision).

3. Read sidecar `*.json` if present for `note`, `session_id`, `cwd`, `source`.

4. Provide a concise analysis:
   - What is shown
   - Extracted text / UI elements
   - Suggested next actions for the current Grok session

5. Mark processed: append path to `~/GrokScreenshots/processed/handled.txt`.

6. Offer to reference the image in future edits as `[Image: <absolute-path>]`.

## Auto-mode (watcher running)

When the watcher prints `NEW:/path/to/file.png` or the user returns after a notification:

1. Immediately **Read** the image and analyze (do not wait for another command).
2. If `~/GrokScreenshots/config.toml` has `analyze_mode = "headless"` or `"both"`, also check for `{basename}.analysis.md` sidecar and incorporate it.

## Configuration

- Screenshots belong in `~/GrokScreenshots/` root (Share/canvas save here automatically). Manual drops in `inbox/` are also watched.
- `inbox.jsonl` is the **queue log file** at the folder root — not the `inbox/` subdirectory.
- Folder config: `~/GrokScreenshots/config.toml` (copy from `~/GrokScreenshotsHelper/config/skeenshot.toml.example`)
- `analyze_mode`: `queue` (default), `headless`, or `both`
- Context file: `~/GrokScreenshots/.context.json`

## Privacy

- All files stay local in `~/GrokScreenshots/`
- Headless mode uses local `grok -p` only (user's existing auth)
- No cloud upload by this skill

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Share option missing | Extension needs Xcode Automatic Signing (embedded.provisionprofile). Run `./install.sh`, or `SkeenShot/scripts/sign_app.sh` and `SkeenShot/scripts/register_extension.sh`. **Workaround:** Shortcuts Share action — see `shortcuts/README.md` |
| Wrong session tag | Run `/skeenshot` or ensure SessionStart hook is installed |
| Watcher not detecting | `~/.grok/skills/skeenshot/scripts/watcher.sh --once` |
| Stop watcher | `~/.grok/skills/skeenshot/scripts/watcher.sh --stop` |

See `~/GrokScreenshotsHelper/README.md` for full installation.
