hook.Add("PlayerDeath", "NoRagdollOnDeath_obelisk", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) and IsValid(ply:GetRagdollEntity()) then
            if not ply:GetNWBool("obelisk_shouldnotragdol") then return end
            ply:SetNWBool("obelisk_shouldnotragdol", false)
            ply:GetRagdollEntity():Remove()
        end
    end)
end)   

hook.Add("PlayerButtonDown", "obeliskgkey", function(ply, button)
    local pillentity = ply.pk_pill_ent
    if IsValid(pillentity) then
        if pillentity.formTable.ObeliskKeybind then
            pillentity.formTable.ObeliskKeybind(ply, pillentity, button)
        end
    end
end)
    
    
    hook.Add("OnEntityCreated", "obelisk_initialize_gem_5", function(ent)
    timer.Simple(0.01, function()
        if !IsValid(ent) then return end
        if ent:GetClass() ~= "pill_ent_costume" then return end


        if ent.formTable then
            local PuppetEntity = ent:GetPuppet()
            local entityply = ent:GetPillUser()

            if ent.formTable.obelisk_customfunction then
                ent.formTable:obelisk_customfunction(entityply, ent, PuppetEntity)
            end

            if ent.formTable.obelisk_initialize then 
                ent.formTable:obelisk_initialize(entityply, ent, PuppetEntity)
                 hook.Add("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex(), function(ply) if entityply == ply then return true end end)

                    ent:CallOnRemove("RemoveHook_OM"..ent:EntIndex(), function()
                        hook.Remove("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex())
                    end)

                local self = ent
                ent.Think = function()
                    local ply = self:GetPillUser()
                    local puppet = self:GetPuppet()
                    if not IsValid(puppet) or not IsValid(ply) then return end
                    local vel = ply:GetVelocity():Length()

                    if SERVER then
                        --Anims
                        local anims = table.Copy(self.formTable.anims.default or {})
                        table.Merge(anims, (IsValid(ply:GetActiveWeapon()) and self.formTable.anims[ply:GetActiveWeapon():GetHoldType()]) or (self.forceAnimSet and self.formTable.anims[self.forceAnimSet]) or {})
                        local anim
                        --local useSeqVel=true
                        local overrideRate

                        if (not self.anim or not anims[self.anim]) then
                            self.animFreeze = nil
                            self.animStart = nil
                        end

                        if self.animFreeze and not self.plyFrozen then
                            self:ApplyMoveSpeed()
                            self.plyFrozen = true
                        elseif not self.animFreeze and self.plyFrozen then
                            self:ApplyMoveSpeed()
                            self.plyFrozen = nil
                        end

                        if self.anim and anims[self.anim] then
                            anim = anims[self.anim]
                            overrideRate = anims[self.anim .. "_rate"] or 1
                            local cycle = puppet:GetCycle()

                            if not self.animStart then
                                if cycle == 1 or (self.animCycle and self.animCycle > cycle) or (string.lower(anim) ~= string.lower(puppet:GetSequenceName(puppet:GetSequence()))) then
                                    self.anim = nil
                                    self.animCycle = nil

                                    if self.animFreeze then
                                        self.animFreeze = nil
                                    end
                                elseif self.animCycle then
                                    self.animCycle = cycle
                                end
                            end
                        elseif self.tickAnim and anims[self.tickAnim] then
                            anim = anims[self.tickAnim]
                            overrideRate = anims[self.tickAnim .. "_rate"] or 1
                            self.tickAnim = nil
                        elseif self.burrowed then
                            anim = anims["burrow_loop"]
                        elseif ply:WaterLevel() > 2 then
                            anim = anims["swim"] or anims["glide"] or anims["idle"]
                        elseif ply:IsOnGround() then
                            if ply:Crouching() then
                                if vel > ply:GetCrouchedWalkSpeed() / 4 then
                                    anim = anims["crouch_walk"] or anims["crouch"] or anims["walk"] or anims["idle"]
                                else
                                    anim = anims["crouch"] or anims["idle"]
                                end
                            else
                                if vel > (ply:GetWalkSpeed() + ply:GetRunSpeed()) / 2 then
                                    anim = anims["run"] or anims["walk"] or anims["idle"]
                                elseif vel > ply:GetWalkSpeed() / 4 then
                                    anim = anims["walk"] or anims["idle"]
                                else
                                    anim = anims["idle"]
                                end
                            end
                        else
                            anim = anims["glide"] or anims["idle"]
                        end

                        if anim == anims["idle"] or anim == anims["crouch"] then
                            overrideRate = 1
                        end

                        if (anim and puppet:GetSequence() ~= puppet:LookupSequence(anim)) or self.animStart or (self.formTable.autoRestartAnims and puppet:GetCycle() == 1) then
                            puppet:ResetSequence(puppet:LookupSequence(anim))
                            puppet:SetCycle(0)
                            self.animCycle = 0
                        end

                        self.animStart = nil
                        local seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                        --if true then
                        if self.formTable.movePoseMode ~= "xy" and self.formTable.movePoseMode ~= "xy-bot" and not overrideRate then
                            local rate = overrideRate or vel / seq_vel

                            --goofy limitation (floods console with errors if above 12!)
                            if rate > 12 then
                                rate = 12
                            end

                            puppet:SetPlaybackRate(rate)
                        else
                            --puppet:SetPlaybackRate(1)
                        end

                        --print(puppet:GetCycle())
                        if self.formTable.movePoseMode then
                            --
                            if self.formTable.movePoseMode == "yaw" then
                                local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                puppet:SetPoseParameter("move_yaw", move_dir.y)
                            elseif self.formTable.movePoseMode == "xy" then
                                if not overrideRate then
                                    local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                    local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                    local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                    puppet:SetPoseParameter("move_x", clampedvel.x)
                                    puppet:SetPoseParameter("move_y", -clampedvel.y)
                                    seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                    if seq_vel ~= 0 then
                                        puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                    end
                                    --print(puppet:GetPlaybackRate())
                                else
                                    puppet:SetPoseParameter("move_x", 0)
                                    puppet:SetPoseParameter("move_y", 0)
                                end
                            elseif self.formTable.movePoseMode == "xy-bot" then
                                if not overrideRate then
                                    local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                    local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                    local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                    local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                    puppet:SetPoseParameter("move_x", clampedvel.x)
                                    puppet:SetPoseParameter("move_y", -clampedvel.y)
                                    puppet:SetPoseParameter("move_yaw", move_dir.y)
                                    puppet:SetPoseParameter("move_scale", 1)
                                    seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                    if seq_vel ~= 0 then
                                        puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_scale", math.Clamp(localvel:Length() / seq_vel, -.99, .99))
                                    end
                                    --print(puppet:GetPlaybackRate())
                                else
                                    puppet:SetPoseParameter("move_x", 0)
                                    puppet:SetPoseParameter("move_y", 0)
                                    puppet:SetPoseParameter("move_yaw", 0)
                                    puppet:SetPoseParameter("move_scale", 0)
                                end
                            end
                        end

                        --Aimage
                        if self.formTable.aim then
                            if self.formTable.aim.xPose then
                                local yaw = math.AngleDifference(ply:EyeAngles().y, self:GetAngles().y)

                                if self.formTable.aim.xInvert then
                                    yaw = -yaw
                                end

                                puppet:SetPoseParameter(self.formTable.aim.xPose, yaw)
                            end

                            if self.formTable.aim.yPose then
                                local pitch = math.AngleDifference(ply:EyeAngles().p, self:GetAngles().p)

                                if self.formTable.aim.yInvert then
                                    pitch = -pitch
                                end

                                puppet:SetPoseParameter(self.formTable.aim.yPose, pitch)
                            end
                        end

                        --gliding and landing
                        if not ply:IsOnGround() and ply:WaterLevel() == 0 and self.formTable.glideThink then
                            self.formTable.glideThink(ply, self)
                        end

                        if not ply:IsOnGround() and not self.touchingWater and ply:WaterLevel() > 0 and self.formTable.land then
                            self.formTable.land(ply, self)
                        end

                        --water death
                        self.touchingWater = ply:WaterLevel() > 1

                        if not SherlockHNS and self.formTable.damageFromWater and self.touchingWater then
                            if self.formTable.damageFromWater == -1 then
                                --self:PillDie()
                                ply:Kill()
                            else
                                ply:TakeDamage(self.formTable.damageFromWater)
                                --TODO APPLY DAMAGE
                            end
                        end

                        --tick attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "tick" then
                            print("auto")
                            self.formTable.attack.func(ply, self, self.formTable.attack)
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "tick" then
                            self.formTable.attack2.func(ply, self, self.formTable.attack2)
                        end


                        --auto attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack")
                            else
                                self:PillLoopStop("attack")
                            end

                            if (not self.lastAttack or (self.formTable.attack.interval or self.formTable.attack.delay) < CurTime() - self.lastAttack) then
                                self.formTable.attack.func(ply, self, self.formTable.attack)
                                self.lastAttack = CurTime()
                            end
                        else
                            self:PillLoopStop("attack")
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack2")
                            else
                                self:PillLoopStop("attack2")
                            end

                            if not self.lastAttack2 or (self.formTable.attack2.interval or self.formTable.attack2.delay) < CurTime() - self.lastAttack2 then
                                self.formTable.attack2.func(ply, self, self.formTable.attack2)
                                self.lastAttack2 = CurTime()
                            end
                        else
                            self:PillLoopStop("attack2")
                        end

                        --charge
                        if not SherlockHNS and self:GetChargeTime() ~= 0 then
                            if ply:OnGround() then
                                local charge = self.formTable.charge
                                local angs = ply:EyeAngles()
                                self:PillAnimTick("charge_loop")
                                local hit_ent = ply:TraceHullAttack(ply:EyePos(), ply:EyePos() + angs:Forward() * 100, Vector(-20, -20, -20), Vector(20, 20, 20), charge.dmg, DMG_CRUSH, 1, true)

                                if IsValid(hit_ent) then
                                    self:PillAnim("charge_hit", true)
                                    --self:PillGesture("charge_hit")
                                    self:PillSound("charge_hit")
                                    self:SetChargeTime(0)
                                    self:PillLoopStop("charge")
                                end
                            else
                                self:SetChargeTime(0)
                                self:PillLoopStop("charge")
                            end
                        end

                        --Cloak
                        if self.formTable.cloak then
                            local cloak = self.formTable.cloak

                            if self.iscloaked then
                                local cloakamt = self:GetCloakLeft()

                                if cloakamt ~= -1 then
                                    cloakamt = cloakamt - FrameTime()

                                    if cloakamt < 0 then
                                        cloakamt = 0
                                        self:ToggleCloak()
                                    end

                                    self:SetCloakLeft(cloakamt)
                                end
                            else
                                local cloakamt = self:GetCloakLeft()

                                if cloakmt ~= -1 and cloakamt < cloak.max then
                                    cloakamt = cloakamt + FrameTime() * cloak.rechargeRate

                                    if cloakamt > cloak.max then
                                        cloakamt = cloak.max
                                    end

                                    self:SetCloakLeft(cloakamt)
                                end
                            end

                            local color = self:GetPuppet():GetColor()

                            if self.iscloaked then
                                if color.a > 0 then
                                    color.a = color.a - 5
                                    self:GetPuppet():SetColor(color)
                                end
                            else
                                if color.a < 255 then
                                    color.a = color.a + 5
                                    self:GetPuppet():SetColor(color)
                                end
                            end

                            --PrintTable(color)
                            if IsValid(self.wepmdl) and self.wepmdl:GetColor().a ~= color.a then
                                self.wepmdl:SetColor(color)
                            end
                        end

                        --if !IsValid(ply) then self:NextThink(CurTime()) return true end
                        --wepon-no longer SO hackey
                        if not self.formTable.hideWeapons then
                            local realWep = self:GetPillUser():GetActiveWeapon()

                            --&&self:GetPillUser()!=ply or pk_pills.var_thirdperson:GetBool()) then
                            if IsValid(realWep) and realWep:GetModel() ~= "" then
                                --hiding the real thing [BROKEN]
                                --[[if realWep:GetRenderMode()!=RENDERMODE_NONE then
                                    realWep:SetRenderMode(RENDERMODE_NONE)
                                end]]
                                if realWep.pill_attachment then
                                    if IsValid(self.wepmdl) then
                                        self.wepmdl:Remove()
                                    end

                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl.attachment = realWep.pill_attachment
                                    self.wepmdl:Spawn()

                                    if realWep.pill_offset then
                                        self.wepmdl:SetWepOffset(realWep.pill_offset)
                                    end

                                    if realWep.pill_angle then
                                        self.wepmdl:SetWepAng(realWep.pill_angle)
                                    end

                                    realWep.pill_proxy = self.wepmdl
                                elseif not IsValid(self.wepmdl) then
                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl:Spawn()
                                    realWep.pill_proxy = self.wepmdl
                                elseif self.wepmdl:GetModel() ~= realWep:GetModel() then
                                    self.wepmdl:SetModel(realWep:GetModel())
                                end
                            elseif IsValid(self.wepmdl) then
                                self.wepmdl:Remove()
                            end
                        end
                    else
                        self:SetNWBool('clientsideshould', not pk_pills.convars.cl_thirdperson:GetBool())

                        if self:GetPillUser() ~= LocalPlayer() or true then
                            puppet:SetNoDraw(false)
                        end

                        local realWep = self:GetPillUser():GetActiveWeapon()

                        if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                            realWep:SetNoDraw(true)
                        end
                    end

                    --Align pos and angles with player
                    if SERVER then
                        puppet:SetPos(ply:GetPos())
                        self:SetAngles(ply:GetAngles())
                    else
                        puppet:SetRenderOrigin(ply:GetPos())
                    end

                    if vel > 0 or math.abs(math.AngleDifference(puppet:GetAngles().y, ply:EyeAngles().y)) > 350 or self:GetNWBool('clientsideshould') then
                        local angs = ply:EyeAngles()
                        angs.p = 0

                        if SERVER then
                            puppet:SetAngles(angs)
                        else
                            --puppet:SetAngles(angs)
                            puppet:SetRenderAngles(angs)
                        end
                    end

                    self:NextThink(CurTime())

                    return true
                end


            else
            end
        end

        if ent.formTable.HandleAnimEvent_g_rac then
            print(1)
            local PuppetEntity = ent:GetPuppet()
            local entityply = ent:GetPillUser()

            if IsValid(PuppetEntity) then
                print(2)
                function PuppetEntity:AcceptInput(inputName, activator, caller, data)
                    ent.formTable.HandleAnimEvent_g_rac(entityply, ent, inputName)
                    return true
                end
            end
        else
            print(0)
        end
    end)
end)



    hook.Add("CalcView", "momo_calcview", function(ply, pos, ang, fov)
        local ent = pk_pills.getMappedEnt(LocalPlayer())

        if IsValid(ent) and ply:GetViewEntity() == ply then
            local startpos

            if ent.formTable.type == "phys" then
                startpos = ent:LocalToWorld(ent.formTable.camera and ent.formTable.camera.offset or Vector(0, 0, 0))
            else
                startpos = pos
            end

            if pk_pills.convars.cl_thirdperson:GetBool() then

                if ent.formTable.ThirdPersonBone then

                    if IsValid(ent:GetPuppet()) then
                        local bonename = ent.formTable.ThirdPersonBone[1]
                        local boneID = ent:GetPuppet():LookupBone(bonename)
                        local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)

                        local dist

                        if ent.formTable.type == "phys" and ent.formTable.camera and ent.formTable.camera.distFromSize then
                            dist = ent:BoundingRadius() * 5
                        else
                            dist = ent.formTable.camera and ent.formTable.camera.dist or 100
                        end
                        local startpos = bonePos + LocalPlayer():GetForward() * (ent.formTable.ThirdPersonBone[2]) + LocalPlayer():GetUp() * (ent.formTable.ThirdPersonBone[4])+ LocalPlayer():GetRight() * (ent.formTable.ThirdPersonBone[3])
                        local underslung = ent.formTable.camera and ent.formTable.camera.underslung
                        local offset = LocalToWorld(Vector(-dist, 0, underslung and -dist / 5 or dist / 5), Angle(0, 0, 0), Vector(0, 0, 0), ang)

                        local tr = util.TraceHull({
                            start = startpos,
                            endpos = startpos + offset,
                            filter = ent.camTraceFilter,
                            mins = Vector(-5, -5, -5),
                            maxs = Vector(5, 5, 5),
                            mask = MASK_VISIBLE
                        })

                        local view = {}
                        view.origin = tr.HitPos
                        view.angles = ang
                        view.fov = fov
                        view.drawviewer = true

                        return view
                    end
                end

                local dist

                if ent.formTable.type == "phys" and ent.formTable.camera and ent.formTable.camera.distFromSize then
                    dist = ent:BoundingRadius() * 5
                else
                    dist = ent.formTable.camera and ent.formTable.camera.dist or 100
                end

                local underslung = ent.formTable.camera and ent.formTable.camera.underslung
                local offset = LocalToWorld(Vector(-dist, 0, underslung and -dist / 5 or dist / 5), Angle(0, 0, 0), Vector(0, 0, 0), ang)

                local tr = util.TraceHull({
                    start = startpos,
                    endpos = startpos + offset,
                    filter = ent.camTraceFilter,
                    mins = Vector(-5, -5, -5),
                    maxs = Vector(5, 5, 5),
                    mask = MASK_VISIBLE
                })

                local view = {}
                view.origin = tr.HitPos
                view.angles = ang
                view.fov = fov
                view.drawviewer = true

                return view
            else
                if ent.formTable.FirstPersonBone then
                    if IsValid(ent:GetPuppet()) then
                        local bonename = ent.formTable.FirstPersonBone[1]
                        local boneID = ent:GetPuppet():LookupBone(bonename)
                        local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)
                        local view = {}
                        view.origin = bonePos + LocalPlayer():GetForward() * (ent.formTable.FirstPersonBone[2]) + LocalPlayer():GetUp() * (ent.formTable.FirstPersonBone[4])+ LocalPlayer():GetRight() * (ent.formTable.FirstPersonBone[3])
                        view.angles = ang
                        view.fov = fov
                        view.drawviewer = false
                        return view
                    end
                end
            end
        end
    end)


