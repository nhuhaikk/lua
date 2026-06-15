local import_ENetRole = import("ENetRole")
local import_EPawnState = import("EPawnState")
local require_GameplayData = require("GameLua.GameCore.Data.GameplayData")
local require_InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
local require_SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")

local config = {}
config.MOD_ACTIVE = true
config.MARK_LOCATION = true
config.ESP_HEALTH_BAR = true
config.ESP_NAME_RADIUS = true
config.ESP_VEHICLE = false
config.AIMBOT = true
config.AIMBOT_LEVEL = "medium"
config.NO_RECOIL = false
config.IPAD_VIEW = true
config.IPAD_VIEW_FOV = 120
config.WHITE_BODY = true
config.WALLHACK = true
config.WALLHACK_VEHICLE = false
config.MAGIC_BULLET = false
config.MAGIC_BULLET_STRENGTH = 100
config.EXPIRE_YEAR = 2026
config.EXPIRE_MONTH = 8
config.EXPIRE_DAY = 7
config.EXPIRE_HOUR = 22
config.EXPIRE_MIN = 0
config.EXPIRE_SEC = 0

local expire_time = {}
expire_time.year = config.EXPIRE_YEAR
expire_time.month = config.EXPIRE_MONTH
expire_time.day = config.EXPIRE_DAY
expire_time.hour = config.EXPIRE_HOUR
expire_time.min = config.EXPIRE_MIN
expire_time.sec = config.EXPIRE_SEC

local expiration_timestamp = os.time(expire_time)
local is_expired_flag = false

local function check_expiration()
    if not config.MOD_ACTIVE then
        return false
    end
    local now = os.time()
    if now > expiration_timestamp then
        if not is_expired_flag then
            is_expired_flag = true
            pcall(function()
                local logic_common_msg_box = require("client.slua.logic.common.logic_common_msg_box")
                local login_module = ModuleManager and ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)

                local function handle_expiration()
                    if login_module and login_module.backLogin then
                        login_module:backLogin("expired")
                    else
                        slua.consoleCommand("quit")
                    end
                end

                local message = string.format([[Mod expired pada %d-%02d-%02d %02d:%02d:%02d
Hubungi @RA6A09 untuk perpanjang]], expire_time.year, expire_time.month, expire_time.day, expire_time.hour, expire_time.min, expire_time.sec)
                logic_common_msg_box.Show(2, "MOD EXPIRED", message, handle_expiration, handle_expiration, "OK", "OK")
            end)
        end
        return false
    end
    return true
end

_G.R6Config = _G.R6Config or {}

local function update_config()
    _G.R6Config.MarkLocation2 = config.MARK_LOCATION and 1 or 0
    _G.R6Config.EspHealthBar = config.ESP_HEALTH_BAR and 1 or 0
    _G.R6Config.Aimbot = config.AIMBOT and 1 or 0
    _G.R6Config.AimbotLevel = config.AIMBOT_LEVEL
    _G.R6Config.NoRecoil = config.NO_RECOIL and 1 or 0
    _G.R6Config.iPadView = config.IPAD_VIEW and 1 or 0
    _G.R6Config.WhiteBody = config.WHITE_BODY and 1 or 0
    _G.R6Config.EspNameRadius = config.ESP_NAME_RADIUS and 1 or 0
    _G.R6Config.iPadViewFOV = config.IPAD_VIEW_FOV
    _G.R6Config.Wallhack = config.WALLHACK and 1 or 0
    _G.R6Config.WallhackVehicle = config.WALLHACK_VEHICLE and 1 or 0
    _G.R6Config.EspVehicle = config.ESP_VEHICLE and 1 or 0
    _G.R6Config.MagicBullet = config.MAGIC_BULLET and 1 or 0
    _G.R6Config.MagicBulletStrength = config.MAGIC_BULLET_STRENGTH

    if _G.R6Config.MagicBulletStrength < 0 then
        _G.R6Config.MagicBulletStrength = 0
    end
    if _G.R6Config.MagicBulletStrength > 500 then
        _G.R6Config.MagicBulletStrength = 500
    end

    if _G.R6Config.AimbotLevel ~= "low" and _G.R6Config.AimbotLevel ~= "medium" then
        _G.R6Config.AimbotLevel = "hard"
    end

    print("[R6] Config loaded - Aimbot: " .. (_G.R6Config.Aimbot == 1 and "ON" or "OFF") ..
        " | NoRecoil: " .. (_G.R6Config.NoRecoil == 1 and "ON" or "OFF") ..
        " | Wallhack: " .. (_G.R6Config.Wallhack == 1 and "ON" or "OFF"))
end

