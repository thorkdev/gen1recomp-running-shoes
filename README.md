# Running Shoes

Hold B to run, once Mom gives you the shoes for helping Prof. Oak.

<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/353cda33-befd-4ba4-8304-e38fbddfda9e" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/ba6bf095-17b5-4c98-bef3-2ceb7a86ffa3" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/d112c7fd-bafe-4bec-b6b1-ae1eea0233ee" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/d131bd49-e3ef-4a33-97b3-2e7d1819eccb" />

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

## OPTIONS rows

Both rows only appear once the shoes are actually unlocked — there's
nothing to toggle before then, so nothing shows up early.

- **RUNNING SHOES** (ON/OFF, default ON) — turns the Hold-B speed boost on
  or off. OFF does not touch the quest: Mom still gives you the shoes and
  the unlock flag still gets set, walking just goes back to vanilla speed
  until you flip it back on.
- **RUN SPEED** (1.5X/2X/3X, default 1.5X) — cycles the Hold-B speed
  multiplier. 1.5X is the closest whole-frame speed under the bike's pace;
  2X matches the bike, and 3X outruns it. Applies to both grid movement
  and the voxel free-roam camera integration below.
- **VIEW BOB** (ON/OFF, default ON) — only appears with dramatic-shape or
  its battle art voxel fork installed (see below). Toggles the camera bob
  while running in first/third person.
- **BOB INTENSITY** (0.5X/1X/1.5X, default 1X) — only appears alongside
  VIEW BOB. Scales how far the camera bobs; has no effect while VIEW BOB
  is OFF.

## Optional: voxel overworld integration

dramatic-shape and its BATTLE_ART_VOXEL_FORK-1.7.x fork both replace
grid movement outright while their 1st/3rd-person camera rungs are active
(`lib/FreeMove.lua`) — the player's position becomes continuous, steered
by the camera, and never goes through `Player:beginStep`. That's the only
place the engine's `movement.speed` hook fires from, so without this
integration the Hold-B boost would silently do nothing the moment you
switched to first or third person.

The fork rewrote the battle presentation, not this seam — its
`FreeMove`/`FirstPerson` keep the same `WALK`/`BIKE` constants and
`tick(state)`/`frame(me, cx, cy, vw, vh)` signatures as dramatic-shape, so
one integration covers either. If dramatic-shape (manifest id
`DRAMATIC_SHAPE`) is installed, this mod hooks into it; otherwise it falls
back to the fork (manifest id `BATTLE_ART_VOXEL_FORK`) if that's installed
instead. In practice only one of the two would ever be installed at once
(same hotkeys, same overworld renderer), so this mod:

- **Wraps `FreeMove.tick`** to scale its `WALK`/`BIKE` px-per-frame
  constants by the same run multiplier the grid hook uses, for the
  duration of one tick, gated on the same unlocked/enabled/Hold-B
  conditions — the free-roam equivalent of the grid speed boost.
- **Wraps `FirstPerson.frame`** to add a small sine-wave offset into the
  eye height (`me.lift`) while running, its phase driven by distance
  actually covered rather than wall-clock time — so the bob rate tracks
  speed the way classic FPS view-bob does, and freezes rather than
  jitters when blocked mid-stride. The phase is wrapped to `[0, 2*pi)`
  every tick rather than left to grow forever, so it doesn't lose
  floating-point precision (and drift or stutter) over a long run. It
  composes with (never overwrites) whatever surf-bob or ledge-hop lift is
  already in play, since `me` is a fresh pose table built fresh every
  frame.

Both wraps reach whichever voxel mod is present only through its own
exported module namespace (`mod.exports.lib`, declared in its `main.lua`)
— no engine file and no voxel mod file is edited. The integration is a
no-op with neither installed, and a hot-reload guard (`_runningShoesHook`
on that namespace) keeps the wraps from stacking if this mod reloads
during dev.

The manifest reflects this: `optional_dependencies` lists `DRAMATIC_SHAPE`
and `BATTLE_ART_VOXEL_FORK` so load order puts whichever is present first,
and `permissions` declares `engine_internals` for the one direct
`require("src.core.Game")` the wraps use to read `save.flags`/`input` —
the same access `FreeMove.tick` itself already has.

## Credits

- pret/pokered — the `TEXT_REDSHOUSE1F_MOM` conversation and
  `EVENT_OAK_GOT_PARCEL` this composes with.
