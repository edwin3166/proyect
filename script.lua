local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Cargar WindUI
local WINDUI_URL = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet(WINDUI_URL))()
end)

if not success or not WindUI then
    warn("Error: No se pudo cargar WindUI.")
    return
end

--// FlyController Reforzado (EdwinDev Style + Forced Logic)
local FlyController = {}
FlyController.__index = FlyController

function FlyController.new(character)
    local self = setmetatable({}, FlyController)
    self.character = character
    self.humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    self.humanoid = character:WaitForChild("Humanoid")
    self.active = false
    self.connection = nil
    self.originalCollisions = {}
    return self
end

function FlyController:_setCollisions(enabled)
    if enabled then
        for part, canCollide in pairs(self.originalCollisions) do
            if part and part.Parent then part.CanCollide = canCollide end
        end
        self.originalCollisions = {}
    else
        for _, part in ipairs(self.character:GetDescendants()) do
            if part:IsA("BasePart") then
                if self.originalCollisions[part] == nil then
                    self.originalCollisions[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end
end

function FlyController:Stop()
    self.active = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.humanoid then
        self.humanoid.PlatformStand = false
    end
    self:_setCollisions(true)
end

function FlyController:StartForcedFly(getTargetFunc)
    self:Stop()
    self.active = true
    
    local lastValidCFrame = self.humanoidRootPart.CFrame
    
    self.connection = RunService.Heartbeat:Connect(function(dt)
        if not self.active or not self.humanoidRootPart or not self.humanoidRootPart.Parent or self.humanoid.Health <= 0 then
            self:Stop()
            return
        end

        local target = getTargetFunc()
        if not target then return end

        local targetPos = target:IsA("Model") and target:GetPivot().Position or target.Position
        local goalPosition = targetPos + Vector3.new(0, 0.5, 0)
        
        local currentPos = self.humanoidRootPart.Position
        local toGoal = goalPosition - currentPos
        local distance = toGoal.Magnitude

        -- Forzar el estado de vuelo
        self.humanoid.PlatformStand = true
        self:_setCollisions(false)

        if distance > 0.5 then
            local direction = toGoal.Unit
            -- Usar la velocidad global del slider
            local speed = _G.FlySpeed or 40
            local step = speed * dt
            
            -- Si el paso es mayor que la distancia, simplemente nos ponemos en el objetivo
            local newPos = (step >= distance) and goalPosition or (currentPos + direction * step)

            local desiredCFrame = CFrame.new(newPos, newPos + direction)
            -- Suavizado de cámara/rotación
            local smoothCFrame = lastValidCFrame:Lerp(desiredCFrame, math.clamp(dt * 10, 0, 1))
            
            self.humanoidRootPart.CFrame = smoothCFrame
            lastValidCFrame = smoothCFrame
        else
            -- Si ya estamos en el objetivo, forzamos la posición para que no se mueva
            self.humanoidRootPart.CFrame = CFrame.new(goalPosition, goalPosition + self.humanoidRootPart.CFrame.LookVector)
            lastValidCFrame = self.humanoidRootPart.CFrame
        end
    end)
end

--// Configuración de la Interfaz (EdwinDev Style)
local Window = WindUI:CreateWindow({
    Title = "1+ tongue escape",
    Icon = "plane",
    Author = "By EdwinDev",
    Folder = "FlyConfigV4",
    Theme = "Dark",
    Size = UDim2.fromOffset(450, 350),
})

local MainTab = Window:Tab({Title = "Main", Icon = "mouse-pointer-2"})

-- Inicializar controlador
local flyController = FlyController.new(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if flyController then flyController:Stop() end
    flyController = FlyController.new(newChar)
    -- Si el toggle estaba activo, reiniciamos el fly forzado en el nuevo personaje
    if _G.AutoFlyActive then
        task.wait()
        flyController:StartForcedFly(function()
            return workspace:FindFirstChild("Map")
                and workspace.Map:FindFirstChild("GiveWins")
                and workspace.Map.GiveWins:FindFirstChild("OneWin")
                and workspace.Map.GiveWins.OneWin:FindFirstChild("Button15")
        end)
    end
end)

-- Variables Globales
_G.FlySpeed = 40
_G.AutoFlyActive = false

-- SLIDER
MainTab:Slider({
    Title = "Flight Speed",
    Desc = "Adjusts the power of the scroll",
    Flag = "flySpeedSlider",
    Value = { Min = 1, Max = 1000000, Default = 40 },
    Callback = function(value)
        _G.FlySpeed = value
    end
})

-- TOGGLE FORZADO
MainTab:Toggle({
    Title = "farm wins",
    Desc = "Forced Farm (No se detiene)",
    Callback = function(state)
        _G.AutoFlyActive = state
        if state then
            flyController:StartForcedFly(function()
                return workspace:FindFirstChild("Map")
                    and workspace.Map:FindFirstChild("GiveWins")
                    and workspace.Map.GiveWins:FindFirstChild("OneWin")
                    and workspace.Map.GiveWins.OneWin:FindFirstChild("Button9")
            end)
            WindUI:Notify({Title = "Auto Farm", Content = "Modo Forzado Activado", Duration = 2})
        else
            flyController:Stop()
            WindUI:Notify({Title = "Auto Farm", Content = "Detenido", Duration = 2})
        end
    end,
})

WindUI:Notify({
    Title = "by EdwinDev",
    Content = "Fly Forzado Cargado (Resistente a interrupciones).",
    Duration = 5
})