/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/

FVJOHNNY_PILLS = FVJOHNNY_PILLS or {}

function FVJOHNNY_PILLS:LoadFile(path, serverOnly, clientOnly)
    if SERVER and not serverOnly then AddCSLuaFile(path) end

    if clientOnly and SERVER then return end
    if serverOnly and CLIENT then return end

    -- Use CompileFile on client to avoid datapack warnings
    include(path)

    print("[FVJOHNNY_PILLS] Loaded file: "..path)
end

function FVJOHNNY_PILLS:LoadFiles()
    self:LoadFile("pills/shared/pills-register.lua")
    self:LoadFile("pills/shared/pills-button-press.lua")
    self:LoadFile("pills/shared/pills-think.lua")
    self:LoadFile("pills/shared/pills-utils.lua")
    self:LoadFile("pills/shared/pills-killcam.lua")
    self:LoadFile("pills/shared/pills-steps.lua")
    self:LoadFile("pills/shared/pills-vgui-abilities.lua")

    self:LoadFile("pills/all-father/config.lua")
    self:LoadFile("pills/all-father/peek.lua")
    self:LoadFile("pills/all-father/mark.lua")
    self:LoadFile("pills/all-father/mark-fucked-movement.lua")
    self:LoadFile("pills/all-father/mark-fucked-vision.lua")
    self:LoadFile("pills/all-father/mark-colors.lua")
    self:LoadFile("pills/all-father/invisibility.lua")
    self:LoadFile("pills/all-father/invisibility-stun.lua")
    self:LoadFile("pills/all-father/invisibility-render.lua")
    self:LoadFile("pills/all-father/invisibility-weapon-block.lua")
    self:LoadFile("pills/all-father/trail.lua")
end



FVJOHNNY_PILLS:LoadFiles()