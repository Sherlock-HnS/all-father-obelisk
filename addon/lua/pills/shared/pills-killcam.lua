/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
FVJOHNNY_PILLS = FVJOHNNY_PILLS or {}

local killCamHookName = 'FVJOHNNY_PILLS_KILLCAM'
if SERVER then
    util.AddNetworkString(killCamHookName)

    function FVJOHNNY_PILLS:KillCam(attacker, victim, isStart)
        if not IsValid(attacker) then return end
        if not IsValid(victim) then return end

        local pill = self:GetPuppet(attacker)
        if not IsValid(pill) then return end

        net.Start(killCamHookName)
        net.WriteEntity(pill)
        net.WriteBool(isStart)
        net.Send(victim)
    end

end

if CLIENT then


    net.Receive(killCamHookName, function()
        local ply = LocalPlayer()
        local ent = net.ReadEntity()
        local state = net.ReadBool()

        if not state then
            hook.Remove('CalcView', killCamHookName)
            hook.Remove('ShouldDrawLocalPlayer', killCamHookName)
            return
        end

        local transitionStart = RealTime()

        -- Hide the local player's model during killcam
        hook.Add('ShouldDrawLocalPlayer', killCamHookName, function(ply)
            return false
        end)

        hook.Add('CalcView', killCamHookName, function(ply, pos, angles, fov)
            if not IsValid(ply) or not ply:Alive() or not IsValid(ent) then
                hook.Remove('CalcView', killCamHookName)
                hook.Remove('ShouldDrawLocalPlayer', killCamHookName)
                return
            end
            local transitionProgress = math.Clamp((RealTime() - transitionStart) / 0.25, 0, 1)
            local cam = ent:GetAttachment(1)
            return {
                origin = LerpVector(transitionProgress, pos, cam.Pos),
                angles = LerpAngle(transitionProgress, angles, cam.Ang),
                fov = 80,
                drawviewer = false
            }
        end)
    end)
end

function FVJOHNNY_PILLS:DoKillAttack(attacker, attackerEnt, timeToStop, bloodTimers)
    if not IsValid(attacker) then return false end
    if not IsValid(attackerEnt) then return false end

    local target = self:GetClosestPlayer(attacker, attackerEnt)
    if not IsValid(target) then return false end

    local pill = attackerEnt:GetPuppet()

    for _, t in pairs(bloodTimers or {}) do
        timer.Simple(t, function()
            FVJOHNNY_PILLS:DoKillBlood(attacker, target)
        end)
    end

    if target:IsPlayer() then
        -- target:Freeze(true)
        target:AddFlags(FL_NOTARGET)
        target:DrawViewModel(false)
        -- target:SetActiveWeapon(nil)
        -- target:SetNoDraw(true)

        -- local testpm = ents.Create('prop_dynamic')
        -- testpm:SetModel(target:GetModel())
        -- testpm:SetModelScale(1)
        -- testpm:SetPos(pill:GetPos())
        -- testpm:SetAngles(pill:GetAngles())                                
        -- testpm:SetParent(pill:GetAttachment(1))
        -- testpm:SetSolid(SOLID_NONE)
        -- testpm:AddEffects(EF_BONEMERGE)

        -- testpm:Fire('SetParentAttachment','camera')

        -- testpm:Spawn()

        FVJOHNNY_PILLS:KillCam(attacker, target, true)
    else
        -- Disable NPC's future thinking to simulate freezing them
        target:NextThink(CurTime() + 1e9)
    end

    -- Move the entity into position relative to the pill
    target:SetPos(pill:GetPos() + pill:GetForward() * 55)

    -- Freeze the player (attacker)
    attacker:Freeze(true)

    -- Timer to handle the next steps after the animation
    timer.Simple(timeToStop, function()
        if not IsValid(target) or not IsValid(attackerEnt) then return end

        FVJOHNNY_PILLS:StopKillAttack(attacker, attackerEnt, target)
    end)

    return true
end

