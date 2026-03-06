for _, mods in pairs(gActiveMods) do if mods.incompatible == "romhack" then return end end

local E_MODEL_63_STARCOIN = smlua_model_util_get_id("jers_63_star_oin_geo")
local SOUND_JMAR_STARCOIN = audio_sample_load("JMAR_SOUND_STARCOIN.ogg")

local starCoinLocations = {
    [LEVEL_BOB]             = {x = 360, y = 2300, z = -3715,   area = 1, flag = "STARCOIN_FLAG_BOB"},
    [LEVEL_WF]              = {x = -250, y = 3200, z = 1800,   area = 1, flag = "STARCOIN_FLAG_WF"},
    [LEVEL_JRB]             = {x = 5150, y = -1500, z = -5120, area = 1, flag = "STARCOIN_FLAG_JRB"},
    [LEVEL_CCM]             = {x = 4330, y = -2500, z = -660,  area = 1, flag = "STARCOIN_FLAG_CCM"},
    [LEVEL_BBH]             = {x = 1000, y = -1600, z = 1800,  area = 1, flag = "STARCOIN_FLAG_BBH"},
    [LEVEL_HMC]             = {x = 6650, y = -300, z = -1600,  area = 1, flag = "STARCOIN_FLAG_HMC"},
    [LEVEL_LLL]             = {x = 0, y = 4200, z = -2460,     area = 2, flag = "STARCOIN_FLAG_LLL"},
    [LEVEL_SSL]             = {x = -1800, y = 3500, z = 1400,  area = 2, flag = "STARCOIN_FLAG_SSL"},
    [LEVEL_DDD]             = {x = 2000, y = 1200, z = -2100,  area = 2, flag = "STARCOIN_FLAG_DDD"},
    [LEVEL_SL]              = {x = -1700, y = 300, z = -300,   area = 2, flag = "STARCOIN_FLAG_SL"},
    [LEVEL_WDW]             = {x = -1000, y = 5000, z = 1300,  area = 1, flag = "STARCOIN_FLAG_WDW"},
    [LEVEL_TTM]             = {x = 2370, y = -2400, z = 3900,  area = 1, flag = "STARCOIN_FLAG_TTM"},
    [LEVEL_THI]             = {x = -5500, y = 500, z = -6000,  area = 1, flag = "STARCOIN_FLAG_THI"},
    [LEVEL_TTC]             = {x = 780, y = 3300, z = 160,     area = 1, flag = "STARCOIN_FLAG_TTC"},
    [LEVEL_RR]              = {x = 3550, y = 6000, z = -2340,  area = 1, flag = "STARCOIN_FLAG_RR"},
    [LEVEL_BITDW]           = {x = -4400, y = 570, z = -520,   area = 1, flag = "STARCOIN_FLAG_BITDW"}, -- Bowser Levels vvv
    [LEVEL_BITFS]           = {x = 4160, y = 3800, z = 80,     area = 1, flag = "STARCOIN_FLAG_BITFS"},
    [LEVEL_BITS]            = {x = 6460, y = 5200, z = -1940,  area = 1, flag = "STARCOIN_FLAG_BITS"},
    [LEVEL_PSS]             = {x = 370, y = -300, z = -5010,   area = 1, flag = "STARCOIN_FLAG_PSS"}, -- Secret Levels vvv
    [LEVEL_SA]              = {x = -2660, y = -300, z = -2670, area = 1, flag = "STARCOIN_FLAG_SA"},
    [LEVEL_WMOTR]           = {x = -4450, y = -250, z = 200,   area = 1, flag = "STARCOIN_FLAG_WMOTR"},
    [LEVEL_TOTWC]           = {x = -4130, y = -1600, z = 4800, area = 1, flag = "STARCOIN_FLAG_TOTWC"}, -- Cap Switch Levels vvv
    [LEVEL_COTMC]           = {x = 0, y = 2000, z = -4500,     area = 1, flag = "STARCOIN_FLAG_COTMC"},
    [LEVEL_VCUTM]           = {x = -2650, y = 1000, z = -1600, area = 1, flag = "STARCOIN_FLAG_VCUTM"},
    [LEVEL_CASTLE_GROUNDS]  = {x = -3700, y = 2500, z = -7000, area = 1, flag = "STARCOIN_FLAG_CASTLE"}, -- Castle vvv
    [LEVEL_CASTLE_COURTYARD]= {x = 0, y = 1200, z = 400,       area = 1, flag = "STARCOIN_FLAG_COURT"},
    --[6]             = {x = 0, y = 0, z = 0}, -- Castle Main Floor
}

