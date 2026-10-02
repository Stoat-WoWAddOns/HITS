# Head In The Sand (HITS) — 1.0.1

If you don't want to see it, stick your head in the sand.

## Install (Retail or WoW Forever Beta)

1. Exit the client you intend to use. Extract this ZIP.
2. Copy the **HeadInTheSand** folder into that client's `Interface/AddOns/`.
   Retail normally uses `_retail_/Interface/AddOns/`; Forever Beta currently
   uses `_classic_beta_/Interface/AddOns/`. Use the selected beta client's own
   installation directory if yours differs. The `.toc` file must be directly in
   `AddOns/HeadInTheSand/`, without a second nested folder.
3. Launch that client and enable **Head In The Sand** in the AddOns menu.
4. Type `/hits` (or `/headinthesand`) to open the Settings panel.

To upgrade, replace the existing HITS addon folder while WoW is closed. Your
saved `HITS_DB` settings are retained. Retail and beta have separate SavedVariables;
installing the addon in beta does not automatically copy Retail's settings.

The shared TOC declares Retail **120100** and Forever **16000, 16001**.
The currently reported Forever Beta interface is **16001**. HITS chooses the
modern or legacy chat/Settings APIs by availability, without treating Forever
as Classic based on its interface number or Mainline project ID.

Beta builds can change. If a newer beta marks HITS out of date, check its
interface with `/dump select(4, GetBuildInfo())`. Enable **Load out of date AddOns**
for a trial, or update the TOC's `## Interface:` line to include that number.
Metadata alone does not prove compatibility. `/hits debug` prints HITS version,
client build/interface, and the chosen chat and Settings APIs for troubleshooting.

## Changes in 1.0.1

- Added Forever Beta interface numbers while retaining Retail's target.
- Prefer `ChatFrameUtil.AddMessageEventFilter`; fall back to the legacy global.
- Use `securecallfunction` for registration when available.
- Recognize Trade (Local) as Trade, including its localized name when provided
  by the client. The Trade checkbox controls both variants.
- Require a complete modern Settings API before choosing it; otherwise use
  legacy options when available.
- Added `/hits debug` and tests for modern/legacy API combinations.

## Configuration

Changes take effect immediately and are saved account-wide by WoW on logout or
`/reload`. No Save button is required.

- **Enable HITS**: pause or resume all filtering.
- **Language Filters**: Chinese/Han and Korean/Hangul detection applies globally
  to all supported player-chat events, regardless of the channel checkboxes.
  This follows the request that language filtering work across the board.
- **Where Should HITS Look?**: one checkbox per source controls **word filtering**.
  General, Trade (including Trade Local), Services, LocalDefense, Say, and Yell default on. Group chat,
  guild/officer, whispers, Battle.net whispers, emotes, and other/custom channels
  default off. Public channel routing uses static IDs rather than mutable /1, /2
  numbers, with English/localized-name fallback.
- **Things I'd Rather Not See**: scrollable phrase list with Remove buttons.
  Type a phrase and press Enter or Add. Defaults are `anal` and `thunderfury`.
- **Ignore capitalization** defaults on. Lua's lowercase conversion handles
  ASCII letters; full Unicode case folding is not implemented.
- **Match text inside WoW links** defaults on and checks visible link labels.
  Turning it off excludes link labels from word matching. Hidden link metadata
  and texture paths are never searched. Language detection still checks labels.
- Optional notices and the session-only hidden-message count default off.
- **Reset Defaults** asks for confirmation, then restores the starting settings.

`/hits status` prints enabled state, phrase count, and messages hidden this session.
`/hits help` prints command help. `/hits debug` prints client compatibility details.

## Matching behavior

A match suppresses the **entire message** in standard chat frames. Messages are
not altered, senders are not ignored, and no information is sent to other players.
It applies to incoming and outgoing messages for supported events. System/NPC
messages, combat logs, chat bubbles, and separate third-party chat displays are
outside this addon's scope. Restricted/secret message values are passed through
if the client does not allow an addon to inspect them.

Words are literal substrings: `anal` also matches `analysis`, `ANAL` (with case
ignored), and longer phrases. `wts boost` matches that exact contiguous phrase,
not arbitrary spacing. Lua pattern symbols such as `.` or `%` are literal.
Color markup is removed before matching to handle ordinary colored chat text.

Han script is shared by Chinese and Japanese kanji, and may occur in Korean
Hanja. The addon detects characters, not a message's spoken language. Japanese
messages containing kanji can therefore be hidden. Romanized Chinese/Korean is
not detected. Hangul syllables, Jamo, compatibility/extended/halfwidth Jamo and
major Han ideograph ranges are included.

Thunderfury is matched by its displayed name, so localized names require adding
that translated name yourself. This is a configurable name filter, not a
hard-coded item-ID block.

## Validation and troubleshooting

The release was syntax-checked and tested in a local Lua harness with mocked WoW
APIs. Tests cover Unicode, malformed UTF-8, literal phrases, links, channel
routing, persistence initialization, commands, UI controls and counter deduplication.
It has **not been run inside Retail or Forever Beta**; live-client validation is still needed. This is a beta-targeted compatibility update, not a claim of an in-game verified release.

For an in-game check: open `/hits`, verify the two default phrases, toggle a
channel, and `/reload` to confirm it persists. Use a checked Say channel to
compare an ordinary message with one containing a blocked phrase. Check that
unchecked Guild/Party messages still allow blocked words. A language match is
global even when that channel is unchecked. Temporarily disable language filters
if your test involves Chinese/Hangul. To inspect errors use
`/console scriptErrors 1`, then `/reload`; restore with `/console scriptErrors 0`.

No external libraries or dependencies are bundled.

## Included source test harness

From the directory containing `HeadInTheSand/`, run:

```sh
texlua HeadInTheSand/tests/test_hits.lua legacy
texlua HeadInTheSand/tests/test_hits.lua modern
texlua HeadInTheSand/tests/test_hits.lua legacy_settings
texlua HeadInTheSand/tests/test_hits.lua partial_settings
texlua HeadInTheSand/tests/test_hits.lua missing_filters
```

The harness also runs with a standard Lua interpreter. It is not loaded by WoW.
This release passed **267 assertions across five API environments** (53/55/53/53/53). The UI mock checks callbacks and bindings,
not rendering or client API compatibility.

API references consulted: Blizzard's UI implementation mirrored in
[ChatFrameOverrides.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Mainline/ChatFrameOverrides.lua)
and [ChatFrameUtil.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua).

Forever interface/project behavior is corroborated by the first-hand
[ArkInventory beta issue](https://github.com/arkayenro/arkinventory/issues/2162)
and the [LibTSMCore developer documentation](https://github.com/TradeSkillMaster/LibTSMCore).
The [Forever Chat Filter author](https://www.curseforge.com/wow/addons/forever-chat-filter)
describes its modern chat API with the legacy fallback.
