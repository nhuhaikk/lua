--[[ ZN_KNOX - Anti-Crack Enhanced Edition with Mini Map ESP + WALLHACK + BYPASS MODULE ]]

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local KismetMathLibrary = import("KismetMathLibrary")
local GameplayStatics = import("GameplayStatics")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")

-- ============================================================================
-- ANTI-CRACK SECURE EXPIRE SYSTEM
-- ============================================================================
local EXPIRE_DATE = "2027-06-4"

local _CACHED_SERVER_TIME = nil
local _CACHED_TIME_SOURCE = nil
local _GLOBAL_EXPIRY_CHECK_PASSED = nil
local _SYSTEM_TAMPER_DETECTED = false
local _LAST_VERIFIED_TIME = nil
local _TIME_MISMATCH_COUNT = 0

local function GetExpireTimestamp()
    local expire = {}
    EXPIRE_DATE:gsub("(%d+)", function(d) table.insert(expire, tonumber(d)) end)
    return os.time({year=expire[1], month=expire[2], day=expire[3], hour=23, min=59, sec=59})
end

local function DetectSystemTampering(currentTime)
    if not _LAST_VERIFIED_TIME then
        _LAST_VERIFIED_TIME = currentTime
        return false
    end
    local timeDifference = currentTime - _LAST_VERIFIED_TIME
    if timeDifference < -300 then
        _TIME_MISMATCH_COUNT = _TIME_MISMATCH_COUNT + 1
        if _TIME_MISMATCH_COUNT >= 2 then
            _SYSTEM_TAMPER_DETECTED = true
            return true
        end
    else
        _TIME_MISMATCH_COUNT = math.max(0, _TIME_MISMATCH_COUNT - 1)
    end
    _LAST_VERIFIED_TIME = currentTime
    return false
end

local function GetRealServerTime()
    if _SYSTEM_TAMPER_DETECTED then return nil end
    if _CACHED_SERVER_TIME and _CACHED_SERVER_TIME > 0 then
        local elapsed = os.difftime(os.time(), _CACHED_TIME_SOURCE or os.time())
        local currentTime = _CACHED_SERVER_TIME + elapsed
        if DetectSystemTampering(currentTime) then return nil end
        return currentTime
    end
    local serverTime = nil
    pcall(function()
        local GameState = GameplayData.GetGameState()
        if slua.isValid(GameState) and GameState.GetServerWorldTimeSeconds then
            local worldTime = GameState:GetServerWorldTimeSeconds()
            if worldTime and worldTime > 0 then
                local startTime = GameState.K2_GetGameServerStartTime or GameState.ServerStartTime
                if startTime and startTime > 0 then
                    serverTime = startTime + worldTime
                end
            end
        end
    end)
    if not serverTime then
        pcall(function()
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) and pc.GetServerTime then
                local st = pc:GetServerTime()
                if st and st > 0 then serverTime = st end
            end
        end)
    end
    if not serverTime then
        local osTime = os.time()
        local osDate = os.date("*t", osTime)
        if osDate.year >= 2024 and osDate.year <= 2030 then
            local expireTime = GetExpireTimestamp()
            if osTime < expireTime - 86400 * 365 then
                _SYSTEM_TAMPER_DETECTED = true
                return nil
            end
            serverTime = osTime
        else
            _SYSTEM_TAMPER_DETECTED = true
            return nil
        end
    end
    if serverTime and serverTime > 0 then
        _CACHED_SERVER_TIME = serverTime
        _CACHED_TIME_SOURCE = os.time()
    end
    return serverTime
end

local function CheckExpiration()
    if _SYSTEM_TAMPER_DETECTED then
        _G._MOD_EXPIRED = true
        _G._TAMPER_DETECTED = true
        return false
    end
    if _GLOBAL_EXPIRY_CHECK_PASSED ~= nil then
        return _GLOBAL_EXPIRY_CHECK_PASSED
    end
    local currentRealTime = GetRealServerTime()
    if not currentRealTime or currentRealTime <= 0 then
        _GLOBAL_EXPIRY_CHECK_PASSED = false
        _G._NO_SERVER_TIME = true
        _G._MOD_EXPIRED = true
        return false
    end
    local expireTime = GetExpireTimestamp()
    if currentRealTime > expireTime then
        _GLOBAL_EXPIRY_CHECK_PASSED = false
        _G._MOD_EXPIRED = true
        return false
    end
    _GLOBAL_EXPIRY_CHECK_PASSED = true
    _G._MOD_EXPIRED = false
    return true
end

local function GetDaysRemaining()
    local currentRealTime = GetRealServerTime()
    if not currentRealTime or currentRealTime <= 0 then return 0 end
    local expireTime = GetExpireTimestamp()
    local days_remaining = math.ceil((expireTime - currentRealTime) / 86400)
    if days_remaining < 0 then days_remaining = 0 end
    return days_remaining
end

local function ShowAntiCrackPopup(reason)
    if _G._ANTICRACK_POPUP_SHOWN then return end
    _G._ANTICRACK_POPUP_SHOWN = true
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] 
            or require("client.slua.logic.common.logic_common_msg_box")
        local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"] 
            or require("client.slua.logic.url.logic_webview_sdk")
        _G._MOD_EXPIRED = true
        local function onClickTelegram()
            if Web then Web:OpenURL("https://t.me/ZN_KNOX") end
        end
        local message = "ANTI-CRACK PROTECTION ACTIVATED!\n\n"
        if reason == "tamper" then
            message = message .. "SYSTEM TAMPERING DETECTED!\n\nDATE CHANGE IS NOT ALLOWED!\n\n"
        elseif reason == "rollback" then
            message = message .. "TIME MANIPULATION DETECTED!\n\nDATE ROLLBACK IS NOT ALLOWED!\n\n"
        elseif _G._NO_SERVER_TIME then
            message = "NO INTERNET CONNECTION DETECTED!\n\nMOD REQUIRES INTERNET\nTO VERIFY LICENSE!\n\n"
        else
            message = "MOD EXPIRED ON " .. EXPIRE_DATE .. "!\n\nCONTACT @ZN_KNOX\nTO GET NEW VERSION!\n\n"
        end
        message = message .. "DEVICE INFO SAVED\n\n@ZN_KNOX"
        Msg.Show(4, " ANTI-CRACK ", message, onClickTelegram)
    end)
