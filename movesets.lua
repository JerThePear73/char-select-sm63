local ACT_63_ROLLOUT = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
local ACT_63_SPIN_AIR = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR)
local ACT_63_SPIN_GROUND = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING)
local ACT_63_SWIM_IDLE = allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_MOVING | ACT_FLAG_WATER_OR_TEXT | ACT_FLAG_SWIMMING)
local ACT_63_SWIM_STROKE = allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_MOVING | ACT_FLAG_WATER_OR_TEXT | ACT_FLAG_SWIMMING)
local ACT_63_HOVER_FALLBACK = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
local ACT_63_START_CROUCH = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING | ACT_FLAG_SHORT_HITBOX)
local ACT_63_EXIT_CROUCH = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING)
local ACT_63_CROUCH = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_MOVING)
local ACT_63_BACKFLIP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
local ACT_127_GP_JUMP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)

local gExtraStates = {}
for i = 0, MAX_PLAYERS - 1 do
    gExtraStates[i] = {}
    local e = gExtraStates[i]
    e.gfxX = 0
    e.gfxY = 0
    e.gfxZ = 0
    gPlayerSyncTable[i].water = 0
    e.pressure = 0
    e.fluddSoundLoop = false
    e.prevVel = 0
    e.prevLives = 0
end

local function convert_s16(a)
    return (a + 0x8000) % 0x10000 - 0x8000
end

function evilswag_fludd_switch(node, matStackIndex)
    local asSwitchNode = cast_graph_node(node)
    local m = geo_get_mario_state()
    local s = gPlayerSyncTable[m.playerIndex]
    local toNode = 0
    if s.water > 0 then
        toNode = 1
    else
        toNode = 0
    end
    asSwitchNode.selectedCase = toNode
end

function evilswag_fludd_nozzle(node, matStackIndex)
    if node.hookProcess ~= 1 then return end

    local camera = geo_get_current_camera()
    globalPosLeftNozzle = get_pos_from_transform_mtx(
        gVec3fZero(),
        gMatStack[matStackIndex],
        camera.matrixPtr
    )
end
hook_event(HOOK_ON_GEO_PROCESS, evilswag_fludd_nozzle)

local stepFrame = 5
local waterMax = 100
local hoverMax = 75

local SOUND_FLUDD_PICKUP    = audio_sample_load("JMAR_SOUND_FLUDD_PICKUP.ogg")
local SOUND_FLUDD_SPRAY     = audio_stream_load("JMAR_SOUND_FLUDD_SPRAY.ogg")

local function pause_check()
    local m = gMarioStates[0]

    if m.action == ACT_START_SLEEPING or m.action == ACT_SLEEPING or m.actionTimer < 80 and
        (m.action == ACT_STAR_DANCE_EXIT or m.action == ACT_STAR_DANCE_NO_EXIT or m.action == ACT_STAR_DANCE_WATER) then
        return 0.2
    end

    if is_game_paused() or _G.charSelect.is_menu_open() then
        return 0
    end

    return 1
end

local function do_swimming_physics(m)
    local intendedSpeed = 0
    local intendedY = -5
    local speed = m.forwardVel
    local turnRate = 0x100 * math.abs(20/m.forwardVel)
    local rate = 0.03

    m.marioBodyState.handState = MARIO_HAND_OPEN

    if m.actionTimer <= 1 then
        m.faceAngle.x = 0
        m.faceAngle.z = 0
    end

    if m.input & INPUT_NONZERO_ANALOG ~= 0 then
        intendedSpeed = m.intendedMag*0.7 - (math.abs(convert_s16(m.intendedYaw - m.faceAngle.y))/1000)
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, turnRate, turnRate)
    end

    if m.pos.y == m.floorHeight then
        rate = 0.1
    end

    m.vel.y = math.lerp(m.vel.y, intendedY, 0.1)
    speed = math.lerp(speed, intendedSpeed, rate)
    mario_set_forward_vel(m, speed)

    local stepResult = perform_water_step(m)
end

local function fludd_particles(m)
    spawn_non_sync_object(id_bhvSnowParticleSpawner,
                            E_MODEL_NONE,
                            globalPosLeftNozzle.x,
                            globalPosLeftNozzle.y,
                            globalPosLeftNozzle.z,
                        nil)
end

