-- ============================================
-- TAKORO LUA - FULL DEOBFUSCATED
-- Telegram: @Bang_Anca
-- ============================================

local class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local combine_class = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local KismetMathLibrary = import("KismetMathLibrary")
local GameplayStatics = import("GameplayStatics")

-- ============================================
-- EXPIRY SYSTEM
-- ============================================
local EXPIRY_TIMESTAMP = os.time({ year = 2026, month = 6, day = 27, hour = 0, min = 0, sec = 0 })

local function FormatTimeRemaining(sec)
    if sec <= 0 then return "EXPIRED" end
    local days = math.floor(sec / 86400); sec = sec % 86400
    local hours = math.floor(sec / 3600); sec = sec % 3600
    local minutes = math.floor(sec / 60)
    local seconds = sec % 60
    return string.format("%02dD %02dH %02dM %02dS", days, hours, minutes, seconds)
end

function CheckExpiration()
    local now = os.time()
    local remaining = EXPIRY_TIMESTAMP - now
    if remaining <= 0 then
        _G._MOD_EXPIRED = true
        return false
    end
    _G._MOD_EXPIRED = false
    _G._MOD_REMAINING_SECONDS = remaining
    return true
end

-- ============================================
-- POPUP CREDIT & AKTIVASI FITUR
-- ============================================
local function ShowCreditPopup(callback)
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        local Web = require("client.slua.logic.url.logic_webview_sdk")
        
        local content = [[
══════════════════════════════
       TAKORO MOD VIP V11
       KRAFTON SUNDALANU      
══════════════════════════════
        MOD BY: @Bang_Anca        
       EXPIRED: 2026-06-23        
══════════════════════════════
       FITUR TERSEDIA:            
      • AIMBOT (Auto Lock)        
    • LESS RECOIL / ANTI GETAR    
   • ANTI KEPALA (MODE ADS)       
   • NO SHAKE / GETAR KAMERA      
        • SMALL CROSSHAIR         
    • IPAD VIEW (LEBIH LUAS)      
       • WALLHACK (CHAMS)         
           • BLACK SKY            
      • HP BAR (PENANDA DARAH)    
     • ANTI CHEAT BYPASS          
══════════════════════════════
]]


        
        Msg.Show(4, "INFORMATION", content, 
            function() 
                if callback then callback() end 
            end, 
            nil, 
            "LANJUTKAN", "")
    end)
end

-- ============================================
-- POPUP AKTIVASI PER FITUR
-- ============================================
_G.TAKORO_Features = {
    { id = "AIMBOT",           name = "AIMBOT",               val = 0, type = "switch" },
    { id = "LESS_RECOIL",      name = "LESS RECOIL",          val = 0, type = "switch" },
    { id = "ANTI_RECOIL_ADS",  name = "ANTI ATAS KEPALA",     val = 0, type = "switch" },
    { id = "NO_SHAKE",         name = "NO SHAKE",             val = 0, type = "switch" },
    { id = "SMALL_CROSS",      name = "SMALL CROWSAIR",    val = 0, type = "switch" },
    { id = "IPAD_VIEW",        name = "IPAD VIEW",            val = 0, type = "switch" },
    { id = "WALLHACK",         name = "WALLHACK",             val = 0, type = "switch" },
    { id = "BLACK_SKY",         name = "BLACK SKY",             val = 0, type = "switch" },
    { id = "HP_BAR",           name = "HP BAR",               val = 0, type = "switch" },
}

-- Konfigurasi dasar
_G.ESPConfig = {
    NoRecoilADS = false,
    AntiShake = false,
    CrossDeviation = false
}

local featureQueue = {}
local isProcessingQueue = false

