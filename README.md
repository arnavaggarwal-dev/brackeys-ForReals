# ForReals

**Brackeys Game Jam 2026.2  theme: Trust No One**

You sign up for a social network with two followers and a handle you can never
change. You get **one post a day**, a day is **thirty seconds**, and the whole run to
five thousand followers takes about **half an hour**. Reaching it ends the story, not
the account - you can take the ending and keep posting.

For three days you post honestly. It does fine. It does not do well.

At **100 followers** the Speech Fragment Store opens. It sells the things you cannot
say for free: verbs that accuse  `caused`, `is hiding`, `quietly funded`  objects
nobody can check, and seven fragments that each break one of the game's own rules.

## Act zero

You do not start as nobody. You start as **@rt_hon_marsh**, a minister with nine
million followers, two strikes already spent, and a suspicion bar at 74 of 80. The
feed is five accounts discussing you in the third person and not one of them follows
you. The objective panel does not say how many followers you need; it says
**Two strikes** - *"there is no appeal, no notification and no number you were ever
shown. You have one post left."*

Whatever you post, it is the third strike. The account is terminated in a single
move, and the ending tells you why in the only terms the game ever uses:

> Nine million people followed that account this morning. It took one post. Nobody
> argued with you. Nobody corrected you. The reach was simply turned down until you
> were talking to an empty room, and then the room was closed. You never saw the
> number that did it.

Then you press **Start again as nobody**, agree to the terms, and the real game
begins at two followers - spending the rest of the run building the machine that
just deleted you.

It is unwinnable on purpose. It runs on the real systems, rigged, so by the time you
have your own account you have already seen suspicion, throttled reach and a strike
land, and nobody had to explain any of them.

## The loop

- **One post a day**, built from three **speech fragments**: **who**, **what they
  did**, and **what they did it to**. `the president` + `caused` + `9/11`. `big food` + `has been lying
  to you about` + `the runaway thermometer`. Every fragment brings its own hashtag,
  so writing the sentence is also choosing the tags. There are thirteen hashtags in
  the whole game and they are deliberately plain - `#science`, `#dailylife`, `#food`,
  `#wakeup` - because a tag is a lane, not a joke.
- **You never see the whole vocabulary.** Every morning deals you four of each slot.
  The day's puzzle is the best sentence hiding in those twelve cards, and you get one
  **DEAL AGAIN** if the hand is useless.
- **Checkable or not.** If the subject and the object come from the same world -
  `big food` and `the price of eggs` - somebody can look it up: it travels less and
  costs you less. Bolt together two things that have nothing to do with each other
  and nothing can disprove it. That is worth 25% more reach and 35% more heat.
- **Catch the trends.** Three hashtags are boosted each day. Each one you catch adds
  75% to your reach, which is worth more than anything you actually have to say. Which
  ones trend is decided by what the real world is actually reading - see below.
- **Your feed is only the last 7 people you followed.** Follow an eighth and the
  first one stops reaching you - their posts leave the feed entirely. The feed is a
  window, not an archive.
- **3-7 new people are recommended every morning**, generated rather than written.
  The handle, display name, bio, topic and follower band are all drawn from the same
  topic table, so an account reads as one person: `coldchain_data`, "Cold Chain",
  *"the study says what i need it to say"*, `#science`. The roll is seeded by run and
  day, so reloading a save offers the same faces.
- **Reacting is posting at a discount.** A like carries **a 25th** of your reach, a
  fire **a 20th**, a reply **an eighth** - each earning followers and payout on the
  same log-normal curve a post does, and costing the same fraction of suspicion.
  Once each per post. Replies unlock at **150 followers**.
- **Your feed is empty until you follow somebody.** Nothing reaches you that you did
  not choose to let in, and following is the only way to fill it.
- **Following costs you the day.** Every follow takes a random **0.3 to 3.67 seconds**
  off that day - and only that day. Tomorrow is thirty seconds again. The toast reports
  it in the game's own clock: *"you spent 1h 50m doomscrolling through @morning_kate's
  posts"*. Twelve accounts exist, so the list is a stock of twelve decisions rather
  than a permanent upgrade, and the bigger ones only appear once you are big enough to
  matter to them.
