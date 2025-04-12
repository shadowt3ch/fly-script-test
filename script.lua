-- Roblox Fly Script for PC and Mobile (Executor Injection, Fixed GUI)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local character = player.Character
if not character then
    print("Waiting for character...")
    player.CharacterAdded:Wait()
    character = player.Character
end

local humanoid = character:WaitForChild("Humanoid", 5)
local rootPart = character:WaitForChild("HumanoidRootPart", 5)
local camera = workspace.CurrentCamera

if not humanoid or not rootPart then
    error("Failed to find humanoid or root part!")
    return
end

local flying = false
local speed = 50 -- Adjust fly speed here
local bodyVelocity = nil
local bodyGyro = nil
local isMobile = UserInputService.TouchEnabled
local flyButton = nil

-- Create minimal GUI for mobile
local function createMobileGUI()
    if not isMobile then return end
    local success, err = pcall(function()
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Parent = player.PlayerGui
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Name = "FlyGUI"

        flyButton = Instance.new("TextButton")
        flyButton.Size = UDim2.new(0, 120, 0, 60)
        flyButton.Position = UDim2.new(0.8, 0, 0.05, 0)
        flyButton.Text = "Fly: OFF"
        flyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        flyButton.TextScaled = true
        flyButton.Parent = ScreenGui
    end)
    if not success then
        print("GUI creation failed: " .. tostring(err))
    else
        print("Mobile GUI loaded!")
    end
end

-- Start flying
local function startFlying()
    if not character or not humanoid or not rootPart then
        print("Cannot fly: character not ready")
        return
    end
    flying = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart

    humanoid.PlatformStand = true
    if flyButton then flyButton.Text = "Fly: ON" end
    print("Flying enabled!")
end

-- Stop flying
local function stopFlying()
    flying = false
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    humanoid.PlatformStand = false
    if flyButton then flyButton.Text = "Fly: OFF" end
    print("Flying disabled!")
end

-- Handle input
local function setupInput()
    -- PC: Toggle with F
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F then
            if flying then
                stopFlying()
            else
                startFlying()
            end
        end
    end)

    -- Mobile: Toggle with button
    if flyButton then
        local success, err = pcall(function()
            flyButton.MouseButton1Click:Connect(function()
                if flying then
                    stopFlying()
                else
                    startFlying()
                end
            end)
        end)
        if not success then
            print("Button binding failed: " .. tostring(err))
        end
    end
end

-- Handle movement
RunService.RenderStepped:Connect(function()
    if not flying or not bodyVelocity or not bodyGyro then return end
    local direction = Vector3.new()

    if isMobile then
        -- Mobile: Touch-based movement
        for _, touch in pairs(UserInputService:GetTouches()) do
            local touchPos = touch.Position
            local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            local delta = Vector2.new(touchPos.X - screenCenter.X, touchPos.Y - screenCenter.Y)
            if delta.Magnitude > 50 then
                direction = direction + Vector3.new(delta.X / 500, -delta.Y / 500, delta.X / 500)
            end
        end
    else
        -- PC: Keyboard controls
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction - Vector3.new(0, 1, 0)
        end
    end

    if direction.Magnitude > 0 then
        direction = direction.Unit * speed
    else
        direction = Vector3.new(0, 0, 0)
    end
    bodyVelocity.Velocity = direction
    bodyGyro.CFrame = camera.CFrame
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid", 5)
    rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if flying then
        startFlying()
    end
end)

-- Initialize
createMobileGUI()
setupInput()
print("Fly script loaded! PC: Press F to toggle. Mobile: Tap button or screen to fly.")