/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/

FVJOHNNY_PILLS = FVJOHNNY_PILLS or {}


pk_pills.packStart("Sonic Saves Robloxia","SonicSavesRobloxia","pills/fvjohnny.png")
function FVJOHNNY_PILLS:RegisterPill(CFG)
    pk_pills.register(CFG.PillName,{
        init=CFG.Init or function(ply, ent) end,
        printName=CFG.Name,
        model=CFG.Model,
        modelScale=CFG.ModelScale,
        anims=CFG.Anims,
        noragdoll=CFG.Noragdoll,
        moveSpeed=CFG.MoveSpeed,
        sounds={},
        type="ply",
        camera=CFG.Camera,
        jumpPower=CFG.JumpPower,
        health=CFG.Health,
        muteSteps=CFG.ShouldMuteOriginalSteps,
        movePoseMode=CFG.MovePoseMode,
        aim=CFG.Aim,
        canAim=CFG.CanAim,
        EddyGar_propperties = CFG.EddyGar_propperties,
        attack= {
            mode = "trigger",
            func = function(ply, ent)
                FVJOHNNY_PILLS:PressButton(ply, ent, "LeftClick", CFG)
            end,
        },
        attack2 = {
            mode = "trigger",
            func = function(ply, ent)
                FVJOHNNY_PILLS:PressButton(ply, ent, "RightClick", CFG)
            end,
        },
        reload = function(ply, ent)
            FVJOHNNY_PILLS:PressButton(ply, ent, "Reload", CFG)
        end,
        flashlight = function(ply, ent)
            FVJOHNNY_PILLS:PressButton(ply, ent, "Flashlight", CFG)
        end,
        jump = function(ply, ent)
            FVJOHNNY_PILLS:PressButton(ply, ent, "Jump", CFG)
        end,
    }, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
        { id = "mark", name = "Visão espectral", key = IN_ATTACK2, OnUse = form.attack2.func },
        { id = "invisible", name = "Invisibilidade", key = IN_RELOAD, OnUse = form.reload },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
end)

    FVJOHNNY_PILLS:RegisterPillsButtonPress(CFG)
    FVJOHNNY_PILLS:RegisterPillThink(CFG)
    FVJOHNNY_PILLS:RegisterPillSteps(CFG)
    if CLIENT then
        FVJOHNNY_PILLS:RegisterAbilitiesGUI(CFG)
    end
