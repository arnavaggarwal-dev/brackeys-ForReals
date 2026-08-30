# itchpush

Everything the itch.io page needs, kept in the repo so the store listing is versioned
like the rest of the game.

```
itchpush/
  screenshots/       five 1664x936 PNGs, regenerate with `godot --shots`
  itch-theme.css     the Win95 page theme - needs CSS access, see below
  PAGE.md            the page description, ready to paste
  README.md          this file
```

## Theming the page

There are two levels, and **the first one needs no permission and gets you most of
the look.**

### 1. The built-in theme editor - works right now

On the game's edit page, open the theme editor and set:

| Field | Value |
| --- | --- |
| Background | `#008080` — the teal desktop |
| Text | `#000000` |
| Link | `#000080` — navy |
| Button background | `#c0c0c0` |
| Button text | `#000000` |

Teal wallpaper, black text, navy links, grey buttons. That is the Windows 95 palette
without writing a line of CSS.

### 2. Custom CSS - has to be requested first

**itch.io does not enable custom CSS by default.** It is granted per account, and
[their guide](https://itch.io/docs/creators/css-guide) states plainly that they *"do
not grant CSS access to empty accounts"* — so publish the game first, then ask.

Contact itch.io support and say what you want to change and why the built-in theme
editor cannot do it. Something like:

> I've published ForReals, a jam game whose whole interface is a Windows 95 desktop.
> I'd like CSS access to give the project page the same bevelled-panel look — the
> theme editor covers the colours but not the one-pixel 3D borders, the title-bar
> headings, or turning off the rounded corners and font smoothing. All my rules are
> scoped inside `#wrapper`, I'm not touching the buy/download flow or the footer, and
> I'll check it logged out and on mobile.

Once granted, click **Edit Theme** and a CSS box appears at the bottom of the editor
sidebar; the small arrow expands it. Paste `itch-theme.css` in.

**Do not unscope the rules.** Every selector in that file sits inside `#wrapper`
because itch requires it, and pages that break itch's own chrome get CSS access — and
possibly the account — suspended. Same reason nothing in there hides a footer link or
moves a download button.

## Screenshots

| File | What it shows |
| --- | --- |
| `01-desktop.png` | the three-window desktop mid-run: your posts travelling, the feed, trends and the day clock |
| `02-composer.png` | building the day's sentence — twelve cards, the verdict, the projected reach and payout |
| `03-store.png` | the Speech Fragment Store, and the seven fragments that each break a rule |
| `04-heat.png` | late run: assets running, heat above cooling, one strike spent, the display coming apart |
| `05-ending.png` | 5,000 followers, the title, and the log of everything you said to get there |

Regenerate them all with:

```
godot --path . --shots
```

That drives the game to each state and writes the PNGs here. It opens a window - it
cannot run headless, because there is nothing to capture without a renderer.

**Upload `01-desktop.png` first.** itch shows screenshots in upload order and the
desktop shot is the one that explains the game in a thumbnail.

## Uploading the build

Use **`builds/ForReals-web.zip`**. Its `index.html` is at the root of the archive,
which is what itch requires - do not re-zip the `builds/web/` folder from its parent
or the entry point ends up one directory down and itch will not find it.

Settings that matter on the upload:

| Setting | Value |
| --- | --- |
| Kind of project | HTML |
| This file will be played in the browser | ticked, on `ForReals-web.zip` |
| Viewport dimensions | `1280 x 720` |
| Fullscreen button | enabled |
| Mobile friendly | off - it is a desktop metaphor with a taskbar |
| SharedArrayBuffer support | **enabled** |

That last one is not optional. Godot 4 web exports use threads, and itch will not
serve the required COOP/COEP headers unless the box is ticked. Without it the game
loads to a black canvas and the browser console complains about `SharedArrayBuffer`.

The Windows, Linux and macOS zips come off the GitHub release rather than being
uploaded by hand - tag a commit (`push.bat "message" v1.0.0`) and the workflow builds
and attaches all four.

## Notes on the CSS

itch applies custom CSS on top of its own stylesheet, so everything is written to
degrade: if a selector changes under it, that rule stops applying and the page falls
back to stock itch rather than breaking.

The one external dependency is the `@font-face` at the top, which pulls `W95FA.otf`
from `raw.githubusercontent.com` on the `main` branch. It works because raw GitHub
sends `access-control-allow-origin: *`. If you rename the repo or the default branch,
**that URL breaks** and the page silently falls back to Tahoma - which still looks
right, just not exact. That declaration is the only rule outside `#wrapper`, because
`@font-face` cannot be nested; it defines a font rather than restyling anything.

itch asks that custom classes be prefixed `custom-`. This file adds none - it only
enhances existing itch components, which is what their guide recommends over
rebuilding the page.