end

local function ShowExpirePopup()
    if _G._EXPIRY_POPUP_SHOWN then return end
    _G._EXPIRY_POPUP_SHOWN = true
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] 
            or require("client.slua.logic.common.logic_common_msg_box")
        local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"] 
            or require("client.slua.logic.url.logic_webview_sdk")
        _G._MOD_EXPIRED = true
        local function onClickTelegram()
            if Web then Web:OpenURL("https://t.me/ZN_KNOX") end
        end
        local message = "YOUR MOD HAS EXPIRED!\n\n"
        if _G._NO_SERVER_TIME then
            message = "NO INTERNET CONNECTION!\n\nMOD REQUIRES INTERNET\nTO VERIFY LICENSE!\n\n"
        elseif _G._TIME_ROLLBACK_DETECTED then
            message = "TIME MANIPULATION DETECTED!\n\nPLEASE SET CORRECT DATE\nAND TIME ON YOUR DEVICE!\n\n"
        else
            message = "MOD EXPIRED ON " .. EXPIRE_DATE .. "!\n\nCONTACT @ZN_KNOX\nTO GET NEW VERSION!\n\n"
        end
        Msg.Show(4, "MOD EXPIRED", message .. "MOD WILL NOT WORK ANYMORE!\n\n@ZN_KNOX", onClickTelegram)
    end)
end

local function ShowDaysRemainingPopup()
    if _G.DaysRemainingShown then return end
    if not CheckExpiration() then 
        ShowExpirePopup() 
        return 
    end
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] 
            or require("client.slua.logic.common.logic_common_msg_box")
        local days = GetDaysRemaining()
        if days <= 0 then
            ShowExpirePopup()
            return
        end
        local daysText = string.format("%d DAYS REMAINING", days)
        local message = string.format("ZN_KNOX MOD ACTIVE - %s\n\nEXPIRES: %s\n\n DO NOT CHANGE DATE/TIME \n\n@ZN_KNOX", daysText, EXPIRE_DATE)
        local function onClickTelegram()
            local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"] 
                or require("client.slua.logic.url.logic_webview_sdk")
            if Web then Web:OpenURL("https://t.me/ZN_KNOX") end
        end
        Msg.Show(4, "MODDED BY @ZN_KNOX", message, onClickTelegram)
        _G.DaysRemainingShown = true
    end)
end

function _G.TryShowWelcome()
    if _G.WelcomeShown then return end
    if not CheckExpiration() then 
        if _SYSTEM_TAMPER_DETECTED then
            ShowAntiCrackPopup("tamper")
        else
            ShowExpirePopup()
        end
        return 
    end
    pcall(function()
        ShowDaysRemainingPopup()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"] 
            or require("client.slua.logic.common.logic_common_msg_box")
        local Web = package.loaded["client.slua.logic.url.logic_webview_sdk"] 
            or require("client.slua.logic.url.logic_webview_sdk")
        local function onClickDirect()
            if Web then Web:OpenURL("https://t.me/ZN_KNOX") end
        end
        Msg.Show(4, "NOTIFICATION FROM @ZN_KNOX", 
            "WELCOME TO LUA VIP MOD\n\nEXPIRY: " .. EXPIRE_DATE .. "\n\n[ THIS OBB IS MODDED BY - @ZN_KNOX ] #REAL DEVELOPER \n\nJOIN TELEGRAM CHANNEL", 
            onClickDirect)
        _G.WelcomeShown = true
    end)
end

-- Continuous Monitor
if not _G.ANTI_TAMPER_MONITOR then
    _G.ANTI_TAMPER_MONITOR = true
    _G._TAMPER_CHECK_COUNT = 0
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) and pc.AddGameTimer then
            pc:AddGameTimer(2.0, true, function()
                _G._TAMPER_CHECK_COUNT = (_G._TAMPER_CHECK_COUNT or 0) + 1
                if not CheckExpiration() then
                    if _SYSTEM_TAMPER_DETECTED then
                        ShowAntiCrackPopup("tamper")
                    else
                        ShowExpirePopup()
                    end
                end
                if _G._TAMPER_CHECK_COUNT % 15 == 0 then
                    _CACHED_SERVER_TIME = nil
                    local freshTime = GetRealServerTime()
                    if freshTime then
                        CheckExpiration()
                    end
                end
            end)
        end
    end)
end

-- ============================================================================
-- BYPASS MODULE (ACTIVATES FIRST)
-- ============================================================================

if not _G.GameplayCallbacks then
    _G.GameplayCallbacks = {}
end