local function try_show_welcome()
    if _G.WelcomeShown then
        return
    end

    if not check_expiration() then
        return
    end

    pcall(function()
        local logic_msg_box = require("client.slua.logic.common.logic_common_msg_box")
        local webview_sdk = require("client.slua.logic.url.logic_webview_sdk")

        local function open_telegram()
            webview_sdk.OpenURL("https://t.me/r6gamingreal")
            local ui_utils = require("GameLua.Util.UIUtils")
            ui_utils.ShowNotice("[TELE @RA6A09] ACTIVE")
        end

        local status_messages = {}
        if config.MOD_ACTIVE then
            table.insert(status_messages, "\226\156\147 MOD ACTIVE")
            if config.AIMBOT then
                table.insert(status_messages, "\226\156\147 Aimbot: " .. config.AIMBOT_LEVEL:upper())
            else
                table.insert(status_messages, "\226\156\151 Aimbot: OFF")
            end
            if config.NO_RECOIL then
                table.insert(status_messages, "\226\156\147 No Recoil: ON")
            else
                table.insert(status_messages, "\226\156\151 No Recoil: OFF")
            end
            if config.WALLHACK then
                table.insert(status_messages, "\226\156\147 Wallhack: ON")
            end
            if config.MAGIC_BULLET then
                table.insert(status_messages, "\226\156\147 Magic Bullet: " .. config.MAGIC_BULLET_STRENGTH)
            end
        else
            table.insert(status_messages, "\226\156\151 MOD DISABLED")
        end

        logic_msg_box.Show(4, "R6 GAMING FULL FEATURE",
            "WELCOME TO LUA VIP\n" ..
            "EXPIRED: " .. os.date("%Y-%m-%d %H:%M:%S", expiration_timestamp) .. "\n" ..
            "================================\n" ..
            table.concat(status_messages, "\n") .. "\n" ..
            "================================\n\n" ..
            "ADMIN @RA6A09",
            open_telegram)

        _G.WelcomeShown = true
    end)
end

_G.TryShowWelcome = try_show_welcome

local function apply_white_body()
    if not check_expiration() then
        return
    end

    if not Client then
        return
    end

    if _G.R6Config.WhiteBody == 0 then
        return
    end

    pcall(function()
        local graphics_settings = require("client.slua.logic.setting.logic_setting_graphics")
        local game_instance = graphics_settings.GetGameInstance()
        if game_instance then
            game_instance.ExecuteCMD("r.CharacterDiffuseOffset", "200")
            game_instance.ExecuteCMD("r.CharacterDiffusePower", "200")
            game_instance.ExecuteCMD("r.CharacterMinShadowFactor", "200")
        end
    end)
end

local function update_ipad_view()
    if not check_expiration() then
        return
    end

    if _G.R6Config.iPadView == 0 then
        return
    end

    pcall(function()
        local setting_config = require("client.logic.setting.setting_config")
        if setting_config then
            if setting_config.TpViewValue then
                setting_config.TpViewValue.max = 140
            end
            if setting_config.FpViewValue then
                setting_config.FpViewValue.max = 140
            end
        end

        local graphic_setting_db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if graphic_setting_db and graphic_setting_db.TpViewValue then
            graphic_setting_db.TpViewValue.max = 140
        end
    end)
end

local magic_bullet_cache = {}

local function apply_magic_bullet()
    if not check_expiration() then
        return
    end

    if _G.R6Config.MagicBullet == 0 then
        return
    end

    if not Client then
        return
    end

    local strength = _G.R6Config.MagicBulletStrength or 150
    local multiplier = 1.0 + (strength / 100.0)

    pcall(function()
        local player_character = require_GameplayData.GetPlayerCharacter()
        if not slua.isValid(player_character) then
            return
        end

        local player_team = player_character.TeamID
        local all_players = Game.GetAllPlayerPawns() or {}

        for _, pawn in pairs(all_players) do
            if slua.isValid(pawn) and pawn ~= player_character then
                local pawn_team = pawn.TeamID
                if pawn_team ~= player_team then
                    local mesh = pawn.Mesh
                    if slua.isValid(mesh) then
                        local cached_physics = magic_bullet_cache[pawn]
                        if not cached_physics then
                            local physics_asset = mesh.PhysicsAssetOverride
                            if not slua.isValid(physics_asset) then
                                if slua.isValid(mesh.SkeletalMesh) then
                                    physics_asset = mesh.SkeletalMesh.PhysicsAsset
                                end
                            end

                            if slua.isValid(physics_asset) and physics_asset.SkeletalBodySetups then
                                local target_bones = {
                                    head = true,
                                    neck_01 = true,
                                    pelvis = true,
                                    spine_01 = true,
                                    spine_02 = true,
                                    spine_03 = true,
                                    upperarm_l = true,
                                    upperarm_r = true,
                                    lowerarm_l = true,
                                    lowerarm_r = true,
                                    hand_l = true,
                                    hand_r = true,
                                    thigh_l = true,
                                    thigh_r = true,
                                    calf_l = true,
                                    calf_r = true,
                                    foot_l = true,
                                    foot_r = true
                                }

                                local body_setups = physics_asset.SkeletalBodySetups
                                for i = 1, 80 do
                                    local body_setup
                                    pcall(function()
                                        if type(body_setups.Get) == "function" then
                                            body_setup = body_setups.Get(i - 1)
                                        else
                                            body_setup = body_setups[i]
                                        end
                                    end)

                                    if not body_setup then break end
                                    if not slua.isValid(body_setup) then break end

                                    local bone_name = tostring(body_setup.BoneName):lower()
                                    local is_target = false
                                    for target_bone in pairs(target_bones) do
                                        if string.find(bone_name, target_bone) then
                                            is_target = true
                                            break
                                        end
                                    end

                                    if is_target then
                                        local geom = body_setup.AggGeom
                                        pcall(function()
                                            local boxes = geom and geom.BoxElems or body_setup.BoxElems
                                            if boxes then
                                                local box
                                                if type(boxes.Get) == "function" then
                                                    box = boxes.Get(0)
                                                else
                                                    box = boxes[1]
                                                end

                                                if box then
                                                    box.X = (box.X or 30) * multiplier
                                                    box.Y = (box.Y or 30) * multiplier
                                                    box.Z = (box.Z or 60) * multiplier

                                                    if type(boxes.Set) == "function" then
                                                        boxes.Set(0, box)
                                                    else
                                                        boxes[1] = box
                                                    end

                                                    if geom then
                                                        body_setup.AggGeom = geom
                                                    else
                                                        body_setup.BoxElems = boxes
                                                    end
                                                end
                                            end
                                        end)

                                        pcall(function()
                                            local capsules = geom and geom.SphylElems or body_setup.SphylElems
                                            if capsules then
                                                local cap
                                                if type(capsules.Get) == "function" then
                                                    cap = capsules.Get(0)
                                                else
                                                    cap = capsules[1]
                                                end

                                                if cap then
                                                    if cap.Radius then
                                                        cap.Radius = cap.Radius * multiplier
                                                    end
                                                    if cap.Length then
                                                        cap.Length = cap.Length * multiplier
                                                    end

                                                    if type(capsules.Set) == "function" then
                                                        capsules.Set(0, cap)
                                                    else
                                                        capsules[1] = cap
                                                    end

                                                    if geom then
                                                        body_setup.AggGeom = geom
                                                    else
                                                        body_setup.SphylElems = capsules
                                                    end
                                                end
                                            end
                                        end)

                                        pcall(function()
                                            local spheres = geom and geom.SphereElems or body_setup.SphereElems
                                            if spheres then
                                                local sph
                                                if type(spheres.Get) == "function" then
                                                    sph = spheres.Get(0)
                                                else
                                                    sph = spheres[1]
                                                end

                                                if sph and sph.Radius then
                                                    sph.Radius = sph.Radius * multiplier

                                                    if type(spheres.Set) == "function" then
                                                        spheres.Set(0, sph)
                                                    else
                                                        spheres[1] = sph
                                                    end

                                                    if geom then
                                                        body_setup.AggGeom = geom
                                                    else
                                                        body_setup.SphereElems = spheres
                                                    end
                                                end
                                            end
                                        end)
                                    end
                                end

                                if mesh.RecreatePhysicsState then
                                    mesh:RecreatePhysicsState()
                                end
                                magic_bullet_cache[pawn] = true
                            end
                        end
                    end
                end
            end
        end
    end)
