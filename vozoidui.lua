-- =================================================================
--  vozoid ui
--  ends with: return Library
-- =================================================================
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local Players = game:GetService("Players")

local T = {
    Bg      = Color3.fromRGB(18, 16, 20),
    Panel   = Color3.fromRGB(26, 22, 30),
    Section = Color3.fromRGB(34, 28, 40),
    Row     = Color3.fromRGB(28, 24, 34),
    Stroke  = Color3.fromRGB(48, 40, 56),
    Accent  = Color3.fromRGB(255, 130, 200),
    Text    = Color3.fromRGB(230, 225, 235),
    TextDim = Color3.fromRGB(140, 130, 150),
    Font    = Enum.Font.Gotham,
    FontBold= Enum.Font.GothamBold,
    FontMono= Enum.Font.Code,
}

local Library = { Flags = {}, Items = {}, Theme = T, ScreenGui = nil }

local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end
local function corner(i, r) new("UICorner", { CornerRadius = UDim.new(0, r or 4) }, i) end
local function stroke(i, c, t) new("UIStroke", { Color = c or T.Stroke, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, i) end
local function pad(i, t, r, b, l)
    new("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0),
    }, i)
end
local function tween(i, p, t) TS:Create(i, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad), p):Play() end
local function fire(cb, ...)
    if type(cb) ~= "function" then return end
    local ok, err = pcall(cb, ...)
    if not ok then warn("[vozoid] callback error:", err) end
end

local sg = new("ScreenGui", {
    Name = "VozoidUI", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
})
pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
Library.ScreenGui = sg

local function openColorPicker(anchor, initial, cb)
    local popup = new("Frame", {
        Size = UDim2.fromOffset(160, 130),
        Position = UDim2.fromOffset(anchor.AbsolutePosition.X, anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 500, Parent = sg,
    })
    corner(popup, 6); stroke(popup)

    local sat = new("ImageLabel", {
        Size = UDim2.fromOffset(120, 80), Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = initial, BorderSizePixel = 0, ZIndex = 501,
        Image = "rbxassetid://4155801252", Parent = popup,
    })
    corner(sat, 4)

    local hue = new("Frame", {
        Size = UDim2.fromOffset(20, 80), Position = UDim2.fromOffset(134, 8),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 501, Parent = popup,
    })
    corner(hue, 4)
    new("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.new(1, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.new(1, 1, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.new(0, 1, 0)),
            ColorSequenceKeypoint.new(0.50, Color3.new(0, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.new(0, 0, 1)),
            ColorSequenceKeypoint.new(0.83, Color3.new(1, 0, 1)),
            ColorSequenceKeypoint.new(1.00, Color3.new(1, 0, 0)),
        }),
    }, hue)

    local h, s, v = initial:ToHSV()
    local cursorS = new("Frame", {
        Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(s, 1 - v), BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 502, Parent = sat,
    })
    corner(cursorS, 4)
    local cursorH = new("Frame", {
        Size = UDim2.new(1, 2, 0, 3), Position = UDim2.fromScale(0.5, h),
        BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 502, Parent = hue,
    })

    local function update()
        sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        fire(cb, Color3.fromHSV(h, s, v))
    end

    local dragging = nil
    local function bindDrag(frame, setter)
        frame.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            dragging = setter; setter()
        end)
    end
    bindDrag(sat, function()
        local m = UIS:GetMouseLocation()
        s = math.clamp((m.X - sat.AbsolutePosition.X) / sat.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp((m.Y - sat.AbsolutePosition.Y) / sat.AbsoluteSize.Y, 0, 1)
        cursorS.Position = UDim2.fromScale(s, 1 - v)
        update()
    end)
    bindDrag(hue, function()
        local m = UIS:GetMouseLocation()
        h = math.clamp((m.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
        cursorH.Position = UDim2.fromScale(0.5, h)
        update()
    end)

    local moveConn, endConn, outside
    moveConn = UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then dragging() end
    end)
    endConn = UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = nil end
    end)
    outside = UIS.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local m = UIS:GetMouseLocation()
        local p, sz = popup.AbsolutePosition, popup.AbsoluteSize
        if m.X < p.X or m.X > p.X + sz.X or m.Y < p.Y or m.Y > p.Y + sz.Y then
            popup:Destroy()
            moveConn:Disconnect(); endConn:Disconnect(); outside:Disconnect()
        end
    end)
    update()
end

