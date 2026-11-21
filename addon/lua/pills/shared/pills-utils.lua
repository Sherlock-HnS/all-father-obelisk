/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/

FVJOHNNY_PILLS = FVJOHNNY_PILLS or {}

local ply = player.GetAll()[1]

function FVJOHNNY_PILLS:EmitSound(ent, snd, isLooping, soundDelay)
    if not snd then return end

    local soundLoopTimer = "FVJOHNNY_PILLS_SOUND_LOOP_"..ent:EntIndex()
    local timerExists = timer.Exists(soundLoopTimer)
    if isLooping and timerExists then return end

    if istable(snd) then
        snd = table.Random(snd)
    end

    timer.Simple(soundDelay or 0, function()
        ent:EmitSound(snd)
        if isLooping then
            local soundDuration = SoundDuration(snd)
            local soundLoopTimer = "FVJOHNNY_PILLS_SOUND_LOOP_"..ent:EntIndex()
            timer.Create(soundLoopTimer, soundDuration, 0, function()
                if !IsValid(ent) then return end
                ent:EmitSound(snd)
            end)
        end
    end)
end

function FVJOHNNY_PILLS:StopSound(ent, snd)
    if istable(snd) then
        for _, s in pairs(snd) do
            ent:StopSound(s)
        end
    else
        ent:StopSound(snd)
    end

    local soundLoopTimer = "FVJOHNNY_PILLS_SOUND_LOOP_"..ent:EntIndex()
    timer.Remove(soundLoopTimer)
end



function FVJOHNNY_PILLS:IsPlayerUsingPillName(ply, pillName)
    return IsValid(ply.pk_pill_ent) and ply.pk_pill_ent.formTable and ply.pk_pill_ent.formTable.name and ply.pk_pill_ent.formTable.name == pillName
end
function FVJOHNNY_PILLS:IsPlayerUsingPill(ply)
    return IsValid(ply.pk_pill_ent)
end

function FVJOHNNY_PILLS:GetPuppetOwner(ent)
    if not IsValid(ent) then return nil end
    if ent:GetClass() ~= "pill_puppet" then return nil end

    for k,v in pairs(player.GetAll()) do
        if IsValid(v.pk_pill_ent) and v.pk_pill_ent:GetPuppet() == ent then
            return v
        end
    end
    return nil
end

function FVJOHNNY_PILLS:GetPuppet(ply)
    if not IsValid(ply) then return nil end
    if not ply:IsPlayer() then return nil end
    if not IsValid(ply.pk_pill_ent) or not IsValid(ply.pk_pill_ent:GetPuppet()) then return nil end
    return ply.pk_pill_ent:GetPuppet()
end

function FVJOHNNY_PILLS:PrintPillSequences(ply)
    if not IsValid(ply) then return end
    if not ply:IsPlayer() then return end
    
    local puppet = self:GetPuppet(ply)
    if not IsValid(puppet) then return end

    PrintTable(puppet:GetSequenceList())
end

function FVJOHNNY_PILLS:GetPlayerAimedAt(ply)
    if not IsValid(ply) then return nil end
    if not ply:IsPlayer() then return nil end

    local startPos = ply.JohnnyPillViewOrigin or ply:EyePos()
    local aimDir = (ply.JohnnyPillViewAngles or ply:EyeAngles()):Forward()

    local trace = util.TraceLine({
        start = startPos,
        endpos = startPos + (aimDir * 32768),
        filter = ply,
        mask = MASK_SHOT
    })

    -- Check if we hit a player or NPC
    if IsValid(trace.Entity) then
        if (trace.Entity:IsPlayer() or trace.Entity:IsNPC()) and trace.Entity:Health() > 0 then
            return trace.Entity
        end
    end
    return nil
end

function FVJOHNNY_PILLS:ReplaceCalcView()
    local calcViewHooks = hook.GetTable()["CalcView"]
    local pillsHook = calcViewHooks["momo_calcview"]

    if not pillsHook then
        timer.Simple(1, function()
            FVJOHNNY_PILLS:ReplaceCalcView()
        end)
        return
    end

    local newHook = function(ply, pos, ang, fov, nearZ, farZ)
        local view = pillsHook(ply, pos, ang, fov, nearZ, farZ)
        if not view then return end
        LocalPlayer().JohnnyPillViewOrigin = view.origin
        LocalPlayer().JohnnyPillViewAngles = view.angles
        return view
    end

    hook.Remove("CalcView", "momo_calcview")
    hook.Add("CalcView", "momo_calcview", newHook)
end

FVJOHNNY_PILLS:ReplaceCalcView()