end

function FVJOHNNY_PILLS:GetClosestPlayer(ply, ent)
     for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 75)) do
        if not (v:IsPlayer() or v:IsNextBot() or v:IsNPC()) then continue end 
        if v == ent or v == ply then continue end
        if v.Team and v:Team() == TEAM_SPECTATOR then continue end
        if v:Health() <= 0 then continue end
        return v
    end
end

if SERVER then
    util.AddNetworkString("spriteimageobelisk")
    util.AddNetworkString("stopspriteimageobelisk")
    util.AddNetworkString("recivejumpplayer")
    util.AddNetworkString("sendbacktoclientobelisk")
    util.AddNetworkString("sendshiftbacktoclient")
    util.AddNetworkString("reciveshiftplayer")
    util.AddNetworkString("redvignette")
    util.AddNetworkString("redvignettestop")
    util.AddNetworkString("restart_obelisk")
    util.AddNetworkString("digcooldown")
    util.AddNetworkString("digcooldown2")
    util.AddNetworkString("ragecooldownobelisk")
    util.AddNetworkString("ragecooldown2")
    util.AddNetworkString("spriteimagedisapearnoclip")
    util.AddNetworkString("obeliskscreamingtocliennt")
    util.AddNetworkString("obelisskscreamstop")
    util.AddNetworkString("nonsensenetworkingshit")
    util.AddNetworkString("ragescreamabilitdisableability")