local function do_fludd_hover(m)
    local e = gExtraStates[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]

    if m.pos.y == m.floorHeight and m.floor.normal.y > 0.8 then
        m.pos.y = m.pos.y + 10
        set_mario_action(m, ACT_63_HOVER_FALLBACK, 0)
    end

    fludd_particles(m)
    s.water = s.water - 0.05
    e.pressure = e.pressure - 1
    m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x400, 0x400)
    m.vel.y = approach_f32(m.vel.y, 8, 8, -1)
    if m.forwardVel > 18 then
        m.forwardVel = m.forwardVel - 2
    end
end

local function do_fludd_slide(m)
    local e = gExtraStates[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]

    if m.forwardVel < 0 then return end

    if m.action == ACT_DIVE_SLIDE then
        if m.forwardVel < 60 and m.forwardVel > 0 then
            m.slideVelZ = m.vel.z * 1.1
            m.slideVelX = m.vel.x * 1.1
        end
    else
        m.forwardVel = m.forwardVel + 1
    end

    fludd_particles(m)
    s.water = s.water - 0.05
    e.fluddSoundLoop = true
end

local function do_fludd_underwater(m)
    local e = gExtraStates[m.playerIndex]

    fludd_particles(m)
    m.vel.y = m.vel.y + 3
end

-- CUSTOM ACTIONS --

local function act_63_rollout(m)
    local e = gExtraStates[m.playerIndex]

    if m.actionTimer == 0 then
        play_character_sound(m, CHAR_SOUND_YAH_WAH_HOO)
        m.vel.y = 30 + math.abs(m.forwardVel/3)
        e.gfxX = -0x10000
    elseif m.actionTimer == 1 and m.prevAction == ACT_63_START_CROUCH then
        play_character_sound(m, CHAR_SOUND_YAH_WAH_HOO)
        m.vel.y = 35 + math.abs(m.forwardVel/3)
        e.gfxX = -0x10000
    end

    local stepResult = common_air_action_step(m, ACT_JUMP_LAND, MARIO_ANIM_SINGLE_JUMP, AIR_STEP_CHECK_LEDGE_GRAB)

    if m.actionTimer == 6 then -- spin sound
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    end

    if m.input & INPUT_B_PRESSED ~= 0 and m.actionTimer > 4 then
        return set_mario_action(m, ACT_DIVE, 0)
    elseif m.input & INPUT_Z_PRESSED ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    e.gfxX = math.lerp(e.gfxX, 0, 0.3)
    m.marioObj.header.gfx.angle.x = e.gfxX

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_63_ROLLOUT, act_63_rollout)

local function act_63_spin_air(m)
    local e = gExtraStates[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]
    local spin = 0x2000

    if m.actionTimer <= 1 then
        if m.prevAction == ACT_TWIRLING then
            m.vel.y = 60
        elseif m.prevAction ~= ACT_63_SPIN_AIR then
            m.vel.y = 20
        end
    end

    local stepResult = common_air_action_step(m, ACT_FREEFALL_LAND, MARIO_ANIM_TWIRL, AIR_STEP_NONE)
    if stepResult == AIR_STEP_HIT_WALL and m.wall ~= nil then
        if m.wall.object ~= nil and m.wall.object.oInteractType & (INTERACT_BREAKABLE) ~= 0 then
            m.wall.object.oInteractStatus = INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
            m.action = ACT_63_SPIN_AIR
        end
    elseif stepResult == AIR_STEP_LANDED and m.controller.buttonDown & X_BUTTON ~= 0 then
        play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING)
        return set_mario_action(m, ACT_63_SPIN_GROUND, 0)
    end
    --if m.prevAction == ACT_TWIRLING then
    --    m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x300, 0x300)
    --end
    if m.controller.buttonDown & X_BUTTON ~= 0 or m.actionTimer < 15 then
        spin = 0x3000
        m.vel.y = m.vel.y + 0.5
    elseif m.input & INPUT_B_PRESSED ~= 0 then
        return set_mario_action(m, ACT_DIVE, 0)
    elseif m.input & INPUT_Z_PRESSED ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    elseif m.controller.buttonDown & L_TRIG ~= 0 and s.water > 0 and e.pressure > 0 then
        set_mario_action(m, ACT_63_HOVER_FALLBACK, 0)
    end

    m.vel.y = m.vel.y + 0.5
    m.peakHeight = m.pos.y
    e.gfxY = e.gfxY + spin
    m.marioObj.header.gfx.angle.y = e.gfxY

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_63_SPIN_AIR, act_63_spin_air)

