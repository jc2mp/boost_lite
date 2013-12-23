
--Helper function to see if the vector is invalid.
function Vector3:IsNaN()
	return (self.x ~= self.x) or (self.y ~= self.y) or (self.z ~= self.z)
end

--Helper function to see if the vehicle is going in reverse.
--Not currently used, but might in future?
function Vehicle:IsReversing()
	local forward = self:GetAngle() * Vector3(0,0,-1)
	local vel = self:GetLinearVelocity()
	
	return forward:Dot(vel:Normalized()) < 0
end

--Is this vehicle in our allowed-vehicle-list?
local function IsVehicleValid( veh )
	return land_vehicles[veh:GetModelId()]
end

--Helper function to see if the player is allowed to boost.
local function PlayerCanBoost( ply )
	if ply:GetWorld() != DefaultWorld then return false end -- Not in same world.
	if ply:GetState() ~= PlayerState.InVehicle then return false end -- Not the driver of a vehicle.
	if not IsValid(ply:GetVehicle()) then return false end -- Vehicle somehow invalid.
	return IsVehicleValid( ply:GetVehicle() ) -- Vehicle not in our allowed vehicle list.
end

--Helper function to easily apply a boost on a vehicle with supplied multiplier.
local function ApplyBoost( veh, mul )
	local forward = veh:GetAngle() * Vector3(0, 0, -1) -- Get our forward direction.
	local vel = veh:GetLinearVelocity() -- Get our current velocity.
	
	local newVel = vel + (forward * mul) -- Apply our current velocity with the forward vector, times input multiplier.

	if newVel:IsNaN() then
		return
	end

	veh:SetLinearVelocity( newVel )
end

local boosters = {} -- List of players currently boosting

--Message received about boosting
local function BoostMessage(val, sender)
	--Val will be 'false' whenever we want to turn off
	--Val will be a value whenever we want to turn on
	
	local turnOn
	if not val then
		turnOn = false
	else
		turnOn = true
	end
	
	if turnOn and not PlayerCanBoost(sender) then return end -- If the player wants to turn it on, but he can't: don't let him.
	
	if turnOn then
		boosters[ sender:GetId() ] = {ply = sender, mul = val} -- Player wants to turn it on
	else
		boosters[ sender:GetId() ] = nil -- Player wants to turn it off
	end
end
Network:Subscribe("Boost", BoostMessage)

local timer = Timer()
local function PostTick()
	if timer:GetMilliseconds() <= 50 then return end
	timer:Restart()
	
	for plyID,tbl in pairs(boosters) do -- Walk through all players who want to boost
	
		if not IsValid(tbl.ply) then -- If the player has left the game
			boosters[plyID] = nil -- Stop us from processing him
		elseif PlayerCanBoost(tbl.ply) then -- Otherwise, check if he's allowed to boost.
			ApplyBoost(tbl.ply:GetVehicle(), tbl.mul)
		end
		
	end
end
Events:Subscribe("PostTick", PostTick)
