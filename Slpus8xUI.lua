--[[
    Slpus8xUI v1.0.0
    Biblioteca de interface (UI) para Roblox
    Criada por slpus8x

    Recursos:
      - Janela arrastavel, minimizar, fechar, tecla para abrir/fechar
      - Botao flutuante para celular
      - Abas (com icone opcional)
      - Elementos: Section, Label, Paragraph, Button, Toggle, Slider,
        Dropdown (simples e multi), TextBox, Keybind, ColorPicker
      - Notificacoes
      - Temas (Dark, Ocean, Rose, Light)
      - Salvar / carregar configuracoes (Flags)

    Uso rapido:
      local Slpus8xUI = loadstring(game:HttpGet("LINK_RAW"))()
      local Window = Slpus8xUI:CreateWindow({ Title = "Meu Hub", Subtitle = "v1" })
      local Tab = Window:CreateTab("Principal")
      Tab:CreateButton({ Name = "Oi", Callback = function() print("oi") end })
]]

local Slpus8xUI = {
    Version = "1.0.0",
    Flags = {},
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------
-- TEMAS
--------------------------------------------------------------------
local Themes = {
    Dark = {
        Background = Color3.fromRGB(16, 16, 22),
        Topbar = Color3.fromRGB(22, 22, 30),
        Sidebar = Color3.fromRGB(19, 19, 26),
        Element = Color3.fromRGB(28, 28, 38),
        ElementHover = Color3.fromRGB(36, 36, 49),
        Accent = Color3.fromRGB(124, 92, 255),
        Text = Color3.fromRGB(240, 240, 248),
        SubText = Color3.fromRGB(150, 150, 168),
        Stroke = Color3.fromRGB(44, 44, 60),
        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(240, 180, 60),
        Error = Color3.fromRGB(235, 80, 90),
    },
    Ocean = {
        Background = Color3.fromRGB(12, 20, 30),
        Topbar = Color3.fromRGB(16, 28, 42),
        Sidebar = Color3.fromRGB(14, 24, 36),
        Element = Color3.fromRGB(21, 36, 54),
        ElementHover = Color3.fromRGB(28, 47, 70),
        Accent = Color3.fromRGB(40, 170, 255),
        Text = Color3.fromRGB(235, 245, 255),
        SubText = Color3.fromRGB(140, 165, 190),
        Stroke = Color3.fromRGB(36, 58, 84),
        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(240, 180, 60),
        Error = Color3.fromRGB(235, 80, 90),
    },
    Rose = {
        Background = Color3.fromRGB(24, 14, 20),
        Topbar = Color3.fromRGB(32, 18, 27),
        Sidebar = Color3.fromRGB(28, 16, 23),
        Element = Color3.fromRGB(40, 24, 33),
        ElementHover = Color3.fromRGB(52, 31, 43),
        Accent = Color3.fromRGB(255, 80, 140),
        Text = Color3.fromRGB(250, 238, 244),
        SubText = Color3.fromRGB(175, 145, 160),
        Stroke = Color3.fromRGB(66, 40, 54),
        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(240, 180, 60),
        Error = Color3.fromRGB(235, 80, 90),
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 246),
        Topbar = Color3.fromRGB(230, 230, 238),
        Sidebar = Color3.fromRGB(235, 235, 243),
        Element = Color3.fromRGB(251, 251, 254),
        ElementHover = Color3.fromRGB(240, 240, 248),
        Accent = Color3.fromRGB(95, 70, 235),
        Text = Color3.fromRGB(25, 25, 36),
        SubText = Color3.fromRGB(100, 100, 122),
        Stroke = Color3.fromRGB(208, 208, 222),
        Success = Color3.fromRGB(40, 160, 90),
        Warning = Color3.fromRGB(210, 150, 30),
        Error = Color3.fromRGB(215, 55, 70),
    },
}

Slpus8xUI.Themes = Themes
Slpus8xUI.Theme = Themes.Dark

--------------------------------------------------------------------
-- FUNCOES AUXILIARES
--------------------------------------------------------------------
local function New(class, props)
    local inst = Instance.new(class)
    if inst:IsA("GuiObject") then
        inst.BorderSizePixel = 0
    end
    if inst:IsA("GuiButton") then
        inst.AutoButtonColor = false
    end
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then
            parent = v
        else
            inst[k] = v
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function Corner(parent, radius)
    local r = UDim.new(0, radius or 6)
    if radius == "full" then
        r = UDim.new(1, 0)
    end
    return New("UICorner", { CornerRadius = r, Parent = parent })
end

local function Tween(obj, props, time, style, direction)
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

local function Animate(obj, props, instant, time)
    if instant then
        for k, v in pairs(props) do
            obj[k] = v
        end
    else
        Tween(obj, props, time)
    end
end

local function Safe(fn, ...)
    if type(fn) ~= "function" then
        return
    end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[Slpus8xUI] Erro no callback: " .. tostring(err))
    end
end

