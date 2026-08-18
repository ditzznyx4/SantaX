-- ╔══════════════════════════════════════════════╗
-- ║           SantaX Mods — Arsenal FPS         ║
-- ║  Created By : Astra                         ║
-- ║  Game       : Arsenal (& FPS Roblox)        ║
-- ║  Ludo ad oblectationem utendo,              ║
-- ║  omnia pericula ab ipso usore feruntur.     ║
-- ╚══════════════════════════════════════════════╝

-- ══════════════════════════════════════════════
-- SAFE BOOTSTRAP — Fixes "attempt to call nil"
-- ══════════════════════════════════════════════
local env = getfenv and getfenv(0) or _ENV or _G
local function safeGet(t, k)
    local ok, v = pcall(function() return t[k] end)
    return ok and v or nil
end

local Players          = safeGet(game,"GetService") and game:GetService("Players")          or nil
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local StarterGui       = game:GetService("StarterGui")
local CoreGui          = game:GetService("CoreGui")

if not Players then warn("[SantaX] Players service nil") return end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then warn("[SantaX] LocalPlayer nil") return end

local Camera = Workspace.CurrentCamera

-- ══════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════
local State = {
    -- Main
    EnableFeature  = false, EnableAim = false, EnableEsp = false,
    -- Aim
    AimbotFire     = false, AimbotLegit = false, AimAssist = false,
    AimSilent      = false, AimVisible  = false,
    AimMagnet      = false, AimKill     = false,
    AimTarget      = "Body",  -- Body | Head | Random
    AimFov         = 90,
    -- Visual
    EspLine        = false, EspBox      = false, EspHitbox3D = false,
    EspHealth      = false, EspDistance = false, EspName     = false,
    EspSkeleton    = false,
    -- Exploits
    SpeedHack      = false, JumpBoost   = false, DoubleJump  = false,
    TeleportToggle = false, FlyAuto     = false, FlyToPlayer = false,
    FastReload     = false, SpeedFire   = false,
    TeleportTarget = nil,   FlyConn     = nil,
    JumpCount      = 0,
}

-- ══════════════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════════════
local function getCharacter(p)   return p and p.Character end
local function getRootPart(p)
    local c = getCharacter(p)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end
local function getHumanoid(p)
    local c = getCharacter(p)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHead(p)
    local c = getCharacter(p)
    return c and c:FindFirstChild("Head")
end
local function isAlive(p)
    local h = getHumanoid(p)
    return h and h.Health > 0
end
local function isEnemy(p)
    if p == LocalPlayer then return false end
    if LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then return false end
    return true
end
local function getEnemies()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) and isAlive(p) then table.insert(list, p) end
    end
    return list
end
local function getTargetPart(p)
    local t = State.AimTarget
    if t == "Random" then t = math.random(1,2)==1 and "Head" or "Body" end
    local c = getCharacter(p) if not c then return nil end
    if t == "Head" then return c:FindFirstChild("Head")
    else return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") end
end
local function getClosestEnemy()
    local cx = Camera.ViewportSize.X/2
    local cy = Camera.ViewportSize.Y/2
    local center = Vector2.new(cx, cy)
    local radius = (State.AimFov/360) * Camera.ViewportSize.X * 0.5
    local best, bestD, bestPart = nil, math.huge, nil
    for _, p in ipairs(getEnemies()) do
        local part = getTargetPart(p) if not part then continue end
        local sp, vis = Camera:WorldToViewportPoint(part.Position)
        if vis then
            local d = (Vector2.new(sp.X,sp.Y)-center).Magnitude
            if d < radius and d < bestD then best=p bestD=d bestPart=part end
        end
    end
    return best, bestPart
end

