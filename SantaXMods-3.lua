-- ╔══════════════════════════════════════════════╗
-- ║           SantaX Mods — Arsenal FPS         ║
-- ║  Created By : Astra                         ║
-- ║  Game       : Arsenal (& FPS Roblox)        ║
-- ║  Ludo ad oblectationem utendo,              ║
-- ║  omnia pericula ab ipso usore feruntur.     ║
-- ╚══════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local StarterGui       = game:GetService("StarterGui")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end
local Camera = Workspace.CurrentCamera

-- ══════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════
local State = {
    EnableFeature=false, EnableAim=false, EnableEsp=false,
    AimbotFire=false, AimbotLegit=false, AimAssist=false,
    AimSilent=false, AimVisible=false,
    AimMagnet=false, AimKill=false,
    AimTarget="Body", AimFov=90,
    EspLine=false, EspBox=false, EspHitbox3D=false,
    EspHealth=false, EspDistance=false, EspName=false, EspSkeleton=false,
    SpeedHack=false, JumpBoost=false, DoubleJump=false,
    TeleportToggle=false, FlyAuto=false, FlyToPlayer=false,
    FastReload=false, SpeedFire=false,
    TeleportTarget=nil, FlyConn=nil, JumpCount=0,
}

-- ══════════════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════════════
local function getChar(p) return p and p.Character end
local function getRoot(p)
    local c=getChar(p)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end
local function getHum(p)
    local c=getChar(p)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHead(p)
    local c=getChar(p)
    return c and c:FindFirstChild("Head")
end
local function isAlive(p)
    local h=getHum(p)
    return h and h.Health>0
end
local function isEnemy(p)
    if p==LocalPlayer then return false end
    if LocalPlayer.Team and p.Team and LocalPlayer.Team==p.Team then return false end
    return true
end
local function getEnemies()
    local t={}
    for _,p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) and isAlive(p) then t[#t+1]=p end
    end
    return t
end

-- ══════════════════════════════════════════════
-- WALLCHECK — true = ada tembok di depan
-- ══════════════════════════════════════════════
local function hasWall(fromPlayer, toPart)
    local myRoot = getRoot(fromPlayer)
    local myChar = getChar(fromPlayer)
    local tChar  = getChar(toPart.Parent and toPart.Parent.Parent)
    if not myRoot then return false end
    local origin = myRoot.Position
    local dir    = toPart.Position - origin
    local rp     = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local excludes = {}
    if myChar then table.insert(excludes, myChar) end
    -- exclude semua karakter enemy juga biar ray tembus karakter lain
    for _,ep in ipairs(Players:GetPlayers()) do
        local ec = getChar(ep)
        if ec then table.insert(excludes, ec) end
    end
    rp.FilterDescendantsInstances = excludes
    local result = Workspace:Raycast(origin, dir, rp)
    return result ~= nil  -- kena sesuatu = ada tembok
end

local function getTargetPart(p)
    local t=State.AimTarget
    if t=="Random" then t=math.random(1,2)==1 and "Head" or "Body" end
    local c=getChar(p) if not c then return nil end
    if t=="Head" then return c:FindFirstChild("Head")
    else return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") end
end

-- closest enemy dalam FoV — dengan wallcheck opsional
local function getClosest(checkWall)
    local cx=Camera.ViewportSize.X/2
    local cy=Camera.ViewportSize.Y/2
    local center=Vector2.new(cx,cy)
    local radius=(State.AimFov/360)*Camera.ViewportSize.X*0.5
    local best,bestD,bestPart=nil,math.huge,nil
    for _,p in ipairs(getEnemies()) do
        local part=getTargetPart(p) if not part then continue end
        local sp,vis=Camera:WorldToViewportPoint(part.Position)
        if not vis then continue end
        local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
        if d<radius and d<bestD then
            if checkWall and hasWall(LocalPlayer, part) then continue end
            best=p bestD=d bestPart=part
        end
    end
    return best,bestPart
end

-- ══════════════════════════════════════════════
-- AIM LOOP
-- ══════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not State.EnableFeature or not State.EnableAim then return end

    -- AimVisible ON = hanya incar yang tidak dibalik tembok
    local wallFilter = State.AimVisible
    local enemy, part = getClosest(wallFilter)
    if not enemy or not part then return end

    if State.AimbotFire then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
    elseif State.AimbotLegit then
        -- AimVisible sudah difilter di getClosest, langsung lerp
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), 0.18)
    elseif State.AimAssist then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), 0.09)
    end

    if State.AimSilent then
        local root=getRoot(LocalPlayer)
        if root then
            root.CFrame=CFrame.new(root.Position, Vector3.new(part.Position.X,root.Position.Y,part.Position.Z))
        end
    end

    if State.AimMagnet then
        local cx=Camera.ViewportSize.X/2
        local cy=Camera.ViewportSize.Y/2
        local center=Vector2.new(cx,cy)
        local radius=(State.AimFov/360)*Camera.ViewportSize.X*0.5
        local myRoot=getRoot(LocalPlayer)
        for _,p in ipairs(getEnemies()) do
            local rp=getRoot(p) if not rp then continue end
            local sp,vis=Camera:WorldToViewportPoint(rp.Position)
            if not vis then continue end
            local d=(Vector2.new(sp.X,sp.Y)-center).Magnitude
            if myRoot and d<radius then
                local worldD=(rp.Position-myRoot.Position).Magnitude
                local ray=Camera:ScreenPointToRay(cx,cy)
                rp.CFrame=CFrame.new(ray.Origin+ray.Direction*worldD, ray.Origin+ray.Direction*(worldD+1))
            end
        end
    end

    if State.AimKill then
        local cx=Camera.ViewportSize.X/2
        local cy=Camera.ViewportSize.Y/2
        local center=Vector2.new(cx,cy)
        local radius=(State.AimFov/360)*Camera.ViewportSize.X*0.5
        for _,p in ipairs(getEnemies()) do
            local pt=getTargetPart(p) if not pt then continue end
            local sp,vis=Camera:WorldToViewportPoint(pt.Position)
            if not vis then continue end
            if (Vector2.new(sp.X,sp.Y)-center).Magnitude>=radius then continue end
            -- AimVisible = skip kalau dibalik tembok
            if State.AimVisible and hasWall(LocalPlayer, pt) then continue end
            local hum=getHum(p) if hum then hum.Health=0 end
        end
    end
