-- LUGIA: grab ReplicatedStorage and Players service
-- ReplicatedStorage is used for RemoteEvents (server <-> client communication)
-- Players lets me connect to when players join
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- LUGIA: check if a RemoteEvent named "AdminAnnounce" already exists in ReplicatedStorage
-- if not, I create it so we don’t get duplicate errors
local announceEvent = ReplicatedStorage:FindFirstChild("AdminAnnounce") or Instance.new("RemoteEvent")
announceEvent.Name = "AdminAnnounce"
announceEvent.Parent = ReplicatedStorage -- place it inside ReplicatedStorage

-- LUGIA: whenever a new player joins, I listen to their chat messages
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- turn the message into lowercase so command checking isn’t case-sensitive
		local lowerMsg = message:lower()

		-- define the command trigger ("/announcement ")
		local cmd = "/announcement "

		-- LUGIA: check if the start of the message matches the command
		-- sub(1, #cmd) means: take the first characters of message equal to the length of cmd
		if lowerMsg:sub(1, #cmd) == cmd then
			-- grab the part of the message AFTER the command
			local text = message:sub(#cmd + 1)

			-- fire the RemoteEvent to ALL clients
			-- passes the announcing player's DisplayName and the announcement text
			announceEvent:FireAllClients(player.DisplayName, text)
		end
	end)
end)