-- ══════════════════════════════════════════════
-- AIM LOOP
-- ══════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not State.EnableFeature or not State.EnableAim then return end
    local enemy, part = getClosestEnemy()
    if not enemy or not part then return end

    if State.AimbotFire then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
    elseif State.AimbotLegit then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), 0.2)
    elseif State.AimAssist then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), 0.1)
    end

    if State.AimSilent then
        local root = getRootPart(LocalPlayer)
        if root then
            root.CFrame = CFrame.new(root.Position, Vector3.new(part.Position.X, root.Position.Y, part.Position.Z))
        end
    end

    if State.AimMagnet then
        local cx = Camera.ViewportSize.X/2
        local cy = Camera.ViewportSize.Y/2
        local center  = Vector2.new(cx,cy)
        local radius  = (State.AimFov/360)*Camera.ViewportSize.X*0.5
        local myRoot  = getRootPart(LocalPlayer)
        for _, p in ipairs(getEnemies()) do
            local rp = getRootPart(p) if not rp then continue end
            local sp, vis = Camera:WorldToViewportPoint(rp.Position)
            if vis then
                local d = (Vector2.new(sp.X,sp.Y)-center).Magnitude
                if myRoot and d < radius then
                    local worldD = (rp.Position - myRoot.Position).Magnitude
                    local ray    = Camera:ScreenPointToRay(cx, cy)
                    rp.CFrame    = CFrame.new(ray.Origin + ray.Direction * worldD, ray.Origin + ray.Direction*(worldD+1))
                end
            end
        end
    end

    if State.AimKill then
        local cx = Camera.ViewportSize.X/2
        local cy = Camera.ViewportSize.Y/2
        local center = Vector2.new(cx,cy)
        local radius = (State.AimFov/360)*Camera.ViewportSize.X*0.5
        local myRoot = getRootPart(LocalPlayer)
        for _, p in ipairs(getEnemies()) do
            local pt = getTargetPart(p) if not pt then continue end
            local sp, vis = Camera:WorldToViewportPoint(pt.Position)
            if vis and (Vector2.new(sp.X,sp.Y)-center).Magnitude < radius then
                if State.AimVisible and myRoot then
                    local rp = RaycastParams.new()
                    rp.FilterDescendantsInstances = {getCharacter(LocalPlayer), getCharacter(p)}
                    rp.FilterType = Enum.RaycastFilterType.Exclude
                    local dir = pt.Position - myRoot.Position
                    if Workspace:Raycast(myRoot.Position, dir, rp) then continue end
                end
                local hum = getHumanoid(p) if hum then hum.Health = 0 end
            end
        end
    end
end)

-- ══════════════════════════════════════════════
-- EXPLOITS
-- ══════════════════════════════════════════════
local wsConn
local function applySpeed(v)
    local h = getHumanoid(LocalPlayer) if not h then return end
    h.WalkSpeed = v and 32 or 16
    if wsConn then wsConn:Disconnect() wsConn=nil end
    if v then wsConn = h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if State.SpeedHack then h.WalkSpeed=32 end
    end) end
end
local function applyJump(v)
    local h = getHumanoid(LocalPlayer) if not h then return end
    h.JumpPower = v and 100 or 50
end
local djConn
local function applyDoubleJump(v)
    if djConn then djConn:Disconnect() djConn=nil end
    State.JumpCount = 0
    if not v then return end
    local h = getHumanoid(LocalPlayer) if not h then return end
    djConn = h.StateChanged:Connect(function(_, n)
        if n == Enum.HumanoidStateType.Jumping then State.JumpCount = State.JumpCount+1
        elseif n == Enum.HumanoidStateType.Landed then State.JumpCount = 0 end
    end)
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.Space and State.DoubleJump and State.JumpCount==1 then
            local r = getRootPart(LocalPlayer)
            if r then r.Velocity = Vector3.new(r.Velocity.X,60,r.Velocity.Z) State.JumpCount=2 end
        end
    end)
end
local function applyFlyAuto(v)
    if State.FlyConn then State.FlyConn:Disconnect() State.FlyConn=nil end
    local root = getRootPart(LocalPlayer)
    local h    = getHumanoid(LocalPlayer)
    if not root or not h then return end
    if v then
        h.PlatformStand = true
        local bp = Instance.new("BodyPosition")
        bp.Name="SXFly" bp.MaxForce=Vector3.new(1e5,1e5,1e5) bp.P=1e4
        bp.Position = root.Position + Vector3.new(0,15,0)
        bp.Parent   = root
        State.FlyConn = RunService.Heartbeat:Connect(function()
            if not State.FlyAuto then bp:Destroy() h.PlatformStand=false
                State.FlyConn:Disconnect() State.FlyConn=nil return end
            bp.Position = Vector3.new(root.Position.X, root.Position.Y+15, root.Position.Z)
        end)
    else
        local e = root:FindFirstChild("SXFly") if e then e:Destroy() end
        h.PlatformStand = false
    end
end
local function doFlyToPlayer()
    local h = getHumanoid(LocalPlayer)
    local r = getRootPart(LocalPlayer)
    if not h or not r then return end
    h.PlatformStand = true
    for _, p in ipairs(getEnemies()) do
        if not State.FlyToPlayer then break end
        local tr = getRootPart(p) if not tr then continue end
        local bp = Instance.new("BodyPosition")
        bp.MaxForce=Vector3.new(1e5,1e5,1e5) bp.P=1e4 bp.Position=tr.Position bp.Parent=r
        task.wait(0.8) bp:Destroy()
    end
    h.PlatformStand = false
end
local function doTeleport()
    if not State.TeleportTarget then return end
    local tp = Players:FindFirstChild(State.TeleportTarget)
    if not tp then return end
    local tr = getRootPart(tp)
    local mr = getRootPart(LocalPlayer)
    if tr and mr then mr.CFrame = tr.CFrame + Vector3.new(2,0,0) end
