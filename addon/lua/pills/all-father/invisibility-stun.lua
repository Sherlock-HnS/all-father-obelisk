/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

function FVJOHNNY_PILLS.AllFather:IsStunned(ply)
    local stunEnd = ply:GetNWFloat("AllFatherStunEndTime", 0)
    return CurTime() < stunEnd
end

if SERVER then
    function FVJOHNNY_PILLS.AllFather:StunNearbyPlayers(allFatherPly)
        local ReloadCfg = FVJOHNNY_PILLS.AllFather.CFG.Reload
        local stunPos = allFatherPly:GetPos()
        local nearbyPlayers = ents.FindInSphere(stunPos, ReloadCfg.stunRadius)

        for _, ent in ipairs(nearbyPlayers) do
            if ent:IsPlayer() and ent ~= allFatherPly and ent:Health() > 0 then
                -- Mark player as stunned
                ent:SetNWFloat("AllFatherStunEndTime", CurTime() + ReloadCfg.stunDuration)
                ent:ChatPrint("You have been stunned by the All-Father!")
                allFatherPly:ChatPrint("You have stunned " .. ent:Nick() .. "!")
            end
        end
    end

    -- Handle stun (reduced movement speed)
    hook.Add("SetupMove", "FVJOHNNY_PILLS_ALLFATHER_StunMovement", function(ply, mv, cmd)
        if FVJOHNNY_PILLS.AllFather:IsStunned(ply) then
            
            local ReloadCfg = FVJOHNNY_PILLS.AllFather.CFG.Reload
            local mult = ReloadCfg.stunMoveSpeedMultiplier or 0.3

            mv:SetMaxSpeed(mv:GetMaxSpeed() * mult)
            mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * mult)
        end
    end)
end
