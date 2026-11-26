/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
if not CLIENT then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

local INVIS_COLOR_OTHERS = Color(0, 0, 0, 0)
local INVIS_COLOR_LOCAL  = Color(100, 100, 100, 100)
local VISIBLE_COLOR      = Color(255, 255, 255, 255)

-- Apply color modulation when rendering
hook.Add("PreDrawTranslucentRenderables", "FVJOHNNY_PILLS_ALLFATHER_InvisibilityRender", function()
    local localPly = LocalPlayer()
    if not IsValid(localPly) then return end

    local localPuppet  = FVJOHNNY_PILLS:GetPuppet(localPly)
    local localCostume = localPly.pk_pill_ent

    for _, ent in ipairs(ents.FindByClass("pill_ent_costume")) do
        local ft = ent.formTable
        if not (ft and ft.EddyGar_propperties and ft.EddyGar_propperties["All-Father_invisperms"]) then continue end

        local puppet   = ent:GetPuppet()
        local pilluser = ent:GetPillUser()
        if not IsValid(puppet) or not IsValid(pilluser) then continue end

        local isInvisible = FVJOHNNY_PILLS.AllFather:IsInvisible(pilluser)
        local isLocalThing = ent == localPuppet or ent == localCostume

        local color
        if isInvisible then
            color = isLocalThing and INVIS_COLOR_LOCAL or INVIS_COLOR_OTHERS
        else
            color = VISIBLE_COLOR
        end

        if color.a == 0 then
            puppet:SetRenderMode(RENDERMODE_NONE)
        elseif color.a < 255 then
            puppet:SetRenderMode(RENDERMODE_TRANSCOLOR)
        else
            puppet:SetRenderMode(RENDERMODE_NORMAL)
        end

        puppet:SetColor(color)
    end
end)
