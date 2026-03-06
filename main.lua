-- name: [CS] \\#ffff22\\Super \\#ff5555\\Mario \\#0055ff\\63.5
-- description: I seem to have misplaced one of my marios.\n\n\\#ff7777\\This Pack requires Character Select\nto use as a Library!

local TEXT_MOD_NAME = "[CS] Super Mario 63.5"

-- Stops mod from loading if Character Select isn't on
if not _G.charSelectExists then
    djui_popup_create("\\#ffffdc\\\n"..TEXT_MOD_NAME.."\nRequires the Character Select Mod\nto use as a Library!\n\nPlease turn on the Character Select Mod\nand Restart the Room!", 6)
    return 0
end

-- Models --
local E_MODEL_J_MARIO = smlua_model_util_get_id("jers_mario_geo")
--local E_MODEL_J_LUIGI = smlua_model_util_get_id("jers_luigi_geo")
local E_MODEL_SHINE_SPRITE = smlua_model_util_get_id("jers_shine_sprite_geo")

-- Textures --
local TEX_J_MARIO = gTextures.mario_head --get_texture_info("jmar_mario_icon")
local TEX_J_LUIGI = gTextures.luigi_head --get_texture_info("jmar_luigi_icon")
local TEX_SHINE_SPRITE = get_texture_info("jmar_shine_sprite")

local VOICETABLE_J_MARIO_SM63 = {
    [CHAR_SOUND_YAH_WAH_HOO] = {"JM_YAH.ogg", "JM_WAH.ogg", "JM_HOO2.ogg"},
    [CHAR_SOUND_HOOHOO] = "JM_HOOHOO.ogg",
    [CHAR_SOUND_YAHOO] = "JM_YAHOO.ogg",
    [CHAR_SOUND_UH] = "JM_UH.ogg",
    [CHAR_SOUND_HRMM] = "JM_HRMM.ogg",
    [CHAR_SOUND_WAH2] = "JM_WAH2.ogg",
    [CHAR_SOUND_WHOA] = "JM_WHOA.ogg",
    [CHAR_SOUND_EEUH] = "JM_EEUH.ogg",
    [CHAR_SOUND_ATTACKED] = "JM_DOH.ogg",
    [CHAR_SOUND_OOOF] = "JM_OOOF.ogg",
    [CHAR_SOUND_OOOF2] = "JM_OOOF.ogg",
    [CHAR_SOUND_HERE_WE_GO] = "JM_HERE_WE_GO.ogg",
    [CHAR_SOUND_YAWNING] = "JM_YAWNING.ogg",
    [CHAR_SOUND_SNORING1] = "JM_SNORING1.ogg",
    [CHAR_SOUND_SNORING2] = "JM_SNORING2.ogg",
    [CHAR_SOUND_WAAAOOOW] = "JM_WAAAOOOW.ogg",
    [CHAR_SOUND_HAHA] = "JM_HAHA.ogg",
    [CHAR_SOUND_HAHA_2] = "JM_HAHA.ogg",
    [CHAR_SOUND_UH2] = "JM_UH2.ogg",
    [CHAR_SOUND_UH2_2] = nil,
    [CHAR_SOUND_ON_FIRE] = "JM_ON_FIRE.ogg",
    [CHAR_SOUND_DYING] = "JM_OHHH.ogg",
    [CHAR_SOUND_PANTING_COLD] = "JM_PANTING.ogg",
    [CHAR_SOUND_PANTING] = "JM_PANTING.ogg",
    [CHAR_SOUND_COUGHING1] = "JM_COUGHING.ogg",
    [CHAR_SOUND_COUGHING2] = "JM_COUGHING.ogg",
    [CHAR_SOUND_COUGHING3] = "JM_COUGHING.ogg",
    [CHAR_SOUND_PUNCH_YAH] = "JM_YAH2.ogg",
    [CHAR_SOUND_PUNCH_HOO] = "JM_HOO.ogg",
    [CHAR_SOUND_MAMA_MIA] = "JM_MAMA_MIA.ogg",
    [CHAR_SOUND_GROUND_POUND_WAH] = nil,
    [CHAR_SOUND_DROWNING] = "JM_MAMA_MIA.ogg", --"JM_DROWNING.ogg",
    [CHAR_SOUND_PUNCH_WAH] = "JM_WAH.ogg",
    [CHAR_SOUND_YAHOO_WAHA_YIPPEE] = "JM_YIPPEE.ogg", --{"JM_YAHOO.ogg", "JM_WAHA.ogg", "JM_YIPPEE.ogg"},
    [CHAR_SOUND_DOH] = "JM_DOH.ogg",
    [CHAR_SOUND_GAME_OVER] = "JM_GAME_OVER.ogg",
    [CHAR_SOUND_HELLO] = "JM_HELLO.ogg",
    [CHAR_SOUND_PRESS_START_TO_PLAY] = "JM_PRESS_START_TO_PLAY.ogg",
    [CHAR_SOUND_TWIRL_BOUNCE] = "JM_TWIRL_BOUNCE.ogg",
    [CHAR_SOUND_SNORING3] = "JM_SNORING3.ogg",
    [CHAR_SOUND_SO_LONGA_BOWSER] = "JM_SO_LONGA_BOWSER.ogg",
    [CHAR_SOUND_IMA_TIRED] = "JM_IMA_TIRED.ogg",
    [CHAR_SOUND_LETS_A_GO] = "JM_LETS_A_GO.ogg",
    [CHAR_SOUND_OKEY_DOKEY] = "JM_OKEY_DOKEY.ogg",
    --CHAR_SOUND_MAX
    --[CHAR_SOUND_YEEHAW] = "JM_YEEHAW.ogg"
}

