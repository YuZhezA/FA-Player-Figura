-- Generated from FA+Player v1.1 CEM expressions.
-- Original animation work: FreshLX / Fresh Animations.
-- Figura compatibility layer: generated locally for personal use.

local CONFIG = {
    -- Minecraft WalkAnimationState uses min(horizontalDistance * 4, 1),
    -- approaches it by 40% per tick, and advances position by that speed.
    speed_scale = 4.0,
    limb_smoothing = 8.0,
    stride_rate = 20.0,
    position_scale = 1.0,
    elytra_strength = 1.0,
}

local pi = math.pi
local sin, cos, abs = math.sin, math.cos, math.abs
local sqrt, exp = math.sqrt, math.exp
local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil

local function clamp(x, low, high)
    return min(max(x, low), high)
end

local function torad(x) return x * pi / 180 end
local function todeg(x) return x * 180 / pi end
local function pow(x, y) return x ^ y end
local function between(x, low, high) return x >= low and x <= high end

local function oneof(x, ...)
    for i = 1, select("#", ...) do
        if x == select(i, ...) then return true end
    end
    return false
end

local function choose(...)
    local count = select("#", ...)
    local index = 1
    while index < count do
        if select(index, ...) then return select(index + 1, ...) end
        index = index + 2
    end
    return select(count, ...)
end

local function round(x)
    return x >= 0 and floor(x + 0.5) or ceil(x - 0.5)
end

local function wraprad(x)
    return (x + pi) % (2 * pi) - pi
end

local function random(seed)
    local value = sin((seed or 0) * 12.9898 + 78.233) * 43758.5453
    return value - floor(value)
end

local v = setmetatable({}, {__index = function() return 0 end})
local vb = setmetatable({}, {__index = function() return false end})
local origin_pos = {}
local wing_origin = {
    right = {rx = 0, ry = 0, rz = 0},
    left = {rx = 0, ry = 0, rz = 0},
}
local m = setmetatable({}, {
    __index = function(table, key)
        local part = setmetatable({sx = 1, sy = 1, sz = 1}, {__index = function() return 0 end})
        rawset(table, key, part)
        return part
    end
})

local age, frame_time, frame_counter, id = 0, 0, 0, 1
local limb_speed, limb_swing, move_forward, move_strafing = 0, 0, 0, 0
local head_pitch, head_yaw, rot_x, rot_y, pos_y, swing_progress = 0, 0, 0, 0, 0, 0
local fluid_depth_up, rule_index = 0, 0
local is_paused, is_in_gui, is_first_person_hand = false, false, false
local is_on_ground, is_in_water, is_in_lava, is_swimming = false, false, false, false
local is_gliding, is_climbing, is_crawling, is_jumping = false, false, false, false
local is_sneaking, is_sprinting, is_riding, is_hurt = false, false, false, false
local is_using_item, is_blocking, is_right_handed = false, false, true
local is_swinging_arm = false
local is_swinging_right_arm, is_swinging_left_arm = false, false
local is_active_right_arm, is_active_left_arm = false, false
local swing_arm_name, last_swing_arm_name = nil, nil
local last_swinging_arm, swing_tail_tick, swing_tail_duration = false, nil, 1
local is_holding_item_right, is_holding_item_left = false, false
local is_sleeping, is_flying_ability = false, false
local main_item_id, off_item_id = "minecraft:air", "minecraft:air"
local last_seconds, last_frame_key = nil, nil
local last_health, hurt_until = nil, 0

local function contains(text, needle)
    return text ~= nil and string.find(text, needle, 1, true) ~= nil
end

local function main_has(needle) return contains(main_item_id, needle) end
local function off_has(needle) return contains(off_item_id, needle) end

local function uuid_seed(uuid)
    local result = 0
    for i = 1, #uuid do result = (result * 33 + string.byte(uuid, i)) % 2147483647 end
    return result
end

local CEM_BASE_POS = {
    head = {0, 0, 0}, headwear = {0, 0, 0},
    body = {0, 0, 0}, jacket = {0, 0, 0},
    right_arm = {-5, 2, 0}, right_sleeve = {-5, 2, 0},
    left_arm = {5, 2, 0}, left_sleeve = {5, 2, 0},
    right_leg = {-2, 12, 0}, right_pants = {-2, 12, 0},
    left_leg = {2, 12, 0}, left_pants = {2, 12, 0},
}

local function seed_part(name, part)
    local target = m[name]
    if part == nil then return end
    local r = part:getOriginRot()
    local p = part:getOriginPos()
    local s = part:getOriginScale()
    local base = CEM_BASE_POS[name] or {0, 0, 0}
    -- Figura exposes Blockbench-style X/Y rotations, while CEM expressions use
    -- Minecraft ModelPart X/Y signs. Convert once here and back when applying.
    target.rx, target.ry, target.rz = -torad(r.x), -torad(r.y), torad(r.z)
    target.tx, target.ty, target.tz = base[1] + p.x, base[2] + p.y, base[3] + p.z
    target.sx, target.sy, target.sz = s.x, s.y, s.z
    origin_pos[name] = {target.tx, target.ty, target.tz}
end

local function seed_model()
    seed_part("head", vanilla_model.HEAD)
    seed_part("headwear", vanilla_model.HAT)
    seed_part("body", vanilla_model.BODY)
    seed_part("jacket", vanilla_model.JACKET)
    seed_part("right_arm", vanilla_model.RIGHT_ARM)
    seed_part("left_arm", vanilla_model.LEFT_ARM)
    seed_part("right_sleeve", vanilla_model.RIGHT_SLEEVE)
    seed_part("left_sleeve", vanilla_model.LEFT_SLEEVE)
    seed_part("right_leg", vanilla_model.RIGHT_LEG)
    seed_part("left_leg", vanilla_model.LEFT_LEG)
    seed_part("right_pants", vanilla_model.RIGHT_PANTS)
    seed_part("left_pants", vanilla_model.LEFT_PANTS)
    seed_part("right_wing", vanilla_model.RIGHT_ELYTRA)
    seed_part("left_wing", vanilla_model.LEFT_ELYTRA)
    wing_origin.right.rx, wing_origin.right.ry, wing_origin.right.rz = m.right_wing.rx, m.right_wing.ry, m.right_wing.rz
    wing_origin.left.rx, wing_origin.left.ry, wing_origin.left.rz = m.left_wing.rx, m.left_wing.ry, m.left_wing.rz
    m.root.rx, m.root.ry, m.root.rz = 0, 0, 0
    m.root.tx, m.root.ty, m.root.tz = 0, 0, 0
    m.root.sx, m.root.sy, m.root.sz = 1, 1, 1
end

local function safe_nbt_flying()
    local ok, result = pcall(function()
        local nbt = player:getNbt()
        return nbt ~= nil and nbt.abilities ~= nil and (nbt.abilities.flying == 1 or nbt.abilities.flying == true)
    end)
    return ok and result or false
end

local function update_inputs(delta, context)
    local now = client.getSystemTime() / 1000
    age = world.getTime(delta)
    local frame_key = floor(age * 100000 + 0.5)
    if last_seconds == nil then last_seconds = now end
    frame_time = frame_key == last_frame_key and 0 or clamp(now - last_seconds, 0, 0.1)
    if frame_key ~= last_frame_key then last_seconds = now end
    last_frame_key = frame_key
    frame_counter = frame_key

    local pos = player:getPos(delta)
    local rot = player:getRot(delta)
    local velocity = player:getVelocity()
    local body_yaw = player:getBodyYaw(delta)
    local horizontal = sqrt(velocity.x * velocity.x + velocity.z * velocity.z)

    pos_y = pos.y
    rot_x, rot_y = torad(rot.x), torad(body_yaw)
    head_pitch = rot.x
    head_yaw = ((rot.y - body_yaw + 180) % 360) - 180
    local target_limb_speed = clamp(horizontal * CONFIG.speed_scale, 0, 1)
    local limb_blend = min(1, frame_time * CONFIG.limb_smoothing)
    limb_speed = target_limb_speed * limb_blend + limb_speed * (1 - limb_blend)
    limb_swing = limb_swing + limb_speed * frame_time * CONFIG.stride_rate

    if horizontal > 0.0001 then
        local yaw = torad(body_yaw)
        move_forward = clamp((-sin(yaw) * velocity.x + cos(yaw) * velocity.z) / horizontal, -1, 1)
        move_strafing = clamp((cos(yaw) * velocity.x + sin(yaw) * velocity.z) / horizontal, -1, 1)
    else
        move_forward, move_strafing = 0, 0
    end

    local duration = max(player:getSwingDuration(), 1)
    local swing_time = player:getSwingTime()
    is_swinging_arm = player:isSwingingArm()
    local reported_swing_arm = player:getSwingArm()
    if reported_swing_arm ~= nil then last_swing_arm_name = reported_swing_arm end

    -- Match LivingEntity.getAttackAnim(delta): swing_time is the current
    -- tick's value, while the renderer interpolates from the previous tick.
    local tick_index = floor(age)
    if is_swinging_arm then
        local previous_swing_time = swing_time > 0 and swing_time - 1 or 0
        swing_progress = clamp((previous_swing_time + (delta or 0)) / duration, 0, 1)
        swing_tail_tick = nil
    elseif last_swinging_arm then
        -- When Minecraft clears `swinging`, its previous progress is still
        -- interpolated to 1 for the remainder of that render tick.
        swing_tail_tick, swing_tail_duration = tick_index, duration
        swing_progress = clamp((duration - 1 + (delta or 0)) / duration, 0, 1)
    elseif swing_tail_tick == tick_index then
        swing_progress = clamp((swing_tail_duration - 1 + (delta or 0)) / swing_tail_duration, 0, 1)
    else
        swing_progress = 0
    end
    last_swinging_arm = is_swinging_arm
    swing_arm_name = reported_swing_arm or (swing_progress > 0 and last_swing_arm_name or nil)

    local pose = player:getPose()
    is_paused = client.isPaused()
    is_in_gui = context == "FIGURA_GUI" or context == "PAPERDOLL" or context == "MINECRAFT_GUI"
    is_first_person_hand = context == "FIRST_PERSON" or context == "FIRST_PERSON_WORLD"
    is_on_ground = player:isOnGround()
    is_in_water = player:isInWater()
    is_in_lava = player:isInLava()
    is_swimming = player:isVisuallySwimming()
    is_gliding = player:isGliding()
    is_climbing = player:isClimbing()
    is_crawling = pose == "SWIMMING" and not is_in_water and not is_gliding
    is_jumping = not is_on_ground and velocity.y > 0.03
    is_sneaking = player:isSneaking() or player:isCrouching()
    is_sprinting = player:isSprinting()
    is_riding = player:getVehicle() ~= nil
    local health = player:getHealth()
    if last_health ~= nil and health < last_health then hurt_until = now + 0.5 end
    last_health = health
    is_hurt = now < hurt_until
    is_using_item = player:isUsingItem()
    is_blocking = player:isBlocking()
    is_right_handed = not player:isLeftHanded()
    is_sleeping = pose == "SLEEPING"
    is_flying_ability = safe_nbt_flying()
    fluid_depth_up = player:isUnderwater() and 3 or (is_in_water and 1 or 0)

    main_item_id = player:getHeldItem(false):getID()
    off_item_id = player:getHeldItem(true):getID()
    local main_held = main_item_id ~= "minecraft:air"
    local off_held = off_item_id ~= "minecraft:air"
    is_holding_item_right = is_right_handed and main_held or off_held
    is_holding_item_left = is_right_handed and off_held or main_held

    is_swinging_right_arm = swing_arm_name == (is_right_handed and "MAIN_HAND" or "OFF_HAND")
    is_swinging_left_arm = swing_arm_name == (is_right_handed and "OFF_HAND" or "MAIN_HAND")
    local active_hand_name = is_using_item and player:getActiveHand() or nil
    is_active_right_arm = active_hand_name == (is_right_handed and "MAIN_HAND" or "OFF_HAND")
    is_active_left_arm = active_hand_name == (is_right_handed and "OFF_HAND" or "MAIN_HAND")
    id = uuid_seed(player:getUUID())
end

