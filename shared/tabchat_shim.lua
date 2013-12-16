
if Client ~= nil then

	-- TabChat
	Events:Register( "LocalPlayerChat" )

	TabChat = { Active = false }

	TabChat.OldChatPrint = Chat.Print

	-- TabChat override definitions

	function TabChat.OverrideChatPrint( self, string, colour )
		-- Client : Chat:Print()

		if colour == nil then
			colour = Color(255,255,255)
		end

		Events:FireRegisteredEvent( "TCSystemChatMessageOverride", {
					from_script = module_name,
					message = string,
					script_colour = colour,
					message_colour = colour
		}	)
	end

	function TabChat.ToggleOverride( toggle )
		if toggle then
			Chat.Print = TabChat.OverrideChatPrint
			TabChat.Active = true
		else
			Chat.Print = TabChat.OldChatPrint
			TabChat.Active = false
		end
	end

	function TC_ClientLoaded( toggle )
		TabChat.ToggleOverride( toggle )
	end
	
	Events:Register( "TC_ClientLoaded" )
	Events:Subscribe( "TC_ClientLoaded", TC_ClientLoaded )
	Events:FireRegisteredEvent( "TC_ClientRunning", false )

else

	function TCLoaded( ... )
		local require_success = require 'TabChat'
	end

	Events:Register( "TCLoaded" )
	Events:Subscribe( "TCLoaded", TCLoaded )
	Events:FireRegisteredEvent( "TCIsRunning", false )

end
