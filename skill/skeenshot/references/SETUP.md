# SkeenShot Setup

## Quick install

```bash
cd ~/GrokScreenshotsHelper
./install.sh
```

## Manual steps

1. **Build the macOS app** (requires Xcode):
   ```bash
   cd ~/GrokScreenshotsHelper/SkeenShot
   xcodebuild -scheme SkeenShot -configuration Release -derivedDataPath build build
   ```

2. **Install skill**:
   ```bash
   ~/GrokScreenshotsHelper/skill/skeenshot/scripts/install_skill.sh
   ```

3. **Configure folder**:
   ```bash
   cp ~/GrokScreenshotsHelper/config/skeenshot.toml.example ~/GrokScreenshots/config.toml
   ```

4. **Enable Share Extension**:
   System Settings → Privacy & Security → Extensions → Sharing → enable **Send to Grok (SkeenShot)**

5. **Optional SessionStart hook**:
   ```bash
   cp ~/GrokScreenshotsHelper/hooks/skeenshot-context.json ~/.grok/hooks/
   ```

## Usage

- **Fastest**: Screenshot → Share → Send to Grok (SkeenShot)
- **Canvas**: `/skeenshot` → paste/drop in menubar app → Submit
- **Analyze**: `/skeenshot analyze` or `/skeenshot analyze skeenshot_*.png`