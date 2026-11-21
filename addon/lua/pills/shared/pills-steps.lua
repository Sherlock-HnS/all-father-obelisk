/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/

FVJOHNNY_PILLS = FVJOHNNY_PILLS or {}

function FVJOHNNY_PILLS:RegisterPillSteps(CFG)

    hook.Add( "PlayerFootstep", "FVJOHNNY_PILLS_MUTE_STEPS_" .. CFG.PillName, function( ply, pos, foot, sound, volume, rf )
        if FVJOHNNY_PILLS:IsPlayerUsingPillName(ply, CFG.PillName) and CFG.StepSounds then
            // FVJOHNNY_PILLS:EmitSound(ply.pk_pill_ent, CFG.StepSounds.walk)
            return true
        end
    end )

    hook.Add("Think", "FVJOHNNY_PILLS_STEPS_" .. CFG.PillName, function()
        if not SERVER then return end
        for _, ply in ipairs(player.GetAll()) do
            if not FVJOHNNY_PILLS:IsPlayerUsingPillName(ply, CFG.PillName) then continue end
            if ply:GetMoveType() == MOVETYPE_NOCLIP then continue end
            if not ply:OnGround() then continue end

            ply.LastFootstepPos = ply.LastFootstepPos or ply:GetPos()
            ply.LastFootstepTime = ply.LastFootstepTime or 0
            
            local dist = ply:GetPos():Distance(ply.LastFootstepPos)
            local timeSince = CurTime() - ply.LastFootstepTime
            if timeSince < 0.1 then continue end

            local walkSpeed = CFG.MoveSpeed.walk or ply:GetWalkSpeed()
            local runSpeed = CFG.MoveSpeed.run or ply:GetRunSpeed()
            
            local isRunning = ply:GetVelocity():Length() > runSpeed*0.8
            local isWalking = ply:GetVelocity():Length() > walkSpeed*0.8
            if not isRunning then
                FVJOHNNY_PILLS:StopSound(ply.pk_pill_ent, CFG.StepSounds.run.sounds)
            end
            if not isWalking then
                FVJOHNNY_PILLS:StopSound(ply.pk_pill_ent, CFG.StepSounds.walk.sounds)
            end

            if not isRunning and not isWalking then continue end

            if isWalking and dist < CFG.StepSounds.walk.distance then continue end
            if isRunning and dist < CFG.StepSounds.run.distance then continue end

            local soundTable = isRunning and CFG.StepSounds.run or CFG.StepSounds.walk
            FVJOHNNY_PILLS:EmitSound(ply.pk_pill_ent, soundTable.sounds, soundTable.isLoop)
            ply.LastFootstepPos = ply:GetPos()
            ply.LastFootstepTime = CurTime()
        end
    end)
end

