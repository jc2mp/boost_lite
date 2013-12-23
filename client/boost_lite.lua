
--Is this vehicle in our allowed-vehicle-list?
local function IsVehicleValid( veh )
	return land_vehicles[veh:GetModelId()]
end

--Helper function to see if the player is allowed to boost.
local function PlayerCanBoost()
	if LocalPlayer:GetWorld() != DefaultWorld then return false end
	if LocalPlayer:GetState() ~= PlayerState.InVehicle then return false end
	if not IsValid(LocalPlayer:GetVehicle()) then return false end
	return IsVehicleValid( LocalPlayer:GetVehicle() )
end

--Returns true if this action is the one used to boost.
local function IsBoostAction( action )
	--return (Game:GetSetting( GameSetting.GamepadInUse ) == 1) and (action == Action.VehicleFireLeft) or (action == Action.PlaneIncTrust)
	return (action == Action.PlaneIncTrust) -- Leaving the other out because I did for the next function.
end

--Returns the key used to boost.
--TODO: Fix this hacky shit.
local function GetBoostKey()
	--return (Game:GetSetting( GameSetting.GamepadInUse ) == 1) and (???) or (16) -- TODO: Controller support
	return 16
end

local timer = Timer()
local nosEnabled = true
local isBoosting = false
local windowOpen = false
local boostMul = MaxBoostMultiplier

function InputEvent( args )
	if not nosEnabled then return true end
	
	if timer:GetMilliseconds() <= 200 then return true end -- If we try to spam the key, leave
	if not IsBoostAction(args.input) then return true end -- If the key we pressed isn't a boost-key, leave
	
	local canBoost = PlayerCanBoost() -- Can we boost currently?
	if not isBoosting and canBoost then -- Only send the message if we ain't boosting
		--Boost
		timer:Restart()
		Network:Send("Boost", boostMul) -- Send message
		isBoosting = true
	end
end

local function PostTick()
	if isBoosting and not Key:IsDown(GetBoostKey()) then -- Keep checking if we have released the boost key
		isBoosting = false
		Network:Send("Boost", false) -- Send message to stop us from boosting
	end
end
Events:Subscribe("PostTick", PostTick)

local textSize
function RenderEvent()
	if not PlayerCanBoost() then return end
	
	local boostText = string.format("Boost Lite (%s) - /boost to toggle", nosEnabled and "ON" or "OFF")
	textSize = textSize or Render:GetTextSize( boostText ) -- only calculate textSize once, duh

	local boostPos = Vector2( 
		(Render.Width - textSize.x)/2, 
		Render.Height - textSize.y ) -- Theoretically we could only calculate this once too, but the player may change resolution.

	Render:DrawText( boostPos, boostText, Color( 255, 255, 255 ) )
end

function LocalPlayerChat( args )
	if args.text == "/boost" then
		SetWindowOpen( not GetWindowOpen() ) -- Disabling window because it only has one setting anyways.
	elseif args.text == "/tboost" then
		nosEnabled = not nosEnabled -- Toggle boosting directly.
	end
end

local window
function CreateSettings()
	window = Window.Create()
		window:SetSize( Vector2( 230, 100 ) )
		window:SetPosition( (Render.Size - window:GetSize())/2 )
		window:SetTitle( "Boost Settings" )
		window:SetVisible( false )
		window:Subscribe( "WindowClosed", function() SetWindowOpen( false ) end )
	
	local lbl = Label.Create( window )
		lbl:SetText("Speed: "..(math.floor(boostMul*1000)/1000))
		lbl:SetPosition( Vector2( 5, 5 ) )
		lbl:SizeToContents()
		
	local slider = HorizontalSlider.Create( window )
		slider:SetPosition( Vector2( 70, 5 ) )
		slider:SetSize( Vector2( 145, 10 ) )
		slider:SetClampToNotches(false)
		slider:SetRange(0.001, MaxBoostMultiplier)
		slider:SetValue(MaxBoostMultiplier)
		--[[slider:Subscribe( "CheckChanged",
		function()
			boostMul = slider:GetValue()
			lbl:SetText("Speed: "..(math.floor(boostMul*1000)/1000))
			lbl:SizeToContents()
		end)]]
	
	
	--I could use a LabeledCheckBox but I want the label to be before the checkbox, and not after.
	local lbl = Label.Create( window )
		lbl:SetText("Enabled")
		lbl:SetPosition( Vector2( 5, 30 ) )
		lbl:SizeToContents()
		
	local enabledCheckbox = CheckBox.Create( window )
		enabledCheckbox:SetPosition( Vector2( 50, 25 ) )
		enabledCheckbox:SetSize( Vector2( 20, 20 ) )
		enabledCheckbox:SetChecked( nosEnabled )
		enabledCheckbox:Subscribe( "CheckChanged", 
		function()
			nosEnabled = enabledCheckbox:GetCheckBox():GetChecked()
		end )
		
	local lbl = Label.Create( window )
		lbl:SetText("Type /tboost to quick-toggle boosting.")
		lbl:SetPosition( Vector2( 5, 50 ) )
		lbl:SizeToContents()
end

function GetWindowOpen()
	return windowOpen
end

function SetWindowOpen( state )
	windowOpen = state
	window:SetVisible( windowOpen )
	Mouse:SetVisible( windowOpen )
end

function ModulesLoad()
	Events:FireRegisteredEvent( "HelpAddItem",
        {
            name = "Boost",
            text = 
[[The boost lets you increase the speed of your car/boat.

To use it, hold Shift on a keyboard, or the LB button on controllers.

To open the menu, type /boost into chat.
To toggle boosting on/off, type /tboost into chat.]]
        } )
end

function ModuleUnload()
	Events:FireRegisteredEvent( "HelpRemoveItem",
			{
					name = "Boost"
			} )
end

CreateSettings()

Events:Subscribe("LocalPlayerChat", LocalPlayerChat)
Events:Subscribe("Render", RenderEvent)
Events:Subscribe("LocalPlayerInput", InputEvent)
Events:Subscribe("ModulesLoad", ModulesLoad)
Events:Subscribe("ModuleUnload", ModuleUnload)