local function evaluate_cem()

    -- variables: a_player_variables.jpm
    vb.v21_2_plus = false
    vb.fcc = is_paused or frame_counter == v.frame_counter_prev
    vb.isjmp = is_jumping
    v.body_yaw = m.body.ry
    v.rarm_rx = m.right_arm.rx +cos(limb_swing*0.6662)/2*limb_speed -choose( m.body.rx==0.5 and m.body.ty==3.2 and m.head.ty==4.2, 0.4, 0) -v.body_yaw
    v.larm_rx = m.left_arm.rx -cos(limb_swing*0.6662)/2*limb_speed -choose( m.body.rx==0.5 and m.body.ty==3.2 and m.head.ty==4.2, 0.4, 0) -v.body_yaw
    v.rarm_ry = wraprad( m.right_arm.ry )
    v.larm_ry = wraprad(m.left_arm.ry )
    v.rarm_rz = wraprad( m.right_arm.rz )
    v.larm_rz = wraprad(m.left_arm.rz )
    v.rarm_tx = m.right_arm.tx
    v.larm_tx = m.left_arm.tx
    v.rarm_ty = m.right_arm.ty
    v.larm_ty = m.left_arm.ty
    v.rarm_tz = m.right_arm.tz
    v.larm_tz = m.left_arm.tz
    v.head_pitch = m.head.rx -torad(head_pitch)
    v.rleg_pitch = m.right_leg.rx
    v.lleg_pitch = m.left_leg.rx
    vb.rblock = is_active_right_arm and is_using_item and ( is_blocking or ( is_right_handed and main_has("shield")) or (not is_right_handed and off_has("shield")) )
    vb.lblock = is_active_left_arm and is_using_item and ( is_blocking or (not is_right_handed and main_has("shield")) or ( is_right_handed and off_has("shield")) )
    vb.rspear_hold = ( is_right_handed and main_has("spear")) or (not is_right_handed and off_has("spear"))
    vb.lspear_hold = (not is_right_handed and main_has("spear")) or ( is_right_handed and off_has("spear"))
    vb.rtrident_aim = is_active_right_arm and is_using_item and between( v.rarm_rx, -pi-0.0501, -pi+0.0501 )
    vb.ltrident_aim = is_active_left_arm and is_using_item and between( v.larm_rx, -pi-0.0501, -pi+0.0501 )
    vb.rbow_and_arrow = is_using_item and between( v.rarm_ry, -0.1 +torad(head_yaw) -0.4 -0.0001, -0.1 +torad(head_yaw) -0.4 +0.0001 )
    vb.lbow_and_arrow = is_using_item and between( v.larm_ry,0.1 +torad(head_yaw) +0.4 -0.0001,0.1 +torad(head_yaw) +0.4 +0.0001 )
    vb.rcrossbow_charge = is_active_right_arm and is_using_item and between( v.rarm_ry, -0.8 -0.0001, -0.8 +0.0001 ) and between( v.rarm_rx -cos(limb_swing*0.6662)/2*limb_speed, -0.97079635 -0.0501, -0.97079635 +0.0501 )
    vb.lcrossbow_charge = is_active_left_arm and is_using_item and between( v.larm_ry,0.8 -0.0001,0.8 +0.0001 ) and between( v.larm_rx +cos(limb_swing*0.6662)/2*limb_speed, -0.97079635 -0.0501, -0.97079635 +0.0501 )
    v.rcrossbow_charge_progress = clamp( choose(vb.rcrossbow_charge,v.larm_ry -0.4, 0 )*2.2223, 0, 1 )
    v.lcrossbow_charge_progress = clamp( choose(vb.lcrossbow_charge, -v.rarm_ry -0.4, 0 )*2.2223, 0, 1 )
    vb.rcrossbow_hold = between( v.rarm_ry, -0.3 +torad(head_yaw) -0.0001, -0.3 +torad(head_yaw) +0.0001 ) and between( v.rarm_rx -cos(limb_swing*0.6662)/2*limb_speed, -1.5707964 +torad(head_pitch) +0.1 -0.0501, -1.5707964 +torad(head_pitch) +0.1 +0.0501 )
    vb.lcrossbow_hold = between( v.larm_ry,0.3 +torad(head_yaw) -0.0001,0.3 +torad(head_yaw) +0.0001 ) and between( v.larm_rx +cos(limb_swing*0.6662)/2*limb_speed, -1.5707964 +torad(head_pitch) +0.1 -0.0501, -1.5707964 +torad(head_pitch) +0.1 +0.0501 )
    vb.rbrush = is_active_right_arm and is_using_item and between( v.rarm_rx, -0.62831855 -0.0501, -0.62831855 +0.0501 )
    vb.lbrush = is_active_left_arm and is_using_item and between( v.larm_rx, -0.62831855 -0.0501, -0.62831855 +0.0501 )
    vb.rspyglass = is_active_right_arm and is_using_item and between( v.rarm_ry, torad(head_yaw) -0.2617994 -0.0001, torad(head_yaw) -0.2617994 +0.0001 ) and not vb.rblock
    vb.lspyglass = is_active_left_arm and is_using_item and between( v.larm_ry, torad(head_yaw) +0.2617994 -0.0001, torad(head_yaw) +0.2617994 +0.0001 ) and not vb.lblock
    vb.rtoot_horn = is_active_right_arm and is_using_item and between( v.rarm_rx -cos(limb_swing*0.6662)/2*limb_speed, clamp(torad(head_pitch), -1.2, 1.2) -1.4835298 -0.0501, clamp(torad(head_pitch), -1.2, 1.2) -1.4835298 +0.0501 ) and not vb.rblock
    vb.ltoot_horn = is_active_left_arm and is_using_item and between( v.larm_rx +cos(limb_swing*0.6662)/2*limb_speed, clamp(torad(head_pitch), -1.2, 1.2) -1.4835298 -0.0501, clamp(torad(head_pitch), -1.2, 1.2) -1.4835298 +0.0501 ) and not vb.lblock
    v.hp = clamp( head_pitch, -90, 90 )
    v.hy = clamp( head_yaw, -90, 90 )
    v.root_angle = clamp( choose( vb.fcc, v.root_angle, is_swimming or is_gliding, v.root_angle +1.6 *frame_time, choose( v.gliding>0, 0, v.root_angle -1.6 *frame_time ) ), 0, 1 )
    v.mforward = choose( limb_speed~=0 and move_forward==0 and move_strafing==0, 1, move_forward )
    vb.rswing = is_swinging_right_arm and swing_progress > 0
    vb.lswing = is_swinging_left_arm and swing_progress > 0
    v.laying = choose( is_sleeping, 1, 0 )
    v.t_sleep = clamp( choose( vb.fcc, v.t_sleep, limb_speed<=0.1 and not is_hurt, v.t_sleep +0.2 *frame_time, v.t_sleep -2 *frame_time ), 0, 1 )
    v.sleep = 1-sin( pow( 1-clamp(v.t_sleep*10 -9, 0, 1), 1.8 )*pi/2 )
    v.forwd_drag = choose( vb.fcc, v.forwd_drag, age<9 or is_riding, 0,v.mforward*min(1,frame_time*8 *(1-0.7*v.underwater)) +v.forwd_drag*max(0,1-frame_time*8 *(1-0.7*v.underwater)) )
    v.sidwd_drag = choose( vb.fcc, v.sidwd_drag, age<9 or is_riding, 0, move_strafing*min(1,frame_time*8 *(1-0.7*v.underwater)) +v.sidwd_drag*max(0,1-frame_time*8 *(1-0.7*v.underwater)) )
    v.speed_drag = choose( vb.fcc, v.speed_drag, age<9 or is_riding, 0,limb_speed*min(1,frame_time*8 *(1-0.7*v.underwater)) +v.speed_drag*max(0,1-frame_time*8 *(1-0.7*v.underwater)) )
    v.pitch_drag = choose( vb.fcc, v.pitch_drag, age<9 or is_riding, rot_x, rot_x*min(1,frame_time*16 ) +v.pitch_drag*max(0,1-frame_time*16 ) )
    v.yaw_drag = choose( vb.fcc, v.yaw_drag, age<9 or is_riding, rot_y, rot_y*min(1,frame_time*12*(1-0.7*v.flying)) +v.yaw_drag*max(0,1-frame_time*12*(1-0.7*v.flying)) )
    v.verti_drag = choose( vb.fcc, v.verti_drag, age<9 or is_riding, pos_y, pos_y*min(1,frame_time*16*(1-0.7*v.underwater)) +v.verti_drag*max(0,1-frame_time*16*(1-0.7*v.underwater)) )
    v.gliderleg_drag = choose( vb.fcc, v.gliderleg_drag, age<9,0, v.lleg_pitch*min(1,frame_time*4 ) +v.gliderleg_drag*max(0,1-frame_time*4 ) )
    v.headpitch_drag = choose( vb.fcc, v.headpitch_drag, age<9, head_pitch, head_pitch*min(1,frame_time*8 ) +v.headpitch_drag*max(0,1-frame_time*8 ) )
    v.headyaw_drag = choose( vb.fcc, v.headyaw_drag, age<9, head_yaw, head_yaw*min(1,frame_time*8 ) +v.headyaw_drag*max(0,1-frame_time*8 ) )
    v.speed_speed = choose( vb.fcc,v.speed_speed, age<9 or is_in_gui, 0, (v.speed_drag-limb_speed)*(1-0.7*v.underwater) )
    v.pitch_speed = choose( vb.fcc,v.pitch_speed, age<9 or is_in_gui, 0, (v.pitch_drag-rot_x ))
    v.yaw_speed = choose( vb.fcc,v.yaw_speed, age<9 or is_in_gui, 0, (v.yaw_drag-rot_y ))
    v.vertical_speed = choose( vb.fcc, v.vertical_speed, age<9, max(0,3-age), (v.verti_drag-pos_y )*(1-0.7*v.underwater) )
    v.headpitch_speed = choose( vb.fcc, v.headpitch_speed, age<9, 0, (v.headpitch_drag-head_pitch)/90)
    v.headyaw_speed = choose( vb.fcc, v.headyaw_speed, age<9, 0, (v.headyaw_drag-head_yaw)/90 +todeg(v.yaw_speed)/45 )*max(0,1-v.raction-v.laction)
    v.vs_ltd = clamp( v.vertical_speed, -choose( not between(v.vertical_speed,-1,1), 1, 3.7 ), choose( not between(v.vertical_speed,-1,1), 1, 3.7 ) )
    vb.jumping = not is_riding and not is_gliding and not is_on_ground and ( ( not is_in_water and (pos_y-v.pre_posy) > 0 ) or pos_y>v.pre_posy )
    vb.falling = not is_riding and not is_gliding and not is_on_ground and ( ( not is_in_water and (pos_y-v.pre_posy) < 0 ) or pos_y<v.pre_posy )
    vb.leveled = not is_riding and not is_gliding and not is_on_ground and round((pos_y-v.pre_posy)*50)/50 ==0
    v.t_fall = clamp(choose( vb.fcc, v.t_fall, vb.falling and not is_climbing, v.t_fall +6 *frame_time, v.t_fall -6 *frame_time ), 0, 1)
    v.t_land = clamp(choose( vb.fcc, v.t_land, oneof(v.t_land,0,1) and vb.falling, 0, v.t_land +frame_time*choose( vb.falling, 2.5, 1.4 )/choose(is_in_water,2,1) -choose( between(v.t_land,0.4,1) and is_on_ground and (pos_y-v.pre_posy)<0, 1, 0 ) ), choose(age<1, 0.01, 0), 1)
    v.fall_amp = clamp( choose( vb.fcc, v.fall_amp, max(0, v.fall_amp - frame_time * v.fall_amp * choose(v.t_land<0.7, 3, 6) +choose(not is_on_ground, frame_time*60*v.vs_ltd/4, 0) ) ), 0, 5.7 )
    v.sj_side = choose( vb.fcc, v.sj_side, (not vb.isjmp and not vb.jumping and not vb.falling and min(1,v.t_land*2)==1) and cos(v.ls)<0, 1, (not vb.isjmp and not vb.jumping and not vb.falling and min(1,v.t_land*2)==1), -1, not vb.jumping and not oneof(v.t_Rjump,0,1), -1, not vb.jumping and not oneof(v.t_Ljump,0,1), 1, v.sj_side )
    v.t_jump = clamp( choose( vb.fcc, v.t_jump ,oneof(v.t_jump ,0,1) and not vb.jumping , 0, v.t_jump+ frame_time * choose( is_on_ground and vb.isjmp, 2, 1 )*(2-v.water)*(1+v.prone) ), choose(age<9,1,0), 1 )
    v.t_Rjump = clamp( choose( vb.fcc, v.t_Rjump, not oneof(v.t_Rjump,0,1) or ( v.sj_side>0 and vb.jumping ), v.t_Rjump + frame_time * choose((is_on_ground and not vb.isjmp) or between(v.t_Ljump,0.01,0.2), 2, 1), 0 ), choose(age<9,1,0), 1 )
    v.t_Ljump = clamp( choose( vb.fcc, v.t_Ljump, not oneof(v.t_Ljump,0,1) or ( v.sj_side<0 and vb.jumping ), v.t_Ljump + frame_time * choose((is_on_ground and not vb.isjmp) or between(v.t_Rjump,0.01,0.2), 2, 1), 0 ), choose(age<9,1,0), 1 )
    v.compass = choose( not is_in_gui, wraprad( -rot_y +pi ), 0)
    v.climb_direction = choose( not vb.v21_2_plus, 0, vb.fcc, v.climb_direction, v.climb~=0 and rule_index==1, v.compass +choose(v.compass>0, -pi, pi), v.climb~=0 and rule_index==2, v.compass, v.climb~=0 and rule_index==3, v.compass +choose(between(v.compass, pi/2, pi), 0, between(v.compass, -pi/2, pi/2), 0, pi*2 ) -pi/2, v.climb~=0 and rule_index==4, v.compass +choose(between(v.compass, pi/2, pi), -pi*2, between(v.compass, -pi/2, pi/2), 0, 0 ) +pi/2, v.climb~=0, v.climb_direction, 0 )
    v.RarmRX_drag = choose( vb.fcc, v.RarmRX_drag, (v.rarm_rx -cos(limb_swing*0.6662)/2*limb_speed*choose(vb.rspear_hold or vb.rbow_and_arrow or vb.lbow_and_arrow or vb.rcrossbow_charge or vb.lcrossbow_charge or vb.rcrossbow_hold or vb.lcrossbow_hold or vb.rspyglass or vb.rtoot_horn, 1, 0))*min(1,frame_time*16) +v.RarmRX_drag*max(0,1-frame_time*16) )
    v.LarmRX_drag = choose( vb.fcc, v.LarmRX_drag, (v.larm_rx +cos(limb_swing*0.6662)/2*limb_speed*choose(vb.lspear_hold or vb.rbow_and_arrow or vb.lbow_and_arrow or vb.rcrossbow_charge or vb.lcrossbow_charge or vb.rcrossbow_hold or vb.lcrossbow_hold or vb.lspyglass or vb.ltoot_horn, 1, 0))*min(1,frame_time*16) +v.LarmRX_drag*max(0,1-frame_time*16) )
    v.RarmRY_drag = choose( vb.fcc, v.RarmRY_drag,v.rarm_ry*min(1,frame_time*16) +v.RarmRY_drag*max(0,1-frame_time*16) )
    v.LarmRY_drag = choose( vb.fcc, v.LarmRY_drag,v.larm_ry*min(1,frame_time*16) +v.LarmRY_drag*max(0,1-frame_time*16) )
    v.RarmRZ_drag = choose( vb.fcc, v.RarmRZ_drag,v.rarm_rz*min(1,frame_time*16) +v.RarmRZ_drag*max(0,1-frame_time*16) )
    v.LarmRZ_drag = choose( vb.fcc, v.LarmRZ_drag,v.larm_rz*min(1,frame_time*16) +v.LarmRZ_drag*max(0,1-frame_time*16) )
    v.RarmTX_drag = choose( vb.fcc, v.RarmTX_drag, (v.rarm_tx+5)*min(1,frame_time*16) +v.RarmTX_drag*max(0,1-frame_time*16) )
    v.LarmTX_drag = choose( vb.fcc, v.LarmTX_drag, (v.larm_tx-5)*min(1,frame_time*16) +v.LarmTX_drag*max(0,1-frame_time*16) )
    v.RarmTY_drag = choose( vb.fcc, v.RarmTY_drag, (v.rarm_ty-2)*min(1,frame_time*16) +v.RarmTY_drag*max(0,1-frame_time*16) )
    v.LarmTY_drag = choose( vb.fcc, v.LarmTY_drag, (v.larm_ty-2)*min(1,frame_time*16) +v.LarmTY_drag*max(0,1-frame_time*16) )
    v.RarmTZ_drag = choose( vb.fcc, v.RarmTZ_drag,v.rarm_tz *min(1,frame_time*16) +v.RarmTZ_drag*max(0,1-frame_time*16) )
    v.LarmTZ_drag = choose( vb.fcc, v.LarmTZ_drag,v.larm_tz *min(1,frame_time*16) +v.LarmTZ_drag*max(0,1-frame_time*16) )
    vb.Raction = is_holding_item_right and ( vb.rblock or vb.rtrident_aim or vb.rbrush ) or vb.rspear_hold or vb.rbow_and_arrow or vb.lbow_and_arrow or vb.rcrossbow_charge or vb.lcrossbow_charge or vb.rcrossbow_hold or vb.lcrossbow_hold or vb.rspyglass or vb.rtoot_horn
    vb.Laction = is_holding_item_left and ( vb.lblock or vb.ltrident_aim or vb.lbrush ) or vb.lspear_hold or vb.lbow_and_arrow or vb.rbow_and_arrow or vb.lcrossbow_charge or vb.rcrossbow_charge or vb.lcrossbow_hold or vb.rcrossbow_hold or vb.lspyglass or vb.ltoot_horn
    v.Raction_drag = choose( vb.fcc, v.Raction_drag, choose(vb.Raction,1,0)*min(1,frame_time*choose(is_right_handed,8,4) ) +v.Raction_drag*max(0,1-frame_time*choose(is_right_handed,8,4) ) )
    v.Laction_drag = choose( vb.fcc, v.Laction_drag, choose(vb.Laction,1,0)*min(1,frame_time*choose(is_right_handed,4,8) ) +v.Laction_drag*max(0,1-frame_time*choose(is_right_handed,4,8) ) )
    v.ractionT = v.Raction_drag +sin( v.Raction_drag*pi )/2.5
    v.lactionT = v.Laction_drag +sin( v.Laction_drag*pi )/2.5
    v.raction = clamp(choose( vb.fcc, v.raction, vb.Raction, v.raction +6 *frame_time, v.raction -6 *frame_time), 0, 1)
    v.laction = clamp(choose( vb.fcc, v.laction, vb.Laction, v.laction +6 *frame_time, v.laction -6 *frame_time), 0, 1)
    v.Requip_drag = choose( vb.fcc, v.Requip_drag, choose( is_holding_item_right and v.laying<1,1,0)*min(1,frame_time*8 ) +v.Requip_drag*max(0,1-frame_time*8 ) )
    v.Lequip_drag = choose( vb.fcc, v.Lequip_drag, choose( is_holding_item_left and v.laying<1,1,0)*min(1,frame_time*8 ) +v.Lequip_drag*max(0,1-frame_time*8 ) )
    v.requip = clamp( v.Requip_drag*1.02, 0, clamp( 1 -v.prone, 0, 1) )
    v.lequip = clamp( v.Lequip_drag*1.02, 0, clamp( 1 -v.prone, 0, 1) )
    v.requip2 = clamp( choose( vb.fcc, v.requip2, is_holding_item_right and v.laying<1, v.requip2 +frame_time*3, 0 ), 0, 1 )
    v.lequip2 = clamp( choose( vb.fcc, v.lequip2, is_holding_item_left and v.laying<1, v.lequip2 +frame_time*3, 0 ), 0, 1 )
    v.Rmap = choose( vb.fcc, v.Rmap, choose( not is_right_handed and off_has("filled_map"), 2, main_has("filled_map"), 1, 0 )*min(1,frame_time*8 ) +v.Rmap*max(0,1-frame_time*8 ) )
    v.Lmap = choose( vb.fcc, v.Lmap, choose(is_right_handed and off_has("filled_map"), 2, main_has("filled_map"), 1, 0 )*min(1,frame_time*8 ) +v.Lmap*max(0,1-frame_time*8 ) )
    v.Asneak = choose( vb.fcc, v.Asneak, choose( (m.body.rx==0.5 and m.body.ty==3.2 and m.head.ty==4.2) or is_sneaking or (not is_gliding and v.gliding>0), 1, 0)*min(1,frame_time*12) +v.Asneak*max(0,1-frame_time*12) )
    v.sneak2 = choose( not is_gliding and m.body.rx==0.5 and m.body.ty==3.2 and m.head.ty==4.2, 1, 0)
    v.sneak = (0.5-0.5*cos(v.Asneak*pi))*(0.5-0.5*cos(sqrt(v.Asneak)*pi))
    v.sit = choose(is_riding, 1, 0)
    v.prone = clamp(choose( vb.fcc, v.prone, not is_in_water and not is_gliding and is_crawling or (is_climbing and not is_on_ground), v.prone +6 *frame_time, v.prone -3 *frame_time ), 0, max(0, 1 -v.flying -v.sit ) )
    v.gliding = clamp( choose( vb.fcc, v.gliding, is_gliding, v.gliding +1.6 *frame_time, v.gliding -1.6 *frame_time ), 0, 1)
    v.gfast = clamp( choose( vb.fcc, v.gfast, is_gliding and between( v.rleg_pitch, -0.03, 0.03 ), v.gfast +0.6 *frame_time, v.gfast -0.6 *frame_time ), 0, 1)
    v.attA = sin( ( 1 -( 1 -swing_progress ) *( 1 -swing_progress ) )*pi )
    v.attB = -cos(swing_progress *pi ) *v.attA
    v.attC = sin( sqrt(swing_progress)*pi*2 )
    v.rswinging = clamp(choose(vb.fcc, v.rswinging, vb.rswing, v.rswinging +14 *frame_time, v.rswinging -4 *frame_time), 0, 1)
    v.lswinging = clamp(choose(vb.fcc, v.lswinging, vb.lswing, v.lswinging +14 *frame_time, v.lswinging -4 *frame_time), 0, 1)
    v.rswingingA = v.rswinging * v.rswinging * v.rswinging
    v.lswingingA = v.lswinging * v.lswinging * v.lswinging
    v.Created_by_FreshLX_for_Fresh_Animations = 1
    v.r = random(id)*pi*4
    v.Bt = v.r +age/(11.5-2*random(id))
    v.Et = v.r +age +sin( v.r +age/9.3 )/1.5
    v.ls_turn = choose( vb.fcc, v.ls_turn, v.ls_turn +abs( v.pre_roty-rot_y )*max( 0.2*(1-v.climb), v.idle )*v.mforward*4 )
    v.ls_bkwd = choose( vb.fcc, v.ls_bkwd, v.mforward<-0.5 and between(v.sidwd_drag, -0.8, 0.8), v.ls_bkwd +frame_time*42 *limb_speed, v.ls_bkwd )
    v.ls_jump = choose( vb.fcc, v.ls_jump, (not (v.mforward<-0.5 and between(v.sidwd_drag, -0.8, 0.8)) and vb.isjmp) or (not is_on_ground and v.run>0), v.ls_jump +frame_time*5*(1-2*v.idle+v.sprint), v.ls_jump )
    v.ls_slow = choose( vb.fcc, v.ls_slow, limb_speed<choose(is_in_water and fluid_depth_up>1, 0.25, 0.63), v.ls_slow +frame_time*6 *limb_speed *v.mforward, v.ls_slow )
    v.ls = choose( vb.fcc, v.ls, is_riding, pi/2, ( limb_swing -v.ls_bkwd -v.ls_jump +v.ls_slow +v.ls_turn )*0.58 +pi/2 )
    v.lsj = limb_swing/6 +age/4
    v.lsF = limb_swing/6 +age/16
    v.lsc = choose(v.prone~=0 and not is_crawling, pos_y*4, v.ls*2)
    v.up_offset = choose( vb.fcc, v.up_offset, v.up_offset +choose( is_in_water, choose( v.swim>0, abs( v.pre_posy-pos_y )*(1+0.5*v.swim_up), pos_y-v.pre_posy )*(1-pow(limb_speed,2)), 0 ) )
    v.Btsw = limb_swing/4 +age/9 +v.up_offset/1.3
    v.asw = choose( is_gliding, pi -pi*3*v.gliding, limb_swing/3 +v.up_offset ) +pi*v.gliding
    v.is_flying = choose( vb.fcc, v.is_flying, not is_riding and is_flying_ability, 1, (not is_flying_ability) and not is_climbing and not is_in_water and ( vb.leveled or ( v.is_flying==1 and not is_riding and not is_gliding and not is_on_ground and abs(v.vertical_speed)<0.5 ) ), min(1, v.is_flying +frame_time*1.8 ), 0 )
    v.flying = clamp(choose( vb.fcc, v.flying, v.is_flying==1, v.flying +2 *frame_time, v.flying -4 *frame_time ), 0, 1-v.laying )
    v.underwater = clamp(choose( vb.fcc, v.underwater, is_in_water and fluid_depth_up>1, v.underwater +2 *frame_time, v.underwater -2 *frame_time), 0, 1 )
    v.water = clamp(choose( vb.fcc, v.water, is_in_water, v.water +4 *frame_time, v.water -4 *frame_time ), 0, 1 )
    v.tread = clamp(choose( vb.fcc, v.tread,(not is_riding and is_in_water and not is_on_ground) or (is_sprinting and is_in_water ), v.tread +4 *frame_time, v.tread -4 *frame_time ), 0, 1 -v.flying )
    v.swim = clamp(choose( vb.fcc, v.swim , is_gliding or ( is_in_water and ( is_sprinting and is_swimming or (vb.isjmp and fluid_depth_up>2) )), v.swim+2 *frame_time, v.swim-2 *frame_time*choose(is_gliding,0.2,1)), 0, 1 -v.flying )
    v.swim_up = choose( vb.fcc, v.swim_up, v.is_flying~=1 and is_in_water and fluid_depth_up>2 and vb.isjmp and (not is_sprinting and not is_swimming), 1, max(0, v.swim_up -frame_time ) )
    v.land = ( min( 1, v.t_land*6 )-sin(v.t_land*pi/2) )*3*clamp(v.fall_amp,0.2,1)*(1-v.water/2)*(1-v.swim)*(1-v.flying)
    v.fall = ( sin(min( 1, v.fall_amp/6*(1+v.tread) )*pi/2) )*v.t_fall*1.2
    v.jump = sin( v.t_jump *pi )*choose(v.laying>0,0,1)*(1-v.vs_ltd)*(1-min(1, v.water +v.swim ))
    v.Rjump = sin( sqrt(v.t_Rjump)*pi )*choose(v.laying>0,0,1) *sin( min(0.5, v.t_Rjump*3)*pi ) *(1-max(0,-2 +v.t_Rjump*3 ))*(1-v.vs_ltd)*(1-min(1, v.water +v.prone +v.flying/2 ))
    v.Ljump = sin( sqrt(v.t_Ljump)*pi )*choose(v.laying>0,0,1) *sin( min(0.5, v.t_Ljump*3)*pi ) *(1-max(0,-2 +v.t_Ljump*3 ))*(1-v.vs_ltd)*(1-min(1, v.water +v.prone +v.flying/2 ))
    v.climb = clamp(choose( vb.fcc, v.climb , not is_on_ground and is_climbing and not is_gliding, v.climb+4 *frame_time, v.climb-4 *frame_time ), 0, 1-v.sit )
    v.in_air = clamp(choose( vb.fcc, v.in_air, not is_on_ground and v.Created_by_FreshLX_for_Fresh_Animations==1, v.in_air +4 *frame_time, v.in_air -4 *frame_time ), 0, 1 )
    v.sprjmp = clamp(choose( vb.fcc, v.sprjmp, not oneof(min(1,v.t_Rjump*2),0,1) or not oneof(min(1,v.t_Ljump*2),0,1) and not is_in_water , v.sprjmp +6 *frame_time, v.sprjmp -2 *frame_time ), 0, 1 )
    v.sprint = clamp(choose( vb.fcc, v.sprint,is_sprinting and not is_in_water and not is_sneaking, v.sprint +4 *frame_time, v.sprint -4 *frame_time ), 0, max(0, 1 -v.sprjmp -v.flying ) )
    v.run = clamp(choose( vb.fcc, v.run , not (is_on_ground and v.mforward<-0.5 and between(v.sidwd_drag,-0.8, 0.8)) and limb_speed>choose(is_in_water and fluid_depth_up>1, 0.25, 0.63), v.run+4 *frame_time, v.run-4 *frame_time ), 0, max(0, 1 -v.sprjmp -v.swim -v.tread -v.prone -choose( not is_gliding and v.gliding>0, max(0,-2+v.gliding*3), v.gliding ) -v.fall -v.flying )*(1+0.2*v.sprint) )
    v.wade = clamp(choose( vb.fcc, v.wade,( not is_sneaking and is_on_ground and is_in_water and fluid_depth_up<=1 ) or is_in_lava, v.wade +6 *frame_time, v.wade -6 *frame_time ), 0, max(0, 1 -v.swim ) )
    v.strafe = clamp(choose( vb.fcc, v.strafe,abs(move_strafing)>0.85 , v.strafe +6 *frame_time*(1-0.7*v.flying), v.strafe -6 *frame_time*(1-0.7*v.flying) ), 0, 1 )
    v.walk = clamp( ( 3 +2*v.sneak +4*(v.raction+v.laction) )*limb_speed, 0, max(0, 1 -v.sprjmp -v.swim -v.tread -v.prone -choose( not is_gliding and v.gliding>0, max(0,-2+v.gliding*3), v.gliding ) -v.fall -v.flying ) )
    v.crawl = clamp( 5*limb_speed*(1-v.climb) +abs(v.vs_ltd)*10*v.climb, 0, v.prone )*1.5
    v.idle = ( 1-min(1, 3*limb_speed) )*( 1 -v.tread -v.prone -v.gliding )
    v.t_idle = choose( vb.fcc, v.t_idle, not is_on_ground or v.idle<1 or v.raction~=0 or v.laction~=0 or swing_progress>0, 0, v.t_idle +frame_time )
    v.root_sy = -0.025
    v.root_sx = -0.025
    v.root_sz = -0.025
    v.root_rx = torad( 90*clamp(v.vertical_speed*4, -1, 1 )*(1-pow(limb_speed*0.7,2)) -head_pitch )*min(1, v.swim*(1-v.swim_up)*(1-v.gliding) )*(1-v.sneak) +torad( -3*sin(limb_swing/33 +sin(limb_swing/40)/4) )*v.gliding +torad( 40*min(1,limb_speed*(1+0.5*v.tread))*v.forwd_drag )*(v.tread+v.flying/2)*(1-v.swim*(1-v.swim_up)) +torad( 5*v.walk )*v.sneak +choose( not is_gliding and v.gliding>0, pi/2*v.gliding, 0 )
    v.root_ry = torad( 60*clamp( v.yaw_speed*3, -1, 1 ) )*min(1, v.swim*(1-v.swim_up)*(1-v.gliding) ) +torad(5*sin(limb_swing/25 +sin(limb_swing/40)/4) )*v.gliding+v.climb_direction*v.climb+torad( 15*v.sidwd_drag )*v.walk*v.strafe
    v.root_rz = torad( 30*clamp( v.yaw_speed*2, -1, 1 )*limb_speed)*v.mforward *(1-v.gliding) +torad(-20*min(1,limb_speed*(1+0.5*v.tread))*v.sidwd_drag )*(v.tread+v.flying/2)*(1-v.swim)
    v.root_tx = 0
    v.root_ty = (1-cos(v.root_rx))*24 *(1-0.75*v.swim*(1-v.gliding)) +(1-cos(v.root_rz))*18 +choose( v.head_pitch~=0 and is_swimming, -16*(1-v.root_angle), 16*v.root_angle ) +choose( not is_gliding and v.gliding>0, 12*v.gliding, 0 )
    v.root_tz = -sin(v.root_rx) *12 *(1-0.5 *v.swim*(1-v.gliding))
    v.pre_rotx = rot_x
    v.pre_roty = rot_y
    v.pre_posy = pos_y
    v.pre_ls = limb_speed
    v.frame_counter_prev = frame_counter

    -- idle: a_player_idle.jpm
    v.idl_bodyrx = torad(12*sin( v.headpitch_drag/180*pi ) +sin(v.Bt) )*v.idle
    v.idl_bodyry = torad( 7*clamp(v.headyaw_speed*2,-1,1) +16*sin( v.headyaw_drag/180*pi ) +2*sin(v.Bt/2)*(1+v.sneak) )*v.idle*(1-v.laying)
    v.idl_bodytx = (0.25*sin( v.Bt/2)*(1+v.sneak-v.sit) )*v.idle*(1-v.laying)-v.idl_bodyrx*v.idl_bodyry*16
    v.idl_bodyty = 0.5*v.sit +( 0.05 +0.1*sin(pi/12 +v.Bt) ) *(1-v.laying)*(1-v.gliding)
    v.idl_bodytz = 1.8*v.sit +( 0.1*sin( v.Bt) )-v.laying
    v.idl_headrx = torad( 60*sin(head_pitch/180*pi)*(1-v.gliding) )*clamp(1-v.sneak/4*v.walk +(-0.3-v.walk)*v.prone, 0, 1-v.swim+v.gliding ) +torad( 13*clamp(abs(v.headyaw_speed*2),-1,1) +10*clamp(v.headpitch_speed*3,-1,1) ) +( torad( 20 -sin(v.Bt-cos(v.Bt)*v.sleep) ) )*v.laying
    v.idl_headry = torad( v.hy/1.1)*clamp(1-v.sneak/8*v.walk , 0, 1-choose(vb.v21_2_plus,v.climb,0) ) +torad( 10*clamp(v.headyaw_speed*2 ,-1,1) )
    v.idl_headrz = choose( vb.v21_2_plus, 0, torad(-v.hy/2*(1-head_pitch/45) )*v.prone )+torad( -7*clamp(v.headyaw_speed*2 ,-1,1) )
    v.idl_headty = 0.03*( 1 -cos(v.Bt) )
    v.idl_rarmrx = torad( 5*clamp(v.headyaw_speed*2,-1,1) -5*clamp(v.headpitch_speed*3,-1,1)+choose( is_right_handed,( v.headyaw_drag/6 )*v.requip, 0) )*v.idle+torad( 20*(1-v.in_air))*v.sneak+torad(-30*(1-v.rswingingA) )*v.sit
    v.idl_larmrx = torad(-5*clamp(v.headyaw_speed*2,-1,1) -5*clamp(v.headpitch_speed*3,-1,1)+choose(not is_right_handed,(-v.headyaw_drag/6 )*v.lequip, 0) )*v.idle+torad( 20*(1-v.in_air))*v.sneak+torad(-30*(1-v.lswingingA) )*v.sit
    v.idl_rarmry = torad( 8*sin( v.headyaw_drag/180*pi )+cos(v.Bt)+0.5+choose( is_right_handed, 3 +( -6 )*v.requip, 0) )*v.idle+torad(-5 *(1-v.rswingingA) )*v.sit
    v.idl_larmry = torad( 8*sin( v.headyaw_drag/180*pi )-cos(v.Bt)-0.5+choose(not is_right_handed,-3 +(6 )*v.lequip, 0) )*v.idle+torad( 5 *(1-v.lswingingA) )*v.sit
    v.idl_rarmrz = torad( 8*sin( v.headpitch_drag/180*pi )*v.headpitch_drag/90+cos(-pi/12 +v.Bt)/1.6*(1-0.7*v.laying) +2 )*v.idle+torad( 10 )*v.sneak+torad( 10*(1-v.rswingingA) )*v.sit
    v.idl_larmrz = torad(-8*sin( v.headpitch_drag/180*pi )*v.headpitch_drag/90-cos(-pi/12 +v.Bt)/1.6*(1-0.7*v.laying) -2 )*v.idle+torad(-10 )*v.sneak+torad(-10*(1-v.lswingingA) )*v.sit
    v.idl_rarmty = 0.5*v.sit +( sin(-pi/15 +v.Bt)/6 +0.3 )*(1-0.7*v.laying)
    v.idl_larmty = 0.5*v.sit +( sin(-pi/15 +v.Bt)/6 +0.3 )*(1-0.7*v.laying)
    v.idl_rarmtz = -0.5*v.sit +v.idl_bodyrx*v.laying
    v.idl_larmtz = -0.5*v.sit +v.idl_bodyrx*v.laying
    v.idl_rlegrx = torad(-85 )*v.sit
    v.idl_llegrx = torad(-85 )*v.sit
    v.idl_rlegry = torad( 25-5 )*v.sit
    v.idl_llegry = torad(-25+5 )*v.sit
    v.idl_rlegrz = torad(-30*0 )*v.sit +torad( 2 )*v.idle
    v.idl_llegrz = torad( 30*0 )*v.sit +torad(-2 )*v.idle
    v.idl_rlegtx = -0.1*v.idle*(1-v.laying)
    v.idl_llegtx = 0.1*v.idle*(1-v.laying)
    v.idl_rlegty = v.sit
    v.idl_llegty = v.sit
    v.idl_rlegtz = v.sit +( 0.4*cos(v.ls) )*v.idle*(1-v.laying)-v.laying
    v.idl_llegtz = v.sit +(-0.4*cos(v.ls) )*v.idle*(1-v.laying)-v.laying
    v.idl_rfootrx = torad( ( 1+sin(pi/4 +v.Bt) )/2-( 2*sin( v.headyaw_drag/180*pi ) )*(1-v.sit/2) )*v.idle*(1-v.laying)
    v.idl_lfootrx = torad( ( 1+sin(pi/4 +v.Bt) )/2+( 2*sin( v.headyaw_drag/180*pi ) )*(1-v.sit/2) )*v.idle*(1-v.laying)
    v.idl_rfootry = torad( ( 10+10*cos(v.ls) )*(1-v.sit) )*v.idle*(1-v.laying)
    v.idl_lfootry = torad( (-10+10*cos(v.ls) )*(1-v.sit) )*v.idle*(1-v.laying)
    v.idl_rfootrz = torad( sin(v.Bt/2)*(1+v.sneak-v.sit) )*v.idle*(1-v.laying)
    v.idl_lfootrz = torad( sin(v.Bt/2)*(1+v.sneak-v.sit) )*v.idle*(1-v.laying)

    -- equipment: a_player_equipment.jpm
    v.eqp_bodyrx = ( sin( sqrt(swing_progress)*pi )*0.1 )*(v.rswingingA+v.lswingingA)
    v.eqp_bodyry = ( v.attC*0.15 -0.4*v.idle)*(v.rswingingA-v.lswingingA)
    v.eqp_bodytx = ( sin( sqrt(swing_progress)*pi )*0.5 +0.2*v.idle )*(v.rswingingA-v.lswingingA)
    v.eqp_rarmrx = -( 0.3 +0.3*v.sneak )*(1-pow(v.gfast,2))*(1-cos(v.requip*pi))/2*(1-v.rswingingA)+torad( ( -10-90*cos(swing_progress *pi ) *v.attA+( head_pitch-0.7 ) )* v.rswingingA +(-18*v.attC +10*v.idle )* v.lswingingA)
    v.eqp_larmrx = -( 0.3 +0.3*v.sneak )*(1-pow(v.gfast,2))*(1-cos(v.lequip*pi))/2*(1-v.lswingingA)+torad( ( -10-90*cos(swing_progress *pi ) *v.attA+( head_pitch-0.7 ) )* v.lswingingA +(-18*v.attC +10*v.idle )* v.rswingingA)
    v.eqp_rarmry = torad( ((-15+25*cos(swing_progress *pi ))*v.attA -10*v.idle +v.hy/1.5*choose(is_riding,0.5,1) )* v.rswinging-(-10*v.attC -10*v.idle )* v.lswinging )
    v.eqp_larmry = torad(-((-15+25*cos(swing_progress *pi ))*v.attA -10*v.idle +v.hy/1.5*choose(is_riding,0.5,1) )* v.lswinging+(-10*v.attC -10*v.idle )* v.rswinging )
    v.eqp_rarmrz = torad( (-20*sin( (1-swing_progress)*pi ) *v.attA +5 )* v.rswinging-(-5)* v.lswinging )
    v.eqp_larmrz = torad(-(-20*sin( (1-swing_progress)*pi ) *v.attA +5 )* v.lswinging+(-5)* v.rswinging )
    v.eqp_rarmtz = -0.4*v.requip +( ( 2 +2*cos( swing_progress*pi )*v.attA )*(v.rswingingA-v.lswingingA) )*v.rspearhold
    v.eqp_larmtz = -0.4*v.lequip +( ( 2 +2*cos( swing_progress*pi )*v.attA )*(v.lswingingA-v.rswingingA) )*v.lspearhold
    v.eqp_rfootrx = torad( ( 4*v.idle )*v.rswingingA +( sin( sqrt(swing_progress)*pi ) )*v.lswingingA )
    v.eqp_lfootrx = torad( ( 4*v.idle )*v.lswingingA +( sin( sqrt(swing_progress)*pi ) )*v.rswingingA )
    v.spr_rarmrx = torad(-30*v.rspearchrg -20*choose(is_using_item, sin(pow(v.rspearchrg,2)*pi), 0 ) )*choose(is_right_handed,0,1) -v.mvmnt_rarmrz*(4-6*v.rspearchrg)*v.rspearhold
    v.spr_larmrx = torad(-30*v.lspearchrg -20*choose(is_using_item, sin(pow(v.lspearchrg,2)*pi), 0 ) )*choose(is_right_handed,0,1) -v.mvmnt_larmrz*(4-6*v.lspearchrg)*v.lspearhold

    -- movement: a_player_movement.jpm
    v.mvmnt_bodyrx = torad( 20*(1-0.7*v.wade) +(20 -5*cos(v.ls*2))*v.walk )*clamp(v.sneak+v.wade/1.5, 0, 1-v.in_air/3) +torad( 2*cos(v.ls*2) +10*v.sprint +7*v.forwd_drag +5*abs(v.sidwd_drag)*v.strafe )* sqrt(limb_speed)*(v.walk/2 +v.run/2) +torad(-25 +( 5 )*(0.5+0.7*v.crawl) )*v.prone
    v.mvmnt_bodyry = torad( 13*cos(v.ls )*(1 +0.2*v.sprint-0.3*v.wade)*(1-v.laying) )*clamp(sqrt(limb_speed)* v.walk, 0.5*v.idle, 1) +torad( -(12*cos( pi/7 +v.lsc))*(0.5+0.7*v.crawl) )*v.prone
    v.mvmnt_bodyrz = torad( -2*sin(v.ls )*(1-v.run) *v.walk)*v.sneak +torad( -3*sin(v.ls )*(1-0.5*v.run+0.6*v.sprint-0.3*v.wade) -5*v.sidwd_drag *v.strafe )* sqrt(limb_speed)* v.walk +torad( -(-4*cos( v.lsc))*(0.5+0.7*v.crawl) )*v.prone
    v.mvmnt_bodytx = ( -cos(v.ls )*(1-v.run) *v.walk)*clamp(v.sneak*(1-v.climb)+v.wade/3, 0, 1-v.in_air/3 ) +( -cos( v.ls)/2.6*v.mforward*(1+v.sprint) )*sqrt(limb_speed)*v.run*(1-v.jump/2*v.sprint) -( ( 0.5*cos(pi/7 +v.lsc ))*(0.5+0.7*v.crawl) )*v.prone +( v.sidwd_drag*v.sneak )*v.walk*v.strafe
    v.mvmnt_bodyty = (4*(1-0.7*clamp(v.wade-v.walk, 0, 1)) -2 *v.walk)*clamp(v.sneak*(1-v.climb)+v.wade/2, 0, 1-v.in_air/1.5) +( sin(pi/4+v.ls*2 -cos(pi/4+v.ls*2)/6) +0.8 )*0.8*v.walk*(1-v.sneak/3)*(1-v.run)*(1-v.in_air) +( -cos(pi/4+v.ls*2 -cos(v.ls*2)/4) )*sqrt(limb_speed)*v.run*(1-v.in_air) +( 1.5 +(0.6+0.6*cos(pi/9 +v.lsc*2-cos(pi/9 +v.lsc*2)/3))*(0.5+0.7*v.crawl) )*v.prone
    v.mvmnt_bodytz = (2*(1-0.7*clamp(v.wade-v.walk, 0, 1)) +(2 -0.5*sin(v.ls*2 -cos(v.ls*2)/3)*(1-v.run))*v.walk)*clamp(v.sneak*(1-v.climb)+v.wade/2, 0, 1-v.in_air/3 ) +(-2*v.walk)*v.wade +(-0.5 +( 1+0.3*sin( v.lsc*2 ))*(0.5+0.7*v.crawl) -3*v.climb )*v.prone +v.sneak
    v.mvmnt_headrx = torad( ( 15 +3*sin(v.lsc*2))*(0.5+0.7*v.crawl) -60*(1-v.climb/2) )*v.prone +torad(5*v.walk)*v.sneak
    v.mvmnt_headry = torad( ( -3*cos(v.lsc ))*(0.5+0.7*v.crawl) )*v.prone +choose( vb.v21_2_plus, torad(-25*v.sidwd_drag)*v.walk*v.strafe +( sin((torad(v.hy)-v.climb_direction) -sin((torad(v.hy)-v.climb_direction)*2)/6 )*1.5 )*v.climb, 0 )
    v.mvmnt_headty = v.sneak
    v.mvmnt_headtz = -v.prone
    v.mvmnt_rarmrx = torad( 60*cos(pi/7+v.ls)*(1-0.2*v.walk +0.2*v.sprint) +10*v.mforward -10*v.wade ) *sqrt(limb_speed)*v.walk *(1-v.in_air/3 )*(1-v.requip/(2+0.8*v.sprint)) +torad(-30*(1-v.rswingingA))*v.wade*(1-v.raction-v.laction/1.5) +torad(-135 -(-5 +12*cos(v.lsc +cos(v.lsc)/2) -10*sin(v.lsc +cos(v.lsc) ) )*(0.5+0.7*v.crawl) +sin(v.Bt) )*v.prone
    v.mvmnt_larmrx = torad( -60*cos(pi/7+v.ls)*(1-0.2*v.walk +0.2*v.sprint) +10*v.mforward -10*v.wade ) *sqrt(limb_speed)*v.walk *(1-v.in_air/3 )*(1-v.lequip/(2+0.8*v.sprint)) +torad(-30*(1-v.lswingingA))*v.wade*(1-v.laction-v.raction/1.5) +torad(-135 -(-5 -12*cos(v.lsc -cos(v.lsc)/2) +10*sin(v.lsc -cos(v.lsc) ) )*(0.5+0.7*v.crawl) +sin(v.Bt) )*v.prone
    v.mvmnt_rarmry = torad( ( 18*cos( v.ls) -10*(0.8+cos(-1.3+v.ls -sin(-1.3+v.ls)/1.5)) )*(1+v.sprint)/2*(1-v.fall) +( 5 -10*cos(pi/3+v.ls))*v.sneak )*(sqrt(limb_speed)*v.walk+v.idle)*(1-v.prone-v.sit)*(1-v.gliding)*(1-v.in_air/1.5)*(1-v.requip/(2+0.8*v.sprint)) +torad( 15*(1-v.rswingingA))*v.wade*(1-v.raction-v.laction/1.5) +torad( 3 -( 4 *sin(v.lsc +cos(v.lsc) ) -4*cos(-pi/6 +v.lsc) )*(0.5+0.7*v.crawl) )*v.prone
    v.mvmnt_larmry = torad( ( 18*cos( v.ls) +10*(0.8-cos(-1.3+v.ls +sin(-1.3+v.ls)/1.5)) )*(1+v.sprint)/2*(1-v.fall) +( -5 -10*cos(pi/3+v.ls))*v.sneak )*(sqrt(limb_speed)*v.walk+v.idle)*(1-v.prone-v.sit)*(1-v.gliding)*(1-v.in_air/1.5)*(1-v.lequip/(2+0.8*v.sprint)) +torad(-15*(1-v.lswingingA))*v.wade*(1-v.laction-v.raction/1.5) +torad( -3 -( 4 *sin(v.lsc -cos(v.lsc) ) -4*cos(-pi/6 +v.lsc) )*(0.5+0.7*v.crawl) )*v.prone
    v.mvmnt_rarmrz = torad( 2 +6*v.sprint +4*cos(pi/5+v.ls) +( 25 +10*cos( v.ls))*v.sneak ) *sqrt(limb_speed)*v.walk *(1-v.requip/(2+0.8*v.sprint)) +torad( 25*(1-v.rswingingA))*v.wade*(1-v.raction-v.laction/1.5)
    v.mvmnt_larmrz = torad(-2 -6*v.sprint +4*cos(pi/5+v.ls) +(-25 +10*cos( v.ls))*v.sneak ) *sqrt(limb_speed)*v.walk *(1-v.lequip/(2+0.8*v.sprint)) +torad(-25*(1-v.lswingingA))*v.wade*(1-v.laction-v.raction/1.5)
    v.mvmnt_rarmtx = ( ( 0.5+cos(v.ls*2))/4 )*sqrt(limb_speed)*v.sprint*(1-v.requip/2) +(-0.7*(1-v.rswingingA))*v.wade
    v.mvmnt_larmtx = ( (-0.5-cos(v.ls*2))/4 )*sqrt(limb_speed)*v.sprint*(1-v.requip/2) +( 0.7*(1-v.lswingingA))*v.wade
    v.mvmnt_rarmty = (-0.5 -( cos(v.lsc +cos(v.lsc)/2.5 ) +0.6*cos(pi/9 +v.lsc*2-cos(pi/9 +v.lsc*2)/3) )*(0.5+0.7*v.crawl) -sin(v.Bt)/2.5 )*v.prone
    v.mvmnt_larmty = (-0.5 -( -cos(v.lsc -cos(v.lsc)/2.5 ) +0.6*cos(pi/9 +v.lsc*2-cos(pi/9 +v.lsc*2)/3) )*(0.5+0.7*v.crawl) -sin(v.Bt)/2.5 )*v.prone
    v.mvmnt_rarmtz = ( 2*cos(v.ls -sin(v.ls)/3*(0.3+0.7*v.sprint)) )*sqrt(limb_speed)*v.walk *(1-v.in_air/1.5)*(1-v.requip/2) *(1-v.rspearhold) +(-1 +(0.5-cos(v.lsc +cos(v.lsc)/2.5 ) )*v.crawl )*v.prone
    v.mvmnt_larmtz = ( -2*cos(v.ls +sin(v.ls)/3*(0.3+0.7*v.sprint)) )*sqrt(limb_speed)*v.walk *(1-v.in_air/1.5)*(1-v.lequip/2) *(1-v.lspearhold) +(-1 +(0.5+cos(v.lsc -cos(v.lsc)/2.5 ) )*v.crawl )*v.prone
    v.mvmnt_rfootrx = torad(6*(1-0.7*v.wade) +6*sin(v.ls)*v.walk )*clamp(v.sneak*(1-v.climb)+v.wade/1.5, 0, 1-v.in_air/1.5)
    v.mvmnt_lfootrx = torad(6*(1-0.7*v.wade) -6*sin(v.ls)*v.walk )*clamp(v.sneak*(1-v.climb)+v.wade/1.5, 0, 1-v.in_air/1.5)
    v.mvmnt_rfootry = torad( 5*v.idle +( 5-5*cos(v.ls) )*v.walk*(1-v.run) )*v.sneak*(1-v.in_air/1.5)
    v.mvmnt_lfootry = torad( -5*v.idle +(-5-5*cos(v.ls) )*v.walk*(1-v.run) )*v.sneak*(1-v.in_air/1.5)
    v.mvmnt_rfootrz = torad( (-1 -2*sin(v.ls) )*v.sneak*v.walk*(1-v.run) )
    v.mvmnt_lfootrz = torad( ( 1 -2*sin(v.ls) )*v.sneak*v.walk*(1-v.run) )
    v.mvmnt_rlegrx = (torad( 10*v.sprint +20*(0.67+0.33*v.mforward) -60*cos(v.ls +cos(v.ls)/4 ) )*sqrt(limb_speed)*v.run*(1-v.in_air/3) +torad( 13*(1-v.sneak/2)*(1-v.idle) -40*cos(v.ls +cos(v.ls)/2.5 ) )*clamp(v.walk, 0.1*v.idle+0.3*v.sneak-0.07*v.laying, 1)*max(0,1-v.run-v.in_air/2-v.gliding) ) +torad(-3 +(-3 -5*cos(pi/4 +v.lsc +sin( v.lsc)/1.3))* v.crawl )*v.prone
    v.mvmnt_llegrx = (torad( 10*v.sprint +20*(0.67+0.33*v.mforward) +60*cos(v.ls -cos(v.ls)/4 ) )*sqrt(limb_speed)*v.run*(1-v.in_air/3) +torad( 13*(1-v.sneak/2)*(1-v.idle) +40*cos(v.ls -cos(v.ls)/2.5 ) )*clamp(v.walk, 0.1*v.idle+0.3*v.sneak-0.07*v.laying, 1)*max(0,1-v.run-v.in_air/2-v.gliding) ) +torad(-3 +(-3 +5*cos(pi/4 +v.lsc -sin( v.lsc)/1.3))* v.crawl )*v.prone
    v.mvmnt_rlegry = -v.root_rz*2*clamp( cos(v.ls)-0.5 -v.yaw_speed*2, 0, 1)*v.walk +torad( 3 +( 5 +9*sin(pi/6 +v.lsc -cos(pi/6 +v.lsc) ))*(0.5+0.7*v.crawl) )*v.prone +torad( 20*max(0, v.sidwd_drag) )*v.walk*v.strafe
    v.mvmnt_llegry = -v.root_rz*2*clamp(-cos(v.ls)-0.5 +v.yaw_speed*2, 0, 1)*v.walk +torad(-3 +(-5 +9*sin(pi/6 +v.lsc +cos(pi/6 +v.lsc) ))*(0.5+0.7*v.crawl) )*v.prone +torad(-20*max(0,-v.sidwd_drag) )*v.walk*v.strafe
    v.mvmnt_rlegrz = -v.root_rz *clamp( cos(v.ls)-0.5 -v.yaw_speed*2, 0, 1)*v.walk +torad( 1 -6*cos(v.ls -cos(v.ls)/1.3) )*sqrt(limb_speed)*(0.5*v.run+0.5*v.sprint) +torad( 1 +( 3-5*sin(v.ls +cos(v.ls) ) )*v.walk )*v.sneak +torad( ( -2*sin( v.lsc -cos( v.lsc) ))*(0.5+0.7*v.crawl) )*v.prone +(-v.mvmnt_rlegrx/2 -torad(2)*abs(v.sidwd_drag) )*v.sidwd_drag*v.walk*v.strafe
    v.mvmnt_llegrz = -v.root_rz *clamp(-cos(v.ls)-0.5 +v.yaw_speed*2, 0, 1)*v.walk +torad( -1 -6*cos(v.ls +cos(v.ls)/1.3) )*sqrt(limb_speed)*(0.5*v.run+0.5*v.sprint) +torad(-1 +(-3-5*sin(v.ls -cos(v.ls) ) )*v.walk )*v.sneak +torad( ( -2*sin( v.lsc +cos( v.lsc) ))*(0.5+0.7*v.crawl) )*v.prone +(-v.mvmnt_llegrx/2 +torad(2)*abs(v.sidwd_drag) )*v.sidwd_drag*v.walk*v.strafe
    v.mvmnt_rlegtx = (-0.05 )*sqrt(limb_speed)*v.run +(-0.3 +(-0.3-0.5*sin( v.lsc -cos( v.lsc) ) )*(0.5+0.7*v.crawl) )*v.prone +( v.mvmnt_rlegtz/1.5 +0.5*max(0,-v.sidwd_drag) -0.5*max(0,v.sidwd_drag) )*v.sidwd_drag*v.walk*v.strafe
    v.mvmnt_llegtx = ( 0.05 )*sqrt(limb_speed)*v.run +( 0.3 +( 0.3-0.5*sin( v.lsc +cos( v.lsc) ) )*(0.5+0.7*v.crawl) )*v.prone +( v.mvmnt_llegtz/1.5 -0.5*max(0,-v.sidwd_drag) +0.5*max(0,v.sidwd_drag) )*v.sidwd_drag*v.walk*v.strafe
    v.mvmnt_rlegty = (-0.4 -2*cos(0.3 +v.ls +cos(0.2 +v.ls)*1.3) )*sqrt(limb_speed)*v.run*(1-v.in_air/1.5)*clamp(1-v.land,0,1) -( -0.3 +clamp(-1.3*sin(v.ls +cos(-pi/4+v.ls)/2.5 ), (-0.45 +0.7*sin(pi/6+v.ls)), 3 ) )*v.walk*(1-v.run)*(1-v.in_air) +(-2 +( 3 *cos(pi/9+v.lsc -cos( pi/9+v.lsc)/2) )*( 1+0.5*v.crawl) )*v.prone
    v.mvmnt_llegty = (-0.4 +2*cos(0.3 +v.ls -cos(0.2 +v.ls)*1.3) )*sqrt(limb_speed)*v.run*(1-v.in_air/1.5)*clamp(1-v.land,0,1) -( -0.3 +clamp( 1.3*sin(v.ls -cos(-pi/4+v.ls)/2.5 ), (-0.45 -0.7*sin(pi/6+v.ls)), 3 ) )*v.walk*(1-v.run)*(1-v.in_air) +(-2 +( -3 *cos(pi/9+v.lsc +cos( pi/9+v.lsc)/2) )*( 1+0.5*v.crawl) )*v.prone
    v.mvmnt_rlegtz = (-2.5 +2.5*sin(0.4 +v.ls +cos( 1 +v.ls)/1.4) )*sqrt(limb_speed)*v.run*(1-v.in_air/1.5) *(1-0.1*v.strafe) +( -1.5 +1.6*sin(v.ls +cos( pi/4+v.ls)/2.5 ) *(1-0.1*v.strafe) )*v.walk*(1-v.run)*(1-v.in_air) +(-3 +( 0.8+0.8*cos( v.lsc +sin(-pi/6+v.lsc)/3) )*v.crawl -2*v.climb )*v.prone +( 0.3 +2*v.walk )*v.sneak
    v.mvmnt_llegtz = (-2.5 -2.5*sin(0.4 +v.ls -cos( 1 +v.ls)/1.4) )*sqrt(limb_speed)*v.run*(1-v.in_air/1.5) *(1-0.1*v.strafe) +( -1.5 -1.6*sin(v.ls -cos( pi/4+v.ls)/2.5 ) *(1-0.1*v.strafe) )*v.walk*(1-v.run)*(1-v.in_air) +(-3 +( 0.8-0.8*cos( v.lsc -sin(-pi/6+v.lsc)/3) )*v.crawl -2*v.climb )*v.prone +( 0.3 +2*v.walk )*v.sneak
    v.udrwtr_bodyrx = torad( 3.5*sin( v.Btsw +sin(v.Btsw)/6)*(1+limb_speed) +2 )*v.tread*(1-v.swim) +torad(-11*cos(v.asw +sin(pi/8 +v.asw)/1.4 ) -11 )*v.swim*(1-v.raction/2-v.laction/2)
    v.udrwtr_bodyry = torad( 5 *sin(-pi/3 +v.Btsw*2 )*(1+0.6*v.swim) )*v.tread*( 1-clamp(-2+limb_speed*3, 0, 1)*v.gliding )*(1-v.raction/2-v.laction/2)
    v.udrwtr_bodyrz = torad( cos(-pi/3 +v.Btsw*2 ) )*v.tread*(1-v.swim)
    v.udrwtr_bodytx = -0.5*cos(pi/3 +v.Btsw*2)*clamp(-6*limb_speed, 0, 4*(1-v.swim))*v.tread
    v.udrwtr_bodyty = ( 0.95*cos(v.asw +sin(pi/9+ v.asw)/2 )+0.15 )*v.swim*(1-v.gliding)
    v.udrwtr_bodytz = ( v.mforward*clamp( 6*limb_speed, 0, 4*(1-v.swim)) )*v.tread +(-0.75*cos(v.asw -sin(pi/6+ v.asw)/5 )-0.75 )*v.swim
    v.udrwtr_headrx = torad( 5*cos(v.Btsw +cos(v.Btsw)/6 )*clamp(3*limb_speed, 0, 1) )*v.tread*(1-v.swim) +torad(-50*(1-0.7*(1-cos(min(1,v.swim_up*4)*pi))/2) +8*cos(pi/4 +v.asw +sin(v.asw)/1.4*(1-0.5*v.swim_up)) )*v.swim
    v.udrwtr_rarmrx = ( torad(-24*cos( pi/5+v.Btsw +sin( pi/5 +v.Btsw )/(1.7+limb_speed)*v.mforward )*clamp(1+limb_speed*3, 0, 2) -10 -5*clamp(3*limb_speed, 0, 1)*v.mforward )*(1-v.swim)*v.tread +torad(-83*cos( v.asw +sin( pi/16 +v.asw)/1.2*(1-0.5*v.swim_up) )-78 )*v.swim )*(1-v.raction-v.laction/2)
    v.udrwtr_larmrx = ( torad(-24*cos( pi/5+v.Btsw +sin( pi/5 +v.Btsw )/(1.7+limb_speed)*v.mforward )*clamp(1+limb_speed*3, 0, 2) -10 -5*clamp(3*limb_speed, 0, 1)*v.mforward )*(1-v.swim)*v.tread +torad(-83*cos( v.asw +sin( pi/16 +v.asw)/1.2*(1-0.5*v.swim_up) )-78 )*v.swim )*(1-v.laction-v.raction/2)
    v.udrwtr_rarmry = ( torad(-18*cos(-pi/5+v.Btsw -sin(-pi/2.5+v.Btsw )/1.5 ) -5*sin(-pi/3+v.Btsw*2) -7 +14*clamp(3*limb_speed, 0, 1) )*(1-v.swim)*v.tread +torad( 40*cos(-pi/4 +v.asw +sin(-pi/4 -pi/12 +v.asw)/1.2*(1-0.5*v.swim_up) )+24 )*v.swim )*(1-v.raction-v.laction/2)
    v.udrwtr_larmry = ( torad( 18*cos(-pi/5+v.Btsw -sin(-pi/2.5+v.Btsw )/1.5 ) -5*sin(-pi/3+v.Btsw*2) +7 -14*clamp(3*limb_speed, 0, 1) )*(1-v.swim)*v.tread +torad(-40*cos(-pi/4 +v.asw +sin(-pi/4 -pi/12 +v.asw)/1.2*(1-0.5*v.swim_up) )-24 )*v.swim )*(1-v.laction-v.raction/2)
    v.udrwtr_rarmrz = ( torad(-10*sin( pi/8+v.Btsw +sin( pi/8 +v.Btsw*2 )/5 )*v.tread +15 )*(1-v.swim)*v.water +torad( 30*sin( v.asw -cos( pi/10 +v.asw)*1.3*(1-0.5*v.swim_up) )+34 )*v.swim )*(1-v.raction-v.laction/2)
    v.udrwtr_larmrz = ( torad( 10*sin( pi/8+v.Btsw +sin( pi/8 +v.Btsw*2 )/5 )*v.tread -15 )*(1-v.swim)*v.water +torad(-30*sin( v.asw -cos( pi/10 +v.asw)*1.3*(1-0.5*v.swim_up) )-34 )*v.swim )*(1-v.laction-v.raction/2)
    v.udrwtr_rarmtx = ( clamp( 2*cos(v.asw ) -0.5, -0.3, 2) )*v.swim
    v.udrwtr_larmtx = ( clamp(-2*cos(v.asw ) +0.5, -2, 0.3) )*v.swim
    v.udrwtr_rarmty = ( -2*cos(v.asw +sin(v.asw)/1.3 ) -1 )*v.swim
    v.udrwtr_larmty = ( -2*cos(v.asw +sin(v.asw)/1.3 ) -1 )*v.swim
    v.udrwtr_rarmtz = ( ((-cos(v.Btsw +sin(pi/10 +v.Btsw )/2 ) -0.3 )*(1-v.swim) +5*sin(-pi/3 +v.Btsw*2)*(1+0.6*v.swim)/15 )*v.tread +( clamp(-2*cos(v.asw ) +0.5, -2, 0 ) )*v.swim )*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_larmtz = ( ((-cos(v.Btsw +sin(pi/10 +v.Btsw )/2 ) -0.3 )*(1-v.swim) -5*sin(-pi/3 +v.Btsw*2)*(1+0.6*v.swim)/15 )*v.tread +( clamp(-2*cos(v.asw ) +0.5, -2, 0 ) )*v.swim )*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_rlegrx = torad(-24 *cos(-pi/8 +v.Btsw*2 )*(1+limb_speed) +8*(1-v.swim) )*v.tread *(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_llegrx = torad( 24 *cos(-pi/8 +v.Btsw*2 )*(1+limb_speed) +8*(1-v.swim) )*v.tread *(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_rlegry = torad( 5.5*cos( v.Btsw*2 +sin(v.Btsw*2)/3 ) +9.5 )*v.tread*clamp(1-3*limb_speed, 0, 1)*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_llegry = torad( 5.5*cos( v.Btsw*2 -sin(v.Btsw*2)/3 ) -9.5 )*v.tread*clamp(1-3*limb_speed, 0, 1)*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_rlegrz = torad(-5.5*sin( v.Btsw*2 ) +5*clamp(1-3*limb_speed, 0, 1) )*v.tread*(1-v.swim) *(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_llegrz = torad(-5.5*sin( v.Btsw*2 ) -5*clamp(1-3*limb_speed, 0, 1) )*v.tread*(1-v.swim) *(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_rlegtx = ( (-0.1 +( 0.1 )*v.swim )*v.tread )*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_llegtx = ( ( 0.1 +(-0.1 )*v.swim )*v.tread )*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_rlegty = ( (-0.5 +0.7*sin(pi/4 +v.Btsw*2 +sin(pi/3 +v.Btsw*2 )/3)*clamp(1+6*limb_speed*v.mforward,-1, 1) )*v.tread*(1-v.swim) +( cos(v.asw +sin( v.asw)/1.5) )*v.swim*(1-v.gliding) )*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_llegty = ( (-0.5 -0.7*sin(pi/4 +v.Btsw*2 -sin(pi/3 +v.Btsw*2 )/3)*clamp(1+6*limb_speed*v.mforward,-1, 1) )*v.tread*(1-v.swim) +( cos(v.asw +sin( v.asw)/1.5) )*v.swim*(1-v.gliding) )*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_rlegtz = ( ( sin( v.Btsw*2 ) -1 +clamp(6*limb_speed, 0, 4)*v.mforward*(1-v.swim) )*v.tread +(-0.75*cos(v.asw -sin(pi/6 +v.asw)/5 )-0.5 )*v.swim )*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.udrwtr_llegtz = ( ( -sin( v.Btsw*2 ) -1 +clamp(6*limb_speed, 0, 4)*v.mforward*(1-v.swim) )*v.tread +(-0.75*cos(v.asw -sin(pi/6 +v.asw)/5 )-0.5 )*v.swim )*(1-clamp(-2+limb_speed*3, 0, 1)*v.gliding)
    v.vrtcl_bodyrx = torad( (-10*(0.2+0.8*limb_speed) +5*sin(v.lsj/2) )*v.fall +(-8*(1-cos(v.ls*2))*v.idle +(30*cos(v.t_jump*pi))*(v.prone-v.climb) )*exp(-v.t_jump*pi)*v.jump*min(1, v.water +v.prone ) +( 20*pow(limb_speed,2)*v.mforward )*(v.Rjump+v.Ljump) -8*sin(v.t_Rjump*5)*v.Rjump -8*sin(v.t_Ljump*5)*v.Ljump +15*sin(-pi/6+v.t_land*4)*(1+limb_speed*v.mforward)*v.land*(1-v.sprjmp) )
    v.vrtcl_bodyry = torad( ( 7*sin(v.lsj ) )*v.fall +( 10*pow(limb_speed,2) +10 )*(v.Rjump-v.Ljump) )
    v.vrtcl_bodyrz = torad( ( -3*cos(v.lsj ) )*v.fall +( (-1-sin(v.t_Rjump*pi*2) )*v.Rjump +( 1+sin(v.t_Ljump*pi*2) )*v.Ljump ) )
    v.vrtcl_bodytx = ( (-1+cos(v.t_Rjump*pi*2) )*v.Rjump +( 1-cos(v.t_Ljump*pi*2) )*v.Ljump )/2*pow(limb_speed,2)*v.mforward -2*v.vrtcl_bodyrx*v.vrtcl_bodyry
    v.vrtcl_bodyty = exp(cos(-pi/4+v.t_land*pi))*(2-limb_speed/1.5)*v.land*(1-v.sprjmp)*(1-v.sneak/2) +(12-8*v.water)*(1.2+0.4*v.sneak)*(1-v.prone)*exp(-v.t_jump*pi)*v.jump
    v.vrtcl_bodytz = cos(-pi/4+v.t_land*pi) *(1-limb_speed/2 )*v.land*(1-v.sprjmp)*(1-v.prone)
    v.vrtcl_headrx = torad( 5*cos(v.t_jump*pi/2)*v.jump*(1-2*v.water) +( 3 -10*cos(pi/4+v.t_land*3) )*v.land )
    v.vrtcl_headty = 2*exp(-v.t_jump*pi)*v.jump*(1-v.water)
    v.vrtcl_rarmrx = torad( (-60*exp(-v.t_jump*pi)*limb_speed*v.mforward*(1-v.sprint) +(30*cos(v.t_jump*pi))*(v.prone-v.climb) )*v.jump*min(1, v.water +v.prone ) +( ( (15+45*pow(limb_speed,2))*sin(v.t_Rjump*pi) )*v.Rjump +( (-20-60*pow(limb_speed,2))*sin(v.t_Ljump*pi) )*v.Ljump )*(1-v.prone)*(1-v.requip/2) +( -5 +10*limb_speed +30*sin(v.lsj)*(1-v.requip/2) )*v.fall*(1-v.raction)*(1-v.tread) +( 30*sin(-pi/6+v.t_land*4)*v.idle*v.requip -5*exp(cos(-pi/4+v.t_land*pi))*v.prone )*v.land )
    v.vrtcl_larmrx = torad( (-60*exp(-v.t_jump*pi)*limb_speed*v.mforward*(1-v.sprint) +(30*cos(v.t_jump*pi))*(v.prone-v.climb) )*v.jump*min(1, v.water +v.prone ) +( ( (15+45*pow(limb_speed,2))*sin(v.t_Ljump*pi) )*v.Ljump +( (-20-60*pow(limb_speed,2))*sin(v.t_Rjump*pi) )*v.Rjump )*(1-v.prone)*(1-v.lequip/2) +( -5 +10*limb_speed -30*sin(v.lsj)*(1-v.lequip/2) )*v.fall*(1-v.laction)*(1-v.tread) +( 30*sin(-pi/6+v.t_land*4)*v.idle*v.lequip -5*exp(cos(-pi/4+v.t_land*pi))*v.prone )*v.land )
    v.vrtcl_rarmry = torad( ( ( -10 *sin(v.t_Rjump*pi) )*v.Rjump +( -20 *sin(v.t_Ljump*pi) )*v.Ljump )*(1-v.prone) +( 30*limb_speed -10*sin(v.lsj)*(1-v.requip/2) +30*v.requip )*v.fall*(1-v.raction)*max(0,1-v.swim-v.sprjmp-v.prone) )
    v.vrtcl_larmry = torad( ( ( 10 *sin(v.t_Ljump*pi) )*v.Ljump +( 20 *sin(v.t_Rjump*pi) )*v.Rjump )*(1-v.prone) +( -30*limb_speed -10*sin(v.lsj)*(1-v.lequip/2) -30*v.lequip )*v.fall*(1-v.laction)*max(0,1-v.swim-v.sprjmp-v.prone) )
    v.vrtcl_rarmrz = torad( ( ( 45*v.sneak *sin(v.t_Rjump*pi) )*v.Rjump +( 45*v.sneak *sin(v.t_Ljump*pi) )*v.Ljump )*(1-v.prone)*(1-v.requip/2) +( 100 -10*cos(v.lsj)*(1-v.requip/2) -30*v.requip )*v.fall*(1-v.raction)*max(0,1-v.swim-v.sprjmp-v.prone) +( 10*abs(cos(v.t_land*pi)) -3 )*v.land )
    v.vrtcl_larmrz = torad( ( ( -45*v.sneak *sin(v.t_Ljump*pi) )*v.Ljump +( -45*v.sneak *sin(v.t_Rjump*pi) )*v.Rjump )*(1-v.prone)*(1-v.lequip/2) +( -110 -10*cos(v.lsj)*(1-v.lequip/2) +30*v.lequip )*v.fall*(1-v.laction)*max(0,1-v.swim-v.sprjmp-v.prone) -( 10*abs(cos(v.t_land*pi)) -3 )*v.land )
    v.vrtcl_rarmtx = -v.fall*(1-v.swim)*(1-v.raction) +0.5*pow(limb_speed,2)*v.Ljump
    v.vrtcl_larmtx = v.fall*(1-v.swim)*(1-v.laction) -0.5*pow(limb_speed,2)*v.Ljump
    v.vrtcl_rarmty = -cos(pi/4+v.t_land*3)*v.land +( -v.vrtcl_rarmrz )*v.fall +( 0.3-sin(v.ls) )/2*sin(v.t_jump*pi)*v.jump*min(1, v.water +v.prone ) +( -1 )*v.Ljump
    v.vrtcl_larmty = -cos(pi/4+v.t_land*3)*v.land +( v.vrtcl_larmrz )*v.fall +( 0.3+sin(v.ls) )/2*sin(v.t_jump*pi)*v.jump*min(1, v.water +v.prone ) +( -1 )*v.Rjump
    v.vrtcl_rarmtz = v.vrtcl_rarmrx*2*v.fall*(1-v.raction) +(-3*cos(v.t_jump*2))*(v.prone-v.climb)*v.jump +( 2.5*pow(limb_speed,2) )*(v.Rjump-v.Ljump)
    v.vrtcl_larmtz = v.vrtcl_larmrx*2*v.fall*(1-v.laction) +(-3*cos(v.t_jump*2))*(v.prone-v.climb)*v.jump +( 2.5*pow(limb_speed,2) )*(v.Ljump-v.Rjump)
    v.vrtcl_rfootrx = torad( 15*exp(cos(-pi/4+v.t_land*pi))/3*sqrt(v.land) )*(1-v.sprjmp)
    v.vrtcl_lfootrx = torad( 15*exp(cos(-pi/4+v.t_land*pi))/3*sqrt(v.land) )*(1-v.sprjmp)
    v.vrtcl_rlegrx = torad( (-20*sin(v.lsj)*(1-v.water) -23*clamp(v.vertical_speed, -1, 1 )*limb_speed*v.mforward )*v.fall +( 20*(1-sin(v.ls)) -(90*cos(v.t_jump*pi))*(v.prone-v.climb) )*exp(-v.t_jump*pi)*v.jump*min(1, v.water +v.prone ) +( ( ( (20+20*pow(limb_speed,2))*cos(min(3,v.t_Rjump*4)) -70*pow(limb_speed,2)*sin(v.t_Rjump*1.5*pi) )*v.Rjump*(1-clamp(-0.3-v.vertical_speed,0,2)) +( 80*pow(limb_speed,2)*(2-v.Ljump) )*sin(v.t_Ljump*pi +sin(v.t_Ljump*pi)/2 ) )*min(1,1+v.mforward) +( ( -(20+40*pow(limb_speed,2)) -70*pow(limb_speed,2)*sin(v.t_Ljump*1.5*pi) )*v.Ljump +( 60*pow(limb_speed,2)*(2-v.Rjump) )*sin(v.t_Rjump*pi +sin(v.t_Rjump*pi)/2 ) )*min(0,v.mforward) )*(1-min(1, v.water +v.prone +v.flying/2 )) )
    v.vrtcl_llegrx = torad( ( 20*sin(v.lsj)*(1-v.water) -23*clamp(v.vertical_speed, -1, 1 )*limb_speed*v.mforward )*v.fall +( 20*(1+sin(v.ls)) -(90*cos(v.t_jump*pi))*(v.prone-v.climb) )*exp(-v.t_jump*pi)*v.jump*min(1, v.water +v.prone ) +( ( ( (20+20*pow(limb_speed,2))*cos(min(3,v.t_Ljump*4)) -70*pow(limb_speed,2)*sin(v.t_Ljump*1.5*pi) )*v.Ljump*(1-clamp(-0.3-v.vertical_speed,0,2)) +( 80*pow(limb_speed,2)*(2-v.Rjump) )*sin(v.t_Rjump*pi +sin(v.t_Rjump*pi)/2 ) )*min(1,1+v.mforward) +( ( -(20+40*pow(limb_speed,2)) -70*pow(limb_speed,2)*sin(v.t_Rjump*1.5*pi) )*v.Rjump +( 60*pow(limb_speed,2)*(2-v.Ljump) )*sin(v.t_Ljump*pi +sin(v.t_Ljump*pi)/2 ) )*min(0,v.mforward) )*(1-min(1, v.water +v.prone +v.flying/2 )) )
    v.vrtcl_rlegry = torad( ( 7*sin(v.lsj)*(1-v.water) +10 )*v.fall +( 6*sin(pi/4 +v.t_Ljump*pi) )*v.Ljump*pow(limb_speed,2) )
    v.vrtcl_llegry = torad( ( 7*sin(v.lsj)*(1-v.water) -10 )*v.fall +( -6*sin(pi/4 +v.t_Rjump*pi) )*v.Rjump*pow(limb_speed,2) )
    v.vrtcl_rlegrz = torad( 5 *v.fall +( -17*v.t_Rjump +5*cos(v.t_Rjump*pi) )*v.Rjump*pow(limb_speed,2) +( 7*pow(limb_speed,2) )*v.Ljump )
    v.vrtcl_llegrz = torad( -5 *v.fall +( 17*v.t_Ljump -5*cos(v.t_Ljump*pi) )*v.Ljump*pow(limb_speed,2) +(-7*pow(limb_speed,2) )*v.Rjump )
    v.vrtcl_rlegtx = -0.2*( v.Rjump +v.Ljump*pow(limb_speed,2) )
    v.vrtcl_llegtx = 0.2*( v.Ljump +v.Rjump*pow(limb_speed,2) )
    v.vrtcl_rlegty = ( (13-8*v.water)*1.2*(1-v.prone) )*exp(-v.t_jump*pi)*v.jump +( ( 3*pow(limb_speed,2)*cos(min(2,v.t_Rjump*4)) -12*exp(-min(1,v.t_Rjump*1.5)*pi) )*v.Rjump +2*v.sneak*v.Ljump )*min(1,1+v.mforward)*(1-v.prone) +( -3*pow(limb_speed,2)*cos(min(2,v.t_Ljump*3)) +12*exp(-min(1,v.t_Ljump*3)*pi) )*v.Ljump*min(0,v.mforward)*(1-v.prone) +(1-cos(v.mvmnt_rlegrx*2))*2*v.land
    v.vrtcl_llegty = ( (13-8*v.water)*1.2*(1-v.prone) )*exp(-v.t_jump*pi)*v.jump +( ( 3*pow(limb_speed,2)*cos(min(2,v.t_Ljump*4)) -12*exp(-min(1,v.t_Ljump*1.5)*pi) )*v.Ljump +2*v.sneak*v.Rjump )*min(1,1+v.mforward)*(1-v.prone) +( -3*pow(limb_speed,2)*cos(min(2,v.t_Rjump*3)) +12*exp(-min(1,v.t_Rjump*3)*pi) )*v.Rjump*min(0,v.mforward)*(1-v.prone) +(1-cos(v.mvmnt_llegrx*2))*2*v.land
    v.vrtcl_rlegtz = ( ( -2*pow(limb_speed,2)*cos(min(2,v.t_Rjump*4)) -5 *exp(- v.t_Rjump *pi) )*v.Rjump*(1-0.5*clamp(-0.3-v.vertical_speed,0,1)) +(-1+1.5*sin(v.t_Ljump*pi) )*2*pow(limb_speed,2)*v.Ljump )*min(1,1+v.mforward)*(1-v.prone) +( 2*pow(limb_speed,2)*cos(min(2,v.t_Ljump*4)) +4 *exp(- v.t_Ljump *pi) )*v.Ljump*min(0,v.mforward)*(1-v.prone)
    v.vrtcl_llegtz = ( ( -2*pow(limb_speed,2)*cos(min(2,v.t_Ljump*4)) -5 *exp(- v.t_Ljump *pi) )*v.Ljump*(1-0.5*clamp(-0.3-v.vertical_speed,0,1)) +(-1+1.5*sin(v.t_Rjump*pi) )*2*pow(limb_speed,2)*v.Rjump )*min(1,1+v.mforward)*(1-v.prone) +( 2*pow(limb_speed,2)*cos(min(2,v.t_Rjump*4)) +4 *exp(- v.t_Rjump *pi) )*v.Rjump*min(0,v.mforward)*(1-v.prone)
    v.vrtcl_rlegsy = 0.3*exp(-min(1,v.t_Ljump*2)*pi)*v.Ljump*(1-v.water)
    v.vrtcl_llegsy = 0.3*exp(-min(1,v.t_Rjump*2)*pi)*v.Rjump*(1-v.water)
    v.gldng_bodyry = torad( 5*cos(limb_swing/25 +sin(limb_swing/40)/4) +v.lleg_pitch*3 )*v.gliding
    v.gldng_bodyrz = torad( v.gliderleg_drag*9 )*v.gliding
    v.gldng_bodytx = ( -cos(limb_swing/25 +sin(limb_swing/40)/4 +pi/8) )*v.gliding
    v.gldng_bodytz = (-2*cos(limb_swing/33 +sin(limb_swing/40)/4 +pi/8) +2 )*v.gliding
    v.gldng_headrx = torad(-20*v.pitch_speed*5 )*v.gliding
    v.gldng_headry = torad( -v.lleg_pitch*2 )*v.gliding
    v.gldng_headrz = torad( -v.hy/1.5 )*v.gliding
    v.gldng_rarmrx = torad( 30*clamp( v.yaw_speed*10, -1, 1) -5 *(1-cos((1-pow(v.gfast,2))*pi))/2 +sin(age/2)*(v.hy/4) +0.5*cos(limb_swing*1.5)*pow(v.gfast,2) +(v.lleg_pitch*9)*(1-v.requip/2) +20*clamp(v.pitch_speed*5,-1,1) )*v.gliding
    v.gldng_larmrx = torad( -30*clamp( v.yaw_speed*10, -1, 1) -5 *(1-cos((1-pow(v.gfast,2))*pi))/2 -sin(age/2)*(v.hy/4) -0.5*cos(limb_swing*1.5)*pow(v.gfast,2) -(v.lleg_pitch*9)*(1-v.lequip/2) +20*clamp(v.pitch_speed*5,-1,1) )*v.gliding
    v.gldng_rarmry = torad( -v.hy/3 +20*clamp( v.yaw_speed*10, -1, 1) +40*(1-cos((1-pow(v.gfast,2))*pi))/2 +(1-v.requip)*sin(limb_swing*1.5)*pow(v.gfast,2) )*v.gliding
    v.gldng_larmry = torad( -v.hy/3 +20*clamp( v.yaw_speed*10, -1, 1) -40*(1-cos((1-pow(v.gfast,2))*pi))/2 -(1-v.lequip)*sin(limb_swing*1.5)*pow(v.gfast,2) )*v.gliding
    v.gldng_rarmrz = torad(( v.hy/45*v.hy*pow(v.gfast,2) -3*clamp( v.yaw_speed*10, -1, 1)) -10*pow(v.gfast,2) -v.gliderleg_drag*20*(1-v.requip) )*v.gliding
    v.gldng_larmrz = torad((-v.hy/45*v.hy*pow(v.gfast,2) +3*clamp( v.yaw_speed*10, -1, 1)) +10*pow(v.gfast,2) -v.gliderleg_drag*20*(1-v.lequip) )*v.gliding
    v.gldng_rlegrx = torad( 20*clamp( v.yaw_speed*10, -1, 1) +cos(pi/6 +age/2) *(v.hy/8) -0.5*cos(limb_swing*1.5)*pow(v.gfast,2) +45*clamp(v.pitch_speed*5,-1,1) -v.lleg_pitch*10 )*v.gliding +choose( not is_gliding and v.gliding>0, torad(-60)*v.gliding, 0 )
    v.gldng_llegrx = torad( -20*clamp( v.yaw_speed*10, -1, 1) -cos(pi/6 +age/2) *(v.hy/8) +0.5*cos(limb_swing*1.5)*pow(v.gfast,2) +45*clamp(v.pitch_speed*5,-1,1) +v.lleg_pitch*10 )*v.gliding +choose( not is_gliding and v.gliding>0, torad(-60)*v.gliding, 0 )
    v.gldng_rlegry = torad( 3 +30*clamp( v.yaw_speed*10, -1, 1) )*v.gliding
    v.gldng_llegry = torad(-3 +30*clamp( v.yaw_speed*10, -1, 1) )*v.gliding
    v.gldng_rlegrz = torad( 0.5 -clamp( v.yaw_speed*10, -1, 1)/2 *v.hy*pow(v.gfast,2) +sin(age/2)/2*(v.hy/4) +0.5*cos(limb_swing*1.3)*pow(v.gfast,2) +2*cos(pi/8 +limb_swing/33 +sin(limb_swing/40)/4) +v.gliderleg_drag*17 )*v.gliding
    v.gldng_llegrz = torad( 0.5 +clamp( v.yaw_speed*10, -1, 1)/2 *v.hy*pow(v.gfast,2) +sin(age/2)/2*(v.hy/4) +0.5*cos(limb_swing*1.3)*pow(v.gfast,2) +2*cos(pi/8 +limb_swing/33 +sin(limb_swing/40)/4) +v.gliderleg_drag*17 )*v.gliding
    v.gldng_rlegtx = ( -cos(pi/8 +limb_swing/25 +sin(limb_swing/40)/4) )*v.gliding
    v.gldng_llegtx = ( -cos(pi/8 +limb_swing/25 +sin(limb_swing/40)/4) )*v.gliding
    v.gldng_rlegtz = ( -2*cos(pi/8 +limb_swing/33 +sin(limb_swing/40)/4) +2 +v.lleg_pitch/5 )*v.gliding
    v.gldng_llegtz = ( -2*cos(pi/8 +limb_swing/33 +sin(limb_swing/40)/4) +2 -v.lleg_pitch/5 )*v.gliding
    v.fly_bodyrx = torad( 3*cos( pi/4+v.lsF )*limb_speed -15*v.speed_drag*min(0, v.forwd_drag ) -30*clamp(v.speed_speed*4*v.forwd_drag,-1,0) )*v.flying
    v.fly_bodyty = ( 0.7*sin(v.Bt) +0.5*cos(-pi/4+v.lsF )*limb_speed )*v.flying
    v.fly_headrx = -v.fly_bodyrx/2 +torad( -15*clamp(v.speed_speed*4*v.forwd_drag,-1,0) )*v.flying
    v.fly_rarmrx = torad(-7*sin( v.lsF )*limb_speed +30*v.speed_drag*(v.forwd_drag+max(0,-v.sidwd_drag*v.strafe)/2) -70*clamp(v.yaw_speed/2,-1,1) -60*clamp(v.speed_speed*4*v.forwd_drag,-1,1) )*max(0,1 -v.rswingingA -v.raction )*v.flying
    v.fly_larmrx = torad(-7*cos( v.lsF )*limb_speed +30*v.speed_drag*(v.forwd_drag+max(0, v.sidwd_drag*v.strafe)/2) +70*clamp(v.yaw_speed/2,-1,1) -60*clamp(v.speed_speed*4*v.forwd_drag,-1,1) )*max(0,1 -v.lswingingA -v.laction )*v.flying
    v.fly_rarmry = torad( 10 -20*clamp(v.yaw_speed/2,-1,1) )*max(0,1 -v.rswingingA -v.raction )*v.flying
    v.fly_larmry = torad(-10 -20*clamp(v.yaw_speed/2,-1,1) )*max(0,1 -v.lswingingA -v.laction )*v.flying
    v.fly_rarmrz = torad( 10-12*v.speed_speed +3*cos(-pi/6*sin(v.lsF)*(1-limb_speed) +v.Bt ) +50*clamp(abs(v.yaw_speed)/2,0,1) -min(0,20*v.speed_drag*v.sidwd_drag*v.strafe) )*v.flying
    v.fly_larmrz = torad(-10+12*v.speed_speed -3*cos( pi/6*sin(v.lsF)*(1-limb_speed) +v.Bt ) -50*clamp(abs(v.yaw_speed)/2,0,1) -max(0,20*v.speed_drag*v.sidwd_drag*v.strafe) )*v.flying
    v.fly_rarmtz = v.fly_rarmrx
    v.fly_larmtz = v.fly_larmrx
    v.fly_rlegrx = torad( 5+8*cos( pi/6*sin(v.lsF/1.2)*(1-limb_speed) +v.Bt ) +7*sin( pi/6*sin(v.lsF/5)*0 +v.lsF )*limb_speed -3*v.fly_rlegty +25*v.speed_drag*(v.forwd_drag+abs(v.sidwd_drag*v.strafe)/2) +(22+30*limb_speed)*clamp(v.yaw_speed/2,-1,1) )*v.flying
    v.fly_llegrx = torad( 5+8*cos(-pi/6*sin(v.lsF/1.2)*(1-limb_speed) +v.Bt ) +7*cos(-pi/6*sin(v.lsF/5)*0 +v.lsF )*limb_speed -3*v.fly_llegty +25*v.speed_drag*(v.forwd_drag+abs(v.sidwd_drag*v.strafe)/2) -(22+30*limb_speed)*clamp(v.yaw_speed/2,-1,1) )*v.flying
    v.fly_rlegry = torad( 4*(1-v.idle) )*v.flying
    v.fly_llegry = torad(-4*(1-v.idle) )*v.flying
    v.fly_rlegrz = torad( (15+20*limb_speed)*clamp(v.yaw_speed/2,-1,1) -20*v.speed_drag*v.sidwd_drag*v.strafe )*v.flying
    v.fly_llegrz = torad( (15+20*limb_speed)*clamp(v.yaw_speed/2,-1,1) -20*v.speed_drag*v.sidwd_drag*v.strafe )*v.flying
    v.fly_rlegty = v.fly_bodyty +( -(1-sin(v.ls/3+cos(v.ls/3)*v.idle))*(1-0.9*limb_speed) +( min(0, v.forwd_drag ) +2*min(0,-v.sidwd_drag) )*limb_speed )*v.flying
    v.fly_llegty = v.fly_bodyty +( -(1+sin(v.ls/3-cos(v.ls/3)*v.idle))*(1-0.9*limb_speed) +( min(0, v.forwd_drag ) +2*min(0, v.sidwd_drag) )*limb_speed )*v.flying
    v.fly_rlegtz = v.fly_rlegty-v.fly_bodyty +( min(0, v.forwd_drag ) +2*min(0,-v.sidwd_drag) )*limb_speed*v.flying
    v.fly_llegtz = v.fly_llegty-v.fly_bodyty +( min(0, v.forwd_drag ) +2*min(0, v.sidwd_drag) )*limb_speed*v.flying

    -- first_person: a_player_firstperson.jpm
    v.fp_rarmrx = choose( vb.v21_2_plus,max(0,1-v.Rmap)*torad(40*choose(v.requip==1, 0, v.requip) +( ( 10 +20*limb_speed*cos(v.t_jump*pi) )*exp(-v.t_jump*pi)*v.jump -( 10 +10*sin(v.lsj) )*v.fall +(-12*cos( pi/5+v.Btsw +sin(pi/5+v.Btsw)/(1.7+limb_speed) )*clamp(1+limb_speed*3, 0, 1) )*v.tread )*max(0,1-v.requip) ), 0 )
    v.fp_larmrx = choose( vb.v21_2_plus,max(0,1-v.Lmap)*torad(40*choose(v.lequip==1, 0, v.lequip) +( ( 10 +20*limb_speed*cos(v.t_jump*pi) )*exp(-v.t_jump*pi)*v.jump -( 10 -10*sin(v.lsj) )*v.fall +(-12*cos( pi/5+v.Btsw +sin(pi/5+v.Btsw)/(1.7+limb_speed) )*clamp(1+limb_speed*3, 0, 1) )*v.tread )*max(0,1-v.lequip) ), 0 )
    v.fp_rarmry = torad( 115*max(0,v.Rmap-1) -2*cos(v.Bt/2) )*min(1,v.Rmap) +max(0,1-v.Rmap)*torad( 5 +60*choose(v.requip==1, 0, v.requip) +(-1.5*cos(v.Bt/2) -20*v.sneak -40*(v.prone-v.climb) +10*limb_speed+( 30 -10*cos(v.lsj) )*v.fall +( -9*cos( pi/choose(vb.v21_2_plus,3,-5)+v.Btsw -sin( -pi/2.5+v.Btsw)/1.5 ) +choose(vb.v21_2_plus,2*cos(pi/6+v.Btsw*2),-9))*v.tread )*max(0,1-v.requip) )+pi/6*clamp(v.headyaw_speed,-1,1)
    v.fp_larmry = torad(-115*max(0,v.Lmap-1) -2*cos(v.Bt/2) )*min(1,v.Lmap) +max(0,1-v.Lmap)*torad(-5 -60*choose(v.lequip==1, 0, v.lequip) +(-1.5*cos(v.Bt/2) +20*v.sneak +40*(v.prone-v.climb) -10*limb_speed-( 30 -10*cos(v.lsj) )*v.fall +(9*cos( pi/choose(vb.v21_2_plus,3,-5)+v.Btsw -sin( -pi/2.5+v.Btsw)/1.5 ) +choose(vb.v21_2_plus,2*cos(pi/6+v.Btsw*2), 9))*v.tread )*max(0,1-v.lequip) )+pi/6*clamp(v.headyaw_speed,-1,1)
    v.fp_rarmrz = torad( 37 -20*max(0,v.Rmap-1) )*min(1,v.Rmap) +max(0,1-v.Rmap)*( torad( 6 +20*choose(v.requip==1, 0, v.requip) +( 0.5*sin(v.Bt) +10*v.sneak -20*v.prone -10*limb_speed -40*exp(-v.t_jump*pi)*v.jump+30*v.fall-( 12*sin(-pi/8+v.t_land*pi)*(1+limb_speed) )*v.land +( -5*sin( pi/8+v.Btsw +sin(choose(vb.v21_2_plus,pi/1.6+v.Btsw*2,pi/8+v.Btsw) )/5 ) +choose(vb.v21_2_plus, 0,-6) )*choose(vb.v21_2_plus,1,3)*v.tread )*max(0,1-v.requip) ) -pi/6*clamp(v.headpitch_speed,-1,1) )
    v.fp_larmrz = torad(-37 +20*max(0,v.Lmap-1) )*min(1,v.Lmap) +max(0,1-v.Lmap)*( torad(-6 -20*choose(v.lequip==1, 0, v.lequip) +(-0.5*sin(v.Bt) -10*v.sneak +20*v.prone +10*limb_speed +40*exp(-v.t_jump*pi)*v.jump-30*v.fall+( 12*sin(-pi/8+v.t_land*pi)*(1+limb_speed) )*v.land +(5*sin( pi/8+v.Btsw +sin(choose(vb.v21_2_plus,pi/1.6+v.Btsw*2,pi/8+v.Btsw) )/5 ) +choose(vb.v21_2_plus, 0, 6) )*choose(vb.v21_2_plus,1,3)*v.tread )*max(0,1-v.lequip) ) -pi/6*clamp(v.headpitch_speed,-1,1) )
    v.fp_rarmtx = -5 +(-0.1*cos(v.Bt/2) )*min(1,v.Rmap) +max(0,1-v.Rmap)*( cos(v.Bt/2)/9*(1-v.requip) )
    v.fp_larmtx = 5 +(-0.1*cos(v.Bt/2) )*min(1,v.Lmap) +max(0,1-v.Lmap)*( cos(v.Bt/2)/9*(1-v.lequip) )
    v.fp_rarmty = 2 +( 2 )*min(1,v.Rmap) +max(0,1-v.Rmap)*( ( sin(v.Bt)/9 -limb_speed -3*exp(-v.t_jump*pi)*v.jump +3*v.fall -0.5*cos(v.t_land*pi) *min(sqrt((1-v.t_land)*2),1)*v.land)*(1-v.requip) +clamp(v.headpitch_speed,-1,1) +v.hp/30 )
    v.fp_larmty = 2 +( 2 )*min(1,v.Lmap) +max(0,1-v.Lmap)*( ( sin(v.Bt)/9 -limb_speed -3*exp(-v.t_jump*pi)*v.jump +3*v.fall -0.5*cos(v.t_land*pi) *min(sqrt((1-v.t_land)*2),1)*v.land)*(1-v.lequip) +clamp(v.headpitch_speed,-1,1) +v.hp/30 )
    v.fp_rarmtz = 0
    v.fp_larmtz = 0

    -- player: player.jem
    m.root.sy = 1+choose(vb.v21_2_plus,v.root_sy,0)
    m.root.sx = 1+choose(vb.v21_2_plus,v.root_sx,0)
    m.root.sz = 1+choose(vb.v21_2_plus,v.root_sz,0)
    m.root.ry = choose(vb.v21_2_plus,v.root_ry,0)
    m.root.rx = choose(vb.v21_2_plus,v.root_rx,0)
    m.root.rz = choose(vb.v21_2_plus,v.root_rz,0)
    m.root.tx = choose(vb.v21_2_plus,v.root_tx,0)
    m.root.ty = choose(vb.v21_2_plus,v.root_ty-(m.root.sy-1)*24,0)
    m.root.tz = choose(vb.v21_2_plus,v.root_tz,0)
    v.body_rx = choose(vb.v21_2_plus,0,v.root_rx)+v.idl_bodyrx+v.mvmnt_bodyrx+v.udrwtr_bodyrx+v.vrtcl_bodyrx+v.fly_bodyrx+v.eqp_bodyrx
    v.body_ry = choose(vb.v21_2_plus,0,v.root_ry/3)+v.idl_bodyry+v.mvmnt_bodyry+v.udrwtr_bodyry+v.vrtcl_bodyry+v.gldng_bodyry+v.eqp_bodyry
    v.body_rz = choose(vb.v21_2_plus,0,v.root_rz/2)+v.mvmnt_bodyrz+v.udrwtr_bodyrz+v.vrtcl_bodyrz+v.gldng_bodyrz+v.eqp_bodyrz
    v.body_tx = sin(v.body_rz)*12+v.idl_bodytx+v.mvmnt_bodytx+v.udrwtr_bodytx+v.gldng_bodytx+v.vrtcl_bodytx+v.eqp_bodytx
    v.body_ty = -cos(v.body_rx)*12+12-cos(v.body_rz)*12+12-2*v.sneak2+v.idl_bodyty+v.mvmnt_bodyty+v.udrwtr_bodyty+v.vrtcl_bodyty+v.fly_bodyty
    v.body_tz = -sin(v.body_rx)*12+v.idl_bodytz+v.mvmnt_bodytz+v.udrwtr_bodytz+v.gldng_bodytz+v.vrtcl_bodytz
    m.body.rx = v.body_rx
    m.body.ry = v.body_ry
    m.body.rz = v.body_rz
    m.body.tx = v.body_tx
    m.body.ty = v.body_ty
    m.body.tz = v.body_tz
    v.head_rx = choose(vb.v21_2_plus,clamp(-v.root_rx*(1-0.2*v.tread),-pi/3,pi/3),0)+v.idl_headrx+v.mvmnt_headrx+v.udrwtr_headrx+v.gldng_headrx+v.fly_headrx+v.vrtcl_headrx+choose(not is_gliding and v.gliding>0,pi/2*v.gliding,0)
    v.head_ry = (v.root_ry-v.climb_direction*v.climb)*(1-v.swim)+v.idl_headry+v.mvmnt_headry+v.gldng_headry
    v.head_rz = choose(vb.v21_2_plus,-v.root_rz/2,0)+v.idl_headrz+v.gldng_headrz
    v.head_tx = m.body.tx
    v.head_ty = m.body.ty+v.idl_headty+v.mvmnt_headty+v.vrtcl_headty
    v.head_tz = m.body.tz+v.mvmnt_headtz
    m.head.rx = v.head_rx
    m.head.ry = v.head_ry
    m.head.rz = v.head_rz
    m.head.tx = v.head_tx
    m.head.ty = v.head_ty
    m.head.tz = v.head_tz
    m.right_arm.rx = choose(is_first_person_hand,v.fp_rarmrx,-v.root_rx*(choose(vb.v21_2_plus,1,0)-v.swim)+(v.idl_rarmrx+v.mvmnt_rarmrx+v.udrwtr_rarmrx+v.gldng_rarmrx+v.vrtcl_rarmrx+v.fly_rarmrx+v.eqp_rarmrx)*(1-v.ractionT*v.ractionT)+v.spr_rarmrx)+v.RarmRX_drag*(v.ractionT*v.ractionT)
    m.left_arm.rx = choose(is_first_person_hand,v.fp_larmrx,-v.root_rx*(choose(vb.v21_2_plus,1,0)-v.swim)+(v.idl_larmrx+v.mvmnt_larmrx+v.udrwtr_larmrx+v.gldng_larmrx+v.vrtcl_larmrx+v.fly_larmrx+v.eqp_larmrx)*(1-v.lactionT*v.lactionT)+v.spr_larmrx)+v.LarmRX_drag*(v.lactionT*v.lactionT)
    m.right_arm.ry = choose(is_first_person_hand,v.fp_rarmry,choose(vb.v21_2_plus,0,v.root_ry/3)+(v.idl_rarmry+v.mvmnt_rarmry+v.udrwtr_rarmry+v.gldng_rarmry+v.vrtcl_rarmry+v.fly_rarmry+v.eqp_rarmry)*(1-v.ractionT*v.ractionT))+v.RarmRY_drag*(v.ractionT*v.ractionT)
    m.left_arm.ry = choose(is_first_person_hand,v.fp_larmry,choose(vb.v21_2_plus,0,v.root_ry/3)+(v.idl_larmry+v.mvmnt_larmry+v.udrwtr_larmry+v.gldng_larmry+v.vrtcl_larmry+v.fly_larmry+v.eqp_larmry)*(1-v.lactionT*v.lactionT))+v.LarmRY_drag*(v.lactionT*v.lactionT)
    m.right_arm.rz = choose(is_first_person_hand,v.fp_rarmrz,choose(vb.v21_2_plus,0,v.root_rz/2)+(v.idl_rarmrz+v.mvmnt_rarmrz+v.udrwtr_rarmrz+v.gldng_rarmrz+v.vrtcl_rarmrz+v.fly_rarmrz+v.eqp_rarmrz)*(1-v.ractionT*v.ractionT))+v.RarmRZ_drag*(v.ractionT*v.ractionT)
    m.left_arm.rz = choose(is_first_person_hand,v.fp_larmrz,choose(vb.v21_2_plus,0,v.root_rz/2)+(v.idl_larmrz+v.mvmnt_larmrz+v.udrwtr_larmrz+v.gldng_larmrz+v.vrtcl_larmrz+v.fly_larmrz+v.eqp_larmrz)*(1-v.lactionT*v.lactionT))+v.LarmRZ_drag*(v.lactionT*v.lactionT)
    m.right_arm.tx = choose(is_first_person_hand,v.fp_rarmtx,m.body.tx+(-cos(v.body_ry)*5+5)*(v.idle+v.ractionT+v.gliding)-5+v.idl_rarmtx+v.mvmnt_rarmtx+v.udrwtr_rarmtx+v.vrtcl_rarmtx)+(m.right_arm.tx+5)*(v.ractionT*v.ractionT)
    m.left_arm.tx = choose(is_first_person_hand,v.fp_larmtx,m.body.tx+(cos(v.body_ry)*5-5)*(v.idle+v.lactionT+v.gliding)+5+v.idl_larmtx+v.mvmnt_larmtx+v.udrwtr_larmtx+v.vrtcl_larmtx)+(m.left_arm.tx-5)*(v.lactionT*v.lactionT)
    m.right_arm.ty = choose(is_first_person_hand,v.fp_rarmty,m.body.ty+cos(v.body_rx)*2-2+2+v.idl_rarmty+v.mvmnt_rarmty+v.udrwtr_rarmty+v.vrtcl_rarmty)+(m.right_arm.ty-2*v.sneak2-2)*(v.ractionT*v.ractionT)
    m.left_arm.ty = choose(is_first_person_hand,v.fp_larmty,m.body.ty+cos(v.body_rx)*2-2+2+v.idl_larmty+v.mvmnt_larmty+v.udrwtr_larmty+v.vrtcl_larmty)+(m.left_arm.ty-2*v.sneak2-2)*(v.lactionT*v.lactionT)
    m.right_arm.tz = choose(is_first_person_hand,v.fp_larmtz,m.body.tz+sin(v.body_rx)*2+(sin(v.body_ry)*5)*(v.idle+v.ractionT+v.gliding)+v.idl_rarmtz+v.mvmnt_rarmtz+v.udrwtr_rarmtz+v.vrtcl_rarmtz+v.fly_rarmtz+v.eqp_rarmtz)+(m.right_arm.tz)*(v.ractionT*v.ractionT)
    m.left_arm.tz = choose(is_first_person_hand,v.fp_larmtz,m.body.tz+sin(v.body_rx)*2+(-sin(v.body_ry)*5)*(v.idle+v.lactionT+v.gliding)+v.idl_larmtz+v.mvmnt_larmtz+v.udrwtr_larmtz+v.vrtcl_larmtz+v.fly_larmtz+v.eqp_larmtz)+(m.left_arm.tz)*(v.lactionT*v.lactionT)
    v.right_footrx = v.idl_rfootrx+v.mvmnt_rfootrx+v.vrtcl_rfootrx+v.eqp_rfootrx
    v.left_footrx = v.idl_lfootrx+v.mvmnt_lfootrx+v.vrtcl_lfootrx+v.eqp_lfootrx
    v.right_footry = v.idl_rfootry+v.mvmnt_rfootry+v.eqp_rfootry
    v.left_footry = v.idl_lfootry+v.mvmnt_lfootry+v.eqp_lfootry
    v.right_footrz = v.idl_rfootrz+v.mvmnt_rfootrz
    v.left_footrz = v.idl_lfootrz+v.mvmnt_lfootrz
    m.right_leg.rx = v.right_footrx-v.root_rx*(1-v.tread*choose(vb.v21_2_plus,1,1.5)-v.flying)+v.idl_rlegrx+v.mvmnt_rlegrx+v.udrwtr_rlegrx+v.gldng_rlegrx+v.vrtcl_rlegrx+v.fly_rlegrx
    m.left_leg.rx = v.left_footrx-v.root_rx*(1-v.tread*choose(vb.v21_2_plus,1,1.5)-v.flying)+v.idl_llegrx+v.mvmnt_llegrx+v.udrwtr_llegrx+v.gldng_llegrx+v.vrtcl_llegrx+v.fly_llegrx
    m.right_leg.ry = v.right_footry+choose(vb.v21_2_plus,0,v.root_ry/3)+v.idl_rlegry+v.mvmnt_rlegry+v.udrwtr_rlegry+v.gldng_rlegry+v.vrtcl_rlegry+v.fly_rlegry
    m.left_leg.ry = v.left_footry+choose(vb.v21_2_plus,0,v.root_ry/3)+v.idl_llegry+v.mvmnt_llegry+v.udrwtr_llegry+v.gldng_llegry+v.vrtcl_llegry+v.fly_llegry
    m.right_leg.rz = v.right_footrz+choose(vb.v21_2_plus,0,v.root_rz/2)+m.right_leg.rx*m.right_leg.ry*(1-v.sit)+v.idl_rlegrz+v.mvmnt_rlegrz+v.udrwtr_rlegrz+v.gldng_rlegrz+v.vrtcl_rlegrz+v.fly_rlegrz
    m.left_leg.rz = v.left_footrz+choose(vb.v21_2_plus,0,v.root_rz/2)+m.left_leg.rx*m.left_leg.ry*(1-v.sit)+v.idl_llegrz+v.mvmnt_llegrz+v.udrwtr_llegrz+v.gldng_llegrz+v.vrtcl_llegrz+v.fly_llegrz
    m.right_leg.tx = -2+(-sin(v.right_footrx)*12)*m.right_leg.ry+(sin(v.right_footrz)*12)+v.idl_rlegtx+v.mvmnt_rlegtx+v.udrwtr_rlegtx+v.gldng_rlegtx+v.vrtcl_rlegtx
    m.left_leg.tx = 2+(-sin(v.left_footrx)*12)*m.left_leg.ry+(sin(v.left_footrz)*12)+v.idl_llegtx+v.mvmnt_llegtx+v.udrwtr_llegtx+v.gldng_llegtx+v.vrtcl_llegtx
    m.right_leg.ty = 12+(-cos(v.right_footrx)*12+12)-2*v.sneak2+(-cos(v.right_footrz)*12+12)+v.idl_rlegty+v.mvmnt_rlegty+v.udrwtr_rlegty+v.vrtcl_rlegty+v.fly_rlegty
    m.left_leg.ty = 12+(-cos(v.left_footrx)*12+12)-2*v.sneak2+(-cos(v.left_footrz)*12+12)+v.idl_llegty+v.mvmnt_llegty+v.udrwtr_llegty+v.vrtcl_llegty+v.fly_llegty
    m.right_leg.tz = (-sin(v.right_footrx)*12)+v.idl_rlegtz+v.mvmnt_rlegtz+v.udrwtr_rlegtz+v.gldng_rlegtz+v.vrtcl_rlegtz+v.fly_rlegtz
    m.left_leg.tz = (-sin(v.left_footrx)*12)+v.idl_llegtz+v.mvmnt_llegtz+v.udrwtr_llegtz+v.gldng_llegtz+v.vrtcl_llegtz+v.fly_llegtz
    m.right_leg.sy = 1+v.vrtcl_rlegsy
    m.left_leg.sy = 1+v.vrtcl_llegsy
    m.headwear.rx = choose(vb.v21_2_plus,0,m.head.rx)
    m.headwear.ry = choose(vb.v21_2_plus,0,m.head.ry)
    m.headwear.rz = choose(vb.v21_2_plus,0,m.head.rz)
    m.headwear.tx = choose(vb.v21_2_plus,0,m.head.tx)
    m.headwear.ty = choose(vb.v21_2_plus,0,m.head.ty)
    m.headwear.tz = choose(vb.v21_2_plus,0,m.head.tz)
    m.headwear.sx = choose(vb.v21_2_plus,1,m.head.sx)
    m.headwear.sy = choose(vb.v21_2_plus,1,m.head.sy)
    m.headwear.sz = choose(vb.v21_2_plus,1,m.head.sz)
    m.jacket.rx = choose(vb.v21_2_plus,0,m.body.rx)
    m.jacket.ry = choose(vb.v21_2_plus,0,m.body.ry)
    m.jacket.rz = choose(vb.v21_2_plus,0,m.body.rz)
    m.jacket.tx = choose(vb.v21_2_plus,0,m.body.tx)
    m.jacket.ty = choose(vb.v21_2_plus,0,m.body.ty)
    m.jacket.tz = choose(vb.v21_2_plus,0,m.body.tz)
    m.jacket.sx = choose(vb.v21_2_plus,1,m.body.sx)
    m.jacket.sy = choose(vb.v21_2_plus,1,m.body.sy)
    m.jacket.sz = choose(vb.v21_2_plus,1,m.body.sz)
    m.right_sleeve.rx = choose(vb.v21_2_plus,0,m.right_arm.rx)
    m.right_sleeve.ry = choose(vb.v21_2_plus,0,m.right_arm.ry)
    m.right_sleeve.rz = choose(vb.v21_2_plus,0,m.right_arm.rz)
    m.right_sleeve.tx = choose(vb.v21_2_plus,0,m.right_arm.tx)
    m.right_sleeve.ty = choose(vb.v21_2_plus,0,m.right_arm.ty)
    m.right_sleeve.tz = choose(vb.v21_2_plus,0,m.right_arm.tz)
    m.right_sleeve.sx = choose(vb.v21_2_plus,1,m.right_arm.sx)
    m.right_sleeve.sy = choose(vb.v21_2_plus,1,m.right_arm.sy)
    m.right_sleeve.sz = choose(vb.v21_2_plus,1,m.right_arm.sz)
    m.left_sleeve.rx = choose(vb.v21_2_plus,0,m.left_arm.rx)
    m.left_sleeve.ry = choose(vb.v21_2_plus,0,m.left_arm.ry)
    m.left_sleeve.rz = choose(vb.v21_2_plus,0,m.left_arm.rz)
    m.left_sleeve.tx = choose(vb.v21_2_plus,0,m.left_arm.tx)
    m.left_sleeve.ty = choose(vb.v21_2_plus,0,m.left_arm.ty)
    m.left_sleeve.tz = choose(vb.v21_2_plus,0,m.left_arm.tz)
    m.left_sleeve.sx = choose(vb.v21_2_plus,1,m.left_arm.sx)
    m.left_sleeve.sy = choose(vb.v21_2_plus,1,m.left_arm.sy)
    m.left_sleeve.sz = choose(vb.v21_2_plus,1,m.left_arm.sz)
    m.right_pants.rx = choose(vb.v21_2_plus,0,m.right_leg.rx)
    m.right_pants.ry = choose(vb.v21_2_plus,0,m.right_leg.ry)
    m.right_pants.rz = choose(vb.v21_2_plus,0,m.right_leg.rz)
    m.right_pants.tx = choose(vb.v21_2_plus,0,m.right_leg.tx)
    m.right_pants.ty = choose(vb.v21_2_plus,0,m.right_leg.ty)
    m.right_pants.tz = choose(vb.v21_2_plus,0,m.right_leg.tz)
    m.right_pants.sx = choose(vb.v21_2_plus,1,m.right_leg.sx)
    m.right_pants.sy = choose(vb.v21_2_plus,1,m.right_leg.sy)
    m.right_pants.sz = choose(vb.v21_2_plus,1,m.right_leg.sz)
    m.left_pants.rx = choose(vb.v21_2_plus,0,m.left_leg.rx)
    m.left_pants.ry = choose(vb.v21_2_plus,0,m.left_leg.ry)
    m.left_pants.rz = choose(vb.v21_2_plus,0,m.left_leg.rz)
    m.left_pants.tx = choose(vb.v21_2_plus,0,m.left_leg.tx)
    m.left_pants.ty = choose(vb.v21_2_plus,0,m.left_leg.ty)
    m.left_pants.tz = choose(vb.v21_2_plus,0,m.left_leg.tz)
    m.left_pants.sx = choose(vb.v21_2_plus,1,m.left_leg.sx)
    m.left_pants.sy = choose(vb.v21_2_plus,1,m.left_leg.sy)
    m.left_pants.sz = choose(vb.v21_2_plus,1,m.left_leg.sz)

    -- elytra: elytra.jem
    m.root.sx = 1+v.root_sx
    m.root.sy = 1+v.root_sy
    m.root.sz = 1+v.root_sz
    m.root.ry = v.root_ry
    m.root.rx = v.root_rx
    m.root.rz = v.root_rz
    m.root.tx = v.root_tx
    m.root.ty = v.root_ty-(m.root.sy-1)*24
    m.root.tz = v.root_tz-choose(vb.v21_2_plus,2,0)
    m.wings.rx = torad(-15)*v.sneak+clamp(torad((50-30*v.sneak)*limb_speed*v.mforward*(1-v.swim)+20*v.vs_ltd*(1+v.water*3-v.swim*2)-10*v.sprint*(1-v.in_air*2)+15*cos(v.t_land*pi*2)*min(sqrt((1-v.t_land)*3),1)*v.land+(10*sin(v.ls*2))*sqrt(limb_speed)*(v.run-0.3*v.sprint)),0,torad(170))/4
    m.wings.ry = 0
    m.wings.rz = 0
    m.wings.tx = 0
    m.wings.ty = -24
    m.wings.tz = 0
    m.right_wing2.rx = m.right_wing.rx-v.body_ry*clamp(v.gliding-v.swim/1.5,-0.5,1)-torad(2*cos(pi/8+limb_swing/25+sin(limb_swing/40)/4)+sin(limb_swing+(1-sin(limb_swing/7)/2))*(0.8+sin(limb_swing/23+cos(limb_swing/13)))/2*limb_speed*v.gfast+40*clamp(v.pitch_speed*5,-1,1)-30*clamp(v.yaw_speed*(1-v.yaw_speed)*10,-1,1)-head_yaw/2*0)*v.gliding
    m.left_wing2.rx = m.left_wing.rx+v.body_ry*clamp(v.gliding-v.swim/1.5,-0.5,1)+torad(2*cos(pi/8+limb_swing/25+sin(limb_swing/40)/4)+sin(limb_swing+(1-sin(limb_swing/7)/2))*(0.8+sin(limb_swing/23+cos(limb_swing/13)))/2*limb_speed*v.gfast-40*clamp(v.pitch_speed*5,-1,1)-30*clamp(v.yaw_speed*(1-v.yaw_speed)*10,-1,1)-head_yaw/2*0)*v.gliding
    m.right_wing2.ry = m.right_wing.ry-torad(-7*sin(-pi/4+v.ls)*(1+0.3*(1-v.run)-0.3*v.trudge))/6*sqrt(limb_speed)*v.walk+torad(3*cos(limb_swing/25+sin(limb_swing/40)/4))*v.gliding
    m.left_wing2.ry = m.left_wing.ry-torad(-7*sin(-pi/4+v.ls)*(1+0.3*(1-v.run)-0.3*v.trudge))/6*sqrt(limb_speed)*v.walk+torad(3*cos(limb_swing/25+sin(limb_swing/40)/4))*v.gliding
    m.right_wing2.rz = m.right_wing.rz+clamp(torad(-6*sin(-pi/4+v.ls)*(1+0.3*(1-v.run)-0.3*v.trudge))*sqrt(limb_speed)*v.walk+torad(3*v.vs_ltd+3*cos(v.t_land*pi*2)*min(sqrt((1-v.t_land)*3),1)*v.land),-torad(10),torad(90))+torad((10-20*cos(v.t_Ljump*pi))*v.Ljump-(10-20*cos(v.t_Rjump*pi))*v.Rjump)*(0.3+0.7*limb_speed)
    m.left_wing2.rz = m.left_wing.rz+clamp(torad(-6*sin(-pi/4+v.ls)*(1+0.3*(1-v.run)-0.3*v.trudge))*sqrt(limb_speed)*v.walk-torad(3*v.vs_ltd+3*cos(v.t_land*pi*2)*min(sqrt((1-v.t_land)*3),1)*v.land),-torad(90),torad(10))+torad((10-15*cos(v.t_Ljump*pi))*v.Ljump-(10-15*cos(v.t_Rjump*pi))*v.Rjump)*(0.3+0.7*limb_speed)
    m.right_wing.rx = v.body_rx
    m.right_wing.ry = v.body_ry
    m.right_wing.rz = v.body_rz
    m.right_wing.tx = v.body_tx
    m.right_wing.ty = v.body_ty
    m.right_wing.tz = v.body_tz-choose(vb.v21_2_plus,0,2)
end

local function apply_part(name, part, state)
    if part == nil or state == nil then return end
    local base = CEM_BASE_POS[name] or {0, 0, 0}
    local origin = origin_pos[name] or base
    local dx = (state.tx - origin[1]) * CONFIG.position_scale
    local dy = (state.ty - origin[2]) * CONFIG.position_scale
    local dz = (state.tz - origin[3]) * CONFIG.position_scale
    part:setRot(-todeg(state.rx), -todeg(state.ry), todeg(state.rz))
    -- CEM expressions describe an absolute ModelPart pivot. Figura setPos()
    -- instead adds a Blockbench-style offset on top of the current vanilla
    -- pose and internally negates X/Y. Subtract the current vanilla origin
    -- first, then compensate for Figura's X/Y sign conversion.
    part:setPos(
        -dx,
        -dy,
        dz
    )
    part:setScale(state.sx, state.sy, state.sz)
end

local function apply_body_family()
    apply_part("head", vanilla_model.HEAD, m.head)
    apply_part("headwear", vanilla_model.HAT, m.headwear)
    apply_part("body", vanilla_model.BODY, m.body)
    apply_part("jacket", vanilla_model.JACKET, m.jacket)
    apply_part("right_arm", vanilla_model.RIGHT_ARM, m.right_arm)
    apply_part("left_arm", vanilla_model.LEFT_ARM, m.left_arm)
    apply_part("right_sleeve", vanilla_model.RIGHT_SLEEVE, m.right_sleeve)
    apply_part("left_sleeve", vanilla_model.LEFT_SLEEVE, m.left_sleeve)
    apply_part("right_leg", vanilla_model.RIGHT_LEG, m.right_leg)
    apply_part("left_leg", vanilla_model.LEFT_LEG, m.left_leg)
    apply_part("right_pants", vanilla_model.RIGHT_PANTS, m.right_pants)
    apply_part("left_pants", vanilla_model.LEFT_PANTS, m.left_pants)

    -- Figura's armor layer copies the already-transformed player pose into its
    -- own HumanoidModel. Writing the same offsets to the armor API here would
    -- add setPos() a second time and detach armor during translated poses.
end

local function set_custom_rot(part, rx, ry, rz)
    if part == nil then return end
    part:setRot(-todeg(rx or 0), -todeg(ry or 0), todeg(rz or 0))
end

local function apply_accessories()
    -- Cape support is intentionally disabled. Hide both vanilla cape parts for
    -- every player and do not provide custom cape geometry or animation.
    vanilla_model.CAPE:setVisible(false)

    local rig = models ~= nil and models.accessories or nil
    if rig == nil then return end

    -- BodyElytraRig mimics the already animated torso. The pivot children
    -- relocate the real vanilla wings, retaining dynamic textures, glint and
    -- compatibility while keeping FA's common and per-wing pivots separate.
    set_custom_rot(
        rig.BodyElytraRig.ElytraWings,
        (m.wings.rx or 0) * CONFIG.elytra_strength,
        (m.wings.ry or 0) * CONFIG.elytra_strength,
        (m.wings.rz or 0) * CONFIG.elytra_strength
    )
    set_custom_rot(
        rig.BodyElytraRig.ElytraWings.RightElytraPivot,
        ((m.right_wing2.rx or 0) - wing_origin.right.rx) * CONFIG.elytra_strength,
        ((m.right_wing2.ry or 0) - wing_origin.right.ry) * CONFIG.elytra_strength,
        ((m.right_wing2.rz or 0) - wing_origin.right.rz) * CONFIG.elytra_strength
    )
    set_custom_rot(
        rig.BodyElytraRig.ElytraWings.LeftElytraPivot,
        ((m.left_wing2.rx or 0) - wing_origin.left.rx) * CONFIG.elytra_strength,
        ((m.left_wing2.ry or 0) - wing_origin.left.ry) * CONFIG.elytra_strength,
        ((m.left_wing2.rz or 0) - wing_origin.left.rz) * CONFIG.elytra_strength
    )
end

function events.render(delta, context)
    if not player:isLoaded() then return end
    update_inputs(delta, context)
    seed_model()
    evaluate_cem()
    apply_body_family()
    apply_accessories()
end
