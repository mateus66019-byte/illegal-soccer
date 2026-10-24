-- language: Lua, file: IllegalSoccerController.client.lua, target: Roblox Studio
-- Coloque como LocalScript em StarterPlayer > StarterPlayerScripts.
-- Controles: F = voo, N = noclip, [ e ] = ajustar velocidade.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local DEFAULT_SPEED = 16
local MIN_SPEED = 8
local MAX_SPEED = 64
local SPEED_STEP = 4
local FLY_SPEED = 48

local state = {
    speed = DEFAULT_SPEED,
    flying = false,
    noclip = false,
}

local character
local humanoid
local root
local flyAttachment
local flyVelocity
local flyOrientation
local connections = {}

local function disconnect_all()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
end

local function stop_flight()
    state.flying = false

    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
    if flyOrientation then
        flyOrientation:Destroy()
        flyOrientation = nil
    end
    if flyAttachment then
        flyAttachment:Destroy()
        flyAttachment = nil
    end

    if humanoid then
        humanoid.AutoRotate = true
    end
end

local function bind_character(new_character)
    stop_flight()
    disconnect_all()

    character = new_character
    humanoid = character:WaitForChild("Humanoid")
    root = character:WaitForChild("HumanoidRootPart")

    humanoid.WalkSpeed = state.speed
    humanoid.PlatformStand = false

    table.insert(connections, humanoid.Died:Connect(stop_flight))
end

local function start_flight()
    if state.flying or not character or not humanoid or not root then
        return
    end

    state.flying = true
    flyAttachment = Instance.new("Attachment")
    flyAttachment.Name = "LocalFlightAttachment"
    flyAttachment.Parent = root

    flyVelocity = Instance.new("LinearVelocity")
    flyVelocity.Name = "LocalFlightVelocity"
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.MaxForce = math.huge
    flyVelocity.VectorVelocity = Vector3.zero
    flyVelocity.Parent = root

    flyOrientation = Instance.new("AlignOrientation")
    flyOrientation.Name = "LocalFlightOrientation"
    flyOrientation.Attachment0 = flyAttachment
    flyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyOrientation.MaxTorque = math.huge
    flyOrientation.Responsiveness = 20
    flyOrientation.Parent = root

    humanoid.AutoRotate = false
end

local function toggle_flight()
    if state.flying then
        stop_flight()
    else
        start_flight()
    end
end

local function adjust_speed(delta)
    state.speed = math.clamp(state.speed + delta, MIN_SPEED, MAX_SPEED)
    if humanoid then
        humanoid.WalkSpeed = state.speed
    end
end

player.CharacterAdded:Connect(bind_character)
if player.Character then
    bind_character(player.Character)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F then
        toggle_flight()
    elseif input.KeyCode == Enum.KeyCode.N then
        state.noclip = not state.noclip
    elseif input.KeyCode == Enum.KeyCode.LeftBracket then
        adjust_speed(-SPEED_STEP)
    elseif input.KeyCode == Enum.KeyCode.RightBracket then
        adjust_speed(SPEED_STEP)
    end
end)

RunService.RenderStepped:Connect(function()
    if state.noclip and character then
        for _, item in ipairs(character:GetDescendants()) do
            if item:IsA("BasePart") then
                item.CanCollide = false
            end
        end
    end

    if not state.flying or not humanoid or not root or not flyVelocity or not flyOrientation then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local direction = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction += camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction -= camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction += camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction -= camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction += Vector3.yAxis
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction -= Vector3.yAxis
    end

    if direction.Magnitude > 0 then
        direction = direction.Unit
    end

    flyVelocity.VectorVelocity = direction * FLY_SPEED
    flyOrientation.CFrame = CFrame.lookAt(Vector3.zero, camera.CFrame.LookVector)
end)
