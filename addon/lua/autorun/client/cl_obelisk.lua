local activateagfddfghdfgh = false
local paint = false
local pos = nil
local players = {}
local duration = CurTime() + 3
local mat = Material("obeliskpng/face_d.png")
local mat2 = Material("obeliskpng/redvignette.png")
local transparency = nil
local maxdist = 800
local mindist = 150
local cooldown1 = false
local cooldown2 = false

local timerstart = CurTime()
local timerstart2 = CurTime()
local timerDuration = 50
local timerDuration2 = 10
local r, g, b = 255,255,255
local r2, g2, b2 = 255,255,255
local targetpos = Vector(0,0,0)
local currentpos = Vector(0,0,0)
local eyeangles = Angle(0,0,0)
local boneangleobelisk = Angle(0,0,0)

local mat1abil = Material("obeliskpng/obelisk_icon_rage.png")
local mat2abil = Material("obeliskpng/obelisk_icon_dig.png")

local distance2 = nil

local activatesound = false
local currentScreamMode = nil


    surface.CreateFont("CooldownFont", {
        font = "Arial",      
        size = 48,            
        weight = 800,       
        antialias = true,     
        outline = true,      
    })

        surface.CreateFont("Abilitylabel", {
        font = "Arial",      
        size = 40,            
        weight = 800,       
        antialias = true,     
        outline = true,      
    })


hook.Add("PlayerButtonDown", "jump", function(ply, button)
    if button == KEY_SPACE then
    net.Start("recivejumpplayer")
    net.WriteEntity(ply)
    net.SendToServer()
    print("jump")
    end
end)

hook.Add("PlayerButtonDown", "shift", function(ply, button)
    if button == KEY_LSHIFT then
    net.Start("reciveshiftplayer")
    net.WriteEntity(ply)
    net.SendToServer()
    print("shift")
    end
end)

local maxdist = 1200
local mindist = 200

local vignetteAlpha = 0
local vignetteTarget = 0

local activatetimerthingidk = false

net.Receive("redvignette", function()
    local distance = net.ReadFloat()

    distance = math.Clamp(distance, mindist, maxdist)
    vignetteTarget = math.Remap(distance, mindist, maxdist, 255, 0)

    activatetimerthingidk = true
end)

if activatetimerthingidk then
    timer.Simple(10, function()
        activatetimerthingidk = false
        vignetteAlpha = 0
        vignetteTarget = 0
    end)
end


hook.Add("HUDPaint", "redeffect", function()
    vignetteAlpha = Lerp(FrameTime() * 6, vignetteAlpha, vignetteTarget)

    if vignetteAlpha < 1 then return end

    surface.SetDrawColor(255, 255, 255, vignetteAlpha)
    surface.SetMaterial(mat2)
    surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
end)


net.Receive("redvignettestop", function()
    vignetteAlpha = 0
    vignetteTarget = 0
end)


local xtimer = ScrW() - 150
local ytimer = ScrH() - 153

local xtimer2 = ScrW() - 477
local ytimer2 = ScrH() - 153

hook.Add("HUDPaint", "abiliconsobelisk", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local pill = pk_pills.getMappedEnt(ply)
    if not IsValid(pill) or pill:GetPillForm() ~= "pill_obelisk" then return end

    local w, h = 300, 300

    local x = ScrW() - 270
    local y = ScrH() - 275

    local x2 = ScrW() - 600
    local y2 = y

    surface.SetDrawColor(r, g, b)
    surface.SetMaterial(mat1abil)
    surface.DrawTexturedRect(x, y, w, h)
    draw.SimpleText("G", "Abilitylabel", ScrW() - 250, ScrH() - 240)
    

    surface.SetDrawColor(r2, g2, b2)
    surface.SetMaterial(mat2abil)
    surface.DrawTexturedRect(x2, y2, w, h)
    draw.SimpleText("R", "Abilitylabel", ScrW() - 550, ScrH() - 240)

    if cooldown1 then
        local elapsed = CurTime() - timerstart
        local remaining = math.max(timerDuration - elapsed, 0)
        local seconds = math.ceil(remaining)

        local secondsStr = tostring(seconds)
        local offset = (seconds < 10) and 12 or 0

        surface.SetFont("CooldownFont")
        surface.SetTextColor(255,255,255)
        surface.SetTextPos(xtimer + offset, ytimer)
        surface.DrawText(secondsStr)

        if remaining <= 0 then
            r, g, b = 255, 255, 255
            cooldown1 = false
        end
    end

    if cooldown2 then
        local elapsed2 = CurTime() - timerstart2
        local remaining2 = math.max(timerDuration2 - elapsed2, 0)
        local seconds2 = math.ceil(remaining2)

        local secondsStr2 = tostring(seconds2)
        local offset2 = (seconds2 < 10) and 12 or 0

        surface.SetFont("CooldownFont")
        surface.SetTextColor(255,255,255)
        surface.SetTextPos(xtimer2 + offset2, ytimer2)
        surface.DrawText(secondsStr2)

        if remaining2 <= 0 then
            r2, g2, b2 = 255, 255, 255
            cooldown2 = false
        end
    end
end)


net.Receive("digcooldown", function()
    r2 = 50
    g2 = 50
    b2 = 50
end)

net.Receive("digcooldown2", function()
    timerDuration2 = 10
    timerstart2 = CurTime()
    cooldown2 = true
end)

net.Receive("ragecooldownobelisk", function()
    r = 50
    g = 50
    b = 50
end)

net.Receive("ragecooldown2", function()
    timerDuration = 50
    timerstart = CurTime()
    cooldown1 = true
end)

net.Receive("obeliskscreamingtocliennt", function()
    distance2 = net.ReadFloat()
    local ent = net.ReadEntity()

    print(distance2)

    if not obeliskragescream then
        obeliskragescream = CreateSound(ent, "obelisk/obeliskscreamloop.wav")  
        print("obeliskragescream createsound") 
    end

    if not reverbscream then
        reverbscream = CreateSound(ent, "obelisk/screamingdistance.wav")
        print("reverbscream createsound")
    end
end)


net.Receive("obelisskscreamstop", function()
    distance2 = nil

    if obeliskragescream then
        obeliskragescream:Stop()
        obeliskragescream = nil
    end

    if reverbscream then
        reverbscream:Stop()
        reverbscream = nil
    end

    print("obelisskscreamstop")
end)

hook.Add("Think", "obeliskreverbscreaminng", function()
    if not distance2 then return end

    if distance2 > 800 then
            obeliskragescream:Stop()
            reverbscream:Play()
            reverbscream:ChangeVolume(2, 0)
            print("FARRRRRRRRRRRRRRRRR")
    elseif distance2 < 800 then
            print("CLOSEEEEEEEEEEEEE")
            print(obeliskragescream)
            reverbscream:Stop()
            obeliskragescream:Play()
    end
end)


net.Receive("nonsensenetworkingshit", function()
    r2 = 255
    g2 = 255
    b2 = 255
end)

net.Receive("ragescreamabilitdisableability", function()
    if distance2 then
      distance2 = nil

    if obeliskragescream then
        obeliskragescream:Stop()
        obeliskragescream = nil
    end

    if reverbscream then
        reverbscream:Stop()
        reverbscream = nil
    end

    vignetteAlpha = 0
    vignetteTarget = 0

    print("obelisskscreamstop")
    end
end)