function _G.InitializeAntiReport()
    pcall(function()
        local reportPaths = { "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem" }
        local ClientReportPlayerSubsystem = nil
        for _, path in ipairs(reportPaths) do
            if package.loaded[path] then ClientReportPlayerSubsystem = package.loaded[path] break end
            local success, loadedReportSubsystem = pcall(require, path)
            if success and loadedReportSubsystem then ClientReportPlayerSubsystem = loadedReportSubsystem break end
        end
        if ClientReportPlayerSubsystem then
            ClientReportPlayerSubsystem.OnInit = function(self) return end
            ClientReportPlayerSubsystem._OnPlayerKilledOtherPlayer = function() return end
            ClientReportPlayerSubsystem._RecordFatalDamager = function() return end
            ClientReportPlayerSubsystem._OnDeathReplayDataWhenFatalDamaged = function() return end
            ClientReportPlayerSubsystem._RecordMurdererFromDeathReplayData = function() return end
            ClientReportPlayerSubsystem._RecordTeammatePlayerInfo = function() return end
            ClientReportPlayerSubsystem._OnBattleResult = function() return end
            ClientReportPlayerSubsystem._OnShowQuickReportMutualExclusiveUI = function() return end
            ClientReportPlayerSubsystem.GetFatalDamagerMap = function() return {} end
            ClientReportPlayerSubsystem.GetCachedTeammateName2InfoMap = function() return {} end
            ClientReportPlayerSubsystem.GetTeammateName2InfoMapDuringBattle = function() return {} end
            ClientReportPlayerSubsystem.GetCurrentNotInTeamHistoricalTeammateMap = function() return {} end
            ClientReportPlayerSubsystem.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
        end
    end)
    pcall(function()
        local reportPaths = { "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem", "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem" }
        local DSReportPlayerSubsystem = nil
        for _, path in ipairs(reportPaths) do
            if package.loaded[path] then DSReportPlayerSubsystem = package.loaded[path] break end
            local success, loadedReportSubsystem = pcall(require, path)
            if success and loadedReportSubsystem then DSReportPlayerSubsystem = loadedReportSubsystem break end
        end
        if DSReportPlayerSubsystem then
            DSReportPlayerSubsystem.OnInit = function(self) return end
            DSReportPlayerSubsystem._OnNearDeathOrRescued = function() return end
            DSReportPlayerSubsystem._OnCharacterDied = function() return end
            DSReportPlayerSubsystem._OnTeammateDamage = function() return end
            DSReportPlayerSubsystem._OnPlayerSettlementStart = function() return end
            DSReportPlayerSubsystem._AddKnockDownerToBattleResult = function() return end
            DSReportPlayerSubsystem._AddKillerToBattleResult = function() return end
            DSReportPlayerSubsystem._AddTeammateMurderToBattleResult = function() return end
            DSReportPlayerSubsystem._AddFatalDamagerMapToBattleResult = function() return end
            DSReportPlayerSubsystem._AddMLKillerUIDToBattleResult = function() return end
            DSReportPlayerSubsystem._SaveHistoricalTeammateInfo = function() return end
            DSReportPlayerSubsystem._RecordFatalDamager = function() return end
            DSReportPlayerSubsystem._RecordTeammateMurderer = function() return end
        end
    end)
    pcall(function()
        local ReportPlayerUtils = require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
        if ReportPlayerUtils then
            ReportPlayerUtils.RecordFatalDamager = function() return end
            ReportPlayerUtils.IsUsingHistoricalTeammateInfo = function() return false end
            ReportPlayerUtils.IsCharacterDeliverAI = function() return false end
        end
    end)
    pcall(function()
        local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if SecurityCommonUtils then
            SecurityCommonUtils.ExtractPlayerBasicInfo = function() return {} end
            SecurityCommonUtils.LogIf = function() return false end
        end
    end)
    pcall(function()
        local ClientQuickReportMaliciousTeammate = require("GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate")
        if ClientQuickReportMaliciousTeammate then
            ClientQuickReportMaliciousTeammate.OnShowMutualExclusiveUI = function() return end
            ClientQuickReportMaliciousTeammate.OnHideMutualExclusiveUI = function() return end
        end
    end)
    pcall(function()
        local LogicReportReplay = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if LogicReportReplay then
            LogicReportReplay.ReportReplay = function() end
            LogicReportReplay.SendReportReq = function() end
        end
        local LogicHomeReport = package.loaded["client.slua.logic.home.logic_home_report"]
        if LogicHomeReport then
            LogicHomeReport.ShowInGameReportUI = function() end
            LogicHomeReport.SendReport = function() end
        end
    end)
end

function _G.DisableHiggsBoson()
    local localPlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not localPlayerController or not slua.isValid(localPlayerController) then return end
    if localPlayerController.HiggsBoson then
        localPlayerController.HiggsBoson.bMHActive = false
        localPlayerController.HiggsBoson.bCallPreReplication = false
    end
    if localPlayerController.HiggsBosonComponent then
        localPlayerController.HiggsBosonComponent.bMHActive = false
        localPlayerController.HiggsBosonComponent:ControlMHActive(0)
    end
end

function _G.InitializeAntiCheatHooks()
    pcall(function()
        local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponent and HiggsBosonComponent.StaticShowSecurityAlertInDev then
            HiggsBosonComponent.StaticShowSecurityAlertInDev = function() end
        end
    end)
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = function(HiggsBosonComponent) end
        _G.AvatarCheckCallback.OnReportItemID = function(HiggsBosonComponent) end
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(localPlayerController)
            if slua.isValid(localPlayerController) and localPlayerController.HiggsBosonComponent then
                localPlayerController.HiggsBosonComponent:ControlMHActive(0)
                localPlayerController.HiggsBosonComponent.bMHActive = false
            end
        end
    end
    pcall(function()
        local HiggsBosonComponentModule = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsBosonComponentModule and HiggsBosonComponentModule.BlackList then
            for k in pairs(HiggsBosonComponentModule.BlackList) do HiggsBosonComponentModule.BlackList[k] = nil end
        end
    end)
    _G.BlackList = {}
    pcall(function()
        _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
        _G.GlobalPlayerCheatTimes = _G.GlobalPlayerCheatTimes or {}
        local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
        mt.__newindex = function(t, k, v) end
        setmetatable(_G.GlobalPlayerCoronaData, mt)
    end)
    pcall(function()
        if _G.GameSafeCallbacks and _G.GameSafeCallbacks.RecordStrategyTimestampInReplay then
            _G.GameSafeCallbacks.RecordStrategyTimestampInReplay = function(...) end
            _G.GameSafeCallbacks.DoAttackFlowStrategy = function() end
            _G.GameSafeCallbacks.GetScriptReportContent = function() return "" end
        end
    end)
    pcall(function()
        local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
        if STExtraBlueprintFunctionLibrary then
            STExtraBlueprintFunctionLibrary.IsDevelopment = function() return false end
        end
    end)
end

