local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {}
}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Bool
  }
}

do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._MOD_LOADED and _G._MOD_PC == pc then return end
    _G._MOD_LOADED = true
    _G._MOD_PC = pc
end

_G.nhhaiConfig = _G.nhhaiConfig or {
    EnableAutoAim = false,
    EnableMagicbullet =false,
    AimbotStrength = 50,
    Aimbot_Fov = 50,
    EnableEsp = false,
    EnableVisColor = false,
    AutoAimBone = "Head",
    AimingLevel = "LOW",
    ShowHP = false,
    ShowName = false,
    ShowDist = false,
    Skeleton = false,
    FPS165_Enabled = false,
    NoGrass_Enabled = false,
    iPadView_Enabled = false,
    Blacksky = false,
    MagicHead = 40,
    MagicBody = 40,
    MagicLess = 40,
    iPadViewDistance = 90,
}

_G.nhhaiState = _G.nhhaiState or {}


local require = require
local import  = import
local isValid = slua.isValid

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

-- ==================== ESP ==================== 
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")

local cachedPawns     = {}
local lastPawnRefresh = 0

local function IsPawnAlive(p)
    if not isValid(p) then return false end
    if p.HealthStatus then return SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    if p.IsAlive then return p:IsAlive() end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end

local function GetEnemyPoseOffset(enemy)
    local pose = 0
    if enemy.PoseState then pose = enemy.PoseState
    elseif enemy.GetPoseState then pose = enemy:GetPoseState() end
    if pose == 1 then return -30, 50 -- Ngồi
    elseif pose == 2 then return -60, 20 -- Nằm
    end
    return 0, 80 -- Đứng
end

local function GetNameFontSize(distM)
    local maxDist = 350
    if distM >= maxDist then return 0.38 end
    local t = (distM / maxDist)
    return 1.0 - (0.62 * t * t)
end

local boneList = {"head","neck_01","spine_01","spine_02","spine_03","pelvis",
    "upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","hand_l","hand_r",
    "calf_l","calf_r","foot_l","foot_r"}
local function TextScale(distM)
    local t = math.min(distM / 400, 1)
    return 0.35 - t * 0.2
end

local function HPBar(pct)
    local n = math.floor((pct * 4) + 0.5)
    local s = ""
    for i = 1, 4 do s = s .. (i <= n and "▁" or " ") end
    return s
end

