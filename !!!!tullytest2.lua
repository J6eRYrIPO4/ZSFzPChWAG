--> VARIABLES <--
local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()
local RunService = game:GetService("RunService")
local camera = game:GetService("Workspace").CurrentCamera
local Players = game:GetService("Players")
local GetPlayers = Players.GetPlayers
local LocalPlayer = Players.LocalPlayer
local get_pivot = workspace.GetPivot;
local new_vector2 = Vector2.new;
local rad = math.rad;
local tan = math.tan;
local floor = math.floor;


local resume = coroutine.resume 
local create = coroutine.create

local cache = {}

local Camera = workspace.CurrentCamera

local WorldToViewportPoint = Camera.WorldToViewportPoint
local RenderStepped = RunService.RenderStepped
local UserInputService = game:GetService("UserInputService")
local GetMouseLocation = UserInputService.GetMouseLocation
local FindFirstChild = game.FindFirstChild
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local wtvp = Camera.WorldToViewportPoint;
local WorldToScreen = Camera.WorldToScreenPoint
local FindFirstChild = game.FindFirstChild

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

local config = {
    --Aimbot settings
    SilentAim = false,
    SilentAimHoldToToggle = true,
    SilentAimDisplayFOVCircle = true,
    SilentAimMethod = nil, --not used
    SilentAimRadius = 200,
    SilentAimBodyPart = "Head",
    SilentAimIsVisible = false,
    SilentAimTeamCheck = false,
    SilentAimShowTargetedPlr = true,
    SilentAimTargetedPlrColor = Color3.fromRGB(255,255,255),
    DrawRay = false,
    RayColor = Color3.fromRGB(255, 50, 255),

    SilentAimOffset = 0,

    Fov = 100,
    --ESP
    Esp = false,
    EspTeamCeck = false,
    EspDefaultColor = Color3.fromRGB(255,70,70),
    EspBoxColor = Color3.fromRGB(70,255,70),
    EspTeamColor = Color3.fromRGB(50,50,255),
    EspEnemyColor = Color3.fromRGB(255,50,50),
    EspType = "Shader",
    EspFilledShaderTransparency = 0.5,
    EspFilledShaderColor = Color3.fromRGB(255,70,70),
    --tracer
    Tracer = true,
    --misc
    Notifications = true,
    NotificationsTime = 1,

}
 



local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 200
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)
fov_circle.Visible = true



--> FUNCTIONS <--