local function ShowFeatureActivationPopup(featureId, featureName, nextCallback)
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        
        local content = string.format("AKTIFKAN %s?\n\n(Yes) FOR ENABLED FEATURES, (No) FOR FISABLED FEATURES.", featureName)
        
        Msg.Show(4, "FEATURES ACTIVATION", content,
            function()
                -- Aktifkan fitur
                for _, f in ipairs(_G.TAKORO_Features) do
                    if f.id == featureId then
                        f.val = 1
                        -- Sinkronkan ke ESPConfig
                        if featureId == "ANTI_RECOIL_ADS" then _G.ESPConfig.NoRecoilADS = true end
                        if featureId == "NO_SHAKE" then _G.ESPConfig.AntiShake = true end
                        if featureId == "SMALL_CROSS" then _G.ESPConfig.CrossDeviation = true end
                        break
                    end
                end
                -- Notifikasi
                local Msg2 = require("client.slua.logic.common.logic_common_msg_box")
                if Msg2 and Msg2.Show then
                    Msg2.Show(2, "AKTIF!", string.format("%s TELAH AKTIF!", featureName), nil, nil, "OK", "")
                end
                if nextCallback then nextCallback() end
            end,
            function()
                -- Matikan fitur
                for _, f in ipairs(_G.TAKORO_Features) do
                    if f.id == featureId then
                        f.val = 0
                        if featureId == "ANTI_RECOIL_ADS" then _G.ESPConfig.NoRecoilADS = false end
                        if featureId == "NO_SHAKE" then _G.ESPConfig.AntiShake = false end
                        if featureId == "SMALL_CROSS" then _G.ESPConfig.CrossDeviation = false end
                        break
                    end
                end
                if nextCallback then nextCallback() end
            end,
            "Yes", "No"
        )
    end)
end

local function ProcessFeatureQueue()
    if isProcessingQueue then return end
    if #featureQueue == 0 then
        ShowMainMenu()
        return
    end
    
    isProcessingQueue = true
    local nextFeature = table.remove(featureQueue, 1)
    
    ShowFeatureActivationPopup(nextFeature.id, nextFeature.name, function()
        isProcessingQueue = false
        ProcessFeatureQueue()
    end)
end

local function ShowActivationSequence()
    featureQueue = {
        { id = "AIMBOT",           name = "AIMBOT" },
        { id = "LESS_RECOIL",      name = "LESS RECOIL" },
        { id = "ANTI_RECOIL_ADS",  name = "ANTI ATAS KEPALA" },
        { id = "NO_SHAKE",         name = "NO SHAKE" },
        { id = "SMALL_CROSS",      name = "SMALL CROWSAIR" },
        { id = "IPAD_VIEW",        name = "IPAD VIEW" },
        { id = "WALLHACK",         name = "WALLHACK" },
        { id = "BLACK_SKY",         name = "BLACK SKY" },
        { id = "HP_BAR",           name = "HP BAR" },
    }
    ProcessFeatureQueue()
end

-- ============================================
-- MAIN MENU (TOGGLE MANUAL)
-- ============================================
local menuIndex = 1
local isMenuActive = false

local function ShowMainMenu()
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        
        local function buildMenuContent()
            local content = "╔════════════════════════════════╗\n"
            for i, f in ipairs(_G.TAKORO_Features) do
                local arrow = (i == menuIndex) and "→ " or "  "
                local status = (f.val == 1) and "[✓]" or "[ ]"
                content = content .. string.format("║ %s %s %s %s║\n", arrow, status, f.name, string.rep(" ", 20 - #f.name))
            end
            content = content .. "╠════════════════════════════════╣\n"
            content = content .. "║  CREDIT: @Bang_Anca         ║\n"
            content = content .. "╚════════════════════════════════╝"
            return content
        end
        
        Msg.Show(4, "TAKORO LUA PAK MENU", buildMenuContent(),
            function()
                -- TOGGLE fitur
                local current = _G.TAKORO_Features[menuIndex]
                current.val = 1 - current.val
                -- Sinkronkan ke ESPConfig
                if current.id == "ANTI_RECOIL_ADS" then _G.ESPConfig.NoRecoilADS = (current.val == 1) end
                if current.id == "NO_SHAKE" then _G.ESPConfig.AntiShake = (current.val == 1) end
                if current.id == "SMALL_CROSS" then _G.ESPConfig.CrossDeviation = (current.val == 1) end
                ShowMainMenu()
            end,
            function()
                -- PILIH FITUR BERIKUTNYA
                menuIndex = menuIndex + 1
                if menuIndex > #_G.TAKORO_Features then
                    menuIndex = 1
                end
                ShowMainMenu()
            end,
            "TOGGLE", "NEXT"
        )
    end)
end

function _G.TAKORO_GetVal(featureId)
    for _, feature in ipairs(_G.TAKORO_Features) do
        if feature.id == featureId then return feature.val end
    end
    return 0
end

-- ============================================
-- EXPIRY POPUP
-- ============================================
local function ShowExpiryPopup(expired)
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        local Web = require("client.slua.logic.url.logic_webview_sdk")
        
        local function onClick()
            if Web then Web:OpenURL("https://t.me/Bang_Anca") end
        end
        
        if expired then
            local expiresAt = os.date("%d/%m/%Y %H:%M", EXPIRY_TIMESTAMP)
            Msg.Show(4, "MOD EXPIRED",
                "YOUR MOD HAS EXPIRED!\n\nExpired on: " .. expiresAt .. "\n\nContact @Bang_Anca for update", onClick)
        else
            local remaining = _G._MOD_REMAINING_SECONDS or (EXPIRY_TIMESTAMP - os.time())
            local formatted = FormatTimeRemaining(remaining)
            local expiresAt = os.date("%d/%m/%Y %H:%M", EXPIRY_TIMESTAMP)
            Msg.Show(4, "MOD ACTIVE",
                "TIME REMAINING:\n" .. formatted .. "\n\nExpires: " .. expiresAt .. "\n\nTelegram: @Bang_Anca", onClick)
        end
    end)
