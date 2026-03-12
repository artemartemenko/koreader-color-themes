# KOReader color theme patch

A user patch for KOReader that adds extended color theme control for reading:

- separate presets for day and night mode
- a curated set of clean light and dark presets out of the box
- create and edit your own themes directly from the settings menu
- manually mark any theme as light or dark (used for separate day/night selection)
- protection against unreadable themes (background and text cannot be the same color)

Inspired by and partially based on ideas from [`Euphoriyy/KOReader.patches`](https://github.com/Euphoriyy/KOReader.patches/).

## Installation

1. Download `2-color-theme.lua`.
2. Copy it to your KOReader user patches directory, for example:

   ```text
   koreader/patches/2-color-theme.lua
   ```

3. Restart KOReader.
4. Open the settings menu — you will see a new `Theme` entry where you can choose and edit themes.

## Themes

### Light themes

<div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#FFFFFF;color:#000000;border:1px solid #ccc;">
    Default day
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#F2F2F2;color:#1A1A1A;border:1px solid #ccc;">
    Paper
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#ECECEC;color:#1A1A1A;border:1px solid #ccc;">
    Soft gray
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#F3EFD8;color:#111111;border:1px solid #ccc;">
    Cream
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#F7E9D0;color:#2A1F14;border:1px solid #ccc;">
    Soft sand
  </div>
    <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#F5E6C8;color:#2C1A0E;border:1px solid #ccc;">
    Sepia
  </div>
    <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#EBE0C8;color:#2C1A0E;border:1px solid #ccc;">
    Parchment
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#EBE0C9;color:#645031;border:1px solid #ccc;">
    Parchment soft
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#E3D1B3;color:#422A14;border:1px solid #ccc;">
    Warm Sepia
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#D4E8D0;color:#1A3320;border:1px solid #ccc;">
    Green Tea
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#E8F0F8;color:#0D1B2A;border:1px solid #ccc;">
    Arctic Blue
  </div>
</div>

### Dark themes

<div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#000000;color:#FFFFFF;border:1px solid #ccc;">
    Default night
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#050505;color:#E0E0E0;border:1px solid #ccc;">
    Ink
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#1A1A1A;color:#F5F5F5;border:1px solid #ccc;">
    Mono Dark
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#282A2C;color:#FFFFFF;border:1px solid #ccc;">
    Twilight
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#121212;color:#B0B0B0;border:1px solid #ccc;">
    Soft night
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#2C3E50;color:#DCDCDC;border:1px solid #ccc;">
    Slate
  </div>
  <div style="display:inline-block;width:130px;text-align:center;padding:6px;margin:4px;border-radius:8px;background:#14100A;color:#FAD08A;border:1px solid #ccc;">
    Amber Night
  </div>
</div>

## Usage

- Open **Settings → Theme** in KOReader.
- Tap to select a theme
- Long‑press a theme to edit or duplicate it