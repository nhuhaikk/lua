-- KNOX MOD MENU V8 - ULTIMATE EDITION (FULLY WORKING)
-- Fixed: Wallhack, iPad View, Aimbot, ESP, and all features
-- Mod Menu System: KNOX Style

do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._MOD_LOADED_V8 and _G._MOD_PC_V8 == pc then return end
    _G._MOD_LOADED_V8 = true
    _G._MOD_PC_V8 = pc
end

-- ==================== INITIALIZE CONFIG ====================
_G.LexusConfig = _G.LexusConfig or {
    -- VISUAL MODS
    EnableFOV = false,
    FOVValue = 90,
    EnableNoGrass = false,
    EnableBlackSky = false,
    
    -- COMBAT MODS
    EnableMagic = false,
    MagicLevel = 70,
    EnableAutoAim = false,
    AutoAimBone = "Head",
    EnableAiming = false,
    AimingLevel = "LOW",
    EnableNoRecoil = false,
    EnableNoShake = false,
    RecoilLevel = "LESS",
    
    -- WEAPON MODS
    EnableWeaponMod = false,
    WeaponMod = {
        [101001] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101002] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101003] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101004] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101005] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101006] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101007] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101008] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101009] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false},
        [101010] = {FireSpeed = false, InstanHit = false, FastSwitch = false, FastScope = false}
    },
    
    -- NEW FEATURES
    EnableWallhack = false,
    EnableESP = false,
    EnableSkinChanger = false,
    Enable165FPS = true,
    AimbotStrength = 50,
    
    -- CHAMS COLORS
    EnableChamsGreen = false,
    EnableChamsYellow = false,
    ChamsGreenRGB = {R=0, G=255, B=0, A=255},
    ChamsYellowRGB = {R=255, G=255, B=0, A=255}
}

_G.LexusState = _G.LexusState or {}
_G._MBones = _G._MBones or {}

-- ==================== BYPASS FUNCTIONS ====================
local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end

function _G.TryBypassMD5()
    if _G.MD5Bypassed then return end
    pcall(function()
        require("client.client_entry")
        if _G.NetUtil then
            _G.NetUtil.check_dh_packet_key = function(packet_key, svr_packet_key_md5, from, dh_ext_info, bReportDSInfo)
                if type(dh_ext_info) == "table" then
                    dh_ext_info.packet_key_md5 = svr_packet_key_md5 or ""
                    dh_ext_info.svr_packet_key_md5 = svr_packet_key_md5 or ""
                end
                return true
            end
            _G.MD5Bypassed = true
        end
    end)
end

function _G.BypassCacheMD5()
    if _G.CacheMD5Bypassed then return end
    pcall(function()
        local CacheMgr = require("common.CustomAsset.CustomAssetCacheManager")
        if CacheMgr then
            CacheMgr._UpdateAssetCacheState = function(self, AssetKey, SuffixType)
                local CacheMetaInfo = self:GetCustomAssetCacheMetaInfo(AssetKey, SuffixType)
                if CacheMetaInfo then
                    CacheMetaInfo.CacheVerifyStatus = CustomAssetDefine.CustomAssetCacheVerifyStatus.Valid
                end
            end
            _G.CacheMD5Bypassed = true
        end
    end)
end

_G.BypassSecurityUtils = function()
    pcall(function()
        local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")        
        if SecurityCommonUtils then
            if SecurityCommonUtils.EStrategyTypeInReplay then
                for k, v in pairs(SecurityCommonUtils.EStrategyTypeInReplay) do
                    SecurityCommonUtils.EStrategyTypeInReplay[k] = 0
                end
            end
            SecurityCommonUtils.LogIf = function(Condition, sFormat, ...) return false end
            SecurityCommonUtils.IsFunctionCheckPass = function(FunctionOuter, sFuncName, ...) return true end
            SecurityCommonUtils.IsHealthStatusHealthy = function(nHealthStatus) return true end
            SecurityCommonUtils.IsHealthStatusAlive = function(nHealthStatus) return true end
            SecurityCommonUtils.IsTrue = function(Value) return true end            
            _G.SecurityCommonUtils = SecurityCommonUtils
        end
    end)
end

_G.BypassHiggsComponent = function()
    pcall(function()
        local HiggsComponentClass = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")        
        if HiggsComponentClass then
            local CHiggsBosonComponent = HiggsComponentClass
            if type(HiggsComponentClass) == "table" and HiggsComponentClass.__index then
                CHiggsBosonComponent = HiggsComponentClass.__index
            end
            CHiggsBosonComponent.StaticShowSecurityAlertInDev = function(uPlayerController, sMessage, bIsClientShowWindow, bSkipServer) return end
            CHiggsBosonComponent._ClientShowSecurityAlertWindow = function(sMessage) return end
            CHiggsBosonComponent._ReportChatRobot = function(sMessage, uHiggsBosonComponent) return end
            CHiggsBosonComponent._ProcessReportChatRobotQueue = function() return end
            CHiggsBosonComponent.RecordStrategyTimestampInReplay = function(nStrategyTypeInReplay, nValue, uController, nTimeInSecondsOffSet) return end
            CHiggsBosonComponent.SendAntiDataFlow = function(self) return end
            CHiggsBosonComponent.SendHitFireBtnFlow = function(self) return end
            CHiggsBosonComponent.OnBattleResult = function(self) return end
            CHiggsBosonComponent.SendHisarData = function() return end
            if CHiggsBosonComponent.ClientRPC then
                CHiggsBosonComponent.ClientRPC.RPC_Client_ShowSecurityAlertWindow = function(self, sMessage) return end
                CHiggsBosonComponent.ClientRPC.RPC_Client_ServerNameAck = function(self) return end
            end
            if CHiggsBosonComponent.ServerRPC then
                CHiggsBosonComponent.ServerRPC.RPC_Server_TellServerName = function(self, sServerName) return end
            end
        end
    end)
end

-- ==================== IPAD VIEW / FOV (FIXED) ====================
function _G.SetFOV(value)
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        
        -- Third person camera
        local camera = player.ThirdPersonCameraComponent
        if slua.isValid(camera) then
            camera:SetFieldOfView(value)
        end
        
        -- Also try first person camera if exists
        local fpCamera = player.FirstPersonCameraComponent
        if slua.isValid(fpCamera) then
            fpCamera:SetFieldOfView(value)
        end
        
        -- Execute console command as backup
        local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
        if gi then
            gi:ExecuteCMD("fov", tostring(value))
        end
    end)
