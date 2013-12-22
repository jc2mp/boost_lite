
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
local nos_enabled = true
local isboosting = false
--local window_open = false

function InputEvent( args )
	if not nos_enabled then return true end -- If we have boosting turned off, leave
	if timer:GetSeconds() <= 0.2 then return true end -- If we try to spam the key, leave
	if not IsBoostAction(args.input) then return true end -- If the key we pressed isn't a boost-key, leave
	
	local canboost = PlayerCanBoost() -- Can we boost currently?
	if not isboosting and canboost then -- Only send the message if we ain't boosting
		--Boost
		Network:Send("Boost", true) -- Send message
		isboosting = true
	end
end

Events:Subscribe("PostTick", function()
	if isboosting and not Key:IsDown(GetBoostKey()) then -- Keep checking if we have released the boost key
		isboosting = false
		Network:Send("Boost", false) -- Send message to stop us from boosting
	end
end)

local textsize
function RenderEvent()
	if not PlayerCanBoost() then return end
	
	local boost_text = string.format("Boost Lite (%s) - /boost to toggle", nos_enabled and "ON" or "OFF")
	textsize = textsize or Render:GetTextSize( boost_text ) -- only calculate textsize once, duh

	local boost_pos = Vector2( 
		(Render.Width - textsize.x)/2, 
		Render.Height - textsize.y ) -- Theoretically we could only calculate this once too, but the player may change resolution.

	Render:DrawText( boost_pos, boost_text, Color( 255, 255, 255 ) )
end

function LocalPlayerChat( args )
	if args.text == "/boost" then
		nos_enabled = not nos_enabled -- Toggle boosting directly.
		--SetWindowOpen( not GetWindowOpen() ) -- Disabling window because it only has one setting anyways.
	end
end

--[[
function CreateSettings()
    window_open = false

    window = Window.Create()
    window:SetSize( Vector2( 300, 100 ) )
    window:SetPosition( (Render.Size - window:GetSize())/2 )

    window:SetTitle( "Boost Settings" )
    window:SetVisible( window_open )
    window:Subscribe( "WindowClosed", function() SetWindowOpen( false ) end )

    local enabled_checkbox = LabeledCheckBox.Create( window )
    enabled_checkbox:SetSize( Vector2( 300, 20 ) )
    enabled_checkbox:SetDock( GwenPosition.Top )
    enabled_checkbox:GetLabel():SetText( "Enabled" )
    enabled_checkbox:GetCheckBox():SetChecked( nos_enabled )
    enabled_checkbox:GetCheckBox():Subscribe( "CheckChanged", 
        function() nos_enabled = enabled_checkbox:GetCheckBox():GetChecked() end )
end

function GetWindowOpen()
    return window_open
end

function SetWindowOpen( state )
    window_open = state
    window:SetVisible( window_open )
    Mouse:SetVisible( window_open )
end]]

function ModulesLoad()
	Events:FireRegisteredEvent( "HelpAddItem",
        {
            name = "Boost",
            text = 
                "The boost lets you increase the speed of your car/boat.\n\n" ..
                "To use it, hold Shift on a keyboard, or the LB button " ..
                "on controllers.\n\n" ..
                "To toggle the script, type /boost into chat."
        } )
end

function ModuleUnload()
    Events:FireRegisteredEvent( "HelpRemoveItem",
        {
            name = "Boost"
        } )
end

--CreateSettings()

Events:Subscribe("LocalPlayerChat", LocalPlayerChat)
Events:Subscribe("Render", RenderEvent)
Events:Subscribe("LocalPlayerInput", InputEvent)
Events:Subscribe("ModulesLoad", ModulesLoad)
Events:Subscribe("ModuleUnload", ModuleUnload)