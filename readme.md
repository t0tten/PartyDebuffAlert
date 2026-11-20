# PartyDebuffAlert

**Language:** Lua  
**Game:** World of Warcraft (WoW Forever 1.6x / Retail compatible)

Alerts you, in real time, when you or a party member carries a debuff that your class can dispel.

---

## Features

- Detects **Magic, Curse, Poison, and Disease** debuffs on the player (`player`) and all party members (`party1`–`party4`).
- Only shows alerts for debuff types **your class can actually remove**:

  | Class   | Dispels                        |
  |---------|--------------------------------|
  | Priest  | Magic, Disease                 |
  | Paladin | Magic, Poison, Disease         |
  | Druid   | Curse, Poison                  |
  | Mage    | Curse                          |
  | Shaman  | Curse, Poison                  |
  | Monk    | Magic, Poison, Disease         |
  | Evoker  | Magic, Curse                   |

- **Popup Alert** (movable via Edit Mode) shows:
  - Who has the debuff (player name)
  - What type it is (color-coded)
  - The spell name
- **Pulsing Portrait Arrows:** Displays a large, left-pointing, color-coded arrow next to each affected unit's portrait (`PlayerFrame` and `PartyMemberFrame1`–`PartyMemberFrame4`). The arrow pulses in size and blinks gently, staying visible for as long as the debuff remains active.
- Multiple alerts queue up and display one at a time without spamming repeated alerts for the same active debuff.
- **In-game configuration panel & Edit Mode** – open with `/pdebuff` (or by clicking the minimap button) to configure debuff tracking, colors, **Preview**, and **Edit Mode** to drag both the popup alert and portrait arrow positions.
- **Minimap button** – drag it to any position around the minimap; the position is saved between sessions.

---

## Installation

1. Copy the `PartyDebuffAlert` folder into your AddOns directory:
   ```text
   World of Warcraft\_forever_\Interface\AddOns\