local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    local PlayerRoot = FindFirstChild(PlayerCharacter, config.SilentAimBodyPart) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    if not PlayerRoot then return end 
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local function getPlayerClosestToMouse()
    local Closest
    local DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if config.SilentAimTeamCheck and Player.Team == LocalPlayer.Team then continue end
        local Character = Player.Character
        if not Character then continue end
        if config.SilentAimIsVisible and not IsPlayerVisible(Player) then continue end
        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end
        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end
        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or config.SilentAimRadius or 2000) then
            Closest = ((config.SilentAimBodyPart == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[config.SilentAimBodyPart])
            DistanceToMouse = Distance
        end
    end
    return Closest
end

function getshader()
    if config.Esp then
        if config.EspType == "Both" or config.EspType == "Shader" then
            return true
        end
    end
    return false
end

function getbox()
    if config.Esp then
        if config.EspType == "Both" or config.EspType == "Box" then
            return true
        end
    end
    return false
end


local function newbox(player)
    local esp = {};
    esp.box = Drawing.new("Square")
    esp.box.Color = Color3.fromRGB(255,255,255)
    esp.box.Thickness = 1
    esp.box.Filled = false

    esp.name = Drawing.new("Text", true);
    esp.name.Color = Color3.fromRGB(255,255,255)
    esp.name.Size = 14;
    esp.name.Center = true;

    esp.distance = Drawing.new("Text", true);
    esp.distance.Color = Color3.fromRGB(255,255,255)
    esp.distance.Size = 14;
    esp.distance.Center = true;

    cache[player] = esp;
end
 
local function drawshader()
    for i,v in next, GetPlayers(Players) do
        char = v.Character
        if char == nil then warn("its nil!") continue end

        if FindFirstChild(char, "Highlight") then
            if config.EspTeamCeck == true then
                if v.Team == LocalPlayer.Team then
                    FindFirstChild(char, "Highlight").OutlineColor = config.EspTeamColor
                else
                    FindFirstChild(char, "Highlight").OutlineColor = config.EspEnemyColor
                end
            else


                if config.SilentAimShowTargetedPlr == true and config.SilentAim == true then
                    local player = getPlayerClosestToMouse()
                    if player ~= nil then
                        if player.Parent == char then
                            character = player.Parent

                            if FindFirstChild(character, "Highlight") then
                                FindFirstChild(character, "Highlight").OutlineColor = config.SilentAimTargetedPlrColor
                                FindFirstChild(character, "Highlight").FillColor = config.SilentAimTargetedPlrColor
                            end
                        elseif player.Parent ~= char then
                            FindFirstChild(char, "Highlight").OutlineColor = config.EspDefaultColor
                            FindFirstChild(char, "Highlight").FillColor = config.EspFilledShaderColor
                        end
                    elseif player == nil or config.SilentAim == false then
                        FindFirstChild(char, "Highlight").OutlineColor = config.EspDefaultColor
                        FindFirstChild(char, "Highlight").FillColor = config.EspFilledShaderColor
                    end
                else

                    FindFirstChild(char, "Highlight").OutlineColor = config.EspDefaultColor
                    FindFirstChild(char, "Highlight").FillColor = config.EspFilledShaderColor
                end
            end
            FindFirstChild(char, "Highlight").Enabled = getshader()
            FindFirstChild(char, "Highlight").FillTransparency = config.EspFilledShaderTransparency

        else
            local highlight = Instance.new("Highlight")
                highlight.Parent = char
                highlight.Adornee = char
                highlight.Enabled = false
                highlight.FillTransparency = config.EspFilledShaderTransparency
                highlight.OutlineTransparency = 0
                
                highlight.OutlineColor = Color3.fromRGB(255,25,25)

        end
    end
end

local function remove_esp(player)
    for _, drawing in next, cache[player] do
        drawing:Remove();
    end

    cache[player] = nil;
end

local function drawbox()
    for i,plr in next, GetPlayers(Players) do
        if cache[plr] == nil then
            newbox(plr)
        end
    end
    for player, esp in next, cache do
        local character = player and player.Character
        if player ~= LocalPlayer and character then
            local cframe = get_pivot(character);
            local position, visible = wtvp(Camera, cframe.Position - Vector3.new(0,2,0));
            
            local scale_factor = 1 / (position.Z * tan(rad(Camera.FieldOfView * 0.5)) * 2) * 100;
            local width, height = floor(50 * scale_factor), floor(70 * scale_factor);
            local x, y = floor(position.X), floor(position.Y);
            if visible and getbox() then
                esp.box.Color = config.EspBoxColor
                esp.box.Visible = true
                esp.box.Size = new_vector2(width, height);
                esp.box.Position = new_vector2(floor(x - width * 0.5), floor(y - height * 0.5));
            else
                esp.box.Visible = false
            end
        end
    end
end

Players.PlayerRemoving:Connect(remove_esp);


--UI------------

local targettracer = Drawing.new("Line")
targettracer.ZIndex = 999
targettracer.Visible = true
targettracer.Transparency = 1
targettracer.Color = Color3.fromRGB(255, 50, 255)
targettracer.Thickness = 2
targettracer.From = Vector2.new(getMousePosition().X,getMousePosition().Y)
targettracer.To = Vector2.new()






















local repo = 'https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/'
local OrionLib = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local MainWindow = OrionLib:CreateWindow({Title = "tullyhack dev", Center = true, AutoShow = true})



local AimbotTab = MainWindow:AddTab('Aimbot')
--Tab
local SilentAimSection = AimbotTab:AddLeftGroupbox("SilentAim")

SilentAimSection:AddToggle("SilentAim",{ --Enable Silent Aim
    Text  = "SilentAim",
	Default = false,
    Tooltip = "Enable Silent Aim"
}):AddKeyPicker("SilentAimBind",{ --Silent Aim KeyBind
    Default = "F",
    SyncToggleState = false, 
    Mode = 'Toggle',
    Text = 'Silent Aim Bind', -- Text to display in the keybind menu
    NoUI = false,
})
Options.SilentAimBind:OnClick(function()
    if config.SilentAim == false then
        config.SilentAim = true
        Toggles.SilentAim:SetValue(true)
    else
        config.SilentAim = false
        Toggles.SilentAim:SetValue(false)
    end
end)

Toggles.SilentAim:OnChanged(function()
    config.SilentAim = Toggles.SilentAim.Value
end)

SilentAimSection:AddToggle("Silentaimvisible",{ --Enable Silent Aim
    Text  = "Visible Check",
	Default = false,
    Tooltip = "Check if player is behind wall"
})
Toggles.Silentaimvisible:OnChanged(function()
    config.SilentAimIsVisible = Toggles.Silentaimvisible.Value
end)

SilentAimSection:AddSlider("SilentAimOffset",{
	Text = "Silent Aim Offset",
	Min = 0,
	Max = 25,
	Default = 0,
    Rounding = 0,
    Tooltip = "Move Origin of Silent aim (potential wallbang)"
})
Options.SilentAimOffset:OnChanged(function()
    config.SilentAimOffset = Options.SilentAimOffset.Value
end)

SilentAimSection:AddToggle('HoldToUseSA',{ --Enable Hold to Use
	Text = "Hold To Use Silent Aim",
	Default = true,
    Tooltip = "Holding the keybind will turn on Silent Aim"
})
Toggles.HoldToUseSA:OnChanged(function()
    config.SilentAimHoldToToggle = Toggles.HoldToUseSA.Value
end)

SilentAimSection:AddToggle("TeamCheck",{ --Enable Silent Aim FOV Circle
    Text = "Team Check",
	Default = false,
    Tooltip = "Only targets enemies"
})
Toggles.TeamCheck:OnChanged(function()
    config.SilentAimTeamCheck = Toggles.TeamCheck.Value
end)

SilentAimSection:AddToggle("DisplayFOV",{ --Enable Silent Aim FOV Circle
    Text = "Display FOV",
	Default = false,
    Tooltip = "Show a circle that displays the silent aim radius"
}):AddColorPicker("FOVCircleColor",{
	Title = "FOV Circle Color",
	Default = Color3.fromRGB(255, 0, 0),
	--fov_circle.Color = Value
})
Options.FOVCircleColor:OnChanged(function()
    fov_circle.Color = Options.FOVCircleColor.Value
end)
Toggles.DisplayFOV:OnChanged(function()
    fov_circle.Visible = Toggles.DisplayFOV.Value
end)

SilentAimSection:AddSlider("FOVRadius",{
	Text = "FOV Radius",
	Min = 1,
	Max = 1000,
	Default = 100,
    Rounding = 0,
    Tooltip = "FOV Size"
})
local Number = Options.FOVRadius.Value
Options.FOVRadius:OnChanged(function()
    fov_circle.Radius = Options.FOVRadius.Value
    config.SilentAimRadius = Options.FOVRadius.Value
end)


--[[        if config.SilentAimHoldToToggle == true then
            
            config.SilentAim = Value
            Toggles.SilentAim:SetValue(Value)
        elseif config.SilentAimHoldToToggle == false then

            if Value == true then
                if config.SilentAim == true then
                    config.SilentAim = false
                    Toggles.SilentAim:SetValue(false)
                elseif config.SilentAim == false then
                    config.SilentAim = true
                    Toggles.SilentAim:SetValue(true)
                end
            end
            
        end]]
        OrionLib:SetWatermarkVisibility(true)

        -- Sets the watermark text
        OrionLib:SetWatermark('tullyhack dev build 10/30/22')




--Visual
local VisualTab = MainWindow:AddTab(
	"Visual")



local SilentAimVisualSection = VisualTab:AddLeftGroupbox("SilentAim Visuals")

SilentAimVisualSection:AddSlider("FOVCircleThick",{
	Text = "FOV Circle Thickness",
	Min = 1,
	Max = 10,
	Default = 1,
	Rounding = 0,
    Tooltip = "Thickness of the FOV Circle"
})
Options.FOVCircleThick:OnChanged(function()
    fov_circle.Thickness = Options.FOVCircleThick.Value
end)

SilentAimVisualSection:AddSlider("FOVCircleTransparency",{
	Text = "FOV Circle Transparency",
	Min = 0,
	Max = 1,
	Default = 1,
	Rounding = 2, 
    Tooltip = "Transparency of the FOV Circle"
})
Options.FOVCircleTransparency:OnChanged(function()
    fov_circle.Transparency = Options.FOVCircleTransparency.Value
end)

SilentAimVisualSection:AddSlider("FOVCircleSides",{
	Text = "FOV Circle Sides",
	Min = 5,
	Max = 200,
	Default = 100,
	Rounding = 0,
    Tooltip = "How many sides the FOV Circle should have"
      
})
Options.FOVCircleSides:OnChanged(function()
    fov_circle.NumSides = Options.FOVCircleSides.Value
end)

SilentAimVisualSection:AddToggle("ShowTargetPlayer",{ --Enable Silent Aim FOV Circle
    Text = "Show Targeted Player",
    Default = true,
    Tooltip = "Display The Aimbot Target"
}):AddColorPicker("TrgetPlrColor",{
	Title = "Targeted Player Color",
	Default = Color3.fromRGB(255, 255, 255),
})
Options.TrgetPlrColor:OnChanged(function()
    config.SilentAimTargetedPlrColor = Options.TrgetPlrColor.Value
end)

Toggles.ShowTargetPlayer:OnChanged(function()
    config.SilentAimShowTargetedPlr = Toggles.ShowTargetPlayer.Value
end)



--ESP-----------

local espvisualsection = VisualTab:AddRightGroupbox("ESP")

espvisualsection:AddToggle("Espon",{ 
    Text = "ESP",
    Default = false,  
    Tooltip = "Turn on ESP"
}):AddColorPicker("ESPDefaultColor",{
	Title = "ESP Shader Color",
	Default = Color3.fromRGB(255,70,70),
}):AddColorPicker("ESPBoxColor",{
	Title = "ESP Box Color",
	Default = Color3.fromRGB(255,70,70),
})
Toggles.Espon:OnChanged(function()
    config.Esp = Toggles.Espon.Value
end)
Options.ESPDefaultColor:OnChanged(function()
    config.EspDefaultColor = Options.ESPDefaultColor.Value
end)
Options.ESPBoxColor:OnChanged(function()
    config.EspBoxColor = Options.ESPBoxColor.Value
end)

espvisualsection:AddSlider("ESPInnsershadertransparency",{
	Text = "ESP Fill Shader Transparency",
	Min = 0,
	Max = 1,
	Default = 0.5,
	Rounding = 2,
    Tooltip = "Transparency of the filled shader"
      
})

espvisualsection:AddLabel('ESP Fill Shader Color'):AddColorPicker("ESPFilledshadercolor",{
	Title = "ESP Filled Shader Color",
	Default = Color3.fromRGB(255,70,70),
})
Options.ESPInnsershadertransparency:OnChanged(function()
    config.EspFilledShaderTransparency = Options.ESPInnsershadertransparency.Value
end)
Options.ESPFilledshadercolor:OnChanged(function()
    config.EspFilledShaderColor = Options.ESPFilledshadercolor.Value
end)



espvisualsection:AddToggle("EspTeamCheck",{ 
    Text = "Team Check",
    Default = false, 
    Tooltip = "Changes the color based on team"
}):AddColorPicker("Teammatecolor",{
	Title = "ESP Teammate Color",
	Default = Color3.fromRGB(50, 50, 255),
}):AddColorPicker("Enemycolor",{
	Title = "ESP Enemy Color",
	Default = Color3.fromRGB(255, 50, 50),
})


Toggles.EspTeamCheck:OnChanged(function()
    config.EspTeamCeck = Toggles.EspTeamCheck.Value
end)
Options.Teammatecolor:OnChanged(function()
    config.EspTeamColor = Options.Teammatecolor.Value
end)
Options.Enemycolor:OnChanged(function()
    config.EspEnemyColor = Options.Enemycolor.Value
end)

espvisualsection:AddDropdown("ESPType",{
	Text = "ESP Type",
	Default = 1,
	Values = {"Shader", "Box", "Both"},
})
Options.ESPType:OnChanged(function()
    config.EspType = Options.ESPType.Value
end)

local miscvisualsection = VisualTab:AddRightGroupbox("Misc")

miscvisualsection:AddToggle("Tracers",{ 
    Text = "Tracers",
    Default = true,
    Tooltip = "Draws lines to the targeted player"
}):AddColorPicker("TracerColor",{
	Title = "Tracer Color",
	Default = Color3.fromRGB(255, 50, 255),
})
Options.TracerColor:OnChanged(function()
    targettracer.Color = Options.TracerColor.Value
end)
Toggles.Tracers:OnChanged(function()
    config.Tracer = Toggles.Tracers.Value
end)

miscvisualsection:AddToggle("DrawRay",{ 
    Text = "Draw Ray",
    Default = false,
    Tooltip = "Displays the rays that are shot"
}):AddColorPicker("RayColor",{
	Title = "Ray Color",
	Default = Color3.fromRGB(255, 50, 255),
})
Options.RayColor:OnChanged(function()
    config.RayColor = Options.RayColor.Value
end)

Toggles.DrawRay:OnChanged(function()
    config.DrawRay = Toggles.DrawRay.Value
end)

miscvisualsection:AddSlider("TracerThickness",{
	Text = "Tracer Thickness",
	Min = 0,
	Max = 10,
	Default = 1,
	Rounding = 0,
    Tooltip = "Thickness of the tracer line"
})

Options.TracerThickness:OnChanged(function()
    targettracer.Thickness = Options.TracerThickness.Value
end)




--FOV=----
miscvisualsection:AddSlider("FOV",{
	Text = "FOV",
	Min = 0,
	Max = 120,
	Default = 100,
	Rounding = 0, 
})
Options.FOV:OnChanged(function()
    config.FOV = Options.FOV.Value
end)

--MISC-----------------

local misctab = MainWindow:AddTab(
	"Miscellaneous"
)

local networksection = misctab:AddLeftGroupbox("Network")


networksection:AddToggle("Lagswitch",{ --Enable Silent Aim
    Text  = "Lag Switch",
	Default = false,
    Tooltip = "Makes your ping go up"
}):AddKeyPicker("lagswitchbind",{ --Silent Aim KeyBind
    Default = "X",
    SyncToggleState = false, 
    Mode = 'Toggle',
    Text = 'Lag Switch Bind', -- Text to display in the keybind menu
    NoUI = false,
})
Options.lagswitchbind:OnClick(function()
    if Toggles.Lagswitch.Value == true then
        Toggles.Lagswitch:SetValue(false)
        settings():GetService("NetworkSettings").IncomingReplicationLag = 0
    else
        Toggles.Lagswitch:SetValue(true)
        settings():GetService("NetworkSettings").IncomingReplicationLag = 10000
    end
end)

Toggles.Lagswitch:OnChanged(function()
    if Toggles.Lagswitch.Value == true then
        settings():GetService("NetworkSettings").IncomingReplicationLag = 10000
    else
        settings():GetService("NetworkSettings").IncomingReplicationLag = 0
    end
end)





local ui = MainWindow:AddTab('UI Settings')

ThemeManager:SetLibrary(OrionLib)
ThemeManager:SetFolder('tullyhackk')
ThemeManager:ApplyToTab(ui)

SaveManager:SetLibrary(OrionLib)
SaveManager:IgnoreThemeSettings() 
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' }) 
SaveManager:SetFolder('tullyware/TULLYHACK')
SaveManager:BuildConfigSection(ui) 













--the real stuff starts here V





















local lifetime = 1 -- seconds
local material = Enum.Material.ForceField
local thickness = 0.1


function createBeam(p1, p2)
	local beam = Instance.new("Part", workspace)
	beam.Anchored = true
	beam.CanCollide = false
	beam.Material = material
	beam.Color = config.RayColor
	beam.Size = Vector3.new(thickness, thickness, (p1 - p2).magnitude)
	beam.CFrame = CFrame.new(p1, p2) * CFrame.new(0, 0, -beam.Size.Z / 2)
    print(beam.CFrame)
    print(p1)
    print(p2)
	return beam
end



--> Hooking to the remote <--
local oldNamecall
 
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    if config.SilentAim == true and self == workspace and not checkcaller() then

        if Method == "FindPartOnRayWithIgnoreList" then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                local A_Ray = Arguments[2]

                local HitPart = getPlayerClosestToMouse()
                if HitPart then
                    local Origin = A_Ray.Origin
                    Origin = Origin + Vector3.new(0,config.SilentAimOffset,0)
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    spawn(function()
                        if config.DrawRay == true then
                            local beam = createBeam(Origin, Direction)

                            for i = 1, 60 * lifetime do
                                wait()
                                beam.Transparency = i / (60 * lifetime)
                            end
                            beam:Destroy()
                        end
                    end)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "FindPartOnRayWithWhitelist" then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                local A_Ray = Arguments[2]

                local HitPart = getPlayerClosestToMouse()
                if HitPart then
                    local Origin = A_Ray.Origin
                    Origin = Origin + Vector3.new(0,config.SilentAimOffset,0)
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    spawn(function()
                        if config.DrawRay == true then
                            local beam = createBeam(Origin, Direction)

                            for i = 1, 60 * lifetime do
                                wait()
                                beam.Transparency = i / (60 * lifetime)
                            end
                            beam:Destroy()
                        end
                    end)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                local A_Ray = Arguments[2]

                local HitPart = getPlayerClosestToMouse()
                if HitPart then
                    local Origin = A_Ray.Origin
                    Origin = Origin + Vector3.new(0,config.SilentAimOffset,0)
                    A_Ray.Origin = Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    spawn(function()
                        if config.DrawRay == true then
                            local beam = createBeam(Origin, Direction)

                            for i = 1, 60 * lifetime do
                                wait()
                                beam.Transparency = i / (60 * lifetime)
                            end
                            beam:Destroy()
                        end
                    end)

                    return oldNamecall(unpack(Arguments))
                end
            end

        elseif Method == "Raycast" then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local A_Origin = Arguments[2]

                local HitPart = getPlayerClosestToMouse()
                if HitPart then
                    A_Origin = A_Origin + Vector3.new(0,config.SilentAimOffset,0)
                    Arguments[2] = A_Origin
                    Arguments[3] = getDirection(A_Origin, HitPart.Position)

                    spawn(function()
                        if config.DrawRay == true then
                            local beam = createBeam(A_Origin, HitPart.Position)

                            for i = 1, 60 * lifetime do
                                wait()
                                beam.Transparency = i / (60 * lifetime)
                            end
                            beam:Destroy()
                        end
                    end)

                    return oldNamecall(unpack(Arguments))
                end
            end
        end




    end
    return oldNamecall(...)
end))