end

pk_pills.register("pill_obelisk",{

    printName="Obelisk",
	
    model="models/whynotboi/pills/allfather/obelisk.mdl",
	
	modelScale="1",
    muteSteps = true,
	
    anims={
        default={
            idle="idle",
			run="run",
            walk="walk",
			attack="kill",
			jumpscare="kill",
            missattack="missattack",
            laugh="laugh",
            crouch="idle",
            crouch_walk="walk",
            noclipmerge = "groundemerge",
            noclipenter = "groundenter",
        },
    },
	
    moveSpeed={
        walk=70,
        run=580,
        ducked=100,
    },
	
    sounds={
		digdown="obelisk/obeliskdigdown.wav",
        emerge="obelisk/obeliskdigstop.wav",
        kill="obelisk/obeliskkill.wav",
    },
	

    type="ply",

    camera={
        dist=120
    },
	
    jumpPower=0,
	
    health=250000,
	
	movePoseMode="xy",
		aim={
		xPose="aim_yaw",
		yPose="aim_pitch",
		nocrosshair = true
	},

    FirstPersonBone = {
        'Head',
        20,
        0,
        10,
    },
   ThirdPersonBone = {
       'Head',
        -40,
        30,
        5,
    },
	
	canAim=function(ply,ent)
        return ent.active
	end,

    obelisk_initialize = function(ply, ent, puppet)
        -- jump
        net.Receive("recivejumpplayer", function()
            local PlayerPressedButton = net.ReadEntity()

            if PlayerPressedButton == ent then return end
            if not puppet.formTable or puppet.formTable.name ~= "pill_obelisk" then return end

            net.Start("sendbacktoclientobelisk")
            net.WriteEntity(PlayerPressedButton)
            net.Send(ent)
            
            print(PlayerPressedButton)
        end)

        -- shift
        net.Receive("reciveshiftplayer", function()
            local PlayerPressedShift = net.ReadEntity()

            if PlayerPressedShift == ent then return end
            if not puppet.formTable or puppet.formTable.name ~= "pill_obelisk" then return end

            net.Start("sendshiftbacktoclient")
            net.WriteEntity(PlayerPressedShift)
            net.Send(ent)
            
            print(PlayerPressedShift)
        end)
    end,


obelisk_customfunction = function(ply, ent, puppet)
end,



    attack = {
        mode = 'trigger',
            func = function(ply, ent)
            if burrowed then return end
            ply:SetNWBool("obelisk_shouldnotragdol", true)
            local ratio = 0.3
            local entity = nil
            local puppet = ent:GetPuppet()

            local attachmentID = puppet:LookupAttachment("camera")
            local attachment = puppet:GetAttachment(attachmentID)

            for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 90)) do
                if v:IsPlayer() or v:IsNextBot() or v:IsNPC() then
                    if v == ent or v == ply then continue end

                    if (v:IsPlayer() and v:Team() ~= TEAM_SPECTATOR) or (v:IsNPC() or v:IsNextBot()) and v:Health() > 0 then

                    local trace = util.TraceLine({start = ent:EyePos(), endpos = v:EyePos(), filter = {ent, ply}, mask = MASK_VISIBLE})

                    if not trace.Hit then
                        entity = v
                        break
                    end
                end
            end
        end

        if SherlockHNS and IsValid(entity) and entity:IsPlayer() then
            return pk_pills.playHNSJumpscare(ply, ent, entity, 2.67, {
                camera = "OBELISKJUMPCAMEDDY",
                offset = 50,
                animation = "jumpscare",
                sound = "kill",
            })
        end

        if IsValid(entity) then
            local pill = ent:GetPuppet()

            ragdoll = ents.Create("prop_ragdoll")
            ragdoll:SetModel(entity:GetModel())
            ragdoll:SetPos(attachment.Pos)
            ragdoll:SetCollisionGroup(COLLISION_GROUP_WORLD)
            ragdoll:Activate()
            ragdoll:Spawn()

            phys = ragdoll:GetPhysicsObject()

            timer.Create("setpos", 0.01, 0, function()
                if not IsValid(ragdoll) and IsValid(phys) then return end

                local attachmentID = puppet:LookupAttachment("camera")
                local attachment = puppet:GetAttachment(attachmentID)

                if IsValid(ragdoll) and IsValid(phys) then
                    phys:SetPos(LerpVector(ratio, phys:GetPos(), attachment.Pos))
                    phys:SetAngles(LerpAngle(ratio, phys:GetAngles(), attachment.Ang))
                end
            end)

            timer.Simple(2.2, function()
                local effectdata = EffectData()
                effectdata:SetOrigin(ragdoll:GetPos())
                effectdata:SetMagnitude(3)
                effectdata:SetScale(15)
                effectdata:SetColor(0)
                effectdata:SetFlags(3)
                util.Effect("bloodspray", effectdata)
            end)

            timer.Simple(2.1, function()
                if IsValid(ragdoll) and IsValid(phys) then
                    timer.Remove("setpos")
                end
            end)

            if entity:IsPlayer() then
                entity:SetNoDraw(true)
                entity:Freeze(true)
                entity:AddFlags(FL_NOTARGET)
                entity:DrawViewModel(false)
                entity:SetActiveWeapon(nil)

                net.Start('OBELISKJUMPCAMEDDY')
                net.WriteEntity(pill)
                net.WriteBool(true)
                net.Send(entity)
            elseif entity:IsNPC() then
                entity:SetNoDraw(true)
                entity:SetNPCState(NPC_STATE_IDLE)
                entity:SetEnemy(nil)
            else
                entity:NextThink(CurTime())
                entity:TakeDamage(1e9, ply)
            end

            entity:SetPos(pill:GetPos() + pill:GetForward() * 50)
            ply:Freeze(true)

            ent:PillAnim('jumpscare')
            ent:PillSound('kill')

            timer.Simple(2.67, function()
                if not (IsValid(entity) and IsValid(ent)) then return end

                ply:Freeze(false)

                if entity:IsPlayer() then
                    entity:Kill(ply)

                    net.Start('OBELISKJUMPCAMEDDY')
                    net.WriteEntity(pill)
                    net.WriteBool(false)
                    net.Send(entity)

                    entity:RemoveFlags(FL_NOTARGET)
                    entity:Freeze(false)
                    entity:DrawViewModel(true)
                else
                    entity:NextThink(CurTime())
                    entity:TakeDamage(1e9, ply)
                end
            end)
        else
        end

        timer.Simple(3, function()
            ply.OnHold = false
        end)

        ent:CallOnRemove("blahblah", function()
        if IsValid(ragdoll) and IsValid(phys) then
           ragdoll:Remove()
        end
    end)

    end
},
	
	attack2={
        mode = "trigger",
        func = function(ply, ent)
        end,
},
    

