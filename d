-- Variables
local ownerName = "Zack089232"-- Replace with the main account's username
local following = false
local viewing = false
local followTarget = nil
local viewTarget = nil
local targetPlayer = nil

-- Coordinates for the vanish position
local vanishPosition = Vector3.new(-17.674, -63.099, -40.585)
local safePosition = Vector3.new(0, 50, 0) -- Position to teleport to when health is low
local teleportPosition = Vector3.new(-100, 100, -100) -- Position to teleport to after grabbing

-- Function to get the alt player (executing player)
local function getAltPlayer()
    return game.Players.LocalPlayer
end

-- Function to teleport alt to a specified player
local function teleportAltToPlayer(playerName)
    local player = game.Players:FindFirstChild(playerName)
    if player and player.Character and player.Character.PrimaryPart then
        local altPlayer = getAltPlayer()
        if altPlayer and altPlayer.Character and altPlayer.Character.PrimaryPart then
            altPlayer.Character:SetPrimaryPartCFrame(player.Character.PrimaryPart.CFrame)
            print("Teleported alt to", playerName)
        else
            warn("Alt's character or primary part is missing.")
        end
    else
        warn("Target player's character or primary part is missing.")
    end
end

-- Function to follow the owner
local function followOwner()
    following = true
    followTarget = game.Players:FindFirstChild(ownerName)
    while following and followTarget do
        if followTarget and followTarget.Character and followTarget.Character.PrimaryPart then
            local altPlayer = getAltPlayer()
            if altPlayer and altPlayer.Character and altPlayer.Character.PrimaryPart then
                altPlayer.Character:SetPrimaryPartCFrame(followTarget.Character.PrimaryPart.CFrame * CFrame.new(2, 0, 2))
            end
        end
        wait(0.1)
    end
end

-- Function to stop following
local function stopFollowing()
    following = false
end

-- Function to enable noclip mode
local function enableNoclip()
    local altPlayer = getAltPlayer()
    if altPlayer and altPlayer.Character then
        for _, part in pairs(altPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

-- Function to disable noclip mode
local function disableNoclip()
    local altPlayer = getAltPlayer()
    if altPlayer and altPlayer.Character then
        for _, part in pairs(altPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Function to view a target player
local function viewTargetPlayer(targetName)
    local targetPlayer = game.Players:FindFirstChild(targetName)
    if targetPlayer then
        viewTarget = targetPlayer
        viewing = true
        print("Started viewing player:", targetName)
        enableNoclip()
    else
        warn("Target player not found.")
    end
end

-- Function to stop viewing
local function stopViewing()
    viewing = false
    print("Stopped viewing.")
    disableNoclip()
    game.Workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
end

-- Function to vanish the alt
local function vanishAlt()
    local altPlayer = getAltPlayer()
    if altPlayer and altPlayer.Character then
        local platform = Instance.new("Part")
        platform.Size = Vector3.new(10, 1, 10)
        platform.Anchored = true
        platform.CFrame = CFrame.new(vanishPosition - Vector3.new(0, 1, 0))
        platform.Parent = game.Workspace

        altPlayer.Character:SetPrimaryPartCFrame(CFrame.new(vanishPosition))
    end
end

-- Function to unvanish the alt
local function unvanishAlt()
    teleportAltToPlayer(ownerName)
end

-- Function to reset the alt
local function resetAlt()
    local altPlayer = getAltPlayer()
    if altPlayer and altPlayer.Character and altPlayer.Character:FindFirstChildOfClass("Humanoid") then
        altPlayer.Character:FindFirstChildOfClass("Humanoid"):TakeDamage(altPlayer.Character:FindFirstChildOfClass("Humanoid").Health)
    end
end

-- Function to kick the alt
local function kickAlt()
    local altPlayer = getAltPlayer()
    if altPlayer then
        altPlayer:Kick("Why did you do that for?")
    end
end

-- Function to find the owner player and check if they are knocked out
local function findOwnerPlayer()
    targetPlayer = game.Players:FindFirstChild(ownerName)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and 
       targetPlayer.Character.BodyEffects:FindFirstChild("K.O") and targetPlayer.Character.BodyEffects["K.O"].Value == true then
        print("Found knocked-out owner player:", ownerName)
        return true
    else
        print("Owner player not found or not knocked out.")
        targetPlayer = nil
        return false
    end
end

-- Function to start grabbing the owner player
local function startGrabbing()
    if not targetPlayer then
        print("No knocked-out player to grab.")
        return
    end

    local LocalPlayer = game.Players.LocalPlayer
    local Character = LocalPlayer.Character
    game.Workspace.CurrentCamera.CameraSubject = targetPlayer.Character.Humanoid

    repeat
        task.wait()
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, -5, 0)
    until targetPlayer.Character.BodyEffects:FindFirstChild("K.O").Value == true

    repeat
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
        if not targetPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT") then
            game:GetService("ReplicatedStorage").MainEvent:FireServer("Grabbing", false)
        end
        task.wait(0.2)
    until targetPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT")

    -- Teleport the local player to the specified coordinates
    LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(teleportPosition))

    -- Reset the camera to the local player
    game.Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid

    print("Grab and teleport completed.")

    -- Wait 2 seconds then reset the alt
    task.wait(2)
    resetAlt()
end

-- Function to monitor the alt's health
local function monitorAltHealth()
    local altPlayer = getAltPlayer()
    if altPlayer and altPlayer.Character and altPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = altPlayer.Character:FindFirstChildOfClass("Humanoid")
        humanoid.HealthChanged:Connect(function(health)
            if health / humanoid.MaxHealth < 0.03 then
                -- Health is below 3%, teleport to safe position
                altPlayer.Character:SetPrimaryPartCFrame(CFrame.new(safePosition))
                print("Teleported alt to safe position.")
            end
        end)
    end
end

-- Function to monitor the owner's health
local function monitorOwnerHealth()
    while true do
        if findOwnerPlayer() then
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") then
                local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid.Health / humanoid.MaxHealth < 0.03 then
                    -- Health is below 3%, perform the grabbing and teleporting actions
                    startGrabbing()
                end
            end
        end
        task.wait(1) -- Check every 1 second
    end
end

-- Chat command listener
local function onChatted(player, msg)
    if player.Name == ownerName then
        local cmd, arg = msg:lower():match("^(%S+)%s*(.*)$")

        if cmd == ".tpalt" and arg then
            teleportAltToPlayer(arg)
        elseif cmd == "s" then
            followOwner()
        elseif cmd == "unfollow!" then
            stopFollowing()
        elseif cmd == "rejoin!" then
            game:GetService("TeleportService"):Teleport(game.PlaceId, player)
        elseif cmd == ".view" and arg then
            viewTargetPlayer(arg)
        elseif cmd == ".unview" then
            stopViewing()
        elseif cmd == "vanish!" then
            vanishAlt()
        elseif cmd == "unvanish!" then
            unvanishAlt()
        elseif cmd == "reset!" then
            resetAlt()
        elseif cmd == "kick!" then
            kickAlt()
        elseif cmd == "grabme!" then
            startGrabbing()
            monitorOwnerHealth() -- Start monitoring owner's health when grabme! is called
        end
    end
end

-- Setup listeners for existing and new players
local function setupPlayer(player)
    if player.Name == ownerName then
        player.Chatted:Connect(function(msg)
            onChatted(player, msg)
        end)
    end
end

-- Monitor alt's health
monitorAltHealth()

-- Connect listeners for current and future players
for _, player in ipairs(game.Players:GetPlayers()) do
    setupPlayer(player)
end
game.Players.PlayerAdded:Connect(setupPlayer)