- **The trust team is watching.** The bought fragments raise **suspicion**. Fill the bar
  and you take a strike: a share of your followers, gone, and your reach limited
  until it cools. Three strikes and the account is removed.
- **Reach arrives, it does not land.** Pressing Post does not pay you out. The post
  starts travelling and the followers trickle in over the next minute or two, fastest
  around the eight-second mark and then tailing off for days. You watch the number
  climb.
- **Like other people.** Liking a post in the feed is free, and the feed remembers
  who shows up: every like you give adds 3% reach to your next post, up to 30%.
- **Silence costs too.** Miss a day and the feed moves on without you.

Two ways out: they suspend you, or you reach **5,000 followers** and become the thing
the trends are made of. The second one is not a door you have to walk through - the
ending offers **Keep the account**, and the run carries on with the clock, the heat
and everything you own exactly where you left them. The ladder above 5,000 runs all
the way to a billion (see below).

## The layout

A Windows 95 desktop. Teal wallpaper, three tiled windows - **Profile**, **ForReals -
Feed**, **Today** - and a taskbar with a Start button and the day clock ticking in
the system tray. NEW POST opens a modal dialog over the top of all of it.

## The look

Every raised control is the same trick the era used: a light source in the top left,
so top and left edges catch white and bottom and right fall into shadow. Invert the
two and it looks pressed; invert only the outer ring and it looks like a hole you can
type into. That is `BevelBox`, a `StyleBox` that draws those two one-pixel rings, and
every panel, button, list box and progress bar in the game is built from it.

Nothing is anti-aliased. Fonts are loaded with hinting and subpixel positioning off
so glyphs land on whole pixels, icons are 12x12 bitmaps written as strings of `#`,
and the progress bars fill in discrete blocks because they never showed you a smooth
fraction.

Suspicion is a machine in trouble. As it climbs, bands of the screen fail to repaint
and smear sideways, the palette collapses toward fewer bits, and the whole display
starts to tear.

## Saving

**Coming back puts you at the top of the day you left.** The save stores the day
number, so a run resumed on day 9 starts day 9 again with a full thirty seconds -
being handed somebody else's four remaining seconds is no way to start a session.
Everything else about the day (posts spent, follows, likes given) is restored as it
was.

The game autosaves to `user://forreals.save` - on Windows that is
`%APPDATA%/Godot/app_userdata/ForReals/`, and on web it is IndexedDB, which Godot 4
flushes for you. It writes five seconds after anything worth keeping happens, on focus
loss, and on window close (the quit is intercepted so the write always lands first).

Launching with a save present resumes straight into the run - no sign-in. "New account"
on the ending screen deletes it. `Save.persistent` reports `OS.is_userfs_persistent()`
so a browser with storage blocked is detectable rather than silently lossy.

Saves carry a `version`; a file from an older version is ignored rather than
half-loaded. Posts store the account handle instead of a copy of the account, and are
rebuilt against `Data.ACCOUNTS` on load, so static content never ends up duplicated in
the save.

## Running it

Open the project folder with **Godot 4.7** and press F5. It starts fullscreen; **F11**
or **Alt+Enter** drops back to a window.

### Builds

`builds/` holds every export, both loose and zipped:

| | Loose | Zipped |
| --- | --- | --- |
| `builds/windows/` | 106 MB | `ForReals-windows.zip` 37.5 MB |
| `builds/Linux/` | 72 MB | `ForReals-linux.zip` 28.4 MB |
| `builds/web/` | 40 MB | `ForReals-web.zip` 11.1 MB |

Rebuild any of them headless, no editor:

```
godot --headless --path . --export-release "Windows Desktop" builds/windows/ForReals.exe
godot --headless --path . --export-release "Linux"           builds/Linux/ForReals.x86_64
godot --headless --path . --export-release "Web"             builds/web/index.html
```

