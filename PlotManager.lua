-- LUGIA: grab Players service
local Players = game:GetService("Players")

-- two tables:
-- plots[] holds references to all available plot objects
-- plotOwners[plot] keeps track of who owns each specific plot
local plots = {}
local plotOwners = {}

-- LUGIA: loop through 6 plots in the Workspace (Map.Plot1 to Map.Plot6)
for i = 1, 6 do
	local plot = workspace.Map:WaitForChild("Plot" .. i) -- wait until plot exists
	table.insert(plots, plot)

	-- update the billboard above the plot to say "Available"
	local billboard = plot:FindFirstChildWhichIsA("BillboardGui")
	local textLabel = billboard:FindFirstChildWhichIsA("TextLabel")
	textLabel.Text = "Available"

	-- each plot gets a StringValue named "Owner" to store who owns it
	local ownerValue = plot:FindFirstChild("Owner")
	if not ownerValue then
		ownerValue = Instance.new("StringValue")
		ownerValue.Name = "Owner"
		ownerValue.Parent = plot
	end

	-- mark the plot as free (no owner yet)
	plotOwners[plot] = nil
end

-- LUGIA: helper function
-- grabs a random free plot (where plotOwners[plot] == nil)
local function getRandomPlot()
	local availablePlots = {}
	for _, plot in ipairs(plots) do
		if plotOwners[plot] == nil then
			table.insert(availablePlots, plot)
		end
	end

	-- if any are available, return one at random
	if #availablePlots > 0 then
		return availablePlots[math.random(1, #availablePlots)]
	else
		return nil -- no plots left
	end
end

-- LUGIA: when a player joins the game
Players.PlayerAdded:Connect(function(player)
	local selectedPlot = getRandomPlot()
	if selectedPlot then
		-- assign this plot to the player
		plotOwners[selectedPlot] = player.Name

		-- update billboard text above the plot
		local billboard = selectedPlot:FindFirstChildWhichIsA("BillboardGui")
		local textLabel = billboard and billboard:FindFirstChildWhichIsA("TextLabel")
		if textLabel then
			textLabel.Text = player.Name .. "'s Lake"
		end

		-- update the StringValue "Owner" inside the plot
		local ownerValue = selectedPlot:FindFirstChild("Owner")
		if ownerValue then
			ownerValue.Value = player.Name
		end

		-- teleport player’s character to their plot spawn when they spawn
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart")
			character:SetPrimaryPartCFrame(selectedPlot.CFrame + Vector3.new(0, 3, 0))
		end)
	end
end)

-- LUGIA: when a player leaves the game
Players.PlayerRemoving:Connect(function(player)
	for plot, ownerName in pairs(plotOwners) do
		if ownerName == player.Name then
			-- free up the plot
			plotOwners[plot] = nil

			-- reset billboard text to "Available"
			local billboard = plot:FindFirstChildWhichIsA("BillboardGui")
			local textLabel = billboard and billboard:FindFirstChildWhichIsA("TextLabel")
			if textLabel then
				textLabel.Text = "Available"
			end

			-- clear the Owner StringValue
			local ownerValue = plot:FindFirstChild("Owner")
			if ownerValue then
				ownerValue.Value = ""
			end
		end
	end
end)