function _G.InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local OriginalOnDSPlayerStateChanged = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            if InPlayerState and string.lower(tostring(InPlayerState)) == "cheatdetected" then return end
            if OriginalOnDSPlayerStateChanged then return OriginalOnDSPlayerStateChanged(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
        end
        local function EmptyFunc() return end
        local function EmptyTableFunc() return {} end
        local function EmptyNilFunc() return nil end
        GC.ReportAttackFlow = EmptyFunc
        GC.ReportSecAttackFlow = EmptyFunc
        GC.ReportHurtFlow = EmptyFunc
        GC.ReportFireArms = EmptyFunc
        GC.ReportVerifyInfoFlow = EmptyFunc
        GC.ReportMrpcsFlow = EmptyFunc
        GC.ReportPlayerBehavior = EmptyFunc
        GC.ReportTeammatHurt = EmptyFunc
        GC.ReportMisKillByTeammate = EmptyFunc
        GC.ReportForbitPick = EmptyFunc
        GC.ReportPlayerMoveRoute = EmptyFunc
        GC.ReportPlayerPosition = EmptyFunc
        GC.ReportVehicleMoveFlow = EmptyFunc
        GC.ReportSecTgameMovingFlow = EmptyFunc
        GC.ReportParachuteData = EmptyFunc
        GC.SendTssSdkAntiDataToLobby = EmptyFunc
        GC.SendDSErrorLogToLobby = EmptyFunc
        GC.SendDSErrorLogToLobbyOnece = EmptyFunc
        GC.SendDSHawkEyePatrolLogToLobby = EmptyFunc
        GC.ReportEquipmentFlow = EmptyFunc
        GC.ReportAimFlow = EmptyFunc
        GC.GetWeaponReport = EmptyTableFunc
        GC.GetOneWeaponReport = EmptyTableFunc
        GC.ReportHeavyWeaponBoxSpawnFlow = EmptyFunc
        GC.ReportHeavyWeaponBoxActivationFlow = EmptyFunc
        GC.ReportHeavyWeaponBoxOpenPlayerFlow = EmptyFunc
        GC.ReportHeavyWeaponBoxItemFlow = EmptyFunc
        GC.ReportPlayersPing = EmptyFunc
        GC.ReportPlayerIP = EmptyFunc
        GC.ReportPlayerFramePingRecord = EmptyFunc
        GC.OnDSConnectionSaturated = EmptyFunc
        GC.ReportDSNetSaturation = EmptyFunc
        GC.ReportNetContinuousSaturate = EmptyFunc
        GC.ReportDSNetRate = EmptyFunc
        GC.SendClientStats = EmptyFunc
        GC.SendServerAvgTickDelta = EmptyFunc
        GC.ReportCircleFlow = EmptyFunc
        GC.ReportDSCircleFlow = EmptyFunc
        GC.ReportJumpFlow = EmptyFunc
        GC.ReportAIStrategyInfo = EmptyFunc
        GC.SendAIDeliveryInfo = EmptyFunc
        GC.ReportDailyTaskInfo = EmptyFunc
        GC.ReportMatchRoomData = EmptyFunc
        GC.SendPlayerSpectatingLog = EmptyFunc
        GC.ReportIDCardProduceFlow = EmptyFunc
        GC.ReportIDCardPickUpFlow = EmptyFunc
        GC.ReportIDCardDestroyFlow = EmptyFunc
        GC.ReportRevivalFlow = EmptyFunc
        GC.ReportGameSetting = EmptyFunc
        GC.ReportGameSettingNew = EmptyFunc
        GC.ReportAntsVoiceTeamCreate = EmptyFunc
        GC.ReportAntsVoiceTeamQuit = EmptyFunc
        GC.ReportCommonInfo = EmptyFunc
        GC.ReportLightweightStat = EmptyFunc
        GC.SendSecTLog = EmptyFunc
        GC.SendDataMiningTLog = EmptyFunc
        GC.SendActivityTLog = EmptyFunc
        GC.GetGeneralTLogData = EmptyNilFunc
        GC.IsBypassed = true
    end)
    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
            local OriginalSendPacket = NetUtil.SendPacket
            local blockedPacketsMap = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1,
                ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportTeammateKillConfirmFlow"]=1,
                ["ReportForbiddenPickupFlow"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1,
                ["ReportSecVehicleMoveFlow"]=1, ["ReportSecTgameMovingFlow"]=1, ["report_parachute_data"]=1,
                ["report_character_all_drag"]=1, ["report_parachute_all_drag"]=1, ["report_vehicle_move_drag"]=1,
                ["on_tss_sdk_anti_data"]=1, ["report_unrealnet_exception"]=1, ["ReportPlayerEquipmentInfo"]=1,
                ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["log_shooting_miss"]=1, ["report_heavy_weapon_box_activation_flow"]=1,
                ["report_heavy_weapon_box_item_flow"]=1, ["ReportCircleFlow"]=1, ["report_ds_player_circle_flow"]=1,
                ["ReportJumpFlow"]=1, ["ReportGameStartFlow"]=1, ["ReportGameEndFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_player_frame_ping_record"]=1, ["report_net_saturate"]=1,
                ["report_ds_netsaturate"]=1, ["report_ds_net_continuous_saturate"]=1, ["report_ds_netrate"]=1,
                ["report_unrealnet_clientstats"]=1, ["report_serverstat_avgtickdelta"]=1, ["report_all_players_address"]=1,
                ["report_ai_strategyinfo"]=1, ["ReportAIActionFlow"]=1, ["ReportGenerateMonsterFlow"]=1,
                ["report_ds_match_room_data"]=1, ["SendSpectatingLog"]=1, ["ReportIDCardProduceFlow"]=1,
                ["ReportIDCardPickUpFlow"]=1, ["ReportIDCardDestroyFlow"]=1, ["ReportRevivalFlow"]=1,
                ["ReportGameSetting"]=1, ["ReportGameSettingNew"]=1, ["ReportAntsVoiceTeamCreate"]=1,
                ["ReportAntsVoiceTeamQuit"]=1, ["report_common_info"]=1, ["report_common_battle_info"]=1,
                ["report_client_scan_result"]=1, ["tss_sdk_report"]=1, ["report_memory_exception"]=1,
                ["report_avatar_exception"]=1, ["report_ui_state"]=1, ["report_hit_reg_fail"]=1,
                ["report_character_state"]=1, ["report_vehicle_exception"]=1, ["report_camera_exception"]=1,
                ["ReportPlayerControllerStateChanged"]=1, ["ReportAvatarFlow"]=1,
                ["send_ugc_report_uni_mod_expose_req"]=1, 
                ["send_ugc_report_uni_mod_interactive_req"]=1,
            }
            NetUtil.SendPacket = function(packetName, ...)
                if blockedPacketsMap[packetName] then return end
                return OriginalSendPacket(packetName, ...)
            end
            NetUtil.IsBypassed = true
        end
    end)