end

-- ==================== WEAPON MODS ====================
_G.otherWeapon = function()
    if not _G.LexusConfig.EnableWeaponMod then return end
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        local weaponManager = player.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        local wid = shootComp.WeaponID
        if type(wid) ~= "number" then return end
        local cfg = _G.LexusConfig.WeaponMod[wid]
        if not cfg then return end
        if cfg.FireSpeed then shootComp.ShootInterval = 0.07 end
        if cfg.InstanHit then shootComp.BulletFireSpeed = 130000 end
        if cfg.FastSwitch then
            shootComp.SwitchFromIdleToBackpackTime = 0
            shootComp.SwitchFromBackpackToIdleTime = 0
        end
        if cfg.FastScope then shootComp.WeaponAimInTime = 7 end
    end)
end

-- ==================== MAGIC BULLET ====================
_G.ResetHitbox = function()
    pcall(function()
        local allChars = Game:GetAllPlayerPawns()
        if allChars then
            for _, enemy in pairs(allChars) do
                if slua.isValid(enemy) and slua.isValid(enemy.Mesh) then
                    enemy.Mesh:RecreatePhysicsState()
                    enemy.Mesh:UpdateBounds()
                end
            end
        end
        _G._MBones = {}
    end)
end

_G.Magic = function()
    if not _G.LexusConfig.EnableMagic then 
        if _G._MBones and next(_G._MBones) ~= nil then _G.ResetHitbox() end
        return 
    end
    pcall(function()
        local char = GameplayData.GetPlayerCharacter()
        if not slua.isValid(char) then return end
        local allChars = Game:GetAllPlayerPawns()
        if not allChars then return end
        _G._MBones = _G._MBones or {}
        local currentMagicScale = _G.LexusConfig.MagicLevel or 70
        for _, enemy in pairs(allChars) do
            pcall(function()
                if not slua.isValid(enemy) or enemy == char or enemy.TeamID == char.TeamID then return end
                local mesh = enemy.Mesh
                if not slua.isValid(mesh) then return end
                local physAsset = mesh.PhysicsAssetOverride
                if not slua.isValid(physAsset) and slua.isValid(mesh.SkeletalMesh) then
                    physAsset = mesh.SkeletalMesh.PhysicsAsset
                end
                if not slua.isValid(physAsset) then return end
                local assetName = tostring((physAsset.GetName and physAsset:GetName()) or physAsset)
                if _G._MBones[assetName] then return end
                local setups = physAsset.SkeletalBodySetups
                if not setups then return end
                local scaleMap = { head = currentMagicScale, neck = currentMagicScale }
                for i = 0, 60 do
                    pcall(function()
                        local bs = (type(setups.Get) == "function" and setups:Get(i)) or setups[i]
                        if not bs or not slua.isValid(bs) then return end
                        local boneName = tostring(bs.BoneName):lower()
                        local scale = nil
                        for pattern, value in pairs(scaleMap) do
                            if string.find(boneName, pattern:lower()) then scale = value; break end
                        end
                        if not scale then return end
                        local ag = bs.AggGeom
                        if not ag then return end
                        pcall(function()
                            local box = ag.BoxElems
                            if box then
                                local elem = (type(box.Get) == "function" and box:Get(0)) or box[1]
                                if elem then
                                    elem.X, elem.Y, elem.Z = scale, scale, scale
                                    if type(box.Set) == "function" then box:Set(0, elem) else box[1] = elem end
                                end
                            end
                        end)
                        pcall(function()
                            local sphyl = ag.SphylElems
                            if sphyl then
                                local elem = (type(sphyl.Get) == "function" and sphyl:Get(0)) or sphyl[1]
                                if elem then
                                    if elem.Radius then elem.Radius = scale end
                                    if elem.Length then elem.Length = scale end
                                    if type(sphyl.Set) == "function" then sphyl:Set(0, elem) else sphyl[1] = elem end
                                end
                            end
                        end)
                    end)
                end
                pcall(function()
                    mesh:RecreatePhysicsState()
                    mesh:WakeAllRigidBodies()
                    mesh:UpdateBounds()
                end)
                _G._MBones[assetName] = true
            end)
        end
    end)
end

-- ==================== AUTO AIM ====================
_G.ApplyAutoAim = function()
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local autoComp = player.AutoAimComp
    if not autoComp then return end
    if _G.LexusConfig.EnableAutoAim then
        local targetBone = _G.LexusConfig.AutoAimBone or "Head"
        autoComp.Bones = { targetBone, targetBone, targetBone }
    else
        autoComp.Bones = nil 
    end
end

-- ==================== AIMBOT (FIXED) ====================
_G.ApplyAimingConfig = function()
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        
        local weaponManager = player.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        local strength = (_G.LexusConfig.AimbotStrength or 50) / 100
        local level = _G.LexusConfig.AimingLevel or "LOW"
        
        -- Base values that multiply with strength
        local speedVal = 3.5
        local speedRateVal = 1.0
        local rangeRateVal = 1.0
        local centerSpeedVal = 0.5
        
        if level == "LOW" then
            speedVal = 5.0 * strength
            speedRateVal = 5.0 * strength
            rangeRateVal = 1.0 * strength
            centerSpeedVal = 3.0 * strength
        elseif level == "MEDIUM" then
            speedVal = 7.0 * strength
            speedRateVal = 7.0 * strength
            rangeRateVal = 2.0 * strength
            centerSpeedVal = 5.0 * strength
        elseif level == "HARD" then
            speedVal = 10.0 * strength
            speedRateVal = 10.0 * strength
            rangeRateVal = 10.0 * strength
            centerSpeedVal = 7.0 * strength
        elseif level == "EXTREME" then
            speedVal = 50.0 * strength
            speedRateVal = 20.0 * strength
            rangeRateVal = 20.0 * strength
            centerSpeedVal = 15.0 * strength
        end
        
        if not _G.LexusConfig.EnableAiming then
            speedVal = 3.5
            speedRateVal = 1.0
            rangeRateVal = 1.0
            centerSpeedVal = 0.5
        end
        
        -- Apply auto aiming config if exists
        if shootComp.AutoAimingConfig then
            local cfg = shootComp.AutoAimingConfig
            if cfg.OuterRange then
                cfg.OuterRange.Speed = speedVal
                cfg.OuterRange.SpeedRate = speedRateVal
                cfg.OuterRange.RangeRate = rangeRateVal
                cfg.OuterRange.CenterSpeedRate = centerSpeedVal
            end
            if cfg.InnerRange then
                cfg.InnerRange.Speed = speedVal
                cfg.InnerRange.SpeedRate = speedRateVal
                cfg.InnerRange.RangeRate = rangeRateVal
                cfg.InnerRange.CenterSpeedRate = centerSpeedVal
            end
        end
        
        -- Recoil reduction based on aimbot strength
        if _G.LexusConfig.EnableAiming then
            shootComp.GameDeviationFactor = 0.1 * (1 - strength * 0.8)
            shootComp.RecoilKickADS = 0.15 * (1 - strength * 0.7)
            shootComp.AccessoriesVRecoilFactor = 0.3 * (1 - strength * 0.6)
            shootComp.AccessoriesHRecoilFactor = 0.3 * (1 - strength * 0.6)
        end
    end)
