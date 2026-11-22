/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}


function FVJOHNNY_PILLS.AllFather:StartSpectreVision(allFatherPly)
    if not SERVER then return end
    if self:IsSpectreVisionActive(allFatherPly) then return end

    local RightClickCfg = FVJOHNNY_PILLS.AllFather.CFG.RightClick

    allFatherPly:SetNWBool("SpectreVisionActive", true)
    FVJOHNNY_PILLS:EmitSound(allFatherPly, RightClickCfg.soundWhileUsingRightClick, true)

    return true
end

function FVJOHNNY_PILLS.AllFather:StopSpectreVision(allFatherPly)
    if not SERVER then return end

    if not self:IsSpectreVisionActive(allFatherPly) then return end

    local RightClickCfg = FVJOHNNY_PILLS.AllFather.CFG.RightClick
    allFatherPly:SetNWBool("SpectreVisionActive", false)
    allFatherPly:SendLua("FVJOHNNY_PILLS.AllFather:ResetMarkPercentages()")
    FVJOHNNY_PILLS:StopSound(allFatherPly, RightClickCfg.soundWhileUsingRightClick)

    return true
end



function FVJOHNNY_PILLS.AllFather:IsSpectreVisionActive(ply)
    return ply:GetNWBool("SpectreVisionActive")
end

function FVJOHNNY_PILLS.AllFather:IsMarkedBy(victimPly, allFatherPly)
    local markAllFather = self:GetMarkAllFather(victimPly)
    return IsValid(markAllFather) and markAllFather == allFatherPly
end

function FVJOHNNY_PILLS.AllFather:GetMarkAllFather(victimPly)
    if not IsValid(victimPly) then return end
    return victimPly:GetNWEntity("IsMarkedAllFatherBy")
end

function FVJOHNNY_PILLS.AllFather:SetMarkAllFather(victimPly, allFatherPly)
    if not IsValid(victimPly) then return end
    victimPly:SetNWEntity("IsMarkedAllFatherBy", allFatherPly)
end

function FVJOHNNY_PILLS.AllFather:IsMarked(ent)
    if not IsValid(ent) then return false end
    
    return IsValid(self:GetMarkAllFather(ent))
end

if SERVER then
    util.AddNetworkString("FVJOHNNY_PILLS_ALLFATHER_MARK_PLAYER")
    net.Receive("FVJOHNNY_PILLS_ALLFATHER_MARK_PLAYER", function(len, allFatherPly)
        local targetPly = net.ReadEntity()
        FVJOHNNY_PILLS.AllFather:MarkPlayer(targetPly, allFatherPly)
    end)

    hook.Add("Initialize", "AllFatherHNSMark", function()
        if not SherlockHNS then return end
        SherlockHNS.RegisterEffect("allfather_mark", {
            OnEnd = function(target) FVJOHNNY_PILLS.AllFather:SetMarkAllFather(target, NULL) end,
        })
    end)
    function FVJOHNNY_PILLS.AllFather:MarkPlayer(targetPly, allFatherPly)
        if not IsValid(allFatherPly) then return end
        if not self:IsSpectreVisionActive(allFatherPly) then return end
        if not IsValid(targetPly) then return end
        if not (targetPly:IsPlayer() or targetPly:IsNPC()) then return end
        if self:IsMarked(targetPly) then return end
        if targetPly == allFatherPly then return end
        if targetPly:Health() <= 0 then return end

        local RightClickCfg = FVJOHNNY_PILLS.AllFather.CFG.RightClick

        if SherlockHNS and targetPly:IsPlayer() and not SherlockHNS.ApplyEffect(targetPly, "allfather_mark", 15, allFatherPly) then return end

        -- Mark the player
        self:SetMarkAllFather(targetPly, allFatherPly)
        local targetName = targetPly:IsPlayer() and targetPly:Nick() or targetPly:GetClass()
        allFatherPly:ChatPrint("You have marked " .. targetName .. " for " .. 15 .. " seconds.")

        -- Play sounds
        FVJOHNNY_PILLS:EmitSound(targetPly, RightClickCfg.soundOnFuckedUpPlayer)
        FVJOHNNY_PILLS:EmitSound(allFatherPly, RightClickCfg.soundOnMarking)

        -- Set cooldown after marking
        FVJOHNNY_PILLS:SetNextAllowedTime(allFatherPly, "RightClick", self.CFG, RightClickCfg.cooldownAfterMarking)

        -- Stop spectre vision
        self:StopSpectreVision(allFatherPly)

        -- Remove mark after duration
        timer.Simple(15, function()
            if not IsValid(targetPly) then return end
            if not FVJOHNNY_PILLS.AllFather:IsMarkedBy(targetPly, allFatherPly) then return end

            self:SetMarkAllFather(targetPly, NULL)
            allFatherPly:ChatPrint("The mark on " .. targetName .. " has worn off.")
        end)

        -- Show peek image
        self:PeekImage(allFatherPly, targetPly, true)
    end