end

local WelcomeShown = false
function _G.TryShowWelcome()
    if WelcomeShown then return end
    if not CheckExpiration() then
        ShowExpiryPopup(true)
        return
    end
    WelcomeShown = true
    ShowCreditPopup(function()
        ShowActivationSequence()
    end)
end

-- ============================================
-- MODUL INISIALISASI
-- ============================================
local function InitializeModules()
    -- Tempat inisialisasi modul tambahan
end

-- ============================================
-- ✅ FUNGSI PISAH SESUAI PERMINTAAN
-- ============================================

-- 1. LESS RECOIL
function ApplyLessRecoil(enabled, shootComp)
    if not slua.isValid(shootComp) then return end
    if enabled then
        shootComp.AccessoriesVRecoilFactor = 0.3
        shootComp.AccessoriesHRecoilFactor = 0.3
        
        if shootComp.RecoilInfo then
            shootComp.RecoilInfo.VerticalRecoilMin = 0
            shootComp.RecoilInfo.VerticalRecoilMax = 0
            shootComp.RecoilInfo.RecoilSpeedVertical = 0
            shootComp.RecoilInfo.RecoilSpeedHorizontal = 0
            shootComp.RecoilInfo.VerticalRecoveryMax = 0
        end
    else
        shootComp.RecoilKick = 1.0
        shootComp.RecoilKickADS = 1.0
        shootComp.AnimationKick = 1.0
        shootComp.AccessoriesVRecoilFactor = 1.0
        shootComp.AccessoriesHRecoilFactor = 1.0
    end
end

-- 2. ANTI ATAS KEPALA (Hanya saat ADS)
function ApplyAntiRecoilADS(enabled, shootComp)
    if not slua.isValid(shootComp) then return end
    if enabled then
        shootComp.RecoilKick = 0
        shootComp.RecoilKickADS = 0
        shootComp.AnimationKick = 0
    end
end

-- 3. NO SHAKE / GETARAN KAMERA
function ApplyNoShake(enabled, shootComp)
    if not slua.isValid(shootComp) then return end
    if enabled then
        shootComp.AnimationKick = 0
        if shootComp.CameraShakeScale then
            shootComp.CameraShakeScale = 0
        end
    else
        shootComp.AnimationKick = 1.0
        if shootComp.CameraShakeScale then
            shootComp.CameraShakeScale = 1.0
        end
    end
end

-- 4. KECILKAN LINTASAN / TANPA PENYEBARAN
function ApplySmallCross(enabled, shootComp)
    if not slua.isValid(shootComp) then return end
    if enabled then
        shootComp.GameDeviationFactor = 0
        shootComp.GameDeviationAccuracy = 0
        shootComp.ShotGunHorizontalSpread = 0
        shootComp.ShotGunVerticalSpread = 0
    else
        shootComp.GameDeviationFactor = 1.0
        shootComp.GameDeviationAccuracy = 1.0
        shootComp.ShotGunHorizontalSpread = 1.0
        shootComp.ShotGunVerticalSpread = 1.0
    end
