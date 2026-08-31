# ForReals

**Brackeys Game Jam 2026.2 — theme: Trust No One**

You sign up for a social network with two followers and a handle you can never change.
One post a day. A day is thirty seconds. Reaching 5,000 followers takes about half an
hour.

For three days you post honestly. It does fine. It does not do well. At **100
followers** the Speech Fragment Store opens and sells the things you cannot say for
free.

## Act zero

You do not start as nobody. You start as **@rt_hon_marsh**, a minister with nine
million followers, two strikes spent, and suspicion at 74 of 80. The objective panel
does not say how many followers you need; it says **Two strikes**.

Whatever you post is the third. The account is gone in one move:

> Nine million people followed that account this morning. It took one post. Nobody
> argued with you. Nobody corrected you. The reach was simply turned down until you
> were talking to an empty room, and then the room was closed.

Then you start again at two followers, and spend the run building the machine that
just deleted you.

The ending names the thing that killed you. It shows the bar the account was actually
carrying - 74 of 80, which you were never shown - and spells out the four rules: claims
nobody can check fill it, it cools a little each day and faster the bigger you are,
filling it costs a strike and 30% of your followers, and three strikes ends the account.
You have just watched all four happen, so the explanation lands on something you already
felt rather than a tooltip you skipped.

## The loop

- **One post a day**, built from three fragments: who, what they did, what they did it
  to. `the president` + `caused` + `9/11`. Each fragment carries a hashtag, so writing
  the sentence is choosing the tags. Thirteen tags, all deliberately plain.
- **You never see the whole vocabulary.** Four of each slot dealt every morning, one
  **DEAL AGAIN** per day. The puzzle is the best sentence in those twelve cards.
- **Checkable or not.** Subject and object from the same world can be looked up: ×0.90
  reach, ×0.60 suspicion. Unrelated things cannot be disproved: ×1.25 reach, ×1.35
  suspicion.
- **Catch the trends.** Three tags are boosted daily, each worth +75% reach. Which ones
  trend is driven by live Wikipedia pageviews.
- **Your feed is only the last 7 people you followed.** Follow an eighth and the first
  drops out. Following costs 0.3–3.67s off *that day* only.
- **Reacting is posting at a discount** — a like is 1/25 of your reach, a fire 1/20, a
  reply 1/8, once each per post. Replies unlock at 5 followers.
- **Reach arrives, it does not land.** Posting pays nothing immediately; followers
  trickle in on a log-normal curve while the post travels.
- **Suspicion.** Bought fragments raise it. Fill the bar and you take a strike. Three
  and the account is removed.

Wins fire at **5,000**, **1,000,000** and **1,000,000,000** followers. Each is a door,
not a wall — take the ending and **Keep the account** to carry on with clock, heat and
assets intact.

On first sign-in a six-step tutorial points at the real controls - the post button, your
profile, the feed, the trends panel, the suspicion bar and the taskbar. Skippable, and
replayable any time from **Start -> Tutorial**.

## Running it

Open with **Godot 4.7**, press F5. Starts fullscreen; **F11** or **Alt+Enter** to
window. No plugins, no addons. All sound is synthesised at boot; every pictogram is a
12×12 bitmap drawn from strings of `#`.

UI scale is one number: `window/stretch/scale` in `project.godot`. Counter-intuitively
a *higher* value makes the interface *bigger*, because Godot divides the base viewport
by it.

| Flag | What it does |
| --- | --- |
| `--tour` | drives the whole UI on a timer and asserts as it goes |
| `--balance` | simulates competent play, reports days-to-win and ban rate |
| `--shots` | writes the five store screenshots to `itchpush/screenshots` |
| `--nuke` | skips straight to the bomb |

The Start menu also carries sound, a font toggle, the tutorial, nuking the save, and
quit. It opens over the sign-in screen too, so you can quit before ever making an
account. The font toggle swaps the whole interface between **W95FA** and **Pixelify
Sans**; both are already bundled and OFL, which is why it is those two and not Comic
Sans (proprietary, cannot be redistributed) or Minecraftia (unclear licence).

## Numbers

Everything that decides how the game feels is a constant at the top of
`scripts/data.gd`.

| | |
| --- | --- |
| Day length | 30s (min 6s after follows) |
| Win tiers | 5,000 / 1M / 1B |
| Unlocks | store 100, replies 5, assets 300, agents 750 |
| Follower share | 11% of reach, × a roll of 0.21–2.83 |
| Payout | £40 per 1,000 reach |
| Suspicion | limit 80, cooling 9/day at 100 followers +5 per tenfold |
| Strike | −30% followers, resets to 50, three ends the run |
| Quiet day | −1.5% followers, −20 suspicion |
| Engagement half-life | 8 game seconds (log-normal CDF) |