end

-- ==================== NO RECOIL ====================
_G.ApplyNoRecoil = function()
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    local weaponManager = player.WeaponManagerComponent
    if not slua.isValid(weaponManager) then return end
    local currentWeapon = weaponManager.CurrentWeaponReplicated
    if not slua.isValid(currentWeapon) then return end
    local shootComp = currentWeapon.ShootWeaponEntityComp
    if not shootComp then return end

    local level = (_G.LexusConfig.EnableNoRecoil and _G.LexusConfig.RecoilLevel) or "DEFAULT"
    local r = shootComp.RecoilInfo

    if level == "DEFAULT" then
        shootComp.RecoilKickADS = 0.2
        shootComp.AccessoriesHRecoilFactor = 0.5
        shootComp.AccessoriesRecoveryFactor = 0.6
        shootComp.AccessoriesVRecoilFactor = 0.5
        if r then
            r.VerticalRecoilMin = 0; r.VerticalRecoilMax = 7; r.VerticalRecoveryMax = 5
            r.RecoilValueClimb = 0.75; r.RecoilValueFail = 2.2; r.VerticalRecoveryModifier = 0.5
            r.RecovertySpeedVertical = 9; r.VerticalRecoveryClamp = 10
            r.LeftMax = -0.8; r.RightMax = 0.8; r.HorizontalTendency = 0.1
            r.RecoilHorizontalMinScalar = 0.1; r.RecoilSpeedHorizontal = 11; r.RecoilSpeedVertical = 11
        end
    elseif level == "LESS" then
        shootComp.RecoilKickADS = 0
        shootComp.AccessoriesHRecoilFactor = 0.1
        shootComp.AccessoriesRecoveryFactor = 0.1
        shootComp.AccessoriesVRecoilFactor = 0.1
        if r then
            r.VerticalRecoilMin = 0; r.VerticalRecoilMax = 1; r.VerticalRecoveryMax = 1
            r.RecoilValueClimb = 0.1; r.RecoilValueFail = 1; r.VerticalRecoveryModifier = 0.1
            r.RecovertySpeedVertical = 1; r.VerticalRecoveryClamp = 1
            r.LeftMax = -0.1; r.RightMax = 0.1; r.HorizontalTendency = 0.05
            r.RecoilHorizontalMinScalar = 0.05; r.RecoilSpeedHorizontal = 1; r.RecoilSpeedVertical = 1
        end
    elseif level == "NO" then
        shootComp.RecoilKickADS = 0
        shootComp.AccessoriesHRecoilFactor = 0
        shootComp.AccessoriesRecoveryFactor = 0
        shootComp.AccessoriesVRecoilFactor = 0
        if r then
            r.VerticalRecoilMin = 0; r.VerticalRecoilMax = 0; r.VerticalRecoveryMax = 0
            r.RecoilValueClimb = 0; r.RecoilValueFail = 0; r.VerticalRecoveryModifier = 0
            r.RecovertySpeedVertical = 0; r.VerticalRecoveryClamp = 0
            r.LeftMax = 0; r.RightMax = 0; r.HorizontalTendency = 0
            r.RecoilHorizontalMinScalar = 0; r.RecoilSpeedHorizontal = 0; r.RecoilSpeedVertical = 0
        end
    end
    
    if _G.LexusConfig.EnableNoShake then
        shootComp.AnimationKick = 0
    end
end

-- ==================== NO GRASS ====================
_G.DisableGrass = function()
    pcall(function()
        local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
        if not gi then return end
        if _G.LexusConfig.EnableNoGrass then
            gi:ExecuteCMD("grass.DensityScale", "0")
            gi:ExecuteCMD("grass.CullDistanceScale", "0")
        else
            gi:ExecuteCMD("grass.DensityScale", "1")
            gi:ExecuteCMD("grass.CullDistanceScale", "1")
        end
    end)
end

-- ==================== BLACK SKY ====================
_G.BlackSky = function()
    pcall(function()
        local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
        if not gi then return end
        if _G.LexusConfig.EnableBlackSky then
            gi:ExecuteCMD("r.SkyAtmosphere", "0")
            gi:ExecuteCMD("r.SkyLighting", "0")
            gi:ExecuteCMD("r.Fog", "0")
            gi:ExecuteCMD("r.VolumetricFog", "0")
        else
            gi:ExecuteCMD("r.SkyAtmosphere", "1")
            gi:ExecuteCMD("r.SkyLighting", "1")
            gi:ExecuteCMD("r.Fog", "1")
            gi:ExecuteCMD("r.VolumetricFog", "1")
        end
    end)
end

-- ==================== 165 FPS ====================
_G.Enable165FPS = function()
    if not _G.LexusConfig.Enable165FPS then return end
    pcall(function()
        local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
        if gi then
            gi:ExecuteCMD("t.MaxFPS", "165")
            gi:ExecuteCMD("r.VSync", "0")
            gi:ExecuteCMD("r.FrameRateLimit", "165")
        end
    end)
end

-- ==================== WALLHACK (FIXED - PROPER WORKING) ====================
local wallhackMaterials = {}
local wallhackApplied = {}