end

local processed_vehicles = {}

function SetMaterialRender(target, disable_depth_test, blend_mode)
    pcall(function()
        if target and target.Mesh then
            local material = target.Mesh:GetMaterial(0)
            if material then
                local base_material = material:GetBaseMaterial()
                if base_material then
                    base_material.bDisableDepthTest = disable_depth_test
                    base_material.BlendMode = blend_mode
                end
            end
        end
    end)
end

_G.SetMaterialRender = SetMaterialRender

function SetVehicleMaterialRender(target, disable_depth_test, blend_mode)
    pcall(function()
        if target and target.Mesh then
            local num_materials = target.Mesh:GetNumMaterials()
            for i = 0, num_materials - 1 do
                local material = target.Mesh:GetMaterial(i)
                if material then
                    local base_material = material:GetBaseMaterial()
                    if base_material then
                        base_material.bDisableDepthTest = disable_depth_test
                        base_material.BlendMode = blend_mode
                    end
                end
            end
        end
    end)
end

_G.SetVehicleMaterialRender = SetVehicleMaterialRender

function ProcessVehicles()
    if not check_expiration() then return end

    if Client and _G.R6Config.Wallhack == 1 and _G.R6Config.WallhackVehicle ~= 0 then
        pcall(function()
            local vehicles = Game.GetAllVehicles() or {}
            for _, vehicle in pairs(vehicles) do
                if slua.isValid(vehicle) and vehicle.Mesh and not processed_vehicles[vehicle] then
                    _G.SetVehicleMaterialRender(vehicle, true, 2)
                    processed_vehicles[vehicle] = true
                end
            end
        end)
    end
end

function ProcessPlayers()
    if not check_expiration() then return end

    if Client and _G.R6Config.Wallhack == 1 then
        pcall(function()
            local player = require_GameplayData.GetPlayerCharacter()
            if not slua.isValid(player) then return end

            local player_team = player.TeamID
            local pawns = Game.GetAllPlayerPawns() or {}

            for _, pawn in pairs(pawns) do
                if slua.isValid(pawn) and pawn ~= player and pawn.TeamID ~= player_team and pawn.Mesh then
                    if pawn:IsAlive() then
                        _G.SetMaterialRender(pawn, true, 2)
                    end
                end
            end

            ProcessVehicles()
        end)
    end
end

function ResetMaterials()
    if not Client then return end

    pcall(function()
        local player = require_GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end

        local player_team = player.TeamID
        local pawns = Game.GetAllPlayerPawns() or {}

        for _, pawn in pairs(pawns) do
            if slua.isValid(pawn) and pawn ~= player and pawn.TeamID ~= player_team and pawn.Mesh then
                _G.SetMaterialRender(pawn, false, 0)
            end
        end

        local vehicles = Game.GetAllVehicles() or {}
        for _, vehicle in pairs(vehicles) do
            if slua.isValid(vehicle) and vehicle.Mesh then
                _G.SetVehicleMaterialRender(vehicle, false, 0)
                processed_vehicles[vehicle] = nil
            end
        end
    end)
end

