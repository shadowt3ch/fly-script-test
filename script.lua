-- Roblox Fly Script for PC and Mobile (Executor Injection)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local character = player.Character
if not character then
    print("Character not found. Waiting for character to load...")
    player.CharacterAdded:Wait()
    character = player.Character
end

local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

local flying = false
local speed = 50 -- Adjust fly speed here
local bodyVelocity = nil
local bodyGyro = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Mobile button setup
local flyButton = nil
local mobileControls = nil
local moveDirection = Vector3.new(0, 0, 0)
local ascend = false
local descend = false

-- Function to create mobile controls
local function createMobileControls()
    if not isMobile then return end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = player.PlayerGui
    ScreenGui.ResetOnSpawn = false

    -- Fly toggle button
    flyButton = Instance.new("TextButton")
    flyButton.Size = UDim2.new(0, 100, 0, 50)
    flyButton.Position = UDim2.new(0.85, 0, 0.1, 0)
    flyButton.Text = "Fly: OFF"
    flyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    flyButton.Parent = ScreenGui

    -- Ascend button
    local upButton = Instance.new("TextButton")
    upButton.Size = UDim2.new(0, 70, 0, 70)
    upButton.Position = UDim2.new(0.1, 0, 0.7, 0)
    upButton.Text = "Up"
    upButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    upButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    upButton.Parent = ScreenGui

    -- Descend button
    local downButton = Instance.new("TextButton")
    downButton.Size = UDim2.new(0, 70, 0, 70)
    downButton.Position = UDim2.new(0.1, 0, 0.85, 0)
    downButton.Text = "Down"
    downButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    downButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    downButton.Parent = ScreenGui

    -- Mobile joystick simulation (basic directional input)
    local joystickArea = Instance.new("Frame")
    joystickArea.Size = UDim2.new(0, 150, 0, 150)
    joystickArea.Position = UDim2.new(0.3, 0, 0.65, 0)
    joystickArea.BackgroundTransparency = 0.8
    joystickArea.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    joystickArea.Parent = ScreenGui

    mobileControls = {flyButton = flyButton, upButton = upButton, downButton = downButton, joystick = joystickArea}
end

-- Function to start flying
local function startFlying()
    if not character or not humanoid or not rootPart then return end
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

-- Function to stop flying
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

-- Handle PC input
local function handlePCInput(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        if flying then
            stopFlying()
        else
            startFlying()
        end
    end
end

-- Handle mobile input
local function setupMobileInput()
    if not isMobile or not mobileControls then return end
    mobileControls.flyButton.MouseButton1Click:Connect(function()
        if flying then
            stopFlying()
        else
            startFlying()
        end
    end)

    mobileControls.upButton.MouseButton1Down:Connect(function() ascend = true end)
    mobileControls.upButton.MouseButton1Up:Connect(function() ascend = false end)

    mobileControls.downButton.MouseButton1Down:Connect(function() descend = true end)
    mobileControls.downButton.MouseButton1Up:Connect(function() descend = false end)

    -- Basic joystick simulation
    local joystick = mobileControls.joystick
    local touchStart = nil
    local centerPos = nil

    UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
        if gameProcessed then return end
        local pos = touch.Position
        local joystickPos = joystick.AbsolutePosition
        local joystickSize = joystick.AbsoluteSize
        if pos.X >= joystickPos.X and pos.X <= joystickPos.X + joystickSize.X and
           pos.Y >= joystickPos.Y and pos.Y <= joystickPos.Y + joystickSize.Y then
            touchStart = pos
            centerPos = Vector2.new(joystickPos.X + joystickSize.X / 2, joystickPos.Y + joystickSize.Y / 2)
        end
    end)

    UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
        if gameProcessed or not touchStart then return end
        local delta = (touch.Position - touchStart)
        local direction = Vector2.new(delta.X, delta.Y).Unit * math.min(delta.Magnitude, 50) / 50
        moveDirection = Vector3.new(direction.X, 0, direction.Y)
    end)

    UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
        if touchStart then
            touchStart = nil
            centerPos = nil
            moveDirection = Vector3.new(0, 0, 0)
        end
    end)
end

-- Handle movement
RunService.RenderStepped:Connect(function()
    if not flying or not bodyVelocity or not bodyGyro then return end
    local direction = Vector3.new()

    if isMobile then
        direction = moveDirection
        if ascend then direction = direction + Vector3.new(0, 1, 0) end
        if descend then direction = direction - Vector3.new(0, 1, 0) end
        direction = camera.CFrame * direction -- Transform to camera space
    else
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

-- Initialize
createMobileControls()
setupMobileInput()
UserInputService.InputBegan:Connect(handlePCInput)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    if flying then
        startFlying()
    end
end)

print("Fly script loaded! PC: Press F to toggle. Mobile: Use on-screen buttons.")