end)

-- ══════════════════════════════════════════════
-- EXPLOITS
-- ══════════════════════════════════════════════
local wsConn
local function applySpeed(v)
    local h=getHum(LocalPlayer) if not h then return end
    h.WalkSpeed=v and 32 or 16
    if wsConn then wsConn:Disconnect() wsConn=nil end
    if v then wsConn=h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if State.SpeedHack then h.WalkSpeed=32 end
    end) end
end
local function applyJump(v)
    local h=getHum(LocalPlayer) if not h then return end
    h.JumpPower=v and 100 or 50
end
local djConn
local function applyDoubleJump(v)
    if djConn then djConn:Disconnect() djConn=nil end
    State.JumpCount=0
    if not v then return end
    local h=getHum(LocalPlayer) if not h then return end
    djConn=h.StateChanged:Connect(function(_,n)
        if n==Enum.HumanoidStateType.Jumping then State.JumpCount=State.JumpCount+1
        elseif n==Enum.HumanoidStateType.Landed then State.JumpCount=0 end
    end)
    UserInputService.InputBegan:Connect(function(inp,gp)
        if gp then return end
        if inp.KeyCode==Enum.KeyCode.Space and State.DoubleJump and State.JumpCount==1 then
            local r=getRoot(LocalPlayer)
            if r then r.Velocity=Vector3.new(r.Velocity.X,60,r.Velocity.Z) State.JumpCount=2 end
        end
    end)
end
local function applyFlyAuto(v)
    if State.FlyConn then State.FlyConn:Disconnect() State.FlyConn=nil end
    local root=getRoot(LocalPlayer) local h=getHum(LocalPlayer)
    if not root or not h then return end
    if v then
        h.PlatformStand=true
        local bp=Instance.new("BodyPosition")
        bp.Name="SXFly" bp.MaxForce=Vector3.new(1e5,1e5,1e5) bp.P=1e4
        bp.Position=root.Position+Vector3.new(0,15,0) bp.Parent=root
        State.FlyConn=RunService.Heartbeat:Connect(function()
            if not State.FlyAuto then bp:Destroy() h.PlatformStand=false
                State.FlyConn:Disconnect() State.FlyConn=nil return end
            bp.Position=Vector3.new(root.Position.X,root.Position.Y+15,root.Position.Z)
        end)
    else
        local e=root:FindFirstChild("SXFly") if e then e:Destroy() end
        h.PlatformStand=false
    end