end

function _G.InitializeConnectionGuard()
    pcall(function()
        if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then return end
        local GC = _G.GameplayCallbacks
        local OriginalOnDSPlayerStateChanged = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            local stateNameLower = InPlayerState and string.lower(tostring(InPlayerState)) or ""
            local blockedStatesMap = {
                ["cheatdetected"] = true, ["connectionlost"] = true,
                ["connectiontimeout"] = true, ["connectionexception"] = true,
                ["netdrivererror"] = true
            }
            if blockedStatesMap[stateNameLower] then return end
            if OriginalOnDSPlayerStateChanged then
                pcall(OriginalOnDSPlayerStateChanged, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            end
        end
        GC.OnPlayerNetConnectionClosed = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnPlayerActorChannelError = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnPlayerRPCValidateFailed = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnPlayerSpectateException = function(GameID, UID, Reason, ErrorMessage) end
        GC.OnShutdownAfterError = function(GameID) end
        _G.ConnectionGuardInitialized = true
    end)
end

function _G.InitializeLogBlocker()
    pcall(function()
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then
            TLog.Info = function() end; TLog.Warning = function() end
            TLog.Error = function() end; TLog.Debug = function() end; TLog.Report = function() end
        end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then
            CrashSight.ReportException = function() end
            CrashSight.SetCustomData = function() end; CrashSight.Log = function() end
        end
        local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if ClientToolsReport then
            ClientToolsReport.SendReport = function() end; ClientToolsReport.SendException = function() end
        end
        local TLogReportUtils = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if TLogReportUtils then
            TLogReportUtils.ReportTLogEvent = function() end
        end
        local UGCNewTLogReport = package.loaded["client.slua.logic.ugc.UGCNewTLogReport"] or package.loaded["client.slua.data.BasicData.BasicDataTLogReport"]
        if UGCNewTLogReport then
            UGCNewTLogReport.SendExposeReq = function() end
            UGCNewTLogReport.SendInteractionReq = function() end
            UGCNewTLogReport.TLogReport = function() end
        end
        local LogicUGCTLog = package.loaded["client.slua.logic.ugc.logic_ugc_tlog"]
        if LogicUGCTLog then
            LogicUGCTLog.SendModTLog = function() end
            LogicUGCTLog.ReportStay = function() end
        end
        local ClientTLogUtil = package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"]
        if ClientTLogUtil then
            ClientTLogUtil.ReportGeneralCountByBRPhase = function() end
            ClientTLogUtil.ReportCommonTLogDataByBRPhase = function() end
        end
        local GameplayDataRef = require("GameLua.GameCore.Data.GameplayData")
        if GameplayDataRef then
            local playerController = GameplayDataRef.GetPlayerControllerSafety and GameplayDataRef.GetPlayerControllerSafety() or GameplayDataRef.GetPlayerController()
            if slua.isValid(playerController) and playerController.ReportCrashKitFeature then
                playerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException = function() end
            end
        end
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local GameReportSubsystem = SubsystemMgr and SubsystemMgr:Get("GameReportSubsystem")
        if GameReportSubsystem then
            GameReportSubsystem.CheckCanBugglyPostException = function() return false end
            GameReportSubsystem.BugglyPostExceptionFull = function() return false end
        end
    end)
end

function _G.InitializeScannerBlocker()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local AFKReportorSubsystem = SubsystemMgr:Get("AFKReportorSubsystem")
            if AFKReportorSubsystem then 
                AFKReportorSubsystem.PlayerHaveAction = function() end; AFKReportorSubsystem.ReportAFK = function() end
            end
            local AvatarExceptionSubsystem = SubsystemMgr:Get("AvatarExceptionSubsystem")
            if AvatarExceptionSubsystem then
                AvatarExceptionSubsystem.ReportException = function() end
                AvatarExceptionSubsystem.BindPlayerCharacter = function() end
                AvatarExceptionSubsystem.CheckAvatarValid = function() return true end
            end
            local ShootVerifySubSystemClient = SubsystemMgr:Get("ShootVerifySubSystemClient")
            if ShootVerifySubSystemClient then
                ShootVerifySubSystemClient.ReportVerifyFail = function() end
                ShootVerifySubSystemClient.OnVerifyFailed = function() end
            end
        end
        local AvatarCheckerModule = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
        if AvatarCheckerModule then
            AvatarCheckerModule.CheckAvatar = function() return true end
            AvatarCheckerModule.ReportException = function() end
        end
        local LogicMemoryWarning = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
        if LogicMemoryWarning then
            LogicMemoryWarning.OnMemoryWarning = function() end
            LogicMemoryWarning.ReportMemoryWarning = function() end
        end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            TssSdk.OnRecvData = function() end; TssSdk.SendReportInfo = function() end
            TssSdk.ScanMemory = function() return true end
        end
    end)
end

function _G.InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local RescueBtnReplayTraceSubsystem = SubsystemMgr and SubsystemMgr:Get("RescueBtnReplayTraceSubsystem")
        if RescueBtnReplayTraceSubsystem then
            RescueBtnReplayTraceSubsystem.ReportTrace = function() end; RescueBtnReplayTraceSubsystem.StartTickMonitor = function() end
            RescueBtnReplayTraceSubsystem.TickMonitorCheck = function() end; RescueBtnReplayTraceSubsystem.ReportTickMonitorHeartbeat = function() end
        end
        local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GameReportUtils then
            GameReportUtils.ReplayReportData = function() end
            GameReportUtils.ReportGameException = function() end
        end
        local GameReportSubsystem = SubsystemMgr and SubsystemMgr:Get("GameReportSubsystem")
        if GameReportSubsystem then
            GameReportSubsystem.ReplayReportData = function() return false end
            if GameReportSubsystem.Reporter then
                GameReportSubsystem.Reporter.ReportIntArrayData = function() end
                GameReportSubsystem.Reporter.ReportUInt8ArrayData = function() end
                GameReportSubsystem.Reporter.ReportFloatArrayData = function() end
            end
        end
    end)
end