local function ESPTick()
    if not _G.CheatsEnabled then return end
    if _G.nhhaiConfig.EnableEsp == false then return end
    if _G._ESPTimerHandle and _G._ESPTimerChar and not isValid(_G._ESPTimerChar) then _G._ESPTimerHandle = nil; _G._ESPTimerChar = nil end
    local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local currentPawn = uCon:GetCurPawn()
    if not isValid(currentPawn) then return end

    local myTeamId = 0
    pcall(function()
        local char = uCon:GetPlayerCharacterSafety()
        if isValid(char) and char.TeamID then myTeamId = char.TeamID
        elseif currentPawn.TeamID then myTeamId = currentPawn.TeamID end
    end)
    local myPos = nil
    pcall(function() myPos = currentPawn:K2_GetActorLocation() end)
    if not myPos then return end
    local myEyePos = myPos
    pcall(function()
        if currentPawn.GetHeadLocation then myEyePos = currentPawn:GetHeadLocation(false) or myPos end
    end)
    HUD = uCon:GetHUD()
    local now      = os.clock()

    if now - lastPawnRefresh > 1.0 then
        lastPawnRefresh = now
        cachedPawns = Game:GetAllPlayerPawns() or {}
    end

    local botCount = 0
    local playerCount = 0

    local totalAlive = 0
    for _, p in pairs(cachedPawns) do
        if isValid(p) and p ~= currentPawn and p.TeamID ~= myTeamId and IsPawnAlive(p) then
            totalAlive = totalAlive + 1
        end
    end
    local crowded = totalAlive > 20

    for _, tPawn in pairs(cachedPawns) do
        if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
            if IsPawnAlive(tPawn) then
                local enemyPos = tPawn:K2_GetActorLocation()
                local dx = enemyPos.X - myPos.X
                local dy = enemyPos.Y - myPos.Y
                local dz = enemyPos.Z - myPos.Z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                local isBot = false
                pcall(function() isBot = Game:IsAI(tPawn) end)
                if isBot then botCount = botCount + 1 else playerCount = playerCount + 1 end

                if dist < 600000 and HUD then
                    local name = tPawn.PlayerName or "UNKNOWN"
                    local distM = dist / 100

                    -- [Logic tính toán HP giữ nguyên]
                    local hp = tPawn.Health
                    local maxHp = tPawn.HealthMax
                    local isKnock = false
                    local hpPercent = 0
                    if not hp or not maxHp or maxHp <= 0 then
                        isKnock = true
                    elseif hp <= 0 then
                        isKnock = true
                    else
                        hpPercent = hp / maxHp
                    end
                    
                    local hpColor = {R=0,G=255,B=0,A=255}
                    if hpPercent < 0.3 then hpColor = {R=255,G=0,B=0,A=255}
                    elseif hpPercent < 0.7 then hpColor = {R=255,G=255,B=0,A=255} end
                    if isKnock then hpColor = {R=255,G=0,B=0,A=255} end

                    -- [Logic tính toán Bone/Vị trí giữ nguyên]
                    local bones = {}
                    local mesh = tPawn.Mesh
                    if isValid(mesh) then
                        for _, bn in ipairs(boneList) do bones[bn] = mesh:GetSocketLocation(bn) end
                    end
                    local origin = enemyPos
                    local oz = origin.Z
                    local headPos = bones["head"]
                    local headZ = headPos and (headPos.Z - oz) or 90
                    local hpOffset = headZ + 70 + math.min(distM, 60) * 3 + math.max(0, distM - 60) * 0.5
                    local nameOffset = -80 - math.min(distM, 60) * 0.33 - math.max(0, distM - 60) * 0.1

                    ---------------------------------------------------------
                    -- 1. VẼ CHẤM TRÒN (HEAD DOT) - LUÔN HIỆN KHI BẬT ESP
                    ---------------------------------------------------------
                    local hz = headPos and (headPos.Z - oz + 15)
                    if hz then
                        local headChar = (crowded) and "●" or (distM <= 25 and "❄" or "●")
                        HUD:AddDebugText(headChar, tPawn, TextScale(distM), {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true)
                    end

                    if _G.nhhaiConfig.Skeleton then
                        local headLoc = tPawn:GetHeadLocation(false) or enemyPos
                        local isVisible = Game:IsTargetPosVisible(myEyePos, headLoc, {player})
                        local color = isVisible and {R=0,G=255,B=0,A=255} or {R=255,G=0,B=0,A=255}
                        
                        local fSize = GetNameFontSize(distM)

    -- 1. Lấy Mesh của kẻ địch để truy xuất tọa độ xương
                        local mesh = tPawn.Mesh or (tPawn.getAvatarComponent2 and tPawn:getAvatarComponent2())
    
                        if slua.isValid(mesh) then
                            -- Danh sách xương bạn đã khai báo trước đó
                            local boneList = {
                                "head", "neck_01", "spine_01", "spine_02", "spine_03", "pelvis",
                                "upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r", "hand_l", "hand_r",
                                "calf_l", "calf_r", "foot_l", "foot_r"
                            }

                            -- 2. Duyệt qua từng xương để vẽ chấm tròn "●" lên HUD
                            for _, boneName in ipairs(boneList) do
                                local boneLocation = nil
            
            -- Thử lấy tọa độ bằng GetBoneLocation hoặc GetSocketLocation tùy framework game
                                pcall(function()
                                    if mesh.GetBoneLocation then
                                        boneLocation = mesh:GetBoneLocation(boneName)
                                    elseif mesh.GetSocketLocation then
                                        boneLocation = mesh:GetSocketLocation(boneName)
                                    end
                                end)

            -- Nếu tìm thấy tọa độ xương hợp lệ thì vẽ lên màn hình
                                if boneLocation then
                                    pcall(function()
                                        HUD:AddDebugText("●", tPawn, 1, boneLocation, boneLocation, color, true, false, true, nil, fSize - 2, true)
                                    end)
                                end
                            end
                        end
                    end

                    ---------------------------------------------------------
                    -- 2. VẼ THANH MÁU (HP) - TÁCH RIÊNG
                    ---------------------------------------------------------
                    if _G.nhhaiConfig.ShowHP then
                        local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                        HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)
                    end

                    ---------------------------------------------------------
                    -- 3. VẼ TÊN VÀ KHOẢNG CÁCH - TÁCH RIÊNG
                    ---------------------------------------------------------
                    if crowded then
                        _G.nhhaiConfig.ShowHP = false
                    else
                        -- Xử lý chuỗi hiển thị dựa trên nút bật/tắt
                        local finalStr = ""
                        local namePart = _G.nhhaiConfig.ShowName and name or ""
                        local distPart = _G.nhhaiConfig.ShowDist and string.format("[%.0fm]", distM) or ""

                        if namePart ~= "" and distPart ~= "" then
                            finalStr = distPart .. " " .. namePart
                        else
                            finalStr = distPart .. namePart -- Một trong hai cái trống
                        end
                        -- Chỉ vẽ nếu có ít nhất 1 trong 2 cái được bật
                        if finalStr ~= "" then
                            local nameColor = {R=0,G=255,B=0,A=255}
                            local targetPos = headPos or tPawn:K2_GetActorLocation()
                            pcall(function()
                                if _G.nhhaiConfig.EnableVisColor then
                                    if Game:IsTargetPosVisible(myEyePos, targetPos, {currentPawn}) then
                                        nameColor = {R=0,G=255,B=0,A=255} -- Nhìn thấy (Xanh)
                                    else
                                        nameColor = {R=255,G=0,B=0,A=255} -- Bị che (Đỏ)
                                    end
                                else
                                    nameColor = {R=255, G=255, B=255, A=255}
                                end
                            end)

                            HUD:AddDebugText(finalStr, tPawn, TextScale(distM), {X=0,Y=0,Z=nameOffset}, {X=0,Y=0,Z=nameOffset}, nameColor, true, false, true, nil, 1.0, true)
                        end
                    end
                end
            end
        end
    end
    if totalAlive > 0 then
        if not crowded and HUD and currentPawn then
            HUD:AddDebugText(string.format("BOT : %d     PLAYER : %d", botCount, playerCount), currentPawn, 1, {X=0,Y=0,Z=170}, {X=0,Y=0,Z=170}, {R=255,G=255,B=255,A=255}, true, false, true, nil, 1.0, true)
            HUD:AddDebugText("Anh Hai Dep Trai", currentPawn, 1, {X=0,Y=0,Z=145}, {X=0,Y=0,Z=145}, {R=255,G=200,B=0,A=255}, true, false, true, nil, 1.0, true)
        end
    end