function InitializeBypass()
    if _G.R6gamingBypassInitialized then return end

    pcall(function()
        local empty_func = function() end

        local gameplay_callbacks = _G.GameplayCallbacks or _G.GC
        if gameplay_callbacks then
            gameplay_callbacks.SendTssSdkAntiDataToLobby = empty_func
            gameplay_callbacks.SendDSErrorLogToLobby = empty_func
            gameplay_callbacks.SendDSHawkEyePatrolLogToLobby = empty_func
            gameplay_callbacks.SendSecTLog = empty_func
            gameplay_callbacks.SendDataMiningTLog = empty_func
            gameplay_callbacks.SendActivityTLog = empty_func
        end

        local subsystem_mgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystem_mgr then
            local hawk_eye_subsystem = subsystem_mgr.Get("DSHawkEyePatrolSubsystem")
            if hawk_eye_subsystem then
                hawk_eye_subsystem.MarkSuspiciousPlayer = empty_func
            end
        end

        local client_report_subsystem = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"] or require("GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem")
        if client_report_subsystem then
            client_report_subsystem.OnInit = empty_func
            client_report_subsystem._OnPlayerKilledOtherPlayer = empty_func
            client_report_subsystem._RecordFatalDamager = empty_func
            client_report_subsystem._OnBattleResult = empty_func
        end

        local ds_report_subsystem = package.loaded["GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"] or require("GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem")
        if ds_report_subsystem then
            ds_report_subsystem.OnInit = empty_func
            ds_report_subsystem._OnCharacterDied = empty_func
            ds_report_subsystem._RecordFatalDamager = empty_func
        end

        pcall(function()
            local module_path = "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"
            local higgs_boson_module = package.loaded[module_path]
            if not higgs_boson_module then
                local success, loaded_module = pcall(require, module_path)
                if success then
                    higgs_boson_module = loaded_module
                end
            end
            if higgs_boson_module then
                higgs_boson_module.ControlMHActive = empty_func
                higgs_boson_module.Tick = empty_func
                higgs_boson_module.OnTick = empty_func
                higgs_boson_module.ReceiveTick = empty_func
                higgs_boson_module.MHActiveLogic = empty_func
                higgs_boson_module.TriggerAvatarCheck = empty_func
                higgs_boson_module.StartAvatarCheck = empty_func
                higgs_boson_module.ReportItemID = empty_func
                higgs_boson_module.OnReportItemID = empty_func
                higgs_boson_module.GetNetAvatarItemIDs = function() return {} end
                higgs_boson_module.GetCurWeaponSkinID = function() return 0 end
                higgs_boson_module.ReceiveAnyDamage = empty_func
                higgs_boson_module.OnWeaponHitRecord = empty_func
                higgs_boson_module.ShowSecurityAlert = empty_func
                if higgs_boson_module.StaticShowSecurityAlertInDev then
                    higgs_boson_module.StaticShowSecurityAlertInDev = empty_func
                end
            end

            if _G.AvatarCheckCallback then
                _G.AvatarCheckCallback.StartAvatarCheck = empty_func
                _G.AvatarCheckCallback.OnReportItemID = empty_func
                _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(player_controller)
                    if slua.isValid(player_controller) and player_controller.HiggsBosonComponent then
                        pcall(function()
                            player_controller.HiggsBosonComponent:ControlMHActive(0)
                            player_controller.HiggsBosonComponent.bMHActive = false
                        end)
                    end
                end
            end

            if _G.DisableHiggsBoson then
                _G.DisableHiggsBoson = function() pcall(empty_func) end
            end
        end)

        if _G.GameplayCallbacks then
            local original_on_ds_player_state_changed = _G.GameplayCallbacks.OnDSPlayerStateChanged
            _G.GameplayCallbacks.OnDSPlayerStateChanged = function(uid, player_state, ...)
                local blocked_states = {
                    cheatdetected = true,
                    connectionlost = true,
                    connectiontimeout = true,
                    netdrivererror = true
                }
                local state_str = tostring(player_state):lower()
                if blocked_states[state_str] then
                    return
                end
                if original_on_ds_player_state_changed then
                    pcall(original_on_ds_player_state_changed, uid, player_state, ...)
                end
            end
            _G.GameplayCallbacks.OnPlayerRPCValidateFailed = empty_func
            _G.GameplayCallbacks.OnPlayerActorChannelError = empty_func
            _G.GameplayCallbacks.OnPlayerSpectateException = empty_func
            _G.GameplayCallbacks.OnShutdownAfterError = empty_func
            _G.GameplayCallbacks.OnPlayerNetConnectionClosed = empty_func
        end
    end)

    _G.R6gamingBypassInitialized = true
    print("[R6] ACTIVATE BYPASS + WALLHACK")
end

InitializeBypass()

local class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local BRPlayerCharacterBase = {}

BRPlayerCharacterBase.ServerRPC = {}
BRPlayerCharacterBase.ClientRPC = {}
BRPlayerCharacterBase.MulticastRPC = {}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
    Reliable = true,
    Params = {}
}

BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
    Reliable = true,
    Params = {UEnums.EPropertyClass.Object}
}

BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = {
    Reliable = true,
    Params = {UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32}
}

function BRPlayerCharacterBase:ctor()
    self.ActiveForceMark = nil
    self.LastMarkUpdate = 0
    self._AssistTimer = nil
    self.MainTimer = nil
    self.WallhackTimer = nil
    self.MagicBulletTimer = nil
    self._lastMarkTime = 0
end

