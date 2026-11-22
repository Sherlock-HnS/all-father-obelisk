/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/

FVJOHNNY_PILLS = FVJOHNNY_PILLS or {}

local BUTTONS_TO_CHECK = {
    LeftClick = IN_ATTACK,
    RightClick = IN_ATTACK2,
    Reload = IN_RELOAD,
    Flashlight = IN_FLASHLIGHT,
    Jump = IN_JUMP,
}
function FVJOHNNY_PILLS:GetAllButtons()
    return BUTTONS_TO_CHECK
end

function FVJOHNNY_PILLS:RegisterPillsButtonPress(CFG)
    hook.Add("Think","FVJOHNNY_PILLS_BUTTON_RELEASE_" .. CFG.PillName,function()
        for _, ply in ipairs(player.GetAll()) do
            if not FVJOHNNY_PILLS:IsPlayerUsingPillName(ply, CFG.PillName) then continue end
            for button, key in pairs(BUTTONS_TO_CHECK) do
                if FVJOHNNY_PILLS:WasButtonPreviouslyPressed(ply, button) and not ply:KeyDown(key) then
                    FVJOHNNY_PILLS:ReleaseButton(ply, ply.pk_pill_ent, button, CFG)
                end
            end
        end
    end)
end

function FVJOHNNY_PILLS:WasButtonPreviouslyPressed(ply, button)
    return ply.FVJOHNNY_PILLS_BUTTON_PRESSED and ply.FVJOHNNY_PILLS_BUTTON_PRESSED[button]
end

function FVJOHNNY_PILLS:ReleaseButton(ply, ent, button, CFG)
    CFG[button].onRelease(ply, ent)
    ply.FVJOHNNY_PILLS_BUTTON_PRESSED[button] = false
end


function FVJOHNNY_PILLS:PressButton(ply, ent, button, CFG)

    local nextAllowedTime = self:GetNextAllowedTime(ply, button)
    if CurTime() < nextAllowedTime then
        ply:ChatPrint("You must wait " .. math.ceil(nextAllowedTime - CurTime()) .. " seconds before you can use this again.")
        return false
    end

    local success = CFG[button].onPress(ply, ent)
    if success then
        -- Handle animation
        if CFG[button].anim then
            ent:PillAnim(CFG[button].anim.sequence, false, CFG[button].anim.speed)
        end
        -- Handle sound
        if CFG[button].sound then
            self:EmitSound(ent, CFG[button].sound.name, false, CFG[button].sound.delay)
        end
    else
        -- Handle fail animation
        if CFG[button].failAnim then
            ent:PillAnim(CFG[button].failAnim.sequence, false, CFG[button].failAnim.speed)
        end
        -- Handle fail sound
        if CFG[button].failSound then
            self:EmitSound(ent, CFG[button].failSound.name, false, CFG[button].failSound.delay)
        end
    end

    self:SetNextAllowedTime(ply, button, CFG)
end

function FVJOHNNY_PILLS:GetNextAllowedTime(ply, button)
    return ply:GetNWFloat("FVJOHNNY_PILLS_BUTTON_NEXT_ALLOWED_TIME_" .. button, 0)
end

function FVJOHNNY_PILLS:GetLastPressedTime(ply, button)
    return ply:GetNWFloat("FVJOHNNY_PILLS_BUTTON_LAST_PRESSED_TIME_" .. button, 0)
end

function FVJOHNNY_PILLS:SetNextAllowedTime(ply, button, CFG, customCooldown)
    if not ply.FVJOHNNY_PILLS_BUTTON_PRESSED then ply.FVJOHNNY_PILLS_BUTTON_PRESSED = {} end
    
    ply.FVJOHNNY_PILLS_BUTTON_PRESSED[button] = true

    local cooldown = customCooldown or CFG[button].cooldown or 0
    if SherlockHNS then
        local id = ({ LeftClick = "attack", RightClick = "mark", Reload = "invisible" })[button]
        if id and cooldown > 0 then SherlockHNS.Ability.SetCooldown(ply, id, cooldown) end
        return
    end
    if cooldown <= 0 then return end

    ply:SetNWFloat("FVJOHNNY_PILLS_BUTTON_NEXT_ALLOWED_TIME_" .. button, CurTime() + cooldown)
    ply:SetNWFloat("FVJOHNNY_PILLS_BUTTON_LAST_PRESSED_TIME_" .. button, CurTime())
end