end

pcall(function()
    if _G._ESPWatchdogHandle then pcall(function() Game:ClearTimer(_G._ESPWatchdogHandle) end); _G._ESPWatchdogHandle = nil end

    local function StartESP(targetActor)
        if not isValid(targetActor) then return end
        cachedPawns = {}; lastPawnRefresh = 0
        _G._ESPTimerChar = targetActor
        _G._ESPTimerHandle = targetActor:AddGameTimer(0.15, true, function()
            pcall(ESPTick)
        end)
    end

    local function Watchdog()
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            local curPawn = pc and pc:GetCurPawn()
            if isValid(curPawn) and _G._ESPTimerChar ~= curPawn then
                if _G._ESPTimerHandle and isValid(_G._ESPTimerChar) then
                    pcall(function() _G._ESPTimerChar:RemoveGameTimer(_G._ESPTimerHandle) end)
                end
                _G._ESPTimerHandle = nil
                StartESP(curPawn)
            elseif not _G._ESPTimerHandle then
                StartESP(curPawn)
            end
        end)
    end

    _G._ESPWatchdogHandle = Game:SetTimer(1.0, true, Watchdog)
    Watchdog()
end)

-- ==================== AIMBOT + FEATURES ====================
_G.Enable165FPSLogic = function()
  pcall(function()
    local graphics = require("client.slua.logic.setting.logic_setting_graphics")
    if graphics then
      local orig = graphics.SetFPS
      function graphics:SetFPS(lvl)
        if orig then orig(self, lvl) end
        if lvl == 8 and _G.nhhaiConfig.FPS165_Enabled ~= false then 
          self:ExecuteCMD("t.MaxFPS", "165")
          self:ExecuteCMD("r.FrameRateLimit", "165")
        end
      end
    end
    local fpsComp = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    if fpsComp and fpsComp.__inner_impl then
      local impl = fpsComp.__inner_impl
      function impl.GetMaxFPSLevel() return 8, 8 end
      function impl:InitRealSupportFPS()
        local t = {}; for i = 1, 8 do t[i] = {true, true} end
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if db then db:UpdateUIData(db.RealSupportFPS, t, false) end
        return t
      end
      function impl:UpdateSelectedFPSState(lvl)
        local fps = {[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120}
        for i = 2, 8 do
          local node = self.UIRoot["NodeFps"..tostring(fps[i] or 120)]
          if isValid(node) then
            node:SetIsEnabled(true); pcall(function() node:SetRenderOpacity(1.0) end)
            local sw = self.UIRoot["WidgetSwitcher_"..tostring(i)]
            if isValid(sw) then sw:SetActiveWidgetIndex(i == lvl and 0 or 1) end
          end
        end
      end
    end
    local fpsFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    if fpsFT and fpsFT.__inner_impl then
      local impl = fpsFT.__inner_impl; local MIN = 90
      function impl:ShowOrHide() self:SelfHitTestInvisible(); if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end end
      function impl:InitFPSFTSwitch()
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"); local on = db:GetUIData(db.FPSFineTuneSwitch)
        if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true) end
        if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, on) end
        if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
        if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
      end
      function impl:InitFPSFTValue165()
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"); local r = self.UIRoot
        local on = db:GetUIData(db.FPSFineTuneSwitch); local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
        if on then
          r.Slider_screen3:SetLocked(false); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,1,1,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,1,1,1))
        else
          r.Slider_screen3:SetLocked(true); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,0.625,0.6,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,0.625,0.6,1))
        end
        local norm = (val - MIN) / (165 - MIN)
        r.Veihclescreen3:SetText(tostring(val)); r.Slider_screen3:SetValue(norm); r.ProgressBar_screen3:SetPercent(norm)
      end
      function impl:OnFPSFTValueChange3(val)
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        db:UpdateUIData(db.FPSFineTuneNum, val); if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
        if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
        local gi = db.GetGameInstance and db.GetGameInstance()
        if gi then gi:ExecuteCMD("t.MaxFPS", tostring(val)); gi:ExecuteCMD("r.FrameRateLimit", tostring(val)) end
      end
      function impl:OnFPSFTAdd3() local cur = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB").GetUIData(db.FPSFineTuneNum) or 90; self:OnFPSFTValueChange3(math.min(165, cur)) end
      function impl:OnFPSFTMinus3() local cur = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB").GetUIData(db.FPSFineTuneNum) or 90; self:OnFPSFTValueChange3(math.max(MIN, 5)) end
      impl.OnFPSFTAdd = impl.OnFPSFTAdd3; impl.OnFPSFTMinus = impl.OnFPSFTMinus3
    end
  end)
