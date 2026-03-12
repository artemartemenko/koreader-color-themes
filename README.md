# KOReader color theme patch

A user patch for KOReader that adds extended color theme control for reading:

- separate presets for **UI** and **book content**
- presets for **day** and **night** mode
- a curated set of clean light and dark presets out of the box
- create and edit your own themes directly from the settings menu

Inspired by and partially based on ideas from [`Euphoriyy/KOReader.patches`](https://github.com/Euphoriyy/KOReader.patches/).

**Compatibility**
Tested on Android devices.

## Installation

1. Download `2-color-theme.lua`.
2. Copy it to your KOReader user patches directory, for example:

   ```text
   koreader/patches/2-color-theme.lua
   ```

3. Restart KOReader.
4. Open the settings menu — you will see a new `Themes` entry with extended controls.

## Menus and presets

The patch adds one main entry to the settings menu:

- **Themes**
  - **Day UI** – light/dark presets for the interface in day mode
  - **Day book** – light/dark presets for book pages in day mode
  - **Night UI** – dark/light presets for the interface in night mode
  - **Night book** – dark/light presets for book pages in night mode
  - **Add theme…** – create a custom preset
  - **Restore themes to default** – reset to KOReader defaults  

Each of the four submenus shows the same list of presets, grouped by brightness, for example:

- `Day UI – Light themes`
- `Day UI – Dark themes`
- `Night book – Dark themes`
- `Night book – Light themes`

## Built‑in presets

### Light themes

<p>
  <img src="assets/Default%20day.svg" alt="Default Day" width="130" />
  <img src="assets/Paper.svg" alt="Paper" width="130" />
  <img src="assets/Light%20Gray.svg" alt="Light Gray" width="130" />
  <img src="assets/Warm%20Stone.svg" alt="Warm Stone" width="130" />
</p>
<p>
  <img src="assets/Cream.svg" alt="Cream" width="130" />
  <img src="assets/Parchment.svg" alt="Parchment" width="130" />
  <img src="assets/Soft%20Parchment.svg" alt="Soft Parchment" width="130" />
  <img src="assets/Sepia.svg" alt="Sepia" width="130" />
</p>
<p>
  <img src="assets/Warm%20Sepia.svg" alt="Warm Sepia" width="130" />
  <img src="assets/Green%20Tea.svg" alt="Green Tea" width="130" />
  <img src="assets/Arctic.svg" alt="Arctic" width="130" />
  <img src="assets/Cool%20Mist.svg" alt="Cool Mist" width="130" />
</p>

### Dark themes

<p>
  <img src="assets/Default%20night.svg" alt="Default Night" width="130" />
  <img src="assets/Ink.svg" alt="Ink" width="130" />
  <img src="assets/Mono%20Dark.svg" alt="Mono Dark" width="130" />
  <img src="assets/Twilight.svg" alt="Twilight" width="130" />
</p>
<p>
  <img src="assets/Dim%20Night.svg" alt="Dim Night" width="130" />
  <img src="assets/Slate.svg" alt="Slate" width="130" />
  <img src="assets/Amber%20Night.svg" alt="Amber Night" width="130" />
</p>

## Usage

- Open **Settings → Themes** in KOReader.
- Tap one of:
  - `Day UI`
  - `Day book`
  - `Night UI`
  - `Night book`
- Tap a preset to apply it to that target.
- Long‑press a preset to edit or duplicate it.
- Use **Add theme…** to create a new custom preset.
- Use **Restore themes to default** to return to KOReader’s stock `Default Day` / `Default Night` behavior.

## Support

If this patch is useful to you and you'd like to support further development of KOReader-related projects, you can support me on Ko‑fi:

[![Support me on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/artemartemenko)