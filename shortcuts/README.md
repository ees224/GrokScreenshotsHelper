# Shortcuts.app Integration

## Share sheet workaround (until Xcode signing is complete)

The native Share Extension requires an Xcode provisioning profile. Until that's set up, use a **Shortcut in the Share sheet**:

1. Open **Shortcuts** → New Shortcut
2. Add **Receive** input: **Images** (and optionally **Files**)
3. Add **Run Shell Script** (pass input as arguments):
   ```bash
   for f in "$@"; do
     /Users/edmundskeen/GrokScreenshotsHelper/skill/skeenshot/scripts/quick_save.sh "$f"
   done
   ```
4. Name it **Send to Grok (SkeenShot)**
5. Shortcut details (ⓘ) → enable **Use as Quick Action** → **Share menu**

Now screenshot preview → Share → your Shortcut appears.

## Folder Action shortcut (optional)

Create a shortcut named **SkeenShot Folder Watcher**:

1. Open **Shortcuts** → New Shortcut
2. Add trigger: **Folder** → `~/GrokScreenshots` → **File is Added**
3. Add actions:
   - **Get Folder Contents** (filter: Name contains `skeenshot_`, Extension is `png`)
   - **Get Details of Files** → Name
   - **Show Notification** — Title: `SkeenShot`, Body: `New screenshot: [Name]`
4. Optional — **Run Shell Script**:
   ```bash
   /Users/edmundskeen/.grok/skills/skeenshot/scripts/watcher.sh --once
   ```

## Raycast Script Command

```bash
#!/bin/bash
open -a SkeenShot
```

Or analyze latest:

```bash
#!/bin/bash
latest=$(ls -t ~/GrokScreenshots/skeenshot_*.png 2>/dev/null | head -1)
~/.grok/skills/skeenshot/scripts/analyze.sh "$latest"
```

## Obsidian

Symlink into your vault:

```bash
ln -s ~/GrokScreenshots ~/Obsidian/MyVault/SkeenShot
```

## OmniFocus

Use **Copy Last Path** from the SkeenShot menubar, then paste into an OmniFocus note.

## Paperless-ngx

Point a consume folder at `~/GrokScreenshots/processed/` for archival OCR (optional).