local function act_63_spin_ground(m)
    local e = gExtraStates[m.playerIndex]

    if should_begin_sliding(m) ~= 0 then
		set_mario_action(m, ACT_BEGIN_SLIDING, 0)
	end

    -- speed
    e.prevVel = e.prevVel * 0.9
    mario_set_forward_vel(m, e.prevVel)
    if e.prevVel > 10 then
        m.particleFlags = m.particleFlags | PARTICLE_DUST
    end

    local stepResult = perform_ground_step(m)
    if stepResult == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    set_mario_animation(m, MARIO_ANIM_TWIRL)

    if m.controller.buttonDown & X_BUTTON == 0 and m.actionTimer > 15 then
        return set_mario_action(m, ACT_IDLE, 0)
    end

    e.gfxY = e.gfxY + 0x3000
    m.marioObj.header.gfx.angle.y = e.gfxY

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_63_SPIN_GROUND, act_63_spin_ground, INT_KICK)

local function act_63_swim_idle(m)
    local anim = MARIO_ANIM_WATER_IDLE
    local accel = 0x16000

    if m.actionTimer == 0 and m.prevAction ~= ACT_63_SWIM_STROKE then
        m.forwardVel = m.forwardVel * 3
    end

    do_swimming_physics(m)

    if m.input & INPUT_A_PRESSED ~= 0 and m.actionTimer > 5 then
        return set_mario_action(m, ACT_63_SWIM_STROKE, 0)
    end

    if m.pos.y < m.floorHeight + 10 then
        anim = MARIO_ANIM_WALKING
        accel = m.forwardVel / 4 * 0x10000
        m.marioBodyState.handState = MARIO_HAND_FISTS
    elseif m.input & INPUT_Z_DOWN ~= 0 then
        m.vel.y = m.vel.y - 1.5
    end

    set_mario_anim_with_accel(m, anim, accel)

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_63_SWIM_IDLE, act_63_swim_idle)

local function act_63_swim_stroke(m)
    local anim = MARIO_ANIM_SWIM_PART1
    local accel = 0x16000
    if m.actionTimer > 17 then
        anim = MARIO_ANIM_WATER_ACTION_END
        accel = 0x32000
    elseif m.actionTimer > 10 then
        anim = MARIO_ANIM_SWIM_PART2
    end

    do_swimming_physics(m)

    m.marioBodyState.handState = MARIO_HAND_OPEN

    if m.actionTimer == 0 then
        play_sound(SOUND_ACTION_SWIM_FAST, m.marioObj.header.gfx.cameraToObject)
        m.marioObj.header.gfx.animInfo.animID = -1
    end

    set_mario_anim_with_accel(m, anim, accel)

    m.vel.y = 23 - m.actionTimer

    if m.input & INPUT_A_PRESSED ~= 0 and m.actionTimer > 5 then
        return set_mario_action(m, ACT_63_SWIM_STROKE, 0)
    end

    if m.actionTimer > 25 then
        return set_mario_action(m, ACT_63_SWIM_IDLE, 0)
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_63_SWIM_STROKE, act_63_swim_stroke)

local function act_63_hover_fallback(m)
    local e = gExtraStates[m.playerIndex]

    local stepResult = common_air_action_step(m, ACT_FREEFALL_LAND, MARIO_ANIM_TRIPLE_JUMP, AIR_STEP_CHECK_LEDGE_GRAB)

    m.marioObj.header.gfx.animInfo.animFrame = 35
    m.marioObj.header.gfx.animInfo.animAccel = 0
    m.marioObj.header.gfx.pos.y = m.pos.y + 30

    if m.input & INPUT_B_PRESSED ~= 0 and m.actionTimer > 4 then
        return set_mario_action(m, ACT_DIVE, 0)
    elseif m.input & INPUT_Z_PRESSED ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    elseif m.controller.buttonDown & X_BUTTON ~= 0 and m.actionTimer > 15 then
        return set_mario_action(m, ACT_63_SPIN_AIR, 0)
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_63_HOVER_FALLBACK, act_63_hover_fallback)