local function IsPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function ParentGui(gui)
    local placed = false
    if type(gethui) == "function" then
        placed = pcall(function()
            gui.Parent = gethui()
        end)
    end
    if not placed or not gui.Parent then
        placed = pcall(function()
            gui.Parent = CoreGui
        end)
    end
    if not placed or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function RemoveOld(name)
    local places = {}
    pcall(function()
        if type(gethui) == "function" then
            places[#places + 1] = gethui()
        end
    end)
    places[#places + 1] = CoreGui
    pcall(function()
        places[#places + 1] = LocalPlayer:FindFirstChild("PlayerGui")
    end)
    for _, place in ipairs(places) do
        pcall(function()
            local old = place:FindFirstChild(name)
            if old then
                old:Destroy()
            end
        end)
    end
end

local function MakeDraggable(handle, target, connect)
    local state = { Moved = false }
    local dragging = false
    local dragStart, startPos, dragInput

    handle.InputBegan:Connect(function(input)
        if IsPointer(input) then
            dragging = true
            state.Moved = false
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if IsMove(input) then
            dragInput = input
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then
                state.Moved = true
            end
            if state.Moved then
                target.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    return state
end

local function Register(flag, obj)
    if flag then
        Slpus8xUI.Flags[flag] = obj
    end
end

--------------------------------------------------------------------
-- NOTIFICACOES
--------------------------------------------------------------------
local NotifyGui, NotifyHolder
local notifyOrder = 0

local function EnsureNotify()
    if NotifyGui and NotifyGui.Parent then
        return
    end
    RemoveOld("Slpus8xUI_Notify")
    NotifyGui = New("ScreenGui", {
        Name = "Slpus8xUI_Notify",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 200,
    })
    ParentGui(NotifyGui)
    NotifyHolder = New("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 270, 1, -32),
        BackgroundTransparency = 1,
        Parent = NotifyGui,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Parent = NotifyHolder,
    })
end

-- cfg: Title, Content, Duration (segundos), Type ("Info", "Success", "Warning", "Error")
function Slpus8xUI:Notify(cfg)
    cfg = cfg or {}
    EnsureNotify()

    local th = Slpus8xUI.Theme
    local duration = cfg.Duration or 4
    local colors = { Info = th.Accent, Success = th.Success, Warning = th.Warning, Error = th.Error }
    local accent = colors[cfg.Type or "Info"] or th.Accent

    notifyOrder = notifyOrder + 1
    local Wrapper = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = notifyOrder,
        Parent = NotifyHolder,
    })
    local Card = New("TextButton", {
        Position = UDim2.new(1, 30, 0, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = th.Element,
        Text = "",
        Parent = Wrapper,
    })
    Corner(Card, 8)
    New("UIStroke", {
        Color = th.Stroke,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Card,
    })
    local Bar = New("Frame", {
        Size = UDim2.new(0, 3, 1, -12),
        Position = UDim2.fromOffset(6, 6),
        BackgroundColor3 = accent,
        Parent = Card,
    })
    Corner(Bar, "full")

    local Content = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = Card,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 18),
        PaddingRight = UDim.new(0, 12),
        Parent = Content,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Content,
    })

    New("TextLabel", {
        LayoutOrder = 1,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextColor3 = th.Text,
        Text = cfg.Title or "Slpus8xUI",
        Parent = Content,
    })
    if cfg.Content and cfg.Content ~= "" then
        New("TextLabel", {
            LayoutOrder = 2,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            TextColor3 = th.SubText,
            Text = cfg.Content,
            Parent = Content,
        })
    end

    local Track = New("Frame", {
        LayoutOrder = 3,
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = th.Stroke,
        Parent = Content,
    })
    Corner(Track, "full")
    local Fill = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = accent,
        Parent = Track,
    })
    Corner(Fill, "full")

    local dismissed = false
    local function dismiss()
        if dismissed then
            return
        end
        dismissed = true
        local t = Tween(Card, { Position = UDim2.new(1, 30, 0, 0) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function()
            Wrapper:Destroy()
        end)
    end

    Card.MouseButton1Click:Connect(dismiss)
    Tween(Card, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back)
    Tween(Fill, { Size = UDim2.fromScale(0, 1) }, duration, Enum.EasingStyle.Linear)
    task.delay(duration, dismiss)
end

--------------------------------------------------------------------
-- JANELA
--------------------------------------------------------------------
-- cfg: Title, Subtitle, Size (UDim2), Theme, ToggleKey (Enum.KeyCode),
--      ConfigFolder, FloatButton (true/false), FloatText, FloatBorderColor (Color3)
function Slpus8xUI:CreateWindow(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "Slpus8xUI"
    local subtitle = cfg.Subtitle or ""
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local size = cfg.Size or (isMobile and UDim2.fromOffset(440, 270) or UDim2.fromOffset(580, 380))
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
    local configFolder = cfg.ConfigFolder or "Slpus8xUI"
    local sidebarWidth = isMobile and 112 or 140

    if cfg.Theme and Themes[cfg.Theme] then
        Slpus8xUI.Theme = Themes[cfg.Theme]
    end

    RemoveOld("Slpus8xUI")

    local Window = { Tabs = {}, Visible = false, Minimized = false, Flags = Slpus8xUI.Flags }
    local Connections = {}
    local Themed = {}
    local Refreshers = {}

    local function Connect(signal, fn)
        local c = signal:Connect(fn)
        Connections[#Connections + 1] = c
        return c
    end

    local function Theme(inst, prop, key)
        inst[prop] = Slpus8xUI.Theme[key]
        Themed[#Themed + 1] = { inst, prop, key }
        return inst
    end

    local function ApplyTheme()
        local th = Slpus8xUI.Theme
        local i = 1
        while i <= #Themed do
            local e = Themed[i]
            if e[1].Parent == nil then
                table.remove(Themed, i)
            else
                e[1][e[2]] = th[e[3]]
                i = i + 1
            end
        end
        for _, fn in ipairs(Refreshers) do
            pcall(fn)
        end
    end

    local function Hover(obj)
        obj.MouseEnter:Connect(function()
            Tween(obj, { BackgroundColor3 = Slpus8xUI.Theme.ElementHover }, 0.12)
        end)
        obj.MouseLeave:Connect(function()
            Tween(obj, { BackgroundColor3 = Slpus8xUI.Theme.Element }, 0.12)
        end)
    end

    local function Lbl(parent, text, colorKey, props)
        local l = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = parent,
        })
        if props then
            for k, v in pairs(props) do
                l[k] = v
            end
        end
        Theme(l, "TextColor3", colorKey or "Text")
        return l
    end

    ----------------------------------------------------------------
    -- Estrutura principal
    ----------------------------------------------------------------
    local Gui = New("ScreenGui", {
        Name = "Slpus8xUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
    })
    ParentGui(Gui)

    local Main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        ClipsDescendants = true,
        Visible = false,
        Parent = Gui,
    })
    Theme(Main, "BackgroundColor3", "Background")
    Corner(Main, 10)
    local MainStroke = New("UIStroke", {
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Main,
    })
    Theme(MainStroke, "Color", "Stroke")
    local Scale = New("UIScale", { Scale = 0.01, Parent = Main })

    -- Barra superior
    local Topbar = New("Frame", { Name = "Topbar", Size = UDim2.new(1, 0, 0, 38), Parent = Main })
    Theme(Topbar, "BackgroundColor3", "Topbar")
    Corner(Topbar, 10)
    -- deixa os cantos de baixo da barra retos (so os de cima ficam arredondados)
    local TopbarFill = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 10),
        Parent = Topbar,
    })
    Theme(TopbarFill, "BackgroundColor3", "Topbar")

    local TitleHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = Topbar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = TitleHolder,
    })
    local TitleLabel = New("TextLabel", {
        LayoutOrder = 1,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Text = title,
        Parent = TitleHolder,
    })
    Theme(TitleLabel, "TextColor3", "Text")
    local SubLabel = New("TextLabel", {
        LayoutOrder = 2,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Text = subtitle,
        Visible = subtitle ~= "",
        Parent = TitleHolder,
    })
    Theme(SubLabel, "TextColor3", "SubText")

    local function TopButton(text, xOffset, onClick)
        local b = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, xOffset, 0.5, 0),
            Size = UDim2.fromOffset(26, 26),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Text = text,
            Parent = Topbar,
        })
        Theme(b, "BackgroundColor3", "Element")
        Theme(b, "TextColor3", "SubText")
        Corner(b, 6)
        b.MouseEnter:Connect(function()
            Tween(b, { BackgroundTransparency = 0 }, 0.12)
        end)
        b.MouseLeave:Connect(function()
            Tween(b, { BackgroundTransparency = 1 }, 0.12)
        end)
        b.MouseButton1Click:Connect(onClick)
        return b
    end

    TopButton("X", -8, function()
        Window:Destroy()
    end)
    local MinButton = TopButton("-", -38, function()
        Window:SetMinimized(not Window.Minimized)
    end)

    MakeDraggable(Topbar, Main, Connect)

    -- Corpo: barra lateral + paginas
    local Body = New("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 38),
        Size = UDim2.new(1, 0, 1, -38),
        Parent = Main,
    })
    local Sidebar = New("Frame", { Size = UDim2.new(0, sidebarWidth, 1, 0), Parent = Body })
    Theme(Sidebar, "BackgroundColor3", "Sidebar")
    Corner(Sidebar, 10)
    -- cantos de cima e da direita retos; so o de baixo a esquerda acompanha a janela
    local SidebarFillTop = New("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Parent = Sidebar,
    })
    Theme(SidebarFillTop, "BackgroundColor3", "Sidebar")
    local SidebarFillRight = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 10, 1, 0),
        Parent = Sidebar,
    })
    Theme(SidebarFillRight, "BackgroundColor3", "Sidebar")
    local Divider = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = Sidebar,
    })
    Theme(Divider, "BackgroundColor3", "Stroke")

    local TabList = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = Sidebar,
    })
    New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabList })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 9),
        Parent = TabList,
    })

    local Pages = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(sidebarWidth, 0),
        Size = UDim2.new(1, -sidebarWidth, 1, 0),
        ClipsDescendants = true,
        Parent = Body,
    })

    -- Botao flutuante (celular)
    local showFloat = cfg.FloatButton
    if showFloat == nil then
        showFloat = isMobile
    end
    if showFloat then
        local Float = New("TextButton", {
            Name = "Float",
            Position = UDim2.new(0, 16, 0.5, -23),
            Size = UDim2.fromOffset(46, 46),
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            Text = cfg.FloatText or string.upper(string.sub(title, 1, 1)),
            Parent = Gui,
        })
        Theme(Float, "BackgroundColor3", "Accent")
        Float.TextColor3 = Color3.new(1, 1, 1)
        Corner(Float, "full")
        -- borda escura fixa (nao muda com o tema)
        New("UIStroke", {
            Color = cfg.FloatBorderColor or Color3.fromRGB(8, 8, 12),
            Thickness = 3,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = Float,
        })
        local state = MakeDraggable(Float, Float, Connect)
        Float.Activated:Connect(function()
            if not state.Moved then
                Window:SetVisible(not Window.Visible)
            end
        end)
    end

    ----------------------------------------------------------------
    -- Metodos da janela
    ----------------------------------------------------------------
    function Window:SetVisible(state)
        Window.Visible = state and true or false
        if Window.Visible then
            Main.Visible = true
            Tween(Scale, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
        else
            local t = Tween(Scale, { Scale = 0.01 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            t.Completed:Connect(function()
                if not Window.Visible then
                    Main.Visible = false
                end
            end)
        end
    end

    function Window:SetMinimized(state)
        Window.Minimized = state and true or false
        local target = Window.Minimized and UDim2.new(size.X.Scale, size.X.Offset, 0, 38) or size
        local tw = Tween(Main, { Size = target }, 0.2)
        if Window.Minimized then
            tw.Completed:Connect(function()
                if Window.Minimized then
                    TopbarFill.Visible = false
                end
            end)
        else
            TopbarFill.Visible = true
        end
        MinButton.Text = Window.Minimized and "+" or "-"
    end

    function Window:SetTitle(text)
        TitleLabel.Text = text
    end

    function Window:SetToggleKey(key)
        toggleKey = key
    end

    function Window:SetTheme(name)
        if not Themes[name] then
            return false
        end
        Slpus8xUI.Theme = Themes[name]
        ApplyTheme()
        return true
    end

    function Window:SelectTab(tab)
        Window.ActiveTab = tab
        for _, t in ipairs(Window.Tabs) do
            t.Page.Visible = (t == tab)
            t.Render()
        end
    end

    function Window:Notify(config)
        Slpus8xUI:Notify(config)
    end

    function Window:Destroy()
        for _, c in ipairs(Connections) do
            pcall(function()
                c:Disconnect()
            end)
        end
        Connections = {}
        Gui:Destroy()
    end

    Connect(UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            Window:SetVisible(not Window.Visible)
        end
    end)

    ----------------------------------------------------------------
    -- Configuracoes (salvar / carregar Flags)
    ----------------------------------------------------------------
    local function canFiles()
        return type(writefile) == "function"
            and type(readfile) == "function"
            and type(isfile) == "function"
            and type(isfolder) == "function"
            and type(makefolder) == "function"
    end

    function Window:SaveConfig(name)
        if not canFiles() then
            return false, "Seu executor nao suporta arquivos"
        end
        local data = {}
        for flag, obj in pairs(Slpus8xUI.Flags) do
            local v = obj.Value
            if obj.Type == "Color" then
                data[flag] = { R = v.R, G = v.G, B = v.B }
            elseif obj.Type == "Keybind" then
                data[flag] = v.Name
            else
                data[flag] = v
            end
        end
        local ok, err = pcall(function()
            if not isfolder(configFolder) then
                makefolder(configFolder)
            end
            writefile(configFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        end)
        if not ok then
            return false, tostring(err)
        end
        return true
    end

    function Window:LoadConfig(name)
        if not canFiles() then
            return false, "Seu executor nao suporta arquivos"
        end
        local path = configFolder .. "/" .. name .. ".json"
        if not isfile(path) then
            return false, "Config nao encontrada"
        end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(data) ~= "table" then
            return false, "Arquivo de config invalido"
        end
        for flag, value in pairs(data) do
            local obj = Slpus8xUI.Flags[flag]
            if obj then
                pcall(function()
                    if obj.Type == "Color" then
                        obj:Set(Color3.new(value.R, value.G, value.B))
                    elseif obj.Type == "Keybind" then
                        obj:Set(value)
                    else
                        obj:Set(value)
                    end
                end)
            end
        end
        return true
    end

    function Window:GetConfigs()
        local list = {}
        if canFiles() and type(listfiles) == "function" and isfolder(configFolder) then
            pcall(function()
                for _, path in ipairs(listfiles(configFolder)) do
                    local name = path:match("([^/\\]+)%.json$")
                    if name then
                        list[#list + 1] = name
                    end
                end
            end)
        end
        return list
    end

    ----------------------------------------------------------------
    -- ABAS
    ----------------------------------------------------------------
    local tabOrder = 0

    function Window:CreateTab(name, icon)
        local Tab = { Name = name }
        tabOrder = tabOrder + 1

        local Button = New("TextButton", {
            Name = name,
            LayoutOrder = tabOrder,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Text = "",
            Parent = TabList,
        })
        Corner(Button, 6)
        local Indicator = New("Frame", {
            Position = UDim2.new(0, 0, 0.5, -8),
            Size = UDim2.fromOffset(3, 16),
            BackgroundTransparency = 1,
            Parent = Button,
        })
        Corner(Indicator, "full")

        local textX = 12
        local labelText = name
        local Img
        if icon and icon ~= "" then
            if tostring(icon):find("^rbx") then
                Img = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0.5, -8),
                    Size = UDim2.fromOffset(16, 16),
                    Image = icon,
                    Parent = Button,
                })
                textX = 32
            else
                labelText = icon .. "  " .. name
            end
        end
        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(textX, 0),
            Size = UDim2.new(1, -textX - 4, 1, 0),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = labelText,
            Parent = Button,
        })

        local function render()
            local active = Window.ActiveTab == Tab
            local th = Slpus8xUI.Theme
            Tween(Button, {
                BackgroundTransparency = active and 0 or 1,
                BackgroundColor3 = th.Element,
            }, 0.15)
            Tween(Label, { TextColor3 = active and th.Text or th.SubText }, 0.15)
            Tween(Indicator, {
                BackgroundTransparency = active and 0 or 1,
                BackgroundColor3 = th.Accent,
            }, 0.15)
            if Img then
                Tween(Img, { ImageColor3 = active and th.Accent or th.SubText }, 0.15)
            end
        end
        Tab.Render = render
        Refreshers[#Refreshers + 1] = render

        Button.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)

        -- Pagina da aba
        local Page = New("ScrollingFrame", {
            Name = name,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            Visible = false,
            Parent = Pages,
        })
        Theme(Page, "ScrollBarImageColor3", "Accent")
        New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Page })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 12),
            Parent = Page,
        })
        Tab.Page = Page

        local order = 0
        local function NextOrder()
            order = order + 1
            return order
        end

        local function Card(height, class)
            local f = New(class or "Frame", {
                Size = UDim2.new(1, 0, 0, height),
                LayoutOrder = NextOrder(),
                Parent = Page,
            })
            if class == "TextButton" then
                f.Text = ""
            end
            Theme(f, "BackgroundColor3", "Element")
            Corner(f, 6)
            local st = New("UIStroke", {
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = f,
            })
            Theme(st, "Color", "Stroke")
            return f
        end

        -- Arrastar dentro de um elemento (slider, color picker)
        local function Drag(area, onMove)
            local active = false
            area.InputBegan:Connect(function(input)
                if IsPointer(input) then
                    active = true
                    Page.ScrollingEnabled = false
                    onMove(input)
                end
            end)
            Connect(UserInputService.InputChanged, function(input)
                if active and IsMove(input) then
                    onMove(input)
                end
            end)
            Connect(UserInputService.InputEnded, function(input)
                if active and IsPointer(input) then
                    active = false
                    Page.ScrollingEnabled = true
                end
            end)
        end

        ------------------------------------------------------------
        -- Section
        ------------------------------------------------------------
        function Tab:CreateSection(text)
            local F = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                LayoutOrder = NextOrder(),
                Parent = Page,
            })
            Lbl(F, string.upper(text or ""), "Accent", {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.fromOffset(2, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
            })
        end

        ------------------------------------------------------------
        -- Label
        ------------------------------------------------------------
        function Tab:CreateLabel(text)
            local C = Card(30)
            local L = Lbl(C, text or "", "SubText", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -24, 1, 0),
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            local Obj = {}
            function Obj:Set(t)
                L.Text = t
            end
            return Obj
        end

        ------------------------------------------------------------
        -- Paragraph
        ------------------------------------------------------------
        function Tab:CreateParagraph(config)
            config = config or {}
            local C = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = NextOrder(),
                Parent = Page,
            })
            Theme(C, "BackgroundColor3", "Element")
            Corner(C, 6)
            local st = New("UIStroke", {
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = C,
            })
            Theme(st, "Color", "Stroke")
            New("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                Parent = C,
            })
            New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = C })
            local T = Lbl(C, config.Title or "", "Text", {
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Enum.Font.GothamBold,
                TextWrapped = true,
            })
            local B = Lbl(C, config.Content or "", "SubText", {
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
            })
            local Obj = {}
            function Obj:Set(newTitle, newContent)
                if newTitle then
                    T.Text = newTitle
                end
                if newContent then
                    B.Text = newContent
                end
            end
            return Obj
        end

        ------------------------------------------------------------
        -- Button
        ------------------------------------------------------------
        function Tab:CreateButton(config)
            config = config or {}
            local C = Card(36, "TextButton")
            Hover(C)
            local L = Lbl(C, config.Name or "Botao", "Text", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -40, 1, 0),
            })
            Lbl(C, ">", "SubText", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 0),
                Size = UDim2.fromOffset(16, 36),
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
            })
            local Obj = { Type = "Button" }
            function Obj:SetText(t)
                L.Text = t
            end
            function Obj:Fire()
                Safe(config.Callback)
            end
            C.MouseButton1Click:Connect(function()
                local th = Slpus8xUI.Theme
                local t = Tween(C, { BackgroundColor3 = th.Accent }, 0.08)
                t.Completed:Connect(function()
                    Tween(C, { BackgroundColor3 = th.ElementHover }, 0.25)
                end)
                Safe(config.Callback)
            end)
            return Obj
        end

        ------------------------------------------------------------
        -- Toggle
        ------------------------------------------------------------
        function Tab:CreateToggle(config)
            config = config or {}
            local Obj = { Type = "Toggle", Value = config.Default == true }
            local C = Card(36, "TextButton")
            Hover(C)
            Lbl(C, config.Name or "Toggle", "Text", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -70, 1, 0),
            })
            local TrackBox = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(38, 20),
                Parent = C,
            })
            Corner(TrackBox, "full")
            local Knob = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Parent = TrackBox,
            })
            Corner(Knob, "full")

            local function render(instant)
                local th = Slpus8xUI.Theme
                Animate(TrackBox, { BackgroundColor3 = Obj.Value and th.Accent or th.Stroke }, instant)
                Animate(Knob, { Position = UDim2.new(0, Obj.Value and 21 or 3, 0.5, 0) }, instant)
            end

            function Obj:Set(value, silent)
                Obj.Value = value and true or false
                render()
                if not silent then
                    Safe(config.Callback, Obj.Value)
                end
            end
            function Obj:Get()
                return Obj.Value
            end

            C.MouseButton1Click:Connect(function()
                Obj:Set(not Obj.Value)
            end)

            render(true)
            Refreshers[#Refreshers + 1] = function()
                render(true)
            end
            Register(config.Flag, Obj)
            if Obj.Value then
                task.defer(function()
                    Safe(config.Callback, true)
                end)
            end
            return Obj
        end

        ------------------------------------------------------------
        -- Slider
        ------------------------------------------------------------
        function Tab:CreateSlider(config)
            config = config or {}
            local min = config.Min or 0
            local max = config.Max or 100
            local inc = config.Increment or 1
            local suffix = config.Suffix or ""
            local Obj = { Type = "Slider", Value = math.clamp(config.Default or min, min, max) }

            local C = Card(52)
            Lbl(C, config.Name or "Slider", "Text", {
                Position = UDim2.fromOffset(12, 7),
                Size = UDim2.new(1, -100, 0, 18),
            })
            local ValueLbl = Lbl(C, "", "SubText", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -12, 0, 7),
                Size = UDim2.fromOffset(88, 18),
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            local Track = New("Frame", {
                Position = UDim2.new(0, 12, 0, 34),
                Size = UDim2.new(1, -24, 0, 6),
                Parent = C,
            })
            Theme(Track, "BackgroundColor3", "Stroke")
            Corner(Track, "full")
            local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), Parent = Track })
            Theme(Fill, "BackgroundColor3", "Accent")
            Corner(Fill, "full")
            New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Parent = Fill,
            }).Name = "Knob"
            Corner(Fill.Knob, "full")

            local Hit = New("TextButton", {
                BackgroundTransparency = 1,
                Text = "",
                Position = UDim2.new(0, 6, 0, 24),
                Size = UDim2.new(1, -12, 0, 26),
                Parent = C,
            })

            local function format(v)
                return tostring(math.floor(v * 1000 + 0.5) / 1000) .. suffix
            end

            function Obj:Set(value, silent)
                value = tonumber(value) or min
                value = min + math.floor((value - min) / inc + 0.5) * inc
                value = math.floor(value * 1000000 + 0.5) / 1000000
                value = math.clamp(value, min, max)
                local changed = value ~= Obj.Value
                Obj.Value = value
                local rel = (max - min) == 0 and 0 or (value - min) / (max - min)
                Tween(Fill, { Size = UDim2.fromScale(rel, 1) }, 0.06)
                ValueLbl.Text = format(value)
                if changed and not silent then
                    Safe(config.Callback, value)
                end
            end
            function Obj:Get()
                return Obj.Value
            end

            Drag(Hit, function(input)
                local rel = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                Obj:Set(min + (max - min) * rel)
            end)

            Obj:Set(Obj.Value, true)
            Register(config.Flag, Obj)
            task.defer(function()
                Safe(config.Callback, Obj.Value)
            end)
            return Obj
        end

        ------------------------------------------------------------
        -- Dropdown (simples ou Multi = true)
        ------------------------------------------------------------
        function Tab:CreateDropdown(config)
            config = config or {}
            local multi = config.Multi == true
            local options = config.Options or {}
            local Obj = { Type = "Dropdown", Options = options, Value = multi and {} or nil }

            local C = Card(36)
            C.ClipsDescendants = true
            local Header = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
                Text = "",
                Parent = C,
            })
            Header.MouseEnter:Connect(function()
                Tween(C, { BackgroundColor3 = Slpus8xUI.Theme.ElementHover }, 0.12)
            end)
            Header.MouseLeave:Connect(function()
                Tween(C, { BackgroundColor3 = Slpus8xUI.Theme.Element }, 0.12)
            end)
            Lbl(Header, config.Name or "Dropdown", "Text", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(0.5, -12, 1, 0),
            })
            local ValueLbl = Lbl(Header, "", "SubText", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -30, 0, 0),
                Size = UDim2.new(0.5, -34, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            local Arrow = Lbl(Header, "v", "SubText", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 0),
                Size = UDim2.fromOffset(16, 36),
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
            })
            local List = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 40),
                Size = UDim2.new(1, -12, 0, 0),
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2,
                Parent = C,
            })
            Theme(List, "ScrollBarImageColor3", "Accent")
            New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = List })

            local open = false
            local function Resize()
                local h = math.min(#options, 5) * 31
                Tween(C, { Size = UDim2.new(1, 0, 0, open and (44 + h) or 36) }, 0.2)
                Tween(List, { Size = UDim2.new(1, -12, 0, h) }, 0.2)
                Tween(Arrow, { Rotation = open and 180 or 0 }, 0.2)
            end

            local function Selected(opt)
                if multi then
                    for _, v in ipairs(Obj.Value) do
                        if v == opt then
                            return true
                        end
                    end
                    return false
                end
                return Obj.Value == opt
            end

            local Buttons = {}
            local function RenderOptions()
                local th = Slpus8xUI.Theme
                for _, entry in ipairs(Buttons) do
                    local sel = Selected(entry.Option)
                    entry.Button.BackgroundColor3 = th.Accent
                    Tween(entry.Button, { BackgroundTransparency = sel and 0.78 or 1 }, 0.12)
                    entry.Label.TextColor3 = sel and th.Accent or th.Text
                end
            end

            local function RenderText()
                if multi then
                    if #Obj.Value == 0 then
                        ValueLbl.Text = "Nenhum"
                    else
                        local names = {}
                        for i, v in ipairs(Obj.Value) do
                            names[i] = tostring(v)
                        end
                        ValueLbl.Text = table.concat(names, ", ")
                    end
                else
                    ValueLbl.Text = Obj.Value ~= nil and tostring(Obj.Value) or "Selecione"
                end
            end

            local Pick

            local function Build()
                for _, entry in ipairs(Buttons) do
                    entry.Button:Destroy()
                end
                Buttons = {}
                for i, opt in ipairs(options) do
                    local B = New("TextButton", {
                        LayoutOrder = i,
                        Size = UDim2.new(1, -4, 0, 28),
                        BackgroundTransparency = 1,
                        Text = "",
                        Parent = List,
                    })
                    Corner(B, 5)
                    local T = Lbl(B, tostring(opt), "Text", {
                        Position = UDim2.fromOffset(10, 0),
                        Size = UDim2.new(1, -20, 1, 0),
                    })
                    Buttons[#Buttons + 1] = { Button = B, Label = T, Option = opt }
                    B.MouseButton1Click:Connect(function()
                        Pick(opt)
                    end)
                end
                RenderOptions()
            end

            function Obj:Set(value, silent)
                if multi then
                    local new = {}
                    if type(value) == "table" then
                        for _, v in ipairs(value) do
                            if table.find(options, v) then
                                new[#new + 1] = v
                            end
                        end
                    end
                    Obj.Value = new
                else
                    if value ~= nil and not table.find(options, value) then
                        value = nil
                    end
                    Obj.Value = value
                end
                RenderText()
                RenderOptions()
                if not silent then
                    Safe(config.Callback, Obj.Value)
                end
            end
            function Obj:Get()
                return Obj.Value
            end

            Pick = function(opt)
                if multi then
                    local new = {}
                    local found = false
                    for _, v in ipairs(Obj.Value) do
                        if v == opt then
                            found = true
                        else
                            new[#new + 1] = v
                        end
                    end
                    if not found then
                        new[#new + 1] = opt
                    end
                    Obj:Set(new)
                else
                    Obj:Set(opt)
                    open = false
                    Resize()
                end
            end

            function Obj:Refresh(newOptions, keepValue)
                options = newOptions or {}
                Obj.Options = options
                Build()
                if keepValue then
                    Obj:Set(Obj.Value, true)
                else
                    Obj:Set(multi and {} or nil, true)
                end
                if open then
                    Resize()
                end
            end

            Header.MouseButton1Click:Connect(function()
                open = not open
                Resize()
            end)

            Refreshers[#Refreshers + 1] = RenderOptions
            Build()
            Obj:Set(config.Default, true)
            Register(config.Flag, Obj)
            local hasValue = (multi and #Obj.Value > 0) or (not multi and Obj.Value ~= nil)
            if hasValue then
                task.defer(function()
                    Safe(config.Callback, Obj.Value)
                end)
            end
            return Obj
        end

        ------------------------------------------------------------
        -- TextBox
        ------------------------------------------------------------
        function Tab:CreateTextBox(config)
            config = config or {}
            local Obj = { Type = "TextBox", Value = config.Default or "" }
            local C = Card(36)
            Lbl(C, config.Name or "TextBox", "Text", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -170, 1, 0),
            })
            local Box = New("TextBox", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(140, 24),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                Text = Obj.Value,
                PlaceholderText = config.Placeholder or "Digite...",
                ClearTextOnFocus = false,
                Parent = C,
            })
            Theme(Box, "BackgroundColor3", "Background")
            Theme(Box, "TextColor3", "Text")
            Theme(Box, "PlaceholderColor3", "SubText")
            Corner(Box, 5)
            local bs = New("UIStroke", {
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = Box,
            })
            Theme(bs, "Color", "Stroke")

            Box.Focused:Connect(function()
                Tween(bs, { Color = Slpus8xUI.Theme.Accent }, 0.12)
            end)
            Box.FocusLost:Connect(function(enterPressed)
                Tween(bs, { Color = Slpus8xUI.Theme.Stroke }, 0.12)
                Obj.Value = Box.Text
                Safe(config.Callback, Box.Text, enterPressed)
            end)

            function Obj:Set(text, silent)
                Obj.Value = tostring(text)
                Box.Text = Obj.Value
                if not silent then
                    Safe(config.Callback, Obj.Value, false)
                end
            end
            function Obj:Get()
                return Obj.Value
            end

            Register(config.Flag, Obj)
            return Obj
        end

        ------------------------------------------------------------
        -- Keybind
        ------------------------------------------------------------
        function Tab:CreateKeybind(config)
            config = config or {}
            local Obj = { Type = "Keybind", Value = config.Default or Enum.KeyCode.Unknown }
            local C = Card(36)
            Lbl(C, config.Name or "Keybind", "Text", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -110, 1, 0),
            })
            local Btn = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(86, 24),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Text = "",
                Parent = C,
            })
            Theme(Btn, "BackgroundColor3", "Background")
            Theme(Btn, "TextColor3", "Text")
            Corner(Btn, 5)
            local bs = New("UIStroke", {
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = Btn,
            })
            Theme(bs, "Color", "Stroke")

            local listening = false
            local function render()
                if listening then
                    Btn.Text = "..."
                elseif Obj.Value == Enum.KeyCode.Unknown then
                    Btn.Text = "Nenhuma"
                else
                    Btn.Text = Obj.Value.Name
                end
            end

            function Obj:Set(key)
                if type(key) == "string" then
                    local ok, k = pcall(function()
                        return Enum.KeyCode[key]
                    end)
                    key = ok and k or Enum.KeyCode.Unknown
                end
                Obj.Value = key or Enum.KeyCode.Unknown
                render()
            end
            function Obj:Get()
                return Obj.Value
            end

            Btn.MouseButton1Click:Connect(function()
                listening = true
                render()
            end)

            Connect(UserInputService.InputBegan, function(input, processed)
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        if input.KeyCode ~= Enum.KeyCode.Escape then
                            Obj.Value = input.KeyCode
                            Safe(config.OnChange, Obj.Value)
                        end
                        render()
                    end
                    return
                end
                if not processed and Obj.Value ~= Enum.KeyCode.Unknown and input.KeyCode == Obj.Value then
                    Safe(config.Callback, Obj.Value)
                end
            end)

            render()
            Register(config.Flag, Obj)
            return Obj
        end

        ------------------------------------------------------------
        -- ColorPicker
        ------------------------------------------------------------
        function Tab:CreateColorPicker(config)
            config = config or {}
            local Obj = { Type = "Color", Value = config.Default or Color3.fromRGB(255, 255, 255) }
            local h, s, v = Color3.toHSV(Obj.Value)

            local C = Card(36)
            C.ClipsDescendants = true
            local Header = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
                Text = "",
                Parent = C,
            })
            Header.MouseEnter:Connect(function()
                Tween(C, { BackgroundColor3 = Slpus8xUI.Theme.ElementHover }, 0.12)
            end)
            Header.MouseLeave:Connect(function()
                Tween(C, { BackgroundColor3 = Slpus8xUI.Theme.Element }, 0.12)
            end)
            Lbl(Header, config.Name or "Cor", "Text", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -70, 1, 0),
            })
            local Preview = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(34, 20),
                Parent = Header,
            })
            Corner(Preview, 5)
            local ps = New("UIStroke", {
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = Preview,
            })
            Theme(ps, "Color", "Stroke")

            local Area = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 42),
                Size = UDim2.new(1, -20, 0, 110),
                Parent = C,
            })

            -- Quadrado de saturacao / brilho
            local SV = New("TextButton", {
                Size = UDim2.new(1, -28, 1, 0),
                Text = "",
                Parent = Area,
            })
            Corner(SV, 5)
            local White = New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Parent = SV,
            })
            Corner(White, 5)
            New("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = White,
            })
            local Black = New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(0, 0, 0),
                Parent = SV,
            })
            Corner(Black, 5)
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Parent = Black,
            })
            local SVCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(10, 10),
                BackgroundTransparency = 1,
                ZIndex = 5,
                Parent = SV,
            })
            Corner(SVCursor, "full")
            New("UIStroke", {
                Color = Color3.new(1, 1, 1),
                Thickness = 2,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = SVCursor,
            })

            -- Barra de matiz
            local HueBar = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 18, 1, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Text = "",
                Parent = Area,
            })
            Corner(HueBar, 5)
            local keys = {}
            for i = 0, 6 do
                keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 >= 1 and 0 or i / 6, 1, 1))
            end
            New("UIGradient", { Rotation = 90, Color = ColorSequence.new(keys), Parent = HueBar })
            local HueCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, 4, 0, 4),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = 5,
                Parent = HueBar,
            })
            Corner(HueCursor, "full")
            New("UIStroke", {
                Color = Color3.new(0, 0, 0),
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = HueCursor,
            })

            local function Render()
                local color = Color3.fromHSV(h, s, v)
                Obj.Value = color
                Preview.BackgroundColor3 = color
                SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                SVCursor.Position = UDim2.fromScale(s, 1 - v)
                HueCursor.Position = UDim2.fromScale(0.5, h)
            end

            Drag(SV, function(input)
                s = math.clamp((input.Position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((input.Position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
                Render()
                Safe(config.Callback, Obj.Value)
            end)
            Drag(HueBar, function(input)
                h = math.clamp((input.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                Render()
                Safe(config.Callback, Obj.Value)
            end)

            local open = false
            Header.MouseButton1Click:Connect(function()
                open = not open
                Tween(C, { Size = UDim2.new(1, 0, 0, open and 162 or 36) }, 0.2)
            end)

            function Obj:Set(color, silent)
                h, s, v = Color3.toHSV(color)
                Render()
                if not silent then
                    Safe(config.Callback, Obj.Value)
                end
            end
            function Obj:Get()
                return Obj.Value
            end

            Render()
            Register(config.Flag, Obj)
            task.defer(function()
                Safe(config.Callback, Obj.Value)
            end)
            return Obj
        end

        ------------------------------------------------------------
        Window.Tabs[#Window.Tabs + 1] = Tab
        if not Window.ActiveTab then
            Window:SelectTab(Tab)
        else
            render()
        end
        return Tab
    end

    Window:SetVisible(true)
    return Window
end

return Slpus8xUI