end
local function doFlyToPlayer()
    local h=getHum(LocalPlayer) local r=getRoot(LocalPlayer)
    if not h or not r then return end
    h.PlatformStand=true
    for _,p in ipairs(getEnemies()) do
        if not State.FlyToPlayer then break end
        local tr=getRoot(p) if not tr then continue end
        local bp=Instance.new("BodyPosition")
        bp.MaxForce=Vector3.new(1e5,1e5,1e5) bp.P=1e4 bp.Position=tr.Position bp.Parent=r
        task.wait(0.8) bp:Destroy()
    end
    h.PlatformStand=false
end
local function doTeleport()
    if not State.TeleportTarget then return end
    local tp=Players:FindFirstChild(State.TeleportTarget) if not tp then return end
    local tr=getRoot(tp) local mr=getRoot(LocalPlayer)
    if tr and mr then mr.CFrame=tr.CFrame+Vector3.new(2,0,0) end
end
local function hookAnimSpeed(kw,spd)
    local c=getChar(LocalPlayer) if not c then return end
    local h=c:FindFirstChildOfClass("Humanoid") if not h then return end
    local a=h:FindFirstChildOfClass("Animator") if not a then return end
    for _,t in ipairs(a:GetPlayingAnimationTracks()) do
        if t.Name:lower():find(kw) then t:AdjustSpeed(spd) end
    end
    a.AnimationPlayed:Connect(function(t)
        if t.Name:lower():find(kw) then t:AdjustSpeed(spd) end
    end)
end

-- ══════════════════════════════════════════════
-- ESP — FIX GHOST + FIX BOX POSISI
-- ══════════════════════════════════════════════
local espCache = {}

-- Helper destroy semua drawing milik satu player
local function destroyPlayerESP(p)
    local d = espCache[p]
    if not d then return end
    local function killObj(obj)
        if type(obj)=="table" then
            for _,v in pairs(obj) do killObj(v) end
        elseif pcall(function() return obj.Visible end) then
            pcall(function() obj:Remove() end)
        end
    end
    killObj(d)
    espCache[p] = nil
end

-- Saat player leave / mati, langsung hapus drawing mereka
Players.PlayerRemoving:Connect(destroyPlayerESP)
Players.PlayerAdded:Connect(function(p)
    p.CharacterRemoving:Connect(function()
        destroyPlayerESP(p)
    end)
end)
-- Untuk player yang sudah ada sebelum script jalan
for _,p in ipairs(Players:GetPlayers()) do
    if p~=LocalPlayer then
        p.CharacterRemoving:Connect(function()
            destroyPlayerESP(p)
        end)
    end
end

local function hidePlayerESP(p)
    local d=espCache[p] if not d then return end
    local function hide(obj)
        if type(obj)=="table" then for _,v in pairs(obj) do hide(v) end
        elseif pcall(function() return obj.Visible end) then
            pcall(function() obj.Visible=false end)
        end
    end
    hide(d)
end