### The growth curve

How loud you already are multiplies what you post next, and this term is the whole
pacing of the game:

```
reach *= AUDIENCE_FLOOR + sqrt(followers) / AUDIENCE_DIVISOR
```

This was `1 + followers / 400` — linear, i.e. compound interest. Every post paid out in
proportion to what the last one earned, so the curve went vertical and the run was over
in ten days. Square root means each new follower is worth less than the one before.
`AUDIENCE_FLOOR` at 0.12 means a new account is muffled rather than amplified; that
constant is the difference between hitting 100 followers on day 3 and in a week.

Measured over seven simulated runs (`--balance`): **100 followers around day 6, 600 by
day 18, 3,000 by day 46, win around day 55** — a little under half an hour. Playing
purely for reach and ignoring the bar gets you banned around day 20 instead.

### The store

Opens at 100 followers, the only source of charged fragments. Seven of its lines each
break a rule the rest of the game obeys:

| Fragment | Price | What it breaks |
| --- | --- | --- |
| `the algorithm` | £95 | ignores the suspicion reach throttle |
| `a leaked document` | £120 | checkable for suspicion, uncheckable for reach |
| `an unnamed source` | £150 | all three hashtags count as trending |
| `quietly deleted` | £45 | no suspicion at all, but travels 40% less far |
| `publicly apologised for` | £70 | takes 25 *off* your suspicion |
| `everyone you know` | £110 | doubles the post's engagement half-life |
| `this exact post` | £85 | +4% reach per post you have already made |

### Assets and people

Assets appear at 300 followers, hires at 750. Prices compound 15% per purchase (the
scheduler 90%, because one copy buys a whole extra post). Every asset you own adds heat
every second, and that is the whole late game - a burner costs over four thousand times
more heat per follower than a media partner.

| Asset | From | Produces | Susp/sec | | Agent | From | Does | Susp/sec |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Burner account | £8 | 0.05 f/s | 0.085 | | Unpaid intern | £45 | a like every 6s | none |
| Comment farm | £30 | 0.30 f/s | 0.170 | | Freelance stringer | £140 | a fire every 8s | none |
| **Scheduling suite** | £60 | **+1 post/day** | 0.250 | | Ghostwriter | £400 | a reply every 11s | none |
| Engagement pod | £90 | 1.6 f/s | 0.300 | | | | | |
| Bot swarm | £170 | 9 f/s | 0.475 | | | | | |
| Sockpuppet network | £320 | 45 f/s | 0.700 | | | | | |
| Programmatic ad buy | £600 | 220 f/s | 0.950 | | | | | |
| Media partner | £1,400 | 1,100 f/s | 1.300 | | | | | |

Assets raise suspicion. **People do not.** They choose what to react to and when, and
being made to answer for a choice you were never offered is not a game - so nothing the
payroll does is charged to you, while your own likes and replies still are. Under the
old rule a competent player who hired the staff the game was offering got banned every
single time; the balance simulation only ever reported otherwise because it never
thought to hire anyone.

Three levers keep you under the cooling line: pause anything (paused items produce
nothing and cost no heat), go quiet for a day, or buy `publicly apologised for`.

Nothing on the shelf is one to a customer. Every asset and every agent can be bought
again as many times as the payout will stand, the price rising 15% a copy - the
Scheduling suite included, which climbs at 90% a copy because each one buys a whole
extra post rather than a trickle of followers. The speech fragments in the store are
the only single purchases, because owning a line twice would mean nothing.

### While you are away

Hired people keep working when the game is shut — assets do not. One real hour buys one
game day of output, capped at eight, at a fifth of the rate they manage while you watch.
They cost no suspicion, so you cannot come back to a strike you did not earn.
**Windows, Linux and Android only**; the web build runs in a tab whose clock and storage
are both negotiable.

## How it is built

Views are plain `static func build() -> Control`. `Game` emits `view_dirty`, `AppShell`
throws the old view away and calls the builder again. There is no scene graph to keep in
sync with state.

