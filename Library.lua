local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local TxS = game:GetService("TextService")
local HS = game:GetService("HttpService")
local RS = game:GetService("RunService")
local CG = game:GetService("CoreGui")

local make_folder = makefolder or function()
end
local write_file = writefile or function()
end
local read_file = readfile or function()
    return nil
end
local is_file = isfile or function()
    return false
end
local list_files = listfiles or function()
    return {}
end
local del_file = delfile or function()
end

local isMobile = UIS.TouchEnabled

local function Create(className, properties, children)
    local inst = Instance.new(className)
    for k, v in pairs(properties or {}) do
        inst[k] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(instance, properties, durationOrTweenInfo)
    local info
    if typeof(durationOrTweenInfo) == "number" then
        info = TweenInfo.new(durationOrTweenInfo, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    else
        info = durationOrTweenInfo or TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    end
    local tween = TS:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function ParseAsset(id)
    if not id or id == "" then
        return ""
    end
    local str = tostring(id):match("^%s*(.-)%s*$")
    if not str or str == "" then
        return ""
    end

    local lowerStr = str:lower()
    if lowerStr:find("://") then
        return str
    end

    if str:match("^%d+$") then
        return "rbxthumb://type=Asset&id=" .. str .. "&w=420&h=420"
    end
    
    if lowerStr:find("roblox%.com") then
        local num = str:match("%d+")
        if num then
            return "rbxthumb://type=Asset&id=" .. num .. "&w=420&h=420"
        end
    end

    return str
end

local function GetKeyName(key)
    if not key then
        return ""
    end
    local name = key.Name
    local numMap = {
        Zero="0", One="1", Two="2", Three="3", Four="4", 
        Five="5", Six="6", Seven="7", Eight="8", Nine="9",
        KeypadZero="0", KeypadOne="1", KeypadTwo="2", KeypadThree="3", KeypadFour="4",
        KeypadFive="5", KeypadSix="6", KeypadSeven="7", KeypadEight="8", KeypadNine="9"
    }
    return numMap[name] or name
end

local FontList = {"Arial", "ArialBold", "SourceSans", "SourceSansBold", "SourceSansSemibold", "SourceSansLight", "SourceSansItalic", "Bodoni", "Garamond", "Cartoon", "Code", "Highway", "SciFi", "Arcade", "Fantasy", "Antique", "Gotham", "GothamMedium", "GothamBold", "Oswald"}

local VelourUI = {
    Settings = {
        Theme = {
            Background = Color3.fromRGB(14, 14, 14),
            SidebarBg = Color3.fromRGB(14, 14, 14),
            SectionBg = Color3.fromRGB(18, 18, 18),
            Stroke = Color3.fromRGB(35, 35, 35),
            Text = Color3.fromRGB(230, 230, 230),
            TextDark = Color3.fromRGB(120, 120, 120),
            Accent = Color3.fromRGB(255, 140, 40), 
            CornerRadius = UDim.new(0, 10),        
            TitleFont = Enum.Font.GothamMedium,
            TextFont = Enum.Font.Gotham,
            BgTransparency = 0,
            SectionTransparency = 0,
            ElementsTransparency = 0,
            BackgroundImage = "",
            BgImageTransparency = 0,
            CurrentScale = 1
        }
    }
}

function VelourUI:CreateWindow(options)
    local titleText = options.Name or "Velour Ultimate"
    local topbarIcon = ParseAsset(options.Icon)
    local configFolder = options.ConfigFolder or "VelourConfigs"

    make_folder(configFolder)
    make_folder("VelourThemes")

    if options.Theme then
        for k, v in pairs(options.Theme) do
            if k == "CornerRadius" and type(v) == "number" then
                VelourUI.Settings.Theme[k] = UDim.new(0, math.clamp(v, 0, 20))
            elseif (k == "BgTransparency" or k == "SectionTransparency" or k == "ElementsTransparency" or k == "BgImageTransparency") and type(v) == "number" then
                if v > 1 then
                    VelourUI.Settings.Theme[k] = v / 100
                else
                    VelourUI.Settings.Theme[k] = v
                end
            elseif k == "BackgroundImage" then
                VelourUI.Settings.Theme[k] = ParseAsset(v)
            elseif k == "TitleFont" or k == "TextFont" then
                if typeof(v) == "EnumItem" then
                    VelourUI.Settings.Theme[k] = v
                else
                    VelourUI.Settings.Theme[k] = Enum.Font[v]
                end
            else
                VelourUI.Settings.Theme[k] = v
            end
        end
    end

    local ScreenGui = Create("ScreenGui", {
        Name = "VelourUI",
        ResetOnSpawn = false
    })
    
    local ok = pcall(function()
        ScreenGui.Parent = CG
    end)
    
    if not ok then
        ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    local NotifyContainer = Create("Frame", {
        Size = UDim2.new(0, 320, 1, -40),
        Position = UDim2.new(1, -340, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 100
    })
    NotifyContainer.Parent = ScreenGui
    
    local NotifyLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        VerticalAlignment = Enum.VerticalAlignment.Top
    })
    NotifyLayout.Parent = NotifyContainer

    local WindowObj = {
        Tabs = {},
        ThemeInstances = {},
        ActiveToggleTracks = {},
        Connections = {},
        Flags = {},
        ThemeUpdaters = {},
        ActiveKeybinds = {}
    }

    function WindowObj:ConnectSignal(signal, callback)
        local conn = signal:Connect(callback)
        table.insert(self.Connections, conn)
        return conn
    end

    function WindowObj:Destroy()
        for _, conn in ipairs(self.Connections) do
            if conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(self.Connections)
        ScreenGui:Destroy()
    end

    local function Reg(inst, prop, tag)
        table.insert(WindowObj.ThemeInstances, {
            Instance = inst,
            Prop = prop,
            Tag = tag
        })
        inst[prop] = VelourUI.Settings.Theme[tag]
    end

    function WindowObj:UpdateTheme(tag, value, noCb)
        if tag == "BgTransparency" then
            VelourUI.Settings.Theme.BgTransparency = value
            if self.ThemeUpdaters[tag] and not noCb then
                self.ThemeUpdaters[tag](value, true)
            end
            for _, obj in pairs(self.ThemeInstances) do
                if obj.Tag == "BgTransparency" then
                    Tween(obj.Instance, {[obj.Prop] = value}, 0.2)
                end
            end
            return
        elseif tag == "SectionTransparency" then
            VelourUI.Settings.Theme.SectionTransparency = value
            if self.ThemeUpdaters[tag] and not noCb then
                self.ThemeUpdaters[tag](value, true)
            end
            for _, obj in pairs(self.ThemeInstances) do
                if obj.Tag == "SectionTransparency" then
                    Tween(obj.Instance, {[obj.Prop] = value}, 0.2)
                end
            end
            return
        elseif tag == "ElementsTransparency" then
            VelourUI.Settings.Theme.ElementsTransparency = value
            if self.ThemeUpdaters[tag] and not noCb then
                self.ThemeUpdaters[tag](value, true)
            end
            for _, obj in pairs(self.ThemeInstances) do
                if obj.Tag == "ElementsTransparency" then
                    Tween(obj.Instance, {[obj.Prop] = value}, 0.2)
                end
            end
            return
        elseif tag == "BackgroundImage" then
            value = ParseAsset(value)
            VelourUI.Settings.Theme.BackgroundImage = value
            if self.ThemeUpdaters[tag] and not noCb then
                self.ThemeUpdaters[tag](value, true)
            end
            for _, obj in pairs(self.ThemeInstances) do
                if obj.Tag == "BackgroundImage" then
                    obj.Instance.Image = value
                end
            end
            return
        elseif tag == "BgImageTransparency" then
            VelourUI.Settings.Theme.BgImageTransparency = value
            if self.ThemeUpdaters[tag] and not noCb then
                self.ThemeUpdaters[tag](value, true)
            end
            for _, obj in pairs(self.ThemeInstances) do
                if obj.Tag == "BgImageTransparency" then
                    Tween(obj.Instance, {ImageTransparency = value}, 0.2)
                end
            end
            return
        elseif tag == "CornerRadius" and type(value) == "number" then
            value = UDim.new(0, math.clamp(value, 0, 20))
        elseif tag == "TextFont" or tag == "TitleFont" then
            VelourUI.Settings.Theme[tag] = value
            if self.ThemeUpdaters[tag] and not noCb then
                self.ThemeUpdaters[tag](value, true)
            end
            for _, obj in pairs(self.ThemeInstances) do
                if obj.Tag == tag then
                    obj.Instance[obj.Prop] = value
                end
            end
            return
        elseif tag == "CurrentScale" then
            VelourUI.Settings.Theme.CurrentScale = value
            if self.ThemeUpdaters[tag] then
                self.ThemeUpdaters[tag](value, false)
            end
            return
        end

        VelourUI.Settings.Theme[tag] = value
        if self.ThemeUpdaters[tag] and not noCb then
            self.ThemeUpdaters[tag](value, true)
        end 

        for _, obj in pairs(self.ThemeInstances) do
            if obj.Tag == tag then
                Tween(obj.Instance, {[obj.Prop] = value}, 0.2)
            end
        end

        if tag == "Background" then
            VelourUI.Settings.Theme.SidebarBg = value
            for _, obj in pairs(self.ThemeInstances) do
                if obj.Tag == "SidebarBg" then
                    Tween(obj.Instance, {[obj.Prop] = value}, 0.2)
                end
            end
        end

        if tag == "Accent" then
            for _, track in pairs(self.ActiveToggleTracks) do
                Tween(track, {BackgroundColor3 = value}, 0.2)
            end
            for _, t in pairs(self.Tabs) do
                if t.Icon and t.IsActive then
                    Tween(t.Icon, {ImageColor3 = value}, 0.2)
                end
            end
        end

        if tag == "Text" or tag == "TextDark" then
            for _, t in pairs(self.Tabs) do
                if t.IsActive then
                    t.TextLabel.TextColor3 = VelourUI.Settings.Theme.Text
                else
                    t.TextLabel.TextColor3 = VelourUI.Settings.Theme.TextDark
                    if t.Icon then
                        t.Icon.ImageColor3 = VelourUI.Settings.Theme.TextDark
                    end
                end
            end
        end
    end

    local function ThemeCorner()
        local c = Create("UICorner", {
            CornerRadius = VelourUI.Settings.Theme.CornerRadius
        })
        Reg(c, "CornerRadius", "CornerRadius")
        return c
    end

    local function ThemeStroke()
        local s = Create("UIStroke", {
            Color = VelourUI.Settings.Theme.Stroke,
            Thickness = 1
        })
        Reg(s, "Color", "Stroke")
        return s
    end

    local MobileToggleBtn = Create("TextButton", {
        Size = UDim2.new(0, 45, 0, 45),
        Position = UDim2.new(0.5, -22, 0, 10),
        BackgroundColor3 = VelourUI.Settings.Theme.Background,
        BackgroundTransparency = VelourUI.Settings.Theme.ElementsTransparency,
        Text = "",
        Visible = isMobile,
        ZIndex = 100
    }, {
        ThemeCorner(),
        ThemeStroke()
    })
    
    Reg(MobileToggleBtn, "BackgroundColor3", "Background")
    Reg(MobileToggleBtn, "BackgroundTransparency", "ElementsTransparency")
    
    if topbarIcon ~= "" then
        local iconImg = Create("ImageLabel", {
            Size = UDim2.new(0, 25, 0, 25),
            Position = UDim2.new(0.5, -12.5, 0.5, -12.5),
            BackgroundTransparency = 1,
            Image = topbarIcon,
            ImageColor3 = VelourUI.Settings.Theme.Accent
        })
        Reg(iconImg, "ImageColor3", "Accent")
        iconImg.Parent = MobileToggleBtn
    end
    
    MobileToggleBtn.Parent = ScreenGui

    local mtDragging = false
    local mtInput = nil
    local mtPos = nil
    local mtFramePos = nil
    local mtDragDist = 0
    
    MobileToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mtDragging = true
            mtPos = input.Position
            mtFramePos = MobileToggleBtn.Position
            mtDragDist = 0
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    mtDragging = false
                end
            end)
        end
    end)
    
    MobileToggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            mtInput = input
        end
    end)
    
    WindowObj:ConnectSignal(UIS.InputChanged, function(input)
        if input == mtInput and mtDragging then
            local delta = input.Position - mtPos
            mtDragDist = mtDragDist + delta.Magnitude
            MobileToggleBtn.Position = UDim2.new(mtFramePos.X.Scale, mtFramePos.X.Offset + delta.X, mtFramePos.Y.Scale, mtFramePos.Y.Offset + delta.Y)
        end
    end)
    
    MobileToggleBtn.MouseButton1Click:Connect(function()
        if mtDragDist < 10 then
            WindowObj:Toggle()
        end
    end)

    local KeybindsPanel = Create("Frame", {
        Size = UDim2.new(0, 220, 0, 300),
        Position = UDim2.new(1, 210, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = VelourUI.Settings.Theme.Background,
        BackgroundTransparency = VelourUI.Settings.Theme.ElementsTransparency,
        ClipsDescendants = true,
        ZIndex = 90
    }, {
        ThemeCorner(),
        ThemeStroke()
    })
    Reg(KeybindsPanel, "BackgroundColor3", "Background")
    Reg(KeybindsPanel, "BackgroundTransparency", "ElementsTransparency")
    KeybindsPanel.Parent = ScreenGui

    local kbStripVisual = Create("Frame", {
        Size = UDim2.new(0, 4, 0, 20),
        Position = UDim2.new(0, 3, 0.5, -10),
        BackgroundColor3 = VelourUI.Settings.Theme.TextDark,
        BorderSizePixel = 0,
        ZIndex = 95
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(1, 0)
        })
    })
    Reg(kbStripVisual, "BackgroundColor3", "TextDark")
    kbStripVisual.Parent = KeybindsPanel

    local kbPanelOpen = false
    local kbStripBtn = Create("TextButton", {
        Size = UDim2.new(0, 10, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 95
    })
    kbStripBtn.Parent = KeybindsPanel

    local kbTitle = Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "Keybinds",
        TextColor3 = VelourUI.Settings.Theme.Accent,
        Font = VelourUI.Settings.Theme.TitleFont,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 96
    })
    Reg(kbTitle, "TextColor3", "Accent")
    Reg(kbTitle, "Font", "TitleFont")
    kbTitle.Parent = KeybindsPanel

    local kbLine = Create("Frame", {
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundColor3 = VelourUI.Settings.Theme.Stroke,
        BorderSizePixel = 0,
        ZIndex = 96
    })
    Reg(kbLine, "BackgroundColor3", "Stroke")
    kbLine.Parent = KeybindsPanel

    local kbListLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    
    local kbListContainer = Create("Frame", {
        Size = UDim2.new(1, -20, 1, -35),
        Position = UDim2.new(0, 10, 0, 35),
        BackgroundTransparency = 1,
        ZIndex = 95
    }, {
        kbListLayout
    })
    kbListContainer.Parent = KeybindsPanel

    function WindowObj:UpdateKeybindsPanel()
        local count = 0
        for _, child in ipairs(kbListContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        for name, key in pairs(self.ActiveKeybinds) do
            count = count + 1
            local kbRow = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                ZIndex = 95
            })
            
            local kbNameLbl = Create("TextLabel", {
                Size = UDim2.new(0.7, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = VelourUI.Settings.Theme.Text,
                Font = VelourUI.Settings.Theme.TextFont,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 96
            })
            Reg(kbNameLbl, "TextColor3", "Text")
            Reg(kbNameLbl, "Font", "TextFont")
            kbNameLbl.Parent = kbRow

            local kbValLbl = Create("TextLabel", {
                Size = UDim2.new(0.3, 0, 1, 0),
                Position = UDim2.new(0.7, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = "[" .. GetKeyName(key) .. "]",
                TextColor3 = VelourUI.Settings.Theme.TextDark,
                Font = VelourUI.Settings.Theme.TextFont,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 96
            })
            Reg(kbValLbl, "TextColor3", "TextDark")
            Reg(kbValLbl, "Font", "TextFont")
            kbValLbl.Parent = kbRow

            kbRow.Parent = kbListContainer
        end

        local targetHeight = math.max(30, 35 + (count * 25))
        if kbPanelOpen then
            Tween(KeybindsPanel, {
                Size = UDim2.new(0, 220, 0, targetHeight)
            }, 0.3)
        else
            KeybindsPanel.Size = UDim2.new(0, 220, 0, targetHeight)
        end
    end

    kbStripBtn.MouseButton1Click:Connect(function()
        kbPanelOpen = not kbPanelOpen
        if kbPanelOpen then
            Tween(KeybindsPanel, {
                Position = UDim2.new(1, -10, 0.5, 0)
            }, 0.3)
        else
            Tween(KeybindsPanel, {
                Position = UDim2.new(1, 210, 0.5, 0)
            }, 0.3)
        end
    end)

    local WatermarkContainer = Create("Frame", {
        Size = UDim2.new(0, 0, 0, 30),
        Position = UDim2.new(0.5, 0, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Visible = options.WatermarkEnabled or false,
        ZIndex = 50
    })
    WatermarkContainer.Parent = ScreenGui
    WindowObj.WatermarkContainer = WatermarkContainer

    local WatermarkItems = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 50
    })
    WatermarkItems.Parent = WatermarkContainer

    local WatermarkLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })
    WatermarkLayout.Parent = WatermarkItems

    WatermarkLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        WatermarkContainer.Size = UDim2.new(0, WatermarkLayout.AbsoluteContentSize.X, 0, 30)
    end)

    local WmDragBtn = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 55
    })
    WmDragBtn.Parent = WatermarkContainer

    local wmDragging = false
    local wmDragInput = nil
    local wmMousePos = nil
    local wmFramePos = nil
    
    WmDragBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wmDragging = true
            wmMousePos = input.Position
            wmFramePos = WatermarkContainer.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    wmDragging = false
                end
            end)
        end
    end)
    
    WmDragBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then 
            wmDragInput = input 
        end
    end)
    
    WindowObj:ConnectSignal(UIS.InputChanged, function(input)
        if input == wmDragInput and wmDragging then
            local delta = input.Position - wmMousePos
            WatermarkContainer.Position = UDim2.new(wmFramePos.X.Scale, wmFramePos.X.Offset + delta.X, wmFramePos.Y.Scale, wmFramePos.Y.Offset + delta.Y)
        end
    end)

    local function CreateWatermarkPiece(textStr, order)
        local Frame = Create("Frame", {
            Size = UDim2.new(0, 100, 1, 0),
            BackgroundColor3 = VelourUI.Settings.Theme.Background,
            BackgroundTransparency = VelourUI.Settings.Theme.ElementsTransparency,
            LayoutOrder = order,
            ZIndex = 51
        }, {
            ThemeCorner(),
            ThemeStroke()
        })
        Reg(Frame, "BackgroundColor3", "Background")
        Reg(Frame, "BackgroundTransparency", "ElementsTransparency")

        local Label = Create("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = textStr,
            TextColor3 = VelourUI.Settings.Theme.Text,
            Font = VelourUI.Settings.Theme.TitleFont,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 52
        })
        Reg(Label, "TextColor3", "Text")
        Reg(Label, "Font", "TitleFont")
        Label.Parent = Frame

        local function UpdateSize()
            local bounds = TxS:GetTextSize(Label.Text, 13, Label.Font, Vector2.new(9999, 30))
            Frame.Size = UDim2.new(0, bounds.X + 24, 1, 0)
        end

        Label:GetPropertyChangedSignal("Text"):Connect(UpdateSize)
        Label:GetPropertyChangedSignal("Font"):Connect(UpdateSize)
        UpdateSize()

        Frame.Parent = WatermarkItems
        return Label
    end

    local localPlayer = game:GetService("Players").LocalPlayer
    local wmNameLabel = CreateWatermarkPiece(localPlayer and localPlayer.Name or "Player", 1)
    local wmPingLabel = CreateWatermarkPiece("Ping: 0ms", 2)
    local wmFpsLabel = CreateWatermarkPiece("FPS: 0", 3)

    local lastUpdate = tick()
    local frames = 0
    
    WindowObj:ConnectSignal(RS.RenderStepped, function()
        frames = frames + 1
        local now = tick()
        if now - lastUpdate >= 1 then
            wmFpsLabel.Text = "FPS: " .. frames
            frames = 0
            lastUpdate = now

            local ping = 0
            pcall(function()
                local Stats = game:GetService("Stats")
                if Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("ServerStatsItem") and Stats.Network.ServerStatsItem:FindFirstChild("Data Ping") then
                    ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
                elseif Stats:FindFirstChild("PerformanceStats") and Stats.PerformanceStats:FindFirstChild("Ping") then
                    ping = math.floor(Stats.PerformanceStats.Ping:GetValue() + 0.5)
                end
            end)
            wmPingLabel.Text = "Ping: " .. tostring(ping) .. "ms"
        end
    end)

    function WindowObj:SetWatermarkVisible(state)
        if self.WatermarkContainer then
            self.WatermarkContainer.Visible = state
        end
    end

    local MainFrame = Create("Frame", {
        Size = UDim2.new(0, 850, 0, 550),
        Position = UDim2.new(0.5, -425, 0.5, -275),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        Draggable = false,
        ClipsDescendants = false
    }, {
        ThemeCorner(),
        ThemeStroke()
    })
    MainFrame.Parent = ScreenGui

    if isMobile then
        MainFrame.Size = UDim2.new(0, 450, 0, 300)
        MainFrame.Position = UDim2.new(0, 10, 0.5, -150)
        WindowObj.CurrentScale = 0.75
        VelourUI.Settings.Theme.CurrentScale = 0.75
    else
        WindowObj.CurrentScale = 1
        VelourUI.Settings.Theme.CurrentScale = 1
    end

    local BgImage = Create("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = VelourUI.Settings.Theme.BackgroundImage,
        ImageTransparency = VelourUI.Settings.Theme.BgImageTransparency,
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = -2
    }, {
        ThemeCorner()
    })
    BgImage.Parent = MainFrame
    Reg(BgImage, "Image", "BackgroundImage")
    Reg(BgImage, "ImageTransparency", "BgImageTransparency")

    local BgOverlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = VelourUI.Settings.Theme.Background,
        BackgroundTransparency = VelourUI.Settings.Theme.BgTransparency,
        BorderSizePixel = 0,
        ZIndex = -1,
        ClipsDescendants = true 
    }, {
        ThemeCorner()
    })
    BgOverlay.Parent = MainFrame
    Reg(BgOverlay, "BackgroundColor3", "Background")
    Reg(BgOverlay, "BackgroundTransparency", "BgTransparency")

    WindowObj.ScaleObj = Create("UIScale", {
        Scale = 0
    })
    WindowObj.ScaleObj.Parent = MainFrame
    WindowObj.IsOpen = true
    WindowObj.ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift

    Tween(WindowObj.ScaleObj, {
        Scale = WindowObj.CurrentScale
    }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))

    function WindowObj:Toggle()
        self.IsOpen = not self.IsOpen
        if self.IsOpen then
            MainFrame.Visible = true 
            Tween(self.ScaleObj, {
                Scale = self.CurrentScale
            }, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        else
            local t = Tween(self.ScaleObj, {
                Scale = 0
            }, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
            t.Completed:Connect(function()
                if not self.IsOpen then
                    MainFrame.Visible = false
                end
            end) 
        end
    end

    WindowObj:ConnectSignal(UIS.InputBegan, function(input, gp)
        if not gp and input.KeyCode == WindowObj.ToggleKey then
            WindowObj:Toggle()
        end
    end)

    local topbarElements = {
        Create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = VelourUI.Settings.Theme.Stroke,
            BorderSizePixel = 0
        })
    }
    
    local titleXPos = 20
    if topbarIcon ~= "" then
        local tbIconL = Create("ImageLabel", {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 20, 0.5, -12),
            BackgroundTransparency = 1,
            Image = topbarIcon,
            ImageColor3 = VelourUI.Settings.Theme.Accent
        })
        table.insert(topbarElements, tbIconL)
        Reg(tbIconL, "ImageColor3", "Accent") 
        titleXPos = 52 
    end

    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(0, titleXPos, 0, 0),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = VelourUI.Settings.Theme.Text,
        Font = VelourUI.Settings.Theme.TitleFont,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    table.insert(topbarElements, titleLabel)
    Reg(titleLabel, "Font", "TitleFont")

    local TopBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 1
    }, topbarElements)
    TopBar.Parent = BgOverlay
    Reg(TopBar:FindFirstChildOfClass("Frame"), "BackgroundColor3", "Stroke")
    Reg(titleLabel, "TextColor3", "Text")

    local CloseBtn = Create("TextButton", {
        Size = UDim2.new(0, 45, 1, 0),
        Position = UDim2.new(1, -45, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    })
    
    local Line1 = Create("Frame", {
        Size = UDim2.new(0, 14, 0, 2),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = VelourUI.Settings.Theme.TextDark,
        BorderSizePixel = 0,
        Rotation = 45
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(1, 0)
        })
    })
    
    local Line2 = Create("Frame", {
        Size = UDim2.new(0, 14, 0, 2),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = VelourUI.Settings.Theme.TextDark,
        BorderSizePixel = 0,
        Rotation = -45
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(1, 0)
        })
    })
    
    Line1.Parent = CloseBtn
    Line2.Parent = CloseBtn
    CloseBtn.Parent = TopBar
    Reg(Line1, "BackgroundColor3", "TextDark")
    Reg(Line2, "BackgroundColor3", "TextDark")

    CloseBtn.MouseEnter:Connect(function()
        Tween(Line1, {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}, 0.2)
        Tween(Line2, {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}, 0.2)
    end)
    
    CloseBtn.MouseLeave:Connect(function()
        Tween(Line1, {BackgroundColor3 = VelourUI.Settings.Theme.TextDark}, 0.2)
        Tween(Line2, {BackgroundColor3 = VelourUI.Settings.Theme.TextDark}, 0.2)
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        WindowObj:Destroy()
    end)

    local draggingWindow = false
    local dragInput = nil
    local mousePos = nil
    local framePos = nil
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position.X >= CloseBtn.AbsolutePosition.X then
                return
            end
            draggingWindow = true
            mousePos = input.Position
            framePos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingWindow = false
                end
            end)
        end
    end)
    
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    WindowObj:ConnectSignal(UIS.InputChanged, function(input)
        if input == dragInput and draggingWindow then
            local delta = (input.Position - mousePos) / WindowObj.CurrentScale
            MainFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)

    local sidebarWidth = isMobile and 120 or 160
    local Sidebar = Create("Frame", {
        Size = UDim2.new(0, sidebarWidth, 1, -46),
        Position = UDim2.new(0, 0, 0, 46),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
    Sidebar.Parent = BgOverlay

    local HighlightLayer = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 1
    })
    HighlightLayer.Parent = Sidebar

    local HighlightBox = Create("Frame", {
        Size = UDim2.new(1, -12, 0, 36),
        Position = UDim2.new(0, 6, 0, 10),
        BackgroundTransparency = 1,
        ZIndex = 1
    }, {
        ThemeCorner(),
        Create("UIStroke", {
            Color = VelourUI.Settings.Theme.Stroke,
            Thickness = 1
        })
    })
    HighlightBox.Parent = HighlightLayer
    Reg(HighlightBox:FindFirstChildOfClass("UIStroke"), "Color", "Stroke")

    local TabsContainer = Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ZIndex = 2
    }, {
        Create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 20)
        })
    })
    TabsContainer.Parent = Sidebar

    local TabsLayout = TabsContainer:FindFirstChildOfClass("UIListLayout")
    TabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabsContainer.CanvasSize = UDim2.new(0, 0, 0, TabsLayout.AbsoluteContentSize.Y + 30)
    end)

    local SidebarLine = Create("Frame", {
        Size = UDim2.new(0, 1, 1, -46),
        Position = UDim2.new(0, sidebarWidth, 0, 46),
        BackgroundColor3 = VelourUI.Settings.Theme.Stroke,
        BorderSizePixel = 0
    })
    SidebarLine.Parent = BgOverlay
    Reg(SidebarLine, "BackgroundColor3", "Stroke")

    local ContentContainer = Create("Frame", {
        Size = UDim2.new(1, -(sidebarWidth + 1), 1, -66),
        Position = UDim2.new(0, sidebarWidth + 1, 0, 46),
        BackgroundTransparency = 1
    })
    ContentContainer.Parent = BgOverlay

    local BottomDivider = Create("Frame", {
        Size = UDim2.new(1, -(sidebarWidth + 1), 0, 1),
        Position = UDim2.new(0, sidebarWidth + 1, 1, -20),
        BackgroundColor3 = VelourUI.Settings.Theme.Stroke,
        BorderSizePixel = 0,
        ZIndex = 10
    })
    BottomDivider.Parent = BgOverlay
    Reg(BottomDivider, "BackgroundColor3", "Stroke")

    local ResizeHandle = Create("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -24, 1, -24),
        BackgroundTransparency = 1,
        Text = "↘",
        TextColor3 = VelourUI.Settings.Theme.TextDark,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        AutoButtonColor = false,
        ZIndex = 10
    }, {
        ThemeCorner(),
        Create("UIStroke", {
            Color = VelourUI.Settings.Theme.Stroke,
            Thickness = 1
        })
    })
    ResizeHandle.Parent = MainFrame
    Reg(ResizeHandle, "TextColor3", "TextDark")
    Reg(ResizeHandle:FindFirstChildOfClass("UIStroke"), "Color", "Stroke")

    local resizing = false
    local firstMove = true
    local startMousePos = nil
    local startSize = nil
    local minWidth = isMobile and 300 or 500
    local minHeight = isMobile and 200 or 320 

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            firstMove = true
            startMousePos = input.Position
            startSize = MainFrame.AbsoluteSize / WindowObj.CurrentScale
            input.UserInputState = Enum.UserInputState.Cancel
        end
    end)
    
    WindowObj:ConnectSignal(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)
    
    WindowObj:ConnectSignal(UIS.InputChanged, function(input)
        if not resizing or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then
            return
        end
        if firstMove then
            firstMove = false
            return
        end
        local delta = (input.Position - startMousePos) / WindowObj.CurrentScale
        local scale = WindowObj.CurrentScale
        MainFrame.Size = UDim2.new(0, math.max(minWidth, startSize.X + delta.X), 0, math.max(minHeight, startSize.Y + delta.Y))
    end)

    function WindowObj:Notify(options)
        local title = options.Title or "Notification"
        local text = options.Text or ""
        local duration = options.Duration or 5
        local icon = ParseAsset(options.Icon)

        if icon == "" and topbarIcon ~= "" then
            icon = topbarIcon
        end
        local hasIcon = (icon ~= "")
        local textX = hasIcon and 50 or 15
        local textWidth = 320 - textX - 15
        
        local textSize = TxS:GetTextSize(text, 14, VelourUI.Settings.Theme.TextFont, Vector2.new(textWidth, 9999))
        local frameHeight = math.max(hasIcon and 50 or 40, textSize.Y + 44)

        local OuterWrapper = Create("Frame", {
            Size = UDim2.new(1, 0, 0, frameHeight),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            LayoutOrder = -math.floor(tick() * 1000)
        }, {
            ThemeCorner()
        }) 

        local NotifFrame = Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(1, 400, 0, 0),
            BackgroundColor3 = VelourUI.Settings.Theme.Background,
            BackgroundTransparency = VelourUI.Settings.Theme.ElementsTransparency,
            BorderSizePixel = 0
        }, {
            ThemeCorner(),
            Create("UIStroke", {
                Color = VelourUI.Settings.Theme.Stroke,
                Thickness = 1
            })
        })
        Reg(NotifFrame, "BackgroundColor3", "Background")
        Reg(NotifFrame, "BackgroundTransparency", "ElementsTransparency")
        Reg(NotifFrame:FindFirstChildOfClass("UIStroke"), "Color", "Stroke")

        local TitleL = Create("TextLabel", {
            Size = UDim2.new(1, -textX - 15, 0, 16),
            Position = UDim2.new(0, textX, 0, 10),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = VelourUI.Settings.Theme.Text,
            Font = VelourUI.Settings.Theme.TitleFont,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        Reg(TitleL, "TextColor3", "Text")
        Reg(TitleL, "Font", "TitleFont")
        TitleL.Parent = NotifFrame

        local DescL = Create("TextLabel", {
            Size = UDim2.new(1, -textX - 15, 1, -30),
            Position = UDim2.new(0, textX, 0, 28),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = VelourUI.Settings.Theme.TextDark,
            Font = VelourUI.Settings.Theme.TextFont,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true
        })
        Reg(DescL, "TextColor3", "TextDark")
        Reg(DescL, "Font", "TextFont")
        DescL.Parent = NotifFrame

        if hasIcon then
            Create("ImageLabel", {
                Size = UDim2.new(0, 26, 0, 26),
                Position = UDim2.new(0, 12, 0, 12),
                BackgroundTransparency = 1,
                Image = icon
            }).Parent = NotifFrame
        end

        local TimeBarBg = Create("Frame", {
            Size = UDim2.new(1, -20, 0, 2),
            Position = UDim2.new(0, 10, 1, -8),
            BackgroundColor3 = VelourUI.Settings.Theme.Stroke,
            BorderSizePixel = 0
        })
        Reg(TimeBarBg, "BackgroundColor3", "Stroke")
        
        local TimeBar = Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = VelourUI.Settings.Theme.Accent,
            BorderSizePixel = 0
        })
        Reg(TimeBar, "BackgroundColor3", "Accent")
        
        TimeBar.Parent = TimeBarBg
        TimeBarBg.Parent = NotifFrame
        NotifFrame.Parent = OuterWrapper
        OuterWrapper.Parent = NotifyContainer
        
        Tween(NotifFrame, {
            Position = UDim2.new(0, 0, 0, 0)
        }, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
        
        local twn = TS:Create(TimeBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 1, 0)
        })
        twn:Play()

        task.delay(duration, function()
            local outTwn = Tween(NotifFrame, {
                Position = UDim2.new(1, 400, 0, 0)
            }, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In))
            outTwn.Completed:Connect(function()
                OuterWrapper:Destroy()
            end)
        end)
    end

    local activeTabRecord = nil
    TabsContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if activeTabRecord then
            local targetY = (activeTabRecord.Button.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y) / WindowObj.CurrentScale
            HighlightBox.Position = UDim2.new(0, 6, 0, targetY)
        end
    end)

    function WindowObj:CreateTab(options)
        local tabName = type(options) == "table" and options.Name or options
        local tabIconId = type(options) == "table" and ParseAsset(options.Icon) or ""
        local hasTabIcon = (tabIconId ~= "")
        local isSettings = type(options) == "table" and options.IsSettings or false
        
        local TabObj = {}

        local TabButton = Create("TextButton", { 
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 2,
            LayoutOrder = isSettings and 9999 or #WindowObj.Tabs 
        })
        TabButton.Parent = TabsContainer

        local textXOffset = hasTabIcon and 38 or 16 
        
        local TabText = Create("TextLabel", {
            Size = UDim2.new(1, -textXOffset, 1, 0),
            Position = UDim2.new(0, textXOffset, 0, 0),
            BackgroundTransparency = 1,
            Text = tabName,
            TextColor3 = VelourUI.Settings.Theme.TextDark,
            Font = VelourUI.Settings.Theme.TextFont,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        TabText.Parent = TabButton
        Reg(TabText, "Font", "TextFont")

        local TabIcon = nil
        if hasTabIcon then
            TabIcon = Create("ImageLabel", {
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(0, 6, 0.5, -12),
                BackgroundTransparency = 1,
                Image = tabIconId,
                ImageColor3 = VelourUI.Settings.Theme.TextDark,
                ZIndex = 2
            })
            TabIcon.Parent = TabButton
        end

        local TabGroup = Create("CanvasGroup", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            GroupTransparency = 1,
            Visible = false,
            BorderSizePixel = 0
        })
        TabGroup.Parent = ContentContainer

        local TabContent = Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            ClipsDescendants = false
        })
        TabContent.Parent = TabGroup

        local LeftColumn = Create("Frame", {
            Size = UDim2.new(0.5, -15, 1, 0),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1
        }, {
            Create("UIListLayout", {
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            Create("UIPadding", {
                PaddingBottom = UDim.new(0, 25)
            })
        })
        
        local RightColumn = Create("Frame", {
            Size = UDim2.new(0.5, -15, 1, 0),
            Position = UDim2.new(0.5, 5, 0, 10),
            BackgroundTransparency = 1
        }, {
            Create("UIListLayout", {
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            Create("UIPadding", {
                PaddingBottom = UDim.new(0, 25)
            })
        })
        
        LeftColumn.Parent = TabContent
        RightColumn.Parent = TabContent

        local function UpdateScroll()
            local contentHeight = math.max(LeftColumn.UIListLayout.AbsoluteContentSize.Y, RightColumn.UIListLayout.AbsoluteContentSize.Y)
            TabContent.CanvasSize = UDim2.new(0, 0, 0, math.ceil(contentHeight / WindowObj.CurrentScale) + 30)
        end

        LeftColumn.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateScroll)
        RightColumn.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateScroll)

        local TabRecord = {
            Button = TabButton,
            TextLabel = TabText,
            Group = TabGroup,
            Content = TabContent,
            Icon = TabIcon,
            IsActive = false,
            IsSettings = isSettings
        }

        TabRecord.Select = function()
            if activeTabRecord == TabRecord then
                return
            end
            
            if TabRecord.Group.Parent then
                TabRecord.Group.Parent.ClipsDescendants = true
            end

            local swipeDir = 1
            if activeTabRecord then
                if TabButton.AbsolutePosition.Y > activeTabRecord.Button.AbsolutePosition.Y then
                    swipeDir = 1 
                else
                    swipeDir = -1 
                end
            end

            for _, t in pairs(WindowObj.Tabs) do
                t.IsActive = false
                Tween(t.TextLabel, {
                    TextColor3 = VelourUI.Settings.Theme.TextDark
                })
                if t.Icon then
                    Tween(t.Icon, {
                        ImageColor3 = VelourUI.Settings.Theme.TextDark
                    })
                end
                
                if t.Group.Visible then
                    local exitY = -1 * swipeDir
                    local tw = Tween(t.Group, {
                        GroupTransparency = 1, 
                        Position = UDim2.new(0, 0, exitY, 0)
                    }, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
                    
                    tw.Completed:Connect(function() 
                        if not t.IsActive then 
                            t.Group.Visible = false 
                        end 
                    end)
                end
            end
            
            TabRecord.IsActive = true
            
            local startY = 1 * swipeDir
            TabRecord.Group.Position = UDim2.new(0, 0, startY, 0)
            TabRecord.Group.Visible = true
            
            Tween(TabRecord.Group, {
                GroupTransparency = 0, 
                Position = UDim2.new(0, 0, 0, 0)
            }, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            
            Tween(TabRecord.TextLabel, {
                TextColor3 = VelourUI.Settings.Theme.Text
            })
            if TabRecord.Icon then
                Tween(TabRecord.Icon, {
                    ImageColor3 = VelourUI.Settings.Theme.Accent
                })
            end
            
            activeTabRecord = TabRecord
            local targetY = (TabButton.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y) / WindowObj.CurrentScale
            
            Tween(HighlightBox, {
                Position = UDim2.new(0, 6, 0, targetY)
            }, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            UpdateScroll()
        end

        TabButton.MouseButton1Click:Connect(TabRecord.Select)

        table.insert(WindowObj.Tabs, TabRecord)

        function TabObj:CreateSection(options)
            local name = type(options) == "table" and options.Name or options
            local side = type(options) == "table" and options.Side or "Left"
            local secIcon = type(options) == "table" and ParseAsset(options.Icon) or ""
            local SectionObj = {}
            local targetColumn = side:lower() == "right" and RightColumn or LeftColumn

            local SectionFrame = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = VelourUI.Settings.Theme.SectionBg,
                BackgroundTransparency = VelourUI.Settings.Theme.SectionTransparency,
                BorderSizePixel = 0,
                ClipsDescendants = false
            }, {
                ThemeCorner(),
                ThemeStroke()
            })
            SectionFrame.Parent = targetColumn
            Reg(SectionFrame, "BackgroundColor3", "SectionBg")
            Reg(SectionFrame, "BackgroundTransparency", "SectionTransparency")

            local Header = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1
            })
            Header.Parent = SectionFrame
            
            local HeaderBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 2
            })
            HeaderBtn.Parent = Header

            local titleOffset = 10
            if secIcon ~= "" then
                local sIco = Create("ImageLabel", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 10, 0.5, -8),
                    BackgroundTransparency = 1,
                    Image = secIcon,
                    ImageColor3 = VelourUI.Settings.Theme.Text
                })
                sIco.Parent = Header
                Reg(sIco, "ImageColor3", "Text")
                titleOffset = 32
            end

            local TitleLabel = Create("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, titleOffset, 0, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = VelourUI.Settings.Theme.Text,
                Font = VelourUI.Settings.Theme.TitleFont,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd
            })
            TitleLabel.Parent = Header
            Reg(TitleLabel, "TextColor3", "Text")
            Reg(TitleLabel, "Font", "TitleFont")

            local CollapseIcon = Create("TextLabel", {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -15, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = "-",
                TextColor3 = VelourUI.Settings.Theme.TextDark,
                Font = VelourUI.Settings.Theme.TitleFont,
                TextSize = 16
            })
            CollapseIcon.Parent = Header
            Reg(CollapseIcon, "TextColor3", "TextDark")
            Reg(CollapseIcon, "Font", "TitleFont")

            local Line = Create("Frame", {
                Size = UDim2.new(1, -20, 0, 1),
                Position = UDim2.new(0, 10, 1, 0),
                BackgroundColor3 = VelourUI.Settings.Theme.Stroke,
                BorderSizePixel = 0
            })
            Line.Parent = Header
            Reg(Line, "BackgroundColor3", "Stroke")

            local InnerContainer = Create("Frame", {
                Size = UDim2.new(1, 0, 1, -31),
                Position = UDim2.new(0, 0, 0, 31),
                BackgroundTransparency = 1
            })
            InnerContainer.Parent = SectionFrame

            local InnerLayout = Create("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            local InnerPadding = Create("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10)
            })
            InnerLayout.Parent = InnerContainer
            InnerPadding.Parent = InnerContainer

            local sectionOpen = true
            local targetHeight = 47

            local function UpdateSectionSize()
                targetHeight = math.ceil(InnerLayout.AbsoluteContentSize.Y / WindowObj.CurrentScale) + 47
                if sectionOpen then
                    SectionFrame.Size = UDim2.new(1, 0, 0, targetHeight)
                end
            end
            InnerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSectionSize)

            HeaderBtn.MouseButton1Click:Connect(function()
                sectionOpen = not sectionOpen
                if sectionOpen then
                    InnerContainer.Visible = true
                    Tween(CollapseIcon, {
                        Rotation = 0
                    }, 0.3)
                    CollapseIcon.Text = "-"
                    local tw = Tween(SectionFrame, {
                        Size = UDim2.new(1, 0, 0, targetHeight)
                    }, 0.3)
                    tw.Completed:Connect(function()
                        if sectionOpen then
                            SectionFrame.ClipsDescendants = false
                        end
                    end)
                else
                    SectionFrame.ClipsDescendants = true
                    Tween(CollapseIcon, {
                        Rotation = 180
                    }, 0.3)
                    CollapseIcon.Text = "+"
                    local tw = Tween(SectionFrame, {
                        Size = UDim2.new(1, 0, 0, 40)
                    }, 0.3)
                    tw.Completed:Connect(function()
                        if not sectionOpen then
                            InnerContainer.Visible = false
                        end
                    end)
                end
            end)

            local function RegisterFlag(flag, getFunc, setFunc)
                if flag then
                    WindowObj.Flags[flag] = {
                        Get = getFunc,
                        Set = setFunc
                    }
                end
            end

            function SectionObj:CreateLabel(options)
                local text = options.Name or "Label"
                local LabelFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1
                })
                LabelFrame.Parent = InnerContainer
                
                local Lbl = Create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = VelourUI.Settings.Theme.TextDark,
                    Font = VelourUI.Settings.Theme.TitleFont,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                Lbl.Parent = LabelFrame
                Reg(Lbl, "TextColor3", "TextDark")
                Reg(Lbl, "Font", "TitleFont")
            end

            function SectionObj:CreateToggle(options)
                local tName = options.Name or "Toggle"
                local default = options.Default or false
                local callback = options.Callback or function()
                end
                
                local state = default
                local ToggleBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    Text = tName,
                    TextColor3 = VelourUI.Settings.Theme.Text,
                    Font = VelourUI.Settings.Theme.TextFont,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                ToggleBtn.Parent = InnerContainer
                Reg(ToggleBtn, "TextColor3", "Text")
                Reg(ToggleBtn, "Font", "TextFont")

                local CheckBox = Create("Frame", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(1, -18, 0.5, -9),
                    BackgroundColor3 = VelourUI.Settings.Theme.Background,
                    BackgroundTransparency = VelourUI.Settings.Theme.SectionTransparency
                }, {
                    ThemeCorner(),
                    ThemeStroke()
                })
                CheckBox.Parent = ToggleBtn
                Reg(CheckBox, "BackgroundColor3", "Background")
                Reg(CheckBox, "BackgroundTransparency", "SectionTransparency")

                local InnerBox = Create("Frame", {
                    Size = UDim2.new(0, state and 10 or 0, 0, state and 10 or 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = VelourUI.Settings.Theme.Accent,
                    BackgroundTransparency = state and 0 or 1
                }, {
                    ThemeCorner()
                })
                InnerBox.Parent = CheckBox
                Reg(InnerBox, "BackgroundColor3", "Accent")

                if state then
                    table.insert(WindowObj.ActiveToggleTracks, InnerBox)
                end

                local function SetState(v, noCb)
                    state = v
                    if state then
                        Tween(InnerBox, {
                            Size = UDim2.new(0, 10, 0, 10),
                            BackgroundTransparency = 0
                        }, 0.2)
                        local found = false
                        for _, t in ipairs(WindowObj.ActiveToggleTracks) do
                            if t == InnerBox then
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(WindowObj.ActiveToggleTracks, InnerBox)
                        end
                    else
                        Tween(InnerBox, {
                            Size = UDim2.new(0, 0, 0, 0),
                            BackgroundTransparency = 1
                        }, 0.2)
                        for i, t in ipairs(WindowObj.ActiveToggleTracks) do
                            if t == InnerBox then
                                table.remove(WindowObj.ActiveToggleTracks, i)
                                break
                            end
                        end
                    end
                    if not noCb then
                        pcall(callback, state)
                    end
                end

                ToggleBtn.MouseButton1Click:Connect(function()
                    SetState(not state)
                end)
                
                RegisterFlag(options.Flag, function()
                    return state
                end, SetState)
                
                pcall(callback, state)
                
                return {
                    Set = SetState,
                    Get = function()
                        return state
                    end
                }
            end

            function SectionObj:CreateButton(options)
                local bName = options.Name or "Button"
                local callback = options.Callback or function()
                end

                local BtnPlate = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = VelourUI.Settings.Theme.SectionBg,
                    BackgroundTransparency = VelourUI.Settings.Theme.SectionTransparency,
                    BorderSizePixel = 0
                }, {
                    ThemeCorner(),
                    ThemeStroke()
                })
                BtnPlate.Parent = InnerContainer
                Reg(BtnPlate, "BackgroundColor3", "SectionBg")
                Reg(BtnPlate, "BackgroundTransparency", "SectionTransparency")

                local Btn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = bName,
                    TextColor3 = VelourUI.Settings.Theme.Text,
                    Font = VelourUI.Settings.Theme.TitleFont,
                    TextSize = 13,
                    AutoButtonColor = false,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                Btn.Parent = BtnPlate
                Reg(Btn, "TextColor3", "Text")
                Reg(Btn, "Font", "TitleFont")

                Btn.MouseButton1Down:Connect(function()
                    local bg = VelourUI.Settings.Theme.SectionBg
                    local flashColor = Color3.fromRGB(math.clamp(bg.R*255 + 25, 0, 255), math.clamp(bg.G*255 + 25, 0, 255), math.clamp(bg.B*255 + 25, 0, 255))
                    Tween(BtnPlate, {
                        BackgroundColor3 = flashColor
                    }, 0.1)
                end)
                
                Btn.MouseButton1Up:Connect(function()
                    Tween(BtnPlate, {
                        BackgroundColor3 = VelourUI.Settings.Theme.SectionBg
                    }, 0.2)
                end)
                
                Btn.MouseLeave:Connect(function()
                    Tween(BtnPlate, {
                        BackgroundColor3 = VelourUI.Settings.Theme.SectionBg
                    }, 0.2)
                end)
                
                Btn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)
            end

            function SectionObj:CreateSlider(options)
                local sName = options.Name or "Slider"
                local min = options.Min or 0
                local max = options.Max or 100
                local default = options.Default or options.Min or 0
                local callback = options.Callback or function()
                end

                local SliderFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1
                })
                SliderFrame.Parent = InnerContainer

                local Title = Create("TextLabel", {
                    Size = UDim2.new(1, -50, 0, 16),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = sName,
                    TextColor3 = VelourUI.Settings.Theme.Text,
                    Font = VelourUI.Settings.Theme.TextFont,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                Title.Parent = SliderFrame
                Reg(Title, "TextColor3", "Text")
                Reg(Title, "Font", "TextFont")

                local ValueText = Create("TextLabel", {
                    Size = UDim2.new(0, 50, 0, 16),
                    Position = UDim2.new(1, -50, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(default),
                    TextColor3 = VelourUI.Settings.Theme.TextDark,
                    Font = VelourUI.Settings.Theme.TextFont,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right
                })
                ValueText.Parent = SliderFrame
                Reg(ValueText, "TextColor3", "TextDark")
                Reg(ValueText, "Font", "TextFont")

                local TrackBg = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 8),
                    Position = UDim2.new(0, 0, 0, 22),
                    BackgroundColor3 = VelourUI.Settings.Theme.Background,
                    BackgroundTransparency = VelourUI.Settings.Theme.SectionTransparency,
                    BorderSizePixel = 0
                }, {
                    Create("UICorner", {
                        CornerRadius = UDim.new(1, 0)
                    }),
                    ThemeStroke()
                })
                TrackBg.Parent = SliderFrame
                Reg(TrackBg, "BackgroundColor3", "Background")
                Reg(TrackBg, "BackgroundTransparency", "SectionTransparency")

                local Fill = Create("Frame", {
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = VelourUI.Settings.Theme.Accent,
                    BorderSizePixel = 0
                }, {
                    Create("UICorner", {
                        CornerRadius = UDim.new(1, 0)
                    })
                })
                Fill.Parent = TrackBg
                Reg(Fill, "BackgroundColor3", "Accent")

                local TouchZone = Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 10),
                    Position = UDim2.new(0, 0, 0, -5),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 3
                })
                TouchZone.Parent = TrackBg

                local dragging = false
                local startX = 0
                local startRel = (default - min) / (max - min)
                local currentRel = startRel
                local startTrackWidth = 0

                local function setSlider(rel, noCb)
                    rel = math.clamp(rel, 0, 1)
                    currentRel = rel
                    local val = math.floor(min + (max - min) * rel)
                    ValueText.Text = tostring(val)
                    Tween(Fill, {
                        Size = UDim2.new(rel, 0, 1, 0)
                    }, 0.05)
                    if not noCb then
                        pcall(callback, val)
                    end
                end

                TouchZone.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        startX = input.Position.X
                        currentRel = (input.Position.X - TrackBg.AbsolutePosition.X) / TrackBg.AbsoluteSize.X
                        startRel = currentRel
                        startTrackWidth = TrackBg.AbsoluteSize.X
                        setSlider(currentRel)
                    end
                end)

                WindowObj:ConnectSignal(UIS.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                WindowObj:ConnectSignal(UIS.InputChanged, function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setSlider(startRel + ((input.Position.X - startX) / startTrackWidth))
                    end
                end)

                RegisterFlag(options.Flag, function()
                    return math.floor(min + (max - min) * currentRel)
                end, function(v, noCb)
                    setSlider((v - min) / (max - min), noCb)
                end)
                
                pcall(callback, default)
                
                return {
                    Set = function(v, noCb)
                        setSlider((v - min) / (max - min), noCb)
                    end,
                    Get = function()
                        return math.floor(min + (max - min) * currentRel)
                    end
                }
            end

            function SectionObj:CreateKeybind(options)
                local kName = options.Name or "Keybind"
                local defaultKey = options.Default or Enum.KeyCode.E
                local callback = options.Callback or function()
                end

                local key = defaultKey
                local binding = false
                local BindFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1
                })
                BindFrame.Parent = InnerContainer

                local kbCheckbox = Create("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 0, 0.5, -8),
                    BackgroundColor3 = VelourUI.Settings.Theme.Background,
                    BackgroundTransparency = VelourUI.Settings.Theme.SectionTransparency,
                    Visible = isMobile
                }, {
                    ThemeCorner(),
                    ThemeStroke()
                })
                Reg(kbCheckbox, "BackgroundColor3", "Background")
                Reg(kbCheckbox, "BackgroundTransparency", "SectionTransparency")
                kbCheckbox.Parent = BindFrame

                local kbCheckInner = Create("Frame", {
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = VelourUI.Settings.Theme.Accent,
                    BackgroundTransparency = 1
                }, {
                    ThemeCorner()
                })
                Reg(kbCheckInner, "BackgroundColor3", "Accent")
                kbCheckInner.Parent = kbCheckbox

                local kbCheckBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Visible = isMobile
                })
                kbCheckBtn.Parent = kbCheckbox

                local labelSize
                if isMobile then
                    labelSize = UDim2.new(0.45, -20, 1, 0)
                else
                    labelSize = UDim2.new(0.45, 0, 1, 0)
                end
                
                local labelPos
                if isMobile then
                    labelPos = UDim2.new(0, 22, 0, 0)
                else
                    labelPos = UDim2.new(0, 0, 0, 0)
                end

                local Label = Create("TextLabel", {
                    Size = labelSize,
                    Position = labelPos,
                    BackgroundTransparency = 1,
                    Text = kName,
                    TextColor3 = VelourUI.Settings.Theme.Text,
                    Font = VelourUI.Settings.Theme.TextFont,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                Label.Parent = BindFrame
                Reg(Label, "TextColor3", "Text")
                Reg(Label, "Font", "TextFont")

                local BindPlate = Create("Frame", {
                    Size = UDim2.new(0.55, 0, 0, 26),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = VelourUI.Settings.Theme.SectionBg,
                    BackgroundTransparency = VelourUI.Settings.Theme.SectionTransparency,
                    BorderSizePixel = 0
                }, {
                    ThemeCorner(),
                    ThemeStroke()
                })
                BindPlate.Parent = BindFrame
                Reg(BindPlate, "BackgroundColor3", "SectionBg")
                Reg(BindPlate, "BackgroundTransparency", "SectionTransparency")

                local BindBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = GetKeyName(key),
                    TextColor3 = VelourUI.Settings.Theme.Accent,
                    Font = VelourUI.Settings.Theme.TitleFont,
                    TextSize = 12,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                BindBtn.Parent = BindPlate
                Reg(BindBtn, "TextColor3", "Accent")
                Reg(BindBtn, "Font", "TitleFont")

                local onScreenBtn = nil
                local isKbChecked = false

                local function ToggleOnScreenBtn()
                    isKbChecked = not isKbChecked
                    if isKbChecked then
                        Tween(kbCheckInner, {
                            Size = UDim2.new(0, 8, 0, 8),
                            BackgroundTransparency = 0
                        }, 0.2)
                        
                        if not onScreenBtn then
                            onScreenBtn = Create("TextButton", {
                                Size = UDim2.new(0, 45, 0, 45),
                                Position = UDim2.new(0.8, 0, 0.8, 0),
                                BackgroundColor3 = VelourUI.Settings.Theme.Background,
                                BackgroundTransparency = VelourUI.Settings.Theme.ElementsTransparency,
                                Text = GetKeyName(key),
                                TextColor3 = VelourUI.Settings.Theme.Text,
                                Font = VelourUI.Settings.Theme.TitleFont,
                                TextSize = 18,
                                ZIndex = 100
                            }, {
                                ThemeCorner(),
                                ThemeStroke()
                            })
                            Reg(onScreenBtn, "BackgroundColor3", "Background")
                            Reg(onScreenBtn, "BackgroundTransparency", "ElementsTransparency")
                            Reg(onScreenBtn, "TextColor3", "Text")
                            Reg(onScreenBtn, "Font", "TitleFont")
                            onScreenBtn.Parent = ScreenGui

                            local osDragging = false
                            local osInput = nil
                            local osPos = nil
                            local osFramePos = nil
                            local dragDist = 0
                            
                            onScreenBtn.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                    osDragging = true
                                    osPos = input.Position
                                    osFramePos = onScreenBtn.Position
                                    dragDist = 0
                                    input.Changed:Connect(function()
                                        if input.UserInputState == Enum.UserInputState.End then
                                            osDragging = false
                                        end
                                    end)
                                end
                            end)
                            
                            onScreenBtn.InputChanged:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                    osInput = input
                                end
                            end)
                            
                            WindowObj:ConnectSignal(UIS.InputChanged, function(input)
                                if input == osInput and osDragging then
                                    local delta = input.Position - osPos
                                    dragDist = dragDist + delta.Magnitude
                                    onScreenBtn.Position = UDim2.new(osFramePos.X.Scale, osFramePos.X.Offset + delta.X, osFramePos.Y.Scale, osFramePos.Y.Offset + delta.Y)
                                end
                            end)
                            
                            onScreenBtn.MouseButton1Click:Connect(function()
                                if dragDist < 10 then
                                    pcall(callback, key, false)
                                end
                            end)
                        end
                        onScreenBtn.Visible = true
                    else
                        Tween(kbCheckInner, {
                            Size = UDim2.new(0, 0, 0, 0),
                            BackgroundTransparency = 1
                        }, 0.2)
                        
                        if onScreenBtn then
                            onScreenBtn.Visible = false
                        end
                    end
                end

                kbCheckBtn.MouseButton1Click:Connect(ToggleOnScreenBtn)

                local function SetKey(v, noCb)
                    key = v
                    BindBtn.Text = GetKeyName(key)
                    if onScreenBtn then
                        onScreenBtn.Text = GetKeyName(key)
                    end
                    WindowObj.ActiveKeybinds[kName] = key
                    WindowObj:UpdateKeybindsPanel()
                    if not noCb then
                        pcall(callback, key, true)
                    end
                end

                BindBtn.MouseButton1Click:Connect(function()
                    binding = true
                    BindBtn.Text = "..."
                end)
                
                WindowObj:ConnectSignal(UIS.InputBegan, function(input, gp)
                    if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                        SetKey(input.KeyCode)
                        binding = false
                        pcall(callback, key, true)
                    elseif input.KeyCode == key and not binding and not gp then
                        pcall(callback, key, false)
                    end
                end)

                WindowObj.ActiveKeybinds[kName] = key
                WindowObj:UpdateKeybindsPanel()

                RegisterFlag(options.Flag, function()
                    return key.Name
                end, function(v, noCb)
                    local k = Enum.KeyCode[v]
                    if k then
                        SetKey(k, noCb)
                    end
                end)
                
                pcall(callback, key, false)
                
                return {
                    Set = function(v, noCb)
                        local k = Enum.KeyCode[v]
                        if k then
                            SetKey(k, noCb)
                        end
                    end,
                    Get = function()
                        return key
                    end
                }
            end

            function SectionObj:CreateInput(options)
                local iName = options.Name or "Input"
                local placeholder = options.Placeholder or ""
                local callback = options.Callback or function()
                end

                local InputFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1
                })
                InputFrame.Parent = InnerContainer

                local Label = Create("TextLabel", {
                    Size = UDim2.new(0.45, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = iName,
                    TextColor3 = VelourUI.Settings.Theme.Text,
                    Font = VelourUI.Settings.Theme.TextFont,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                Label.Parent = InputFrame
                Reg(Label, "TextColor3", "Text")
                Reg(Label, "Font", "TextFont")

                local InputPlate = Create("Frame", {
                    Size = UDim2.new(0.55, 0, 0, 26),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = VelourUI.Settings.Theme.SectionBg,
                    BackgroundTransparency = VelourUI.Settings.Theme.SectionTransparency, 
                    BorderSizePixel = 0,
                    ClipsDescendants = true 
                }, {
                    ThemeCorner(),
                    ThemeStroke()
                })
                InputPlate.Parent = InputFrame
                Reg(InputPlate, "BackgroundColor3", "SectionBg")
                Reg(InputPlate, "BackgroundTransparency", "SectionTransparency")

                local TextBox = Create("TextBox", {
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    PlaceholderText = placeholder or "",
                    TextColor3 = VelourUI.Settings.Theme.Text,
                    PlaceholderColor3 = VelourUI.Settings.Theme.TextDark,
                    Font = VelourUI.Settings.Theme.TextFont,
                    TextSize = 13,
                    ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                TextBox.Parent = InputPlate
                Reg(TextBox, "TextColor3", "Text")
                Reg(TextBox, "Font", "TextFont")

                local textTween = nil
                
                local function UpdateTextScroll()
                    if textTween then
                        textTween:Cancel()
                        textTween = nil
                    end
                    local maxW = InputPlate.AbsoluteSize.X - 12
                    local textSize = TxS:GetTextSize(TextBox.Text, 13, VelourUI.Settings.Theme.TextFont, Vector2.new(9999, 26))
                    
                    if textSize.X > maxW then
                        TextBox.Size = UDim2.new(0, textSize.X + 6, 1, 0)
                    else
                        TextBox.Size = UDim2.new(1, -12, 1, 0)
                    end
                    
                    TextBox.Position = UDim2.new(0, 6, 0, 0)
                    
                    if textSize.X > maxW and not TextBox:IsFocused() then
                        local overflow = textSize.X - maxW
                        textTween = TS:Create(TextBox, TweenInfo.new(overflow / 30, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                            Position = UDim2.new(0, 6 - overflow, 0, 0)
                        })
                        textTween:Play()
                    end
                end

                TextBox.Focused:Connect(function()
                    if textTween then
                        textTween:Cancel()
                        textTween = nil
                    end
                    TextBox.Position = UDim2.new(0, 6, 0, 0)
                end)

                TextBox.FocusLost:Connect(function()
                    UpdateTextScroll()
                    pcall(callback, TextBox.Text)
                end)
                
                local function SetVal(v, noCb)
                    TextBox.Text = tostring(v)
                    UpdateTextScroll()
                    if not noCb then
                        pcall(callback, TextBox.Text)
                    end
                end

                RegisterFlag(options.Flag, function()
                    return TextBox.Text
                end, function(v, noCb)
                    SetVal(v, noCb)
                end)
                
                pcall(callback, TextBox.Text)
                
                return {
                    Set = SetVal,
                    Get = function()
                        return TextBox.Text
                    end
                }
            end

            function SectionObj:CreateDropdown(options)
                local dName = options.Name or "Dropdown"
                local list = options.Options or {}
                local default = options.Default
                local callback = options.Callback or function()
                end

                local dropped = false
                local selected = default or (list[1] or "")

                local DropWrapper = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    ClipsDescendants = false
                })
                DropWrapper.Parent = InnerContainer

                local Label = Create("TextLabel", {
                    Size = UDim2.new(0.45, 0, 0, 26),
                    BackgroundTransparency = 1,
                    Text = dName,
                    TextColor3 = VelourUI.Settings.Theme.Text,
                    Font = VelourUI.Settings.Theme.TextFont,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                Label.Parent = DropWrapper
                Reg(Label, "TextColor3", "Text")
                Reg(Label, "Font", "TextFont")

                local DropPlate = Create("Frame", {
                    Size = UDim2.new(0.55, 0, 0, 26),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = VelourUI.Settings.Theme.SectionBg,
                    BackgroundTransparency = VelourUI.Settings.Theme.SectionTransparency, 
                    ClipsDescendants = true,
                    ZIndex = 10
                }, {
                    ThemeCorner(),
                    ThemeStroke()
                })
                DropPlate.Parent = DropWrapper
                Reg(DropPlate, "BackgroundColor3", "SectionBg")
                Reg(DropPlate, "BackgroundTransparency", "SectionTransparency")

                local DropBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    Text = "  " .. tostring(selected),
                    TextColor3 = VelourUI.Settings.Theme.Text,
                    Font = VelourUI.Settings.Theme.TextFont,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 11,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                DropBtn.Parent = DropPlate
                Reg(DropBtn, "TextColor3", "Text")
                Reg(DropBtn, "Font", "TextFont")

                local Arrow = Create("TextLabel", {
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -15, 0, 3),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "+",
                    TextColor3 = VelourUI.Settings.Theme.TextDark,
                    Font = VelourUI.Settings.Theme.TitleFont,
                    TextSize = 14,
                    ZIndex = 12
                })
                Arrow.Parent = DropPlate
                Reg(Arrow, "TextColor3", "TextDark")
                Reg(Arrow, "Font", "TitleFont")

                local Divider = Create("Frame", {
                    Size = UDim2.new(1, -12, 0, 1),
                    Position = UDim2.new(0, 6, 0, 25),
                    BackgroundColor3 = VelourUI.Settings.Theme.Stroke,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    ZIndex = 12
                })
                Divider.Parent = DropPlate
                Reg(Divider, "BackgroundColor3", "Stroke")

                local ListContainer = Create("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 1, -26),
                    Position = UDim2.new(0, 0, 0, 26),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 0,
                    CanvasSize = UDim2.new(0,0,0,0),
                    ZIndex = 11
                }, {
                    Create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }),
                    Create("UIPadding", {
                        PaddingBottom = UDim.new(0, 4)
                    })
                })
                ListContainer.Parent = DropPlate

                local function SetValue(v, noCb)
                    selected = v
                    DropBtn.Text = "  " .. tostring(v)
                    if not noCb then
                        pcall(callback, v)
                    end
                end

                local function RefreshList(newList, keepSelected)
                    list = newList
                    for _, child in ipairs(ListContainer:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    
                    local found = false
                    for _, i in ipairs(list) do
                        if i == selected then
                            found = true
                            break
                        end
                    end
                    
                    if not found and not keepSelected then
                        SetValue(list[1] or "", true)
                    end

                    local h = 0
                    for _, item in ipairs(list) do
                        local btn = Create("TextButton", {
                            Size = UDim2.new(1, -6, 0, 22),
                            BackgroundTransparency = 1,
                            Text = "  "..tostring(item),
                            TextColor3 = VelourUI.Settings.Theme.Text,
                            Font = VelourUI.Settings.Theme.TextFont,
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 11,
                            TextTruncate = Enum.TextTruncate.AtEnd
                        })
                        Reg(btn, "TextColor3", "Text")
                        Reg(btn, "Font", "TextFont")
                        btn.Parent = ListContainer
                        
                        btn.MouseButton1Click:Connect(function()
                            SetValue(item)
                            dropped = false
                            Tween(DropPlate, {
                                Size = UDim2.new(0.55, 0, 0, 26)
                            }, 0.3)
                            Tween(DropWrapper, {
                                Size = UDim2.new(1, 0, 0, 26)
                            }, 0.3)
                            Tween(Arrow, {
                                Rotation = 0
                            }, 0.3)
                            Arrow.Text = "+"
                            Tween(Divider, {
                                BackgroundTransparency = 1
                            }, 0.1)
                        end)
                        h = h + 22
                    end
                    ListContainer.CanvasSize = UDim2.new(0, 0, 0, h + 4)
                    
                    if dropped then
                        local newH = math.clamp(h, 0, 110)
                        Tween(DropPlate, {
                            Size = UDim2.new(0.55, 0, 0, 26 + newH + 6)
                        }, 0.3)
                        Tween(DropWrapper, {
                            Size = UDim2.new(1, 0, 0, 26 + newH + 6)
                        }, 0.3)
                    end
                end
                RefreshList(list)

                DropBtn.MouseButton1Click:Connect(function()
                    dropped = not dropped
                    local h = math.clamp(#list * 22, 0, 110)
                    local targetHeight
                    if dropped then
                        targetHeight = 26 + h + 6
                    else
                        targetHeight = 26
                    end
                    
                    Tween(DropPlate, {
                        Size = UDim2.new(0.55, 0, 0, targetHeight)
                    }, 0.3)
                    Tween(DropWrapper, {
                        Size = UDim2.new(1, 0, 0, targetHeight)
                    }, 0.3)
                    
                    if dropped then
                        Tween(Arrow, {Rotation = 180}, 0.3)
                        Arrow.Text = "-"
                        Tween(Divider, {BackgroundTransparency = 0}, 0.1)
                    else
                        Tween(Arrow, {Rotation = 0}, 0.3)
                        Arrow.Text = "+"
                        Tween(Divider, {BackgroundTransparency = 1}, 0.1)
                    end
                end)

                RegisterFlag(options.Flag, function()
                    return selected
                end, function(v, noCb)
                    SetValue(v, noCb)
                end)
                
                pcall(callback, selected)
                
                return {
                    Refresh = RefreshList,
                    Set = SetValue,
                    Get = function()
                        return selected
                    end,
                    GetOptions = function()
                        return list
                    end
                }
            end

            function SectionObj:CreateColorPicker(options)
                local cName = options.Name or "Color Picker"
                local default = options.Default or Color3.fromRGB(255, 255, 255)
                local callback = options.Callback or function()
                end

                local h, s, v = default:ToHSV()
                local dropped = false

                local CPFrame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true
                })
                CPFrame.Parent = InnerContainer

                local CPBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Text = cName,
                    TextColor3 = VelourUI.Settings.Theme.Text,
                    Font = VelourUI.Settings.Theme.TextFont,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                CPBtn.Parent = CPFrame
                Reg(CPBtn, "TextColor3", "Text")
                Reg(CPBtn, "Font", "TextFont")

                local ColorIndicator = Create("Frame", {
                    Size = UDim2.new(0, 28, 0, 14),
                    Position = UDim2.new(1, -30, 0.5, -7),
                    BackgroundColor3 = default
                }, {
                    ThemeCorner(),
                    ThemeStroke()
                })
                ColorIndicator.Parent = CPBtn

                local PaletteMap = Create("ImageButton", {
                    Size = UDim2.new(1, 0, 0, 100),
                    Position = UDim2.new(0, 0, 0, 30),
                    Image = "rbxassetid://4155801252",
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    AutoButtonColor = false
                }, {
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    })
                })
                PaletteMap.Parent = CPFrame

                local PickerCircle = Create("Frame", {
                    Size = UDim2.new(0, 8, 0, 8),
                    Position = UDim2.new(s, 0, 1 - v, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 1,
                    BorderColor3 = Color3.fromRGB(0, 0, 0)
                }, {
                    Create("UICorner", {
                        CornerRadius = UDim.new(1, 0)
                    })
                })
                PickerCircle.Parent = PaletteMap

                local HueSlider = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 10),
                    Position = UDim2.new(0, 0, 0, 136),
                    Text = "",
                    AutoButtonColor = false
                }, {
                    Create("UICorner", {
                        CornerRadius = UDim.new(0, 4)
                    }),
                    Create("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                        })
                    })
                })
                HueSlider.Parent = CPFrame

                local HueMarker = Create("Frame", {
                    Size = UDim2.new(0, 2, 1, 4),
                    Position = UDim2.new(h, -1, 0, -2),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0
                })
                HueMarker.Parent = HueSlider

                local RGBContainer = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.new(0, 0, 0, 154),
                    BackgroundTransparency = 1
                })
                RGBContainer.Parent = CPFrame

                local function CreateColorInput(textLabel, posX, defVal)
                    local cFrame = Create("Frame", {
                        Size = UDim2.new(0.31, 0, 1, 0),
                        Position = posX,
                        BackgroundColor3 = VelourUI.Settings.Theme.Background,
                        BackgroundTransparency = VelourUI.Settings.Theme.SectionTransparency,
                        BorderSizePixel = 0
                    }, {
                        ThemeCorner(),
                        ThemeStroke()
                    })
                    Reg(cFrame, "BackgroundColor3", "Background")
                    Reg(cFrame, "BackgroundTransparency", "SectionTransparency")
                    
                    local cLabel = Create("TextLabel", {
                        Size = UDim2.new(0, 16, 1, 0),
                        Position = UDim2.new(0, 4, 0, 0),
                        BackgroundTransparency = 1,
                        Text = textLabel,
                        TextColor3 = VelourUI.Settings.Theme.TextDark,
                        Font = VelourUI.Settings.Theme.TextFont,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    cLabel.Parent = cFrame
                    Reg(cLabel, "TextColor3", "TextDark")
                    Reg(cLabel, "Font", "TextFont")
                    
                    local cBox = Create("TextBox", {
                        Size = UDim2.new(1, -18, 1, 0),
                        Position = UDim2.new(0, 16, 0, 0),
                        BackgroundTransparency = 1,
                        Text = tostring(math.floor(defVal * 255)),
                        TextColor3 = VelourUI.Settings.Theme.Text,
                        Font = VelourUI.Settings.Theme.TextFont,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ClearTextOnFocus = false
                    })
                    cBox.Parent = cFrame
                    Reg(cBox, "TextColor3", "Text")
                    Reg(cBox, "Font", "TextFont")
                    
                    cFrame.Parent = RGBContainer
                    return cBox
                end

                local rBox = CreateColorInput("R:", UDim2.new(0.02, 0, 0, 0), default.R)
                local gBox = CreateColorInput("G:", UDim2.new(0.345, 0, 0, 0), default.G)
                local bBox = CreateColorInput("B:", UDim2.new(0.67, 0, 0, 0), default.B)

                CPBtn.MouseButton1Click:Connect(function()
                    dropped = not dropped
                    local currentSize
                    if dropped then
                        currentSize = 182
                    else
                        currentSize = 24
                    end
                    Tween(CPFrame, {
                        Size = UDim2.new(1, 0, 0, currentSize)
                    })
                end)

                local function UpdateColor()
                    local finalColor = Color3.fromHSV(h, s, v)
                    ColorIndicator.BackgroundColor3 = finalColor
                    PaletteMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    rBox.Text = tostring(math.floor(finalColor.R * 255))
                    gBox.Text = tostring(math.floor(finalColor.G * 255))
                    bBox.Text = tostring(math.floor(finalColor.B * 255))
                    pcall(callback, finalColor)
                end

                local function UpdateFromRGB()
                    local r = math.clamp(tonumber(rBox.Text) or 0, 0, 255) / 255
                    local g = math.clamp(tonumber(gBox.Text) or 0, 0, 255) / 255
                    local b = math.clamp(tonumber(bBox.Text) or 0, 0, 255) / 255
                    local c = Color3.new(r, g, b)
                    local nH, nS, nV = c:ToHSV()
                    if nV > 0.001 then
                        s = nS
                    end
                    if nS > 0.001 and nV > 0.001 then
                        h = nH
                    end
                    v = nV
                    PickerCircle.Position = UDim2.new(math.clamp(s, 0.04, 0.96), 0, math.clamp(1 - v, 0.04, 0.96), 0)
                    HueMarker.Position = UDim2.new(h, -1, 0, -2)
                    UpdateColor()
                end

                local function SetColor(val, noCallback)
                    if type(val) == "table" and #val == 3 then
                        local c = Color3.new(val[1], val[2], val[3])
                        local nH, nS, nV = c:ToHSV()
                        if nV > 0.001 then
                            s = nS
                        end
                        if nS > 0.001 and nV > 0.001 then
                            h = nH
                        end
                        v = nV
                    elseif typeof(val) == "Color3" then
                        local nH, nS, nV = val:ToHSV()
                        if nV > 0.001 then
                            s = nS
                        end
                        if nS > 0.001 and nV > 0.001 then
                            h = nH
                        end
                        v = nV
                    end
                    PickerCircle.Position = UDim2.new(math.clamp(s, 0.04, 0.96), 0, math.clamp(1 - v, 0.04, 0.96), 0)
                    HueMarker.Position = UDim2.new(h, -1, 0, -2)
                    
                    local finalColor = Color3.fromHSV(h, s, v)
                    ColorIndicator.BackgroundColor3 = finalColor
                    PaletteMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    rBox.Text = tostring(math.floor(finalColor.R * 255))
                    gBox.Text = tostring(math.floor(finalColor.G * 255))
                    bBox.Text = tostring(math.floor(finalColor.B * 255))
                    if not noCallback then
                        pcall(callback, finalColor)
                    end
                end

                rBox.FocusLost:Connect(UpdateFromRGB)
                gBox.FocusLost:Connect(UpdateFromRGB)
                bBox.FocusLost:Connect(UpdateFromRGB)

                local dragSV = false
                local dragHue = false
                
                PaletteMap.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragSV = true
                    end
                end)
                
                HueSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragHue = true
                    end
                end)
                
                WindowObj:ConnectSignal(UIS.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragSV = false
                        dragHue = false
                    end
                end)
                
                WindowObj:ConnectSignal(UIS.InputChanged, function(input)
                    if dragSV and input.UserInputType == Enum.UserInputType.MouseMovement then
                        s = math.clamp((input.Position.X - PaletteMap.AbsolutePosition.X) / PaletteMap.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((input.Position.Y - PaletteMap.AbsolutePosition.Y) / PaletteMap.AbsoluteSize.Y, 0, 1)
                        PickerCircle.Position = UDim2.new(math.clamp(s, 0.04, 0.96), 0, math.clamp(1 - v, 0.04, 0.96), 0)
                        UpdateColor()
                    elseif dragHue and input.UserInputType == Enum.UserInputType.MouseMovement then
                        h = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                        HueMarker.Position = UDim2.new(h, -1, 0, -2)
                        UpdateColor()
                    end
                end)

                RegisterFlag(options.Flag, function()
                    return {Color3.fromHSV(h, s, v).R, Color3.fromHSV(h, s, v).G, Color3.fromHSV(h, s, v).B}
                end, SetColor)
                
                pcall(callback, default)
                
                return {
                    Set = SetColor
                }
            end

            return SectionObj
        end
        return TabObj
    end

    local SettingsTab = WindowObj:CreateTab({
        Name = "UI Settings",
        Icon = "7059346373",
        IsSettings = true
    })
    
    local ThemeSec = SettingsTab:CreateSection({
        Name = "Colors",
        Side = "Left"
    })
    
    local MiscSec = SettingsTab:CreateSection({
        Name = "Customization",
        Side = "Right"
    })

    local pickerAccent = ThemeSec:CreateColorPicker({
        Name = "Accent Color",
        Default = VelourUI.Settings.Theme.Accent,
        Callback = function(c)
            WindowObj:UpdateTheme("Accent", c)
        end
    })
    
    local pickerBg = ThemeSec:CreateColorPicker({
        Name = "Background Color",
        Default = VelourUI.Settings.Theme.Background,
        Callback = function(c)
            WindowObj:UpdateTheme("Background", c)
        end
    })
    
    local pickerSecBg = ThemeSec:CreateColorPicker({
        Name = "Section Overlay",
        Default = VelourUI.Settings.Theme.SectionBg,
        Callback = function(c)
            WindowObj:UpdateTheme("SectionBg", c)
        end
    })
    
    local pickerStroke = ThemeSec:CreateColorPicker({
        Name = "Stroke (Outlines)",
        Default = VelourUI.Settings.Theme.Stroke,
        Callback = function(c)
            WindowObj:UpdateTheme("Stroke", c)
        end
    })
    
    local pickerText = ThemeSec:CreateColorPicker({
        Name = "Text Color",
        Default = VelourUI.Settings.Theme.Text,
        Callback = function(c)
            WindowObj:UpdateTheme("Text", c)
        end
    })
    
    local pickerTextDark = ThemeSec:CreateColorPicker({
        Name = "Subtext Color",
        Default = VelourUI.Settings.Theme.TextDark,
        Callback = function(c)
            WindowObj:UpdateTheme("TextDark", c)
        end
    })

    WindowObj.ThemeUpdaters["Accent"] = pickerAccent.Set
    WindowObj.ThemeUpdaters["Background"] = pickerBg.Set
    WindowObj.ThemeUpdaters["SectionBg"] = pickerSecBg.Set
    WindowObj.ThemeUpdaters["Stroke"] = pickerStroke.Set
    WindowObj.ThemeUpdaters["Text"] = pickerText.Set
    WindowObj.ThemeUpdaters["TextDark"] = pickerTextDark.Set

    local scaleSlider = MiscSec:CreateSlider({
        Name = "UI Scale",
        Min = 70,
        Max = 120,
        Default = VelourUI.Settings.Theme.CurrentScale and VelourUI.Settings.Theme.CurrentScale * 100 or 100,
        Callback = function(val)
            VelourUI.Settings.Theme.CurrentScale = val / 100
            WindowObj.CurrentScale = val / 100
            if WindowObj.IsOpen then
                WindowObj.ScaleObj.Scale = WindowObj.CurrentScale
            end
            for _, tab in ipairs(WindowObj.Tabs) do
                if tab.Content.Visible then
                    local lc = tab.Content:FindFirstChild("LeftColumn")
                    local rc = tab.Content:FindFirstChild("RightColumn")
                    if lc and rc then
                        local contentHeight = math.max(lc.UIListLayout.AbsoluteContentSize.Y, rc.UIListLayout.AbsoluteContentSize.Y)
                        tab.Content.CanvasSize = UDim2.new(0, 0, 0, math.ceil(contentHeight / WindowObj.CurrentScale) + 30)
                    end
                end
            end
            
            task.defer(function()
                if activeTabRecord then
                    local targetY = (activeTabRecord.Button.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y) / WindowObj.CurrentScale
                    HighlightBox.Position = UDim2.new(0, 6, 0, targetY)
                end
            end)
        end
    })
    
    local radSlider = MiscSec:CreateSlider({
        Name = "Global Corner Radius",
        Min = 0,
        Max = 20,
        Default = VelourUI.Settings.Theme.CornerRadius.Offset,
        Callback = function(val)
            WindowObj:UpdateTheme("CornerRadius", val)
        end
    })
    
    local bgTrSlider = MiscSec:CreateSlider({
        Name = "Background Transparency",
        Min = 0,
        Max = 100,
        Default = VelourUI.Settings.Theme.BgTransparency * 100,
        Callback = function(val)
            WindowObj:UpdateTheme("BgTransparency", val / 100)
        end
    })
    
    local secTrSlider = MiscSec:CreateSlider({
        Name = "Section Transparency",
        Min = 0,
        Max = 100,
        Default = VelourUI.Settings.Theme.SectionTransparency * 100,
        Callback = function(val)
            WindowObj:UpdateTheme("SectionTransparency", val / 100)
        end
    })
    
    local elemTrSlider = MiscSec:CreateSlider({
        Name = "Elements Transparency",
        Min = 0,
        Max = 100,
        Default = VelourUI.Settings.Theme.ElementsTransparency * 100,
        Callback = function(val)
            WindowObj:UpdateTheme("ElementsTransparency", val / 100)
        end
    })
    
    MiscSec:CreateLabel({
        Name = "-- Fonts & Images --"
    })
    
    local titleFntDrop = MiscSec:CreateDropdown({
        Name = "Title Font",
        Options = FontList,
        Default = VelourUI.Settings.Theme.TitleFont.Name,
        Callback = function(val)
            WindowObj:UpdateTheme("TitleFont", Enum.Font[val])
        end
    })
    
    local textFntDrop = MiscSec:CreateDropdown({
        Name = "Text Font",
        Options = FontList,
        Default = VelourUI.Settings.Theme.TextFont.Name,
        Callback = function(val)
            WindowObj:UpdateTheme("TextFont", Enum.Font[val])
        end
    })
    
    local bgImgInput = MiscSec:CreateInput({
        Name = "Background Image ID",
        Placeholder = "Enter Asset ID...",
        Callback = function(val)
            WindowObj:UpdateTheme("BackgroundImage", val)
        end
    })
    
    local bgImgTrSlider = MiscSec:CreateSlider({
        Name = "Image Transparency",
        Min = 0,
        Max = 100,
        Default = VelourUI.Settings.Theme.BgImageTransparency * 100,
        Callback = function(val)
            WindowObj:UpdateTheme("BgImageTransparency", val / 100)
        end
    })
    
    MiscSec:CreateKeybind({
        Name = "Toggle UI Key",
        Default = WindowObj.ToggleKey,
        Callback = function(key, isRebind)
            if isRebind then
                WindowObj.ToggleKey = key
            end
        end
    })

    WindowObj.ThemeUpdaters["CurrentScale"] = function(v, noCb)
        scaleSlider.Set(v * 100, noCb)
    end
    WindowObj.ThemeUpdaters["CornerRadius"] = function(v, noCb)
        local value
        if type(v) == "number" then
            value = v
        else
            value = v.Offset
        end
        radSlider.Set(value, noCb)
    end
    WindowObj.ThemeUpdaters["BgTransparency"] = function(v, noCb)
        bgTrSlider.Set(v * 100, noCb)
    end
    WindowObj.ThemeUpdaters["SectionTransparency"] = function(v, noCb)
        secTrSlider.Set(v * 100, noCb)
    end
    WindowObj.ThemeUpdaters["ElementsTransparency"] = function(v, noCb)
        elemTrSlider.Set(v * 100, noCb)
    end
    WindowObj.ThemeUpdaters["TitleFont"] = function(v, noCb)
        titleFntDrop.Set(v.Name, noCb)
    end
    WindowObj.ThemeUpdaters["TextFont"] = function(v, noCb)
        textFntDrop.Set(v.Name, noCb)
    end
    WindowObj.ThemeUpdaters["BackgroundImage"] = function(v, noCb)
        bgImgInput.Set(v, noCb)
    end
    WindowObj.ThemeUpdaters["BgImageTransparency"] = function(v, noCb)
        bgImgTrSlider.Set(v * 100, noCb)
    end

    local ConfigSec = SettingsTab:CreateSection({
        Name = "Configurations",
        Side = "Left"
    })
    
    local cfgInput = ConfigSec:CreateInput({
        Name = "Config Name",
        Placeholder = "Type to Save..."
    })
    
    local function GetFiles(folder)
        local list = {}
        for _, f in ipairs(list_files(folder)) do
            local name = f:match("([^/\\]+)%.json$")
            if name then
                table.insert(list, name)
            end
        end
        return list
    end

    local function ArrayEquals(a, b)
        if #a ~= #b then
            return false
        end
        for i=1, #a do
            if a[i] ~= b[i] then
                return false
            end
        end
        return true
    end

    local cfgDropdown = ConfigSec:CreateDropdown({
        Name = "Select Config",
        Options = GetFiles(configFolder)
    })

    local autoLoadEnabled = false
    local autoLoadFile = configFolder .. "/autoload.txt"

    local function RealCfgLoad(name)
        local raw = read_file(configFolder .. "/" .. name .. ".json")
        if raw then
            local data = HS:JSONDecode(raw)
            for flag, val in pairs(data) do
                if WindowObj.Flags[flag] then
                    WindowObj.Flags[flag].Set(val, false)
                end
            end
            WindowObj:Notify({
                Title = "System",
                Text = "Config Loaded: " .. name,
                Duration = 3
            })
            if autoLoadEnabled then
                write_file(autoLoadFile, name)
            end
        end
    end

    ConfigSec:CreateButton({
        Name = "Load Config",
        Callback = function()
            local name = cfgDropdown.Get()
            if name and name ~= "" then
                RealCfgLoad(name)
            end
        end
    })

    ConfigSec:CreateButton({
        Name = "Save Config",
        Callback = function()
            local name = cfgInput.Get()
            if name and name ~= "" then
                name = name:gsub("%.json$", "") 
                local data = {}
                for flag, obj in pairs(WindowObj.Flags) do
                    data[flag] = obj.Get()
                end
                write_file(configFolder .. "/" .. name .. ".json", HS:JSONEncode(data))
                cfgDropdown.Refresh(GetFiles(configFolder), true)
                WindowObj:Notify({
                    Title = "System",
                    Text = "Config Saved: " .. name,
                    Duration = 3
                })
            end
        end
    })

    ConfigSec:CreateButton({
        Name = "Delete Config",
        Callback = function()
            local name = cfgDropdown.Get()
            if name and name ~= "" then
                del_file(configFolder .. "/" .. name .. ".json")
                local upList = GetFiles(configFolder)
                cfgDropdown.Refresh(upList)
                WindowObj:Notify({
                    Title = "System",
                    Text = "Config Deleted: " .. name,
                    Duration = 3
                })
            end
        end
    })

    if is_file(autoLoadFile) then
        autoLoadEnabled = true
        local nameToLoad = read_file(autoLoadFile)
        if nameToLoad and is_file(configFolder .. "/" .. nameToLoad .. ".json") then
            task.spawn(function()
                task.wait(1)
                RealCfgLoad(nameToLoad)
                cfgDropdown.Set(nameToLoad, true)
            end)
        end
    end

    ConfigSec:CreateToggle({
        Name = "Auto-Load Selected",
        Default = autoLoadEnabled,
        Callback = function(state)
            autoLoadEnabled = state
            if state then
                local name = cfgDropdown.Get()
                if name and name ~= "" then
                    write_file(autoLoadFile, name)
                end
            else
                if is_file(autoLoadFile) then
                    del_file(autoLoadFile)
                end
            end
        end
    })

    local ThemeSecOption = SettingsTab:CreateSection({
        Name = "Themes",
        Side = "Right"
    })
    
    local thmInput = ThemeSecOption:CreateInput({
        Name = "Theme Name",
        Placeholder = "Type to Save..."
    })
    
    local thmDropdown = ThemeSecOption:CreateDropdown({
        Name = "Select Theme",
        Options = GetFiles("VelourThemes")
    })

    local autoLoadThemeEnabled = false
    local autoLoadThemeFile = "VelourThemes/autoload.txt"

    local function RealThemeLoad(name)
        local raw = read_file("VelourThemes/" .. name .. ".json")
        if raw then
            local data = HS:JSONDecode(raw)
            for k, v in pairs(data) do
                if type(v) == "table" and v[4] == "Color3" then
                    WindowObj:UpdateTheme(k, Color3.new(v[1], v[2], v[3]))
                elseif type(v) == "table" and v[3] == "UDim" then
                    WindowObj:UpdateTheme(k, UDim.new(v[1], v[2]))
                elseif type(v) == "table" and v[2] == "EnumItem" then
                    WindowObj:UpdateTheme(k, Enum.Font[v[1]])
                else
                    WindowObj:UpdateTheme(k, v)
                end
            end
            WindowObj:Notify({
                Title = "System",
                Text = "Theme Loaded: " .. name,
                Duration = 3
            })
            if autoLoadThemeEnabled then
                write_file(autoLoadThemeFile, name)
            end
        end
    end

    ThemeSecOption:CreateButton({
        Name = "Load Theme",
        Callback = function()
            local name = thmDropdown.Get()
            if name and name ~= "" then
                RealThemeLoad(name)
            end
        end
    })

    ThemeSecOption:CreateButton({
        Name = "Save Theme",
        Callback = function()
            local name = thmInput.Get()
            if name and name ~= "" then
                name = name:gsub("%.json$", "")
                local data = {}
                for k, v in pairs(VelourUI.Settings.Theme) do
                    if typeof(v) == "Color3" then
                        data[k] = {v.R, v.G, v.B, "Color3"}
                    elseif typeof(v) == "UDim" then
                        data[k] = {v.Scale, v.Offset, "UDim"}
                    elseif typeof(v) == "EnumItem" then
                        data[k] = {v.Name, "EnumItem"}
                    else
                        data[k] = v
                    end
                end
                write_file("VelourThemes/" .. name .. ".json", HS:JSONEncode(data))
                thmDropdown.Refresh(GetFiles("VelourThemes"), true)
                WindowObj:Notify({
                    Title = "System",
                    Text = "Theme Saved: " .. name,
                    Duration = 3
                })
            end
        end
    })

    ThemeSecOption:CreateButton({
        Name = "Delete Theme",
        Callback = function()
            local name = thmDropdown.Get()
            if name and name ~= "" then
                del_file("VelourThemes/" .. name .. ".json")
                local upList = GetFiles("VelourThemes")
                thmDropdown.Refresh(upList)
                WindowObj:Notify({
                    Title = "System",
                    Text = "Theme Deleted: " .. name,
                    Duration = 3
                })
            end
        end
    })

    if is_file(autoLoadThemeFile) then
        autoLoadThemeEnabled = true
        local nameToLoad = read_file(autoLoadThemeFile)
        if nameToLoad and is_file("VelourThemes/" .. nameToLoad .. ".json") then
            task.spawn(function()
                task.wait(1)
                RealThemeLoad(nameToLoad)
                thmDropdown.Set(nameToLoad, true)
            end)
        end
    end

    ThemeSecOption:CreateToggle({
        Name = "Auto-Load Selected",
        Default = autoLoadThemeEnabled,
        Callback = function(state)
            autoLoadThemeEnabled = state
            if state then
                local name = thmDropdown.Get()
                if name and name ~= "" then
                    write_file(autoLoadThemeFile, name)
                end
            else
                if is_file(autoLoadThemeFile) then
                    del_file(autoLoadThemeFile)
                end
            end
        end
    })

    task.spawn(function()
        while task.wait(1) do
            if WindowObj.IsOpen then
                local newCfgs = GetFiles(configFolder)
                if not ArrayEquals(cfgDropdown.GetOptions(), newCfgs) then
                    cfgDropdown.Refresh(newCfgs, true)
                end
                
                local newThemes = GetFiles("VelourThemes")
                if not ArrayEquals(thmDropdown.GetOptions(), newThemes) then
                    thmDropdown.Refresh(newThemes, true)
                end
            end
        end
    end)

    task.spawn(function()
        task.wait(0.1)
        for _, t in ipairs(WindowObj.Tabs) do
            if not t.IsSettings then
                t.Select()
                return
            end
        end
        if WindowObj.Tabs[1] then
            WindowObj.Tabs[1].Select()
        end
    end)

    return WindowObj
end

return VelourUI