local function InitializeAllBlockers()
    pcall(function()
        if _G.InitializeAntiReport then _G.InitializeAntiReport() end
        if _G.InitializeAntiCheatHooks then _G.InitializeAntiCheatHooks() end
        if _G.InitializeGameplayBypass then _G.InitializeGameplayBypass() end
        if _G.InitializeConnectionGuard then _G.InitializeConnectionGuard() end
        if _G.DisableHiggsBoson then _G.DisableHiggsBoson() end
        if _G.InitializeLogBlocker then _G.InitializeLogBlocker() end
        if _G.InitializeScannerBlocker then _G.InitializeScannerBlocker() end
        if _G.InitializeReplayTelemetryBlocker then _G.InitializeReplayTelemetryBlocker() end
    end)
end

-- ============================================================================
-- AIMBOT FUNCTIONS
-- ============================================================================
_G._AimbotCurrentPC = nil

local function ApplyHardAimbot()
    if not CheckExpiration() then return end
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

        entity.RecoilKickADS = 0.01
        entity.GameDeviationFactor = 0.01
        entity.GameDeviationAccuracy = 0.01
        entity.ExtraHitPerformScale = 50
        
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = 4.5
                    cfg.RangeRate = 4.5
                    cfg.SpeedRate = 4.5
                    cfg.RangeRateSight = 4.5
                    cfg.SpeedRateSight = 4.5
                    cfg.CrouchRate = 4.5
                    cfg.ProneRate = 4.5
                    cfg.DyingRate = 0
                    cfg.adsorbMaxRange = 200
                    cfg.adsorbMinRange = 20
                    cfg.adsorbMinAttenuationDis = 100
                    cfg.adsorbMaxAttenuationDis = 8000
                    cfg.adsorbActiveMinRange = 20
                end
            end
            entity.AutoAimingConfig = entity.AutoAimingConfig
        end

        pcall(function()
            local aimComp = char.BP_AutoAimingComponent_C 
                         or char.BP_AutoAimingComponent 
                         or char.AutoAimingComponent
            if slua.isValid(aimComp) and aimComp.Bones then
                pcall(function() aimComp.Bones[0] = "head" end)
                pcall(function() aimComp.Bones[1] = "head" end)
                pcall(function() aimComp.Bones[2] = "head" end)
                pcall(function() aimComp.Bones:Set(0, "head") end)
                pcall(function() aimComp.Bones:Set(1, "head") end)
                pcall(function() aimComp.Bones:Set(2, "head") end)
            end
        end)
    end)
end

-- ============================================================================
-- WALLHACK FUNCTIONS (MERGED FROM wall.lua)
-- ============================================================================

local function Valid(obj)
    return slua.isValid(obj)
end

local function ApplyVisualMods(localPlayer, enemy, pc, mWh, mWp)
    if not Valid(enemy) then return end
    local meshes = {}
    pcall(function()
        if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = enemy:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c-1) or childs[c]
                    if Valid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    local isEnabled = mWh or mWp
    if isEnabled then
        local depthTest = mWh
        local blendMode = mWh and 2 or 1
        pcall(function()
            for _, comp in ipairs(meshes) do
                if Valid(comp) then
                    local s, matInterface = pcall(function() return comp:GetMaterial(0) end)
                    if s and Valid(matInterface) then
                        local s2, baseMat = pcall(function() return matInterface:GetBaseMaterial() end)
                        if s2 and Valid(baseMat) then
                            if baseMat.bDisableDepthTest ~= depthTest then baseMat.bDisableDepthTest = depthTest end
                            if baseMat.BlendMode ~= blendMode then baseMat.BlendMode = blendMode end
                        end
                    end
                end
            end
        end)
        pcall(function()
            for _, comp in ipairs(meshes) do
                if Valid(comp) then
                    comp.UseScopeDistanceCulling = false 
                    comp.PrimitiveShadingStrategy = 1
                    comp.ShadingRate = 6
                end
            end
            local finalColor
            if mWh then
                local isVisible = false
                if Valid(pc) and Valid(enemy) and type(pc.LineOfSightTo) == "function" then 
                    pcall(function() isVisible = pc:LineOfSightTo(enemy) end) 
                end
                local hiddenColor  = { R = 25.0, G = 0.0,  B = 25.0, A = 1.0, r = 25.0, g = 0.0,  b = 25.0, a = 1.0 }
                local visibleColor = { R = 0.0,  G = 25.0, B = 25.0, A = 1.0, r = 0.0,  g = 25.0, b = 25.0, a = 1.0 }
                finalColor = isVisible and visibleColor or hiddenColor
            else
                finalColor = { R = 50.0, G = 50.0, B = 50.0, A = 1.0, r = 50.0, g = 50.0, b = 50.0, a = 1.0 }
            end
            local scale = { R = 3.0,  G = 3.0,  B = 0.0,  A = 0.0, r = 3.0,  g = 3.0,  b = 0.0,  a = 0.0 }
            enemy.WH_MIDs = enemy.WH_MIDs or {}
            local stateChanged = (enemy.WH_LastColorR ~= finalColor.R) or (enemy.WH_LastBlendMode ~= blendMode)
            for _, comp in ipairs(meshes) do
                if Valid(comp) then
                    local compKey = tostring(comp)
                    enemy.WH_MIDs[compKey] = enemy.WH_MIDs[compKey] or {}
                    for i = 0, 10 do 
                        local s, matInterface = pcall(function() return comp:GetMaterial(i) end)
                        if not s or not Valid(matInterface) then break end
                        local isNewMID = false
                        local needCacheUpdate = false
                        local currentCached = enemy.WH_MIDs[compKey][i]
                        if not Valid(currentCached) then
                            local s2, newMid = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                            if s2 and Valid(newMid) then 
                                enemy.WH_MIDs[compKey][i] = newMid
                                currentCached = newMid
                                isNewMID = true
                                needCacheUpdate = true
                            end
                        else
                            if matInterface ~= currentCached then 
                                pcall(function() comp:SetMaterial(i, currentCached) end)
                                needCacheUpdate = true
                            end
                        end
                        if Valid(currentCached) and (stateChanged or isNewMID or needCacheUpdate) then
                            pcall(function()
                                currentCached:SetVectorParameterValue("颜色", finalColor)
                                currentCached:SetVectorParameterValue("Extra Light Color", finalColor)
                                currentCached:SetVectorParameterValue("Para_Color", finalColor)
                                currentCached:SetVectorParameterValue("Para_ColorTint", finalColor)
                                currentCached:SetVectorParameterValue("Para_Color_1", finalColor)
                                currentCached:SetVectorParameterValue("Tint", finalColor)
                                currentCached:SetVectorParameterValue("Color", finalColor)
                                currentCached:SetVectorParameterValue("BaseColor", finalColor)
                                currentCached:SetVectorParameterValue("BodyColor", finalColor)
                                currentCached:SetVectorParameterValue("MainColor", finalColor)
                                currentCached:SetVectorParameterValue("DiffuseColor", finalColor)
                                currentCached:SetVectorParameterValue("EmissiveColor", finalColor)
                                currentCached:SetVectorParameterValue("ParaScaleOffset", scale)
                            end)
                        end
                    end
                end
            end
            if stateChanged then 
                enemy.WH_LastColorR = finalColor.R
                enemy.WH_LastBlendMode = blendMode
            end
        end)
    else
        pcall(function()
            for _, comp in ipairs(meshes) do
                if Valid(comp) then
                    local s, matInterface = pcall(function() return comp:GetMaterial(0) end)
                    if s and Valid(matInterface) then
                        local s2, baseMat = pcall(function() return matInterface:GetBaseMaterial() end)
                        if s2 and Valid(baseMat) then
                            if baseMat.bDisableDepthTest ~= false then baseMat.bDisableDepthTest = false end
                            if baseMat.BlendMode ~= 1 then baseMat.BlendMode = 1 end
                        end
                    end
                end
            end
        end)
        enemy.WH_LastColorR = nil
        enemy.WH_LastBlendMode = nil
        enemy.WH_MIDs = nil
    end