end

_G.EnableiPadViewUI = function()
  pcall(function()
    local sc = require("client.logic.setting.setting_config")
    if sc then
      if sc.TpViewValue then sc.TpViewValue.max = 90 end
      if sc.FpViewValue then sc.FpViewValue.max = 90 end
    end
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    if db and db.TpViewValue then db.TpViewValue.max = 90 end
  end)
end

if _G.nhhaiConfig.FPS165_Enabled ~= false then _G.Enable165FPSLogic() end
if _G.nhhaiConfig.iPadView_Enabled ~= false then _G.EnableiPadViewUI() end

local pc = slua_GameFrontendHUD:GetPlayerController()
if isValid(pc) and pc.AddGameTimer and pc ~= _G._FeaturesTimerPC then
  _G._FeaturesTimerPC = pc
  local SubsystemMgr = nil
  pc:AddGameTimer(0.1, true, function()
    pcall(function()
      if not _G.CheatsEnabled then return end
      local pc = slua_GameFrontendHUD:GetPlayerController()
      if not isValid(pc) then return end
      local char = pc:GetPlayerCharacterSafety()
      if not isValid(char) then return end
      local lp = GameplayData.GetPlayerCharacter()
      if not isValid(lp) then return end
      local isEnemy = lp.TeamID ~= char.TeamID

      SubsystemMgr = SubsystemMgr or package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"] or require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
      if SubsystemMgr then
        local SettingSubsystem = SubsystemMgr:Get("SettingSubsystem")
        if SettingSubsystem then
          -- Use mod slider value if enabled, otherwise use game's setting
          local rawSliderValue = _G.nhhaiConfig.iPadViewDistance or (SettingSubsystem:GetUserSettings_Int("TpViewValue") or 90)
          local targetTPP = rawSliderValue
          if rawSliderValue > 80 and rawSliderValue <= 90 then
              targetTPP = 80 + (rawSliderValue - 80) * 6.0
          elseif rawSliderValue > 90 then
              targetTPP = rawSliderValue
          end
          if _G.nhhaiConfig.iPadView_Enabled ~= false then
            local uTPPCam = char.ThirdPersonCameraComponent
            if isValid(uTPPCam) and not char.bIsWeaponAiming then
                if uTPPCam.FieldOfView ~= targetTPP then
                    uTPPCam.FieldOfView = targetTPP
                end
            end
          end
        end
      end

      local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
      if not gi then
        local SettingUtil = require("client.slua.logic.setting.setting_util")
        gi = SettingUtil and SettingUtil.GetGameInstance()
      end
      if gi then
        if _G.nhhaiConfig.NoGrass_Enabled ~= false then
          gi:ExecuteCMD("grass.DensityScale", "0")
          gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
        end
      end
      
      
      _G.BlackSky = function()
          local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
          local gi = logic_setting_graphics.GetGameInstance()
          if not gi then return end

          if _G.._G.nhhaiConfig.BlackSky then
              gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
          else
              gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0")
          end
      end

      pcall(function()
        if _G.nhhaiConfig.EnableMagicbullet then
            local allChars = Game:GetAllPlayerPawns() or {}
            for _, c in pairs(allChars) do
              if isValid(c) and c ~= char and c.TeamID ~= char.TeamID then
                local mesh = c.Mesh
                if isValid(mesh) then
                  local physAsset = mesh.PhysicsAssetOverride
                  if not isValid(physAsset) and isValid(mesh.SkeletalMesh) then
                    physAsset = mesh.SkeletalMesh.PhysicsAsset
                  end
                  if isValid(physAsset) and physAsset.SkeletalBodySetups then
                    _G._MBones = _G._MBones or {}
                    local assetName = (physAsset.GetName and physAsset:GetName()) or tostring(physAsset)
                    if not _G._MBones[assetName] then
                      local nhMagicSTHead = 1 + _G.nhhaiConfig.MagicHead
                      local nhMagicSTBody = 1 + _G.nhhaiConfig.MagicBody
                      local nhMagicSTLess = 1 + _G.nhhaiConfig.MagicLess

                      local mb = {
                        ["head"]=nhMagicSTHead, ["neck_01"]=nhMagicSTHead, ["pelvis"]=nhMagicSTBody,
                        ["spine_01"]=nhMagicSTBody, ["spine_02"]=nhMagicSTBody, ["spine_03"]=nhMagicSTBody,
                        ["upperarm_l"]=nhMagicSTBody, ["upperarm_r"]=nhMagicSTBody,
                        ["lowerarm_l"]=nhMagicSTBody, ["lowerarm_r"]=nhMagicSTBody,
                        ["hand_l"]=nhMagicSTBody, ["hand_r"]=nhMagicSTBody,
                        ["thigh_l"]=nhMagicSTLess, ["thigh_r"]=nhMagicSTLess,
                        ["calf_l"]=nhMagicSTLess, ["calf_r"]=nhMagicSTLess,
                        ["foot_l"]=nhMagicSTLess, ["foot_r"]=nhMagicSTLess,
                      }
                      local setups = physAsset.SkeletalBodySetups
                      for i = 1, 80 do
                        local bs = nil
                        pcall(function() bs = (type(setups.Get)=="function") and setups:Get(i-1) or setups[i] end)
                        if not bs or not isValid(bs) then break end
                        local bn = tostring(bs.BoneName):lower()
                        local pct = nil
                        for pat, val in pairs(mb) do
                          if string.find(bn, pat) then pct = val; break end
                        end
                        if pct then
                          local sc = 1.0 + pct/100.0
                          local ag = bs.AggGeom
                          pcall(function()
                            local bx = (ag and ag.BoxElems) or bs.BoxElems
                            if bx then
                              local b = (type(bx.Get)=="function") and bx:Get(0) or bx[1]
                              if b then
                                b.X = (b.X or 30)*sc; b.Y = (b.Y or 30)*sc; b.Z = (b.Z or 60)*sc
                                if type(bx.Set)=="function" then bx:Set(0,b) else bx[1]=b end
                                if ag then bs.AggGeom=ag else bs.BoxElems=bx end
                              end
                            end
                          end)
                          pcall(function()
                            local sp = (ag and ag.SphylElems) or bs.SphylElems
                            if sp then
                              local s = (type(sp.Get)=="function") and sp:Get(0) or sp[1]
                              if s then
                                if s.Radius then s.Radius=s.Radius*sc end
                                if s.Length then s.Length=s.Length*sc end
                                if type(sp.Set)=="function" then sp:Set(0,s) else sp[1]=s end
                                if ag then bs.AggGeom=ag else bs.SphylElems=sp end
                              end
                            end
                          end)
                          pcall(function()
                            local sr = (ag and ag.SphereElems) or bs.SphereElems
                            if sr then
                              local r = (type(sr.Get)=="function") and sr:Get(0) or sr[1]
                              if r and r.Radius then
                                r.Radius=r.Radius*sc
                                if type(sr.Set)=="function" then sr:Set(0,r) else sr[1]=r end
                                if ag then bs.AggGeom=ag else bs.SphereElems=sr end
                              end
                            end
                          end)
                        end
                      end
                      _G._MBones[assetName] = true
                      if mesh.RecreatePhysicsState then mesh:RecreatePhysicsState() end
                    end
                  end
                end
              end
            end
        end
      end)
    end)
  end)
