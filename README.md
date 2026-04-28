
# ✨ Velour UI Library

**Velour UI** — modern, lightweight and customizable Roblox UI library with built-in config system, flags, watermark and full element set.

---

## 📢 Social Networks
- Owner Telegram: @x_kat4na_x


## ✨ Features

- Clean & premium UI
- Simple and readable API
- Full component system (buttons, toggles, sliders, etc.)
- Flag system (state management)
- Custom themes
- Lightweight & optimized

---

## 🛠️ Built-in Settings Tab

Velour UI automatically generates a fully functional **"UI Settings"** tab at the bottom of your sidebar. 
You don't need to write code for configurations! It already includes:
- **Theme Customizer:** Change accent color, background, strokes, text fonts, UI Scale, and corner radius.
- **Config Manager:** Save, load, and delete script configs (automatically handles all elements with a `Flag`).
- **Theme Manager:** Save your custom color themes and auto-load them.

---

## 📥 Installation

Load the library directly into your script using `loadstring`:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/katnaa-debug/Velour/refs/heads/main/Library.lua"))()
```

## 📚 Documentation
1. Creating a Window

```lua
local Window = VelourUI:CreateWindow({
    Name = "Name of gui", -- Main title of your UI
    Icon = "rbxassetid", -- Top-left icon (string or id, optional)
    ToggleKey = Enum.KeyCode.RightShift, -- Key to open/close UI
    ConfigFolder = "AetherConfigs", -- Folder where configs will be saved
    WatermarkEnabled = true, -- Enables draggable watermark (FPS, ping, user)
    Theme = {
        Accent = Color3.fromRGB(255, 140, 40), -- Main accent color
        BgTransparency = 0, -- Window background transparency (0-100)
        SectionTransparency = 0, -- Section background transparency (0-100)
        ElementsTransparency = 0, -- Elements transparency (0-100)
        CornerRadius = 10, -- UI roundness (0-20)
        TitleFont = Enum.Font.GothamMedium, -- Title font
        TextFont = Enum.Font.Gotham, -- Default text font
        BackgroundImage = "6057464213", -- Background image id (optional)
        BgImageTransparency = 50 -- Background image transparency
    }
})

```

2. Tabs 
Standard Tab

```lua
local MainTab = Window:CreateTab({
    Name = "Main", -- Tab name
    Icon = "rbxassetid" -- Optional icon
})
```

3. Sections

```lua
local LeftColumn = MainTab:CreateSection({
    Name = "Main", -- Section name
    Side = "Left", -- "Left" or "Right"
    Icon = "rbxassetid" -- Optional icon
})
```
## 📖 Elements UI

label
```lua
LeftColumn:CreateLabel({ Name = "-- Settings --" })
```

Button
```lua
LeftColumn:CreateButton({
    Name = "Execute",
    Callback = function()
        print("Click")
    end
})
```

Toggle

```lua
LeftColumn:CreateToggle({
    Name = "Enable",
    Default = true, -- true / false
    Flag = "Target", -- Saved this flag in config
    Callback = function(state) -- boolean
        print(state)
    end
})
```

Slider

```lua
LeftColumn:CreateSlider({
    Name = "Smoothing",
    Min = 1, -- minimum value
    Max = 10, -- maximum value
    Default = 5, -- default value
    Flag = "Smooth",
    Callback = function(value) -- number
        print(value)
    end
})
```

Input (TextBox)

```lua
LeftColumn:CreateInput({
    Name = "Custom Tag",
    Placeholder = "Enter...", -- placeholder text
    Flag = "Tag",
    Callback = function(text) -- string
        print(text)
    end
})
```

Dropdown

```lua
local MyDropdown = LeftColumn:CreateDropdown({
    Name = "Select", -- Name of dropdown
    Options = {"Head", "Torso", "Legs"}, -- List of values
    Default = "Head", -- Default selected value
    Flag = "Target2", -- Saved in config system
    Callback = function(val) -- Returns selected value
        print("Selected:", val)
    end
})
```

Color Picker

```lua
LeftColumn:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 80, 80),
    Flag = "ESP",
    Callback = function(color) -- Color3
        print("color selected")
    end
})
```

Keybind

```lua
LeftColumn:CreateKeybind({
    Name = "Key",
    Default = Enum.KeyCode.E, -- default key
    Flag = "Bind1",
    Callback = function(key, released)
        -- key = pressed key
        -- released = true/false (depending on implementation)
        print("button pressed")
    end
})

```

## 🔔 Notifications

You can send notifications with custom text, icon, and duration.

```lua
Window:Notify({
    Title = "System Notification",
    Text = "This is a very long subtext that will automatically wrap...",
    Icon = "rbxassetid://12345678", -- Optional icon
    Duration = 5 -- Duration in seconds before closing
})
```

---

## 📝 Full Example Script

```lua
local VelourUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/katnaa-debug/Velour/refs/heads/main/Library.lua"))()

local Window = VelourUI:CreateWindow({
    Name = "Velour Hub",
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "VelourConfigs",
    WatermarkEnabled = true,
})

local MainTab = Window:CreateTab({ Name = "Main Features", Icon = "rbxassetid://12345678" })
local CombatSec = MainTab:CreateSection({ Name = "Combat", Side = "Left" })

CombatSec:CreateToggle({
    Name = "Enable Aimbot",
    Default = false,
    Flag = "AimbotEnabled",
    Callback = function(state)
        print("Aimbot:", state)
    end
})

Window:Notify({ Title = "Loaded", Text = "UI successfully loaded!", Duration = 3 })
```

---

## 🅰️ Fonts

Available Fonts:

Arial, ArialBold, SourceSans, SourceSansBold, SourceSansSemibold, SourceSansLight, SourceSansItalic, Bodoni, Garamond, Cartoon, Code, Highway, SciFi, Arcade, Fantasy, Antique, Gotham, GothamMedium, GothamBold, Oswald
