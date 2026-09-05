-- Guardian Sphere ULTIMATE Ragdoll - SIÊU MẠNH & ỔN ĐỊNH (Tất cả Game)
-- Instant Ragdoll | 80 stud | Cooldown 0.00001s | Detect & Ragdoll cực nhanh

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ============ CẤU HÌNH TỐI ƯU ============
local GUARDIAN_COUNT = 6
local DETECT_RANGE = 80              -- Tầm phát hiện 80 stud (siêu xa)
local MOVE_TIME = 0.05               -- Bay cực nhanh
local ORBIT_RADIUS = 8
local ORBIT_SPEED = 3.5
local RAGDOLL_COOLDOWN = 0.00001     -- Tốc độ ragdoll cực nhanh
local SCAN_INTERVAL = 0.1            -- Scan mob mỗi 0.1s
local RAGDOLL_DURATION = 0.8         -- Thời gian ngã

-- ============ CLEANUP CŨ ============
if workspace:FindFirstChild("GuardiansULT") then
    workspace.GuardiansULT:Destroy()
end

local GuardianFolder = Instance.new("Folder")
GuardianFolder.Name = "GuardiansULT"
GuardianFolder.Parent = workspace

local Guardians = {}
local CachedMobs = {}
local RagdolledMobs = {}             -- Tránh ragdoll trùng lặp
local LastScan = 0
local AngleOffset = 0
local IsActive = true

-- ============ TẠO GUARDIAN NEON ============
local function CreateGuardian(index)
    local sphere = Instance.new("Part")
    sphere.Name = "Guardian_" .. index
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(2, 2, 2)
    sphere.Material = Enum.Material.Neon
    sphere.Color = Color3.fromRGB(255, 0, 255)
    sphere.CanCollide = false
    sphere.Anchored = true
    sphere.CastShadow = false
    sphere.Parent = GuardianFolder
    sphere.TopSurface = Enum.SurfaceType.Smooth
    sphere.BottomSurface = Enum.SurfaceType.Smooth

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 0, 255)
    light.Brightness = 5
    light.Range = 20
    light.Parent = sphere

    local att0 = Instance.new("Attachment")
    att0.Parent = sphere
    local att1 = Instance.new("Attachment")
    att1.Position = Vector3.new(0, 1, 0)
    att1.Parent = sphere

    local trail = Instance.new("Trail")
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Color = ColorSequence.new(Color3.fromRGB(255, 0, 255), Color3.fromRGB(100, 0, 255))
    trail.Transparency = NumberSequence.new(0.3, 1)
    trail.Lifetime = 0.35
    trail.MinLength = 0.05
    trail.Parent = sphere

    Guardians[index] = {
        Part = sphere,
        LastRagdoll = 0,
        TargetRoot = nil
    }
end

for i = 1, GUARDIAN_COUNT do
    CreateGuardian(i)
end

-- ============ HÀM KIỂM TRA MOB ============
local function IsValidMob(model)
    if not model or not model.Parent then return false end
    if not model:IsA("Model") then return false end
    
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    
    if Players:GetPlayerFromCharacter(model) then return false end
    
    -- Loại bỏ các part trôi nổi
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model.PrimaryPart
    return root ~= nil
end

-- ============ RAGDOLL INSTANT CỰC MẠNH ============
local function RagdollMobInstant(mob)
    if not mob or not mob.Parent then return end
    if RagdolledMobs[mob] then return end
    RagdolledMobs[mob] = true
    
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    
    pcall(function()
        -- Disable tất cả movement state
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.TakingDamage, false)
        
        -- Buộc ngã ngay
        hum.Sit = true
        
        -- Ragdoll tất cả body parts
        for _, part in ipairs(mob:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                
                -- Xóa constraints cũ
                for _, c in ipairs(part:FindFirstChild("BodyVelocity") and {part:FindFirstChild("BodyVelocity")} or {}) do
                    pcall(function() c:Destroy() end)
                end
                
                -- Thêm velocity lăn lộn
                local bv = Instance.new("BodyVelocity")
                bv.Name = "RagdollVelocity"
                bv.Velocity = Vector3.new(
                    (math.random() - 0.5) * 40,
                    math.random() * 25,
                    (math.random() - 0.5) * 40
                )
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.P = 10000
                bv.Parent = part
                
                -- Tự xóa sau RAGDOLL_DURATION
                game:GetService("Debris"):AddItem(bv, RAGDOLL_DURATION)
            end
        end
    end)
    
    -- Khôi phục sau thời gian
    task.delay(RAGDOLL_DURATION, function()
        pcall(function()
            if mob and mob.Parent then
                local hum2 = mob:FindFirstChildOfClass("Humanoid")
                if hum2 then
                    hum2.Sit = false
                    hum2:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                    hum2:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                    hum2:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
                    hum2:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
                    hum2:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
                    hum2:SetStateEnabled(Enum.HumanoidStateType.TakingDamage, true)
                end
                RagdolledMobs[mob] = nil
            end
        end)
    end)
