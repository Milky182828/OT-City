include("shared.lua")

ENT.PhysPos = Vector(0,0,0)
ENT.PhysAng = Angle(0,0,0)

local mat2 = Material("sprites/light_glow02_add_noz")

function ENT:Draw()
	self:DrawModel()

	if self:GetNetVar("enabled", false) then
		local view = render.GetViewSetup(true)
		local deg = self:GetAngles():Forward():Dot(view.angles:Forward())
		local chekvisible = util.TraceLine({
			start = self:GetPos() + self:GetAngles():Forward() * 6,
			endpos = view.origin,
			filter = { self, LocalPlayer() },
			mask = MASK_VISIBLE
		})

		if deg < 0 and not chekvisible.Hit then
			render.SetMaterial(mat2)
			render.DrawSprite(self:GetPos() + self:GetAngles():Forward() * 6 + self:GetAngles():Right() * -0.5, 300 * math.min(deg, 0), 100 * math.min(deg, 0), color_white)
			render.DrawSprite(self:GetPos() + self:GetAngles():Forward() * 6 + self:GetAngles():Right() * -0.5, 100 * math.min(deg, 0), 200 * math.min(deg, 0), color_white)
		end
	end
end

function ENT:Think()
	local enabled = self:GetNetVar("enabled", false)

	if enabled then
		if not self.flashlight then
			self.flashlight = ProjectedTexture()
		end

		local fl = self.flashlight
		if fl and fl:IsValid() then
			fl:SetTexture("effects/flashlight/soft")
			fl:SetFarZ(1500)
			fl:SetNearZ(10)
			fl:SetFOV(50)
			fl:SetEnableShadows(false)
			fl:SetBrightness(2)
			fl:SetColor(color_white)
			fl:SetConstantAttenuation(1)
			fl:SetLinearAttenuation(50)
			fl:SetPos(self:GetPos() + self:GetAngles():Forward() * 20)
			fl:SetAngles(self:GetAngles())
			fl:Update()
		end
	else
		if self.flashlight and self.flashlight:IsValid() then
			self.flashlight:Remove()
		end
		self.flashlight = nil
	end

	self:NextThink(CurTime())
	return true
end

function ENT:Initialize()
end

function ENT:OnRemove()
	if self.flashlight and self.flashlight:IsValid() then
		self.flashlight:Remove()
	end
	self.flashlight = nil
end