end

_G._AimbotCurrentPC = nil

local function ApplyHardAimbot()
    if not _G.CheatsEnabled then return end
    if _G.nhhaiConfig.EnableAutoAim == false then return end
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) then return end
        
        local weaponManager = char:GetWeaponManagerComponent()
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        if _G.nhhaiConfig.EnableAutoAim then
            local speed_aimbot = _G.nhhaiConfig.AimbotStrength / 10
            local fov_aimbot = _G.nhhaiConfig.Aimbot_Fov / 10
                                    
            local speedScale = 1 + (1 * speed_aimbot)
            local fovScale = 1.5 + (1 * fov_aimbot)
            if shootComp.AutoAimingConfig then
                if shootComp.AutoAimingConfig.OuterRange then
                    shootComp.AutoAimingConfig.OuterRange.Speed = speedScale
                    shootComp.AutoAimingConfig.OuterRange.SpeedRate = speedScale
                    shootComp.AutoAimingConfig.OuterRange.RangeRate = fovScale
                    shootComp.AutoAimingConfig.OuterRange.RangeRateSight = fovScale
                    shootComp.AutoAimingConfig.OuterRange.SpeedRateSight = speedScale
                    shootComp.AutoAimingConfig.OuterRange.CrouchRate = 1.0
                    shootComp.AutoAimingConfig.OuterRange.ProneRate = 1.0
                end
                if shootComp.AutoAimingConfig.InnerRange then
                    shootComp.AutoAimingConfig.InnerRange.Speed = speedScale
                    shootComp.AutoAimingConfig.InnerRange.SpeedRate = speedScale
                    shootComp.AutoAimingConfig.InnerRange.RangeRate = fovScale
                    shootComp.AutoAimingConfig.InnerRange.RangeRateSight = fovScale
                    shootComp.AutoAimingConfig.InnerRange.SpeedRateSight = speedScale
                    shootComp.AutoAimingConfig.InnerRange.CrouchRate = 1.0
                    shootComp.AutoAimingConfig.InnerRange.ProneRate = 1.0
                end
                shootComp.AutoAimingConfig = shootComp.AutoAimingConfig
            end
        end
    end)
