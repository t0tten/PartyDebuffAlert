# PartyDebuffAlert

**Language:** Lua  
**Game:** World of Warcraft (Interface 10.2.x / Retail)

Alerts you, in real time, when a party member carries a debuff that your class can dispel.

---

## Features

- Detects **Magic, Curse, Poison and Disease** debuffs on the player and all party members.
- Only shows alerts for debuff types **your class can actually remove**:

  | Class   | Dispels                        |
  |---------|-------------------------------|
  | Priest  | Magic, Disease                |
  | Paladin | Magic, Poison, Disease        |
  | Druid   | Curse, Poison                 |
  | Mage    | Curse                         |
  | Shaman  | Curse, Poison                 |
  | Monk    | Magic, Poison, Disease        |
  | Evoker  | Magic, Curse                  |

- Popup appears **centre-screen** and shows:
  - Who has the debuff (player name)
  - What type it is (colour-coded)
  - The spell name
- Multiple alerts queue up and display one at a time.
- **In-game configuration panel** – open with `/pda`, `/partydebuffalert`, or by clicking the minimap button.
- **Minimap button** – drag it to any position around the minimap; the position is saved between sessions.

---

## Installation

1. Copy the `PartyDebuffAlert` folder into:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
2. Start or reload WoW (`/reload`).
3. Enable **PartyDebuffAlert** in the AddOns list on the character-select screen.

---

## Configuration

Type `/pda` in-game to open the config panel. Available options:

| Setting                 | Default | Description                              |
|-------------------------|---------|------------------------------------------|
| Enable addon            | On      | Master on/off switch                     |
| Track Magic             | On      | Alert on Magic debuffs                   |
| Track Curse             | On      | Alert on Curse debuffs                   |
| Track Poison            | On      | Alert on Poison debuffs                  |
| Track Disease           | On      | Alert on Disease debuffs                 |
| Alert display duration  | 4 sec   | How long each popup stays on screen (1–10 s) |

Settings are saved between sessions via `SavedVariables`.

---

## File overview

| File                           | Purpose                                   |
|--------------------------------|-------------------------------------------|
| `PartyDebuffAlert.toc`              | Addon manifest                            |
| `PartyDebuffAlert.lua`              | Core logic – event handling, scan loop    |
| `PartyDebuffAlert_UI.lua`           | Popup frame and alert queue               |
| `PartyDebuffAlert_Config.lua`       | In-game configuration panel               |
| `PartyDebuffAlert_MinimapButton.lua`| Draggable minimap button                  |
