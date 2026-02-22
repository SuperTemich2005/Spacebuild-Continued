AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
--include('entities/base_wire_entity/init.lua')
include( 'shared.lua' )

util.PrecacheSound( "ambient/atmosphere/outdoor2.wav" )
util.PrecacheSound( "ambient/atmosphere/indoor1.wav" )
util.PrecacheSound( "buttons/button1.wav" )
util.PrecacheSound( "buttons/button18.wav" )
util.PrecacheSound( "buttons/button6.wav" )
util.PrecacheSound( "buttons/combine_button3.wav" )
util.PrecacheSound( "buttons/combine_button2.wav" )
util.PrecacheSound( "buttons/lever7.wav" )

function ENT:Initialize()
	self:SetName("advanced_gyropod")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMaterial("spacebuild/SBLight5");
	self.Inputs = WireLib.CreateSpecialInputs( self, {"Activate", "Forward", "Back", "MoveLeft", "MoveRight", "MoveUp", "MoveDown", "RollLeft", "RollRight", "PitchUp", "PitchDown", "YawLeft", "YawRight", "MouseAngle", "MouseAim", "LinearSpeed", "TurnSpeed", "LinearAcceleration", "TurnAcceleration", "Level"},
													 {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "ANGLE", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL"},
													 {"Send a value other than 0 to parent all (recursively) connected entities to this gyropod and enable motion.", "Send value from 0 to 1 to make ship move forward", "Send value from 0 to 1 to make ship move backward", "Send value from 0 to 1 to make ship strafe left", "Send value from 0 to 1 to make ship strafe right", "Send value from 0 to 1 to make ship hover up", "Send value from 0 to 1 to make ship hover down", "Send value from 0 to 1 to make ship roll left", "Send value from 0 to 1 to make ship roll right", "Send value from 0 to 1 to make ship pitch up", "Send value from 0 to 1 to make ship pitch down", "Send value from 0 to 1 to make ship turn left", "Send value from 0 to 1 to make ship turn right", "If MouseAim is not 0, make ship face in this direction", "If not 0, ship will rotate after MouseAngle. Can be Cam Controller CamAng or really any other angle.", "Value from 0 to 8192 defining ship's linear speed in units/second", "Value from 0 to 180 defining ships's spin speed in degrees/second", "How fast the ship will go from current speed to LinearSpeed", "How fast will ship go from current turn rate to TurnSpeed", "Make the ship level with ground. Used to avoid having to use complicated gate setups and E2/SF chips to do that manually."})
	self.Outputs = WireLib.CreateSpecialOutputs(self, { "On", "Targeting Mode", "MPH", "KmPH", "Leveler", "Total Mass", "Props Linked", "Angles" }, { "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "ANGLE" })
	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
	end
	self.SystemOn = false
	self.Forw = 0
	self.Back = 0
	self.SLeft = 0
	self.SRight = 0
	self.HUp = 0
	self.HDown = 0
	self.RollLeft = 0
	self.RollRight = 0
	self.GyroPitchUp = 0
	self.GyroPitchDown = 0
	self.GyroYawLeft = 0
	self.GyroYawRight = 0

	self.CurrentDirection = Vector()
	self.CurrentRotation = Angle()
	self.LinearSpeed = 1024
	self.TurnSpeed = 90
	self.LinearAcceleration = 1
	self.TurnAcceleration = 1
	self.MouseAim = false
	self.MouseAngle = Angle()
	self.ShipMins = Vector()
	self.ShipMaxs = Vector()
	self.ShipCenter = Vector()
	self.ShipProps = {}
end

function ENT:TriggerInput(iname, value)
	if (iname == "Activate") then
		if (value ~= 0) then
			self.SystemOn = true

			local mins = Vector()
			local maxs = Vector()
			self.ShipProps = {}

			for _, part in pairs(constraint.GetAllConstrainedEntities(self)) do
				part:SetParent(self)
				part:GetPhysicsObject():EnableMotion(false)
				self.ShipProps[#self.ShipProps+1] = part

				for _, corner in pairs({
					Vector(0,0,0),
					Vector(0,0,1),
					Vector(0,1,0),
					Vector(0,1,1),
					Vector(1,0,0),
					Vector(1,0,1),
					Vector(1,1,0),
					Vector(1,1,1)
				}) do
					local corner_coordinate = self:WorldToLocal(part:LocalToWorld(part:OBBMins()+(part:OBBMaxs()-part:OBBMins())*corner))
					
					if corner_coordinate.x < mins.x then mins.x = corner_coordinate.x end
					if corner_coordinate.y < mins.y then mins.y = corner_coordinate.y end
					if corner_coordinate.z < mins.z then mins.z = corner_coordinate.z end
					
					if corner_coordinate.x > maxs.x then maxs.x = corner_coordinate.x end
					if corner_coordinate.y > maxs.y then maxs.y = corner_coordinate.y end
					if corner_coordinate.z > maxs.z then maxs.z = corner_coordinate.z end
				end
			end

			self.ShipProps[#self.ShipProps+1] = self
			self.ShipMins = mins
			self.ShipMaxs = maxs
			self.ShipCenter = (maxs+mins)/2
		else
			self.SystemOn = false
			for _, part in pairs(constraint.GetAllConstrainedEntities(self)) do
				part:SetParent(nil)
				part:GetPhysicsObject():EnableMotion(false)
			end
		end
	elseif (iname == "Freeze") then
		if (value ~= 0) then
			self.FreezeOn = true
		else
			self.FreezeOn = false
		end
	elseif (iname == "AimMode") then
		if (value ~= 0) then
			self.AimModeOn = true
		else
			self.AimModeOn = false
		end
	elseif (iname == "Forward") then
		self.Forw = math.Clamp(value,0,1)
	elseif (iname == "Back") then
		self.Back = math.Clamp(value,0,1)
	elseif (iname == "MoveLeft") then
		self.SLeft = math.Clamp(value,0,1)
	elseif (iname == "MoveRight") then
		self.SRight = math.Clamp(value,0,1)
	elseif (iname == "MoveUp") then
		self.HUp = math.Clamp(value,0,1)
	elseif (iname == "MoveDown") then
		self.HDown = math.Clamp(value,0,1)
	elseif (iname == "RollLeft") then
		self.RollLeft = math.Clamp(value,0,1)
	elseif (iname == "RollRight") then
		self.RollRight = math.Clamp(value,0,1)
	elseif (iname == "PitchUp") then
		self.GyroPitchUp = math.Clamp(value,0,1)
	elseif (iname == "PitchDown") then
		self.GyroPitchDown = math.Clamp(value,0,1)
	elseif (iname == "YawLeft") then
		self.GyroYawLeft = math.Clamp(value,0,1)
	elseif (iname == "YawRight") then
		self.GyroYawRight = math.Clamp(value,0,1)
	elseif (iname == "Level") then
		if (value ~= 0) then
			self.GyroLevelerOut = 1
			self.GyroLvl = true
		else
			self.GyroLevelerOut = 0
			self.GyroLvl = false
		end		
	elseif (iname == "LinearSpeed") then
		self.LinearSpeed = math.Clamp(value,0,16384)
	elseif (iname == "TurnSpeed") then
		self.TurnSpeed = math.Clamp(value,0,180)
	elseif (iname == "LinearAcceleration") then
		self.LinearAcceleration = math.Clamp(value,0,4)
	elseif (iname == "TurnAcceleration") then
		self.TurnAcceleration = math.Clamp(value,0,4)
	elseif (iname == "MouseAim") then
		if value ~= 0 then self.MouseAim = true else self.MouseAim = false end
	elseif (iname == "MouseAngle") then
		self.MouseAngle = value
	end
end

function ENT:Think()
	if not self.SystemOn then self.CurrentDirection = Vector() self.CurrentRotation = Angle() return end
	local input_direction = Vector(self.Forw-self.Back,self.SLeft-self.SRight,self.HUp-self.HDown)
	self.CurrentDirection = LerpVector(FrameTime()*self.LinearAcceleration,self.CurrentDirection,input_direction)
	local tr = util.TraceLine({
		start = self:LocalToWorld(self.ShipCenter),
		endpos = self:LocalToWorld(self.ShipCenter+input_direction*(self.ShipMaxs-self.ShipMins)/2),
		filter = self.ShipProps
	})
	if not tr.Hit then self:SetPos(self:LocalToWorld(self.CurrentDirection*self.LinearSpeed*FrameTime())) else self.CurrentDirection = Vector() end

	local input_rotation = Angle()
	if self.MouseAim then
		input_rotation = self.MouseAngle
		self.CurrentRotation = Angle()
		if self.GyroLvl then
			self:SetAngles(LerpAngle(FrameTime()*self.TurnAcceleration,self:GetAngles(),Angle(0,input_rotation.y,0)))
		else
			self:SetAngles(LerpAngle(FrameTime()*self.TurnAcceleration,self:GetAngles(),input_rotation))
		end
	else
		input_rotation = Angle(self.GyroPitchUp-self.GyroPitchDown,self.GyroYawLeft-self.GyroYawRight,self.RollRight-self.RollLeft)
		self.CurrentRotation = LerpAngle(FrameTime()*self.TurnAcceleration,self.CurrentRotation,input_rotation)
		if self.GyroLvl then
			self:SetAngles(self:LocalToWorldAngles(self.TurnSpeed*Angle(0,self.CurrentRotation.y,0)*FrameTime()))
		else
			self:SetAngles(self:LocalToWorldAngles(self.TurnSpeed*self.CurrentRotation*FrameTime()))
		end
	end



	self:NextThink(CurTime())
	return true
end

function ENT:OnRemove()
	if self.sound then
		self.HighEngineSound:Stop()
		self.LowDroneSound:Stop()
	end	
end

function ENT:PreEntityCopy()
	local DI = {}

	if (self.Pod and IsValid(self.Pod)) then
		DI.Pod = self.Pod:EntIndex()
	end
	
	if WireAddon then
		DI.WireData = WireLib.BuildDupeInfo( self )
	end
	
	duplicator.StoreEntityModifier(self, "SBEPGyroAdv", DI)
end
duplicator.RegisterEntityModifier( "SBEPGyroAdv" , function() end)

function ENT:PostEntityPaste(pl, Ent, CreatedEntities)
	local DI = Ent.EntityMods.SBEPGyroAdv
	
	if (DI.Pod) then
		self.Pod = CreatedEntities[ DI.Pod ]
		/*if (!self.Pod) then
			self.Pod = ents.GetByIndex(DI.Pod)
		end*/
	end
	
	if(Ent.EntityMods and Ent.EntityMods.SBEPGyroAdv.WireData) then
		WireLib.ApplyDupeInfo( pl, Ent, Ent.EntityMods.SBEPGyroAdv.WireData, function(id) return CreatedEntities[id] end)
	end

end