end

-- ============================================================================
-- ALL FEATURES AUTO-ON
-- ============================================================================
_G.AK_Features = {
    { id = "ESP_HP",         name = "ESP Health Bar",     val = 1, type = "toggle" },
    { id = "ESP_BOX",        name = "ESP Box",            val = 1, type = "toggle" },
    { id = "ESP_MAP",        name = "Mini Map ESP",       val = 1, type = "toggle" },
    { id = "AIMBOT",         name = "Aimbot",             val = 1, type = "toggle" },
    { id = "WALLHACK",       name = "Wallhack",           val = 1, type = "toggle" },
}

function _G.AK_GetVal(featureId)
    for _, feature in ipairs(_G.AK_Features) do
        if feature.id == featureId then return feature.val end
    end
    return 0
end

-- ============================================================================
-- DISTANCE MARKER SYSTEM (Mini Map ESP)
-- ============================================================================

local distanceMarkerConfig = {
    UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
    MaxWidgetNum = 99,
    MaxShowDistance = 6000000,
    bBindOutScreen = true,
    bBindBlocked = true,
    bIsBindingActor = true,
    BindSocketName = "head",
    bUseLuaWorldSocketName = true,
    WorldPositionOffset = FVector(0, 0, 50),
    bNeedPreLoad = true,
    Priority = 2
}

local function InitDistanceMarkerSystem()
    pcall(function()
        if InGameMarkTools and InGameMarkTools.ScreenMarkManager and InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
            InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999)
        end
        local gameplayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local screenMarkConfig = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
        if screenMarkConfig then
            screenMarkConfig[9999] = distanceMarkerConfig
        end
        for moduleName, moduleData in pairs(package.loaded) do
            if type(moduleName) == "string" and string.find(moduleName, "ScreenMarkConfig") then
                if type(moduleData) == "table" then
                    moduleData[9999] = distanceMarkerConfig
                end
            end
        end
    end)
end

if not _G.AK_Active_Marks_Cache then
    _G.AK_Active_Marks_Cache = {}
end

local function createDistanceMarker(enemy)
    if _G._MOD_EXPIRED then return end
    pcall(function()
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(9999, FVector(0,0,0), 0, "", 4, enemy)
            _G.AK_Active_Marks_Cache[tostring(enemy)] = { actor = enemy, distMark = enemy.NativeDistMark }
        end
    end)
end

local function removeDistanceMarker(enemy)
    pcall(function()
        if InGameMarkTools then
            if InGameMarkTools.ClientRemoveMapMark then
                InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark)
            elseif InGameMarkTools.HideMapMark then
                InGameMarkTools.HideMapMark(enemy.NativeDistMark)
            end
        end
        enemy.NativeDistMark = nil
        _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
    end)
end

local function cleanupDeadEnemyMarks()
    for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
        local shouldRemove = false
        if not slua.isValid(cacheData.actor) then
            shouldRemove = true
        else
            pcall(function()
                local actor = cacheData.actor
                if actor.bHidden or (actor.Mesh and actor.Mesh.bHidden) then
                    shouldRemove = true
                end
                if type(actor.IsDead) == "function" and actor:IsDead() then
                    shouldRemove = true
                elseif actor.bIsDead == true or actor.bIsDeadFlag == true then
                    shouldRemove = true
                end
            end)
        end
        if shouldRemove then
            pcall(function()
                if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                    InGameMarkTools.ClientRemoveMapMark(cacheData.distMark)
                end
            end)
            _G.AK_Active_Marks_Cache[cacheKey] = nil
        end
    end
end

local function processEnemyMapESP(enemy, localPlayer, isMapESPEnabled)
    if _G._MOD_EXPIRED then return end
    if not slua.isValid(enemy) or enemy == localPlayer or enemy.TeamID == localPlayer.TeamID then return end

    local isDead = false
    pcall(function()
        if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
        elseif enemy.bIsDead then isDead = true end
        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
    end)

    if not isDead then
        if isMapESPEnabled == 1 then
            if not enemy.bHasAKNativeMapMarker then
                createDistanceMarker(enemy)
                enemy.bHasAKNativeMapMarker = true
            end
        else
            if enemy.bHasAKNativeMapMarker then
                removeDistanceMarker(enemy)
                enemy.bHasAKNativeMapMarker = false
            end
        end
    else
        if enemy.bHasAKNativeMapMarker then
            removeDistanceMarker(enemy)
            enemy.bHasAKNativeMapMarker = false
        end
    end