function _G.ApplyWallhack()
    if not _G.LexusConfig.EnableWallhack then return end
    
    pcall(function()
        local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(uCon) then return end
        
        local currentPawn = uCon:GetCurPawn()
        if not slua.isValid(currentPawn) then return end
        
        local myTeamId = 0
        if currentPawn.TeamID then myTeamId = currentPawn.TeamID end
        
        local allChars = Game:GetAllPlayerPawns() or {}
        
        for _, enemy in pairs(allChars) do
            if slua.isValid(enemy) and enemy ~= currentPawn then
                local isEnemy = false
                if enemy.TeamID and enemy.TeamID ~= myTeamId then isEnemy = true end
                
                if isEnemy then
                    local meshes = {}
                    if slua.isValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
                    
                    local childComps = enemy:GetComponentsByClass(import("SkeletalMeshComponent"))
                    if childComps then
                        for i = 0, childComps:Num() - 1 do
                            local comp = childComps:Get(i)
                            if slua.isValid(comp) and comp ~= enemy.Mesh then
                                table.insert(meshes, comp)
                            end
                        end
                    end
                    
                    for _, mesh in ipairs(meshes) do
                        if slua.isValid(mesh) then
                            -- Disable depth test for wallhack effect
                            mesh:SetRenderCustomDepth(true)
                            mesh:SetCustomDepthStencilValue(1)
                            mesh.SetRenderInMainPass = true
                            mesh.bRenderInMainPass = true
                            mesh.bReceivesDecals = false
                            mesh.bCastDynamicShadow = false
                            mesh.SetCastShadow = false
                            mesh:SetCastShadow(false)
                            
                            -- Override materials
                            for i = 0, 5 do
                                local mat = mesh:GetMaterial(i)
                                if slua.isValid(mat) then
                                    local mid = mesh:CreateAndSetMaterialInstanceDynamic(i)
                                    if slua.isValid(mid) then
                                        -- Red color for enemies through walls
                                        mid:SetVectorParameterValue("Color", {R=1.0, G=0.0, B=0.0, A=1.0})
                                        mid:SetVectorParameterValue("BaseColor", {R=1.0, G=0.0, B=0.0, A=1.0})
                                        mid:SetVectorParameterValue("DiffuseColor", {R=1.0, G=0.0, B=0.0, A=1.0})
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ==================== ESP (FIXED) ====================
local cachedPawns = {}
local lastPawnRefresh = 0
local boneList = {"head", "neck_01", "spine_03", "pelvis"}

local function TextScale(distM)
    local t = math.min(distM / 400, 1)
    return 0.35 - t * 0.2
end

local function HPBar(pct)
    local n = math.floor((pct * 4) + 0.5)
    local s = ""
    for i = 1, 4 do s = s .. (i <= n and "█" or "░") end
    return s
end

local function IsPawnAlive(p)
    if not slua.isValid(p) then return false end
    local health = p.Health or 0
    return health > 0
end

local function ESPTick()
    if not _G.LexusConfig.EnableESP then return end
    
    pcall(function()
        local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(uCon) then return end
        
        local currentPawn = uCon:GetCurPawn()
        if not slua.isValid(currentPawn) then return end
        
        local myTeamId = 0
        if currentPawn.TeamID then myTeamId = currentPawn.TeamID end
        
        local myPos = currentPawn:K2_GetActorLocation()
        if not myPos then return end
        
        local myEyePos = myPos
        if currentPawn.GetHeadLocation then
            myEyePos = currentPawn:GetHeadLocation(false) or myPos
        end
        
        local HUD = uCon:GetHUD()
        if not slua.isValid(HUD) then return end
        
        local now = os.clock()
        if now - lastPawnRefresh > 1.0 then
            lastPawnRefresh = now
            cachedPawns = Game:GetAllPlayerPawns() or {}
        end
        
        for _, tPawn in pairs(cachedPawns) do
            if slua.isValid(tPawn) and tPawn ~= currentPawn then
                local isEnemy = false
                if tPawn.TeamID and tPawn.TeamID ~= myTeamId then isEnemy = true end
                
                if isEnemy and IsPawnAlive(tPawn) then
                    local enemyPos = tPawn:K2_GetActorLocation()
                    local dx = enemyPos.X - myPos.X
                    local dy = enemyPos.Y - myPos.Y
                    local dz = enemyPos.Z - myPos.Z
                    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                    
                    if dist < 300000 then
                        local name = tPawn.PlayerName or "UNKNOWN"
                        local distM = dist / 100
                        
                        local health = tPawn.Health or 100
                        local maxHealth = tPawn.HealthMax or 100
                        local hpPercent = health / maxHealth
                        
                        local hpColor = {R=0,G=255,B=0,A=255}
                        if hpPercent < 0.3 then hpColor = {R=255,G=0,B=0,A=255}
                        elseif hpPercent < 0.7 then hpColor = {R=255,G=255,B=0,A=255} end
                        
                        -- Get head position for text placement
                        local headPos = enemyPos
                        local mesh = tPawn.Mesh
                        if slua.isValid(mesh) then
                            headPos = mesh:GetSocketLocation("head")
                        end
                        
                        local textZ = headPos.Z - enemyPos.Z + 80
                        local nameZ = textZ - 25
                        
                        -- Check visibility for color
                        local isVisible = false
                        pcall(function()
                            isVisible = uCon:LineOfSightTo(tPawn)
                        end)
                        
                        local nameColor = {R=0,G=255,B=0,A=255}
                        if isVisible then
                            if _G.LexusConfig.EnableChamsGreen then
                                nameColor = _G.LexusConfig.ChamsGreenRGB
                            end
                        else
                            if _G.LexusConfig.EnableChamsYellow then
                                nameColor = _G.LexusConfig.ChamsYellowRGB
                            end
                        end
                        
                        -- Draw name
                        HUD:AddDebugText(string.format("[%.0fm] %s", distM, name), tPawn, TextScale(distM), 
                            {X=0,Y=0,Z=nameZ}, {X=0,Y=0,Z=nameZ}, nameColor, true, false, true, nil, 1.0, true)
                        
                        -- Draw health bar
                        local hpText = HPBar(hpPercent) .. " " .. math.floor(hpPercent * 100) .. "%"
                        HUD:AddDebugText(hpText, tPawn, TextScale(distM), 
                            {X=0,Y=0,Z=textZ}, {X=0,Y=0,Z=textZ}, hpColor, true, false, true, nil, 1.0, true)
                    end
                end
            end
        end
    end)
end

-- ==================== SKIN CHANGER ====================
_G.WeaponSkinMap = _G.WeaponSkinMap or {}
_G.OutfitMap = _G.OutfitMap or {}
_G.SkinLoadedCache = _G.SkinLoadedCache or {}

_G.get_skin_id = function(weaponID)
    if not weaponID or weaponID == 0 then return nil end
    return _G.WeaponSkinMap[weaponID]
end

_G.download_item = function(i)
    if not i then return end
    pcall(function()
        local PM = require("client.slua.logic.download.puffer.puffer_manager")
        local PC = require("client.slua.logic.download.puffer_const")
        if PM.GetState(PC.ENUM_DownloadType.ODPAK, {i}) ~= PC.ENUM_DownloadState.Done then
            PM.Download(PC.ENUM_DownloadType.ODPAK, {i})
        end
    end)
end

_G.ApplyWeaponSkins = function(pawn)
    if not _G.LexusConfig.EnableSkinChanger then return end
    if not slua.isValid(pawn) then return end
    pcall(function()
        local wm = pawn:GetWeaponManager()
        if not slua.isValid(wm) then return end
        for i = 1, 3 do
            local wpn = wm:GetInventoryWeaponByPropSlot(i)
            if slua.isValid(wpn) then
                local targetID = _G.get_skin_id(wpn:GetWeaponID())
                if targetID and targetID > 0 then
                    if not _G.SkinLoadedCache[targetID] then
                        pcall(_G.download_item, targetID)
                        _G.SkinLoadedCache[targetID] = true
                    end
                    if wpn.SetWeaponAvatarID then wpn:SetWeaponAvatarID(targetID) end
                end
            end
        end
    end)
end

_G.ApplyOutfitSkins = function(pawn)
    if not _G.LexusConfig.EnableSkinChanger then return end
    if not slua.isValid(pawn) then return end
    pcall(function()
        local ac = pawn:getAvatarComponent2()
        if slua.isValid(ac) and ac.NetAvatarData then
            if _G.OutfitMap.Suit and _G.OutfitMap.Suit > 0 then
                if not _G.SkinLoadedCache[_G.OutfitMap.Suit] then
                    pcall(_G.download_item, _G.OutfitMap.Suit)
                    _G.SkinLoadedCache[_G.OutfitMap.Suit] = true
                end
                ac:PutOnCustomEquipmentByID(_G.OutfitMap.Suit, {})
            end
        end
    end)
end

-- ==================== MOD MENU (KNOX STYLE) ====================
function _G.TryShowLegalCredit()  
    if _G.LegalShown then return end 
    pcall(function() 
        local Legal = require("client.slua.logic.common.logic_common_legal_msg") 
        local onRefuse = function() end 
        local onAccept = function() end 
        local content = table.concat({
            "╔════════════════════════════════════════════════════╗",
            "║        ULTIMATE KNOX MOD MENU V8                 ║",
            "║     Fully Working - All Features Fixed             ║",
            "╠════════════════════════════════════════════════════╣",
            "║                                                    ║",
            "║  DJTEAM CREW:                                      ║",
            "║  @KNOX_REALONE                                   ║",
            "║  @JECKYF                                           ║",
            "║                                                    ║",
            "╠════════════════════════════════════════════════════╣",
            "║  WORKING FEATURES:                                 ║",
            "║  ✓ Aimbot (LOW/MEDIUM/HARD/EXTREME + Strength)     ║",
            "║  ✓ Auto Aim (Head/Neck/Pelvis)                     ║",
            "║  ✓ No Recoil / No Shake                            ║",
            "║  ✓ Magic Bullet (70/120/180)                       ║",
            "║  ✓ IPAD View / FOV Changer (80-140)                ║",
            "║  ✓ No Grass / Black Sky                            ║",
            "║  ✓ Weapon Mods (FireSpeed, Instan Hit, etc.)       ║",
            "║  ✓ Wallhack (Red enemies through walls)            ║",
            "║  ✓ Wall ESP + Health Bars                          ║",
            "║  ✓ 165 FPS Unlock                                  ║",
            "║  ✓ Skin Changer                                    ║",
            "║                                                    ║",
            "╠════════════════════════════════════════════════════╣",
            "║         ENJOY & PLAY SAFE!                         ║",
            "╚════════════════════════════════════════════════════╝"
        }, "\n") 
        Legal.ShowOnePopUI({
            tabType = 999,
            title = "KNOX MOD MENU V8",
            content = content,
            tipsText = nil,
            btnOKText = "OK",
            btnCancleText = "CLOSE",
            acceptFunc = onAccept,
            refuseFunc = onRefuse
        }) 
        _G.LegalShown = true 
    end) 
end

function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then return id end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")

    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

        -- CATEGORY 1: VISUAL MODS
        local VisualStack = {
            { Key = "ModMenu_FOV_Ex", UI = AliasMap.TitleSwitcher, Text = "IPAD VIEW / FOV", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableFOV end,
              SetFunc = function(c, v) _G.LexusConfig.EnableFOV = v; if not v then _G.SetFOV(90) else _G.SetFOV(_G.LexusConfig.FOVValue) end; return true end },
            { Key = "ModMenu_FOV_Slider", UI = AliasMap.Slider, Text = "   FOV Value (80-140)", ExpandHandle = "ModMenu_FOV_Ex", MinValue = 0, MaxValue = 60,
              GetFunc = function() return (_G.LexusConfig.FOVValue or 110) - 80 end,
              SetFunc = function(c, v) local finalFOV = v + 80; _G.LexusConfig.FOVValue = finalFOV; if _G.LexusConfig.EnableFOV then _G.SetFOV(finalFOV) end; return true end },
            { Key = "ModMenu_Grass_Ex", UI = AliasMap.TitleSwitcher, Text = "NO GRASS",
              GetFunc = function() return _G.LexusConfig.EnableNoGrass end,
              SetFunc = function(c, v) _G.LexusConfig.EnableNoGrass = v; _G.DisableGrass(); return true end },
            { Key = "ModMenu_BlackSky", UI = AliasMap.TitleSwitcher, Text = "BLACK SKY",
              GetFunc = function() return _G.LexusConfig.EnableBlackSky end,
              SetFunc = function(c, v) _G.LexusConfig.EnableBlackSky = v; _G.BlackSky(); return true end },
            { Key = "ModMenu_165FPS", UI = AliasMap.TitleSwitcher, Text = "165 FPS UNLOCK",
              GetFunc = function() return _G.LexusConfig.Enable165FPS end,
              SetFunc = function(c, v) _G.LexusConfig.Enable165FPS = v; _G.Enable165FPS(); return true end },
        }

        -- CATEGORY 2: COMBAT MODS
        local CombatStack = {
            { Key = "ModMenu_AimConfig_Ex", UI = AliasMap.TitleSwitcher, Text = "AIMBOT", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableAiming end,
              SetFunc = function(c, v) _G.LexusConfig.EnableAiming = v; _G.ApplyAimingConfig(); return true end },
            { Key = "ModMenu_AimbotStrength", UI = AliasMap.Slider, Text = "   Aimbot Strength (0-100)", ExpandHandle = "ModMenu_AimConfig_Ex", MinValue = 0, MaxValue = 100,
              GetFunc = function() return _G.LexusConfig.AimbotStrength or 50 end,
              SetFunc = function(c, v) _G.LexusConfig.AimbotStrength = v; _G.ApplyAimingConfig(); return true end },
            { Key = "ModMenu_Aim_Level_Title", UI = AliasMap.Title, Text = "   SPEED LEVEL", ExpandHandle = "ModMenu_AimConfig_Ex" },
            { Key = "ModMenu_Aim_Low", UI = AliasMap.Switcher, Text = "      [ LOW ]", ExpandHandle = "ModMenu_AimConfig_Ex",
              GetFunc = function() return _G.LexusConfig.AimingLevel == "LOW" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AimingLevel = "LOW"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end; return true end },
            { Key = "ModMenu_Aim_Med", UI = AliasMap.Switcher, Text = "      [ MEDIUM ]", ExpandHandle = "ModMenu_AimConfig_Ex",
              GetFunc = function() return _G.LexusConfig.AimingLevel == "MEDIUM" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AimingLevel = "MEDIUM"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end; return true end },
            { Key = "ModMenu_Aim_Hard", UI = AliasMap.Switcher, Text = "      [ HARD ]", ExpandHandle = "ModMenu_AimConfig_Ex",
              GetFunc = function() return _G.LexusConfig.AimingLevel == "HARD" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AimingLevel = "HARD"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end; return true end },
            { Key = "ModMenu_Aim_Ext", UI = AliasMap.Switcher, Text = "      [ EXTREME ]", ExpandHandle = "ModMenu_AimConfig_Ex",
              GetFunc = function() return _G.LexusConfig.AimingLevel == "EXTREME" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AimingLevel = "EXTREME"; _G.LexusConfig.EnableAiming = true; _G.ApplyAimingConfig() end; return true end },
            { Key = "ModMenu_AutoAim_Ex", UI = AliasMap.TitleSwitcher, Text = "AUTO AIM", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableAutoAim end,
              SetFunc = function(c, v) _G.LexusConfig.EnableAutoAim = v; _G.ApplyAutoAim(); return true end },
            { Key = "ModMenu_Bones_Title", UI = AliasMap.Title, Text = "   TARGET BONES", ExpandHandle = "ModMenu_AutoAim_Ex" },
            { Key = "ModMenu_Aim_Head", UI = AliasMap.Switcher, Text = "      [ HEAD ]", ExpandHandle = "ModMenu_AutoAim_Ex",
              GetFunc = function() return _G.LexusConfig.AutoAimBone == "Head" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AutoAimBone = "Head"; _G.ApplyAutoAim() end; return true end },
            { Key = "ModMenu_Aim_Neck", UI = AliasMap.Switcher, Text = "      [ NECK ]", ExpandHandle = "ModMenu_AutoAim_Ex",
              GetFunc = function() return _G.LexusConfig.AutoAimBone == "neck_01" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AutoAimBone = "neck_01"; _G.ApplyAutoAim() end; return true end },
            { Key = "ModMenu_Aim_Pelvis", UI = AliasMap.Switcher, Text = "      [ PELVIS ]", ExpandHandle = "ModMenu_AutoAim_Ex",
              GetFunc = function() return _G.LexusConfig.AutoAimBone == "pelvis" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.AutoAimBone = "pelvis"; _G.ApplyAutoAim() end; return true end },
            { Key = "ModMenu_Magic_Ex", UI = AliasMap.TitleSwitcher, Text = "MAGIC BULLET", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableMagic end,
              SetFunc = function(c, v) _G.LexusConfig.EnableMagic = v; _G.ResetHitbox(); return true end },
            { Key = "ModMenu_Magic_Low", UI = AliasMap.Switcher, Text = "   [ LEVEL: LOW (70) ]", ExpandHandle = "ModMenu_Magic_Ex",
              GetFunc = function() return _G.LexusConfig.MagicLevel == 70 end,
              SetFunc = function(c, v) if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel = 70 end; return true end },
            { Key = "ModMenu_Magic_Med", UI = AliasMap.Switcher, Text = "   [ LEVEL: MEDIUM (120) ]", ExpandHandle = "ModMenu_Magic_Ex",
              GetFunc = function() return _G.LexusConfig.MagicLevel == 120 end,
              SetFunc = function(c, v) if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel = 120 end; return true end },
            { Key = "ModMenu_Magic_High", UI = AliasMap.Switcher, Text = "   [ LEVEL: HARD (180) ]", ExpandHandle = "ModMenu_Magic_Ex",
              GetFunc = function() return _G.LexusConfig.MagicLevel == 180 end,
              SetFunc = function(c, v) if v then _G.ResetHitbox(); _G.LexusConfig.MagicLevel = 180 end; return true end },
            { Key = "ModMenu_Recoil_Ex", UI = AliasMap.TitleSwitcher, Text = "NO RECOIL", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableNoRecoil end,
              SetFunc = function(c, v) _G.LexusConfig.EnableNoRecoil = v; _G.ApplyNoRecoil(); return true end },
            { Key = "ModMenu_NoShake", UI = AliasMap.Switcher, Text = "   [ NO SHAKE ]", ExpandHandle = "ModMenu_Recoil_Ex",
              GetFunc = function() return _G.LexusConfig.EnableNoShake end,
              SetFunc = function(c, v) _G.LexusConfig.EnableNoShake = v; _G.ApplyNoRecoil(); return true end },
            { Key = "ModMenu_Recoil_Less", UI = AliasMap.Switcher, Text = "   [ LESS RECOIL ]", ExpandHandle = "ModMenu_Recoil_Ex",
              GetFunc = function() return _G.LexusConfig.RecoilLevel == "LESS" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.RecoilLevel = "LESS"; _G.LexusConfig.EnableNoRecoil = true; _G.ApplyNoRecoil() end; return true end },
            { Key = "ModMenu_Recoil_No", UI = AliasMap.Switcher, Text = "   [ NO RECOIL ]", ExpandHandle = "ModMenu_Recoil_Ex",
              GetFunc = function() return _G.LexusConfig.RecoilLevel == "NO" end,
              SetFunc = function(c, v) if v then _G.LexusConfig.RecoilLevel = "NO"; _G.LexusConfig.EnableNoRecoil = true; _G.ApplyNoRecoil() end; return true end },
        }

        -- CATEGORY 3: ESP & WALLHACK
        local ESPStack = {
            { Key = "ModMenu_Wallhack", UI = AliasMap.TitleSwitcher, Text = "WALLHACK (Red Enemies Through Walls)",
              GetFunc = function() return _G.LexusConfig.EnableWallhack end,
              SetFunc = function(c, v) _G.LexusConfig.EnableWallhack = v; return true end },
            { Key = "ModMenu_ESP", UI = AliasMap.TitleSwitcher, Text = "WALL ESP + HEALTH BARS",
              GetFunc = function() return _G.LexusConfig.EnableESP end,
              SetFunc = function(c, v) _G.LexusConfig.EnableESP = v; return true end },
            { Key = "Title_ESP_Colors", UI = AliasMap.Title, Text = "CHAMS COLORS" },
            { Key = "ModMenu_GreenColor", UI = AliasMap.Switcher, Text = "   GREEN (Visible Enemies)",
              GetFunc = function() return _G.LexusConfig.EnableChamsGreen end,
              SetFunc = function(c, v) _G.LexusConfig.EnableChamsGreen = v; return true end },
            { Key = "ModMenu_GreenR", UI = AliasMap.Slider, Text = "      Green-R (0-255)", MinValue = 0, MaxValue = 255,
              GetFunc = function() return _G.LexusConfig.ChamsGreenRGB.R or 0 end,
              SetFunc = function(c, v) _G.LexusConfig.ChamsGreenRGB.R = v; return true end },
            { Key = "ModMenu_GreenG", UI = AliasMap.Slider, Text = "      Green-G (0-255)", MinValue = 0, MaxValue = 255,
              GetFunc = function() return _G.LexusConfig.ChamsGreenRGB.G or 255 end,
              SetFunc = function(c, v) _G.LexusConfig.ChamsGreenRGB.G = v; return true end },
            { Key = "ModMenu_GreenB", UI = AliasMap.Slider, Text = "      Green-B (0-255)", MinValue = 0, MaxValue = 255,
              GetFunc = function() return _G.LexusConfig.ChamsGreenRGB.B or 0 end,
              SetFunc = function(c, v) _G.LexusConfig.ChamsGreenRGB.B = v; return true end },
            { Key = "ModMenu_YellowColor", UI = AliasMap.Switcher, Text = "   YELLOW (Hidden Enemies)",
              GetFunc = function() return _G.LexusConfig.EnableChamsYellow end,
              SetFunc = function(c, v) _G.LexusConfig.EnableChamsYellow = v; return true end },
            { Key = "ModMenu_YellowR", UI = AliasMap.Slider, Text = "      Yellow-R (0-255)", MinValue = 0, MaxValue = 255,
              GetFunc = function() return _G.LexusConfig.ChamsYellowRGB.R or 255 end,
              SetFunc = function(c, v) _G.LexusConfig.ChamsYellowRGB.R = v; return true end },
            { Key = "ModMenu_YellowG", UI = AliasMap.Slider, Text = "      Yellow-G (0-255)", MinValue = 0, MaxValue = 255,
              GetFunc = function() return _G.LexusConfig.ChamsYellowRGB.G or 255 end,
              SetFunc = function(c, v) _G.LexusConfig.ChamsYellowRGB.G = v; return true end },
            { Key = "ModMenu_YellowB", UI = AliasMap.Slider, Text = "      Yellow-B (0-255)", MinValue = 0, MaxValue = 255,
              GetFunc = function() return _G.LexusConfig.ChamsYellowRGB.B or 0 end,
              SetFunc = function(c, v) _G.LexusConfig.ChamsYellowRGB.B = v; return true end },
        }

        -- CATEGORY 4: WEAPON MODS
        local WeaponStack = {
            { Key = "ModMenu_Weapon_Ex", UI = AliasMap.TitleSwitcher, Text = "WEAPON MODS", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableWeaponMod end,
              SetFunc = function(c, v) _G.LexusConfig.EnableWeaponMod = v; return true end },
            -- AKM
            { Key = "ModMenu_W101001_Title", UI = AliasMap.Title, Text = "AKM", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101001_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101001].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].FireSpeed = v; return true end },
            { Key = "ModMenu_W101001_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101001].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].InstanHit = v; return true end },
            { Key = "ModMenu_W101001_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101001].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].FastSwitch = v; return true end },
            { Key = "ModMenu_W101001_O", UI = AliasMap.Switcher, Text = "   FAST SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101001].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101001].FastScope = v; return true end },
            -- M416
            { Key = "ModMenu_W101004_Title", UI = AliasMap.Title, Text = "M416", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101004_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101004].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].FireSpeed = v; return true end },
            { Key = "ModMenu_W101004_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101004].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].InstanHit = v; return true end },
            { Key = "ModMenu_W101004_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101004].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].FastSwitch = v; return true end },
            { Key = "ModMenu_W101004_O", UI = AliasMap.Switcher, Text = "   FAST SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101004].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101004].FastScope = v; return true end },
            -- SCAR-L
            { Key = "ModMenu_W101003_Title", UI = AliasMap.Title, Text = "SCAR-L", ExpandHandle = "ModMenu_Weapon_Ex" },
            { Key = "ModMenu_W101003_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101003].FireSpeed end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].FireSpeed = v; return true end },
            { Key = "ModMenu_W101003_I", UI = AliasMap.Switcher, Text = "   INSTAN HIT", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101003].InstanHit end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].InstanHit = v; return true end },
            { Key = "ModMenu_W101003_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101003].FastSwitch end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].FastSwitch = v; return true end },
            { Key = "ModMenu_W101003_O", UI = AliasMap.Switcher, Text = "   FAST SCOPE", ExpandHandle = "ModMenu_Weapon_Ex", GetFunc = function() return _G.LexusConfig.WeaponMod[101003].FastScope end, SetFunc = function(c, v) _G.LexusConfig.WeaponMod[101003].FastScope = v; return true end },
        }

        -- CATEGORY 5: SKINS
        local SkinStack = {
            { Key = "ModMenu_Skin_Ex", UI = AliasMap.TitleSwitcher, Text = "SKIN CHANGER", ExpandIndex = 0,
              GetFunc = function() return _G.LexusConfig.EnableSkinChanger end,
              SetFunc = function(c, v) _G.LexusConfig.EnableSkinChanger = v; return true end },
            { Key = "ModMenu_Suit_Title", UI = AliasMap.Title, Text = "OUTFIT SKINS", ExpandHandle = "ModMenu_Skin_Ex" },
            { Key = "ModMenu_Suit", UI = AliasMap.Input, Text = "   Suit ID (Outfit)", ExpandHandle = "ModMenu_Skin_Ex", DefaultText = "Enter Suit ID",
              GetFunc = function() return tostring(_G.OutfitMap.Suit or "") end,
              SetFunc = function(c, v) local num = tonumber(v); if num then _G.OutfitMap.Suit = num end; return true end },
            { Key = "ModMenu_Weapon_Title", UI = AliasMap.Title, Text = "WEAPON SKINS", ExpandHandle = "ModMenu_Skin_Ex" },
            { Key = "ModMenu_M416_Skin", UI = AliasMap.Input, Text = "   M416 Skin ID", ExpandHandle = "ModMenu_Skin_Ex", DefaultText = "Enter Skin ID",
              GetFunc = function() return tostring(_G.WeaponSkinMap[101004] or "") end,
              SetFunc = function(c, v) local num = tonumber(v); if num then _G.WeaponSkinMap[101004] = num end; return true end },
            { Key = "ModMenu_AKM_Skin", UI = AliasMap.Input, Text = "   AKM Skin ID", ExpandHandle = "ModMenu_Skin_Ex", DefaultText = "Enter Skin ID",
              GetFunc = function() return tostring(_G.WeaponSkinMap[101001] or "") end,
              SetFunc = function(c, v) local num = tonumber(v); if num then _G.WeaponSkinMap[101001] = num end; return true end },
        }

        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            loc = "KNOX MOD MENU V8",
            UIKey = "Setting_Page_Privacy",
            Category = {
                { Key = "Cat_Visual", loc = "VISUAL MODS", Stack = VisualStack },
                { Key = "Cat_Combat", loc = "COMBAT MODS", Stack = CombatStack },
                { Key = "Cat_ESP", loc = "ESP & WALLHACK", Stack = ESPStack },
                { Key = "Cat_Weapon", loc = "WEAPON MODS", Stack = WeaponStack },
                { Key = "Cat_Skin", loc = "SKINS", Stack = SkinStack }
            }
        }

        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...)
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if type(catalog) == "table" then
                    local hasModMenu = false
                    for _, page in ipairs(catalog) do if type(page) == "table" and page.Key == "ModMenu" then hasModMenu = true; break end end
                    if not hasModMenu then table.insert(catalog, SettingPageDefine.ModMenu) end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

-- ==================== TICK FUNCTIONS ====================
local function OnTick()
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return end
    
    -- IPAD View / FOV
    if _G.LexusConfig.EnableFOV then
        _G.SetFOV(_G.LexusConfig.FOVValue)
    end
    
    -- Weapon Mods
    if _G.LexusConfig.EnableWeaponMod then
        _G.otherWeapon()
    end
    
    -- Aimbot
    if _G.LexusConfig.EnableAiming then
        _G.ApplyAimingConfig()
    end
    
    -- No Recoil
    if _G.LexusConfig.EnableNoRecoil then
        _G.ApplyNoRecoil()
    end
    
    -- Magic Bullet
    if _G.LexusConfig.EnableMagic then
        _G.Magic()
    end
    
    -- Auto Aim
    if _G.LexusConfig.EnableAutoAim then
        _G.ApplyAutoAim()
    end
    
    -- Skins
    if _G.LexusConfig.EnableSkinChanger then
        _G.ApplyWeaponSkins(player)
        _G.ApplyOutfitSkins(player)
    end
    
    -- Wallhack (runs every tick for continuous effect)
    if _G.LexusConfig.EnableWallhack then
        _G.ApplyWallhack()
    end
    
    -- No Grass / Black Sky
    _G.DisableGrass()
    _G.BlackSky()
    
    -- 165 FPS
    if _G.LexusConfig.Enable165FPS then
        _G.Enable165FPS()
    end
end

local function StartESPTimer()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) then
        if _G._ESPTimerHandle then pcall(function() pc:RemoveGameTimer(_G._ESPTimerHandle) end) end
        _G._ESPTimerHandle = pc:AddGameTimer(0.15, true, function() pcall(ESPTick) end)
    end
end

local function StartMainTimer()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) then
        if _G._MainTimerHandle then pcall(function() pc:RemoveGameTimer(_G._MainTimerHandle) end) end
        _G._MainTimerHandle = pc:AddGameTimer(0.1, true, function() pcall(OnTick) end)
        StartESPTimer()
    end
end

-- ==================== INITIALIZATION ====================
local M = {}

function M.OnBeginPlay(self)
    _G.InitModMenuTab()
    _G.TryShowLegalCredit()
    _G.TryBypassMD5()
    _G.BypassCacheMD5()
    _G.BypassSecurityUtils()
    _G.BypassHiggsComponent()
    StartMainTimer()
end

return M