local function act_63_start_crouch(m)
    local e = gExtraStates[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]

    if should_begin_sliding(m) ~= 0 then
		set_mario_action(m, ACT_STOMACH_SLIDE, 0)
	end

    if m.actionTimer == 0 then
        e.prevVel = m.forwardVel * 1.1
    end

    -- speed
    if m.controller.buttonDown & L_TRIG ~= 0 and s.water > 0 and m.forwardVel < 60 then
        e.prevVel = e.prevVel + 4
    else
        e.prevVel = e.prevVel * 0.95
    end
    mario_set_forward_vel(m, e.prevVel)
    if m.forwardVel > 10 then
        m.particleFlags = m.particleFlags | PARTICLE_DUST
    end
    if m.forwardVel > 0 then
        play_sound(SOUND_MOVING_TERRAIN_SLIDE + m.terrainSoundAddend, m.marioObj.header.gfx.cameraToObject)
    end

    m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x200, 0x200)

    local stepResult = perform_ground_step(m)
    if stepResult == GROUND_STEP_LEFT_GROUND then
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    set_mario_anim_with_accel(m, MARIO_ANIM_DIVE, 0x20000)

    if m.input & INPUT_A_PRESSED ~= 0 then
        if m.forwardVel == 0 then
            return set_mario_action(m, ACT_63_BACKFLIP, 0)
        else
            set_mario_action(m, ACT_63_ROLLOUT, 0)
            m.pos.y = m.pos.y + 20
            local initSpeed = 20
            local cap = 45
            if m.forwardVel > 0 then
                if m.forwardVel < (cap - initSpeed) then
                    m.forwardVel = m.forwardVel + initSpeed
                else
                    m.forwardVel = cap
                end
            end
        end
    elseif m.input & INPUT_B_PRESSED ~= 0 then
        if m.forwardVel < 45 then
            e.gfxX = -0x10000
        else
            e.gfxX = -0x20000
        end
        e.gfxY = 100
        return set_mario_action(m, ACT_SLIDE_KICK, 0)
    elseif m.actionTimer > 4 then
        if m.input & INPUT_Z_DOWN == 0 and m.forwardVel == 0 then
            return set_mario_action(m, ACT_63_EXIT_CROUCH, 0)
        elseif m.actionTimer > 15 then
            if m.forwardVel == 0 then
                set_mario_action(m, ACT_63_CROUCH, 0)
            else
                set_mario_action(m, ACT_DIVE_SLIDE, 0)
            end
        end
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_63_START_CROUCH, act_63_start_crouch)

local function act_63_crouch(m)
    local e = gExtraStates[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]

    if should_begin_sliding(m) ~= 0 then
		set_mario_action(m, ACT_STOMACH_SLIDE, 0)
	end

    set_mario_animation(m, MARIO_ANIM_DIVE)

    local stepResult = perform_ground_step(m)

    if m.input & INPUT_Z_DOWN == 0 then
        return set_mario_action(m, ACT_63_EXIT_CROUCH, 0)
    elseif m.input & INPUT_A_PRESSED ~= 0 then
        return set_mario_action(m, ACT_63_BACKFLIP, 0)
    elseif m.controller.buttonDown & L_TRIG ~= 0 and s.water > 0 then
        m.action = ACT_63_START_CROUCH
    end

    return 0
end
hook_mario_action(ACT_63_CROUCH, act_63_crouch)

local function act_63_exit_crouch(m)
    set_mario_anim_with_accel(m, 90, 0x35000)

    local stepResult = perform_ground_step(m)

    if m.actionTimer > 10 then
        return set_mario_action(m, ACT_IDLE, 0)
    end

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_63_EXIT_CROUCH, act_63_exit_crouch)

local function act_63_backflip(m)
    local e = gExtraStates[m.playerIndex]

    if m.actionTimer == 0 then
        play_character_sound(m, CHAR_SOUND_YAH_WAH_HOO)
        m.vel.y = 70
        m.forwardVel = -40
        e.gfxX = 0x13000
    end
    local stepResult = common_air_action_step(m, ACT_JUMP_LAND, MARIO_ANIM_SINGLE_JUMP, AIR_STEP_CHECK_LEDGE_GRAB)

    if m.actionTimer == 8 then -- spin sound
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    end

    if m.input & INPUT_B_PRESSED ~= 0 and m.actionTimer > 4 then
        return set_mario_action(m, ACT_DIVE, 0)
    elseif m.input & INPUT_Z_PRESSED ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    e.gfxX = math.lerp(e.gfxX, 0, 0.2)
    m.marioObj.header.gfx.angle.x = e.gfxX

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_63_BACKFLIP, act_63_backflip)

