/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
if not CLIENT then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

if CLIENT then

    function FVJOHNNY_PILLS.AllFather:ShouldRecolorEntity(ent)
        if not (ent:IsPlayer() or ent:IsNPC()) then return false end
        if ent == LocalPlayer()  then return false end
        if IsValid(ent.pk_pill_ent) then return false end
        if ent:Health() <= 0 then return false end
        
        return true
    end
    function FVJOHNNY_PILLS.AllFather:GetPlayerGlowColor(ply)
        local RightClickCfg = FVJOHNNY_PILLS.AllFather.CFG.RightClick
        local baseColor = RightClickCfg.playersTurnIntoColor
        local targetColor = RightClickCfg.markedPlayerColor

        -- If player is fully marked, always return target color regardless of markPercentage
        if self:IsMarkedBy(ply, LocalPlayer()) then
            return targetColor
        end

        -- If spectre vision is not active, return white
        if not self:IsSpectreVisionActive(LocalPlayer()) then
            return Color(255, 255, 255, 255)
        end

        -- Otherwise, interpolate based on mark percentage
        local markPercentage = FVJOHNNY_PILLS.AllFather:GetMarkPercentage(ply)
        if markPercentage and markPercentage > 0 then
            local t = math.Clamp(markPercentage / 100, 0, 1)

            local r = Lerp(t, baseColor.r, targetColor.r)
            local g = Lerp(t, baseColor.g, targetColor.g)
            local b = Lerp(t, baseColor.b, targetColor.b)
            local a = Lerp(t, baseColor.a, targetColor.a)

            return Color(r, g, b, a)
        end

        return baseColor
    end

    function FVJOHNNY_PILLS.AllFather:GetEntitiesForGlow()
        local spectreVisionActive = FVJOHNNY_PILLS.AllFather:IsSpectreVisionActive(LocalPlayer())

        local entities = {}
        local localPly = LocalPlayer()
        local searchRadius = 5000 -- Adjust radius as needed
        for _, ent in ipairs(ents.FindInSphere(localPly:GetPos(), searchRadius)) do
            if not FVJOHNNY_PILLS.AllFather:ShouldRecolorEntity(ent) then continue end
            if not spectreVisionActive and not FVJOHNNY_PILLS.AllFather:IsMarkedBy(ent, LocalPlayer()) then continue end

            table.insert(entities, ent)
        end
        return entities
    end

    local whiteMat  = Material("models/debug/debugwhite")
    hook.Add("PreDrawEffects","FVJOHNNY_PILLS_ALLFATHER_YellowSpectreVision",function()
        

        render.SuppressEngineLighting(true)
        render.SetLightingMode(1)
        render.MaterialOverride(whiteMat)
        render.SetBlend(0.2)

        -- Draw each entity with its individual color
        local localPly = LocalPlayer()
        for _, ent in ipairs(FVJOHNNY_PILLS.AllFather:GetEntitiesForGlow()) do
            local color = FVJOHNNY_PILLS.AllFather:GetPlayerGlowColor(ent)
            render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
            ent:DrawModel()
        end

        render.MaterialOverride()
        render.SetBlend(1)
        render.SetLightingMode(0)
        render.SuppressEngineLighting(false)
    end)

    hook.Add("PrePlayerDraw","FVJOHNNY_PILLS_ALLFATHER_YellowSpectreVision_HideSelf",function(ply)
        if ply == LocalPlayer() and FVJOHNNY_PILLS.AllFather:IsSpectreVisionActive(LocalPlayer()) then
            return true   
        end
    end)

    hook.Add("PreDrawHalos", "FVJOHNNY_PILLS_ALLFATHER_YellowSpectreGlow", function()
        local spectreVisionActive = FVJOHNNY_PILLS.AllFather:IsSpectreVisionActive(LocalPlayer())

        local RightClickCfg = FVJOHNNY_PILLS.AllFather.CFG.RightClick

        -- Group players by their glow color for efficient rendering
        local entitiesByColor = {}

        local localPly = LocalPlayer()
        for _, ent in ipairs(FVJOHNNY_PILLS.AllFather:GetEntitiesForGlow()) do
            local color = FVJOHNNY_PILLS.AllFather:GetPlayerGlowColor(ent)
            local colorKey = string.format("%d_%d_%d_%d", color.r, color.g, color.b, color.a)

            if not entitiesByColor[colorKey] then
                entitiesByColor[colorKey] = {
                    color = color,
                    entities = {}
                }
            end

            table.insert(entitiesByColor[colorKey].entities, ent)
        end

        -- Draw halos for each color group
        for _, data in pairs(entitiesByColor) do
            if #data.entities > 0 then
                halo.Add(data.entities, data.color, 3, 3, 2)
            end
        end
    end)
end