function FVJOHNNY_PILLS:StopKillAttack(attacker, attackerEnt, target)
    if not IsValid(attacker) then return end
    if not IsValid(attackerEnt) then return end
    if not IsValid(target) then return end

    attacker:Freeze(false)

    -- Handling NPCs
    if target:IsNPC() or target:IsNextBot() then
        local headBone = target:LookupBone("ValveBiped.Bip01_Head1")
        if headBone then
            target:ManipulateBoneScale(headBone, Vector(0, 0, 0))
        end
    end

    -- -- Handling Players
    if target:IsPlayer() then
        -- target:SetNoDraw(false)
        -- local finalRagdoll = ents.Create("prop_ragdoll")
        -- finalRagdoll:SetModel(target:GetModel())
        -- finalRagdoll:SetPos(target:GetPos())
        -- finalRagdoll:SetAngles(target:GetAngles())
        -- finalRagdoll:Spawn()
        -- timer.Simple(5, function()
        --     finalRagdoll:Remove()
        -- end)

        -- -- Set ragdoll physics
        -- for i = 0, target:GetBoneCount() - 1 do
        --     local phys = finalRagdoll:GetPhysicsObjectNum(i)
        --     if IsValid(phys) then
        --         local pos, ang = target:GetBonePosition(i)
        --         phys:SetPos(pos)
        --         phys:SetAngles(ang)
        --         phys:Wake()
        --     end
        -- end

        -- -- Manipulate head bone
        -- local headBone = finalRagdoll:LookupBone("ValveBiped.Bip01_Head1")
        -- if headBone then
        --     finalRagdoll:ManipulateBoneScale(headBone, Vector(0, 0, 0))
        -- end
    end



    -- Kill the player or damage the NPC
    if target:IsPlayer() then
        target:SetHealth(1)
        target:TakeDamage(1, attacker)
        target:RemoveFlags(FL_NOTARGET)
        target:Freeze(false)
        target:DrawViewModel(true)

        FVJOHNNY_PILLS:KillCam(attacker, target, false)
    else
        target:NextThink(CurTime()) 
        target:TakeDamage(1e9, attacker)
    end
end

function FVJOHNNY_PILLS:DoKillBlood(attacker, target)
    if not IsValid(attacker) then return end
    if not IsValid(target) then return end
    
    local pill = self:GetPuppet(attacker)
    if not IsValid(pill) then return end

    target:TakeDamage(1, attacker)

    -- Get target's head position
    local headBone = target:LookupBone("ValveBiped.Bip01_Head1")
    local headPos = target:GetPos() + Vector(0, 0, 64) -- Default head height

    if headBone then
        headPos = target:GetBonePosition(headBone)
    end

    local bloodPos = headPos
    
    local effectdata = EffectData()
    effectdata:SetOrigin(bloodPos)
    effectdata:SetNormal(target:GetAngles():Forward())
    effectdata:SetMagnitude(3)
    effectdata:SetScale(15)
    effectdata:SetColor(0)
    effectdata:SetFlags(3)
    util.Effect("bloodspray", effectdata)
    effectdata:SetOrigin(bloodPos)
    effectdata:SetNormal(target:GetAngles():Forward())
    effectdata:SetMagnitude(3)
    effectdata:SetScale(15)
    effectdata:SetColor(0)
    effectdata:SetFlags(3)
    util.Effect("BloodImpact", effectdata)
    effectdata:SetOrigin(bloodPos)
    effectdata:SetNormal(target:GetAngles():Forward())
    effectdata:SetMagnitude(3)
    effectdata:SetScale(15)
    effectdata:SetColor(0)
    effectdata:SetFlags(3)
    util.Effect("BloodSplash", effectdata)
end


if SERVER then
	util.AddNetworkString('OBELISKJUMPCAMEDDY')
end

if CLIENT then

	net.Receive('OBELISKJUMPCAMEDDY', function()
		local ply = LocalPlayer()
		local ent = net.ReadEntity()
		local state = net.ReadBool()
		local hookname = 'FNAF2MOVIEEDDY_playercam_new_' .. tostring(ply)

		if not state then
			hook.Remove('CalcView', hookname)
			return
		end

		local transitionStart = RealTime()

		hook.Add('CalcView', hookname, function(ply, pos, angles, fov)
			if not IsValid(ply) or not ply:Alive() or not IsValid(ent) then
				hook.Remove('CalcView', hookname)
				return
			end	
			local transitionProgress = math.Clamp((RealTime() - transitionStart) / 0.25, 0, 1)
			local cam = ent:GetAttachment(ent:LookupAttachment('camera'))
			return {
				origin = LerpVector(transitionProgress, pos, cam.Pos),
				angles = LerpAngle(transitionProgress, angles, cam.Ang),
				fov = 90,
				drawviewer = false
			}
		end)
	end)
end