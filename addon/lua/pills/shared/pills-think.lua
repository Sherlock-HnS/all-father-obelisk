/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/

FVJOHNNY_PILLS = FVJOHNNY_PILLS or {}

function FVJOHNNY_PILLS:RegisterPillThink(CFG)
    hook.Add("Think", "FVJOHNNY_PILLS_THINK_" .. CFG.PillName, function()
        if not CFG.Think then return end
        if CLIENT then 
            self:Init(LocalPlayer(), CFG)
            self:Think(LocalPlayer(), CFG)
        end

        if SERVER then
            for _, ply in pairs(player.GetAll()) do
                self:Init(ply, CFG)
                self:Think(ply, CFG)
            end
        end
    end)
end

function FVJOHNNY_PILLS:Think(ply, CFG)
    if not CFG.Think then return end
    if not FVJOHNNY_PILLS:IsPlayerUsingPillName(ply, CFG.PillName) then return end

    CFG.Think(ply, ply.pk_pill_ent)
end

function FVJOHNNY_PILLS:Init(ply, CFG)
    ply.PillThinks = ply.PillThinks or {}

    if not FVJOHNNY_PILLS:IsPlayerUsingPillName(ply, CFG.PillName) then 
        ply.PillThinks[CFG.PillName] = nil
        return
    end

    if not ply.PillThinks[CFG.PillName] then
        CFG.Init(ply, ply.pk_pill_ent)
        ply.PillThinks[CFG.PillName] = true
    end
end