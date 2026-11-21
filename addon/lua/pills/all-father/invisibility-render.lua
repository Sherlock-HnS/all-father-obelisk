/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
if not CLIENT then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

-- Apply color modulation when rendering
hook.Add("PreDrawTranslucentRenderables", "FVJOHNNY_PILLS_ALLFATHER_InvisibilityRender", function()
    local localPly = LocalPlayer()
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetClass() ~= "pill_ent_costume" then continue end
        if ent.formTable and ent.formTable.EddyGar_propperties and ent.formTable.EddyGar_propperties["All-Father_invisperms"] then
            local puppet = ent:GetPuppet() -- honestly getting sick and tired of typing ent:GetPuppet()
            local pilluser = ent:GetPillUser()
            local isInvisible = FVJOHNNY_PILLS.AllFather:IsInvisible(pilluser)
            local localPuppet = FVJOHNNY_PILLS:GetPuppet(LocalPlayer())
            local localCostume = LocalPlayer().pk_pill_ent
            local isLocalThing = ent == localPuppet or ent == localCostume

            local color = isInvisible and Color(0, 0, 0, 0) or Color(255, 255, 255, 255)
            if isLocalThing then
                color = isInvisible and Color(100, 100, 100, 100) or Color(255, 255, 255, 255)
            end

            if (color.a == 0) then
                puppet:SetRenderMode(RENDERMODE_NONE)
            elseif (color.a < 255) then
                puppet:SetRenderMode(RENDERMODE_TRANSCOLOR)
            else
                puppet:SetRenderMode(RENDERMODE_NORMAL)
            end

            puppet:SetColor(color)
        end
    end
    
end)
