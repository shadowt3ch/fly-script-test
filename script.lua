-- Roblox Fly Script for PC and Mobile (Executor Injection, Fixed Movement)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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
    print("Flying enabled! PC: WASD, Space, Shift. Mobile: Tap to toggle, swipe screen zones.")
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
    print("Flying disabled!")
end

-- Toggle flying
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F or (isMobile and input.UserInputType == Enum.UserInputType.Touch) then
        if flying then
            stopFlying()
        else
            startFlying()
        end
    end
end)

-- Handle movement
RunService.RenderStepped:Connect(function()
    if not flying or not bodyVelocity or not bodyGyro then return end
    local direction = Vector3.new()

    if isMobile then
        -- Mobile: Screen zones for movement
        for _, touch in pairs(User
        local touches = UserInputService:GetTouches()
        if #touches > 0 then
            local touch = touches[1]
            local touchPos = touch.Position
            local screenWidth = camera.ViewportSize.X
            local screenHeight = camera.ViewportSize.Y

            -- Left half: move left, right half: move right
            if touchPos.X < screenWidth * 0.5 then
                direction = direction - camera.CFrame.RightVector
                print("Mobile: Moving left")
            elseif touchPos.X > screenWidth * 0.5 then
                direction = direction + camera.CFrame.RightVector
                print("Mobile: Moving right")
            end

            -- Top half: ascend, bottom half: descend
            if touchPos.Y < screenHeight * 0.5 then
                direction = direction + Vector3.new(0, 1, 0)
                print("Mobile: Ascending")
            elseif touchPos.Y > screenHeight * 0.5 then
                direction = direction - Vector3.new(0, 1, 0)
                print("Mobile: Descending")
            end
        end
    else
        -- PC: Keyboard controls
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
            print("PC: Moving forward")
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
            print("PC: Moving backward")
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
            print("PC: Moving left")
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
            print("PC: Moving right")
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
            print("PC: Ascending")
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction - Vector3.new(0, 1, 0)
            print("PC: Descending")
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

print("Fly script loaded! PC: Press F to toggle, WASD/Space/Shift to move. Mobile: Tap to toggle, swipe left/right/top/bottom to move.")
