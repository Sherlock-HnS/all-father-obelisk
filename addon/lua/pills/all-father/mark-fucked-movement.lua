/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
if not CLIENT then return end

FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

-- Scramble movement controls for marked players
FVJOHNNY_PILLS.AllFather.ScrambledControls = {}
FVJOHNNY_PILLS.AllFather.LastKeyStates = {}

hook.Add("CreateMove", "FVJOHNNY_PILLS_ScrambleMarkedControls", function(cmd)
    local localPly = LocalPlayer()
    if not IsValid(localPly) then return end

    -- Check if we are marked
    if not FVJOHNNY_PILLS.AllFather:IsMarked(localPly) then
        -- Clear scrambled controls if not marked
        FVJOHNNY_PILLS.AllFather.ScrambledControls = {}
        FVJOHNNY_PILLS.AllFather.LastKeyStates = {}
        return
    end

    -- Define the movement keys
    local keys = {
        {key = IN_FORWARD, name = "forward"},
        {key = IN_BACK, name = "back"},
        {key = IN_MOVELEFT, name = "left"},
        {key = IN_MOVERIGHT, name = "right"}
    }

    -- Swap sprint (shift) and duck (ctrl)
    local buttons = cmd:GetButtons()
    local hasSpeed = bit.band(buttons, IN_SPEED) ~= 0  -- Shift/Walk
    local hasDuck = bit.band(buttons, IN_DUCK) ~= 0    -- Ctrl/Duck

    if hasSpeed then
        buttons = bit.band(buttons, bit.bnot(IN_SPEED))  -- Remove shift
        buttons = bit.bor(buttons, IN_DUCK)              -- Add ctrl
    end

    if hasDuck then
        buttons = bit.band(buttons, bit.bnot(IN_DUCK))   -- Remove ctrl
        buttons = bit.bor(buttons, IN_SPEED)             -- Add shift
    end

    cmd:SetButtons(buttons)

    -- Get current button state
    local buttons = cmd:GetButtons()

    -- Check each key and re-randomize if just pressed
    for _, keyData in ipairs(keys) do
        local isPressed = bit.band(buttons, keyData.key) ~= 0
        local wasPressed = FVJOHNNY_PILLS.AllFather.LastKeyStates[keyData.name]

        -- If key was just pressed (transition from not pressed to pressed)
        if isPressed and not wasPressed then
            -- Create a list of possible remappings (exclude the original key)
            local possibleMappings = {}
            for _, otherKey in ipairs(keys) do
                if otherKey.key ~= keyData.key then
                    table.insert(possibleMappings, otherKey.key)
                end
            end

            -- Randomly select a new mapping
            FVJOHNNY_PILLS.AllFather.ScrambledControls[keyData.key] = possibleMappings[math.random(#possibleMappings)]
        end

        FVJOHNNY_PILLS.AllFather.LastKeyStates[keyData.name] = isPressed
    end

    -- Store original movement values
    local originalForwardMove = cmd:GetForwardMove()
    local originalSideMove = cmd:GetSideMove()

    -- Calculate new movement based on scrambled controls
    local newForwardMove = 0
    local newSideMove = 0

    local maxMove = 10000 -- GMod's max movement speed value

    for _, keyData in ipairs(keys) do
        if bit.band(buttons, keyData.key) ~= 0 then
            local mappedKey = FVJOHNNY_PILLS.AllFather.ScrambledControls[keyData.key] or keyData.key

            if mappedKey == IN_FORWARD then
                newForwardMove = maxMove
            elseif mappedKey == IN_BACK then
                newForwardMove = -maxMove
            elseif mappedKey == IN_MOVELEFT then
                newSideMove = -maxMove
            elseif mappedKey == IN_MOVERIGHT then
                newSideMove = maxMove
            end
        end
    end

    -- Apply the new movement
    cmd:SetForwardMove(newForwardMove)
    cmd:SetSideMove(newSideMove)
end)

