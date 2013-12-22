
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
	local forward = veh:GetAngle() * Vector3(0, 0, -1) -- Get a forward vector.
	local vel = veh:GetLinearVelocity() -- Get our current velocity.
	
	local new_vel = vel + (forward * mul) -- Apply our current velocity with the forward vector, times input multiplier.

	if new_vel:IsNaN() then -- If the newly calculated velocity is somehow invalid, stop what we're doing.
		return
	end

	veh:SetLinearVelocity( new_vel )
end

local boosters = {} -- List of players currently boosting

--Message received about boosting
Network:Subscribe("Boost",
	function(turnon, sender)
		if turnon and not PlayerCanBoost(sender) then return end -- If the player wants to turn it on, but he can't: don't let him.
		
		if turnon then
			boosters[ sender:GetId() ] = sender -- Player wants to turn it on
		else
			boosters[ sender:GetId() ] = nil -- Player wants to turn it off
		end
	end)

Events:Subscribe("PostTick", function()
	for plyid,ply in pairs(boosters) do -- Walk through all players who want to boost
		if not IsValid(ply) then -- If the player has left the game
			boosters[plyid] = nil -- Stop us from processing him
		elseif PlayerCanBoost(ply) then -- Otherwise, check if he's allowed to boost.
			ApplyBoost(ply:GetVehicle(), BoostMultiplier) -- He is! Boost him!
		end
	end
end)