function BRPlayerCharacterBase:_PostConstruct()
    CharacterBase._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
    self:StartMainLoop()
    self:StartWallhackLoop()
    self:StartMagicBulletLoop()
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    CharacterBase.ReceiveBeginPlay(self)
    self:SetActorTickEnabled(true)
    EventSystem.postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)

    if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
        local CheckFallingDistanceComponent = import("CheckFallingDistanceComponent")
        if slua.isValid(CheckFallingDistanceComponent) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent)) then
            Game.AddComponent(CheckFallingDistanceComponent, self, "CheckFallingDistanceComponent")
        end
    end

    if Client then
        require_GameplayData.AddCharacter(self.Object)
        update_config()
        try_show_welcome()
        apply_white_body()
        update_ipad_view()
        self:InitESP()
        ProcessPlayers()
    end
end

function BRPlayerCharacterBase:ReceiveEndPlay(reason)
    if self.ActiveForceMark then
        require_InGameMarkTools.HideMapMark(self.ActiveForceMark)
        self.ActiveForceMark = nil
    end
    if self._AssistTimer then
        self:RemoveGameTimer(self._AssistTimer)
        self._AssistTimer = nil
    end
    if self.MainTimer then
        _G.KillTimer(self.MainTimer)
        self.MainTimer = nil
    end
    if self.WallhackTimer then
        self:RemoveGameTimer(self.WallhackTimer)
        self.WallhackTimer = nil
    end
    if self.MagicBulletTimer then
        self:RemoveGameTimer(self.MagicBulletTimer)
        self.MagicBulletTimer = nil
    end
    if Client then
        require_GameplayData.RemoveCharacter(self.Object)
    end
    CharacterBase.ReceiveEndPlay(self, reason)
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
    return true
end

function BRPlayerCharacterBase:InitAddSpecialMoveInfo()
end

function BRPlayerCharacterBase:StartMagicBulletLoop()
    if not Client then return end

    if self.MagicBulletTimer then
        self:RemoveGameTimer(self.MagicBulletTimer)
    end

    self.MagicBulletTimer = self:AddGameTimer(5.0, true, function()
        if not slua.isValid(self.Object) then return end
        if check_expiration() and _G.R6Config.MagicBullet == 1 then
            apply_magic_bullet()
        end
    end)
end

function BRPlayerCharacterBase:StartWallhackLoop()
    if not Client then return end

    if self.WallhackTimer then
        self:RemoveGameTimer(self.WallhackTimer)
    end

    self.WallhackTimer = self:AddGameTimer(0.3, true, function()
        if not slua.isValid(self.Object) then return end
        if check_expiration() then
            if _G.R6Config.Wallhack == 1 then
                ProcessPlayers()
            end
        else
            ResetMaterials()
        end
    end)
end

function BRPlayerCharacterBase:UpdateESP_Mark()
    if not check_expiration() then return end
    if _G.R6Config.MarkLocation2 ~= 1 then return end

    local local_player = require_GameplayData.GetPlayerCharacter()
    if not slua.isValid(local_player) then return end

    if local_player.TeamID ~= self.TeamID then
        if self.Object.IsAlive and self.Object:IsAlive() then
            local current_time = os.clock()
            if current_time - self._lastMarkTime >= 2.0 then
                self._lastMarkTime = current_time
                local head_location = self:GetHeadLocation(false) or self:GetFuzzyPosition(FVector(0,0,0))
                if head_location then
                    if self.ActiveForceMark then
                        require_InGameMarkTools.HideMapMark(self.ActiveForceMark)
                        self.ActiveForceMark = nil
                    end
                    self.ActiveForceMark = require_InGameMarkTools.ClientAddMapMark(1003, head_location, 0, "", 4, nil)
                end
            end
        end
    else
        if self.ActiveForceMark then
            require_InGameMarkTools.HideMapMark(self.ActiveForceMark)
            self.ActiveForceMark = nil
        end
    end
end

function BRPlayerCharacterBase:DrawNameAndStatus(target, distance, hud, controller)
    if not check_expiration() then return end
    if _G.R6Config.EspNameRadius ~= 1 then return end

    if not slua.isValid(target) then return end
    if not hud or not controller then return end

    local player_name = target.PlayerName or target.PlayerNamePublic or "Enemy"
    local health = target.Health or 100
    local max_health = target.HealthMax or 100
    local is_knocked = false

    if target.HealthStatus then
        is_knocked = require_SecurityCommonUtils.IsHealthStatusAlive(target.HealthStatus)
        is_knocked = health <= 0 or max_health <= 0 or is_knocked
    end

    local status_text = ""
    local color = {R = 255, G = 255, B = 255, A = 255}

    if is_knocked then
        status_text = " [KNOCK]"
        color = {R = 255, G = 100, B = 100, A = 255}
    else
        local health_percent = math.max(0, math.min(100, (health / max_health) * 100))
        status_text = string.format(" [HP: %.0f%%]", health_percent)

        if health_percent < 30 then
            color = {R = 255, G = 50, B = 50, A = 255}
        elseif health_percent < 70 then
            color = {R = 255, G = 255, B = 50, A = 255}
        else
            color = {R = 100, G = 255, B = 100, A = 255}
        end
    end

    local display_text = player_name .. status_text
    hud:AddDebugText(display_text, target, 0.3,
        {X = 0, Y = 0, Z = 130},
        {X = 0, Y = 0, Z = 130},
        color, true, false, true, nil, 0.7, true)
end

