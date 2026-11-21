/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

if SERVER then
    local PeekCfg = FVJOHNNY_PILLS.AllFather.CFG.Peek

    util.AddNetworkString("FVJOHNNY_PILLS_PEEK_IMAGE")
    // Show a peeking image of all-father to the player
    function FVJOHNNY_PILLS.AllFather:PeekImage(allFatherPly, victimPly, fuckedVision)
        if not IsValid(victimPly) then return end
        if not victimPly:IsPlayer() then return end

        net.Start("FVJOHNNY_PILLS_PEEK_IMAGE")
        net.WriteBool(fuckedVision)
        net.Send(victimPly)
    end

    function FVJOHNNY_PILLS.AllFather:PeekRandomPlayers(allFatherPly)
        if not FVJOHNNY_PILLS:IsPlayerUsingPillName(allFatherPly, self.CFG.PillName) then return end
        
        for k,v in pairs(player.GetAll()) do
            if not IsValid(v) then continue end
            if not v:IsPlayer() then continue end
            if not v:Alive() then continue end
            if self:IsMarked(v) then continue end
            if not PeekCfg.showToMyself and v == allFatherPly then continue end
            if FVJOHNNY_PILLS:IsPlayerUsingPill(v) then continue end
            if v:GetPos():Distance(allFatherPly:GetPos()) < PeekCfg.distance then continue end
            if math.random(1, 100) > PeekCfg.chance then continue end

            self:PeekImage(allFatherPly, v, false)
        end
    end

    timer.Create("FVJOHNNY_PILLS_PEEK_IMAGE_TIMER", PeekCfg.interval, 0, function()
        for k,v in pairs(player.GetAll()) do
            FVJOHNNY_PILLS.AllFather:PeekRandomPlayers(v)
        end
    end)
end

if CLIENT then
    net.Receive("FVJOHNNY_PILLS_PEEK_IMAGE", function()
        local fuckedVision = net.ReadBool()

        FVJOHNNY_PILLS.AllFather:ShowPeekImage(fuckedVision)
    end)

    function FVJOHNNY_PILLS.AllFather:ShowPeekImage(fuckedVision)
        if FVJOHNNY_PILLS.AllFather.peekImage then
            FVJOHNNY_PILLS.AllFather.peekImage:Remove()
        end
        if FVJOHNNY_PILLS.AllFather.textLabel then
            FVJOHNNY_PILLS.AllFather.textLabel:Remove()
        end

        local PeekCfg = FVJOHNNY_PILLS.AllFather.CFG.Peek
        local scrW, scrH = ScrW(), ScrH()

        -- Random edge: 1=top, 2=right, 3=bottom, 4=left
        local edge = math.random(1, 4)

        -- Random chance to be half visible (50% chance)
        local halfVisible = math.random(1, 2) == 1

        local imgX, imgY = 0, 0
        local textX, textY = 0, 0
        local textAlign = 5 -- Center by default

        if edge == 1 then -- Top
            imgX = math.random(50, scrW - PeekCfg.size.w - 50)
            if halfVisible then
                imgY = -(PeekCfg.size.h / 2)
                textY = PeekCfg.size.h / 2 + 10
            else
                imgY = 0
                textY = PeekCfg.size.h + 10
            end
            textX = imgX + (PeekCfg.size.w / 2)
        elseif edge == 2 then -- Right
            if halfVisible then
                imgX = scrW - (PeekCfg.size.w / 2)
                textX = scrW - 10
                textAlign = 6 -- Right-aligned
            else
                imgX = scrW - PeekCfg.size.w
                textX = scrW - 10
                textAlign = 6 -- Right-aligned
            end
            imgY = math.random(50, scrH - PeekCfg.size.h - 50)
            textY = imgY + PeekCfg.size.h + 10
        elseif edge == 3 then -- Bottom
            imgX = math.random(50, scrW - PeekCfg.size.w - 50)
            if halfVisible then
                imgY = scrH - (PeekCfg.size.h / 2)
                textY = scrH - (PeekCfg.size.h / 2) - 30
            else
                imgY = scrH - PeekCfg.size.h
                textY = scrH - PeekCfg.size.h - 30
            end
            textX = imgX + (PeekCfg.size.w / 2)
        else -- Left (edge == 4)
            if halfVisible then
                imgX = -(PeekCfg.size.w / 2)
                textX = (PeekCfg.size.w / 2) + 20
                textAlign = 4 -- Left-aligned
            else
                imgX = 0
                textX = 20
                textAlign = 4 -- Left-aligned
            end
            imgY = math.random(50, scrH - PeekCfg.size.h - 50)
            textY = imgY + PeekCfg.size.h + 10
        end

        -- Create and position image
        local image = vgui.Create("DImage")
        FVJOHNNY_PILLS.AllFather.peekImage = image
        image:SetSize(PeekCfg.size.w, PeekCfg.size.h)
        image:SetPos(imgX, imgY)
        image:SetImage(PeekCfg.image)
        image:SetAlpha(255)
        image:SetVisible(true)
        image:SetMouseInputEnabled(false)
        image:SetKeyboardInputEnabled(false)

        -- Create text label with random message
        local randomText = PeekCfg.texts[math.random(1, #PeekCfg.texts)]
        if fuckedVision then
            randomText = PeekCfg.fuckedVisionTexts[math.random(1, #PeekCfg.fuckedVisionTexts)]
        end

        local textLabel = vgui.Create("DLabel")
        FVJOHNNY_PILLS.AllFather.textLabel = textLabel
        textLabel:SetText(randomText)
        textLabel:SetFont(PeekCfg.textFont)
        textLabel:SetTextColor(PeekCfg.textColor)
        textLabel:SetContentAlignment(textAlign)
        textLabel:SizeToContents()

        -- Adjust text position to be centered for the alignment
        if textAlign == 6 then -- Right-aligned
            textLabel:SetPos(textX - textLabel:GetWide(), textY)
        elseif textAlign == 4 then -- Left-aligned
            textLabel:SetPos(textX, textY)
        else -- Center-aligned
            textLabel:SetPos(textX - (textLabel:GetWide() / 2), textY)
        end

        textLabel:SetVisible(true)

        timer.Create("FVJOHNNY_PILLS_PEEK_IMAGE_TIMER", PeekCfg.lastsFor, 1, function()
            image:Remove()
            textLabel:Remove()
        end)
    end
end