RunService.RenderStepped:Connect(function()
    -- Kalau ESP off, sembunyikan semua lalu return
    if not State.EnableFeature or not State.EnableEsp then
        for p,_ in pairs(espCache) do hidePlayerESP(p) end
        return
    end

    -- Set aktif player ke tabel untuk cek ghost
    local activeSet={}
    for _,p in ipairs(getEnemies()) do activeSet[p]=true end

    -- Hapus ESP player yang sudah tidak jadi enemy / mati
    for p,_ in pairs(espCache) do
        if not activeSet[p] then
            destroyPlayerESP(p)
        end
    end

    for _,p in ipairs(getEnemies()) do
        local c=getChar(p)
        local root=getRoot(p)
        local head=getHead(p)
        local hum=getHum(p)
        if not c or not root or not head or not hum then
            hidePlayerESP(p) continue
        end

        -- Ambil screen pos root (bagian tengah badan)
        local rs,visR=Camera:WorldToViewportPoint(root.Position)
        -- Ambil screen pos head
        local hs,visH=Camera:WorldToViewportPoint(head.Position)
        -- Ambil screen pos kaki (estimasi: root - offset ke bawah)
        local footPos=root.Position - Vector3.new(0, (root.Size and root.Size.Y/2 or 1.5), 0)
        local fs,visF=Camera:WorldToViewportPoint(footPos)

        if not visR then hidePlayerESP(p) continue end

        espCache[p]=espCache[p] or {}
        local d=espCache[p]

        -- ══ BOX FIX ══
        -- Pakai head screen Y sebagai top, foot screen Y sebagai bottom
        -- Ini jauh lebih akurat daripada *2.2 multiplier
        local topY    = hs.Y - 6          -- sedikit margin atas kepala
        local bottomY = fs.Y + 4          -- sedikit margin bawah kaki
        local boxH    = bottomY - topY
        if boxH < 10 then boxH=10 end     -- minimum agar tidak collapse
        local boxW    = boxH * 0.52
        local bx      = rs.X - boxW/2
        local by      = topY

        if State.EspBox then
            if not d.Box then
                local b=Drawing.new("Square")
                b.Color=Color3.fromRGB(220,50,50) b.Thickness=1.5 b.Filled=false
                d.Box=b
            end
            d.Box.Size=Vector2.new(boxW,boxH)
            d.Box.Position=Vector2.new(bx,by)
            d.Box.Visible=true
        elseif d.Box then d.Box.Visible=false end

        -- Line dari bawah layar ke root
        if State.EspLine then
            if not d.Line then
                local l=Drawing.new("Line")
                l.Color=Color3.fromRGB(220,50,50) l.Thickness=1.5
                d.Line=l
            end
            d.Line.From=Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            d.Line.To=Vector2.new(rs.X, rs.Y)
            d.Line.Visible=true
        elseif d.Line then d.Line.Visible=false end

        -- Name — tampil di atas kepala
        if State.EspName then
            if not d.NameD then
                local n=Drawing.new("Text")
                n.Color=Color3.fromRGB(255,255,255) n.Size=13 n.Center=true
                d.NameD=n
            end
            d.NameD.Text=p.Name
            d.NameD.Position=Vector2.new(rs.X, by-16)
            d.NameD.Visible=true
        elseif d.NameD then d.NameD.Visible=false end

        -- Health — tampil di bawah box
        if State.EspHealth then
            if not d.Hp then
                local h2=Drawing.new("Text")
                h2.Color=Color3.fromRGB(80,255,80) h2.Size=12 h2.Center=true
                d.Hp=h2
            end
            d.Hp.Text=string.format("HP: %d", math.floor(hum.Health))
            d.Hp.Position=Vector2.new(rs.X, bottomY+4)
            d.Hp.Visible=true
        elseif d.Hp then d.Hp.Visible=false end

        -- Distance
        if State.EspDistance then
            local mr=getRoot(LocalPlayer)
            local dist=mr and math.floor((root.Position-mr.Position).Magnitude) or 0
            if not d.Dist then
                local dd=Drawing.new("Text")
                dd.Color=Color3.fromRGB(255,200,0) dd.Size=12 dd.Center=true
                d.Dist=dd
            end
            d.Dist.Text=dist.."m"
            d.Dist.Position=Vector2.new(rs.X, bottomY+16)
            d.Dist.Visible=true
        elseif d.Dist then d.Dist.Visible=false end

        -- Skeleton
        if State.EspSkeleton then
            local bones={
                {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
                {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
                {"LeftLowerArm","LeftHand"},
                {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
                {"RightLowerArm","RightHand"},
                {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
                {"LeftLowerLeg","LeftFoot"},
                {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},
                {"RightLowerLeg","RightFoot"},
            }
            d.Sk=d.Sk or {}
            for i,pair in ipairs(bones) do
                local b1=c:FindFirstChild(pair[1])
                local b2=c:FindFirstChild(pair[2])
                if b1 and b2 then
                    local s1,v1=Camera:WorldToViewportPoint(b1.Position)
                    local s2,v2=Camera:WorldToViewportPoint(b2.Position)
                    if v1 and v2 then
                        if not d.Sk[i] then
                            local l=Drawing.new("Line")
                            l.Color=Color3.fromRGB(220,60,60) l.Thickness=1
                            d.Sk[i]=l
                        end
                        d.Sk[i].From=Vector2.new(s1.X,s1.Y)
                        d.Sk[i].To=Vector2.new(s2.X,s2.Y)
                        d.Sk[i].Visible=true
                    end
                end
            end
        else
            if d.Sk then for _,l in pairs(d.Sk) do
                pcall(function() l.Visible=false end)
            end end
        end
    end
end)

-- ══════════════════════════════════════════════
-- FOV CIRCLE + CROSSHAIR
-- ══════════════════════════════════════════════
local fovCircle=Drawing.new("Circle")
fovCircle.Filled=false fovCircle.Color=Color3.fromRGB(200,40,40)
fovCircle.Thickness=1.5 fovCircle.NumSides=64

local cross={}
for i=1,4 do
    local l=Drawing.new("Line")
    l.Color=Color3.fromRGB(255,255,255) l.Thickness=1.5 l.Visible=true
    cross[i]=l
end

RunService.RenderStepped:Connect(function()
    local cx=Camera.ViewportSize.X/2
    local cy=Camera.ViewportSize.Y/2
    local radius=(State.AimFov/360)*Camera.ViewportSize.X*0.5
    fovCircle.Radius=radius
    fovCircle.Position=Vector2.new(cx,cy)
    fovCircle.Visible=State.EnableFeature and State.EnableAim
    local cs=8
    cross[1].From=Vector2.new(cx-cs,cy) cross[1].To=Vector2.new(cx-2,cy)
    cross[2].From=Vector2.new(cx+2,cy)  cross[2].To=Vector2.new(cx+cs,cy)
    cross[3].From=Vector2.new(cx,cy-cs) cross[3].To=Vector2.new(cx,cy-2)
    cross[4].From=Vector2.new(cx,cy+2)  cross[4].To=Vector2.new(cx,cy+cs)
    for i=1,4 do cross[i].Visible=true end
end)

-- ══════════════════════════════════════════════
-- GUI ROOT
-- ══════════════════════════════════════════════
local oldGui=CoreGui:FindFirstChild("SantaXMods")
if oldGui then oldGui:Destroy() end

local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="SantaXMods"
ScreenGui.ResetOnSpawn=false
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset=true
ScreenGui.Parent=CoreGui

local RED   =Color3.fromRGB(200,40,40)
local WHITE =Color3.fromRGB(255,255,255)
local DARK  =Color3.fromRGB(13,13,13)
local PANEL =Color3.fromRGB(20,20,20)
local ROW   =Color3.fromRGB(28,28,28)
local DIM   =Color3.fromRGB(110,110,110)

-- ══ ICON ══
local IconBtn=Instance.new("TextButton")
IconBtn.Name="SantaXIcon"
IconBtn.Size=UDim2.new(0,52,0,52)
IconBtn.Position=UDim2.new(0,24,0.5,-26)
IconBtn.BackgroundColor3=DARK
IconBtn.BorderSizePixel=0 IconBtn.Text=""
IconBtn.Active=true IconBtn.Draggable=true IconBtn.ZIndex=20
IconBtn.Parent=ScreenGui
Instance.new("UICorner",IconBtn).CornerRadius=UDim.new(0.5,0)
local ics=Instance.new("UIStroke",IconBtn)
ics.Color=RED ics.Thickness=2.5
local icLbl=Instance.new("TextLabel",IconBtn)
icLbl.Size=UDim2.new(1,0,1,0) icLbl.BackgroundTransparency=1
icLbl.Font=Enum.Font.GothamBold icLbl.TextSize=17
icLbl.RichText=true icLbl.ZIndex=21
icLbl.Text='<font color="#C82828">S</font><font color="#ffffff">M</font>'

-- ══ MAIN FRAME ══
local MainFrame=Instance.new("Frame")
MainFrame.Name="MainFrame"
MainFrame.Size=UDim2.new(0,400,0,500)
MainFrame.Position=UDim2.new(0.5,-200,0.5,-250)
MainFrame.BackgroundColor3=DARK MainFrame.BorderSizePixel=0
MainFrame.Active=true MainFrame.Draggable=true
MainFrame.Visible=false MainFrame.ZIndex=10
MainFrame.Parent=ScreenGui
Instance.new("UICorner",MainFrame).CornerRadius=UDim.new(0,8)
local ms=Instance.new("UIStroke",MainFrame) ms.Color=RED ms.Thickness=1.5

-- Title
local TitleBar=Instance.new("Frame",MainFrame)
TitleBar.Size=UDim2.new(1,0,0,36) TitleBar.BackgroundColor3=DARK TitleBar.BorderSizePixel=0
Instance.new("UICorner",TitleBar).CornerRadius=UDim.new(0,8)
local TitleLbl=Instance.new("TextLabel",TitleBar)
TitleLbl.Size=UDim2.new(1,-50,1,0) TitleLbl.Position=UDim2.new(0,12,0,0)
TitleLbl.BackgroundTransparency=1 TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextSize=14 TitleLbl.TextColor3=WHITE
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left TitleLbl.RichText=true
TitleLbl.Text='<font color="#C82828">SantaX</font> Mods'
local CloseBtn=Instance.new("TextButton",TitleBar)
CloseBtn.Size=UDim2.new(0,26,0,26) CloseBtn.Position=UDim2.new(1,-30,0,5)
CloseBtn.BackgroundColor3=Color3.fromRGB(160,25,25) CloseBtn.Font=Enum.Font.GothamBold
CloseBtn.TextSize=13 CloseBtn.TextColor3=WHITE CloseBtn.Text="✕" CloseBtn.BorderSizePixel=0
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,5)

local menuOpen=false
local function toggleMenu() menuOpen=not menuOpen MainFrame.Visible=menuOpen end
IconBtn.MouseButton1Click:Connect(toggleMenu)
CloseBtn.MouseButton1Click:Connect(function() menuOpen=false MainFrame.Visible=false end)

-- Info Banner
local InfoBanner=Instance.new("Frame",MainFrame)
InfoBanner.Size=UDim2.new(1,-14,0,38) InfoBanner.Position=UDim2.new(0,7,0,40)
InfoBanner.BackgroundColor3=Color3.fromRGB(35,8,8) InfoBanner.BorderSizePixel=0
Instance.new("UICorner",InfoBanner).CornerRadius=UDim.new(0,6)
local IL1=Instance.new("TextLabel",InfoBanner)
IL1.Size=UDim2.new(1,-10,0,18) IL1.Position=UDim2.new(0,6,0,2)
IL1.BackgroundTransparency=1 IL1.Font=Enum.Font.Gotham IL1.TextSize=11
IL1.TextColor3=Color3.fromRGB(210,210,210) IL1.TextXAlignment=Enum.TextXAlignment.Left
IL1.RichText=true IL1.Text='<font color="#C82828">Created By</font> : Astra   <font color="#C82828">Game</font> : Arsenal'
local IL2=Instance.new("TextLabel",InfoBanner)
IL2.Size=UDim2.new(1,-10,0,14) IL2.Position=UDim2.new(0,6,0,20)
IL2.BackgroundTransparency=1 IL2.Font=Enum.Font.Gotham IL2.TextSize=9
IL2.TextColor3=DIM IL2.TextXAlignment=Enum.TextXAlignment.Left
IL2.Text="Ludo ad oblectationem utendo, omnia pericula ab ipso usore feruntur."

-- Tab Bar
local TabBar=Instance.new("Frame",MainFrame)
TabBar.Size=UDim2.new(0,88,1,-96) TabBar.Position=UDim2.new(0,7,0,87)
TabBar.BackgroundColor3=PANEL TabBar.BorderSizePixel=0
Instance.new("UICorner",TabBar).CornerRadius=UDim.new(0,6)
local tbL=Instance.new("UIListLayout",TabBar)
tbL.SortOrder=Enum.SortOrder.LayoutOrder tbL.Padding=UDim.new(0,2)
tbL.HorizontalAlignment=Enum.HorizontalAlignment.Center
local tbP=Instance.new("UIPadding",TabBar) tbP.PaddingTop=UDim.new(0,6)

-- Content
local ContentFrame=Instance.new("ScrollingFrame",MainFrame)
ContentFrame.Size=UDim2.new(1,-104,1,-96) ContentFrame.Position=UDim2.new(0,100,0,87)
ContentFrame.BackgroundColor3=PANEL ContentFrame.BorderSizePixel=0
ContentFrame.ScrollBarThickness=3 ContentFrame.ScrollBarImageColor3=RED
ContentFrame.CanvasSize=UDim2.new(0,0,0,0) ContentFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
Instance.new("UICorner",ContentFrame).CornerRadius=UDim.new(0,6)
local cL=Instance.new("UIListLayout",ContentFrame)
cL.SortOrder=Enum.SortOrder.LayoutOrder cL.Padding=UDim.new(0,3)
local cP=Instance.new("UIPadding",ContentFrame)
cP.PaddingLeft=UDim.new(0,8) cP.PaddingRight=UDim.new(0,8)
cP.PaddingTop=UDim.new(0,8) cP.PaddingBottom=UDim.new(0,8)

-- ══════════════════════════════════════════════
-- COMPONENTS
-- ══════════════════════════════════════════════
local function section(txt,order)
    local f=Instance.new("TextLabel",ContentFrame)
    f.LayoutOrder=order f.Size=UDim2.new(1,0,0,20)
    f.BackgroundTransparency=1 f.Font=Enum.Font.GothamBold
    f.TextSize=11 f.TextColor3=RED f.TextXAlignment=Enum.TextXAlignment.Left
    f.Text=txt:upper()
end

local function toggle(label,key,order,cb)
    local row=Instance.new("Frame",ContentFrame)
    row.LayoutOrder=order row.Size=UDim2.new(1,0,0,28)
    row.BackgroundColor3=ROW row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)
    local box=Instance.new("Frame",row)
    box.Size=UDim2.new(0,16,0,16) box.Position=UDim2.new(0,7,0.5,-8)
    box.BackgroundColor3=DARK box.BorderSizePixel=0
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,3)
    local bs=Instance.new("UIStroke",box) bs.Color=RED bs.Thickness=1
    local chk=Instance.new("TextLabel",box)
    chk.Size=UDim2.new(1,0,1,0) chk.BackgroundTransparency=1
    chk.Font=Enum.Font.GothamBold chk.TextSize=12 chk.TextColor3=RED chk.Text=""
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-32,1,0) lbl.Position=UDim2.new(0,28,0,0)
    lbl.BackgroundTransparency=1 lbl.Font=Enum.Font.Gotham
    lbl.TextSize=12 lbl.TextColor3=WHITE lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Text=label
    if label:find("%(Testing%)") then
        local b2=Instance.new("TextLabel",row)
        b2.Size=UDim2.new(0,50,0,14) b2.Position=UDim2.new(1,-56,0.5,-7)
        b2.BackgroundColor3=Color3.fromRGB(110,18,18) b2.Font=Enum.Font.GothamBold
        b2.TextSize=9 b2.TextColor3=WHITE b2.Text="TESTING" b2.BorderSizePixel=0
        Instance.new("UICorner",b2).CornerRadius=UDim.new(0,3)
    end
    local function upd()
        chk.Text=State[key] and "✓" or ""
        box.BackgroundColor3=State[key] and Color3.fromRGB(35,8,8) or DARK
    end
    upd()
    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(1,0,1,0) btn.BackgroundTransparency=1 btn.Text=""
    btn.MouseButton1Click:Connect(function()
        State[key]=not State[key] upd()
        if cb then cb(State[key]) end
    end)