function BRPlayerCharacterBase:VehicleESP()
    if not Client then return end
    if not check_expiration() then return end
    if _G.R6Config.EspVehicle == 0 then return end

    pcall(function()
        local player = require_GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end

        local vehicle_names = {
            BP_BRDM_C = "BRDM",
            BP_UAZ_C = "UAZ",
            BP_DPSSUV_C = "DPS SUV",
            BP_Mirado_C = "Mirado",
            BP_PonyCoupe_C = "Pony Coupe",
            BP_Rony_C = "Rony",
            BP_PickupTruck_C = "Pickup",
            BP_TukTuk_C = "Tuk Tuk",
            BP_Porter_C = "Porter",
            BP_Motorbike_C = "Motor",
            BP_Motorbike_SideCar_C = "Sidecar",
            BP_Scooter_C = "Scooter",
            BP_Buggy_C = "Buggy",
            BP_Aquarail_C = "Jetski",
            BP_PG117_C = "Boat",
            BP_Glider_C = "Glider",
            BP_MotorGlider_C = "Motor Glider",
            BP_Choppa_C = "Helicopter"
        }

        local vehicles = nil
        pcall(function()
            vehicles = Game.GetAllVehicles()
        end)

        if not vehicles then
            pcall(function()
                local vehicle_class = import("/Script/ShadowTrackerExtra.ASTExtraVehicleBase")
                vehicles = Game.GetAllActorOfClass(vehicle_class) or {}
            end)
        end

        if not vehicles then
            vehicles = {}
        end

        local player_controller = require_GameplayData.GetPlayerController()
        if not slua.isValid(player_controller) then return end

        local hud = player_controller:GetHUD()
        if not hud then return end

        local player_pos = player:K2_GetActorLocation()

        for _, vehicle in pairs(vehicles) do
            if slua.isValid(vehicle) then
                local vehicle_pos = vehicle:K2_GetActorLocation()
                local dx = vehicle_pos.X - player_pos.X
                local dy = vehicle_pos.Y - player_pos.Y
                local dz = vehicle_pos.Z - player_pos.Z
                local distance = math.sqrt(dx*dx + dy*dy + dz*dz) / 100

                if distance < 300 then
                    local vehicle_type = tostring(vehicle.__cname or "")
                    local display_name = vehicle_names[vehicle_type]

                    if not display_name then
                        display_name = vehicle_type:gsub("BP_", ""):gsub("Vehicle_", ""):gsub("_C", "")
                        if #display_name <= 1 or #display_name >= 15 then
                            display_name = "Vehicle"
                        end
                    end

                    local driver = vehicle.Driver
                    local driver_status = slua.isValid(driver) and ">" or "-"
                    local driver_color = slua.isValid(driver) and
                        {R = 255, G = 100, B = 100, A = 255} or
                        {R = 255, G = 255, B = 100, A = 255}

                    hud:AddDebugText(
                        string.format("%s %s %dm", driver_status, display_name, math.floor(distance)),
                        vehicle, 0.5,
                        {X = 0, Y = 0, Z = 100},
                        {X = 0, Y = 0, Z = 100},
                        driver_color, true, false, true, nil, 0.9, true)
                end
            end
        end
    end)
end

local function IsPlayerAlive(player)
    if not slua.isValid(player) then return false end
    if player.HealthStatus then
        return require_SecurityCommonUtils.IsHealthStatusAlive(player.HealthStatus)
    end
    if player.IsAlive then
        return player:IsAlive()
    end
    if player.GetHealth then
        local health = player:GetHealth() or 0
        return health > 0
    end
    return false
end

local function GetPlayerHealthPercent(player)
    local health = player.GetHealth and player:GetHealth() or 100
    local max_health = player.GetHealthMax and player:GetHealthMax() or 100
    return math.max(0, math.min(1, health / (max_health <= 0 and 100 or max_health)))
end