local function act_127_gp_jump(m)
    local e = gExtraStates[m.playerIndex]

    if m.actionTimer == 0 then
        play_character_sound(m, CHAR_SOUND_YAHOO)
        m.vel.y = 60
        if m.actionArg == 0 then
            e.gfxY = 0x15000
        else
            e.gfxY = -0x15000
        end
    end
    local stepResult = common_air_action_step(m, ACT_DOUBLE_JUMP_LAND, MARIO_ANIM_DOUBLE_JUMP_RISE, AIR_STEP_CHECK_LEDGE_GRAB)

    if m.input & INPUT_B_PRESSED ~= 0 and m.actionTimer > 8 then
        return set_mario_action(m, ACT_DIVE, 0)
    elseif m.input & INPUT_Z_PRESSED ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    if m.vel.y > 40 then
        m.particleFlags = m.particleFlags | PARTICLE_DUST
    end

    e.gfxY = e.gfxY * 0.8
    m.marioObj.header.gfx.angle.y = m.faceAngle.y + e.gfxY

    m.actionTimer = m.actionTimer + 1
    return 0
end
hook_mario_action(ACT_127_GP_JUMP, act_127_gp_jump)

-- UPDATES --

-- Mario
local spinActions = {
    -- air
    [ACT_JUMP] = true,
    [ACT_DOUBLE_JUMP] = true,
    [ACT_TRIPLE_JUMP] = true,
    [ACT_63_ROLLOUT] = true,
    [ACT_BACKFLIP] = true,
    [ACT_SIDE_FLIP] = true,
    [ACT_WALL_KICK_AIR] = true,
    [ACT_FREEFALL] = true,
    --[ACT_63_HOVER_FALLBACK] = true,
    [ACT_63_BACKFLIP] = true,
    [ACT_127_GP_JUMP] = true,
    --[ACT_LONG_JUMP] = true,
    -- ground
    [ACT_IDLE] = true,
    [ACT_WALKING] = true,
    [ACT_BRAKING] = true,
}
local fluddActions = {
    -- air
    [ACT_JUMP] = true,
    [ACT_DOUBLE_JUMP] = true,
    [ACT_TRIPLE_JUMP] = true,
    [ACT_63_ROLLOUT] = true,
    [ACT_BACKFLIP] = true,
    [ACT_SIDE_FLIP] = true,
    [ACT_WALL_KICK_AIR] = true,
    [ACT_FREEFALL] = true,
    [ACT_63_HOVER_FALLBACK] = true,
    [ACT_63_BACKFLIP] = true,
    [ACT_127_GP_JUMP] = true,
    -- ground
    [ACT_IDLE] = true,
    [ACT_WALKING] = true,
    [ACT_BRAKING] = true,
    -- water
    [ACT_63_SWIM_IDLE] = true,
}
local fluddDiveActions = {
    [ACT_DIVE] = true,
    [ACT_DIVE_SLIDE] = true,
    [ACT_63_START_CROUCH] = true,
    [ACT_63_CROUCH] = true,
}