end
local function hookAnimSpeed(keyword, speed)
    local char = getCharacter(LocalPlayer) if not char then return end
    local h    = char:FindFirstChildOfClass("Humanoid") if not h then return end
    local anim = h:FindFirstChildOfClass("Animator") if not anim then return end
    for _, t in ipairs(anim:GetPlayingAnimationTracks()) do
        if t.Name:lower():find(keyword) then t:AdjustSpeed(speed) end
    end
    anim.AnimationPlayed:Connect(function(t)
        if t.Name:lower():find(keyword) and (keyword=="reload" and State.FastReload or State.SpeedFire) then
            t:AdjustSpeed(speed)
        end
    end)
end

-- ══════════════════════════════════════════════
-- ESP SYSTEM
-- ══════════════════════════════════════════════
local espCache = {}
local function clearESP()
    for _, d in pairs(espCache) do
        if type(d)=="table" then
            for _, obj in pairs(d) do
                if type(obj)=="table" then for _, l in pairs(obj) do if typeof(l)=="Instance" then pcall(function() l:Remove() end) end end
                elseif typeof(obj)=="Instance" then pcall(function() obj:Remove() end) end
            end
        end
    end
    espCache = {}
end
RunService.RenderStepped:Connect(function()
    if not State.EnableFeature or not State.EnableEsp then clearESP() return end
    for _, p in ipairs(getEnemies()) do
        local c = getCharacter(p) local root = getRootPart(p)
        local head = getHead(p)   local hum  = getHumanoid(p)
        if not c or not root or not head or not hum then continue end
        local rs, vis = Camera:WorldToViewportPoint(root.Position)
        if not vis then continue end
        espCache[p] = espCache[p] or {}
        local d = espCache[p]
        local hs = Camera:WorldToViewportPoint(head.Position)
        local boxH = math.abs(rs.Y - hs.Y)*2.2
        local boxW = boxH * 0.55
        local bx = rs.X - boxW/2  local by = rs.Y - boxH/2
        -- Box
        if State.EspBox then
            if not d.Box then
                local b = Drawing.new("Square")
                b.Color=Color3.fromRGB(220,50,50) b.Thickness=1.5 b.Filled=false
                d.Box=b
            end
            d.Box.Size=Vector2.new(boxW,boxH) d.Box.Position=Vector2.new(bx,by) d.Box.Visible=true
        elseif d.Box then d.Box.Visible=false end
        -- Line
        if State.EspLine then
            if not d.Line then
                local l=Drawing.new("Line") l.Color=Color3.fromRGB(220,50,50) l.Thickness=1.5 d.Line=l end
            d.Line.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
            d.Line.To=Vector2.new(rs.X,rs.Y) d.Line.Visible=true
        elseif d.Line then d.Line.Visible=false end
        -- Name
        if State.EspName then
            if not d.NameD then local n=Drawing.new("Text") n.Color=Color3.fromRGB(255,255,255) n.Size=13 n.Center=true d.NameD=n end
            d.NameD.Text=p.Name d.NameD.Position=Vector2.new(rs.X,by-15) d.NameD.Visible=true
        elseif d.NameD then d.NameD.Visible=false end
        -- Health
        if State.EspHealth then
            if not d.Hp then local h=Drawing.new("Text") h.Color=Color3.fromRGB(80,255,80) h.Size=12 h.Center=true d.Hp=h end
            d.Hp.Text=string.format("HP:%d",math.floor(hum.Health)) d.Hp.Position=Vector2.new(rs.X,by+boxH+2) d.Hp.Visible=true
        elseif d.Hp then d.Hp.Visible=false end
        -- Distance
        if State.EspDistance then
            local mr = getRootPart(LocalPlayer)
            local dist = mr and math.floor((root.Position-mr.Position).Magnitude) or 0
            if not d.Dist then local dd=Drawing.new("Text") dd.Color=Color3.fromRGB(255,200,0) dd.Size=12 dd.Center=true d.Dist=dd end
            d.Dist.Text=dist.."m" d.Dist.Position=Vector2.new(rs.X,by+boxH+15) d.Dist.Visible=true
        elseif d.Dist then d.Dist.Visible=false end
        -- Skeleton
        if State.EspSkeleton then
            local bones={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
                {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
                {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
                {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
                {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}
            d.Sk = d.Sk or {}
            for i, pair in ipairs(bones) do
                local b1=c:FindFirstChild(pair[1]) local b2=c:FindFirstChild(pair[2])
                if b1 and b2 then
                    local s1,v1=Camera:WorldToViewportPoint(b1.Position)
                    local s2,v2=Camera:WorldToViewportPoint(b2.Position)
                    if v1 and v2 then
                        if not d.Sk[i] then local l=Drawing.new("Line") l.Color=Color3.fromRGB(220,60,60) l.Thickness=1 d.Sk[i]=l end
                        d.Sk[i].From=Vector2.new(s1.X,s1.Y) d.Sk[i].To=Vector2.new(s2.X,s2.Y) d.Sk[i].Visible=true
                    end
                end
            end
        else
            if d.Sk then for _,l in pairs(d.Sk) do l.Visible=false end end
        end
    end
end)

-- ══════════════════════════════════════════════
-- FOV CIRCLE + CROSSHAIR (crosshair FIXED center)
-- ══════════════════════════════════════════════
local fovCircle = Drawing.new("Circle")
fovCircle.Filled=false fovCircle.Color=Color3.fromRGB(200,40,40)
fovCircle.Thickness=1.5 fovCircle.NumSides=64

-- 4 segmen crosshair, ukuran fixed 8px, tidak ikut radius
local cross = {}
for i=1,4 do
    local l=Drawing.new("Line") l.Color=Color3.fromRGB(255,255,255) l.Thickness=1.5 l.Visible=true
    cross[i]=l
end

RunService.RenderStepped:Connect(function()
    local cx = Camera.ViewportSize.X/2
    local cy = Camera.ViewportSize.Y/2
    local radius = (State.AimFov/360)*Camera.ViewportSize.X*0.5
    fovCircle.Radius   = radius
    fovCircle.Position = Vector2.new(cx,cy)
    fovCircle.Visible  = State.EnableFeature and State.EnableAim
    -- Crosshair selalu tetap di center, ukuran 8px bukan ikut radius
    local cs = 8
    cross[1].From=Vector2.new(cx-cs,cy) cross[1].To=Vector2.new(cx-2,cy)
    cross[2].From=Vector2.new(cx+2,cy)  cross[2].To=Vector2.new(cx+cs,cy)
    cross[3].From=Vector2.new(cx,cy-cs) cross[3].To=Vector2.new(cx,cy-2)
    cross[4].From=Vector2.new(cx,cy+2)  cross[4].To=Vector2.new(cx,cy+cs)
    for i=1,4 do cross[i].Visible=true end
end)

-- ══════════════════════════════════════════════
-- CLEANUP OLD GUI
-- ══════════════════════════════════════════════
local oldGui = CoreGui:FindFirstChild("SantaXMods")
if oldGui then oldGui:Destroy() end

-- ══════════════════════════════════════════════
-- GUI ROOT
-- ══════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "SantaXMods"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = CoreGui

-- TEMA
local RED   = Color3.fromRGB(200, 40, 40)
local WHITE = Color3.fromRGB(255, 255, 255)
local DARK  = Color3.fromRGB(13, 13, 13)
local PANEL = Color3.fromRGB(20, 20, 20)
local ROW   = Color3.fromRGB(28, 28, 28)
local DIM   = Color3.fromRGB(110, 110, 110)

-- ══════════════════════════════════════════════
-- FLOATING ICON BUTTON (SM)
-- ══════════════════════════════════════════════
local IconBtn = Instance.new("TextButton")
IconBtn.Name             = "SantaXIcon"
IconBtn.Size             = UDim2.new(0, 52, 0, 52)
IconBtn.Position         = UDim2.new(0, 24, 0.5, -26)
IconBtn.BackgroundColor3 = DARK
IconBtn.BorderSizePixel  = 0
IconBtn.Text             = ""
IconBtn.Active           = true
IconBtn.Draggable        = true
IconBtn.ZIndex           = 20
IconBtn.Parent           = ScreenGui

local iconCorner = Instance.new("UICorner", IconBtn)
iconCorner.CornerRadius = UDim.new(0.5, 0)

local iconStroke = Instance.new("UIStroke", IconBtn)
iconStroke.Color     = RED
iconStroke.Thickness = 2.5

local iconLabel = Instance.new("TextLabel", IconBtn)
iconLabel.Size             = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Font             = Enum.Font.GothamBold
iconLabel.TextSize         = 17
iconLabel.RichText         = true
iconLabel.Text             = '<font color="#C82828">S</font><font color="#ffffff">M</font>'
iconLabel.ZIndex           = 21

-- ══════════════════════════════════════════════
-- MAIN FRAME (menu utama)
-- ══════════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Name          = "MainFrame"
MainFrame.Size          = UDim2.new(0, 400, 0, 500)
MainFrame.Position      = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = DARK
MainFrame.BorderSizePixel  = 0
MainFrame.Active           = true
MainFrame.Draggable        = true
MainFrame.Visible          = false
MainFrame.ZIndex           = 10
MainFrame.Parent           = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = RED mainStroke.Thickness = 1.5

-- TITLE BAR
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size             = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = DARK
TitleBar.BorderSizePixel  = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size             = UDim2.new(1, -50, 1, 0)
TitleLbl.Position         = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font             = Enum.Font.GothamBold
TitleLbl.TextSize         = 14
TitleLbl.TextColor3       = WHITE
TitleLbl.TextXAlignment   = Enum.TextXAlignment.Left
TitleLbl.RichText         = true
TitleLbl.Text             = '<font color="#C82828">SantaX</font> Mods'

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size             = UDim2.new(0, 26, 0, 26)
CloseBtn.Position         = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(160,25,25)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 13
CloseBtn.TextColor3       = WHITE
CloseBtn.Text             = "✕"
CloseBtn.BorderSizePixel  = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

-- TOGGLE: icon ↔ menu
local menuOpen = false
local function toggleMenu()
    menuOpen = not menuOpen
    MainFrame.Visible = menuOpen
end
IconBtn.MouseButton1Click:Connect(toggleMenu)
CloseBtn.MouseButton1Click:Connect(function()
    menuOpen = false
    MainFrame.Visible = false
end)

-- INFO BANNER
local InfoBanner = Instance.new("Frame", MainFrame)
InfoBanner.Size             = UDim2.new(1, -14, 0, 38)
InfoBanner.Position         = UDim2.new(0, 7, 0, 40)
InfoBanner.BackgroundColor3 = Color3.fromRGB(35, 8, 8)
InfoBanner.BorderSizePixel  = 0
Instance.new("UICorner", InfoBanner).CornerRadius = UDim.new(0, 6)

local InfoLine1 = Instance.new("TextLabel", InfoBanner)
InfoLine1.Size             = UDim2.new(1, -10, 0, 18)
InfoLine1.Position         = UDim2.new(0, 6, 0, 2)
InfoLine1.BackgroundTransparency = 1
InfoLine1.Font             = Enum.Font.Gotham
InfoLine1.TextSize         = 11
InfoLine1.TextColor3       = Color3.fromRGB(210,210,210)
InfoLine1.TextXAlignment   = Enum.TextXAlignment.Left
InfoLine1.RichText         = true
InfoLine1.Text             = '<font color="#C82828">Created By</font> : Astra   <font color="#C82828">Game</font> : Arsenal'

local InfoLine2 = Instance.new("TextLabel", InfoBanner)
InfoLine2.Size             = UDim2.new(1, -10, 0, 14)
InfoLine2.Position         = UDim2.new(0, 6, 0, 20)
InfoLine2.BackgroundTransparency = 1
InfoLine2.Font             = Enum.Font.Gotham
InfoLine2.TextSize         = 9
InfoLine2.TextColor3       = DIM
InfoLine2.TextXAlignment   = Enum.TextXAlignment.Left
InfoLine2.Text             = "Ludo ad oblectationem utendo, omnia pericula ab ipso usore feruntur."

-- TAB BAR
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size             = UDim2.new(0, 88, 1, -96)
TabBar.Position         = UDim2.new(0, 7, 0, 87)
TabBar.BackgroundColor3 = PANEL
TabBar.BorderSizePixel  = 0
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 6)
local tabLayout = Instance.new("UIListLayout", TabBar)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding   = UDim.new(0, 2)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local tabPad = Instance.new("UIPadding", TabBar)
tabPad.PaddingTop = UDim.new(0, 6)

-- CONTENT SCROLL
local ContentFrame = Instance.new("ScrollingFrame", MainFrame)
ContentFrame.Size                = UDim2.new(1, -104, 1, -96)
ContentFrame.Position            = UDim2.new(0, 100, 0, 87)
ContentFrame.BackgroundColor3    = PANEL
ContentFrame.BorderSizePixel     = 0
ContentFrame.ScrollBarThickness  = 3
ContentFrame.ScrollBarImageColor3= RED
ContentFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 6)
local cLayout = Instance.new("UIListLayout", ContentFrame)
cLayout.SortOrder = Enum.SortOrder.LayoutOrder
cLayout.Padding   = UDim.new(0, 3)
local cPad = Instance.new("UIPadding", ContentFrame)
cPad.PaddingLeft=UDim.new(0,8) cPad.PaddingRight=UDim.new(0,8)
cPad.PaddingTop=UDim.new(0,8) cPad.PaddingBottom=UDim.new(0,8)

-- ══════════════════════════════════════════════
-- FACTORY COMPONENTS
-- ══════════════════════════════════════════════
local function section(txt, order)
    local f = Instance.new("TextLabel", ContentFrame)
    f.LayoutOrder=order f.Size=UDim2.new(1,0,0,20)
    f.BackgroundTransparency=1 f.Font=Enum.Font.GothamBold
    f.TextSize=11 f.TextColor3=RED f.TextXAlignment=Enum.TextXAlignment.Left
    f.Text=txt:upper()
    return f
end

local function toggle(label, key, order, cb)
    local row = Instance.new("Frame", ContentFrame)
    row.LayoutOrder=order row.Size=UDim2.new(1,0,0,28)
    row.BackgroundColor3=ROW row.BorderSizePixel=0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,5)

    local box = Instance.new("Frame", row)
    box.Size=UDim2.new(0,16,0,16) box.Position=UDim2.new(0,7,0.5,-8)
    box.BackgroundColor3=DARK box.BorderSizePixel=0
    Instance.new("UICorner", box).CornerRadius=UDim.new(0,3)
    local bs=Instance.new("UIStroke",box) bs.Color=RED bs.Thickness=1

    local chk = Instance.new("TextLabel", box)
    chk.Size=UDim2.new(1,0,1,0) chk.BackgroundTransparency=1
    chk.Font=Enum.Font.GothamBold chk.TextSize=12 chk.TextColor3=RED chk.Text=""

    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(1,-32,1,0) lbl.Position=UDim2.new(0,28,0,0)
    lbl.BackgroundTransparency=1 lbl.Font=Enum.Font.Gotham
    lbl.TextSize=12 lbl.TextColor3=WHITE lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=label

    if label:find("%(Testing%)") then
        local badge=Instance.new("TextLabel",row)
        badge.Size=UDim2.new(0,50,0,14) badge.Position=UDim2.new(1,-56,0.5,-7)
        badge.BackgroundColor3=Color3.fromRGB(110,18,18) badge.Font=Enum.Font.GothamBold
        badge.TextSize=9 badge.TextColor3=WHITE badge.Text="TESTING" badge.BorderSizePixel=0
        Instance.new("UICorner",badge).CornerRadius=UDim.new(0,3)
    end

    local function upd()
        local on = State[key]
        chk.Text = on and "✓" or ""
        box.BackgroundColor3 = on and Color3.fromRGB(35,8,8) or DARK
    end
    upd()
    local btn = Instance.new("TextButton", row)
    btn.Size=UDim2.new(1,0,1,0) btn.BackgroundTransparency=1 btn.Text=""
    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key] upd()
        if cb then cb(State[key]) end
    end)
