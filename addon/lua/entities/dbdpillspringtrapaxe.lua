AddCSLuaFile()
ENT.Type = 'anim'
ENT.Category = 'Dead by Daylight'
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true
ENT.PrintName = 'Fire Axe'
  
if SERVER then
end

function ENT:Initialize()
    self:SetModel('models/whynotboi/deadbydaylight/fnaf/springtrap/fireaxe.mdl')

    if SERVER then
        self:SetRenderMode(2)

        self:SetCollisionGroup(0)

        self:PhysicsInit(6)

        self:SetSolid(6)

        self:SetMoveType(6)

        self:SetGravity(0)
        
        local phys = self:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:Wake()
            --phys:EnableDrag(false)
            --phys:SetDamping(0, 0)
        end

        phys:SetVelocity(self:GetForward() * 800 + Vector(0, 0, 150))
    end
end

function ENT:PhysicsCollide(colData)
    self:Remove()
end

function ENT:HitEnt(entity)
    if SherlockHNS and IsValid(entity) and entity:IsPlayer() then
        local owner = self:GetCreator()
        if IsValid(owner) and SherlockHNS.Kill(entity, owner, { reason = "axe", inflictor = self }) then self:Remove() end
        return
    end
    if IsValid(entity) and entity:Health() then
        local effectdata = EffectData()

        effectdata:SetOrigin(entity:WorldSpaceCenter())
        effectdata:SetNormal(entity:GetAngles():Forward())
        effectdata:SetMagnitude(3)
        effectdata:SetScale(15)
        effectdata:SetColor(0)
        effectdata:SetFlags(3)
        util.Effect('bloodspray', effectdata)

        if not entity.DBDPILLHITS then 
            entity.DBDPILLHITS = 1
        else
            entity.DBDPILLHITS = (entity.DBDPILLHITS + 1) or 0
        end

        entity:EmitSound('K40_Machete_ImpactSurvivor')
        entity:TakeDamage(30, self)
    end

    self:Remove()
end

function ENT:HitCheckTick()
    if self.HitTick then return end
    self.HitTick = true

    for k,v in pairs(ents.FindInSphere(self:LocalToWorld(Vector(0,0,0)), 50)) do
        if v == self:GetCreator() then continue end

        if v:IsPlayer() or v:IsNPC() or v:IsNextBot() then
            self:HitEnt(v)
        end
    end

    timer.Simple(0.05, function()
        if not IsValid(self) then return end
        
        self.HitTick = false
    end) 
end


function ENT:OnRemove()
end

function ENT:Think()
    local phys = self:GetPhysicsObject()

	if ( SERVER ) then
        self:HitCheckTick()

		self:NextThink( CurTime() )
		return true
	end
end