local PALETTES_MARIO = {
    {
        name = "Default",
        [PANTS]  = "0000ff",
        [SHIRT]  = "ff0000",
        [GLOVES] = "ffffff",
        [SHOES]  = "721c0e",
        [HAIR]   = "730600",
        [SKIN]   = "fec179",
        [CAP]    = "ff0000",
        [EMBLEM] = "ff0000",
    },
    {
        name = "Skyward Highway",
        [PANTS]  = "194ba3",
        [SHIRT]  = "ff3033",
        [GLOVES] = "dddddd",
        [SHOES]  = "512800",
        [HAIR]   = "580900",
        [SKIN]   = "ffaf8c",
        [CAP]    = "ff3033",
        [EMBLEM] = "ff3033",
    },
    {
        name = "Fortunate Feline",
        [PANTS]  = "0099ff",
        [SHIRT]  = "ff0024",
        [GLOVES] = "ffffff",
        [SHOES]  = "e1b858",
        [HAIR]   = "730600",
        [SKIN]   = "fec179",
        [CAP]    = "ff0024",
        [EMBLEM] = "ff0024",
    },
    {
        name = "Clay Court Comeback",
        [PANTS]  = "002886",
        [SHIRT]  = "FF0000",
        [GLOVES] = "ffffff",
        [SHOES]  = "472708",
        [HAIR]   = "472708",
        [SKIN]   = "FFEF9C",
        [CAP]    = "FF0000",
        [EMBLEM] = "FF0000",
    },
    {
        name = "Blue Brawler",
        [PANTS]  = "d32210",
        [SHIRT]  = "4231b6",
        [GLOVES] = "ffffff",
        [SHOES]  = "472708",
        [HAIR]   = "730600",
        [SKIN]   = "fec179",
        [CAP]    = "4231b6",
        [EMBLEM] = "4231b6",
    },
    {
        name = "Aged Beige",
        [PANTS]  = "4b1d00",
        [SHIRT]  = "bdb66c",
        [GLOVES] = "ffffff",
        [SHOES]  = "18275d",
        [HAIR]   = "730600",
        [SKIN]   = "fec179",
        [CAP]    = "4b1d00",
        [EMBLEM] = "4b1d00",
    },
    {
        name = "Clumsy In Nature",
        [PANTS]  = "ffffff",
        [SHIRT]  = "ff0000",
        [GLOVES] = "fec179",
        [SHOES]  = "333333",
        [HAIR]   = "730600",
        [SKIN]   = "fec179",
        [CAP]    = "ffffff",
        [EMBLEM] = "ff0000",
    },
    {
        name = "Neighbourly Painter",
        [PANTS]  = "00ff00",
        [SHIRT]  = "000000",
        [GLOVES] = "ffff00",
        [SHOES]  = "ff0000",
        [HAIR]   = "000000",
        [SKIN]   = "ffff00",
        [CAP]    = "000000",
        [EMBLEM] = "000000",
    },
}

