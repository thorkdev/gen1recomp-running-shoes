# Running Shoes

Hold B to run, once Mom gives you the shoes for helping Prof. Oak.

<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/353cda33-befd-4ba4-8304-e38fbddfda9e" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/ba6bf095-17b5-4c98-bef3-2ceb7a86ffa3" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/d112c7fd-bafe-4bec-b6b1-ae1eea0233ee" />

## What it does

- Deliver Oak's Parcel like normal — no new quest, just the game's own intro errand.
- Talk to Mom afterward and she hands you a pair of Running Shoes.
- From then on, hold **B** while walking to move faster than on foot but
  slower than the bike. Braking on the bike (also B) is unaffected, and
  every other conversation with Mom plays out exactly as vanilla.

## Requirements

- [gen1recomp](https://github.com/bryanthaboi/gen1recomp) — a native LÖVE2D
  recreation of Pokémon Red/Blue/Yellow. This mod needs your own legally
  obtained ROM already imported; it ships no ROM content of its own.

## Install

Drop this folder into your `gen1recomp` install's `mods/` directory:

```sh
git clone https://github.com/<you>/running_shoes mods/running_shoes
```

then enable it in `options.lua` (`mods = { running_shoes = true }`) or
toggle it on in the in-game mod manager (**F10**).

## Credits

- pret/pokered — the `TEXT_REDSHOUSE1F_MOM` conversation and
  `EVENT_OAK_GOT_PARCEL` this composes with.