end

-- Fungsi utama pemanggil semua fitur recoil
function ApplyAllRecoilFeatures()
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end

        -- Jalankan masing-masing fungsi sesuai status menu
        ApplyLessRecoil(_G.TAKORO_GetVal("LESS_RECOIL") == 1, shootComp)
        ApplyAntiRecoilADS(_G.ESPConfig.NoRecoilADS, shootComp)
        ApplyNoShake(_G.ESPConfig.AntiShake, shootComp)
        ApplySmallCross(_G.ESPConfig.CrossDeviation, shootComp)
    end)
end

-- ============================================
-- AIMBOT
-- ============================================
local function ApplyHardAimbot()
    if not CheckExpiration() then return end
    if _G.TAKORO_GetVal("AIMBOT") ~= 1 then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not slua.isValid(wm) then return end
        local weapon = wm.CurrentWeaponReplicated
        if not slua.isValid(weapon) then return end
        local entity = weapon.ShootWeaponEntityComp
        if not slua.isValid(entity) then return end
     
        entity.ExtraHitPerformScale = 3
        
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = 4.6; cfg.RangeRate = 4.6; cfg.SpeedRate = 3.6
                    cfg.RangeRateSight = 4.6; cfg.SpeedRateSight = 3.6
                    cfg.CrouchRate = 3.8; cfg.ProneRate = 3.8; cfg.DyingRate = 0
                    cfg.adsorbMaxRange = 110; cfg.adsorbMinRange = 20
                    cfg.adsorbMinAttenuationDis = 110; cfg.adsorbMaxAttenuationDis = 8000
                    cfg.adsorbActiveMinRange = 20
                end
            end
        end
        
        local aimComp = char.BP_AutoAimingComponent_C or char.BP_AutoAimingComponent or char.AutoAimingComponent
        if slua.isValid(aimComp) and aimComp.Bones then
            aimComp.Bones[0] = "neck_01"; aimComp.Bones[1] = "neck_01"; aimComp.Bones[2] = "neck_01"
            pcall(function() aimComp.Bones:Set(0, "neck_01") end)
            pcall(function() aimComp.Bones:Set(1, "neck_01") end)
            pcall(function() aimComp.Bones:Set(2, "neck_01") end)
        end
    end)
end

-- ============================================
-- IPAD VIEW
-- ============================================
local TARGET_FOV = 108
local function ApplyIpadView(cameraComp)
    if _G._MOD_EXPIRED or _G.TAKORO_GetVal("IPAD_VIEW") ~= 1 or not slua.isValid(cameraComp) then return end
    if math.abs(cameraComp.FieldOfView - TARGET_FOV) > 0.5 then
        cameraComp.FieldOfView = TARGET_FOV
    end
end

-- ============================================
-- WALLHACK / CHAMS
-- ============================================

local function is_valid(obj)
    return slua and slua.isValid and slua.isValid(obj)
end

