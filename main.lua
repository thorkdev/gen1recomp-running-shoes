-- mods/running_shoes/main.lua
local MapScripts = require("src.script.MapScripts")

local UNLOCKED = "MOD_RUNNING_SHOES_UNLOCKED"

return function(mod)
  -- Hands off to Mom's real (engine) conversation, whichever branch it
  -- resolves to (pre-starter wake-up, or the post-starter heal script).
  -- Her entry in data/scripts/reds_house.lua is a plain row list, not a
  -- function (unlike the Pewter nerd in example_lost_parcel), so it can't
  -- be called directly -- and runner:run() refuses to start a second
  -- script while this one (the row that got us here) is still running.
  -- ScriptRunner:exec runs the base rows in place on the same coroutine,
  -- which is exactly what happens when the base script is dispatched
  -- normally, just inlined instead of a fresh :run().
  mod.content.commands:register("running_shoes:base_mom_chat", {
    foreground = true,
    fn = function(ctx)
      local base = MapScripts.baseTalk("REDS_HOUSE_1F", "TEXT_REDSHOUSE1F_MOM")
      if not base then return end
      if type(base) == "function" then
        local runner = ctx.runner
        base(ctx.game, ctx.overworld, ctx.npc, function() runner:resume() end)
        runner:yield()
        return
      end
      ctx.runner:exec(base, ctx)
    end,
  })

  mod.content.map_scripts:register("REDS_HOUSE_1F", {
    talk = {
      TEXT_REDSHOUSE1F_MOM = {
        { "check_flag", UNLOCKED },
        { "jump_if_true", "vanilla" },      -- already has the shoes: normal Mom
        { "check_flag", "EVENT_OAK_GOT_PARCEL" },
        { "jump_if_false", "vanilla" },      -- parcel not delivered yet: normal Mom
        { "set_flag", UNLOCKED },
        { "show_text",
          "MOM: Oh, {PLAYER}!\nI heard you helped\nPROF.OAK out.\fTake these RUNNING\nSHOES as thanks!\fHold B while you\nwalk to run!" },
        { "jump", "end" },

        { "label", "vanilla" },
        { "running_shoes:base_mom_chat" },
      },
    },
  })

  -- ------- hold B to run, once unlocked -- faster than walking, slower
  -- than the bike.  Speed here is frames-per-step (fewer = faster) and
  -- has to land on a whole number, so 1.5x isn't exact: 16 walk frames /
  -- 1.5 = 10.67, floored to 10 frames (an effective 1.6x -- the closest
  -- whole-frame value under the bike's clean 2x/8-frame pace).
  local RUN_SPEED = 1.5
  mod.hooks:wrap("movement.speed", function(next, frames, ctx)
    if ctx.onBike or ctx.surfing then return next(frames, ctx) end
    if not (ctx.save and ctx.save.flags and ctx.save.flags[UNLOCKED]) then
      return next(frames, ctx)
    end
    -- OFF: the OPTIONS toggle below only gates the speed boost, never the
    -- quest itself -- UNLOCKED still gets set by Mom's script either way,
    -- so switching this back on later doesn't require replaying anything.
    if not mod.save:get("enabled", true) then
      return next(frames, ctx)
    end
    if ctx.input and ctx.input.isDown and ctx.input:isDown("b") then
      return math.max(1, math.floor(frames / RUN_SPEED))
    end
    return next(frames, ctx)
  end)

  -- ------- voxel overworld integration (dramatic-shape / battle art voxel fork)
  --
  -- The voxel mod's 1ST/3RD free-roam camera rungs replace grid movement
  -- outright (lib/FreeMove.lua): OverworldState:handleInput gets wrapped
  -- so FreeMove.tick drives the player's continuous world position
  -- directly and never calls Player:beginStep -- which is the only place
  -- movement.speed above ever fires from. Standing on the grid (rung
  -- off) still goes through the hook above as normal; this is purely the
  -- free-roam case.
  --
  -- Optional: this whole block is a no-op unless one of the two voxel
  -- mods is installed and has already run -- dramatic-shape (manifest id
  -- DRAMATIC_SHAPE) or its BATTLE_ART_VOXEL_FORK fork, checked in that
  -- order. Both ship FreeMove/FirstPerson with the same WALK/BIKE
  -- constants and tick(state)/frame(me, cx, cy, vw, vh) signatures --
  -- the fork rewrote the battle presentation, not this seam -- so one
  -- integration covers either. mod.exports.lib is the module's entire
  -- namespace, exported wholesale by both (main.lua: `mod.exports.lib =
  -- V`) -- the sanctioned way another mod reaches in. Only one of the
  -- two would ever be installed at once in practice (same hotkeys, same
  -- overworld renderer), so precedence between them doesn't matter.
  -- bobActive/bobPhase are shared between the two wraps below: the tick
  -- wrap (world update) knows whether the player is actually running and
  -- how far they moved this tick; the frame wrap (camera/render) only
  -- needs to read that and turn it into an eye offset. Phase advances by
  -- distance actually covered, not wall-clock time, so the bob rate
  -- tracks speed the way Doom's does -- standing still (blocked by a
  -- wall, mid wall-slide) holds the last phase instead of bobbing in
  -- place.
  local bobActive = false
  local bobPhase = 0
  local BOB_AMPLITUDE = 1.2 -- world px of vertical eye travel
  local BOB_PERIOD_PX = 20 -- world px of running per full bob cycle
  local BOB_FREQ = (2 * math.pi) / BOB_PERIOD_PX

  local ds = mod.find("DRAMATIC_SHAPE") or mod.find("BATTLE_ART_VOXEL_FORK")
  if ds and ds.exports and ds.exports.lib and not ds.exports.lib._runningShoesHook then
    local FreeMove = ds.exports.lib.require("FreeMove")
    local FirstPerson = ds.exports.lib.require("FirstPerson")
    ds.exports.lib._runningShoesHook = true -- hot-reload guard: wrap once
    -- WALK/BIKE are world-px-per-fixed-frame constants FreeMove.tick reads
    -- fresh on every call (see its own header comment on why they're set
    -- to mirror the grid walker's speeds 1:1). Scaling them for the
    -- duration of one tick and restoring right after is the free-walk
    -- equivalent of movement.speed's per-step frame count: same RUN_SPEED,
    -- same UNLOCKED/enabled gate, no dramatic-shape file touched.
    local baseWalk, baseBike = FreeMove.WALK, FreeMove.BIKE
    local innerTick = FreeMove.tick
    function FreeMove.tick(state)
      local Game = require("src.core.Game")
      local unlocked = Game.save and Game.save.flags
        and Game.save.flags[UNLOCKED]
      local running = unlocked and mod.save:get("enabled", true)
        and Game.input and Game.input.isDown and Game.input:isDown("b")
      if running then
        FreeMove.WALK = baseWalk * RUN_SPEED
        FreeMove.BIKE = baseBike * RUN_SPEED
      end
      local p = state.player
      local px0, py0 = p and p.px, p and p.py
      innerTick(state)
      FreeMove.WALK, FreeMove.BIKE = baseWalk, baseBike

      bobActive = running and true or false
      if bobActive and p and px0 and p.px then
        local dx, dy = p.px - px0, p.py - py0
        bobPhase = bobPhase + math.sqrt(dx * dx + dy * dy) * BOB_FREQ
      end
    end

    -- me is a fresh per-frame pose table (VoxelScene.posesOf), not shared
    -- state, so adding to me.lift here only ever affects this one frame's
    -- eye height -- it composes with whatever surf bob or ledge-hop lift
    -- is already in there rather than overwriting it.
    local innerFrame = FirstPerson.frame
    function FirstPerson.frame(me, cx, cy, vw, vh)
      if bobActive and me and mod.save:get("viewBob", true) then
        me.lift = (me.lift or 0) + BOB_AMPLITUDE * math.sin(bobPhase)
      end
      return innerFrame(me, cx, cy, vw, vh)
    end
  end

  -- ------- OPTIONS row, but only once there's something to toggle: a
  -- save that hasn't met Mom with the parcel yet has no UNLOCKED flag, so
  -- offering a switch for a feature the player doesn't have yet would just
  -- be confusing (same reasoning as the vanilla POKéDEX/LINK start-menu
  -- rows, which are conditioned on save state the same way).
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    if not (game.save and game.save.flags and game.save.flags[UNLOCKED]) then
      return out
    end
    out[#out + 1] = {
      id = "running_shoes_enabled",
      label = "RUNNING SHOES",
      value = function()
        return mod.save:get("enabled", true) and "ON" or "OFF"
      end,
      step = function()
        mod.save:set("enabled", not mod.save:get("enabled", true))
        return true
      end,
    }
    -- only meaningful with a voxel mod's first/third-person camera
    -- installed (dramatic-shape or its battle art voxel fork) -- ds is
    -- the same handle the integration block above resolved once at
    -- load, so this stays in sync with whether that block actually ran
    if ds then
      out[#out + 1] = {
        id = "running_shoes_view_bob",
        label = "VIEW BOB",
        value = function()
          return mod.save:get("viewBob", true) and "ON" or "OFF"
        end,
        step = function()
          mod.save:set("viewBob", not mod.save:get("viewBob", true))
          return true
        end,
      }
    end
    return out
  end)
end