function BRPlayerCharacterBase:InitESP()
    if not Client then return end
    if not check_expiration() then return end
    if self._AssistTimer or (InitESP_CurrentPlayer and InitESP_CurrentPlayer ~= self) then return end
    InitESP_CurrentPlayer = self

    local player_list = {}
    local last_update_time = 0

    self._AssistTimer = self:AddGameTimer(0.05, true, function()
        if not slua.isValid(self.Object) then
            InitESP_CurrentPlayer = nil
            return
        end

        local player_controller = require_GameplayData.GetPlayerController()
        if not slua.isValid(player_controller) then return end

        local local_pawn = player_controller:GetCurPawn()
        if not slua.isValid(local_pawn) then return end

        local team_id = local_pawn.TeamID
        local my_location = local_pawn:K2_GetActorLocation()
        local hud = player_controller:GetHUD()
        local canvas = (slua.isValid(hud) and hud.Canvas) or nil

        local now = os.clock()
        if now - last_update_time > 1.0 then
            last_update_time = now
            player_list = Game.GetAllPlayerPawns() or {}
        end

        if check_expiration() then
            for _, other_player in pairs(player_list) do
                if slua.isValid(other_player) and other_player ~= local_pawn and other_player.TeamID ~= team_id then
                    if IsPlayerAlive(other_player) then
                        local other_pos = other_player:K2_GetActorLocation()
                        local dx = other_pos.X - my_location.X
                        local dy = other_pos.Y - my_location.Y
                        local dz = other_pos.Z - my_location.Z
                        local distance = math.sqrt(dx*dx + dy*dy + dz*dz)

                        if distance < 600000 then
                            if _G.R6Config.EspHealthBar == 1 and canvas then
                                local head_pos = other_player:GetHeadLocation(false) or (other_pos + FVector(0, 0, 85))
                                local foot_pos = other_pos - FVector(0, 0, 90)
                                local head_screen = FVector2D(0, 0)
                                local foot_screen = FVector2D(0, 0)

                                if player_controller:ProjectWorldLocationToScreen(head_pos, false, head_screen) and
                                   player_controller:ProjectWorldLocationToScreen(foot_pos, false, foot_screen) then
                                    local height = math.max(25, math.abs(head_screen.Y - foot_screen.Y))
                                    local scale = math.max(0.3, math.min(1.5, 15000 / math.max(10000, distance)))
                                    local width = 4 * scale
                                    local scaled_height = height * scale
                                    local x_pos = head_screen.X - width * 1.5
                                    local y_pos = head_screen.Y

                                    local health_percent = GetPlayerHealthPercent(other_player)
                                    local health_color
                                    if health_percent < 0.3 then
                                        health_color = FLinearColor(1, 0, 0, 0.95)
                                    elseif health_percent < 0.6 then
                                        health_color = FLinearColor(1, 1, 0, 0.95)
                                    else
                                        health_color = FLinearColor(0, 1, 0, 0.95)
                                    end

                                    canvas:K2_DrawBox(FVector2D(x_pos, y_pos), FVector2D(width, scaled_height), 1, FLinearColor(0, 0, 0, 0.55))
                                    canvas:K2_DrawBox(FVector2D(x_pos, y_pos + scaled_height * (1 - health_percent)), FVector2D(width, scaled_height * health_percent), 1, health_color)
                                end
                            end

                            if _G.R6Config.EspHealthBar == 1 and hud then
                                local distance_meters = distance / 100
                                hud:AddDebugText(
                                    string.format("%dm", math.floor(distance_meters)),
                                    other_player, 0.5,
                                    {X = 15, Y = 15, Z = -15},
                                    {X = 15, Y = 15, Z = -15},
                                    {R = 255, G = 255, B = 255, A = 255},
                                    true, false, true, nil, 0.9, true)
                            end

                            if hud and player_controller then
                                self:DrawNameAndStatus(other_player, distance, hud, player_controller)
                            end
                        end
                    end
                end
            end

            self:VehicleESP()

            for _, other_player in pairs(player_list) do
                if slua.isValid(other_player) and other_player ~= local_pawn and other_player.TeamID ~= team_id then
                    if other_player.UpdateESP_Mark then
                        other_player:UpdateESP_Mark()
                    end
                end
            end
        end
    end)
end

