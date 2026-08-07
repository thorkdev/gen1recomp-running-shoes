# Running Shoes

<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/353cda33-befd-4ba4-8304-e38fbddfda9e" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/ba6bf095-17b5-4c98-bef3-2ceb7a86ffa3" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/d112c7fd-bafe-4bec-b6b1-ae1eea0233ee" />

A `content` mod for the LOVE2D Pokemon Red engine (mod api 2).

## Layout

- `manifest.json` - identity, version range, load order
- `main.lua` - the entry chunk; receives the `mod` object

## Loop

1. `POKEPORT_DEV=1 love .` once, leave it running
2. edit, press F5 to hot-reload, backtick for the dev console
3. `python3 tools/modkit.py validate running_shoes` before sharing
4. `python3 tools/modkit.py pack mods/running_shoes` to ship
