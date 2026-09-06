# ForReals

A game about growing a social media account by posting things that aren't true.

Made for Brackeys Game Jam 2026.2. The theme was Trust No One.

Play it at [lazilydev.itch.io/forreals](https://lazilydev.itch.io/forreals).

## The game

You sign up with two followers and one post a day. A day lasts 30 seconds.

A post is three fragments stuck together: someone, something they did, and who they
did it to. `the president` + `caused` + `9/11`. Every morning you get dealt four of
each slot and have to make the best sentence you can out of those twelve cards.

Two things you can look up spread less far but barely raise suspicion. Two unrelated
things nobody can disprove spread further and look much worse. Suspicion fills a bar.
Fill it and you take a strike, lose 30% of your followers, and carry on. Three strikes
and the account is deleted.

At 100 followers a store opens and starts selling fragments that break the rules. Later
you can buy bot farms, and hire people to like and reply for you.

The first win is at 5,000 followers, which takes about half an hour. Playing purely for
reach and ignoring the bar gets you banned in about ten minutes instead.

## Running it

Godot 4.7. Open the project, press F5. No addons, no plugins. It starts fullscreen;
F11 or Alt+Enter to window it.

Everything that decides how it feels is a constant at the top of `scripts/data.gd`.

There are four dev flags:

| Flag | |
| --- | --- |
| `--tour` | drives the whole UI on a timer and asserts as it goes |
| `--balance` | plays competently a few times, prints days-to-win and ban rate |
| `--shots` | writes the itch.io screenshots |
| `--nuke` | skips to the ending |

## The code

8,600 lines of GDScript, 38 scripts, 6 scenes.

There is almost no scene tree. Views are `static func build() -> Control`, and when
`Game` says state changed the shell throws the old one away and calls the builder
again. It means there's nothing to keep in sync, and it means everything rebuilds far
more often than it needs to.

| | |
| --- | --- |
| `scripts/data.gd` | all the text and all the tuning numbers |
| `scripts/game.gd` | the day clock, reach maths, suspicion, strikes |
| `scripts/main.gd` | the shell: three columns, taskbar, toasts, dialogs |
| `scripts/style.gd` | palette, fonts, and the widget factories |
| `scripts/trends.gd` | pulls Wikipedia pageviews to pick the day's trending tags |
| `scripts/sfx.gd` | every sound, synthesised at boot, no audio files |
| `scripts/views/` | the three columns |
| `scripts/screens/` | sign-in, composer, store, tutorial, ending |

`dev_tour.gd` is 1,459 lines and `game.gd` is 1,288. Both want splitting up and neither
got it.

## Builds

A tagged push builds Windows, Linux, macOS, web, Android and iOS and attaches them to
a release. `push.bat "message" v1.0.0` does the tagging.

Some caveats. The macOS build is ad-hoc signed, so Gatekeeper blocks it on first
launch and you have to right-click and Open. The `.ipa` is unsigned and only installs
through AltStore or Sideloadly. The web build runs, but the desktop one is better, and
hired staff don't work offline there because a browser tab's clock can't be trusted.

## Fonts

W95FA by Alina Sava, a recreation of the Windows 95 MS Sans Serif, with Silkscreen for
numbers and Pixelify Sans as the alternate. All three are OFL.