local PALETTES_LUIGI =  {
    {
        name = "Default",
        [PANTS]  = "0000ff",
        [SHIRT]  = "008C00",
        [GLOVES] = "ffffff",
        [SHOES]  = "501607",
        [HAIR]   = "730600",
        [SKIN]   = "fec179",
        [CAP]    = "008C00",
        [EMBLEM] = "008C00",
    },
    {
        name = "Frenchie",
        [PANTS]  = "371785",
        [SHIRT]  = "008519",
        [GLOVES] = "ffffff",
        [SHOES]  = "721C0E",
        [HAIR]   = "721C0E",
        [SKIN]   = "FEC179",
        [CAP]    = "008519",
        [EMBLEM] = "008519",
    },
}

local ANIMS_J_MARIO = {
    [_G.charSelect.CS_ANIM_MENU]            = "mario_anim_cs_menu",
    [CHAR_ANIM_RUNNING]                     = "JMAR_RUN",
    [CHAR_ANIM_SINGLE_JUMP]                 = "JMAR_SINGLE_JUMP",
    [CHAR_ANIM_GROUND_POUND_LANDING]        = "JMAR_GP_LANDING",
    [CHAR_ANIM_TRIPLE_JUMP_GROUND_POUND]    = "JMAR_START_GP",
    [CHAR_ANIM_START_GROUND_POUND]          = "JMAR_START_GP",
    [CHAR_ANIM_GROUND_POUND]                = "JMAR_GP",
}
local EYES_J_MARIO = {
    [_G.charSelect.CS_ANIM_MENU]            = MARIO_EYES_LOOK_RIGHT,
    [CHAR_ANIM_IDLE_HEAD_LEFT]              = MARIO_EYES_LOOK_RIGHT,
    [CHAR_ANIM_IDLE_HEAD_RIGHT]             = MARIO_EYES_LOOK_LEFT,
    [CHAR_ANIM_GROUND_POUND_LANDING]        = MARIO_EYES_DEAD,
    [CHAR_ANIM_TRIPLE_JUMP_GROUND_POUND]    = MARIO_EYES_DEAD,
    [CHAR_ANIM_START_GROUND_POUND]          = MARIO_EYES_DEAD,
    [CHAR_ANIM_GROUND_POUND]                = MARIO_EYES_DEAD,
    [CHAR_ANIM_SOFT_BACK_KB]                = MARIO_EYES_DEAD,
    [CHAR_ANIM_SOFT_FRONT_KB]               = MARIO_EYES_DEAD,
    [CHAR_ANIM_BACKWARD_KB]                 = MARIO_EYES_DEAD,
    [CHAR_ANIM_FORWARD_KB]                  = MARIO_EYES_DEAD,
    [CHAR_ANIM_BACKWARDS_WATER_KB]          = MARIO_EYES_DEAD,
    [CHAR_ANIM_WATER_FORWARD_KB]            = MARIO_EYES_DEAD,
    [CHAR_ANIM_BACKWARD_AIR_KB]             = MARIO_EYES_DEAD,
    [CHAR_ANIM_AIR_FORWARD_KB]              = MARIO_EYES_DEAD,
    [CHAR_ANIM_FALL_OVER_BACKWARDS]         = MARIO_EYES_DEAD,
    [CHAR_ANIM_STAR_DANCE]                  = function(m, frame) if frame > 37 then return MARIO_EYES_LOOK_DOWN end end,
    [CHAR_ANIM_WATER_STAR_DANCE]            = function(m, frame) if frame > 68 then return MARIO_EYES_LOOK_DOWN end end,
}
local HANDS_J_MARIO = {
    [CHAR_ANIM_TRIPLE_JUMP_GROUND_POUND]    = function(m, frame) if frame < 7 then return MARIO_HAND_OPEN end end,
    [CHAR_ANIM_START_GROUND_POUND]          = function(m, frame) if frame < 7 then return MARIO_HAND_OPEN end end,
    [CHAR_ANIM_TWIRL]                       = MARIO_HAND_OPEN,
}
local ANIMS_J_LUIGI = {
    [_G.charSelect.CS_ANIM_MENU]            = "luigi_anim_cs_menu",
    [CHAR_ANIM_SINGLE_JUMP]                 = "JLUI_SINGLE_JUMP",
}

