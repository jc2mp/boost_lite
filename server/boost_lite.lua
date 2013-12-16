function Vector3:IsNaN()
	return (self.x ~= self.x) or (self.y ~= self.y) or (self.z ~= self.z)
end

Network:Subscribe("Boost",
	function(args, sender)
		if sender:GetWorld() ~= DefaultWorld then return end
		if not sender:InVehicle() then return end
		if sender:GetState() ~= PlayerState.InVehicle then return end

		local v = sender:GetVehicle()
		local forward = v:GetAngle() * Vector3(0, 0, -1)
		local vel = v:GetLinearVelocity()
		local new_vel = vel + (forward * 10)

		if new_vel:IsNaN() then
			new_vel = Vector3( 0, 0, 0 )
		end

		v:SetLinearVelocity( new_vel )
	end)