end

-- ============================================================================
-- BRPLAYERCHARACTERBASE CLASS
-- ============================================================================

local BRPlayerCharacterBase = {
    ServerRPC = {},
    ClientRPC = {},
    MulticastRPC = {}
}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }

function BRPlayerCharacterBase:ctor()
    self.bHasShownDevNotice = false
    self.AK_NativeESP_Ready = false
end

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
    self:StartAdvancedSystems()
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    if slua.isValid(self.STCharacterMovement) then
        self.STCharacterMovement.bPositiveBlowUp = true
    end
    if Client then
        GameplayData.AddCharacter(self.Object)
    end
    EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
    if Client then
        GameplayData.RemoveCharacter(self.Object)
    end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
    self.Super:OnPlayerEnterCarryBoxState()
    if self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
    end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    if self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
    if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
    end
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
    local uNearDeathComp = self.NearDeatchComponent
    if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
        uNearDeathComp:TriggerGotoDieExplictly(self.Object)
    end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
    return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle) end
function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle) end
function BRPlayerCharacterBase:ClearAttachToVehicleTimer() end

-- ============================================================================
-- MAIN ADVANCED SYSTEMS (ESP + AIMBOT + WALLHACK)
-- ============================================================================

function BRPlayerCharacterBase:StartAdvancedSystems()
    if not Client then return end
    
    if not CheckExpiration() then
        if _SYSTEM_TAMPER_DETECTED then
            ShowAntiCrackPopup("tamper")
        else
            ShowExpirePopup()
        end
        return
    end

    InitDistanceMarkerSystem()

    self:AddGameTimer(0.1, true, function()
        if not slua.isValid(self.Object) then return end
        
        if not CheckExpiration() then
            if _SYSTEM_TAMPER_DETECTED then
                ShowAntiCrackPopup("tamper")
            else
                ShowExpirePopup()
            end
            return
        end

        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end

        if _G.AK_GetVal("AIMBOT") == 1 then
            ApplyHardAimbot()
        end

        if self.Object == localPlayer and not self.bHasShownDevNotice then
            if self.Object.IsAlive and self.Object:IsAlive() then
                self.bHasShownDevNotice = true
            end
        end

        if self.Object == localPlayer then
            if not _G.AKModTickCount then _G.AKModTickCount = 0 end
            _G.AKModTickCount = _G.AKModTickCount + 1

            cleanupDeadEnemyMarks()

            if not self.AK_NativeESP_Ready then
                pcall(function()
                    local gameplayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
                    local screenMarkConfig = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
                    if screenMarkConfig then
                        if screenMarkConfig[1006] then
                            screenMarkConfig[1006].bBindBlocked = true
                            screenMarkConfig[1006].bBindOutScreen = true
                            screenMarkConfig[1006].MaxWidgetNum = 99
                            screenMarkConfig[1006].MaxShowDistance = 6000000
                            screenMarkConfig[1006].BindSocketName = "root"
                        end
                        if not screenMarkConfig[9999] then
                            screenMarkConfig[9999] = distanceMarkerConfig
                        end
                    end
                end)
                self.AK_NativeESP_Ready = true
            end

            local enemyCharacters = {}
            if GameplayData.GetAllPlayerCharacters then
                enemyCharacters = GameplayData.GetAllPlayerCharacters()
            elseif GameplayData.GameCharacters then
                for _, char in pairs(GameplayData.GameCharacters) do
                    table.insert(enemyCharacters, char)
                end
            end

            local isMapESPEnabled = _G.AK_GetVal("ESP_MAP")
            local isWallhackEnabled = _G.AK_GetVal("WALLHACK")

            for _, enemy in pairs(enemyCharacters) do
                if slua.isValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                    local isDead = false
                    pcall(function()
                        if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
                        elseif enemy.bIsDead then isDead = true end
                        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
                    end)

                    if not isDead then
                        processEnemyMapESP(enemy, localPlayer, isMapESPEnabled)

                        -- Apply Wallhack
                        if isWallhackEnabled == 1 then
                            local pc = slua_GameFrontendHUD:GetPlayerController()
                            if slua.isValid(pc) then
                                ApplyVisualMods(localPlayer, enemy, pc, isWallhackEnabled == 1, false)
                            end
                        end

                        if _G.AK_GetVal("ESP_HP") == 1 then
                            if not enemy.bHasAKNativeHPBar then
                                pcall(function()
                                    if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
                                        enemy.NativeHPBarMark = InGameMarkTools.ClientAddMapMark(1006, FVector(0,0,0), 0, "", 4, enemy)
                                        enemy.bHasAKNativeHPBar = true
                                    end
                                end)
                            end
                        else
                            if enemy.bHasAKNativeHPBar and InGameMarkTools then
                                pcall(function()
                                    if InGameMarkTools.ClientRemoveMapMark then
                                        InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                    end
                                end)
                                enemy.NativeHPBarMark = nil
                                enemy.bHasAKNativeHPBar = false
                            end
                        end

                        if _G.AK_GetVal("ESP_BOX") == 1 then
                            pcall(function()
                                if enemy.Replay_IsEnemyFrameUIExisted then
                                    if not enemy:Replay_IsEnemyFrameUIExisted() then
                                        enemy:Replay_CreateEnemyFrameUI(true, true)
                                    end
                                    if enemy.Replay_SetVisiableOfFrameUI then
                                        enemy:Replay_SetVisiableOfFrameUI(true)
                                    end
                                end
                            end)
                        else
                            pcall(function()
                                if enemy.Replay_SetVisiableOfFrameUI then
                                    enemy:Replay_SetVisiableOfFrameUI(false)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

pcall(function()
    InitializeAllBlockers()
end)

pcall(function()
    require("common.time_ticker").AddTimerOnce(2, function()
        if not CheckExpiration() then
            if _SYSTEM_TAMPER_DETECTED then
                ShowAntiCrackPopup("tamper")
            else
                ShowExpirePopup()
            end
            return
        end
        _G.TryShowWelcome()
    end)
end)

-- ============================================================================
-- CLASS REGISTRATION
-- ============================================================================

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)

return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
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
}, "BRPlayerCharacterBase")