# Lifey

A life tracker for trading card games, built for a phone or iPad sitting in the middle of the table. Written in SwiftUI, no dependencies, no network access, no analytics.

On the App Store as **Lifey - MTG Life Counter**.

Not affiliated with or endorsed by Wizards of the Coast.

## What it does

- **Life totals** for two to four players, with a press-and-hold that repeats and speeds up.
- **Commander damage** in its own section on every panel. A player's panel tracks what *their own* commanders have dealt, one tile per opponent, doubled when the deck runs partners. A tile turns red at 21. Dealing damage takes the same amount off that opponent's life, which can be switched off. A **Dealt / Taken** switch at the top of the section flips to a read-only view of what this player has taken from each opposing commander.
- **Counters**: poison, energy, experience, rad, tickets and storm, plus any counter the table invents. Each is a chip along the bottom of the panel; tap a chip and the big number becomes that counter.
- **Custom counters**: name it, give it a short chip label, pick a symbol and a colour. Added from the setup screen or mid-game from the menu, and saved with the default. Deleting one keeps its totals, so adding it back brings the numbers with it.
- **Rotation**: two players sit head to head in portrait, so the top panel is upside down and reads correctly from the far side. Three or four players switch the app to landscape, with a choice of arrangements including a pinwheel where every seat faces outwards.
- **Saved default**: once the table is set up the way it likes, "Save as default" stores the seat count, life total, arrangement, names, colours and counter sections. Lifey opens there next time.
- **Dice and coin**: d20, d6, coin flip and a random first player. Hold the button in the middle of the table to reach it.
- **Resume**: a game in progress is written to disk after every change, so closing the app loses nothing.

## Build and run

```sh
cd Lifey
xcodebuild -project Lifey.xcodeproj -scheme Lifey \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Or open `Lifey.xcodeproj` in Xcode and press Run. Deployment target is iOS 17, and the target builds for both iPhone and iPad.

To run on a physical device, select the target, open Signing & Capabilities, and pick your own team. The bundle identifier is `com.lifey.Lifey`.

## Layout of the source

| Path | Contents |
| --- | --- |
| `Lifey/Models` | `Player`, `GameConfig` (the savable default), `GameStore` (all game state and persistence), `CounterKind`, `SeatLayout` |
| `Lifey/Views` | `SetupView`, `GameView` (places and rotates the panels), `PlayerPanel`, `PanelSections` (commander damage and seat settings), `CustomCounters` (the counter editor), `MenuSheet`, `DiceSheet` |
| `Lifey/Support` | `Theme` (colours and fonts), `Feedback` (haptics and sound), `OrientationController` |
| `Tools/MakeAppIcon.swift` | Draws the 1024pt app icon. Run `swift Tools/MakeAppIcon.swift <output.png>` to regenerate it. |

## Adding a table arrangement

Add a case to `SeatLayout`, give it a player count, an orientation, a title and its `slots`. Each slot is a rectangle in unit coordinates plus a rotation in degrees, where 0 faces the player at the bottom edge. `GameView` and `LayoutPreview` both read the same slots, so the setup diagram and the table stay in step.

## Adding a counter in code

Built-in counters are cases of `CounterKind`; the table's own counters are `CustomCounter` values held in `GameConfig`. Both are read through `CounterDefinition`, so a panel chip, the big tally and the saved default all work the same either way.

## Nothing secret lives here

No App Store Connect API keys, no `.p8` files, no certificates. `.gitignore` blocks `*.p8` and `AuthKey_*` as a second line of defence, along with `build/` and the local release notes. Release keys stay in `~/.appstoreconnect/private_keys/`, which is outside this repository. If you fork this to ship your own build, keep it that way.

## Privacy

Lifey stores its totals and settings on the device with `UserDefaults` and makes no network requests at all. The bundled `PrivacyInfo.xcprivacy` declares `UserDefaults` access under reason `CA92.1` and no data collection or tracking.

## Contributing

Issues and pull requests are welcome. The app is deliberately small: one store object, one panel view, and a layout table that both the game screen and the setup diagram read from. Changes that keep it that way are the easiest to merge.

## Licence

No licence has been chosen yet, so all rights are reserved. You are welcome to read the code and open issues; ask before reusing it in your own app.
