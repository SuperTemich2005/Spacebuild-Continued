TOOL.Category		= "SBEP"
TOOL.Tab 			= "Spacebuild"
TOOL.Name = "#Part Spawner"
TOOL.Command = nil
TOOL.ConfigName = ""

local SmallBridgeModels = list.Get("SBEP_SmallBridgeModels")

if CLIENT then
    language.Add("Tool.sbep_part_spawner.name", "SBEP Part Spawner")
    language.Add("Tool.sbep_part_spawner.desc", "Spawn SBEP props.")
    language.Add("Tool.sbep_part_spawner.0", "Left click to spawn a prop. Shift + F to toggle between Part Spawner and Part Assembler Tool.")
    language.Add("undone_SBEP Part", "Undone SBEP Part")

	hook.Add("PlayerBindPress","[MPTF] Switch To Part Assembler",function(ply,bind,pressed,code)
		if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "gmod_tool" then
			if ply == LocalPlayer() and bind == "impulse 100" and pressed and LocalPlayer():KeyDown(IN_SPEED) then
				if ply:GetActiveWeapon():GetMode() == "sbep_part_spawner" then
					spawnmenu.ActivateTool("sbep_part_assembler")
					return true
				elseif ply:GetActiveWeapon():GetMode() == "sbep_part_assembler" then
					spawnmenu.ActivateTool("sbep_part_spawner")
					return true
				end
			end
		end
	end)

	local SCEPanel = {}
	surface.CreateFont( "SCEPanelCustomFont", {
		font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer.
		extended = false,
		size = 24,
		weight = 1100,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	function SCEPanel:Init()

	end
	function SCEPanel:SetText(text)
		self.text = text
	end
	function SCEPanel:SetTextColor(color)
		self.color = color
	end
	function SCEPanel:Paint(w,h)
		draw.RoundedBox(5,0,0,w,h,self.color)
		draw.DrawText(self.text,"SCEPanelCustomFont",w/2,0,Color(240,240,240,255),TEXT_ALIGN_CENTER)
	end
	vgui.Register("SCEP_PartSpawner_BridgeSeparator",SCEPanel,"Panel")
end

TOOL.ClientConVar["model"] = "models/smallbridge/hulls_sw/sbhulle1.mdl"
TOOL.ClientConVar["skin"] = 0
TOOL.ClientConVar["glass"] = 0
TOOL.ClientConVar["hab_mod"] = 0
TOOL.ClientConVar["weld"] = 0

function TOOL:LeftClick(trace)

    if CLIENT then return end

    local model = self:GetClientInfo("model")
    local hab = self:GetClientNumber("hab_mod")
    local skin = self:GetClientNumber("skin")
    local glass = self:GetClientNumber("glass")
    local weld = self:GetClientNumber("weld")
    local pos = trace.HitPos

    local SMBProp = nil

    if hab == 1 then
        SMBProp = ents.Create("livable_module")
    else
        SMBProp = ents.Create("prop_physics")
    end

    SMBProp:SetModel(model)

    local skincount = SMBProp:SkinCount()
	SMBProp:SetNWInt("Skin",skinnum)
    local skinnum = nil
    if skincount > 5 then
        skinnum = skin * 2 + glass
    else
        skinnum = skin
    end

	SMBProp:SetNWInt("Skin", skinnum)

    SMBProp:SetSkin(skinnum)
    SMBProp:SetPos(pos - Vector(0, 0, SMBProp:OBBMins().z))

    SMBProp:Spawn()
    SMBProp:Activate()
	if CPPI and SMBProp.CPPISetOwner then SMBProp:CPPISetOwner( self:GetOwner() ) end
	if weld == 1 and IsValid(trace.Entity) then
		constraint.Weld( SMBProp, trace.Entity, 0, trace.PhysicsBone, 0, collision == 1, false )
	end
    undo.Create("SBEP Part")
    undo.AddEntity(SMBProp)
    undo.SetPlayer(self:GetOwner())
    undo.Finish()

    return true
end

function TOOL:Reload(trace)
end

function TOOL.BuildCPanel(panel)

    panel:SetSpacing(10)
    panel:SetName("SBEP Part Spawner")
	
	local SkinTable = 
	{
		"Advanced",
		"SlyBridge",
		"MedBridge2",
		"Jaanus",
		"Scrappers"
	}
	
	local SkinSelectorLabel = vgui.Create("DLabel", panel)
	SkinSelectorLabel:SetText("SmallBridge skin:")
	SkinSelectorLabel:SetTextColor(Color(0,0,0,255))
	panel:AddItem(SkinSelectorLabel)
	local SkinSelector = vgui.Create( "DComboBox", panel )
	SkinSelector:SetValue( SkinTable[GetConVar("sbep_part_spawner_skin"):GetInt()] or SkinTable[1] )
	SkinSelector.OnSelect = function( index, value, data )
		RunConsoleCommand( "sbep_part_spawner_skin", value )
	end
	for k,v in pairs( SkinTable ) do
		SkinSelector:AddChoice( v )
	end
	panel:AddItem(SkinSelector)

	local GlassButton = vgui.Create( "DCheckBoxLabel", panel )
	GlassButton:SetValue( GetConVar( "sbep_part_spawner_glass" ):GetBool() )
	GlassButton:SetText( "Spawn with Glass (for SmallBridge)" )
	GlassButton:SetTextColor(Color(0,0,0,255))
	GlassButton:SetConVar( "sbep_part_spawner_glass" )
	panel:AddItem(GlassButton)
	
	if CAF then
		local HabitableModuleButton = vgui.Create("DCheckBoxLabel", panel )
		HabitableModuleButton:SetValue( GetConVar( "sbep_part_spawner_hab_mod" ):GetBool() )
		HabitableModuleButton:SetText( "Spawn as Habitable Module" )
		HabitableModuleButton:SetTextColor(Color(0,0,0,255))
		HabitableModuleButton:SetConVar( "sbep_part_spawner_hab_mod" )
		panel:AddItem(HabitableModuleButton)
	else
		local NoHabLabel = vgui.Create("DLabel", panel)
		NoHabLabel:SetText("No Spacebuild 3 installed, cannot create habitable modules.")
		panel:AddItem(NoHabLabel)
	end
	
	for Tab,v  in pairs( SmallBridgeModels ) do
		local CategoryLabel = vgui.Create("SCEP_PartSpawner_BridgeSeparator", panel)
		CategoryLabel:SetText(Tab)
		CategoryLabel:SetTextColor(v.Color)
		panel:AddItem(CategoryLabel)
		for Category, models in pairs( v ) do
			if Category == "Color" then continue end
			local catPanel = vgui.Create( "DCollapsibleCategory", panel )
			catPanel:SetText(Category)
			catPanel:SetLabel(Category)
			panel:AddItem(catPanel)
			
			local grid = vgui.Create( "DGrid", catPanel )
			grid:Dock( TOP )
			--grid:SetCols( 3 )
			local width,_ = catPanel:GetSize()
			grid:SetColWide( 64 )
			grid:SetRowHeight( 64 )
			
			for key, modelpath in pairs( models ) do
				local icon = vgui.Create( "SpawnIcon", panel )
				--icon:Dock( TOP )
				icon:SetModel( modelpath )
				icon:SetToolTip( modelpath )
				icon.DoClick = function( panel )
					
					RunConsoleCommand( "sbep_part_spawner_model", modelpath )
				end
				--icon:SetIconSize( width )
				grid:AddItem( icon )
				
			end
			catPanel:SetExpanded( 0 )
		end
	end
end


function TOOL:Think()
 	if ( !IsValid( self.GhostEntity ) || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model"), Vector( 0, 0, 0 ), Angle( 0, 0, 0 )) 
	end
	self:UpdateGhostPart(self.GhostEntity,self:GetOwner())
end

function TOOL:UpdateGhostPart( ent, pl )

	if CLIENT then return end
	if ( !IsValid( ent ) ) then return end

	local tr = util.GetPlayerTrace( pl )
	local trace	= util.TraceLine( tr )
	if ( !trace.Hit ) then return end

	if ( trace.Entity:IsPlayer()) then

		ent:SetNoDraw( true )
		return

	end

	local CurPos = ent:GetPos()
	local NearestPoint = ent:NearestPoint( CurPos - ( trace.HitNormal * 512 ) )
	local Offset = CurPos - NearestPoint

	
	ent:SetPos( trace.HitPos + Offset )

	ent:SetNoDraw( false )

end