noragdoll=true,

ObeliskKeybind = function(ply, ent, button)
    local distance = nil
    local distance2 = nil

    if button == KEY_G then
    if cooldowiwishiknew then return end
    if burrowed then return end
    cooldowiwishiknew = true
    rageactive = true

    if SERVER then
    net.Start("ragecooldownobelisk")
    net.Send(ply)
    end

    if not SERVER then return end

    timer.Create("getplayerdistance", 0.1, 0, function()
       for _, v in ipairs(player.GetAll()) do
        if v == ply then continue end
        if v:IsPlayer() and v:Alive() then
        if v:Team() == TEAM_SPECTATOR then continue end
        
        distance = (ply:GetPos() - v:GetPos()):Length()

            print(v)
            net.Start("redvignette")
            net.WriteFloat(distance)
            net.Send(v)
        end
        
    end
end)

timer.Create("senddistance", 0.1, 0, function()
    for _, v in ipairs(player.GetAll()) do
        if v == ply then continue end
        if v:IsPlayer() and v:Alive() then
        if v:Team() == TEAM_SPECTATOR then continue end
        
            distance2 = (ply:GetPos() - v:GetPos()):Length()
            
            net.Start("obeliskscreamingtocliennt")
            net.WriteFloat(distance2)
            net.WriteEntity(ent)
            net.WriteEntity(ply)
            net.Send(v)
        end
        
    end
end)

    pk_pills.setCostumeMoveSpeed(ent, 100, 650)

    timer.Simple(10, function()
    if ent.DontActivateTimer then return end
    if not IsValid(ply) or not IsValid(ent) then return end
    if not SERVER then return end
    rageactive = false

    net.Start("ragecooldown2")
    net.Send(ply)
    print("if u find this here: https://www.youtube.com/shorts/jROmY_0o658")

    timer.Simple(50, function()
        if cooldowiwishiknew then
            cooldowiwishiknew = false
        end
    end)
        
    net.Start("obelisskscreamstop")
    net.Broadcast()

    timer.Remove("getplayerdistance")
    timer.Remove("senddistance")

    net.Start("redvignettestop")
    net.Broadcast()

    pk_pills.setCostumeMoveSpeed(ent, 70, 580)
    end)
