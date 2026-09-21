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

local RunService = game:GetService("RunService")

-- Cargar WindUI (versión nueva, código fuente)
local WINDUI_URL = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet(WINDUI_URL))()
end)

if not success or not WindUI then
    warn("Error: No se pudo cargar WindUI.")
    return
end

--// FlyController Reforzado (EdwinDev Style + Forced Logic)
local SessionStats = {
    ActiveSeconds = 0,
    LastCheck = os.clock(),
    DistanceFlown = 0,
    StartWins = 0,
    WinsStat = nil,
    ReachedCount = 0,
}

task.spawn(function()
    local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
    local winsStat = leaderstats and leaderstats:FindFirstChild("Wins")
    if winsStat then
        SessionStats.WinsStat = winsStat
        SessionStats.StartWins = winsStat.Value
    end
end)

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
    self.collisionParts = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            self.collisionParts[#self.collisionParts + 1] = part
        end
    end
    self.collisionsDisabled = false
    self.hasReachedTarget = false
    return self
end

function FlyController:_setCollisions(enabled)
    if enabled == (not self.collisionsDisabled) then return end

    if enabled then
        for part, canCollide in pairs(self.originalCollisions) do
            if part and part.Parent then part.CanCollide = canCollide end
        end
        table.clear(self.originalCollisions)
        self.collisionsDisabled = false
        return
    end

    for _, part in ipairs(self.collisionParts) do
        if part.Parent then
            self.originalCollisions[part] = part.CanCollide
            part.CanCollide = false
        end
    end
    self.collisionsDisabled = true
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

        local goalPosition = target:IsA("Model") and target:GetPivot().Position or target.Position

        local currentPos = self.humanoidRootPart.Position
        local toGoal = goalPosition - currentPos
        local distance = toGoal.Magnitude

        -- Forzar el estado de vuelo
        if not self.humanoid.PlatformStand then
            self.humanoid.PlatformStand = true
        end
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
            SessionStats.DistanceFlown = SessionStats.DistanceFlown + (smoothCFrame.Position - currentPos).Magnitude
            self.hasReachedTarget = false
        else
            self.humanoidRootPart.CFrame = CFrame.new(goalPosition, goalPosition + self.humanoidRootPart.CFrame.LookVector)
            lastValidCFrame = self.humanoidRootPart.CFrame
            if not self.hasReachedTarget then
                self.hasReachedTarget = true
                SessionStats.ReachedCount = SessionStats.ReachedCount + 1
            end
        end
    end)
end