function starcoin_63_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oFaceAngleYaw = 0
    o.oFaceAnglePitch = 0
    o.oFaceAngleRoll = 0
    o.oAction = 0
    o.oOpacity = 255
    o.header.gfx.shadowInvisible = false
    o.hitboxRadius = 100
    o.hitboxHeight = 100
    obj_scale(o, 1)
    network_init_object(o, true, {"oAction"})
end
function starcoin_63_loop(o)
    local m = nearest_mario_state_to_object(o)
    local npl = gNetworkPlayers[0].currLevelNum

    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x500

    if o.oAction == 0 then
        local max = 100
        local min = 0 - max
        local spawnX = o.oPosX + math.random(min, max)
        local spawnY = o.oPosY + math.random(min, max) + (max/2)
        local spawnZ = o.oPosZ + math.random(min, max)
        spawn_non_sync_object(id_bhvSparkle, E_MODEL_SPARKLES_ANIMATION, spawnX, spawnY, spawnZ, nil)
        if obj_check_hitbox_overlap(m.marioObj, o) then --or (gGlobalSyncTable.collectedStarCoins63 & (o.oBehParams >> 8) ~= 0) then
            o.oAction = 1
            audio_sample_play(SOUND_JMAR_STARCOIN, {x = o.oPosX, y = o.oPosY, z = o.oPosZ}, 1)
            spawn_mist_particles()
            --djui_chat_message_create("starcoin get!")
            save_starcoin(starCoinLocations[npl].flag)
        end
    end

    if o.oAction == 1 then
        o.oFaceAngleYaw = o.oFaceAngleYaw * 1.03
        o.oOpacity = o.oOpacity * 0.92
        o.header.gfx.shadowInvisible = true
        if o.oOpacity < 5 then
            obj_mark_for_deletion(o)
        end
    end
end
id_bhvStarCoin63 = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, true, starcoin_63_init, starcoin_63_loop, "bhv63StarOin")

function save_starcoin(flag) -- will be called with a flag input
		mod_storage_save_number(flag, 1)
        --djui_chat_message_create("starcoin SAVED")
end

local function on_packet_recieve(data)
	if data.id == PACKET_63_STARCOIN then
		save_starcoin(data.flag)
	end
end
hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_recieve)

local function level_init()
    local npl = gNetworkPlayers[0].currLevelNum
    local npa = gNetworkPlayers[0].currAreaIndex
    local m = gMarioStates[0]
    local starcoin = starCoinLocations[npl]

    if starcoin ~= nil then
        if starcoin.area == npa and obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvStarCoin63) == nil and mod_storage_load_number(starcoin.flag) == 0 then
            spawn_sync_object(id_bhvStarCoin63, E_MODEL_63_STARCOIN, starcoin.x, starcoin.y, starcoin.z, nil)
        end
    end
end
hook_event(HOOK_ON_SYNC_VALID, level_init)

local function count_star_coins()
    local collectedCount = 0
    for i = 0, 255 do
        if starCoinLocations[i] ~= nil then
            collectedCount = collectedCount + mod_storage_load_number(starCoinLocations[i].flag)
        end
    end
    return collectedCount
end

local function reset_starcoins(msg)
	--if network_is_server() then
		for i = 0, 255 do
            if starCoinLocations[i] ~= nil then
                mod_storage_save_number(starCoinLocations[i].flag, 0)
            end
        end
		djui_chat_message_create("Star coins reset!")
		return true
	--end
end
hook_chat_command("63resetstarcoins", "Reset all star coins collected.", reset_starcoins)

local TEX_STARCOIN = get_texture_info("jmar_star_coin")

local function star_coin_counter()
    if gNetworkPlayers[0].currActNum == 99
    or gMarioStates[0].action == ACT_INTRO_CUTSCENE
    or hud_is_hidden()
    or obj_get_first_with_behavior_id(id_bhvActSelector) then return end

    local m = gMarioStates[0]

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_HUD)
    local width = djui_hud_get_screen_width()

    djui_hud_render_texture(TEX_STARCOIN, width - 76, 35, 1, 1)
    djui_hud_print_text("@", width - 60, 34, 1)
    djui_hud_print_text(string.format("%.0f", count_star_coins()), width - 46, 34, 1)
end
hook_event(HOOK_ON_HUD_RENDER_BEHIND, star_coin_counter)