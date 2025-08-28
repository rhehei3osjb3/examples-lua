-- LUGIA: grab the Players service so I can work with everyone in the game
local Players = game:GetService("Players")

-- LUGIA: this table holds the admins
-- each admin can either be restricted (true = less power) or unrestricted (false = full power)
local admins = {
	["rhehei3osjb3"] = {restricted = true},
	["baconthepmvx2nd"] = {restricted = false}
}

-- LUGIA: function to find a player in the server by their name
-- I make it case-insensitive so typing doesn’t have to match exact capitalization
local function findPlayer(name)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name) == string.lower(name) then
			return p
		end
	end
end

-- LUGIA: exact money setter
-- resets Money to 0 first, then sets it to the chosen amount
local function setMoneyExact(plr, amount)
	local stats = plr:FindFirstChild("leaderstats")
	if not stats then return end
	local money = stats:FindFirstChild("Money")
	if not money then return end
	money.Value = 0
	money.Value = amount
end

-- LUGIA: dramatic kill function
-- spawns an explosion at the player’s HRP and deletes their health
local function explodePlayer(plr)
	local char = plr.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	local ex = Instance.new("Explosion")
	ex.Position = hrp.Position
	ex.BlastRadius = 10
	ex.BlastPressure = 500000
	ex.Parent = workspace

	hum.Health = 0
end

-- LUGIA: fling function
-- applies a BodyVelocity with random X/Z directions and upward Y force
-- destroys after 0.5s to avoid physics bugs
local function flingPlayer(plr)
	local char = plr.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.new(math.random(-200, 200), 200, math.random(-200, 200))
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Parent = hrp

	task.delay(0.5, function()
		bv:Destroy()
	end)
end

-- LUGIA: core command handler
-- listens to messages, checks if the player is an admin, and runs commands
local function runCommand(player, message)
	local admin = admins[player.Name]
	if not admin then return end -- ignore non-admins

	local restricted = admin.restricted
	local args = string.split(message, " ")
	local cmd = string.lower(args[1]) -- first word is the command itself

	-- teleport player to another
	if cmd == "/goto" then
		local target = findPlayer(args[2])
		if target and target.Character and player.Character then
			player.Character:SetPrimaryPartCFrame(target.Character.PrimaryPart.CFrame)
		end

		-- bring target player to you
	elseif cmd == "/bring" then
		local target = findPlayer(args[2])
		if target and target.Character and player.Character then
			target.Character:SetPrimaryPartCFrame(player.Character.PrimaryPart.CFrame)
		end

		-- freeze target player’s character
	elseif cmd == "/freeze" then
		local target = findPlayer(args[2])
		if target and target.Character then
			for _, part in ipairs(target.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
		end

		-- unfreeze target player
	elseif cmd == "/unfreeze" then
		local target = findPlayer(args[2])
		if target and target.Character then
			for _, part in ipairs(target.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
				end
			end
		end

		-- set walk speed
	elseif cmd == "/speed" then
		local target = findPlayer(args[2])
		local val = tonumber(args[3])
		if target and target.Character and val then
			target.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
		end

		-- set jump power
	elseif cmd == "/jump" then
		local target = findPlayer(args[2])
		local val = tonumber(args[3])
		if target and target.Character and val then
			target.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
		end

		-- set health
	elseif cmd == "/health" then
		local target = findPlayer(args[2])
		local val = tonumber(args[3])
		if target and target.Character and val then
			target.Character:FindFirstChildOfClass("Humanoid").Health = val
		end

		-- mute (placeholder, doesn’t really mute — just connects and waits)
	elseif cmd == "/mute" then
		local target = findPlayer(args[2])
		local duration = tonumber(args[3])
		if target and duration then
			target.Chatted:Connect(function(msg)
				task.wait(duration)
			end)
		end

		-- set money
	elseif cmd == "/money" then
		local target = findPlayer(args[2])
		local val = tonumber(args[3])
		if target and val then
			setMoneyExact(target, val)
		end

		-- explode commands (specific targets or groups)
	elseif cmd == "/explode" then
		local arg = string.lower(args[2] or "")
		if arg == "everyone" then
			for _, p in ipairs(Players:GetPlayers()) do
				explodePlayer(p)
			end
		elseif arg == "notowner" then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player then
					explodePlayer(p)
				end
			end
		else
			local target = findPlayer(arg)
			if target then
				explodePlayer(target)
			end
		end

		-- fling commands (similar to explode)
	elseif cmd == "/fling" then
		local arg = string.lower(args[2] or "")
		if arg == "everyone" then
			for _, p in ipairs(Players:GetPlayers()) do
				flingPlayer(p)
			end
		elseif arg == "notowner" then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player then
					flingPlayer(p)
				end
			end
		else
			local target = findPlayer(arg)
			if target then
				flingPlayer(target)
			end
		end

		-- kick player (only if not restricted)
	elseif cmd == "/kick" and not restricted then
		local target = findPlayer(args[2])
		local reason = table.concat(args, " ", 3)
		if target then
			target:Kick(reason ~= "" and reason or "Kicked by admin")
		end

		-- ban player (temporary logic, just kicks them)
	elseif cmd == "/ban" and not restricted then
		local target = findPlayer(args[2])
		local duration = tonumber(args[3])
		if target and duration then
			target:Kick("Banned by admin")
		end

		-- shutdown server (only unrestricted admins)
	elseif cmd == "/shutdown" and not restricted then
		for _, p in ipairs(Players:GetPlayers()) do
			p:Kick("Server shutdown by admin")
		end
	end
end

-- LUGIA: hook into PlayerAdded and Chatted
-- every time a player chats, I check if it’s an admin and if they’re using a command
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		runCommand(player, msg)
	end)
end)
