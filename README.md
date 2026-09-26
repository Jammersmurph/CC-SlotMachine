# CC-SlotMachine

A simple animated slot machine for **CC: Tweaked** using an Advanced Computer and attached monitor.

## Behavior

- Redstone input on the **right** starts one spin.
- The right input must turn off before another spin can occur.
- If all three reels match, the computer outputs a redstone pulse on the **left**.
- The program waits for the next trigger after each spin.

## Install / Update

Run this on the CC:Tweaked computer:

```lua
wget run https://raw.githubusercontent.com/Jammersmurph/CC-SlotMachine/main/install.lua
```

The installer downloads the latest program and saves it as `startup.lua`, so it runs automatically on boot.

## Wiring

- **Right:** spin trigger input
- **Left:** win pulse output

## Default odds

There are 5 equally likely symbols and a win requires all 3 to match.

**Win probability: 1/25 = 4%**