end

local function AttachAimbotTimer()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        if pc == _G._AimbotCurrentPC then return end
        _G._AimbotCurrentPC = pc
        if pc.AddGameTimer then
            pc:AddGameTimer(0.1, true, function()
                if not isValid(_G._AimbotCurrentPC) then
                    _G._AimbotCurrentPC = nil
                    return
                end
                ApplyHardAimbot()
            end)
        end
    end)
end

AttachAimbotTimer()

pcall(function()
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(2.0, true, function()
            if not isValid(_G._AimbotCurrentPC) then
                _G._AimbotCurrentPC = nil
                AttachAimbotTimer()
            end
        end)
    end
end)

-- ==================== NH EXTRA BYPASS ====================
pcall(function()
    local function nop() end
    local function retTrue() return true end
    local function retFalse() return false end
    local function retEmpty() return {} end

    _G.InitModMenuTab = function()
        local LocUtil = _G.LocUtil
        if not LocUtil and package.loaded["client.common.LocUtil"] then
            LocUtil = require("client.common.LocUtil")
        end
        
        if LocUtil and not LocUtil._IsModMenuHooked then
            local old_get = LocUtil.GetLocalizeResStr
            LocUtil.GetLocalizeResStr = function(id)
                if type(id) == "string" and not tonumber(id) then
                    return id
                end
                return old_get(id)
            end
            LocUtil._IsModMenuHooked = true
        end

        local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
        local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
        
        if not SettingPageDefine.ModMenu then
            local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
            
            local ModMenuEsp = {
                {
                    Key = "ModMenu_ESP",
                    UI = AliasMap.TitleSwitcher,
                    Text = "Kích Hoạt Esp",
                    ExpandIndex = 0,
                    GetFunc = function() return _G.nhhaiConfig.EnableEsp or false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.EnableEsp = value
                        return true
                    end
                },
                {
                    Key = "ESPHP",
                    UI = AliasMap.Switcher,
                    Text = "Esp Máu",
                    ExpandHandle = "ModMenu_ESP",
                    GetFunc = function() return _G.nhhaiConfig.ShowHP or false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.ShowHP = value
                        return true
                    end
                },
                {
                    Key = "ESPSKELETON",
                    UI = AliasMap.Switcher,
                    Text = "Esp Xương (Bảo Trì)",
                    ExpandHandle = "ModMenu_ESP",
                    GetFunc = function() return _G.nhhaiConfig.Skeleton or false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.Skeleton = value
                        return true
                    end
                },
                {
                    Key = "ESPNAME",
                    UI = AliasMap.Switcher,
                    Text = "Esp Tên",
                    ExpandHandle = "ModMenu_ESP",
                    GetFunc = function() return _G.nhhaiConfig.ShowName or false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.ShowName = value
                        return true
                    end
                },
                {
                    Key = "ESPDISTANCE",
                    UI = AliasMap.Switcher,
                    Text = "Esp Khoảng Cách",
                    ExpandHandle = "ModMenu_ESP",
                    GetFunc = function() return _G.nhhaiConfig.ShowDist or false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.ShowDist = value
                        return true
                    end
                },
                {
                    Key = "ESPCOLOR_VIS",
                    UI = AliasMap.Switcher,
                    Text = "Màu Khi Kẻ Địch Ẩn/Hiện",
                    ExpandHandle = "ModMenu_ESP",
                    Visible = function() return _G.nhhaiConfig.EnableEsp end, -- Chỉ hiện khi bật ESP
                    GetFunc = function() return _G.nhhaiConfig.EnableVisColor or false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.EnableVisColor = value
                        return true
                    end
                }
            }
            local ModMenuAim = {
                {
                    Key = "ModMenu_Aimbot",
                    UI = AliasMap.TitleSwitcher,
                    Text = "Aimbot",
                    ExpandIndex = 0,
                    GetFunc = function() return _G.nhhaiConfig.EnableAutoAim or false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.EnableAutoAim = value
                        return true 
                    end
                },
                {
                    Key = "ModMenu_Bones_Title", 
                    UI = AliasMap.Title, 
                    Text = "Chọn Aim", 
                    ExpandHandle = "ModMenu_Aimbot" 
                },
                {
                    Key = "ModMenu_Aim_Head",
                    UI = AliasMap.Switcher,
                    Text = "Aim Đầu",
                    ExpandHandle = "ModMenu_Aimbot",
                    GetFunc = function() return _G.nhhaiConfig.AutoAimBone == "Head" end,
                    SetFunc = function(c, v) 
                        if v then _G.nhhaiConfig.AutoAimBone = "Head" end
                        return true 
                    end
                },
                {
                    Key = "ModMenu_Aim_Neck",
                    UI = AliasMap.Switcher,
                    Text = "Aim Bụng",
                    ExpandHandle = "ModMenu_Aimbot",
                    GetFunc = function() return _G.nhhaiConfig.AutoAimBone == "neck_01" end,
                    SetFunc = function(c, v) 
                        if v then _G.nhhaiConfig.AutoAimBone = "neck_01" end
                        return true 
                    end
                },
                {
                    Key = "ModMenu_Aim_Pelvis",
                    UI = AliasMap.Switcher,
                    Text = "Aim Chân",
                    ExpandHandle = "ModMenu_Aimbot",
                    GetFunc = function() return _G.nhhaiConfig.AutoAimBone == "pelvis" end,
                    SetFunc = function(c, v) 
                        if v then _G.nhhaiConfig.AutoAimBone = "pelvis" end
                        return true 
                    end
                },
                {
                    Key = "ModMenu_AimbotStrength",
                    UI = AliasMap.Slider,
                    Text = "Tốc Độ Aimbot",
                    Min = 0,
                    Max = 100,
                    Format = "%.0f", -- Dòng này quan trọng: Nó sẽ bỏ % và chỉ hiện số
                    ExpandHandle = "ModMenu_Aimbot",
                    GetFunc = function() 
                        return _G.nhhaiConfig.AimbotStrength or 50
                    end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.AimbotStrength = math.floor(value)
                        return true
                    end
                },
                {
                    Key = "ModMenu_AimbotFov",
                    UI = AliasMap.Slider,
                    Text = "Aimbot Fov",
                    Min = 0,
                    Max = 100,
                    Format = "%.0f", -- Dòng này quan trọng: Nó sẽ bỏ % và chỉ hiện số
                    ExpandHandle = "ModMenu_Aimbot",
                    GetFunc = function() 
                        return _G.nhhaiConfig.Aimbot_Fov or 50
                    end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.Aimbot_Fov = math.floor(value)
                        return true
                    end
                },
                {
                    Key = "ModMenu_MagicBullet",
                    UI = AliasMap.TitleSwitcher,
                    Text = "Magic Bullet",
                    ExpandIndex = 0,
                    GetFunc = function() return _G.nhhaiConfig.EnableMagicbullet or false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.EnableMagicbullet = value
                        return true
                    end
                },
                {
                    Key = "ModMenu_MagicHead",
                    UI = AliasMap.Slider,
                    Text = "Magic Đầu",
                    Min = 0,
                    Max = 100,
                    Format = "%.0f", -- Dòng này quan trọng: Nó sẽ bỏ % và chỉ hiện số
                    ExpandHandle = "ModMenu_MagicBullet",
                    GetFunc = function() 
                        return _G.nhhaiConfig.MagicHead or 40
                    end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.MagicHead = math.floor(value)
                        return true
                    end
                },
                {
                    Key = "ModMenu_MagicBody",
                    UI = AliasMap.Slider,
                    Text = "Magic Thân Trên",
                    Min = 0,
                    Max = 100,
                    Format = "%.0f", -- Dòng này quan trọng: Nó sẽ bỏ % và chỉ hiện số
                    ExpandHandle = "ModMenu_MagicBullet",
                    GetFunc = function() 
                        return _G.nhhaiConfig.MagicBody or 40
                    end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.MagicBody = math.floor(value)
                        return true
                    end
                },
                {
                    Key = "ModMenu_MagicLess",
                    UI = AliasMap.Slider,
                    Text = "Magic Thân Dưới",
                    Min = 0,
                    Max = 100,
                    Format = "%.0f", -- Dòng này quan trọng: Nó sẽ bỏ % và chỉ hiện số
                    ExpandHandle = "ModMenu_MagicBullet",
                    GetFunc = function() 
                        return _G.nhhaiConfig.MagicLess or 40
                    end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.MagicLess = math.floor(value)
                        return true
                    end
                }
            }
            local ModMenuOther = {
                { UI = AliasMap.Title, Text = "SETTING" },
                {
                    Key = "FPS165",
                    UI = AliasMap.TitleSwitcher,
                    Text = "165 FPS",
                    GetFunc = function() return _G.nhhaiConfig.FPS165_Enabled ~= false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.FPS165_Enabled = value
                        if value then _G.Enable165FPSLogic() end
                        return true
                    end
                },
                {
                    Key = "NoGrass",
                    UI = AliasMap.TitleSwitcher,
                    Text = "Xóa Cỏ",
                    GetFunc = function() return _G.nhhaiConfig.NoGrass_Enabled ~= false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.NoGrass_Enabled = value
                        if value then
                            pcall(function()
                                local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
                                if gi then
                                    gi:ExecuteCMD("grass.DensityScale", "0")
                                    gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                                end
                            end)
                        end
                        return true
                    end
                },
                {
                    Key = "Blacksky",
                    UI = AliasMap.TitleSwitcher,
                    Text = "Trời Tối",
                    GetFunc = function() return _G.nhhaiConfig.BlackSky ~= false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.BlackSky = value
                        if value then
                            pcall(function()
                                local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
                                local gi = logic_setting_graphics.GetGameInstance()
                                if gi then 
                                    gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                                else
                                    gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0")
                                end
                            end)
                        end
                        return true
                    end
                },
                {
                    Key = "iPadView",
                    UI = AliasMap.TitleSwitcher,
                    Text = "IPAD VIEW",
                    GetFunc = function() return _G.nhhaiConfig.iPadView_Enabled ~= false end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.iPadView_Enabled = value
                        if value then _G.EnableiPadViewUI() end
                        return true
                    end
                },
                {
                    Key = "iPadFOV",
                    UI = AliasMap.Slider,
                    Text = "iPad View",
                    Min = 90,
                    Max = 150,
                    Format = "%.0f", -- Dòng này quan trọng: Nó sẽ bỏ % và chỉ hiện số
                    GetFunc = function() 
                        return _G.nhhaiConfig.iPadViewDistance or 90
                    end,
                    SetFunc = function(_, value)
                        _G.nhhaiConfig.iPadViewDistance = math.floor(value)
                        return true
                    end
                }
            }
            SettingPageDefine.ModMenu = {
                Key = "ModMenu",
                loc = "NHU HAI MOD",
                UIKey = "Setting_Page_Privacy", 
                Category = {
                    { Key = "ModMenu_Main", loc = "Esp", Stack = ModMenuEsp },
                    { Key = "ModMenu_Aim", loc = "Aim", Stack = ModMenuAim },
                    { Key = "ModMenu_Other",loc = "Khác", Stack = ModMenuOther }
                }
            }
            
            table.insert(SettingCatalog, SettingPageDefine.ModMenu)
        end

        local UIManager = _G.UIManager
        if UIManager and not UIManager._IsModMenuHooked then
            local old_ShowUI = UIManager.ShowUI
            UIManager.ShowUI = function(config, ...)
                local args = {...}
                if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                    local catalog = args[1]
                    if catalog and (type(catalog) == "table" or type(catalog) == "userdata") then
                        local hasModMenu = false
                        local newCatalog = {}
                        for _, page in ipairs(catalog) do
                            table.insert(newCatalog, page)
                            if page.Key == "ModMenu" then
                                hasModMenu = true
                            end
                        end
                        
                        if not hasModMenu then
                            table.insert(newCatalog, SettingPageDefine.ModMenu)
                            args[1] = newCatalog
                        end
                    end
                end
                local table_unpack = table.unpack or unpack
                return old_ShowUI(config, table_unpack(args))
            end
            UIManager._IsModMenuHooked = true
        end
    end
    
    local bypassInit = function()
        pcall(function()
            _G.InitModMenuTab()
            _G.TryShowLegalCredit()
            _G.TryBypassMD5()
            _G.BypassCacheMD5()
            _G.BypassSecurityUtils()
            _G.BypassHiggsComponent()
        end)
    end

    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(3.0, false, bypassInit)
    else
        bypassInit()
    end
end)