**macOS cannot be exported from Windows**, so it is not in `builds/` - it is built in
CI instead, from Linux, where the `macos.zip` template works. See below.

Because the binaries are committed, the repository uses **Git LFS**. Anyone cloning
needs it installed (`https://git-lfs.com`) or they get 134-byte pointer files instead
of a game. `.gitattributes` routes `*.exe`, `*.pck`, `*.wasm`, `*.zip`, `*.x86_64` and
the large source assets through it. The Windows export is 106 MB on its own, and
GitHub rejects any single file over 100 MB outside LFS, so this is not optional.

### Shipping

`.github/workflows/release.yml` exports **Windows, Linux, macOS and web** on a tagged
push, on a clean Ubuntu runner with a freshly downloaded Godot and template set, and
attaches all four zips to a GitHub release. Tag it and it ships:

```
push.bat "the jam build" v1.0.0
```

`push.bat` stages everything, commits, pushes, and - given a second argument - tags
and pushes the tag, which is what fires the workflow. Without a tag it is just a
commit and a push. It refuses to run if Git LFS is missing, because a push without it
either fails at the 100 MB limit or silently uploads pointer files.

Running the workflow by hand from the Actions tab builds all four platforms and
uploads them as artifacts, but publishes no release - a release needs a tag to be
named after.

The macOS build is ad-hoc signed, not notarised. Gatekeeper refuses it on first
launch; right-click and **Open**, or `xattr -dr com.apple.quarantine ForReals.app`.
Notarising properly needs a paid Apple Developer account, which a jam entry does not
justify.

The repository otherwise carries no import cache and no tooling output - Godot rebuilds
`.godot/` the first time you open it.

The UI size is one number: `window/stretch/scale` in `project.godot`. Counter-intuitively
a *higher* value makes the interface *bigger*, because Godot divides the base viewport
by it - at `0.85` a 1280x720 base becomes a 1506x941 logical viewport, so more fits on
screen and everything draws smaller. Raise it toward 1.0 for a chunkier interface. There is nothing to
install  no plugins, no addons, and no audio or image assets. The sound is
synthesised into WAV buffers at boot, and every pictogram is a drawing, not a sprite
or a font glyph.

## How it is built

| Path | What lives there |
| --- | --- |
| `scripts/trends.gd` | Autoload `Trends` - the Wikimedia fetch, normalised topic weights, and the live/offline status. |
| `scripts/data.gd` | All content and every tuning number: the three fragment tables, their hashtags and weights, accounts, milestones. Autoload `Data`, never mutated. |
| `scripts/game.gd` | Autoload `Game`  the day clock, reach maths, suspicion, strikes, follows, feed generation. Emits signals; knows nothing about UI. |
| `scripts/style.gd` | Autoload `Style`  palette, fonts, and the small factories every view builds from. |
| `scripts/bevel_box.gd` | `BevelBox` - the Windows 95 3D border as a `StyleBox`. |
| `scripts/sfx.gd` | Autoload `Sfx`  procedural synthesis, no audio files. Six voices: `tick`, `tap`, `blip`, `keypress` (typing the handle), `buzz` (a dead control refusing a click) and `shear` (suspicion tearing the screen). |
| `scripts/main.gd` | `AppShell`  one wide sheet of paper split into three columns by drawn rules, plus toasts and the modal host. |
| `scripts/views/` | `left_column` (you, active posts, NEW POST, objective, standing), `center_column` (the feed), `right_column` (the day, trends, follow suggestions), and the shared `post_card`. |
| `scripts/screens/` | The terms of service, sign-in, the `composer`, the `store`, the ending, and the `dialog` base every modal is built from. |
| `scripts/md.gd` | `Md` - a small markdown renderer, used to draw `TOS.md` in the game's own chrome. |
| `scripts/people.gd` | `People` - the profile generator. Topic-consistent handles, names, bios and follower bands, seeded per day. |
| `scripts/widgets/sprite_anim.gd` | `SpriteAnim` - plays the 2D sheets. One table describes every grid. |
| `scripts/shell/taskbar.gd` | `Taskbar` - Start button, window button and tray, lifted out of `AppShell`. |
| `scripts/widgets/toast.gd` | `Toast` - one notification, its own scene. |
| `scripts/nuke.gd` + `nuke.tscn` | The 3D bomb: fall, tumble, impact, fireball, smoke, shake. |
| `scripts/widgets/` | `WinWindow` (frame + title bar), `Icon` (12x12 bitmaps), `Avatar`, `Meter` (segmented bar), `EtchedRule`, `Tappable`. |
| `shaders/` | `desktop` (teal + Bayer dither), `glitch_fx` (stuck bands, palette collapse, tearing). |