function apply_wallhack(local_player, target, controller, is_through_wall, blend_mode)
    if _G._MOD_EXPIRED then return end
    if _G.TAKORO_GetVal("WALLHACK") ~= 1 then return end
    if not is_valid(target) then return end
    
    -- Collect all mesh components
    local meshes = {}
    pcall(function()
        if is_valid(target.Mesh) then table.insert(meshes, target.Mesh) end
        
        local okSkel, SkelComp = pcall(function() return import("SkeletalMeshComponent") end)
        if okSkel and SkelComp and type(target.GetComponentsByClass) == "function" then
            local ok, comps = pcall(function() return target:GetComponentsByClass(SkelComp) end)
            if ok and comps then
                local count = (type(comps.Num) == "function" and comps:Num()) or #comps or 0
                for i = 1, count do
                    local comp = (type(comps.Get) == "function" and comps:Get(i-1)) or comps[i]
                    if is_valid(comp) and comp ~= target.Mesh then table.insert(meshes, comp) end
                end
            end
        end
        
        local okStatic, StaticComp = pcall(function() return import("StaticMeshComponent") end)
        if okStatic and StaticComp and type(target.GetComponentsByClass) == "function" then
            local ok, comps = pcall(function() return target:GetComponentsByClass(StaticComp) end)
            if ok and comps then
                local count = (type(comps.Num) == "function" and comps:Num()) or #comps or 0
                for i = 1, count do
                    local comp = (type(comps.Get) == "function" and comps:Get(i-1)) or comps[i]
                    if is_valid(comp) and comp ~= target.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    
    if #meshes == 0 then return end
    
    if is_through_wall then
        local depth_test = (blend_mode == 2)
        
        pcall(function()
            for _, mesh in ipairs(meshes) do
                if is_valid(mesh) then
                    pcall(function() mesh:SetVisibility(true, false) end)
                    pcall(function() mesh:SetHiddenInGame(false, false) end)
                    pcall(function()
                        local ok, mat = pcall(function() return mesh:GetMaterial(0) end)
                        if ok and is_valid(mat) then
                            local okb, base = pcall(function()
                                if type(mat.GetBaseMaterial) == "function" then return mat:GetBaseMaterial() end
                                return mat
                            end)
                            if okb and is_valid(base) then
                                if base.bDisableDepthTest ~= depth_test then base.bDisableDepthTest = depth_test end
                                if base.BlendMode ~= blend_mode then base.BlendMode = blend_mode end
                            end
                        end
                    end)
                end
            end
        end)
        
        pcall(function()
            for _, mesh in ipairs(meshes) do
                if is_valid(mesh) then
                    pcall(function() mesh.UseScopeDistanceCulling = false end)
                    pcall(function() mesh.PrimitiveShadingStrategy = 1 end)
                    pcall(function() mesh.ShadingRate = 6 end)
                end
            end
        end)
        
        local is_los = false
        if is_valid(controller) and type(controller.LineOfSightTo) == "function" then
            pcall(function() is_los = controller:LineOfSightTo(target) end)
        end
        
        local behind_color = { R = 300, G = 0, B = 0, A = 1, r = 300, g = 0, b = 0, a = 1 }
        local visible_color = { R = 0, G = 300, B = 0, A = 1, r = 0, g = 300, b = 0, a = 1 }
        local color = is_los and visible_color or behind_color
        local colorKey = tostring(color.R) .. "." .. tostring(color.G) .. "." .. tostring(color.B)
        local scale_offset = { R = 3, G = 3, B = 0, A = 0, r = 3, g = 3, b = 0, a = 0 }
        
        if not target.WH_MIDs then target.WH_MIDs = {} end
        if not target.WH_LastColorKey then target.WH_LastColorKey = "" end
        local color_changed = (target.WH_LastColorKey ~= colorKey) or (target.WH_LastBlendMode ~= blend_mode)
        
        local vectorParamNames = {
            "颜色", "Extra Light Color", "Para_Color", "Para_ColorTint",
            "Para_Color_1", "Tint", "Color", "BaseColor",
            "BodyColor", "MainColor", "DiffuseColor", "EmissiveColor",
            "ParaScaleOffset"
        }
        
        local scalarParamNames = {
            "Roughness", "Metallic", "Specular", "Opacity", "Glow", "Brightness"
        }
        
        for _, mesh in ipairs(meshes) do
            if not is_valid(mesh) then goto continue_mesh end
            
            local mesh_id = tostring(mesh)
            if not target.WH_MIDs[mesh_id] then target.WH_MIDs[mesh_id] = {} end
            
            local numSlots = 1
            pcall(function()
                if type(mesh.GetNumMaterials) == "function" then
                    local ok, n = pcall(function() return mesh:GetNumMaterials() end)
                    if ok and type(n) == "number" and n > 0 then numSlots = n end
                elseif type(mesh.NumMaterials) == "number" and mesh.NumMaterials > 0 then
                    numSlots = mesh.NumMaterials
                end
            end)
            
            for slot = 0, (numSlots - 1) do
                local mat = nil
                pcall(function()
                    if type(mesh.GetMaterial) == "function" then mat = mesh:GetMaterial(slot) end
                end)
                
                local mid = target.WH_MIDs[mesh_id][slot]
                local was_new_mid = false
                
                if not is_valid(mid) then
                    local okCreate, new_mid = pcall(function()
                        if type(mesh.CreateAndSetMaterialInstanceDynamic) == "function" then
                            return mesh:CreateAndSetMaterialInstanceDynamic(slot)
                        end
                        return nil
                    end)
                    if okCreate and is_valid(new_mid) then
                        target.WH_MIDs[mesh_id][slot] = new_mid
                        mid = new_mid
                        was_new_mid = true
                    end
                elseif is_valid(mat) and mat ~= mid then
                    pcall(function()
                        if type(mesh.SetMaterial) == "function" then mesh:SetMaterial(slot, mid) end
                    end)
                end
                
                if is_valid(mid) and (color_changed or was_new_mid) then
                    for _, pname in ipairs(vectorParamNames) do
                        pcall(function()
                            if type(mid.SetVectorParameterValue) == "function" then
                                mid:SetVectorParameterValue(pname, color)
                            end
                        end)
                    end
                    pcall(function()
                        if type(mid.SetVectorParameterValue) == "function" then
                            mid:SetVectorParameterValue("ParaScaleOffset", scale_offset)
                        end
                    end)
                    for _, sname in ipairs(scalarParamNames) do
                        pcall(function()
                            if type(mid.SetScalarParameterValue) == "function" then
                                mid:SetScalarParameterValue(sname, 5.0)
                            end
                        end)
                    end
                end
            end
            ::continue_mesh::
        end
        
        if color_changed then
            target.WH_LastColorKey = colorKey
            target.WH_LastBlendMode = blend_mode
        end
    else
        pcall(function()
            for _, mesh in ipairs(meshes) do
                if is_valid(mesh) then
                    pcall(function()
                        if type(mesh.GetMaterial) == "function" then
                            local mat = mesh:GetMaterial(0)
                            if mat then
                                local base = (type(mat.GetBaseMaterial) == "function") and mat:GetBaseMaterial() or mat
                                if base then
                                    if base.bDisableDepthTest ~= false then base.bDisableDepthTest = false end
                                    if base.BlendMode ~= 1 then base.BlendMode = 1 end
                                end
                            end
                        end
                    end)
                    local m_id = tostring(mesh)
                    if target.WH_MIDs and target.WH_MIDs[m_id] then target.WH_MIDs[m_id] = nil end
                end
            end
        end)
        target.WH_LastColorKey = nil
        target.WH_LastBlendMode = nil
        target.WH_MIDs = nil
    end
end

-- ============================================
-- BLACK SKY (Bisa ON / OFF)
-- ============================================
function SetBlackSky(enabled)
    InitializeModules()
    pcall(function()
        local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
        if logic_setting_graphics and logic_setting_graphics.GetGameInstance then
            local gameInstance = logic_setting_graphics.GetGameInstance()
            if gameInstance then
                if enabled then
                    -- Aktifkan Langit Hitam
                    gameInstance:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                    gameInstance:ExecuteCMD("r.SkyLightingQuality", "0")
                    gameInstance:ExecuteCMD("r.FogDensity", "0")
                    gameInstance:ExecuteCMD("r.SkyDistanceThreshold", "0")
                else
                    -- Kembalikan ke pengaturan awal
                    gameInstance:ExecuteCMD("r.CylinderMaxDrawHeight", "0")
                    gameInstance:ExecuteCMD("r.SkyLightingQuality", "3")
                    gameInstance:ExecuteCMD("r.FogDensity", "1")
                    gameInstance:ExecuteCMD("r.SkyDistanceThreshold", "1")
                end
            end
        end
    end)
end
-- ============================================
-- ANTI-CHEAT BYPASS
-- ============================================
if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end

function _G.InitializeAntiReport()
    pcall(function()
        local ClientReportPlayerSubsystem = require("GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem")
        if ClientReportPlayerSubsystem then
            ClientReportPlayerSubsystem.OnInit = function() end
            ClientReportPlayerSubsystem._OnPlayerKilledOtherPlayer = function() end
            ClientReportPlayerSubsystem._RecordFatalDamager = function() end
            ClientReportPlayerSubsystem._OnBattleResult = function() end
            ClientReportPlayerSubsystem.GetFatalDamagerMap = function() return {} end
        end
        
        local DSReportPlayerSubsystem = require("GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem")
        if DSReportPlayerSubsystem then
            DSReportPlayerSubsystem.OnInit = function() end
            DSReportPlayerSubsystem._OnCharacterDied = function() end
            DSReportPlayerSubsystem._RecordFatalDamager = function() end
        end
    end)
end

function _G.InitializeAntiCheatHooks()
    pcall(function()
        local hbc = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if hbc and hbc.StaticShowSecurityAlertInDev then
            hbc.StaticShowSecurityAlertInDev = function() end
        end
        if _G.AvatarCheckCallback then
            _G.AvatarCheckCallback.StartAvatarCheck = function() end
            _G.AvatarCheckCallback.OnReportItemID = function() end
            _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(pc)
                if slua.isValid(pc) and pc.HiggsBosonComponent then
                    pc.HiggsBosonComponent:ControlMHActive(0)
                    pc.HiggsBosonComponent.bMHActive = false
                end
            end
        end
    end)
end

function _G.InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        
        local function EF() end
        local function ETF() return {} end
        
        GC.SendTssSdkAntiDataToLobby = EF
        GC.SendDSErrorLogToLobby = EF
        GC.SendDSHawkEyePatrolLogToLobby = EF
        GC.SendSecTLog = EF
        GC.SendDataMiningTLog = EF
        GC.SendActivityTLog = EF
        GC.ReportAttackFlow = EF
        GC.ReportHurtFlow = EF
        GC.ReportFireArms = EF
        GC.ReportPlayerPosition = EF
        GC.ReportVehicleMoveFlow = EF
        GC.GetWeaponReport = ETF
        GC.IsBypassed = true
        
        local orig = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, state, ...)
            if tostring(state):lower() == "cheatdetected" then return end
            if orig then pcall(orig, UID, state, ...) end
        end
        
        GC.OnPlayerRPCValidateFailed = EF
        GC.OnPlayerActorChannelError = EF
        GC.OnShutdownAfterError = EF
    end)