end

    ent:CallOnRemove("disableabilityragescream", function()
        if rageactive then
            print("rage deactivated")
            timer.Remove("senddistance")
            timer.Remove("getplayerdistance")
            rageactive = false
            cooldowiwishiknew = true
            net.Start("ragescreamabilitdisableability")
            net.Broadcast()
            net.Start("ragecooldown2")
            net.Send(ply)
            ent.DontActivateTimer = true

            timer.Simple(50, function()
                if cooldowiwishiknew then
                    cooldowiwishiknew = false 
                end
            end)
        end
    end)
end,
	
reload = function(ply, ent)
    if rageactive then return end

    if ply.OnHold then return end

    local pill = ent:GetPuppet()
    if not IsValid(pill) then return end

    local function aftermathorsmth()
        ply:Freeze(true)

        timer.Simple(2, function()
            if IsValid(ply) then
                ply:Freeze(false)
            end
        end)

        ent:CallOnRemove("disableabilitynoclip", function()
            if ent.Burrowed then
                burrowed = false
                pill:SetColor(Color(255, 255, 255, 255))
                net.Start("nonsensenetworkingshit")
                net.Send(ply)
            end
        end)
    end

    if ent.Burrowed then
        if !IsValid(ent) then return end

        local mins, maxs = ply:GetCollisionBounds()

        local tr = util.TraceHull({
            start = ply:GetPos(),
            endpos = ply:GetPos(),
            mins = mins,
            maxs = maxs,
            filter = function(hitEnt)
                if hitEnt == ply then return false end
                if hitEnt == ent then return false end
                if hitEnt == ent:GetPuppet() then return false end
                return true
            end,
            mask = MASK_PLAYERSOLID
        })

        if not tr.Hit then
            burrowed = false

            local pillpuppet = ent:GetPuppet()
            if not IsValid(pillpuppet) then return end

            local effectdata = EffectData()
            effectdata:SetEntity(pillpuppet)
            effectdata:SetOrigin(Vector(0,0,0))

            util.Effect("obelisk_sprite", effectdata, true, true)

            ply.OnHold = true
            pk_pills.setHNSCooldown(ent, "burrow", 10)
            timer.Create("cooldownobelisk" .. ply:SteamID64(), 10, 1, function()
                if IsValid(ply) then
                    ply.OnHold = false
                end
            end)

            net.Start("digcooldown2")
            net.Send(ply)

            local tr = util.TraceLine({
                start = ent:GetPos(),
                endpos = ent:GetPos() + Vector(0,0,-10000),
                filter = {ply, ent}
            })

            if tr.Hit then
                ply:SetPos(tr.HitPos + Vector(0,0,50))
            else
                ply:SetPos(ply:GetPos())
            end

            pill:SetColor(Color(255, 255, 255, 255))
            pill:SetRenderMode(RENDERMODE_NORMAL)
            ent.Burrowed = false

            ply:SetLocalVelocity(Vector(0,0,0))
            ply:SetMoveType(2)
            ply:SetNotSolid(false)

            ent:PillAnim('noclipmerge')
            ent:PillSound("emerge")
            aftermathorsmth()
        end

    else
        if ply:IsOnGround() then
            burrowed = true
            net.Start("digcooldown")
            net.Send(ply)

            ent:PillAnim('noclipenter')
            ent:PillSound("digdown")

            timer.Simple(1, function()
                if not IsValid(pill) or not IsValid(ent) or not IsValid(ply) then return end

                net.Start("spriteimagedisapearnoclip")
                net.Broadcast()

                pill:SetColor(Color(0, 0, 0, 0))
                pill:SetRenderMode(RENDERMODE_TRANSALPHA)
                ent.Burrowed = true
                ply:SetLocalVelocity(Vector(0,0,0))
                ply:SetMoveType(8)
                ply:SetNotSolid(true)
            end)
            aftermathorsmth()
        end
    end
end,

	
    flashlight=function(ply,ent)
    end,
	
    jump=function(ply,ent)
    end
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
        { id = "burrow", name = "Enterrar", key = IN_RELOAD, OnUse = form.reload },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
    pk_pills.bindHNSButtons(form, "ObeliskKeybind", {
        { id = "rage", name = "Fúria", button = KEY_G, keyLabel = "G", cooldown = 60 },
    })
end)