Views are plain `static func build() -> Control` functions. `Game` emits
`view_dirty`, `AppShell` throws the old view away and calls the builder again. There
is no scene graph to keep in sync with the state.

### Live trends

Six topics are weighted by real-world attention, pulled from the **Wikimedia
pageviews API** at boot: one request per topic anchor article (`Sport`, `War`,
`Technology`, `Politics`, `Science`, `Food`), summing the last seven days and
normalising so the busiest topic is 1.0. Those weights bias which three tags trend each
day and how full their heat bars run.

**All thirteen hashtags answer to one of those six**, through `Data.TAG_TOPICS`. The
six topic tags map to themselves; the seven meta tags are filed under whatever their
fragments actually talk about - `#breaking`, `#dailylife` and `#wakeup` under politics,
`#research` and `#cats` under science, `#receipts` under war, `#thread` under
technology. Without that table the meta tags fell back to a flat weight and half the
vocabulary ignored the live data entirely.

Instagram was the original idea and is not possible: there is no public
trending-hashtags endpoint. `ig_hashtag_search` needs a Business account, a reviewed
Meta app and a token, caps you at 30 unique hashtags per rolling week, and only returns
media for a hashtag you already named. Wikimedia is free, keyless, and sends permissive
CORS headers, so it also works from a web export.

The six requests fire in parallel with a 5s timeout each and an 8s overall deadline,
and nothing waits on them. If the fetch fails, times out, or you are offline, the game
falls back to the original random daily shuffle and the panel says so. The trends
badge in the Today window reads `live - wikipedia` or `offline - shuffled`.

### The store and the payout

**Money comes from one place: your own posts travelling.** The platform pays a
**creator payout** of £40 per 1,000 reach, and like followers it does not arrive all at
once  it trickles in on the same log-normal curve while the post is still going. Reach
further, earn more. Nothing else in the game earns anything: following, liking and
waiting are all free and all pay nothing.

The composer shows the payout a draft will earn next to its projected reach, so you can
see the money before you spend the day on it. It is deliberately not followers as a
currency  buying should never cost you progress toward the five thousand.

The store button does not exist until you cross 100 followers; it simply appears.

The store opens at 100 followers and is the *only* way to get the charged fragments;
until then the composer deals you honest ones. Seven of its lines each bend one rule
the rest of the game obeys:

| Fragment | Price | What it breaks |
| --- | --- | --- |
| `the algorithm` | £95 | Ignores the suspicion reach throttle entirely. |
| `a leaked document` | £120 | Counts as checkable for suspicion, uncheckable for reach. |
| `an unnamed source` | £150 | All three of your hashtags count as trending. |
| `quietly deleted` | £45 | Costs no suspicion at all, but travels 40% less far. |
| `publicly apologised for` | £70 | Takes 25 *off* your suspicion instead of adding any. |
| `everyone you know` | £110 | Doubles the post's engagement half-life. |
| `this exact post` | £85 | Reach grows 4% for every post you have already made. |

### Assets

Bottom right, the idle half of the game. The panel does not exist until you cross
**300 followers**; like the store it simply appears. Eight things you can buy with the
payout, each getting 15% dearer every time you buy one:

| Asset | From | Produces | Suspicion/sec |
| --- | --- | --- | --- |
| Burner account | £8 | 0.05 followers/sec | 0.085 |
| Comment farm | £30 | 0.30 followers/sec | 0.170 |
| **Scheduling suite** | £60 | **+1 post per day** | 0.250 |
| Engagement pod | £90 | 1.6 followers/sec | 0.300 |
| Bot swarm | £170 | 9 followers/sec | 0.475 |
| Sockpuppet network | £320 | 45 followers/sec | 0.700 |
| Programmatic ad buy | £600 | 220 followers/sec | 0.950 |
| Media partner | £1,400 | 1,100 followers/sec | 1.300 |

The **scheduling suite** is the one that is not idle: each one buys another post in
the day, and it grows at **4x** per purchase rather than 1.15x, because the day does
not get any longer. Buying past one post a day is the most expensive thing in the
game and the only way to spend two hands in one thirty seconds.

A bought audience is exactly what a trust team looks for, so **everything you own
adds heat every second**. The platform only cools you so fast, and that is the whole
late game.

### Heat, and the ceiling

Cooling is **9 a day at 100 followers, rising 5 per tenfold** - 14 a day at a
thousand, 17.5 at five. A big account gets the benefit of the doubt it never gave you at two
followers. The Assets panel shows the only number that matters:

```
earning        2 /SEC
costing       +0.28 SUSP/SEC
vs cooling    x0.63  SUSTAINABLE
```

Above x1.00 you are climbing toward a strike no matter what else you do. Three
strikes ends the run, each one takes **30% of your followers**, and each leaves you
at 50 of 80 - so the second and third arrive faster than the first.

Three levers keep you under the line:

- **Switch things off.** Every asset and agent has an on/off toggle. A paused item
  produces nothing and costs no heat, and you keep what you paid for.
- **Go quiet.** Skip your post for a day: you lose 1.5% of your followers and take
  **-20 suspicion**. The only cooling that costs nothing but reach.
- **`publicly apologised for`** from the store takes 25 off instead of adding any.

Heat per follower-per-second is what separates the tiers - a burner is **0.57**, a
media partner is **0.00013**. Spamming the cheap end fills your heat budget with
almost no output; saving for the top of the ladder is how the panel is meant to be
played. A burner costs you over four thousand times more heat per follower than a
media partner does, so buying cheapest-first fills the bar long before it fills the
counter.

### Buying in bulk

**x1 / x10 / x25**, at the top of both panels. Prices compound per purchase, so ten
burners is a geometric sum, not ten stickers - £162 rather than £80. If you cannot
afford the full step you buy as many as you can.

### People

At **750 followers** you can start hiring. Where assets print followers directly,
people *use your account*: each one lands a like, a fire or a reply on the feed every
few seconds, worth its usual fraction of a post, earning on the same engagement curve.

| Agent | From | Does | Suspicion/sec |
| --- | --- | --- | --- |
| Unpaid intern | £45 | a like every 6s | 0.060 |
| Freelance stringer | £140 | a fire every 8s | 0.110 |
| Ghostwriter | £400 | a reply every 11s | 0.200 |

Slower per pound than a botnet, and far quieter per follower - which is the point.
Their output scales with your reach, so unlike the flat-rate assets they keep pace
with the account.

Prices across both panels are set against what a run actually earns. The payout is
**£40 per 1,000 reach** and a run to 5,000 followers moves a few hundred thousand
reach, so the ladder tops out at **£1,400** and the first agent costs **£45**. Anything
priced above that curve is content nobody ever sees.

### The ladder

Twenty-four ranks, from twenty-five followers to a billion. Each one is a number and
a **title**, and the title is what the profile panel calls you until you pass the next
one. You start as **nobody**.

| At | They call you | At | They call you |
| --- | --- | --- | --- |
| 25 | bud | 100,000 | an institution |
| 100 | regular | 250,000 | a household name |
| 300 | source | 500,000 | the mainstream |
| 600 | voice | 1,000,000 | the record |
| 1,000 | the trend | 2,500,000 | the narrative |
| 1,800 | correspondent | 5,000,000 | consensus |
| 3,000 | commentator | 10,000,000 | the news |
| **5,000** | **public figure** | 25,000,000 | the weather |
| 10,000 | pundit | 50,000,000 | common knowledge |
| 25,000 | thought leader | 100,000,000 | history |
| 50,000 | the discourse | 250,000,000 | the ground truth |
| | | 500,000,000 | the archive |
| | | 1,000,000,000 | everyone |