function BRPlayerCharacterBase:ApplyAimbotAndRecoil()
    if not check_expiration() then return end

    local weapon_manager = self.Object.WeaponManagerComponent
    if not weapon_manager then return end

    local current_weapon = weapon_manager.CurrentWeaponReplicated
    if not current_weapon then return end

    local shoot_component = current_weapon.ShootWeaponEntityComp
    if not slua.isValid(shoot_component) then return end

    if _G.R6Config.NoRecoil == 1 then
        shoot_component.RecoilKick = 0
        shoot_component.RecoilKickADS = 0
        shoot_component.AnimationKick = 0
        shoot_component.AccessoriesVRecoilFactor = 0.35
        shoot_component.AccessoriesHRecoilFactor = 0.25
        shoot_component.GameDeviationFactor = 0.1
        if shoot_component.RecoilInfo then
            shoot_component.RecoilInfo.VerticalRecoilMin = 0.2
            shoot_component.RecoilInfo.VerticalRecoilMax = 0.3
            shoot_component.RecoilInfo.RecoilSpeedVertical = 0.2
            shoot_component.RecoilInfo.RecoilSpeedHorizontal = 0.2
            shoot_component.RecoilInfo.VerticalRecoveryMax = 0.2
        end
        shoot_component.RecoilModifierStand = 0.3
        shoot_component.RecoilModifierCrouch = 0.2
        shoot_component.RecoilModifierProne = 0.15
    end

    if _G.R6Config.Aimbot ~= 1 then return end
    local aim_config = shoot_component.AutoAimingConfig
    if not aim_config then return end

    local aim_level = _G.R6Config.AimbotLevel or "hard"

    local function set_range_params(range_table, speed, range_rate, speed_rate, range_rate_sight, speed_rate_sight, crouch_rate, prone_rate, dying_rate)
        for _, range_name in ipairs({"OuterRange", "InnerRange"}) do
            local range = shoot_component.AutoAimingConfig[range_name]
            if range then
                range.Speed = speed
                range.RangeRate = range_rate
                range.SpeedRate = speed_rate
                range.RangeRateSight = range_rate_sight
                range.SpeedRateSight = speed_rate_sight
                range.CrouchRate = crouch_rate
                range.ProneRate = prone_rate
                range.DyingRate = dying_rate
            end
        end
    end

    if aim_level == "low" then
        set_range_params(aim_config, 1.8, 1.6, 1.6, 1.6, 1.6, 1.6, 1.6, 0)
        if aim_config then
            aim_config.OuterRange.Speed = 1.5
            aim_config.InnerRange.Speed = 1.5
            aim_config.OuterRange.SpeedRate = 1.5
            aim_config.InnerRange.SpeedRate = 1.5
            aim_config.OuterRange.CenterSpeedRate = 1.5
            aim_config.InnerRange.CenterSpeedRate = 1.5
            aim_config.OuterRange.RangeRate = 1.2
            aim_config.InnerRange.RangeRate = 1.2
            aim_config.OuterRange.RangeRateSight = 1.2
            aim_config.InnerRange.RangeRateSight = 1.2
            aim_config.OuterRange.SpeedRateSight = 1.2
            aim_config.InnerRange.SpeedRateSight = 1.2
            aim_config.OuterRange.CrouchRate = 1.2
            aim_config.InnerRange.CrouchRate = 1.2
            aim_config.OuterRange.ProneRate = 1.2
            aim_config.InnerRange.ProneRate = 1.2
            aim_config.OuterRange.DyingRate = 0.5
            aim_config.InnerRange.DyingRate = 0.5
            shoot_component.WeaponAimInTime = 2.0
            shoot_component.GameDeviationFactor = 0.15
            shoot_component.GameDeviationAccuracy = 0.15
        end
    elseif aim_level == "medium" then
        set_range_params(aim_config, 2.5, 2, 2, 2, 2, 2, 2, 0.2)
        if aim_config then
            aim_config.OuterRange.Speed = 2.5
            aim_config.InnerRange.Speed = 2.5
            aim_config.OuterRange.SpeedRate = 2.5
            aim_config.InnerRange.SpeedRate = 2.5
            aim_config.OuterRange.CenterSpeedRate = 2.5
            aim_config.InnerRange.CenterSpeedRate = 2.5
            aim_config.OuterRange.RangeRate = 2
            aim_config.InnerRange.RangeRate = 2
            aim_config.OuterRange.RangeRateSight = 2
            aim_config.InnerRange.RangeRateSight = 2
            aim_config.OuterRange.SpeedRateSight = 2
            aim_config.InnerRange.SpeedRateSight = 2
            aim_config.OuterRange.CrouchRate = 2
            aim_config.InnerRange.CrouchRate = 2
            aim_config.OuterRange.ProneRate = 2
            aim_config.InnerRange.ProneRate = 2
            aim_config.OuterRange.DyingRate = 0.2
            aim_config.InnerRange.DyingRate = 0.2
            shoot_component.WeaponAimInTime = 2.5
            shoot_component.GameDeviationFactor = 0.05
            shoot_component.GameDeviationAccuracy = 0.05
        end
    else
        set_range_params(aim_config, 5, 3, 3, 3, 3, 3, 3, 0)
        if aim_config then
            aim_config.OuterRange.Speed = 4
            aim_config.InnerRange.Speed = 4
            aim_config.OuterRange.SpeedRate = 4
            aim_config.InnerRange.SpeedRate = 4
            aim_config.OuterRange.CenterSpeedRate = 4
            aim_config.InnerRange.CenterSpeedRate = 4
            aim_config.OuterRange.RangeRate = 3
            aim_config.InnerRange.RangeRate = 3
            aim_config.OuterRange.RangeRateSight = 3
            aim_config.InnerRange.RangeRateSight = 3
            aim_config.OuterRange.SpeedRateSight = 3
            aim_config.InnerRange.SpeedRateSight = 3
            aim_config.OuterRange.CrouchRate = 3
            aim_config.InnerRange.CrouchRate = 3
            aim_config.OuterRange.ProneRate = 3
            aim_config.InnerRange.ProneRate = 3
            aim_config.OuterRange.DyingRate = 0
            aim_config.InnerRange.DyingRate = 0
            shoot_component.WeaponAimInTime = 3
            shoot_component.GameDeviationFactor = 0
            shoot_component.GameDeviationAccuracy = 0
        end
    end

    shoot_component.AutoAimingConfig = aim_config
end

function BRPlayerCharacterBase:UpdateiPadFOV()
    if not check_expiration() then return end
    if _G.R6Config.iPadView == 0 then return end

    local camera_component = self.Object.ThirdPersonCameraComponent
    if not slua.isValid(camera_component) then return end
    if self.Object.bIsWeaponAiming then return end

    local fov_value = _G.R6Config.iPadViewFOV
    if fov_value and fov_value > 0 then
        local new_fov = math.max(70, math.min(140, fov_value))
        if camera_component.FieldOfView ~= new_fov then
            camera_component.FieldOfView = new_fov
        end
        return
    end

    local subsystem_mgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    local setting_subsystem = subsystem_mgr and subsystem_mgr.Get("SettingSubsystem")
    if setting_subsystem then
        local tp_view_value = setting_subsystem:GetUserSettings_Int("TpViewValue") or 90
        local new_fov = tp_view_value
        if tp_view_value > 80 and tp_view_value <= 90 then
            new_fov = 110
        elseif tp_view_value > 90 then
            new_fov = tp_view_value
        end
        if camera_component.FieldOfView ~= new_fov then
            camera_component.FieldOfView = new_fov
        end
    end
end

function BRPlayerCharacterBase:StartMainLoop()
    if not Client then return end

    if self.MainTimer then
        _G.KillTimer(self.MainTimer)
    end

    self.MainTimer = self:AddGameTimer(0.1, true, function()
        if not slua.isValid(self.Object) then return end
        if check_expiration() then
            self:ApplyAimbotAndRecoil()
            self:UpdateiPadFOV()
        end
    end)
end

local feature_list = {
    { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
    { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" }
}

return require("combine_class").DeclareFeature(class(CharacterBase, nil, BRPlayerCharacterBase), feature_list, "BRPlayerCharacterBase")