end

function _G.DisableHiggsBoson()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not pc or not slua.isValid(pc) then return end
    if pc.HiggsBosonComponent then
        pc.HiggsBosonComponent.bMHActive = false
        pc.HiggsBosonComponent:ControlMHActive(0)
    end
end

function _G.InitializeConnectionGuard()
    if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then return end
    _G.ConnectionGuardInitialized = true
    local GC = _G.GameplayCallbacks
    GC.OnPlayerNetConnectionClosed = function() end
    GC.OnPlayerActorChannelError = function() end
    GC.OnPlayerRPCValidateFailed = function() end
    GC.OnPlayerSpectateException = function() end
    GC.OnShutdownAfterError = function() end
end

function _G.InitializeLogBlocker()
    pcall(function()
        local TLog = _G.TLog
        if TLog then TLog.Info=function() end; TLog.Error=function() end end
    end)
end

function _G.InitializeScannerBlocker()
    pcall(function()
        local TssSdk = _G.TssSdk
        if TssSdk then TssSdk.OnRecvData=function() end; TssSdk.SendReportInfo=function() end end
    end)
end

function _G.InitializeReplayTelemetryBlocker()
    pcall(function() end)
end

local function InitializeAllBlockers()
    pcall(function()
        _G.InitializeAntiReport()
        _G.InitializeAntiCheatHooks()
        _G.InitializeGameplayBypass()
        _G.InitializeConnectionGuard()
        _G.DisableHiggsBoson()
        _G.InitializeLogBlocker()
        _G.InitializeScannerBlocker()
        _G.InitializeReplayTelemetryBlocker()
    end)
