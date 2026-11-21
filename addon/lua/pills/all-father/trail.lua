/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

if CLIENT then
    -- Hook that runs for everyone, checking all AllFather players
    hook.Add("Think", "FVJOHNNY_PILLS_AllFather_Trail", function()
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) then continue end

            FVJOHNNY_PILLS.AllFather:UpdateTrails(ply)
            FVJOHNNY_PILLS.AllFather:RemoveOldTrails(ply)
        end
    end)

    -- Cleanup trails when player disconnects
    hook.Add("EntityRemoved", "FVJOHNNY_PILLS_AllFather_Trail_Cleanup", function(ent)
        if not ent:IsPlayer() then return end

        FVJOHNNY_PILLS.AllFather:CleanupPlayerTrails(ent)
    end)

    function FVJOHNNY_PILLS.AllFather:CleanupPlayerTrails(ply)
        if not ply.AllFatherTrailModels then return end

        for i = #ply.AllFatherTrailModels, 1, -1 do
            local trail = ply.AllFatherTrailModels[i]
            if IsValid(trail) then
                trail:Remove()
            end
            table.remove(ply.AllFatherTrailModels, i)
        end

        ply.AllFatherTrailModels = nil
        ply.AllFatherLastTrailTime = nil
    end

    function FVJOHNNY_PILLS.AllFather:UpdateTrails(ply)
        if not FVJOHNNY_PILLS:IsPlayerUsingPillName(ply, FVJOHNNY_PILLS.AllFather.CFG.PillName) then return end

        local ent = FVJOHNNY_PILLS:GetPuppet(ply)
        if not IsValid(ent) then return end

        if self:IsInvisible(ent) then return end

        -- Create pixelated body trail effect
        local currentTime = CurTime()
        local trailInterval = 0.05 -- Create a trail every 0.05 seconds

        ply.AllFatherLastTrailTime = ply.AllFatherLastTrailTime or 0
        ply.AllFatherTrailModels = ply.AllFatherTrailModels or {}

        if currentTime - ply.AllFatherLastTrailTime < trailInterval then return end
        ply.AllFatherLastTrailTime = currentTime

        -- Create a clientside model that mimics the current pose
        local trailModel = ClientsideModel(ent:GetModel(), RENDERGROUP_TRANSLUCENT)
        if not IsValid(trailModel) then return end
        trailModel:SetPos(ent:GetPos())
        trailModel:SetAngles(ent:GetAngles())
        trailModel:SetModelScale(ent:GetModelScale())
        trailModel:SetSkin(ent:GetSkin())

        -- Copy bodygroups
        for i = 0, ent:GetNumBodyGroups() - 1 do
            trailModel:SetBodygroup(i, ent:GetBodygroup(i))
        end

        -- Copy submaterials
        for i = 0, 31 do
            local submat = ent:GetSubMaterial(i)
            if submat and submat ~= "" then
                trailModel:SetSubMaterial(i, submat)
            end
        end

        -- Setup bones on the original entity first
        ent:SetupBones()

        trailModel:SetSequence(ent:GetSequence())
        trailModel:SetCycle(ent:GetCycle())

        -- Copy all pose parameters
        for i = 0, ent:GetNumPoseParameters() - 1 do
            local name = ent:GetPoseParameterName(i)
            if name then
                trailModel:SetPoseParameter(name, ent:GetPoseParameter(name))
            end
        end

        -- Setup bones on trail model
        trailModel:SetupBones()

        -- Copy bone matrices for accurate pose
        for i = 0, ent:GetBoneCount() - 1 do
            local matrix = ent:GetBoneMatrix(i)
            if matrix then
                trailModel:SetBoneMatrix(i, matrix)
            end
        end

        trailModel:SetNoDraw(false)
        trailModel.CreationTime = currentTime
        trailModel.LifeTime = 0.25 -- Trail lasts 0.25 seconds

        table.insert(ply.AllFatherTrailModels, trailModel)
    end

    function FVJOHNNY_PILLS.AllFather:RemoveOldTrails(ply)
        -- Clean up if player is no longer valid
        if not IsValid(ply) then
            self:CleanupPlayerTrails(ply)
            return
        end

        local currentTime = CurTime()

        ply.AllFatherTrailModels = ply.AllFatherTrailModels or {}
        for i = #ply.AllFatherTrailModels, 1, -1 do
            local trail = ply.AllFatherTrailModels[i]
            if not IsValid(trail) then table.remove(ply.AllFatherTrailModels, i) continue end

            local age = currentTime - trail.CreationTime
            -- Make trails much less visible (max 30% opacity, fading to 0%)
            local alpha = math.max(0, 77 * (1 - age / trail.LifeTime))

            -- Set pixelated/glitchy appearance with original model colors
            trail:SetColor(Color(255, 255, 255, alpha))
            trail:SetRenderMode(RENDERMODE_TRANSALPHA)

            if age >= trail.LifeTime then
                trail:Remove()
                table.remove(ply.AllFatherTrailModels, i)
            end
        end
    end
end