local function mario_update(m)
    local e = gExtraStates[m.playerIndex]
    local s = gPlayerSyncTable[m.playerIndex]

    -- gp cancel
    if m.action == ACT_GROUND_POUND then
        if (m.input & INPUT_B_PRESSED) ~= 0 then
            m.faceAngle.y = m.intendedYaw
            m.forwardVel = 20
            m.vel.y = 20
            set_mario_action(m, ACT_DIVE, 0)
            play_sound(SOUND_GENERAL_SWISH_WATER, m.marioObj.header.gfx.cameraToObject)
        end
        m.marioObj.header.gfx.angle.y = m.faceAngle.y
    end
    -- gp jump
    if m.action == ACT_GROUND_POUND_LAND and m.input & INPUT_A_PRESSED ~= 0 then
        set_mario_action(m, ACT_127_GP_JUMP, math.random(0, 1))
        m.pos.y = m.floorHeight + 10
    end
    if m.action == ACT_DOUBLE_JUMP and m.prevAction == ACT_GROUND_POUND_LAND and m.marioObj.header.gfx.animInfo.animFrame == -1 and m.vel.y == 63 then
        play_character_sound(m, CHAR_SOUND_YAHOO)
    end
    -- metal cap can move underwater airborne
    if m.intendedMag ~= 0 and m.action == ACT_METAL_WATER_FALLING then
        m.forwardVel = approach_f32(m.forwardVel, m.intendedMag - 12, 2, 1)
        m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x200, 0x200)
    end
    -- walking
    if m.action == ACT_WALKING and m.pos.y > m.waterLevel then
        if get_global_timer() % stepFrame == 0 and m.forwardVel > 29 then
            m.particleFlags = m.particleFlags | PARTICLE_DUST
        end

        if m.marioObj.header.gfx.animInfo.animID == MARIO_ANIM_RUNNING then
            m.marioBodyState.torsoAngle.z = 0

            local dYaw = convert_s16(m.faceAngle.y - m.intendedYaw)
            local val04 = (dYaw * m.forwardVel / 12)
            local max = 0x1800

            if val04 > max then
                val04 = max;
            end
            if val04 < -max then
                val04 = -max;
            end

            e.gfxZ = approach_s32(e.gfxZ, val04, 0x200, 0x200)

            m.marioObj.header.gfx.angle.z = e.gfxZ

            if e.gfxZ > 5000 then
                m.marioBodyState.eyeState = MARIO_EYES_LOOK_LEFT
            elseif e.gfxZ < -5000 then
                m.marioBodyState.eyeState = MARIO_EYES_LOOK_RIGHT
            end
        end
    end
    -- spin
    if (spinActions[m.action] and m.controller.buttonPressed & X_BUTTON ~= 0) then
        e.prevVel = m.forwardVel
        if m.pos.y == m.floorHeight then
            set_mario_action(m, ACT_63_SPIN_GROUND, 0)
        elseif m.vel.y < 0 or m.controller.buttonDown & L_TRIG ~= 0 then
            set_mario_action(m, ACT_63_SPIN_AIR, 0)
        end
    end
    if m.action == ACT_TWIRLING then
        set_mario_action(m, ACT_63_SPIN_AIR, 0)
    end

    --wing cap
    if m.action == ACT_DIVE and m.prevAction ~= ACT_GROUND_POUND and m.flags & MARIO_WING_CAP ~= 0 and m.vel.y < 0 and m.pos.y > (m.floorHeight + 100) then
        m.action = ACT_FLYING
        e.gfxZ = 0x10000
    end
    if m.action == ACT_FLYING then
        e.gfxZ = math.lerp(e.gfxZ, 0, 0.1)
        m.marioObj.header.gfx.angle.z = m.marioObj.header.gfx.angle.z + e.gfxZ
    end

    -- fludd
    if m.controller.buttonDown & L_TRIG ~= 0 and s.water > 0 and e.pressure > 0 and (fluddActions[m.action] or (fluddDiveActions[m.action] and m.forwardVel > 0)) then
        if fluddDiveActions[m.action] then
            do_fludd_slide(m)
        elseif m.action == ACT_63_SWIM_IDLE then
            do_fludd_underwater(m)
        else
            do_fludd_hover(m)
        end
        e.fluddSoundLoop = true
    else
        e.fluddSoundLoop = false
    end
    if s.water < 0 then
        s.water = 0
    elseif s.water > waterMax then
        s.water = waterMax
    elseif m.pos.y < m.waterLevel and s.water > 0 then
        s.water = s.water + 0.5
        e.pressure = hoverMax
    end
    if e.pressure < 0 then
        e.pressure = 0
    elseif m.pos.y == m.floorHeight then
        e.pressure = hoverMax
    end
    -- swimming
    if m.pos.y > m.waterLevel - 150 and m.input & INPUT_A_PRESSED ~= 0 and (m.action == ACT_63_SWIM_IDLE or m.action == ACT_63_SWIM_STROKE) then
        m.pos.y = m.pos.y + 50
        return set_mario_action(m, ACT_JUMP, 0)
    end
    --lives
    if e.prevLives > m.numLives then
        s.water = 0
    end
    e.prevLives = m.numLives
    -- slide kick
    if m.action == ACT_SLIDE_KICK then
        e.gfxX = e.gfxX * 0.8
        e.gfxY = e.gfxY * 0.8
        m.marioObj.header.gfx.angle.x = e.gfxX
        m.marioObj.header.gfx.pos.y = m.pos.y + e.gfxY
        m.marioObj.header.gfx.animInfo.animFrame = 7
        m.marioObj.header.gfx.animInfo.animAccel = 0
    end
end

local function mario_set_action(m)
    local e = gExtraStates[m.playerIndex]

    -- twirl landing momentum
    if m.action == ACT_TWIRL_LAND and m.input & INPUT_NONZERO_ANALOG ~= 0 then
        set_mario_action(m, ACT_WALKING, 0)
    end
    -- rollout
    if (m.action == ACT_FORWARD_ROLLOUT or
        m.action == ACT_BACKWARD_ROLLOUT) and
        (m.prevAction == ACT_DIVE_SLIDE or m.prevAction == ACT_SLIDE_KICK_SLIDE) then
        set_mario_action(m, ACT_63_ROLLOUT, 0)
    end
    -- dive
    if m.action == ACT_DIVE then
        m.forwardVel = m.forwardVel + 5
    end
    -- crouch
    if m.action == ACT_CROUCH_SLIDE 
    or m.action == ACT_START_CROUCHING then
        set_mario_action(m, ACT_63_START_CROUCH, 0)
    end

    if m.action == ACT_SLIDE_KICK then
        play_sound(SOUND_GENERAL_SWISH_WATER, m.marioObj.header.gfx.cameraToObject)
        m.vel.y = 20
    else
        e.gfxX = 0
        e.gfxY = 0
        e.gfxZ = 0
    end
