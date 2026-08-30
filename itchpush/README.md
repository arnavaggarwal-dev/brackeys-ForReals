# itchpush

Everything the itch.io page needs, kept in the repo so the store listing is versioned
like the rest of the game.

```
itchpush/
  screenshots/       five 1664x936 PNGs, regenerate with `godot --shots`
  PAGE.md            the page description, ready to paste
  push-itch.bat      upload the builds with butler
  README.md          this file
```

## Theming the page

Use the built-in theme editor on the game's edit page. It needs no permission and gets
you the Windows 95 palette:

| Field | Value |
| --- | --- |
| Background | `#008080` — the teal desktop |
| Text | `#000000` |
| Link | `#000080` — navy |
| Button background | `#c0c0c0` |
| Button text | `#000000` |

Custom CSS is a separate thing on itch and is **not enabled by default** — it is
granted per account on request, and [their guide](https://itch.io/docs/creators/css-guide)
says they do not grant it to empty accounts. The theme editor above covers the colours
without any of that.

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

## Uploading

`push.bat` in the project root does it, once `ITCH_TARGET` is set in that file:

```
push.bat "message"              commit and push to GitHub
push.bat "message" v1.0.0       ...tag it, which builds and releases
push.bat "message" v1.0.0 itch  ...and upload the builds to itch.io
```

`itchpush/push-itch.bat` does only the itch half if that is all you want.

Butler pushes the loose `builds/` folders rather than the zips on purpose: it diffs
against the previous upload and sends only what changed, so the first push moves the
full ~218 MB and every one after that is seconds. The zips stay for the GitHub release.

The project page has to exist on itch before butler can push to it - butler will not
create it for you. The target is `<username>/<game-slug>`, where the slug is the last
part of the page URL, not the display title.

## Settings that matter on the web upload

| Setting | Value |
| --- | --- |
| Kind of project | HTML |
| This file will be played in the browser | ticked, on the `html` channel upload |
| Viewport dimensions | `1280 x 720` |
| Fullscreen button | enabled |
| Mobile friendly | off - it is a desktop metaphor with a taskbar |
| SharedArrayBuffer support | **enabled** |

That last one is not optional. Godot 4 web exports use threads, and itch will not
serve the required COOP/COEP headers unless the box is ticked. Without it the game
loads to a black canvas and the browser console complains about `SharedArrayBuffer`.

macOS is not pushed from Windows - it cannot be exported there. It comes off the
GitHub release once CI has built it:

```
gh release download v1.0.0 -p "ForReals-macos.zip"
butler push ForReals-macos.zip <user>/<game>:osx
```
