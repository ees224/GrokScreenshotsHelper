# Shortcuts.app Integration

## Share sheet

Use a Shortcut in the Share sheet:

1. Open **Shortcuts** → New Shortcut
2. Add **Receive** input: **Images** (and optionally **Files**)
3. Add **Run Shell Script** (pass input as arguments):
   ```bash
   for f in "$@"; do
     "$HOME/.grok/skills/skeenshot/scripts/quick_save.sh" "$f"
   done
   ```
4. Name it **Send to Grok (SkeenShot)**
5. Shortcut details (ⓘ) → enable **Use as Quick Action** → **Share menu**

Screenshot preview → Share → your Shortcut appears.

## Raycast Script Command

```bash
#!/bin/bash
open -a SkeenShot
```

## Obsidian

Symlink into your vault:

```bash
ln -s ~/GrokScreenshots ~/Obsidian/MyVault/SkeenShot
```

## OmniFocus

Paste a saved screenshot path into an OmniFocus note.