end

local function mario_before_set_action(m, act)
    local e = gExtraStates[m.playerIndex]
    -- remove kick
    if act == ACT_JUMP_KICK and m.pos.y > (m.floorHeight + 50) then
        return ACT_DIVE
    -- swimming
    elseif (act == ACT_WATER_PLUNGE or act == ACT_WATER_IDLE) and m.flags & MARIO_METAL_CAP == 0 then
        if m.action ~= ACT_BACKWARD_WATER_KB and m.action ~= ACT_FORWARD_WATER_KB then
            play_sound(SOUND_OBJ_DIVING_INTO_WATER, m.marioObj.header.gfx.cameraToObject)
            m.particleFlags = m.particleFlags | PARTICLE_WATER_SPLASH
        end
        return ACT_63_SWIM_IDLE
    --backflip
    elseif act == ACT_BACKFLIP then
        return ACT_63_BACKFLIP
    -- crouch
    elseif act == ACT_STOMACH_SLIDE_STOP then
        return ACT_63_CROUCH
    -- flying fix; idk if this is necessary cuz of custom twirling
    elseif act == ACT_FLYING then
        m.marioObj.header.gfx.angle.y = m.faceAngle.y
    end
end

local function mario_before_step(m)
    if m.action == ACT_GROUND_POUND then
        local sidewaysSpeed = 0
        local forwardSpeed = 0
        if m.input & INPUT_NONZERO_ANALOG ~= 0 and m.vel.y < -50 then
            intendedDYaw = m.intendedYaw - m.faceAngle.y;
            intendedMag = m.intendedMag / 32;

            mario_set_forward_vel(m, intendedMag * coss(intendedDYaw) * 10.0);
            sidewaysSpeed = intendedMag * sins(intendedDYaw) * 10.0;

            m.slideVelX = forwardSpeed * sins(m.faceAngle.y);
            m.slideVelZ = forwardSpeed * coss(m.faceAngle.y);

            m.slideVelX = sidewaysSpeed * sins(m.faceAngle.y + 0x4000);
            m.slideVelZ = sidewaysSpeed * coss(m.faceAngle.y + 0x4000);

            m.vel.x = m.slideVelX;
            m.vel.z = m.slideVelZ;
        end
    end
end

local function mario_interact(m, o, intee)
    local e = gExtraStates[m.playerIndex]

    if intee == INTERACT_BULLY and m.action == ACT_63_SPIN_GROUND then
        m.faceAngle.y = o.oFaceAngleYaw - 0x8000
        e.prevVel = -30
    end
end

local function give_fludd(id)
    local m = gMarioStates[0]
    local s = gPlayerSyncTable[0]

    if id == SOUND_GENERAL_COLLECT_1UP and m.action ~= ACT_EXIT_LAND_SAVE_DIALOG then
        if s.water > 75 then
            s.water = waterMax
        elseif s.water > 0 then
            s.water = s.water + 25
        else
            s.water = waterMax
        end
        audio_sample_play(SOUND_FLUDD_PICKUP, m.pos, pause_check())
        spawn_non_sync_object(id_bhvMistCircParticleSpawner, E_MODEL_NONE, m.pos.x, m.pos.y, m.pos.z, nil)
    end
end

local function level_init()
    --local e = gExtraStates[0]
    local s = gPlayerSyncTable[0]

    s.water = 0
end

local waterMeter    = get_texture_info("jmar_hud_water_meter")
local waterTop      = get_texture_info("jmar_hud_water_top")
local waterMid      = get_texture_info("jmar_hud_water_mid")
local waterBot      = get_texture_info("jmar_hud_water_bot")
local pressureBar   = get_texture_info("jmar_hud_water_red")
local nozzleHover   = get_texture_info("jmar_hud_fludd_hover")