end

-- ══ SLIDER FIX — pakai InputBegan di track bukan hanya knob ══
local function slider(label,key,minV,maxV,order,cb)
    local row=Instance.new("Frame",ContentFrame)
    row.LayoutOrder=order row.Size=UDim2.new(1,0,0,50)
    row.BackgroundColor3=ROW row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)

    local top=Instance.new("Frame",row)
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
    track.Size=UDim2.new(1,-16,0,8) track.Position=UDim2.new(0,8,0,30)
    track.BackgroundColor3=DARK track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(0,4)

    local fill=Instance.new("Frame",track)
    fill.BackgroundColor3=RED fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,4)

    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,16,0,16) knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.BackgroundColor3=WHITE knob.BorderSizePixel=0 knob.ZIndex=3
    Instance.new("UICorner",knob).CornerRadius=UDim.new(0.5,0)
    local ks=Instance.new("UIStroke",knob) ks.Color=RED ks.Thickness=1.5

    local function setValue(v)
        v=math.clamp(math.floor(v),minV,maxV)
        local pct=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(pct,0,1,0)
        knob.Position=UDim2.new(pct,0,0.5,0)
        valLbl.Text=tostring(v)
        State[key]=v
        if cb then cb(v) end
    end
    setValue(State[key])

    -- drag bisa dimulai dari knob atau track
    local drag=false
    local function startDrag() drag=true end
    local function stopDrag()  drag=false end
    local function processDrag(inputX)
        if not drag then return end
        local ap=track.AbsolutePosition
        local as=track.AbsoluteSize
        local rx=math.clamp(inputX-ap.X,0,as.X)
        setValue(minV+(maxV-minV)*(rx/as.X))
    end

    knob.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            startDrag()
        end
    end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            startDrag()
            processDrag(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            stopDrag()
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            processDrag(i.Position.X)
        end
    end)
