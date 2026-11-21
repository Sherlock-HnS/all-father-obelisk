local jumpHighlights = {}
local shiftHighlights = {}
local HIGHLIGHT_TIME = 3

net.Receive("sendbacktoclientobelisk", function()
    local ply = net.ReadEntity()
    if not IsValid(ply) then return end
    jumpHighlights[ply] = CurTime() + HIGHLIGHT_TIME
end)

net.Receive("sendshiftbacktoclient", function()
    local ply = net.ReadEntity()
    if not IsValid(ply) then return end
    shiftHighlights[ply] = CurTime() + HIGHLIGHT_TIME
end)

hook.Add("PostDrawTranslucentRenderables", "obelisk_highlight", function()
    local now = CurTime()
    local lp = LocalPlayer()
    local drew = false

    cam.IgnoreZ(true)
    render.SetStencilEnable(true)
    render.ClearStencil()

    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
    render.SetStencilCompareFunction(STENCIL_NEVER)
    render.SetStencilFailOperation(STENCIL_REPLACE)
    render.SetStencilReferenceValue(0x1C)
    render.SetStencilWriteMask(0x55)

    for ply, expire in pairs(jumpHighlights) do
        if not IsValid(ply) or now > expire then
            jumpHighlights[ply] = nil
        elseif ply ~= lp then
            ply:DrawModel()
            drew = true
        end
    end

    for ply, expire in pairs(shiftHighlights) do
        if not IsValid(ply) or now > expire then
            shiftHighlights[ply] = nil
        elseif ply ~= lp then
            ply:DrawModel()
            drew = true
        end
    end

    if drew then
        render.SetStencilTestMask(0xF3)
        render.SetStencilReferenceValue(0x10)
        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.ClearBuffersObeyStencil(255, 0, 0, 255, false)
    end

    render.SetStencilEnable(false)
    cam.IgnoreZ(false)
end)