**Public figure at 5,000 is the win.** The ending fires there once and offers **Keep
the account**; taking it drops you back into the same day with the same heat, and the
objective panel just moves on to the next rank. The titles above it are the point of
the idle half - nothing else in the game asks you to reach a billion of anything.
Past the last rank the objective keeps doubling rather than dead-ending.

### While you are away

**The people you hire keep working when the game is shut.** Assets do not - a bot
swarm is a thing you left running on your own account, and the game is not running.
Agents are people with your password.

One real hour away buys **one game day** of their output, capped at **eight hours**,
and they work at **a fifth** of the rate they manage while you are watching - so
leaving the game open is always better than closing it. They earn followers and payout
on the usual reaction curve, and they raise suspicion the whole time at the same
discount, which means a large enough stable of ghostwriters can hand you a strike
while you are asleep.

This is **Windows and Linux only** (`Game.offline_supported()`). The web export runs
in a tab whose storage and wall clock are both negotiable, so it does not get offline
earnings at all. A save whose timestamp is in the future - a timezone change, a
fiddled system clock - earns nothing rather than everything.

### How suspicion explains itself

Nothing in the game ever defines suspicion. The Standing panel just says how the
account is being treated, and the line changes with the state:

| When | It says |
| --- | --- |
| nothing running, bar empty | nobody is looking at you yet. |
| bar falling | it is going down faster than you are adding to it. |
| heat above cooling | whatever you have running is being noticed. |
| over a third | you have been added to a list somewhere. |
| over 60% | your reach is being quietly limited. |
| over 85% | somebody is reading your posts twice. |
| two strikes | one more and there is no account. |

That last line is the one act zero opens on, before you have any idea what it means.

### Suspicion and strikes

Every post adds `middle + end` suspicion, times **0.60** if the claim is checkable or
**1.35** if it is not. It decays 9 a day at 100 followers and faster as you grow (see
above). While it is up, reach is multiplied by
`1 - suspicion/220`, floored at 25%.

Hit 80 and you take a **strike**: minus 30% of your followers, and suspicion resets to
50 rather than 0  so each strike leaves you closer to the next. Three ends the run.

### The engagement curve

Real posts do not spike and stop. Engagement is an "early burst + long tail": the
arrival rate peaks shortly after publication and then decays hard, so most of the
lifetime total lands early and the rest trickles in for a very long time. Graffius
(2026, 5.6M posts) measures the engagement half-life on X at **52 minutes**, and the
shape is a positively skewed unimodal curve.

So cumulative engagement here is the **log-normal CDF** - `Game.engagement_progress()`
- with its median at `ENGAGEMENT_HALFLIFE` (8 game seconds, the same fraction of a day
that 52 minutes is of 24 hours) and spread `ENGAGEMENT_SIGMA`. Likes, replies, fire
and followers are all that curve times the post's lifetime total, so a fresh post
reads `+4 still going` and the same post two days later reads `+1,204`.

Followers are the one slice that is not predictable: the lifetime total is
`reach x 0.11` times a roll of **0.21 to 2.83**, so the same draft can land anywhere
from a fifth of what it looks worth to nearly three times it. That is why the composer
shows reach and payout but never a follower count - the number does not exist yet.

Timestamps run on the same fiction: one game second is 48 minutes, so a 30-second day
reads as a 24-hour one and posts are stamped `20m ago`, `6h ago`, `2d ago`.

### The growth curve

How loud your account already is multiplies everything it posts next, and the shape of
that term is the whole pacing of the game:

```
reach *= AUDIENCE_FLOOR + sqrt(followers) / AUDIENCE_DIVISOR
```

