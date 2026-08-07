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
    return out
  end)
end