local HEALTH_METER_MARIO = {
    label = {
        left = get_texture_info("texture_power_meter_left_side"),
        right = get_texture_info("texture_power_meter_right_side"),
    },
    pie = {
        [1] = get_texture_info("texture_power_meter_one_segments"),
        [2] = get_texture_info("texture_power_meter_two_segments"),
        [3] = get_texture_info("texture_power_meter_three_segments"),
        [4] = get_texture_info("texture_power_meter_four_segments"),
        [5] = get_texture_info("texture_power_meter_five_segments"),
        [6] = get_texture_info("texture_power_meter_six_segments"),
        [7] = get_texture_info("texture_power_meter_seven_segments"),
        [8] = get_texture_info("texture_power_meter_full"),
    }
}
local HEALTH_METER_LUIGI = {
    label = {
        left  = get_texture_info("char_select_luigi_meter_left"),
        right = get_texture_info("char_select_luigi_meter_right"),
    },
    pie = {
        [1] = get_texture_info("char_select_custom_meter_pie1"),
        [2] = get_texture_info("char_select_custom_meter_pie2"),
        [3] = get_texture_info("char_select_custom_meter_pie3"),
        [4] = get_texture_info("char_select_custom_meter_pie4"),
        [5] = get_texture_info("char_select_custom_meter_pie5"),
        [6] = get_texture_info("char_select_custom_meter_pie6"),
        [7] = get_texture_info("char_select_custom_meter_pie7"),
        [8] = get_texture_info("char_select_custom_meter_pie8"),
    }
}

--local CAP_J_MARIO = {
--    normal = smlua_model_util_get_id("cap_normal_geo"),
--    wing = smlua_model_util_get_id("cap_wing_geo"),
--    metal = smlua_model_util_get_id("cap_metal_geo"),
--    metalWing = smlua_model_util_get_id("cap_metal_wing_geo")
--}

if _G.charSelectExists then
    CT_J_MARIO = _G.charSelect.character_add("Mario", {"Let's the go!!!"}, "JerThePear", {r = 255, g = 000, b = 000}, E_MODEL_J_MARIO, CT_MARIO, TEX_J_MARIO)
end

local CSloaded = false
local function on_character_select_load()
    for i = 1, #PALETTES_MARIO do
        _G.charSelect.character_add_palette_preset(E_MODEL_J_MARIO, PALETTES_MARIO[i], PALETTES_MARIO[i].name)
	end
    _G.charSelect.character_add_voice(              E_MODEL_J_MARIO, VOICETABLE_J_MARIO_SM63)
    _G.charSelect.character_add_animations(         E_MODEL_J_MARIO, ANIMS_J_MARIO, EYES_J_MARIO, HANDS_J_MARIO)
    _G.charSelect.character_add_health_meter(       CT_J_MARIO, HEALTH_METER_MARIO)
    _G.charSelect.character_add_celebration_star(   E_MODEL_J_MARIO, E_MODEL_SHINE_SPRITE, TEX_SHINE_SPRITE)
    --_G.charSelect.character_add_caps(               E_MODEL_J_MARIO, CAP_J_MARIO)

    CSloaded = true
end

local function on_character_sound(m, sound)
    if not CSloaded then return end
    if _G.charSelect.character_get_voice(m) == VOICETABLE_J_MARIO_SM63 then return _G.charSelect.voice.sound(m, sound) end
    --if _G.charSelect.character_get_voice(m) == VOICETABLE_J_LUIGI_SM63 then return _G.charSelect.voice.sound(m, sound) end
end

local function on_character_snore(m)
    if not CSloaded then return end
    if _G.charSelect.character_get_voice(m) == VOICETABLE_J_MARIO_SM63 then return _G.charSelect.voice.snore(m) end
    --if _G.charSelect.character_get_voice(m) == VOICETABLE_J_LUIGI_SM63 then return _G.charSelect.voice.snore(m) end
end

hook_event(HOOK_ON_MODS_LOADED, on_character_select_load)
hook_event(HOOK_CHARACTER_SOUND, on_character_sound)
hook_event(HOOK_MARIO_UPDATE, on_character_snore)