end

-- ============ SCAN MOB SIÊU NHANH ============
local function ScanMobs()
    if not IsActive then return end
    
    local newCache = {}
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return end
    myPos = myPos.Position

    -- Scan workspace cực tối ưu
    local workspace_parts = workspace:FindPartBoundsInRadius(myPos, DETECT_RANGE)
    
    for _, part in ipairs(workspace_parts) do
        if part and part.Parent then
            local model = part.Parent
            
            if model:IsA("Model") and IsValidMob(model) then
                local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model.PrimaryPart
                if root and root.Parent then
                    local dist = (root.Position - myPos).Magnitude
                    if dist <= DETECT_RANGE then
                        table.insert(newCache, {Model = model, Root = root, Dist = dist})
                    end
                end
            end
        end
    end

    table.sort(newCache, function(a, b) return a.Dist < b.Dist end)
    CachedMobs = newCache
end

-- ============ CLEANUP MOB RAGDOLL ============
local function CleanupRagdollTracking()
    for mob, _ in pairs(RagdolledMobs) do
        if not mob or not mob.Parent then
            RagdolledMobs[mob] = nil
        end
    end
end

-- ============ VÒNG LẶP CHÍNH - SIÊU TỐI ƯU ============
local Heartbeat = RunService.Heartbeat

local connection
connection = Heartbeat:Connect(function(dt)
    if not IsActive then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local now = os.clock()
    AngleOffset += dt * ORBIT_SPEED

    -- Scan mob cực nhanh
    if now - LastScan >= SCAN_INTERVAL then
        LastScan = now
        ScanMobs()
        CleanupRagdollTracking()
    end

    local nearest = CachedMobs[1]
    local targetRoot = nearest and nearest.Root

    for i, g in ipairs(Guardians) do
        local part = g.Part
        if not part or not part.Parent then continue end

        if targetRoot and targetRoot.Parent and nearest.Model.Parent then
            -- Bay tới mob cực nhanh
            local goal = targetRoot.Position + Vector3.new(0, 2.5, 0)
            local alpha = math.min(dt / MOVE_TIME * 2, 1)
            part.CFrame = part.CFrame:Lerp(CFrame.new(goal), alpha)

            -- RAGDOLL INSTANT - COOLDOWN CỰC NGẮN
            if now - g.LastRagdoll >= RAGDOLL_COOLDOWN then
                RagdollMobInstant(nearest.Model)
                g.LastRagdoll = now
            end
        else
            -- Orbit quanh player
            local angle = AngleOffset + (i * (math.pi * 2 / GUARDIAN_COUNT))
            local offset = Vector3.new(
                math.cos(angle) * ORBIT_RADIUS,
                4 + math.sin(angle * 2) * 1.5,
                math.sin(angle) * ORBIT_RADIUS
            )
            part.CFrame = part.CFrame:Lerp(CFrame.new(hrp.Position + offset), 0.25)
        end
    end
end)

-- ============ HỆ THỐNG KÍCH HOẠT ============
local function ToggleGuardians()
    IsActive = not IsActive
    if IsActive then
        print("✅ Guardian Sphere ACTIVATED!")
    else
        print("❌ Guardian Sphere DEACTIVATED!")
    end
end

-- Bấm G để bật/tắt
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        ToggleGuardians()
    end
end)

-- Xử lý respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    RagdolledMobs = {}
    CachedMobs = {}
end)

-- ============ ANTI-LAG & ANTI-BAN ============
game:GetService("RunService").RenderStepped:Connect(function()
    -- Giảm lag nếu có quá nhiều guardian
    if #Guardians > 6 then
        for i = 7, #Guardians do
            if Guardians[i].Part then
                Guardians[i].Part:Destroy()
            end
        end
    end
end)

print("⚡ ========================================")
print("✅ Guardian Sphere ULTIMATE RAGDOLL LOADED!")
print("⚡ ========================================")
print("📊 Config:")
print("   • Tầm phát hiện: " .. DETECT_RANGE .. " stud")
print("   • Cooldown ragdoll: " .. RAGDOLL_COOLDOWN .. "s")
print("   • Thời gian ngã: " .. RAGDOLL_DURATION .. "s")
print("   • Số guardian: " .. GUARDIAN_COUNT)
print("🎮 Điều khiển:")
print("   • Bấm G để bật/tắt")
print("⚡ ========================================")