end

local function slider(label, key, minV, maxV, order, cb)
    local row = Instance.new("Frame", ContentFrame)
    row.LayoutOrder=order row.Size=UDim2.new(1,0,0,50)
    row.BackgroundColor3=ROW row.BorderSizePixel=0
    Instance.new("UICorner", row).CornerRadius=UDim.new(0,5)

    local top = Instance.new("Frame", row)
    top.Size=UDim2.new(1,0,0,24) top.BackgroundTransparency=1

    local lbl=Instance.new("TextLabel",top)
    lbl.Size=UDim2.new(0.6,0,1,0) lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1 lbl.Font=Enum.Font.Gotham
    lbl.TextSize=12 lbl.TextColor3=WHITE lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Text=label

    local valLbl=Instance.new("TextLabel",top)
    valLbl.Size=UDim2.new(0.4,-8,1,0) valLbl.Position=UDim2.new(0.6,0,0,0)
    valLbl.BackgroundTransparency=1 valLbl.Font=Enum.Font.GothamBold
    valLbl.TextSize=12 valLbl.TextColor3=RED valLbl.TextXAlignment=Enum.TextXAlignment.Right
    valLbl.Text=tostring(State[key])

    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(1,-16,0,6) track.Position=UDim2.new(0,8,0,32)
    track.BackgroundColor3=DARK track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(0,3)

    local fill=Instance.new("Frame",track)
    fill.BackgroundColor3=RED fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,3)

    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,12,0,12) knob.BackgroundColor3=WHITE
    knob.BorderSizePixel=0 knob.ZIndex=2
    Instance.new("UICorner",knob).CornerRadius=UDim.new(0.5,0)

    local function upd(v)
        local pct=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(pct,0,1,0)
        knob.Position=UDim2.new(pct,-6,0.5,-6)
        valLbl.Text=tostring(v)
        State[key]=v if cb then cb(v) end
    end
    upd(State[key])

    local drag=false
    knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local ap=track.AbsolutePosition local as=track.AbsoluteSize
            local rx=math.clamp(i.Position.X-ap.X,0,as.X)
            upd(math.floor(minV+(maxV-minV)*(rx/as.X)))
        end
    end)