| Path | What lives there |
| --- | --- |
| `scripts/data.gd` | all content and every tuning number. Autoload `Data`, never mutated |
| `scripts/game.gd` | the day clock, reach maths, suspicion, strikes, feed. Emits signals, knows nothing about UI |
| `scripts/trends.gd` | the Wikimedia fetch and normalised topic weights |
| `scripts/style.gd` | palette, fonts, and the factories every view builds from |
| `scripts/prefs.gd` | `user://forreals.cfg` - sound, font and tutorial-seen, kept out of the save |
| `scripts/screens/tutorial.gd` | the six-step overlay, and `widgets/highlight.gd` draws its ring |
| `scripts/bevel_box.gd` | the Windows 95 3D border as a `StyleBox` |
| `scripts/sfx.gd` | procedural synthesis, no audio files |
| `scripts/main.gd` | `AppShell` — three columns, toasts, modal host |
| `scripts/views/` | left (you, objective, standing), center (feed), right (day, trends, assets) |
| `scripts/screens/` | terms, sign-in, composer, store, ending, and the `dialog` base |
| `scripts/people.gd` | the profile generator, seeded per day |
| `scripts/md.gd` | small markdown renderer, used to draw `TOS.md` in the game's chrome |
| `scripts/nuke.gd` | the 3D bomb |
| `shaders/` | `desktop` (teal + Bayer dither), `glitch_fx` (stuck bands, tearing) |
| `tools/gdgraph.py` | walks the `.gd` and `.tscn` sources into `graph.json` |

### Live trends

Six topic weights are pulled from the **Wikimedia pageviews API** at boot — one request
per anchor article, last seven days, normalised so the busiest topic is 1.0. All
thirteen hashtags map to one of those six through `Data.TAG_TOPICS`; without that table
the seven meta tags fell back to a flat weight and half the vocabulary ignored the live
data. Six parallel requests, 5s timeout each, 8s overall deadline, nothing waits on
them. On failure the game falls back to a random daily shuffle and the panel says
`offline - shuffled`.

Instagram was the original idea and is not possible: no public trending-hashtags
endpoint. Wikimedia is free, keyless, and sends permissive CORS headers, so it works
from a web export too.

### Saving

Autosaves to `user://forreals.save` five seconds after anything worth keeping, on a
sixty-second heartbeat, on focus loss, and on window close (the quit is intercepted so
the write lands first). Resuming puts you at the **top** of the day you left with a full
thirty seconds. Saves carry a `version`; an older file is ignored rather than
half-loaded. Posts store the account handle and are rebuilt against `Data.ACCOUNTS` on
load.

### Type and sprites

