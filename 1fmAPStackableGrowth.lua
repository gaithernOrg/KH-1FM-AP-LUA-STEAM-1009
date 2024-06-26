-----------------------------------
------ Kingdom Hearts 1 FM AP -----
------         by Gicu        -----
-----------------------------------

LUAGUI_NAME = "1fmAPStackableGrowth"
LUAGUI_AUTH = "Denhonator with edits by Gicu"
LUAGUI_DESC = "Kingdom Hearts 1FM AP Integration"

game_version = 1 --1 for ESG 1.0.0.9, 2 for Steam 1.0.0.9

canExecute = false
dodgeDataAddr = 0

function CountSharedAbilities()
    sharedAbilities = {0x2DEA279, 0x2DE98F9}
    local shared = {0,0,0}
    for i=0,9 do
        local ab = ReadByte(sharedAbilities[game_version]+i)
        if ab == 3 or ab == 4 then
            shared[3] = shared[3]+1
        elseif ab > 0 and ab <= 4 then
            shared[ab] = shared[ab]+1
        end
    end
    return shared
end

function StackAbilities()
    jumpHeights         = {0x2D2376C, 0x2D22DEC}
    world               = {0x2340DDC, 0x233FE84}
    room                = {0x2340DDC + 0x68, 0x233FE84 + 0x8}
    soraHUD             = {0x2812E1C, 0x281249C}
    cutsceneFlags       = {0x2DEA6E0, 0x2DE9D60}
    sharedAbilities     = {0x2DEA279, 0x2DE98F9}
    superglideSpeedHack = {0x2B05B4, 0x2B2744}
    mermaidKickSpeed    = {0x3F081C, 0x3EF9DC}
    stateFlag           = {0x2867C58, 0x2867364}
    local countedAbilities = CountSharedAbilities()
    local jumpHeight = math.max(290, 190+(countedAbilities[1]*100))
    stackAbilities = 2

    WriteShort(jumpHeights[game_version]+2, jumpHeight)
    if ReadByte(world[game_version]) == 0x10 and countedAbilities[3] == 0 and stackAbilities == 3 and (ReadByte(room[game_version]) == 0x21 or 
            (ReadByte(cutsceneFlags[game_version]+0xB0F) >= 0x6E) and ReadFloat(soraHUD[game_version]) > 0) then
        WriteShort(jumpHeights[game_version], 390)
        WriteShort(jumpHeights[game_version]+2, math.max(390, jumpHeight))
    end

    if stackAbilities > 1 then
        local glides = false
        for i=0,9 do
            local ab = ReadByte(sharedAbilities[game_version]+i)
            if ab % 0x80 >= 3 and not glides then
                WriteByte(sharedAbilities[game_version]+i, (ab % 0x80 == 4) and ab-1 or ab)
                glides = true
            elseif ab % 0x80 == 3 and glides then
                WriteByte(sharedAbilities[game_version]+i, ab+1)
            end
        end
        if game_version == 1 then
            if ReadShort(superglideSpeedHack[game_version]+1) == 0x1802 then
                WriteInt(superglideSpeedHack[game_version], 0x18027C + math.max(countedAbilities[3]-2, 0)*4)
            end
        elseif game_version == 2 then
            if ReadShort(superglideSpeedHack[game_version]+1) == 0x17D1 then
                WriteInt(superglideSpeedHack[game_version], 0x17D1BC + math.max(countedAbilities[3]-2, 0)*4)
            end
        end
        
        WriteFloat(mermaidKickSpeed[game_version], 10+(8*countedAbilities[2]))
        
        -- Allow early flight in Neverland if glide equipped
        if countedAbilities[3] > 0 and ReadByte(world[game_version]) == 0xD then
            if (ReadByte(stateFlag[game_version]) // 0x20) % 2 == 0 then
                WriteByte(stateFlag[game_version], ReadByte(stateFlag[game_version]) + 0x20)
            end
        end
    end
end

function _OnInit()
    IsEpicGLVersion  = 0x3A2B86
    IsSteamGLVersion = 0x3A29A6
    if GAME_ID == 0xAF71841E and ENGINE_TYPE == "BACKEND" then
        if ReadByte(IsEpicGLVersion) == 0xFF then
            ConsolePrint("Epic Version Detected")
            game_version = 1
        end
        if ReadByte(IsSteamGLVersion) == 0xFF then
            ConsolePrint("Steam Version Detected")
            game_version = 2
        end
        canExecute = true
    end
end
function _OnFrame()
    if canExecute then
        StackAbilities()
    end
end