This used to be `1 + followers / 400`, which is **linear in followers** - compound
interest. Every post paid out in proportion to what the last one earned, so the curve
went vertical and the run was over in ten days. Square root instead means each new
follower is worth less than the one before: a big account is meaningfully louder than a
small one, but it never runs away.

`AUDIENCE_FLOOR` is where the curve starts, and at **0.12** it means a brand new
account is not amplified, it is muffled. That number is the difference between
reaching 100 followers on day 3 and reaching it in a week, which is the point - the
first days are supposed to do fine and not do well.

Simulated over seven runs of competent play: **100 followers around day 6, 600 by day
18, 3,000 by day 46, and the win around day 55** - a little under half an hour. Playing
purely for reach and ignoring the bar gets you banned around day 20 instead.

### Balance

`godot --headless --balance` plays the run the way a competent player would - the
loudest sentence in the hand it can afford the heat for, a few reactions, assets bought
by heat efficiency - and reports days to win, ban rate and where each milestone landed:

```
run 1: won  day  55  10,663 followers  0 strikes  100@d6 600@d18 3.0K@d46 5.0K@d55
BALANCE: won 7/7 - median day 55, mean 55.7
BALANCE: that is 27.9 minutes of play at 30s a day
```

Tuning an economy by feel is how it ended up winnable in five minutes. This is the
number to tune against.

### Tuning

Everything that decides how the game feels is a constant at the top of
`scripts/data.gd`: day length, the follow discount, how many honest days you get,
the suspicion limit and its decay, the coherent/absurd multipliers, and the reach and
suspicion cost of every single fragment.

### The Start menu

Bottom left, where it belongs. Three things:

- **Sound: on / off** - toggles all audio, including the bomb. The setting lives in
  its own file, `user://forreals.cfg`, so it is a machine preference and survives
  having the save deleted.
- **Nuke account...** - asks once, then deletes the save. Permanently.
- **Quit** - writes the save, then closes.

### Nuking the account

Choosing it plays `nuke.tscn`: a 3D scene mounted over the desktop in a
`SubViewport`. A bomb falls out of frame-top, tumbling on all three axes with a
sideways drift so it reads as unsteered rather than aimed, hits the ground about two
seconds later, and detonates - the screen goes fully white on the frame of impact and fades over 1.2s, a one-shot fireball, a rising
smoke plume, a burst of light, camera shake, and `kaboom.mp3`. Then the save is gone
and you are at the sign-in screen with nothing.

`godot --nuke` skips straight to it, for working on the animation without playing
the whole run to reach it.

Both particle systems draw their colour straight from a gradient with
`shading_mode = UNSHADED` and `vertex_color_is_srgb = true`; lit, the smoke came out
white, and without the sRGB flag the greys render two stops too bright.

The bomb model was 55 MB as exported; the decimated version in `assets/3d` is
**1.2 MB**, which is no longer the thing dominating the web download.

### Type

