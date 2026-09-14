if game.PlaceId ~= 122245938604556 then
	warn("❌ Este script solo funciona en 1+ tongue escape(PlaceId: 122245938604556)")
	return
end

-- ======================================================
-- Anti-AFK Mejorado (siempre activo + sin cámara)
-- ======================================================
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local MinInterval = 40
local MaxInterval = 70

local function DoAntiAFK()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end

LocalPlayer.Idled:Connect(function()
	DoAntiAFK()
end)

task.spawn(function()
	while true do
		task.wait(math.random(MinInterval, MaxInterval))
		DoAntiAFK()
	end
end)

print("✅ Anti-AFK activado permanentemente")

-- ======================================================
-- Anti-Kick + Protección extra (siempre activo)
-- ======================================================
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall

setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
	local method = getnamecallmethod()
	local args = {...}

	if method == "Kick" and self == LocalPlayer then
		return
	end

	-- Bloquea FireServer de remotes sospechosos de kick/ban
	if method == "FireServer" then
		local remoteName = tostring(self.Name):lower()
		if remoteName:find("kick") or remoteName:find("ban") or remoteName:find("moderate") or remoteName:find("punish") then
			return
		end
	end

	return oldNamecall(self, ...)
end)

setreadonly(mt, true)

print("✅ Anti-Kick completo cargado")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--[[ WindUI Example Adapted for EdwinDev ]]
local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local HttpService = cloneref(game:GetService("HttpService"))

local WindUI
do
    local ok, result = pcall(function() return require("./src/Init") end)
    if ok then
        WindUI = result
    else
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
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
        local goalPosition = targetPos + Vector3.new(0, 0, 0)
        
        local currentPos = self.humanoidRootPart.Position
        local toGoal = goalPosition - currentPos
        local distance = toGoal.Magnitude

        -- Forzar el estado de vuelo
        self.humanoid.PlatformStand = true
        self:_setCollisions(false)

        if distance > 0.5 then
            local direction = toGoal.Unit
            local speed = _G.FlySpeed or 40
            local step = speed * dt
            
            local newPos = (step >= distance) and goalPosition or (currentPos + direction * step)
            local desiredCFrame = CFrame.new(newPos, newPos + direction)
            local smoothCFrame = lastValidCFrame:Lerp(desiredCFrame, math.clamp(dt * 10, 0, 1))
            
            self.humanoidRootPart.CFrame = smoothCFrame
            lastValidCFrame = smoothCFrame
        else
            self.humanoidRootPart.CFrame = CFrame.new(goalPosition, goalPosition + self.humanoidRootPart.CFrame.LookVector)
            lastValidCFrame = self.humanoidRootPart.CFrame
        end
    end)
end

-- */ Window /* --
local Window = WindUI:CreateWindow({
    Title = "1+ tongue escape",
    Author = "by EdwinDev",
    Folder = "EdwinDevHub",
    Icon = "solar:folder-2-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open EdwinDev UI",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"),
            Color3.fromHex("#e7ff2f")
        ),
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

-- */ Tags /* --
do
    Window:Tag({
        Title = "v" .. WindUI.Version,
        Icon = "github",
        Color = Color3.fromHex("#1c1c1c"),
        Border = true,
    })
end

-- */ Elements Section /* --
local ElementsSection = Window:Section({
    Title = "Elements",
})

-- */ Main Tab /* --
do
    local MainTab = ElementsSection:Tab({
        Title = "Main",
        Icon = "solar:home-2-bold",
        IconColor = Color3.fromHex("#83889E"),
        IconShape = "Square",
        Border = true,
    })

    -- Inicializar controlador
    local flyController = FlyController.new(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        if flyController then flyController:Stop() end
        flyController = FlyController.new(newChar)
        if _G.AutoFlyActive then
            task.wait(0.5)
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

    local MainSection = MainTab:Section({
        Title = "Farm Controls",
    })

    MainSection:Slider({
        Title = "Flight Speed",
        Desc = "Adjusts the power of the scroll",
        Flag = "flySpeedSlider",
        Value = { Min = 1, Max = 1000000, Default = 40 },
        Callback = function(value)
            _G.FlySpeed = value
        end
    })

    MainSection:Toggle({
        Title = "farm wins",
        Desc = "Forced Farm (No se detiene)",
        Callback = function(state)
            _G.AutoFlyActive = state
            if state then
                flyController:StartForcedFly(function()
                    return workspace:FindFirstChild("Map")
                        and workspace.Map:FindFirstChild("GiveWins")
                        and workspace.Map.GiveWins:FindFirstChild("OneWin")
                        and workspace.Map.GiveWins.OneWin:FindFirstChild("Button15")
                end)
                WindUI:Notify({Title = "Auto Farm", Content = "Modo Forzado Activado", Duration = 2})
            else
                flyController:Stop()
                WindUI:Notify({Title = "Auto Farm", Content = "Detenido", Duration = 2})
            end
        end,
    })
end

-- */ About Tab /* --
do
    local AboutTab = Window:Tab({
        Title = "About",
        Icon = "solar:info-square-bold",
        IconColor = Color3.fromHex("#83889E"),
        IconShape = "Square",
        Border = true,
    })

    local AboutSection = AboutTab:Section({
        Title = "EdwinDev Hub",
    })

    AboutSection:Section({
        Title = "1+ tongue escape",
        TextSize = 24,
        FontWeight = Enum.FontWeight.SemiBold,
    })

    AboutSection:Space()

    AboutSection:Section({
        Title = "Custom Script Hub developed by EdwinDev.\nOptimized for forced flight and automated farming.",
        TextSize = 18,
        TextTransparency = 0.35,
        FontWeight = Enum.FontWeight.Medium,
    })

    AboutTab:Button({
        Title = "Destroy Window",
        Color = Color3.fromHex("#ff4830"),
        Justify = "Center",
        Icon = "shredder",
        IconAlign = "Left",
        Callback = function()
            Window:Destroy()
        end,
    })
end

WindUI:Notify({
    Title = "by EdwinDev",
    Content = "Interface Adapted to WindUI v2 Format.",
    Duration = 5
})
