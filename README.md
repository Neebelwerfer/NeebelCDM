# A Cooldown manager for Wow
Taking some inspiration from WAs but wanting to take a more constrained approach after WoWs big API changes

## The goal
The goal of this project is to learn a bit about WoW Api and Data-driven design in terms of creating modular UI

## Current State
Early phase - Just figuring out the structure and experimenting

### Current tasks:
- [ ] Add tracking 
    - [x] Add initial spell tracking
    - [x] Add initial aura tracking
    - [ ] Add initial item tracking
- [ ] Add Dynamic groups
    - [x] Vertical/Horizontal
    - [x] Trailing/Centered/Leading
    - [ ] Wrapping
- [ ] Add in game editor
    - [ ] Node list
        - [ ] Node Creation
        - [x] Context Menu
        - [ ] Drag and Drop
        - [ ] Movable node when selected in the hierarchy
    - [ ] Property settings
        - [x] Icon
        - [x] Cooldown
        - [x] Text
        - [ ] Bar 
    - [x] Node layout settings
    - [x] Bindings menu
    - [x] Additional CDM options menu
- [ ] Events?
    - [ ] Spell Events (Going off/on cd, getting full charges)
    - [ ] Aura Events (Activated, Removed)
- [ ] Conditionals and Visibility
    - [ ] Visibility for notes based on load rules
    - [ ] Conditionals (very constrained conditional system)
- [ ] Refactor
    - [ ] Move frame offset from layout to properties so it fits better with the system
    - [ ] Split the frame update functions into multiple functions, one for each property
    - [ ] Make sure we dont update static properties since they never change
    - [ ] Remake the whole Blizzard Manager integration and aura and blizzard manager hooks to be more stable
    - [ ] Make dynamic group actually change layout settings for children so it wont get awkward later
    - [ ] Add validation when adding bindings etc. 
    - [x] Add templating for text
- [ ] Fixes
    - [ ] Layout: Anchor point seems to behaver weirdly