--// Configuración de la Interfaz (WindUI nuevo)
local Window = WindUI:CreateWindow({
    Title = "Admin Panel",
    Icon = "solar:plain-2-bold",
    Author = "By EdwinDev",
    Folder = "FlyConfigV4",
    Theme = "Dark",
    Size = UDim2.fromOffset(450, 350),
    NewElements = true,

    OpenButton = {
        Title = "Abrir Panel",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
    },

    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

local MainTab = Window:Tab({ Title = "Main", Icon = "mouse-pointer-2", Opened = true })

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

-- SLIDER
MainTab:Slider({
    Title = "Flight Speed",
    Desc = "Adjusts the power of the scroll",
    Flag = "flySpeedSlider",
    Value = { Min = 1, Max = 1000000, Default = 40 },
    Callback = function(value)
        _G.FlySpeed = value
    end,
})

-- TOGGLE FORZADO
MainTab:Toggle({
    Title = "Fly dev",
    Desc = "Dev",
    Callback = function(state)
        _G.AutoFlyActive = state
        if state then
            flyController:StartForcedFly(function()
                return workspace:FindFirstChild("Map")
                    and workspace.Map:FindFirstChild("GiveWins")
                    and workspace.Map.GiveWins:FindFirstChild("OneWin")
                    and workspace.Map.GiveWins.OneWin:FindFirstChild("Button15")
            end)
            WindUI:Notify({ Title = "Auto Farm", Content = "Modo Forzado Activado", Duration = 2 })
        else
            flyController:Stop()
            WindUI:Notify({ Title = "Auto Farm", Content = "Detenido", Duration = 2 })
        end
    end,
})

--// MISC TAB — Perfil + Contador de ejecuciones activas
local MiscTab = Window:Tab({ Title = "Misc", Icon = "users" })

-- Perfil del usuario actual (nombre + avatar)
do
    local thumbOk, thumbContent = pcall(function()
        local content = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
        return content
    end)

    local profileParams = {
        Title = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")",
        Desc = "UserId: " .. tostring(LocalPlayer.UserId),
    }
    if thumbOk and thumbContent then
        profileParams.Image = thumbContent
    end

    local createdOk = pcall(function()
        MiscTab:Paragraph(profileParams)
    end)
    if not createdOk then
        -- Fallback por si esta build no acepta el campo Image en Paragraph
        MiscTab:Paragraph({
            Title = profileParams.Title,
            Desc = profileParams.Desc,
        })
    end
end

local COUNTAPI_NAMESPACE = "givewins-fly-v4"
local COUNTAPI_KEY = "active-users"

-- Estadísticas de la sesión
local statsLabel = MiscTab:Paragraph({
    Title = "Estadísticas",
    Desc = "Cargando...",
})

local function formatDuration(seconds)
    local totalSeconds = math.floor(seconds)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local secs = totalSeconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function refreshStats()
    local flyState = _G.AutoFlyActive and "Activo" or "Inactivo"

    local winsLine
    local currentWinsLine
    if SessionStats.WinsStat then
        local gained = SessionStats.WinsStat.Value - SessionStats.StartWins
        winsLine = "Wins ganadas desde que ejecuté: " .. tostring(math.max(gained, 0))
        currentWinsLine = "Wins actuales: " .. tostring(SessionStats.WinsStat.Value)
    else
        winsLine = "Wins ganadas (aprox., veces llegado al botón): " .. tostring(SessionStats.ReachedCount)
        currentWinsLine = "Wins actuales: no disponible"
    end

    local lines = {
        "Tiempo de fly activo: " .. formatDuration(SessionStats.ActiveSeconds),
        "Estado del Fly: " .. flyState,
        "Velocidad actual: " .. tostring(_G.FlySpeed or 40),
        "Distancia recorrida: " .. string.format("%.0f studs", SessionStats.DistanceFlown),
        currentWinsLine,
        winsLine,
        "Antigüedad de cuenta: " .. tostring(LocalPlayer.AccountAge) .. " días",
    }
    statsLabel:SetDesc(table.concat(lines, "\n"))
end

task.spawn(function()
    while true do
        local now = os.clock()
        local delta = now - SessionStats.LastCheck
        SessionStats.LastCheck = now
        if _G.AutoFlyActive then
            SessionStats.ActiveSeconds = SessionStats.ActiveSeconds + delta
        end
        refreshStats()
        task.wait(1)
    end
end)

local activeCountLabel = MiscTab:Paragraph({
    Title = "Usuarios ejecutando ahora",
    Desc = "Cargando...",
})

local HttpService = game:GetService("HttpService")
local hasIncremented = false

local function safeHttpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then return nil end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(result)
    end)
    if decodeOk then return decoded end
    return nil
end

local function incrementActiveCount()
    local data = safeHttpGet(("https://api.countapi.xyz/hit/%s/%s"):format(COUNTAPI_NAMESPACE, COUNTAPI_KEY))
    if data and data.value then
        hasIncremented = true
        return data.value
    end
    return nil
end

local function decrementActiveCount()
    if not hasIncremented then return end
    safeHttpGet(("https://api.countapi.xyz/hit/%s/%s?amount=-1"):format(COUNTAPI_NAMESPACE, COUNTAPI_KEY))
    hasIncremented = false
end

local function getActiveCount()
    local data = safeHttpGet(("https://api.countapi.xyz/get/%s/%s"):format(COUNTAPI_NAMESPACE, COUNTAPI_KEY))
    if data and data.value then
        return data.value
    end
    return nil
end

local function refreshLabel()
    local count = getActiveCount()
    if count then
        activeCountLabel:SetDesc(("%d personas ejecutando el script ahora"):format(math.max(count, 0)))
    else
        activeCountLabel:SetDesc("No se pudo obtener el dato")
    end
end

task.spawn(function()
    incrementActiveCount()
    refreshLabel()
    while true do
        task.wait(10)
        refreshLabel()
    end
end)

-- Colores disponibles para acento e iconos
local colorPalette = {
    { Name = "Amarillo", Color = Color3.fromHex("#E3B341") },
    { Name = "Azul",     Color = Color3.fromHex("#5B8DEF") },
    { Name = "Rojo",     Color = Color3.fromHex("#E5484D") },
    { Name = "Verde",    Color = Color3.fromHex("#30A46C") },
    { Name = "Morado",   Color = Color3.fromHex("#8B5CF6") },
    { Name = "Naranja",  Color = Color3.fromHex("#F5A524") },
    { Name = "Rosa",     Color = Color3.fromHex("#D6409F") },
    { Name = "Cian",     Color = Color3.fromHex("#23A9C4") },
}

-- Colores disponibles para el fondo del panel
local backgroundPalette = {
    { Name = "Negro",         Color = Color3.fromHex("#0D0D0F") },
    { Name = "Gris Oscuro",   Color = Color3.fromHex("#151518") },
    { Name = "Azul Oscuro",   Color = Color3.fromHex("#0B1220") },
    { Name = "Verde Oscuro",  Color = Color3.fromHex("#0B1710") },
    { Name = "Morado Oscuro", Color = Color3.fromHex("#140B1F") },
    { Name = "Rojo Oscuro",   Color = Color3.fromHex("#1F0B0E") },
}

local function findColor(list, name)
    for _, entry in ipairs(list) do
        if entry.Name == name then return entry.Color end
    end
    return list[1].Color
end

local currentAccentName = "Azul"
local currentIconName = "Azul"
local currentBackgroundName = "Negro"

local function applyDynamicTheme()
    local accent = findColor(colorPalette, currentAccentName)
    local iconColor = findColor(colorPalette, currentIconName)
    local bg = findColor(backgroundPalette, currentBackgroundName)

    local themeTable = {
        Name = "Personalizado",
        Accent = accent,
        Dialog = Color3.fromHex("#18181b"),
        Outline = accent,
        Text = Color3.fromHex("#EDEDEF"),
        Placeholder = Color3.fromHex("#71717A"),
        Background = bg,
        Button = Color3.fromHex("#232326"),
        Icon = iconColor,
    }

    local addOk = pcall(function()
        WindUI:AddTheme(themeTable)
    end)
    if addOk then
        pcall(function()
            WindUI:SetTheme("Personalizado")
        end)
    else
        WindUI:Notify({
            Title = "Tema",
            Content = "No se pudo aplicar el tema personalizado en esta build.",
            Duration = 3,
        })
    end
end

local accentNames, iconNames, bgNames = {}, {}, {}
for _, entry in ipairs(colorPalette) do
    table.insert(accentNames, entry.Name)
    table.insert(iconNames, entry.Name)
end
for _, entry in ipairs(backgroundPalette) do
    table.insert(bgNames, entry.Name)
end

MiscTab:Dropdown({
    Title = "Color de acento",
    Desc = "Color principal de botones, sliders y bordes",
    Values = accentNames,
    Default = currentAccentName,
    Callback = function(name)
        currentAccentName = name
        applyDynamicTheme()
    end,
})

MiscTab:Dropdown({
    Title = "Color de iconos",
    Desc = "Color de los íconos de la interfaz",
    Values = iconNames,
    Default = currentIconName,
    Callback = function(name)
        currentIconName = name
        applyDynamicTheme()
    end,
})

MiscTab:Dropdown({
    Title = "Color de fondo",
    Desc = "Color de fondo del panel",
    Values = bgNames,
    Default = currentBackgroundName,
    Callback = function(name)
        currentBackgroundName = name
        applyDynamicTheme()
    end,
})

applyDynamicTheme()

-- Best effort: descontar al salir del juego o al cerrarse el cliente
Players.PlayerRemoving:Connect(function(plr)
    if plr == LocalPlayer then
        decrementActiveCount()
    end
end)

pcall(function()
    game:BindToClose(function()
        decrementActiveCount()
    end)
end)

WindUI:Notify({
    Title = "by EdwinDev",
    Content = "Fly Forzado Cargado (Resistente a interrupciones).",
    Duration = 5,
})
