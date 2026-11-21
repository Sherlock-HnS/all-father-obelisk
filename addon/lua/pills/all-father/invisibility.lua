/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

function FVJOHNNY_PILLS.AllFather:IsInvisible(ply)
    return ply:GetNWBool("AllFatherInvisible", false)
end

if SERVER then
    function FVJOHNNY_PILLS.AllFather:ToggleInvisibility(allFatherPly)
        if not IsValid(allFatherPly) then return false end

        local ReloadCfg = FVJOHNNY_PILLS.AllFather.CFG.Reload
        local isInvisible = self:IsInvisible(allFatherPly)

        if not isInvisible then
            -- Becoming invisible
            allFatherPly:SetNWBool("AllFatherInvisible", true)
            allFatherPly:EmitSound(ReloadCfg.soundOnEnteringInvisibility)
            local puppet = FVJOHNNY_PILLS:GetPuppet(allFatherPly)
            if IsValid(puppet) then
                puppet:SetNWBool("AllFatherInvisible", true)
            end
            return true
        else
            -- Becoming visible
            allFatherPly:SetNWBool("AllFatherInvisible", false)
            allFatherPly:EmitSound(ReloadCfg.soundOnExitingInvisibility)
            local puppet = FVJOHNNY_PILLS:GetPuppet(allFatherPly)
            if IsValid(puppet) then
                puppet:SetNWBool("AllFatherInvisible", false)
            end

            -- Stun nearby players
            self:StunNearbyPlayers(allFatherPly)

            -- Set cooldown using the built-in system
            FVJOHNNY_PILLS:SetNextAllowedTime(allFatherPly, "Reload", self.CFG, ReloadCfg.cooldownWhenBecomingVisible)
            return true
        end
    end
end