Body text is [W95FA](https://fontsarena.com/w95fa-by-alina-sava/) by Alina Sava, a
recreation of the MS Sans Serif that shipped with Windows 95 — the correct face for this
interface rather than merely a compatible one. It ships one weight, so medium and bold
are `FontVariation`. Numbers go through [Silkscreen](https://fonts.google.com/specimen/Silkscreen),
whose digits are unambiguous at small sizes. Both SIL Open Font License. Antialiasing,
hinting and subpixel positioning stay off: MS Sans Serif was a bitmap font, so unhinted
and aliased is both authentic and sharper.

Everything in `assets/2d` is 8×8 pixel art on a uniform grid drawn nearest-neighbour.
Heart, comment and fire play at 8fps, the follower strip at 12. A sheet loops while its
post is still travelling and settles on frame 0 once it has finished.

### The terms of service

On a first run the game opens `TOS.md` before sign-in and will not create an account
until the box is ticked. It is ordinary markdown rendered into the game's own controls.
**`TOS.md` is a loose file, so an export preset must include `*.md` in its resource
filter** or the build falls back to a stub.

## Builds

`builds/` holds every export, loose and zipped. Rebuild headless:

```
godot --headless --path . --export-release "Windows Desktop" builds/windows/ForReals.exe
godot --headless --path . --export-release "Linux"           builds/Linux/ForReals.x86_64
godot --headless --path . --export-release "Web"             builds/web/index.html
godot --headless --path . --export-debug   "Android"         builds/android/ForReals.apk
godot --headless --path . --export-release "iOS"             builds/ios/ForReals.ipa
```

The iOS line writes an Xcode project, not an app, and only works on macOS.


### Shipping

`.github/workflows/release.yml` exports Windows, Linux, macOS, web, Android and iOS on
a tagged push and attaches all six to a release. Everything but iOS builds on a Linux
runner; iOS needs macOS for Xcode. `push.bat` drives it:

```
push.bat "message"              commit and push
push.bat "message" v1.0.0       ...tag it, which builds and releases
push.bat "message" notag        ...commit and push without tagging
```

The macOS build is ad-hoc signed, not notarised. Gatekeeper refuses it on first launch:
right-click and **Open**, or `xattr -dr com.apple.quarantine ForReals.app`.

### Android

The APK carries arm64-v8a, armeabi-v7a and x86_64, so it covers phones, tablets and
Chromebooks; that is most of the 80 MB. It is exported from the prebuilt templates, so
no Gradle and no NDK are needed - only a **JDK 17 or newer** and the Android SDK
build-tools, both pointed at from *Editor Settings -> Export -> Android*. Android Studio
already ships a suitable JDK at `.../Android Studio/jbr`.

Signing is a preset setting, not an environment variable. CI writes `keystore/release`,
`keystore/release_user` and `keystore/release_password` into `export_presets.cfg` before
exporting, from the `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD` and
`ANDROID_KEY_ALIAS` repository secrets. Without those secrets it makes a throwaway key,
which still installs but will not install *over* an earlier release. To build locally,
inject the same three keys by hand and take them out again afterwards - do not commit an
absolute keystore path.

#### The handheld shell

The interface is scaled against the **real screen, not the pixel count**: about 5.9
units per millimetre of glass on a phone, 5.0 on a tablet, worked back into
`content_scale_factor` in `AppShell._fit_handheld`. Any fixed unit count fails - the
desktop's density puts body text at 1.15mm on a phone, and a count that reads well in
landscape is unreadable turned upright.

Three columns need 340 + 320 plus a feed between them, which no phone has in either
orientation, so below `NARROW_BELOW` the shell shows **one window at a time** and the
taskbar grows a button per window - Me, Feed, Today - which is what a taskbar was always
for. Both orientations are allowed and rotating re-scales; it only rebuilds the shell
when the column count actually changes, which is to say on a tablet.

Two things bite on a real device, both fixed here and both worth knowing:

  - **The taskbar must not set the shell's width.** Its row wanted 411 units against a
    385 unit portrait screen, and being a `PanelContainer` it propagated that minimum
    all the way up, dragging every window off the right edge. The row now sits in a
    plain `Control`, which reports no minimum of its own.

  - **`get_display_safe_area()` answers late.** Just after a rotation Android still
    describes the orientation the phone has left, so a landscape rectangle arrives
    against a portrait window and the right inset comes out *positive*. Anything
    claiming more than a quarter of the window is not believed.

The safe area insets the desktop along with the shell, so the band beside a camera
cutout falls through to a black underlay and reads as bezel rather than a teal stripe.

A dialog asks for a width but a container is never smaller than what it holds, so
anything laid out in columns has to stack on a narrow shell or it overrides that width
and hangs off the screen. The composer does exactly that with its three fragment lists
and its verdict/projection pair.

Rows scroll by dragging: `DragScroll` tracks the finger in `_input`, ahead of the GUI,
because every row is a `Tappable` that swallows the press before a `ScrollContainer`
could ever see it. A drag past ten pixels cancels the press, so scrolling a shelf never
buys anything. The back gesture steps out of the open panel and falls through to the
Start menu; it never ends the run.

`res://assets/android/` and `res://assets/ios/` hold the launcher icons, generated from
`icon.svg` by `godot --headless --path . --script res://tools/make_mobile_icons.gd`.
iOS rejects an icon with an alpha channel, so those are flattened onto the boot teal.

### iOS

Built in CI on a macOS runner, because Xcode only exists there. Godot writes an Xcode
project rather than a finished app - the preset sets `application/export_project_only` -
and `xcodebuild` turns it into the `.app`, which is zipped as `Payload/` into an `.ipa`.
The target is read out of `xcodebuild -list` rather than named, and it is built with
`-target` not `-scheme`, because the generated project carries no shared scheme.

`audio/general/ios/session_category` is **Playback**. Godot defaults to Ambient, which
the ring/silent switch mutes, so the game shipped silent on any iPhone with the switch
flicked - which is most of them.

Quitting from the Start menu ends the process outright on a handheld. iOS ignores
`get_tree().quit()` and Android can leave the task in the switcher, so `AppShell` follows
it with `OS.kill(OS.get_process_id())`.

**The `.ipa` is unsigned.** Signing needs a paid Apple Developer account, so CI passes
`CODE_SIGNING_ALLOWED=NO`. It installs through AltStore or Sideloadly, which re-sign it
with your own Apple ID, and it is not App Store ready. To sign it properly, import a
`.p12` and a provisioning profile into the runner keychain and drop the
`CODE_SIGNING_*` overrides.

Godot refuses to export iOS at all without an App Store team ID, signed or not, so the
preset carries the placeholder `0000000000`. Set an `APPLE_TEAM_ID` secret and CI writes
the real one in before exporting, which is what makes the generated Xcode project ready
to sign. `application/min_ios_version` is 14.0 because the Metal renderer will not go
lower.
