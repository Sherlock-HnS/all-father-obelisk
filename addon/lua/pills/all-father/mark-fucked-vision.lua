/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
if not CLIENT then return end

FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

-- Create materials for visual effects
local matBlur = Material("pp/blurscreen")
local matColorMod = Material("pp/colour")

-- Timer for peek images
local lastPeekTime = 0
local peekInterval = 5 -- Show peek every 5 seconds

-- Apply fucked up vision effects to marked players
hook.Add("RenderScreenspaceEffects", "FVJOHNNY_PILLS_AllFather_MarkedVision", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not FVJOHNNY_PILLS.AllFather:IsMarked(ply) then return end

    -- SLIGHT BLUR
    render.UpdateScreenEffectTexture()
    matBlur:SetFloat("$blur", 5)
    matBlur:Recompute()
    render.SetMaterial(matBlur)
    render.DrawScreenQuad()

    -- SATURATED COLORS
    local colorModTab = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 3,
        ["$pp_colour_colour"] = 3, -- Increased saturation
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }
    DrawColorModify(colorModTab)
end)