end

if CLIENT then

    function FVJOHNNY_PILLS.AllFather:GetMarkPercentage(ply)
        local puppetOwner = FVJOHNNY_PILLS:GetPuppetOwner(ply)
        if IsValid(puppetOwner) then
            return self:GetMarkPercentage(puppetOwner)
        end

        return FVJOHNNY_PILLS.AllFather.MarkPercentages and FVJOHNNY_PILLS.AllFather.MarkPercentages[ply:EntIndex()] or 0
    end

    function FVJOHNNY_PILLS.AllFather:SetMarkPercentage(victimPly, percentage)
        FVJOHNNY_PILLS.AllFather.MarkPercentages = FVJOHNNY_PILLS.AllFather.MarkPercentages or {}

        local oldPercentage = FVJOHNNY_PILLS.AllFather.MarkPercentages[victimPly:EntIndex()] or 0
        FVJOHNNY_PILLS.AllFather.MarkPercentages[victimPly:EntIndex()] = percentage

        -- If we just reached 100%, send net message to server
        if oldPercentage < 100 and percentage >= 100 then
            net.Start("FVJOHNNY_PILLS_ALLFATHER_MARK_PLAYER")
            net.WriteEntity(victimPly)
            net.SendToServer()

            timer.Simple(1, function()
                FVJOHNNY_PILLS.AllFather:ResetMarkPercentages()
            end)
        end
    end

    function FVJOHNNY_PILLS.AllFather:ResetMarkPercentage(victimPly)
        if not FVJOHNNY_PILLS.AllFather.MarkPercentages then return end
        FVJOHNNY_PILLS.AllFather.MarkPercentages[victimPly:EntIndex()] = 0
    end
    function FVJOHNNY_PILLS.AllFather:ResetMarkPercentages()
        if not FVJOHNNY_PILLS.AllFather.MarkPercentages then return end
        FVJOHNNY_PILLS.AllFather.MarkPercentages = {}
    end
    function FVJOHNNY_PILLS.AllFather:IncrementMarkPercentage(victimPly)
        if not IsValid(victimPly) then return end

        local RightClickCfg = FVJOHNNY_PILLS.AllFather.CFG.RightClick

        local incrementPerFrame = (100 / RightClickCfg.markAimTimeRequired) * FrameTime()
        local currentPercentage = self:GetMarkPercentage(victimPly)
        local newPercentage = math.Clamp(currentPercentage + incrementPerFrame, 0, 100)

        self:SetMarkPercentage(victimPly, newPercentage)
    end

    function FVJOHNNY_PILLS.AllFather:MarkPlayerThink()
        local localPly = LocalPlayer()
        if not IsValid(localPly) then return end
        if not FVJOHNNY_PILLS.AllFather:IsSpectreVisionActive(localPly) then return end

        local targetPly = FVJOHNNY_PILLS:GetPlayerAimedAt(localPly, FVJOHNNY_PILLS.AllFather.CFG)

        -- Increment mark percentage of the player we're aiming at
        self:IncrementMarkPercentage(targetPly)

        -- Reset mark percentages of all players that are not the target player
        for _, ply in ipairs(ents.GetAll()) do
            if ply == localPly then continue end
            if ply == targetPly then continue end
            if not (ply:IsPlayer() or ply:IsNPC()) then continue end

            self:ResetMarkPercentage(ply)
        end
    end
end