local function mario_hud()
    if gNetworkPlayers[0].currActNum == 99 
    or gMarioStates[0].action == ACT_INTRO_CUTSCENE 
    or hud_is_hidden() 
    or obj_get_first_with_behavior_id(id_bhvActSelector) then return end

    local m = gMarioStates[0]
    local e = gExtraStates[0]
    local s = gPlayerSyncTable[0]

    if s.water > 0 then
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_set_resolution(RESOLUTION_N64)
        djui_hud_set_font(FONT_NORMAL)

        local WaterMeterScale = s.water/waterMax
        local HoverMeterScale = (e.pressure/hoverMax) * 6

        if s.water > 99.5 then
            textOffset = 11
        elseif s.water < 99.5 and s.water > 9.5 then
            textOffset = 15
        else
            textOffset = 19
        end

        djui_hud_render_texture(nozzleHover, 10, (math.sin(get_global_timer()*0.05)*3) + 152, 0.78, 0.78)
        djui_hud_render_texture(waterBot, 10, 218, 1, 1)
        djui_hud_render_texture(waterMid, 10, (222 - (8 * 14 * WaterMeterScale)), 1, 14 * WaterMeterScale)
        djui_hud_render_texture(waterTop, 10, (218 - (WaterMeterScale * 112)), 1, 1)
        djui_hud_render_texture(pressureBar, 10, (160 - (8 * HoverMeterScale)), 1, HoverMeterScale)
        djui_hud_render_texture(waterMeter, 10, 100, 1, 1)
        local waterString = string.format("%.0f", s.water)
        local waterScale = 0.5
        djui_hud_set_color(0, 0, 0, 255)
        djui_hud_print_text(waterString, textOffset, 159, waterScale)
        djui_hud_print_text(waterString, textOffset, 161, waterScale)
        djui_hud_print_text(waterString, textOffset + 1, 160, waterScale)
        djui_hud_print_text(waterString, textOffset - 1, 160, waterScale)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text(waterString, textOffset, 160, waterScale)
    end
end

local function fludd_sound()
    local e = gExtraStates[0]
    if e.fluddSoundLoop then
        audio_stream_play(SOUND_FLUDD_SPRAY, false, pause_check()*0.4)
    else
        audio_stream_stop(SOUND_FLUDD_SPRAY)
    end
end


_G.charSelect.character_hook_moveset(CT_J_MARIO, HOOK_MARIO_UPDATE, mario_update)
_G.charSelect.character_hook_moveset(CT_J_MARIO, HOOK_ON_SET_MARIO_ACTION, mario_set_action)
_G.charSelect.character_hook_moveset(CT_J_MARIO, HOOK_BEFORE_SET_MARIO_ACTION, mario_before_set_action)
_G.charSelect.character_hook_moveset(CT_J_MARIO, HOOK_BEFORE_PHYS_STEP, mario_before_step)
_G.charSelect.character_hook_moveset(CT_J_MARIO, HOOK_ON_INTERACT, mario_interact)
_G.charSelect.character_hook_moveset(CT_J_MARIO, HOOK_ON_PLAY_SOUND, give_fludd)
_G.charSelect.character_hook_moveset(CT_J_MARIO, HOOK_ON_LEVEL_INIT, level_init)
_G.charSelect.character_hook_moveset(CT_J_MARIO, HOOK_ON_HUD_RENDER_BEHIND, mario_hud)
_G.charSelect.character_hook_moveset(CT_J_MARIO, HOOK_UPDATE, fludd_sound)

--hook_event(HOOK_ON_HUD_RENDER, function()
--    local m = gMarioStates[0]
--    local e = gExtraStates[0]
--    local s = gPlayerSyncTable[m.playerIndex]
--
--    local width = djui_hud_get_screen_width()
--
--    djui_hud_set_resolution(RESOLUTION_DJUI)
--    djui_hud_set_color(255, 0, 0, 255)
--
--    djui_hud_print_text(string.format("s.water = %.0f", s.water), 25, 200, 1)
--    djui_hud_print_text(string.format("e.pressure = %.0f", e.pressure), 25, 250, 1)
--    djui_hud_print_text(string.format("e.gfxZ = %.0f", e.gfxZ), 25, 300, 1)
--    djui_hud_print_text("e.fluddSoundLoop = ".. tostring(e.fluddSoundLoop).."", 25, 350, 1)
--    djui_hud_print_text(string.format("actionTimer = %.0f", m.actionTimer), 25, 400, 1)
--
--
--    djui_hud_print_text(string.format("animFrame = %.0f", m.marioObj.header.gfx.animInfo.animFrame), width - 200, 200, 1)
--    djui_hud_print_text(string.format("animID = %.0f", m.marioObj.header.gfx.animInfo.animID), width - 200, 250, 1)
--
--end)