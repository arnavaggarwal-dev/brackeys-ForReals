# ForReals

*Brackeys Game Jam 2026.2 — **Trust No One***

You sign up for a social network with two followers and a handle you can never change.
One post a day. A day is thirty seconds.

For three days you post honestly. It does fine. It does not do well.

At **100 followers** the Speech Fragment Store opens, and it sells the things you cannot
say for free: verbs that accuse — `caused`, `is hiding`, `quietly funded` — objects
nobody can check, and seven fragments that each break one of the game's own rules.

---

## But you do not start as nobody

You start as **@rt_hon_marsh**, a minister with nine million followers, two strikes
already spent, and a suspicion bar at 74 of 80. The feed is five accounts discussing
you in the third person, and not one of them follows you. The objective panel does not
say how many followers you need. It says **Two strikes**.

Whatever you post, it is the third. The account is gone in a single move:

> Nine million people followed that account this morning. It took one post. Nobody
> argued with you. Nobody corrected you. The reach was simply turned down until you
> were talking to an empty room, and then the room was closed. You never saw the number
> that did it.

Then you press **Start again as nobody**, agree to the terms, and the real game begins
at two followers — spending the rest of the run building the machine that just deleted
you.

---

## The loop

- **One post a day**, built from three fragments: who, what they did, and what they did
  it to. `the president` + `caused` + `9/11`. Every fragment brings its own hashtag, so
  writing the sentence is also choosing the tags.
- **You never see the whole vocabulary.** Every morning deals you four of each slot. The
  day's puzzle is the best sentence hiding in those twelve cards.
- **Checkable or not.** If your subject and object come from the same world, somebody
  can look it up — it travels less. Bolt together two unrelated things and nothing can
  disprove it: 25% more reach, 35% more heat.
- **Catch the trends.** Three hashtags are boosted each day, and which ones is decided
  by **what the real world is actually reading** — pulled live from Wikipedia pageviews
  at boot.
- **Your feed is only the last 7 people you followed.** Follow an eighth and the first
  one stops reaching you.
- **Following costs you the day.** Every follow takes real seconds off your thirty.
- **The trust team is watching.** Bought fragments raise suspicion. Fill the bar and you
  take a strike. Three and the account is removed.
- **Reach arrives, it does not land.** Pressing Post pays you nothing. The post starts
  travelling and the followers trickle in over the next minute or two, on a log-normal
  curve fitted to a real measurement of engagement half-life.

Reach **5,000 followers** and you are a *public figure* — and the ending is a door, not
a wall. Keep the account and the ladder runs on to a billion.

---

## It is unwinnable on purpose

It runs on the real systems, rigged. By the time you have your own account you have
already seen suspicion, throttled reach and a strike land, and nobody had to explain
any of them to you.

---

## Made for the jam

A Windows 95 desktop, drawn rather than skinned: every raised control is one light
source in the top left, two one-pixel rings, and nothing anti-aliased. All sound is
synthesised into WAV buffers at boot — there are no audio files except the bomb. Every
pictogram is a 12×12 bitmap written as strings of `#`.

Godot 4.7. Type is [W95FA](https://fontsarena.com/w95fa-by-alina-sava/) by Alina Sava
and [Silkscreen](https://fonts.google.com/specimen/Silkscreen) for numbers, both SIL
Open Font License.

**Source:** https://github.com/arnavaggarwal-dev/brackeys-ForReals

---

### Downloads

| | |
| --- | --- |
| **Play in browser** | no download, works on desktop browsers |
| **Windows** | `ForReals-windows.zip` |
| **Linux** | `ForReals-linux.zip` |
| **macOS** | `ForReals-macos.zip` — unsigned, see below |

The macOS build is ad-hoc signed, not notarised, because notarising needs a paid Apple
Developer account. Gatekeeper will refuse it on first launch: **right-click the app and
choose Open**, or run `xattr -dr com.apple.quarantine ForReals.app`.
