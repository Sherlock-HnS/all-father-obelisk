/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

if SERVER then
    -- Block weapon attacks while invisible
    hook.Add("EntityFireBullets", "FVJOHNNY_PILLS_ALLFATHER_BlockAttack", function(ent, data)
        if not ent:IsPlayer() then return end
        if not FVJOHNNY_PILLS.AllFather:IsInvisible(ent) then return end

        return false -- Block the attack
    end)

    -- Block melee attacks
    hook.Add("PlayerSwitchWeapon", "FVJOHNNY_PILLS_ALLFATHER_BlockWeaponSwitch", function(ply, oldWep, newWep)
        if not FVJOHNNY_PILLS.AllFather:IsInvisible(ply) then return end
        -- Allow weapon switching but attacks are blocked
    end)

    -- Block +attack input
    hook.Add("StartCommand", "FVJOHNNY_PILLS_ALLFATHER_BlockAttackInput", function(ply, cmd)
        if not FVJOHNNY_PILLS.AllFather:IsInvisible(ply) then return end

        -- Remove attack buttons
        if bit.band(cmd:GetButtons(), IN_ATTACK) ~= 0 then
            cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK)))
        end
    end)
end