Body and UI text is **[W95FA](https://fontsarena.com/w95fa-by-alina-sava/)** by Alina
Sava, SIL Open Font License, bundled in `assets/fonts/`. It is a recreation of the
MS Sans Serif that shipped with Windows 95, so it is the correct face for this
interface rather than merely a compatible one, and it is a proportional UI font
doing UI work. Pixelify Sans was a display face set as body copy and it showed.

W95FA ships one weight, so medium and bold are `FontVariation` with
`variation_embolden` at 0.35 and 0.85. Numbers still go through Silkscreen via
`Style.num()` / `Style.live_num()`, because Pixelify's digits were ambiguous and
that fix is unrelated to the body face.

Antialiasing, hinting and subpixel positioning stay off: MS Sans Serif was a bitmap
font, so unhinted and aliased is both authentic and sharper at these sizes.

### Sprites

Everything in `assets/2d` is 8x8 pixel art on a uniform grid, drawn nearest-neighbour
(`default_texture_filter=0`):

| Sheet | Grid | Frames | Used for |
| --- | --- | --- | --- |
| `heart.png` | 2x2 of 8x8 | 3 | likes, on posts and in your stats |
| `comments.png` | 2x2 of 8x8 | 3 | replies |
| `followers.png` | 3x3 of 8x8 | 9 | the follower counter |
| `fire.png` | 5x1 of 32x32 | 5 | trending markers, the Start button |
| `persona*.png` | single 8x8 | - | six avatars, one per account colour |

Heart, comment and fire play at **8fps**; the follower strip at 12. A sheet loops
while its post is still travelling and settles on frame 0 once it has finished, so a
live post is visibly alive. `fire.png` was converted from `fire.gif` - 1200x1200 and
5 frames - down to a 160x32 strip with a hard alpha cut, because a 1.4MB flame for a
15px icon is not a trade worth making.

`SpriteAnim` sets `expand_mode = EXPAND_IGNORE_SIZE`; without it the 32x32 fire cell
drags its whole row to 32px while the 8x8 sheets sit at 8, and nothing lines up.

### Scenes

The project began as one `main.tscn` and about 450 lines of `AppShell` doing
everything. It is now six scenes:

| Scene | What it is |
| --- | --- |
| `scenes/main.tscn` | the shell - desktop, three windows, veil |
| `scenes/shell/taskbar.tscn` | Start button, window button, tray |
| `scenes/widgets/toast.tscn` | one notification |
| `scenes/widgets/sprite_anim.tscn` | one animated sheet |
| `scenes/widgets/avatar.tscn` | one profile picture |
| `scenes/nuke.tscn` | the bomb |

Watch for Godot re-creating a moved `.tscn` at its old path from the uid cache - it
did exactly that to `main.tscn` and `nuke.tscn` here, leaving two copies to drift
apart. `tools/gdgraph.py` catches it: a scene "instanced by nothing" that is not the
entry point is a duplicate.

### The graph

`/graphify` cannot read this project. GDScript is not in its `CODE_EXTENSIONS`, so it
sees three markdown files, fifteen sprites and an mp3, and reports **zero code
nodes** - the graph it built on 2026-08-28 described an architecture that no longer
exists.

`tools/gdgraph.py` replaces the AST pass: it walks the `.gd` and `.tscn` sources and
writes the same `graph.json` node_link shape plus `GRAPH_REPORT.md`, so
`graphify query`, `graphify path` and `graphify explain` still work. Every edge is
EXTRACTED - imports, `class_name` references, autoload use, `res://` paths,
`ext_resource` entries. No inference, no LLM, no tokens.

### The terms of service

On a first run - no save file, which is also the state of any fresh browser tab - the
game opens `TOS.md` before sign-in and will not create an account until the box is
ticked. The file is authored as ordinary markdown and rendered by `scripts/md.gd` into
the game's own controls: headings, rules, bullets, numbered lists, blockquotes, code
blocks, and inline bold/italic/code. Numbers are routed through Silkscreen there for
the same reason they are everywhere else - Pixelify's digits are ambiguous at small
sizes.

Edit `TOS.md` and the screen changes; no code touches the text. **`TOS.md` is a loose
file, not an imported resource, so an export preset must include `*.md` in its
resource filter** or the build falls back to a stub. The tour asserts the real file
loads and renders.

### Development tour

`godot --tour` drives the UI through sign-in, a post, every tab, the day-four offer
and the ending on a timer. Combined with `--write-movie frames/f.png` it gives you a
full visual pass without touching the mouse. The flag does nothing when it is absent.

`godot --shots` drives the game to five representative states and writes a PNG of each
into `itchpush/screenshots` - the desktop, the composer, the store, the late-run heat,
and the ending. Five, because that is what a store page can use. It needs a window;
there is nothing to capture headless. See `itchpush/README.md` for what goes where on
the itch.io page, including the SharedArrayBuffer setting the web build will not run
without.

## Credits

Fonts: [Pixelify Sans](https://fonts.google.com/specimen/Pixelify+Sans) for prose and
[Silkscreen](https://fonts.google.com/specimen/Silkscreen) for anything numeric - its
digits are unambiguous at small sizes, which matters in a game you read numbers off.
Both SIL Open Font License. Everything else is in this repository.