function Library:Window(cfg)
    cfg = cfg or {}
    local win = { Tabs = {}, ActiveTab = nil }

    local root = new("Frame", {
        Name = "Window",
        Size = cfg.Size or UDim2.fromOffset(620, 500),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Bg, BorderSizePixel = 0,
        Active = true, Draggable = true,
        ZIndex = 1, Parent = sg,
    })
    corner(root, 6); stroke(root)

    local titleBar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 2, Parent = root,
    })
    corner(titleBar, 6)
    new("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 2, Parent = titleBar })

    new("TextLabel", {
        Text = cfg.Name or "vozoid ui", Font = T.FontBold, TextSize = 12,
        TextColor3 = T.Text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -60, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = titleBar,
    })

    local close = new("TextButton", {
        Text = "X", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = T.TextDim, BackgroundTransparency = 1,
        Size = UDim2.fromOffset(24, 28), Position = UDim2.new(1, -28, 0, 0),
        ZIndex = 3, Parent = titleBar,
    })
    close.MouseButton1Click:Connect(function() sg.Enabled = false end)

    local tabStrip = new("Frame", {
        Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 28),
        BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 2, Parent = root,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder,
    }, tabStrip)
    pad(tabStrip, 0, 0, 0, 6)

    local content = new("Frame", {
        Size = UDim2.new(1, 0, 1, -54), Position = UDim2.fromOffset(0, 54),
        BackgroundTransparency = 1, ZIndex = 2, Parent = root, ClipsDescendants = true,
    })

    function win:Tab(name)
        local tab = { Name = name }
        local btn = new("TextButton", {
            Text = name, Font = T.Font, TextSize = 12,
            TextColor3 = T.TextDim, BackgroundColor3 = T.Panel, BackgroundTransparency = 1,
            BorderSizePixel = 0, Size = UDim2.fromOffset(72, 26),
            LayoutOrder = #win.Tabs, ZIndex = 3, Parent = tabStrip,
        })
        local underline = new("Frame", {
            Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = T.Accent, BorderSizePixel = 0, Visible = false,
            ZIndex = 3, Parent = btn,
        })
        local page = new("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            Visible = false, ZIndex = 3, Parent = content,
        })
        local leftCol = new("ScrollingFrame", {
            Size = UDim2.new(0.5, -6, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.Stroke,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 3, Parent = page,
        })
        pad(leftCol, 6, 3, 6, 6)
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, leftCol)

        local rightCol = new("ScrollingFrame", {
            Size = UDim2.new(0.5, -6, 1, 0), Position = UDim2.new(0.5, 3, 0, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.Stroke,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 3, Parent = page,
        })
        pad(rightCol, 6, 6, 6, 3)
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, rightCol)

        tab.Left, tab.Right = leftCol, rightCol

        btn.MouseButton1Click:Connect(function()
            if win.ActiveTab then
                win.ActiveTab.Page.Visible = false
                win.ActiveTab.Button.TextColor3 = T.TextDim
                win.ActiveTab.Underline.Visible = false
            end
            win.ActiveTab = tab
            page.Visible = true
            btn.TextColor3 = T.Text
            underline.Visible = true
        end)

        tab.Button, tab.Page, tab.Underline = btn, page, underline

        if not win.ActiveTab then
            win.ActiveTab = tab
            page.Visible = true
            btn.TextColor3 = T.Text
            underline.Visible = true
        end

        function tab:Section(sectionName, side)
            local column = (side == "Right") and rightCol or leftCol
            local sec = { Items = {} }

            local box = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = T.Section, BorderSizePixel = 0,
                ZIndex = 4, Parent = column,
            })
            corner(box, 5); stroke(box)

            local header = new("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundColor3 = T.Row, BorderSizePixel = 0, ZIndex = 5, Parent = box,
            })
            corner(header, 5)
            new("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, -5),
                BackgroundColor3 = T.Row, BorderSizePixel = 0, ZIndex = 5, Parent = header })
            new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 6, Parent = header })
            new("TextLabel", {
                Text = sectionName, Font = T.FontBold, TextSize = 11,
                TextColor3 = T.Text, BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = header,
            })

            local body = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 22),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, ZIndex = 5, Parent = box,
            })
            new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, body)
            pad(body, 4, 6, 6, 6)

            function sec:Toggle(o)
                local flag  = o.Flag or o.Name
                local value = o.Default == true
                Library.Flags[flag] = value

                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1, ZIndex = 6, Parent = body,
                })
                local box2 = new("Frame", {
                    Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 0, 0.5, -7),
                    BackgroundColor3 = T.Row, BorderSizePixel = 0, ZIndex = 7, Parent = row,
                })
                corner(box2, 3); stroke(box2, T.Stroke)
                local fill = new("Frame", {
                    Size = value and UDim2.fromScale(1, 1) or UDim2.fromScale(0, 0),
                    Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = T.Accent, BorderSizePixel = 0,
                    Visible = value, ZIndex = 8, Parent = box2,
                })
                corner(fill, 2)
                local label = new("TextLabel", {
                    Text = o.Name or "Toggle", Font = T.Font, TextSize = 11,
                    TextColor3 = value and T.Text or T.TextDim, BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -22, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7, Parent = row,
                })

                local click = new("TextButton", {
                    Text = "", BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1), ZIndex = 100, Parent = row,
                })

                local item = {
                    Name = o.Name, Flag = flag, Value = value,
                    Set = function(_, v)
                        item.Value = v
                        Library.Flags[flag] = v
                        fill.Visible = v
                        tween(fill, { Size = v and UDim2.fromScale(1, 1) or UDim2.fromScale(0, 0) }, 0.1)
                        label.TextColor3 = v and T.Text or T.TextDim
                        fire(o.Callback, v)
                    end,
                }
                Library.Items[flag] = item

                click.MouseButton1Click:Connect(function()
                    item:Set(not item.Value)
                end)

                table.insert(sec.Items, item)
                return item
            end

            function sec:Slider(o)
                local flag   = o.Flag or o.Name
                local min    = o.Min or 0
                local max    = o.Max or 100
                local dec    = o.Decimals or 0
                local value  = o.Default or min
                Library.Flags[flag] = value

                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1, ZIndex = 6, Parent = body,
                })
                new("TextLabel", {
                    Text = o.Name or "Slider", Font = T.Font, TextSize = 11,
                    TextColor3 = T.Text, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 0, 12), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7, Parent = row,
                })
                local box = new("TextBox", {
                    Text = tostring(value), Font = T.FontMono, TextSize = 10,
                    TextColor3 = T.Text, BackgroundColor3 = T.Row, BorderSizePixel = 0,
                    Size = UDim2.fromOffset(48, 14), Position = UDim2.new(1, -48, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8, Parent = row,
                })
                corner(box, 2); stroke(box, T.Stroke)

                local bar = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 20),
                    BackgroundColor3 = T.Row, BorderSizePixel = 0, ZIndex = 7, Parent = row,
                })
                corner(bar, 3)
                local fill = new("Frame", {
                    Size = UDim2.fromScale((value - min) / (max - min), 1),
                    BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 8, Parent = bar,
                })
                corner(fill, 3)

                local function setValue(v, doFire)
                    v = math.clamp(v, min, max)
                    if dec > 0 then v = math.floor(v * 10 ^ dec + 0.5) / 10 ^ dec
                    else v = math.floor(v + 0.5) end
                    value = v
                    Library.Flags[flag] = v
                    box.Text = tostring(v)
                    tween(fill, { Size = UDim2.fromScale((v - min) / (max - min), 1) }, 0.05)
                    if doFire then fire(o.Callback, v) end
                end

                bar.InputBegan:Connect(function(i)
                    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local function upd()
                        local m = UIS:GetMouseLocation()
                        local rel = math.clamp((m.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                        setValue(min + rel * (max - min), true)
                    end
                    upd()
                    local mConn, eConn
                    mConn = UIS.InputChanged:Connect(function(x)
                        if x.UserInputType == Enum.UserInputType.MouseMovement then upd() end
                    end)
                    eConn = UIS.InputEnded:Connect(function(x)
                        if x.UserInputType == Enum.UserInputType.MouseButton1 then
                            mConn:Disconnect(); eConn:Disconnect()
                        end
                    end)
                end)

                box.FocusLost:Connect(function()
                    local n = tonumber(box.Text)
                    if n then setValue(n, true) else setValue(value, false) end
                end)

                local item = { Name = o.Name, Flag = flag, Value = value,
                    Set = function(_, v) setValue(v, true) end }
                Library.Items[flag] = item
                table.insert(sec.Items, item)
                return item
            end

            function sec:Dropdown(o)
                local flag   = o.Flag or o.Name
                local values = o.Values or {}
                local current = o.Default or values[1]
                Library.Flags[flag] = current

                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1, ZIndex = 6, Parent = body,
                })
                local disp = new("TextButton", {
                    Text = tostring(current), Font = T.Font, TextSize = 11,
                    TextColor3 = T.Text, BackgroundColor3 = T.Row,
                    BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7, Parent = row,
                })
                corner(disp, 3); stroke(disp, T.Stroke); pad(disp, 0, 6, 0, 6)

                local list = new("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 20),
                    BackgroundColor3 = T.Section, BorderSizePixel = 0,
                    Visible = false, ZIndex = 50, Parent = row,
                    ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                })
                corner(list, 3); stroke(list, T.Stroke)
                new("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }, list)
                pad(list, 3, 3, 3, 3)

                local function rebuild()
                    for _, c in ipairs(list:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for i, v in ipairs(values) do
                        local b = new("TextButton", {
                            Text = tostring(v), Font = T.Font, TextSize = 11,
                            TextColor3 = (v == current) and T.Accent or T.Text,
                            BackgroundColor3 = T.Section, BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 16), LayoutOrder = i, ZIndex = 51, Parent = list,
                        })
                        pad(b, 0, 4, 0, 4); b.TextXAlignment = Enum.TextXAlignment.Left
                        b.MouseButton1Click:Connect(function()
                            current = v
                            Library.Flags[flag] = v
                            disp.Text = tostring(v)
                            list.Visible = false; rebuild()
                            fire(o.Callback, v)
                        end)
                    end
                    list.Size = UDim2.new(1, 0, 0, math.min(#values, 6) * 18 + 8)
                end
                rebuild()

                local open = false
                disp.MouseButton1Click:Connect(function()
                    open = not open; list.Visible = open
                end)

                local item = {
                    Name = o.Name, Flag = flag, Value = current,
                    Set = function(_, v)
                        current = v; Library.Flags[flag] = v
                        disp.Text = tostring(v); rebuild()
                        fire(o.Callback, v)
                    end,
                    Refresh = function(_, nv) values = nv; rebuild() end,
                }
                Library.Items[flag] = item
                table.insert(sec.Items, item)
                return item
            end

            function sec:Input(o)
                local flag  = o.Flag or o.Name
                local value = o.Default or ""
                Library.Flags[flag] = value
                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1, ZIndex = 6, Parent = body,
                })
                local box = new("TextBox", {
                    Text = value, PlaceholderText = o.Placeholder or "",
                    Font = T.Font, TextSize = 11, TextColor3 = T.Text,
                    PlaceholderColor3 = T.TextDim, BackgroundColor3 = T.Row,
                    BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7, Parent = row,
                })
                corner(box, 3); stroke(box, T.Stroke); pad(box, 0, 6, 0, 6)
                local item = { Name = o.Name, Flag = flag, Value = value,
                    Set = function(_, v) value = v; Library.Flags[flag] = v; box.Text = tostring(v) end }
                Library.Items[flag] = item
                box.FocusLost:Connect(function()
                    value = box.Text; Library.Flags[flag] = value
                    fire(o.Callback, value)
                end)
                table.insert(sec.Items, item)
                return item
            end

            function sec:Button(o)
                local b = new("TextButton", {
                    Text = o.Name or "Button", Font = T.Font, TextSize = 11,
                    TextColor3 = T.Text, BackgroundColor3 = T.Row,
                    BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 20),
                    ZIndex = 7, Parent = body,
                })
                corner(b, 3); stroke(b, T.Stroke)
                b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = T.Accent }, 0.1) end)
                b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = T.Row }, 0.1) end)
                b.MouseButton1Click:Connect(function() fire(o.Callback) end)
                return b
            end

            function sec:Keybind(o)
                local flag = o.Flag or o.Name
                local key  = o.Default or Enum.KeyCode.F
                Library.Flags[flag] = key
                local listening = false

                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1, ZIndex = 6, Parent = body,
                })
                new("TextLabel", {
                    Text = o.Name or "Keybind", Font = T.Font, TextSize = 11,
                    TextColor3 = T.Text, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7, Parent = row,
                })
                local btn = new("TextButton", {
                    Text = key.Name, Font = T.FontMono, TextSize = 10,
                    TextColor3 = T.Text, BackgroundColor3 = T.Row, BorderSizePixel = 0,
                    Size = UDim2.fromOffset(48, 14), Position = UDim2.new(1, -48, 0.5, -7),
                    ZIndex = 8, Parent = row,
                })
                corner(btn, 3); stroke(btn, T.Stroke)

                local item = { Name = o.Name, Flag = flag, Value = key,
                    Set = function(_, v) key = v; Library.Flags[flag] = v; btn.Text = v.Name end }
                Library.Items[flag] = item

                local conn
                btn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true; btn.Text = "..."
                    conn = UIS.InputBegan:Connect(function(i, p)
                        if p then return end
                        if i.UserInputType == Enum.UserInputType.Keyboard then
                            item:Set(i.KeyCode)
                            listening = false; conn:Disconnect()
                            fire(o.Callback, i.KeyCode)
                        end
                    end)
                end)

                UIS.InputBegan:Connect(function(i, p)
                    if p then return end
                    if not listening and i.KeyCode == key then fire(o.Callback, key) end
                end)

                table.insert(sec.Items, item)
                return item
            end

            return sec
        end

        return tab
    end

    function win:Close()   sg.Enabled = false end
    function win:Open()    sg.Enabled = true  end
    function win:Destroy() sg:Destroy()       end

    return win
end

UIS.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.RightShift then sg.Enabled = not sg.Enabled end
end)

return Library