end

local function dropdown(label,opts,key,order,cb)
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
    df.BackgroundColor3=Color3.fromRGB(22,5,5) df.BorderSizePixel=0 df.ZIndex=10 df.Visible=false
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
    local top=Instance.new("Frame",row) top.Size=UDim2.new(1,0,0,28) top.BackgroundTransparency=1
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
    lbl2.TextSize=12 lbl2.TextColor3=WHITE lbl2.TextXAlignment=Enum.TextXAlignment.Left lbl2.Text="Teleport Toggle"
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
        for _,cc in ipairs(df2:GetChildren()) do if cc:IsA("TextButton") then cc:Destroy() end end
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
local tabs={"Main","Aim","Visual","Exploits"}
local tabBtns={} local activeTab=""

local function clearContent()
    for _,cc in ipairs(ContentFrame:GetChildren()) do
        if cc:IsA("UIListLayout") or cc:IsA("UIPadding") then continue end
        cc:Destroy()
    end
end

local function setTab(name)
    if activeTab==name then return end
    activeTab=name
    clearContent()
    for n,b in pairs(tabBtns) do
        local on=n==name
        b.TextColor3=on and WHITE or DIM
        b.BackgroundColor3=on and ROW or PANEL
        local lb=b:FindFirstChild("LB") if lb then lb:Destroy() end
        if on then
            local lb2=Instance.new("Frame",b) lb2.Name="LB"
            lb2.Size=UDim2.new(0,3,0.65,0) lb2.Position=UDim2.new(0,0,0.175,0)
            lb2.BackgroundColor3=RED lb2.BorderSizePixel=0
            Instance.new("UICorner",lb2).CornerRadius=UDim.new(0,2)
        end
    end
    if name=="Main" then
        section("MAIN SETTINGS",1)
        toggle("Enable Feature","EnableFeature",2)
        toggle("Enable Aim","EnableAim",3)
        toggle("Enable ESP","EnableEsp",4)
    elseif name=="Aim" then
        section("AIM SETTINGS",1)
        toggle("Aimbot Fire","AimbotFire",2)
        toggle("Aimbot Legit","AimbotLegit",3)
        toggle("Aim Assist","AimAssist",4)
        toggle("Aim Silent","AimSilent",5)
        toggle("Aim Visible","AimVisible",6)
        toggle("Aim Magnet (Testing)","AimMagnet",7)
        toggle("Aim Kill (Testing)","AimKill",8)
        dropdown("Aim Target",{"Body","Head","Random"},"AimTarget",9)
        slider("Aim FoV","AimFov",1,360,10)
    elseif name=="Visual" then
        section("VISUAL SETTINGS",1)
        toggle("Esp Line","EspLine",2)
        toggle("Esp Box","EspBox",3)
        toggle("Esp Hitbox 3D","EspHitbox3D",4)
        toggle("Esp Health","EspHealth",5)
        toggle("Esp Distance","EspDistance",6)
        toggle("Esp Name","EspName",7)
        toggle("Esp Skeleton","EspSkeleton",8)
    elseif name=="Exploits" then
        section("EXPLOIT SETTINGS",1)
        toggle("Speed Hack (2x)","SpeedHack",2,applySpeed)
        toggle("Jump Boost (2x)","JumpBoost",3,applyJump)
        toggle("Double Jump","DoubleJump",4,applyDoubleJump)
        teleportRow(5)
        toggle("Fly Auto Toggle","FlyAuto",6,applyFlyAuto)
        toggle("Fly to Player Toggle","FlyToPlayer",7,function(v)
            if v then task.spawn(doFlyToPlayer) end
        end)
        toggle("Fast Reload (100x)","FastReload",8,function(v)
            hookAnimSpeed("reload",v and 100 or 1)
        end)
        toggle("Speed Fire (100x)","SpeedFire",9,function(v)
            hookAnimSpeed("fire",v and 100 or 1)
        end)
    end
end

for i,name in ipairs(tabs) do
    local btn=Instance.new("TextButton",TabBar)
    btn.LayoutOrder=i btn.Size=UDim2.new(0.88,0,0,38)
    btn.BackgroundColor3=PANEL btn.Font=Enum.Font.GothamBold
    btn.TextSize=12 btn.TextColor3=DIM btn.Text=name btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    tabBtns[name]=btn
    btn.MouseButton1Click:Connect(function() setTab(name) end)
end

setTab("Main")

pcall(function()
    StarterGui:SetCore("SendNotification",{
        Title="SantaX Mods",Text="Loaded — Astra ✓",Duration=4,
    })
end)
print("[SantaX Mods] ✓ Loaded")