local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and config.SilentAim == true and getClosestPlayer() then
        local HitPart = getClosestPlayer()
        local Origin = self.Origin

        Origin = Origin + Vector3.new(0,config.SilentAimOffset,0)
         
        if Index == "Target" or Index == "target" then 
            return HitPart
        elseif Index == "Hit" or Index == "hit" then 
            return HitPart.CFrame
        elseif Index == "X" or Index == "x" then 
            return self.X 
        elseif Index == "Y" or Index == "y" then 
            return self.Y 
        elseif Index == "UnitRay" then 
            return Ray.new(Origin, (self.Hit - Origin).Unit)
        end
    end

    return oldIndex(self, Index)
end))


local storage = shared.gamer_storage or {}
local old_mt = storage.old_mt or {}

old_mt.__index = old_mt.__index or _nindex
local _neindex = hookmetamethod(game, "__newindex", function(...)
    local self, index, value = ...
    if checkcaller() then 
        return old_mt.__newindex(self, index, value) 
    end

    if index == "FieldOfView" then
        return old_mt.__newindex(self, index, value * 0 + 120)
    end

    return old_mt.__newindex(self, index, value)
end)
old_mt.__newindex = old_mt.__newindex or _neindex


resume(create(function()
    RenderStepped:Connect(function()
        drawbox()

        local playr = getPlayerClosestToMouse()
        if config.Tracer == true and config.SilentAim == true and playr ~= nil then
            local pos = WorldToViewportPoint(Camera, playr.Position)
            targettracer.Visible = true
            targettracer.To = Vector2.new(pos.X, pos.Y)
            targettracer.From = Vector2.new(getMousePosition().X,getMousePosition().Y)
        else
            targettracer.Visible = false
        end

        fov_circle.Position = getMousePosition()
        
        Camera.FieldOfView = config.FOV
    end)
end))

resume(create(function()
    while true do
        wait(.05)
        drawshader()
    end
end))