end

-- ============================================
-- CHARACTER MODULE & LOOP UTAMA
-- ============================================
local BRPlayerCharacterBase = {}

function BRPlayerCharacterBase:ctor()
    self.bHasShownDevNotice = false
    self.TAKORO_NativeESP_Ready = false
end

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
    self:StartAdvancedSystems()
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
end

function BRPlayerCharacterBase:ReceiveEndPlay(endPlayReason)
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, endPlayReason)
    if Client and GameplayData.RemoveCharacter then
        GameplayData.RemoveCharacter(self.Object)
    end
end

function BRPlayerCharacterBase:StartAdvancedSystems()
    if not Client then return end
    if not CheckExpiration() then ShowExpiryPopup(true); return end
    
    self:AddGameTimer(1.0, true, function()
        if not slua.isValid(self.Object) then return end
        if not CheckExpiration() then ShowExpiryPopup(true); return end
        
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end
        
        -- Jalankan semua fitur aktif
        ApplyHardAimbot()
        ApplyAllRecoilFeatures() -- Ganti fungsi lama dengan yang baru
        ApplyIpadView(self.Object.ThirdPersonCameraComponent)
        SetBlackSky(_G.TAKORO_GetVal("BLACK_SKY") == 1)

        
        if self.Object == localPlayer then
            if not _G.TAKOROModTickCount then _G.TAKOROModTickCount = 0 end
            _G.TAKOROModTickCount = _G.TAKOROModTickCount + 1
            
            if not self.TAKORO_NativeESP_Ready then
                pcall(function()
                    local gameplayTools = require("GameLua.GameCore.Module.ScreenMark.ScreenMarkConfig")
                    local screenMarkConfig = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
					if screenMarkConfig and screenMarkConfig[1006] then
    					screenMarkConfig[1006].bBindBlocked = false
    					screenMarkConfig[1006].bBindOutScreen = true
    					screenMarkConfig[1006].bIgnoreObstacle = true 
    					screenMarkConfig[1006].MaxWidgetNum = 99
    					screenMarkConfig[1006].MaxShowDistance = 35000
    					screenMarkConfig[1006].BindSocketName = "head"
    					screenMarkConfig[1006].RenderPriority = 10
					end
                end)
                self.TAKORO_NativeESP_Ready = true
            end
            
            local enemies = Game:GetAllPlayerPawns() or {}
            local pc = slua_GameFrontendHUD:GetPlayerController()
            
            for _, enemy in pairs(enemies) do
                if slua.isValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                    local isDead = false
                    pcall(function()
                        if enemy.IsDead then isDead = enemy:IsDead()
                        elseif enemy.bIsDead then isDead = true end
                    end)
                    
                    if not isDead then
                        apply_wallhack(localPlayer, enemy, pc, true, 2)
                        
                        if _G.TAKORO_GetVal("HP_BAR") == 1 then
    						pcall(function()
        						if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            						if not enemy.NativeHPBarMark or not slua.isValid(enemy.NativeHPBarMark) then
                						enemy.NativeHPBarMark = InGameMarkTools.ClientAddMapMark(1006, FVector(0,0,0), 0, "", 4, enemy)
                						enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(9999, FVector(0,0,0), 0, "", 4, enemy)
                						enemy.bHasTAKORONativeHPBar = true
            						end
            						if slua.isValid(enemy.NativeHPBarMark) then
                						enemy.NativeHPBarMark:SetVisibility(true)
                						enemy.NativeHPBarMark:SetHiddenInGame(false)
                						enemy.NativeHPBarMark.bIgnoreLineOfSight = true
                						enemy.NativeHPBarMark.bAlwaysRender = true
                						enemy.NativeHPBarMark.RenderMode = 1 
                						enemy.NativeHPBarMark.MaxViewDistance = 350000 
            						end
        						end
    						end)
						end
                    end
                end
            end
        end
    end)
end

-- ============================================
-- INITIALIZATION
-- ============================================
function _G.InitializeAllSystems()
    if not CheckExpiration() then ShowExpiryPopup(true); return end
    InitializeAllBlockers()
end

pcall(function()
    require("common.time_ticker").AddTimerOnce(2, function()
        if not CheckExpiration() then ShowExpiryPopup(true); return end
        _G.TryShowWelcome()
        _G.InitializeAllSystems()
    end)
end)

-- ============================================
-- EXPORT
-- ============================================
local BRCharacterClass = class(CharacterBase, nil, BRPlayerCharacterBase)
BRPlayerCharacterBase.ServerRPC = {}
BRPlayerCharacterBase.ClientRPC = {}
BRPlayerCharacterBase.MulticastRPC = {}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = {UEnums.EPropertyClass.Object} }
BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = { Reliable = true, Params = {UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32} }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = {UEnums.EPropertyClass.Bool} }

return combine_class.DeclareFeature(BRCharacterClass, {
    { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" }
}, "BRPlayerCharacterBase")
