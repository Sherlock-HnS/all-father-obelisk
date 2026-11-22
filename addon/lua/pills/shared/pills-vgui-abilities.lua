/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
if not CLIENT then return end

-- HUD configuration
local HUD_CONFIG = {
    abilitySize = 200,           -- Size of ability icons
    abilitySpacing = 10,        -- Spacing between icons
    offsetX = 20,               -- Distance from left edge of screen
    offsetY = 100,               -- Distance from bottom edge of screen
    cooldownFont = "DermaLarge",
    cooldownColor = Color(255, 255, 255, 255),
    cooldownShadowColor = Color(0, 0, 0, 200),
}

-- Cache for materials
local materialCache = {}

function FVJOHNNY_PILLS:RegisterAbilitiesGUI(CFG)
    hook.Add("HUDPaint", "FVJOHNNY_PILLS_AbilitiesGUI_" .. CFG.PillName, function()
        if SherlockHNS then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if not FVJOHNNY_PILLS:IsPlayerUsingPillName(ply, CFG.PillName) then return end

        -- Get abilities for current pill
        if not CFG.AbilitiesGUI or #CFG.AbilitiesGUI == 0 then return end

        -- Calculate starting position (bottom left corner)
        local scrW, scrH = ScrW(), ScrH()
        local size = HUD_CONFIG.abilitySize
        local spacing = HUD_CONFIG.abilitySpacing

        -- Starting X position (left-aligned)
        local startX = HUD_CONFIG.offsetX
        local startY = scrH - HUD_CONFIG.offsetY - size

        local movefromrightside = true

        -- Draw each ability
        for i, ability in ipairs(CFG.AbilitiesGUI) do
            local x = (startX + ((i - 1) * (size + spacing)))
            if movefromrightside then
                local startX = scrW - startX
                x = (startX - size - ((i - 1) * (size + spacing)))
            end

            FVJOHNNY_PILLS:DrawAbility(x, startY, ability, ability.button, ply)
        end
    end)
end


-- Get material from cache or load it
local function GetMaterial(materialPath)
    if not materialCache[materialPath] then
        materialCache[materialPath] = Material("materials/" .. materialPath)
    end
    return materialCache[materialPath]
end

-- Draw a single ability icon with cooldown
function FVJOHNNY_PILLS:DrawAbility(x, y, abilityConfig, button, ply)
    local size = HUD_CONFIG.abilitySize

    -- Get cooldown information
    local nextAllowedTime = FVJOHNNY_PILLS:GetNextAllowedTime(ply, button)
    local lastPressedTime = FVJOHNNY_PILLS:GetLastPressedTime(ply, button)
    local totalCooldown = nextAllowedTime - lastPressedTime
    local currentTime = CurTime()
    local cooldownRemaining = math.max(0, nextAllowedTime - currentTime)
    local isOnCooldown = cooldownRemaining > 0

    -- Calculate recovery percentage (0 = just used, 1 = ready)
    local recoveryPercent = 1
    if isOnCooldown and totalCooldown > 0 then
        recoveryPercent = 1 - (cooldownRemaining / totalCooldown)
    end

    -- Get the material
    local mat = GetMaterial(abilityConfig.material)
    if mat then
        local recoveredHeight = size * recoveryPercent
        local cooldownHeight = size - recoveredHeight

        -- Draw the top part (still on cooldown) with semi-transparent
        if cooldownHeight > 0 then
            surface.SetDrawColor(255, 255, 255, 64)  -- 25% opacity
            surface.SetMaterial(mat)
            -- Draw top portion: UV from (0,0) to (1, 1-recoveryPercent)
            surface.DrawTexturedRectUV(x, y, size, cooldownHeight, 0, 0, 1, 1 - recoveryPercent)
        end

        -- Draw the bottom part (recovered) with full opacity
        if recoveredHeight > 0 then
            surface.SetDrawColor(255, 255, 255, 255)  -- Full opacity
            surface.SetMaterial(mat)
            -- Draw bottom portion: UV from (0, 1-recoveryPercent) to (1, 1)
            surface.DrawTexturedRectUV(x, y + cooldownHeight, size, recoveredHeight, 0, 1 - recoveryPercent, 1, 1)
        end
        if abilityConfig.keybind then
            local modifierx = abilityConfig.uioffsetx or 0
            local modifiery = abilityConfig.uioffsety or 0
            draw.SimpleText(abilityConfig.keybind, "Abilitylabel", x + size * modifierx, y + size * modifiery, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
        end
    end

    -- Draw cooldown text in bottom right of icon
    if isOnCooldown then
        local cooldownText = string.format("%.1f", cooldownRemaining)

        surface.SetFont(HUD_CONFIG.cooldownFont)
        local textW, textH = surface.GetTextSize(cooldownText)

        -- Position in bottom right corner with small padding
        local textX = x + size - textW - 4
        local textY = y + size - textH - 4

        -- Draw shadow
        draw.SimpleText(cooldownText, HUD_CONFIG.cooldownFont, textX + 1, textY + 1, HUD_CONFIG.cooldownShadowColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        -- Draw text
        draw.SimpleText(cooldownText, HUD_CONFIG.cooldownFont, textX, textY, HUD_CONFIG.cooldownColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end