end

local function dropdown(label, opts, key, order, cb)
    local row=Instance.new("Frame",ContentFrame)
    row.LayoutOrder=order row.Size=UDim2.new(1,0,0,30)
    row.BackgroundColor3=ROW row.BorderSizePixel=0 row.ClipsDescendants=false row.ZIndex=5
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.5,0,1,0) lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1 lbl.Font=Enum.Font.Gotham lbl.TextSize=12
    lbl.TextColor3=WHITE lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Text=label

    local sel=Instance.new("TextButton",row)
    sel.Size=UDim2.new(0.48,-4,0.78,0) sel.Position=UDim2.new(0.52,0,0.11,0)
    sel.BackgroundColor3=Color3.fromRGB(38,8,8) sel.Font=Enum.Font.GothamBold
    sel.TextSize=11 sel.TextColor3=RED sel.Text=State[key].." ▾" sel.BorderSizePixel=0
    Instance.new("UICorner",sel).CornerRadius=UDim.new(0,4)

    local df=Instance.new("Frame",row)
    df.Size=UDim2.new(0.48,-4,0,#opts*26) df.Position=UDim2.new(0.52,0,1,2)
    df.BackgroundColor3=Color3.fromRGB(22,5,5) df.BorderSizePixel=0
    df.ZIndex=10 df.Visible=false
    Instance.new("UICorner",df).CornerRadius=UDim.new(0,4)

    for i,opt in ipairs(opts) do
        local ob=Instance.new("TextButton",df)
        ob.Size=UDim2.new(1,0,0,26) ob.Position=UDim2.new(0,0,0,(i-1)*26)
        ob.BackgroundTransparency=1 ob.Font=Enum.Font.Gotham ob.TextSize=11
        ob.TextColor3=WHITE ob.Text=opt ob.ZIndex=11
        ob.MouseButton1Click:Connect(function()
            State[key]=opt sel.Text=opt.." ▾" df.Visible=false
            if cb then cb(opt) end
        end)
    end
    sel.MouseButton1Click:Connect(function() df.Visible=not df.Visible end)
end

local function teleportRow(order)
    local row=Instance.new("Frame",ContentFrame)
    row.LayoutOrder=order row.Size=UDim2.new(1,0,0,58)
    row.BackgroundColor3=ROW row.BorderSizePixel=0 row.ClipsDescendants=false row.ZIndex=5
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)

    local top=Instance.new("Frame",row)
    top.Size=UDim2.new(1,0,0,28) top.BackgroundTransparency=1

    local box=Instance.new("Frame",top) box.Size=UDim2.new(0,16,0,16)
    box.Position=UDim2.new(0,7,0.5,-8) box.BackgroundColor3=DARK box.BorderSizePixel=0
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,3)
    local bs2=Instance.new("UIStroke",box) bs2.Color=RED bs2.Thickness=1
    local chk2=Instance.new("TextLabel",box)
    chk2.Size=UDim2.new(1,0,1,0) chk2.BackgroundTransparency=1
    chk2.Font=Enum.Font.GothamBold chk2.TextSize=12 chk2.TextColor3=RED chk2.Text=""

    local lbl2=Instance.new("TextLabel",top)
    lbl2.Size=UDim2.new(0.45,0,1,0) lbl2.Position=UDim2.new(0,28,0,0)
    lbl2.BackgroundTransparency=1 lbl2.Font=Enum.Font.Gotham
    lbl2.TextSize=12 lbl2.TextColor3=WHITE lbl2.TextXAlignment=Enum.TextXAlignment.Left
    lbl2.Text="Teleport Toggle"

    local sel2=Instance.new("TextButton",top)
    sel2.Size=UDim2.new(0.42,0,0.78,0) sel2.Position=UDim2.new(0.57,0,0.11,0)
    sel2.BackgroundColor3=Color3.fromRGB(38,8,8) sel2.Font=Enum.Font.GothamBold
    sel2.TextSize=10 sel2.TextColor3=RED sel2.Text="Target ▾" sel2.BorderSizePixel=0
    Instance.new("UICorner",sel2).CornerRadius=UDim.new(0,4)

    local df2=Instance.new("ScrollingFrame",row)
    df2.Size=UDim2.new(0.42,0,0,76) df2.Position=UDim2.new(0.57,0,0,28)
    df2.BackgroundColor3=Color3.fromRGB(22,5,5) df2.BorderSizePixel=0
    df2.ZIndex=10 df2.Visible=false df2.ScrollBarThickness=2
    df2.CanvasSize=UDim2.new(0,0,0,0) df2.AutomaticCanvasSize=Enum.AutomaticSize.Y
    Instance.new("UICorner",df2).CornerRadius=UDim.new(0,4)
    Instance.new("UIListLayout",df2).SortOrder=Enum.SortOrder.LayoutOrder

    local tpBtn=Instance.new("TextButton",row)
    tpBtn.Size=UDim2.new(1,-12,0,22) tpBtn.Position=UDim2.new(0,6,0,32)
    tpBtn.BackgroundColor3=RED tpBtn.Font=Enum.Font.GothamBold
    tpBtn.TextSize=11 tpBtn.TextColor3=WHITE tpBtn.Text="⚡ Teleport Now" tpBtn.BorderSizePixel=0
    Instance.new("UICorner",tpBtn).CornerRadius=UDim.new(0,4)

    local function refresh()
        for _,c in ipairs(df2:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _,p in ipairs(getEnemies()) do
            local ob=Instance.new("TextButton",df2)
            ob.Size=UDim2.new(1,0,0,22) ob.BackgroundTransparency=1
            ob.Font=Enum.Font.Gotham ob.TextSize=10 ob.TextColor3=WHITE ob.Text=p.Name ob.ZIndex=11
            ob.MouseButton1Click:Connect(function()
                State.TeleportTarget=p.Name sel2.Text=p.Name.." ▾" df2.Visible=false
            end)
        end
    end
    sel2.MouseButton1Click:Connect(function() refresh() df2.Visible=not df2.Visible end)
    tpBtn.MouseButton1Click:Connect(doTeleport)

    local togBtn=Instance.new("TextButton",top)
    togBtn.Size=UDim2.new(0.5,0,1,0) togBtn.BackgroundTransparency=1 togBtn.Text=""
    togBtn.MouseButton1Click:Connect(function()
        State.TeleportToggle=not State.TeleportToggle
        chk2.Text=State.TeleportToggle and "✓" or ""
        box.BackgroundColor3=State.TeleportToggle and Color3.fromRGB(35,8,8) or DARK
    end)
end

-- ══════════════════════════════════════════════
-- TAB SYSTEM
-- ══════════════════════════════════════════════
local tabs     = {"Main","Aim","Visual","Exploits"}
local tabBtns  = {}
local activeTab = ""

local function clearContent()
    for _, c in ipairs(ContentFrame:GetChildren()) do
        if c:IsA("UIListLayout") or c:IsA("UIPadding") then continue end
        c:Destroy()
    end
end

local function setTab(name)
    if activeTab == name then return end
    activeTab = name
    clearContent()

    for n, b in pairs(tabBtns) do
        local on = n == name
        b.TextColor3       = on and WHITE or DIM
        b.BackgroundColor3 = on and ROW or PANEL
        local lb = b:FindFirstChild("LB") if lb then lb:Destroy() end
        if on then
            local lb2=Instance.new("Frame",b) lb2.Name="LB"
            lb2.Size=UDim2.new(0,3,0.65,0) lb2.Position=UDim2.new(0,0,0.175,0)
            lb2.BackgroundColor3=RED lb2.BorderSizePixel=0
            Instance.new("UICorner",lb2).CornerRadius=UDim.new(0,2)
        end
    end

    if name == "Main" then
        section("MAIN SETTINGS", 1)
        toggle("Enable Feature", "EnableFeature", 2)
        toggle("Enable Aim",     "EnableAim",     3)
        toggle("Enable ESP",     "EnableEsp",     4)

    elseif name == "Aim" then
        section("AIM SETTINGS", 1)
        toggle("Aimbot Fire",          "AimbotFire",  2)
        toggle("Aimbot Legit",         "AimbotLegit", 3)
        toggle("Aim Assist",           "AimAssist",   4)
        toggle("Aim Silent",           "AimSilent",   5)
        toggle("Aim Visible",          "AimVisible",  6)
        toggle("Aim Magnet (Testing)", "AimMagnet",   7)
        toggle("Aim Kill (Testing)",   "AimKill",     8)
        dropdown("Aim Target", {"Body","Head","Random"}, "AimTarget", 9)
        slider("Aim FoV", "AimFov", 1, 360, 10)

    elseif name == "Visual" then
        section("VISUAL SETTINGS", 1)
        toggle("Esp Line",     "EspLine",     2)
        toggle("Esp Box",      "EspBox",      3)
        toggle("Esp Hitbox 3D","EspHitbox3D", 4)
        toggle("Esp Health",   "EspHealth",   5)
        toggle("Esp Distance", "EspDistance", 6)
        toggle("Esp Name",     "EspName",     7)
        toggle("Esp Skeleton", "EspSkeleton", 8)

    elseif name == "Exploits" then
        section("EXPLOIT SETTINGS", 1)
        toggle("Speed Hack (2x)",     "SpeedHack",  2, applySpeed)
        toggle("Jump Boost (2x)",     "JumpBoost",  3, applyJump)
        toggle("Double Jump",         "DoubleJump", 4, applyDoubleJump)
        teleportRow(5)
        toggle("Fly Auto Toggle",     "FlyAuto",    6, applyFlyAuto)
        toggle("Fly to Player Toggle","FlyToPlayer",7, function(v)
            if v then task.spawn(doFlyToPlayer) end
        end)
        toggle("Fast Reload (100x)",  "FastReload", 8, function(v)
            if v then hookAnimSpeed("reload",100) else hookAnimSpeed("reload",1) end
        end)
        toggle("Speed Fire (100x)",   "SpeedFire",  9, function(v)
            if v then hookAnimSpeed("fire",100) else hookAnimSpeed("fire",1) end
        end)
    end
end

for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", TabBar)
    btn.LayoutOrder      = i
    btn.Size             = UDim2.new(0.88, 0, 0, 38)
    btn.BackgroundColor3 = PANEL
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 12
    btn.TextColor3       = DIM
    btn.Text             = name
    btn.BorderSizePixel  = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    tabBtns[name] = btn
    btn.MouseButton1Click:Connect(function() setTab(name) end)
end

setTab("Main")

-- NOTIF
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title    = "SantaX Mods",
        Text     = "Loaded — Created by Astra ✓",
        Duration = 4,
    })
end)

print("[SantaX Mods] ✓ Loaded — Astra | Arsenal FPS")
