-- THIS FILE IS DECOMPILED USING @ OFFICIAL_NADEEM896211 TOOL
-- JOIN OVER TELEGRAM CHANNEL @ASSET_FINDER



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

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local KismetMathLibrary = import("KismetMathLibrary")
local GameplayStatics = import("GameplayStatics")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")

local currentTime = os.time(os.date("!*t"))
local expirationTime = os.time({ year = 2028, month = 5, day = 15, hour = 6, min = 45, sec = 0 })

if currentTime <= expirationTime then
    local LogicSettingGraphics = package.loaded["client.slua.logic.setting.logic_setting_graphics"] or require("client.slua.logic.setting.logic_setting_graphics")
    local GSC_FPS = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS"] or require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    local GSC_FPSFT = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT"] or require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    local GraphicSettingDB = package.loaded["client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"] or require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")

    if LogicSettingGraphics then
        local OriginalSetFPS = LogicSettingGraphics.SetFPS
        function LogicSettingGraphics.SetFPS(gameInstance, FPSLevel)
            if FPSLevel == 8 and GraphicSettingDB then
                local FPSFineTuneSwitchVal = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                if not FPSFineTuneSwitchVal then 
                    GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneSwitch, true) 
                end
            end
            if OriginalSetFPS then 
                OriginalSetFPS(gameInstance, FPSLevel) 
            end
            if FPSLevel == 8 and GraphicSettingDB then
                GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, 165)
                gameInstance:ExecuteCMD("t.MaxFPS", "165")
                gameInstance:ExecuteCMD("r.FrameRateLimit", "165")
            end
        end
    end

    if GSC_FPS and GSC_FPS.__inner_impl then
        local GSC_FPS_impl = GSC_FPS.__inner_impl
        function GSC_FPS_impl:GetMaxFPSLevel() return 8, 8 end
        function GSC_FPS_impl:CanChangeQualityAndFPSPreCheck() return true end
        function GSC_FPS_impl:InitRealSupportFPS()
            local fpsSupportList = {}
            for i = 1, 8 do fpsSupportList[i] = {true, true} end
            if GraphicSettingDB then GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, fpsSupportList, false) end
            return fpsSupportList
        end
        function GSC_FPS_impl:SetFPSAndQualityEnable(bEnable)
            if self.UIRoot and self.UIRoot.Image_Mask then self:SetWidgetVisible(self.UIRoot.Image_Mask, false) end
        end
        function GSC_FPS_impl:UpdateSelectedFPSState(selectedLevel)
            local fpsNodeNameMap = { [2]="NodeFps20", [3]="NodeFps25", [4]="NodeFps30", [5]="NodeFps40", [6]="NodeFps60", [7]="NodeFps90", [8]="NodeFps120" }
            if not self.UIRoot then return end
            for level, name in pairs(fpsNodeNameMap) do
                if self.UIRoot[name] then
                    self:WidgetSelfHit(self.UIRoot[name])
                    self.UIRoot[name]:SetIsEnabled(true)
                    local fpsSwitcherWidget = self.UIRoot["WidgetSwitcher_" .. level]
                    if fpsSwitcherWidget then fpsSwitcherWidget:SetActiveWidgetIndex(level == selectedLevel and 0 or 1) end
                end
            end
        end
        local OriginalUpdateUI = GSC_FPS_impl.UpdateUI
        function GSC_FPS_impl:UpdateUI()
            if OriginalUpdateUI then pcall(OriginalUpdateUI, self) end
            self:SelfHitTestInvisible()
            self:InitRealSupportFPS()
            self:SetFPSAndQualityEnable(true)
            local selectedFPSLevel = 8
            if GraphicSettingDB then
                if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab) == 2 then
                    selectedFPSLevel = GraphicSettingDB:GetUIData(GraphicSettingDB.LobbyFPS) or 8
                else
                    selectedFPSLevel = GraphicSettingDB:GetUIData(GraphicSettingDB.SelectedFPS) or 8
                end
            end
            self:UpdateSelectedFPSState(selectedFPSLevel)
        end
        function GSC_FPS_impl:DoClickFPS(FPSLevel)
            if slua.isValid(self.UIRoot) then
                if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab) == 2 then
                    GraphicSettingDB:UpdateUIData(GraphicSettingDB.LobbyFPS, FPSLevel)
                else
                    GraphicSettingDB:UpdateSelectedFPS(FPSLevel)
                end
                self:UpdateSelectedFPSState(FPSLevel)
                if self:GetParentUI() then 
                    self:GetParentUI():SaveQualityAndFPS()
                    self:GetParentUI():SetDirty(true) 
                end
            end
        end
    end

    if GSC_FPSFT and GSC_FPSFT.__inner_impl then
        local GSC_FPSFT_impl = GSC_FPSFT.__inner_impl
        local MIN_FPS, FPS_STEP = 90, 5
        local function Clamp(val, min, max) return val < min and min or (val > max and max or val) end
        function GSC_FPSFT_impl:ShowOrHide() 
            self:SelfHitTestInvisible() 
            if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end 
        end
        function GSC_FPSFT_impl:InitFPSFTSwitch()
            local sw = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
            if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(sw, true) end
            if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, sw) end
            if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
            if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
        end
        function GSC_FPSFT_impl:InitFPSFTValue165()
            local uiRoot = self.UIRoot
            local sw = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
            local fpsFineTuneNum = sw and GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165
            uiRoot.Slider_screen3:SetLocked(not sw)
            uiRoot.ProgressBar_screen3:SetFillColorAndOpacity(sw and FLinearColor(1,1,1,1) or FLinearColor(1,0.625,0.6,1))
            local sliderPercent = (fpsFineTuneNum - MIN_FPS) / (165 - MIN_FPS)
            uiRoot.Veihclescreen3:SetText(LocUtil.LocalizeResFormat(10567, fpsFineTuneNum))
            uiRoot.Slider_screen3:SetValue(sliderPercent)
            uiRoot.ProgressBar_screen3:SetPercent(sliderPercent)
        end
        function GSC_FPSFT_impl:OnFPSFTValueChange3(fpsFineTuneNum)
            GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, fpsFineTuneNum)
            self:InitFPSFTValue165()
            if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
            local gameInstance = GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
            if gameInstance then 
                gameInstance:ExecuteCMD("t.MaxFPS", tostring(fpsFineTuneNum))
                gameInstance:ExecuteCMD("r.FrameRateLimit", tostring(fpsFineTuneNum)) 
            end
        end
        function GSC_FPSFT_impl:OnFPSFTSliderValueChange3(value)
            if GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) then
                local fpsFineTuneNum = KismetMathLibrary.FCeil(value * (165 - MIN_FPS) / FPS_STEP) * FPS_STEP + MIN_FPS
                self:OnFPSFTValueChange3(Clamp(fpsFineTuneNum, MIN_FPS, 165))
            end
        end
        function GSC_FPSFT_impl:OnFPSFTAdd3()
            local fpsFineTuneNum = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum)
            if fpsFineTuneNum then self:OnFPSFTValueChange3(math.min(165, fpsFineTuneNum + FPS_STEP)) end
        end
        function GSC_FPSFT_impl:OnFPSFTMinus3()
            local fpsFineTuneNum = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum)
            if fpsFineTuneNum then self:OnFPSFTValueChange3(math.max(MIN_FPS, fpsFineTuneNum - FPS_STEP)) end
        end
        GSC_FPSFT_impl.OnFPSFTAdd = GSC_FPSFT_impl.OnFPSFTAdd3 
        GSC_FPSFT_impl.OnFPSFTMinus = GSC_FPSFT_impl.OnFPSFTMinus3
        GSC_FPSFT_impl.OnFPSFTSliderValueChange = GSC_FPSFT_impl.OnFPSFTSliderValueChange3
    end
end

local iniPaths = {
    '/storage/emulated/0/Android/data/com.tencent.ig/files/AKMOD_MENU.ini',
    '/storage/emulated/0/Android/data/com.pubg.krmobile/files/AKMOD_MENU.ini',
    '/storage/emulated/0/Android/data/com.vng.pubgmobile/files/AKMOD_MENU.ini',
    '/storage/emulated/0/Android/data/com.rekoo.pubgm/files/AKMOD_MENU.ini'
}

function _G.AK_SaveINI()
    for _, path in ipairs(iniPaths) do
        local fileHandle = io.open(path, "w")
        if fileHandle then
            local iniContent = ""
            for _, f in ipairs(_G.AK_Features) do
                iniContent = iniContent .. f.id .. "=" .. tostring(f.val) .. "\n"
            end
            fileHandle:write(iniContent)
            fileHandle:close()
        end
    end
    _G.EnvRequiresUpdate = true
    _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
end

function _G.AK_LoadINI()
    local fileHandle = nil
    for _, path in ipairs(iniPaths) do
        fileHandle = io.open(path, "r")
        if fileHandle then break end
    end
    if fileHandle then
        local iniContent = fileHandle:read("*all")
        fileHandle:close()
        for _, f in ipairs(_G.AK_Features) do
            local matchedValue = string.match(iniContent, f.id .. "=(%d+)")
            if matchedValue then f.val = tonumber(matchedValue) end
        end
    end
end

function _G.AK_GetVal(id)
    if not _G.AK_Features then return 0 end
    for _, f in ipairs(_G.AK_Features) do
        if f.id == id then return f.val end
    end
    return 0
end

function _G.ShowAKMenu()
    if not _G.AK_Features then return end

    local currentFeature = _G.AK_Features[_G.AK_MenuIndex]
    local menuTitle = "AKMODPUBG"
    local menuBody = "MOD LUA PAK FREE CUSTOM ANDROID V5\n[BYPASS UPDATE V4 + MAGIC CUSTOM]\n"
    local statusText = ""
    
    if currentFeature.type == "toggle" then
        statusText = (currentFeature.val == 1) and "BẬT" or "TẮT"
    elseif currentFeature.type == "percent_100" then
        local actionPrefix = currentFeature.action_prefix or "TĂNG"
        statusText = actionPrefix .. " " .. tostring(currentFeature.val / 10) .. "%"
    elseif currentFeature.type == "percent_10" then
        local actionPrefix = currentFeature.action_prefix or "TĂNG"
        statusText = actionPrefix .. " " .. tostring(currentFeature.val) .. "%"
    elseif currentFeature.type == "value_range" then
        statusText = tostring(currentFeature.val)
    end
    
    menuBody = menuBody .. "CHỨC NĂNG ĐANG CHỌN \n[" .. currentFeature.name .. "]\nTRẠNG THÁI [" .. statusText .. "]\n\n"
    
    for i, f in ipairs(_G.AK_Features) do
        local selectorPrefix = (i == _G.AK_MenuIndex) and "▶ " or "   "
        local featureValueText = ""
        if f.type == "toggle" then
            featureValueText = (f.val == 1) and "[BẬT]" or "[TẮT]"
        elseif f.type == "percent_100" then
            featureValueText = "[" .. tostring(f.val / 10) .. "%]"
        elseif f.type == "percent_10" then
            featureValueText = "[" .. tostring(f.val) .. "%]"
        elseif f.type == "value_range" then
            featureValueText = "[" .. tostring(f.val) .. "]"
        end
        menuBody = menuBody .. selectorPrefix .. f.name .. " " .. featureValueText .. "\n"
    end
    
    local confirmButtonText = "CHỌN"
    if currentFeature.type == "toggle" then
        confirmButtonText = "BẬT / TẮT"
    elseif currentFeature.type == "percent_100" or currentFeature.type == "percent_10" then
        local actionPrefix = currentFeature.action_prefix or "TĂNG"
        confirmButtonText = actionPrefix .. " 10%"
    elseif currentFeature.type == "value_range" then
        confirmButtonText = "TĂNG THÊM " .. tostring(currentFeature.step)
    end

    local LogicCommonMsgBox = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
    if LogicCommonMsgBox and LogicCommonMsgBox.Show then
        LogicCommonMsgBox.Show(4, menuTitle, menuBody, 
        function() 
            if currentFeature.type == "toggle" then
                currentFeature.val = 1 - currentFeature.val
            elseif currentFeature.type == "percent_100" then
                currentFeature.val = currentFeature.val + 100
                if currentFeature.val > 1000 then currentFeature.val = 0 end 
            elseif currentFeature.type == "percent_10" then
                currentFeature.val = currentFeature.val + 10
                if currentFeature.val > 100 then currentFeature.val = 0 end 
            elseif currentFeature.type == "value_range" then
                currentFeature.val = currentFeature.val + currentFeature.step
                if currentFeature.val > currentFeature.max then currentFeature.val = currentFeature.min end
            end
            _G.AK_SaveINI()
            _G.ShowAKMenu()
        end, 
        function() 
            _G.AK_MenuIndex = _G.AK_MenuIndex + 1
            if _G.AK_MenuIndex > #_G.AK_Features then
                _G.AK_MenuIndex = 1
            end
            _G.ShowAKMenu()
        end, 
        confirmButtonText, "CHỨC NĂNG KHÁC")
    end
end

function BRPlayerCharacterBase:ctor()
    self.bHasShownDevNotice = false 
    self.bHasShownExpiredNotice = false 
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
    EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
    if Client and GameplayData.RemoveCharacter ~= nil then
        GameplayData.RemoveCharacter(self.Object)
    end
end

function BRPlayerCharacterBase:StartAdvancedSystems()
    if not Client then return end
    
    self:AddGameTimer(0.1, true, function()
        if not slua.isValid(self.Object) then return end
        
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end

        if currentTime > expirationTime then
            if self.Object == localPlayer and not self.bHasShownExpiredNotice then
                if self.Object.IsAlive and self.Object:IsAlive() then
                    self.bHasShownExpiredNotice = true
                    pcall(function()
                        local LogicCommonMsgBox = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
                        if LogicCommonMsgBox and LogicCommonMsgBox.Show then
                            LogicCommonMsgBox.Show(4, "THÔNG BÁO TỪ ADMIN AKMODPUBG", "PHIÊN BẢN MOD CỦA BẠN ĐÃ HẾT HẠN\nVUI LÒNG LIÊN HỆ TELEGRAM @nanamod96 ĐỂ MUA", function() 
                                local KismetSystemLibrary = import("KismetSystemLibrary")
                                if KismetSystemLibrary then KismetSystemLibrary.LaunchURL("https://t.me/nanamod96") end
                            end, function() end, "LIÊN HỆ ADMIN", "HỦY")
                        end
                    end)
                end
            end
            return 
        end

        if self.Object == localPlayer and not self.bHasShownDevNotice then
            if self.Object.IsAlive and self.Object:IsAlive() then
                self.bHasShownDevNotice = true
                
                if not _G.AK_Features then
                    _G.AK_Features = {
                        { id="ESP_HP", name="ESP THANH MÁU", val=0, type="toggle" },
                        { id="ESP_BOX", name="ESP BOX", val=0, type="toggle" },
                        { id="IPAD_VIEW_TPP", name="GÓC NHÌN IPAD TPP", val=90, type="value_range", min=90, max=150, step=5 },
                        { id="IPAD_VIEW_FPP", name="GÓC NHÌN IPAD FPP", val=103, type="value_range", min=103, max=150, step=5 },
                        { id="AIMBOT", name="AIMBOT", val=0, type="toggle" },
                        { id="SPEED_AIMBOT", name="TỐC ĐỘ AIMBOT", val=0, type="percent_10", action_prefix="TĂNG" },
                        { id="FOV_AIMBOT", name="FOV AIMBOT", val=0, type="percent_10", action_prefix="TĂNG" },
                        { id="THU_TAM", name="THU TÂM", val=0, type="percent_10", action_prefix="THU" },
                        { id="GIAM_GIAT_NGANG", name="GIẢM GIẬT NGANG", val=0, type="percent_10", action_prefix="GIẢM" },
                        { id="GIAM_GIAT_DOC", name="GIẢM GIẬT DỌC", val=0, type="percent_10", action_prefix="GIẢM" },
                        { id="GIAM_RUNG_SCOPE", name="GIẢM RUNG SCOPE", val=0, type="percent_10", action_prefix="GIẢM" },
                        { id="MAGIC_HEAD", name="MAGIC ĐẦU", val=0, type="percent_100", action_prefix="TĂNG" },
                        { id="MAGIC_BODY", name="MAGIC THÂN", val=0, type="percent_100", action_prefix="TĂNG" },
                        { id="MAGIC_LEGS", name="MAGIC CHÂN", val=0, type="percent_100", action_prefix="TĂNG" },
                        { id="NOGRASS", name="XÓA CỎ", val=0, type="toggle" },
                        { id="NOTREES", name="XÓA CÂY", val=0, type="toggle" },
                        { id="NOWATER", name="XÓA NƯỚC", val=0, type="toggle" },
                        { id="NOFOG", name="XÓA SƯƠNG MÙ", val=0, type="toggle" },
                        { id="WHITE_BODY", name="NGƯỜI MÀU", val=0, type="toggle" },
                    }
                    _G.AK_MenuIndex = 1
                end

                pcall(function()
                    _G.AK_LoadINI()
                    _G.ShowAKMenu()
                end)
            end
        end

        local ipadViewTPP = _G.AK_GetVal("IPAD_VIEW_TPP")
        if ipadViewTPP == 0 or ipadViewTPP < 90 then ipadViewTPP = 90 end
        
        local ipadViewFPP = _G.AK_GetVal("IPAD_VIEW_FPP")
        if ipadViewFPP == 0 or ipadViewFPP < 103 then ipadViewFPP = 103 end
        
        local thirdPersonCamera = self.Object.ThirdPersonCameraComponent
        local firstPersonCamera = self.Object.FirstPersonCameraComponent
        local isWeaponAiming = self.Object.bIsWeaponAiming or false
        
        if not isWeaponAiming then
            if slua.isValid(thirdPersonCamera) and ipadViewTPP > 90 then 
                thirdPersonCamera:SetFieldOfView(ipadViewTPP)
                thirdPersonCamera.FieldOfView = ipadViewTPP 
            end
            if slua.isValid(firstPersonCamera) and ipadViewFPP > 103 then 
                firstPersonCamera:SetFieldOfView(ipadViewFPP)
                firstPersonCamera.FieldOfView = ipadViewFPP 
            end
        end

        if self.Object.GetCurrentWeapon then
            local currentWeapon = self.Object:GetCurrentWeapon()
            if slua.isValid(currentWeapon) then
                local currentClock = os.clock()
                if self.LastWeaponEntity ~= currentWeapon then
                    self.LastWeaponEntity = currentWeapon
                    self.bForceWeaponMod = true
                end
                
                if not self.LastWeaponModTime or currentClock > self.LastWeaponModTime + 2.0 then
                    self.bForceWeaponMod = true
                    self.LastWeaponModTime = currentClock
                end
                
                if self.bForceWeaponMod or not currentWeapon.bIsAKModded then
                    pcall(function()
                        local shootWeaponEntity = currentWeapon.ShootWeaponEntity_GEN_VARIABLE or currentWeapon.ShootWeaponEntity
                        if slua.isValid(shootWeaponEntity) then
                            local thuTamVal = _G.AK_GetVal("THU_TAM") / 100.0
                            local giamGiatNgangVal = _G.AK_GetVal("GIAM_GIAT_NGANG") / 100.0
                            local giamGiatDocVal = _G.AK_GetVal("GIAM_GIAT_DOC") / 100.0
                            local giamRungScopeVal = _G.AK_GetVal("GIAM_RUNG_SCOPE") / 100.0
                            
                            shootWeaponEntity.GameDeviationFactor = 3.36 - (3.36 * thuTamVal)
                            shootWeaponEntity.AccessoriesHRecoilFactor = 0.80 - (0.80 * giamGiatNgangVal)
                            shootWeaponEntity.AccessoriesVRecoilFactor = 0.50 - (0.50 * giamGiatDocVal)
                            shootWeaponEntity.RecoilKickADS = 0.20 - (0.20 * giamRungScopeVal)

                            if _G.AK_GetVal("AIMBOT") == 1 then
                                if shootWeaponEntity.AutoAimingConfig then
                                    local autoAimingConfig = shootWeaponEntity.AutoAimingConfig
                                    local speedAimbotVal = _G.AK_GetVal("SPEED_AIMBOT") / 100.0
                                    local fovAimbotVal = _G.AK_GetVal("FOV_AIMBOT") / 100.0
                                    
                                    local aimbotSpeed = 3.0 + (3.0 * speedAimbotVal)
                                    local aimbotRange = 1.5 + (1.5 * fovAimbotVal)
                                    
                                    if autoAimingConfig.OuterRange then
                                        autoAimingConfig.OuterRange.Speed = aimbotSpeed
                                        autoAimingConfig.OuterRange.SpeedRate = aimbotSpeed
                                        autoAimingConfig.OuterRange.RangeRate = aimbotRange
                                        autoAimingConfig.OuterRange.RangeRateSight = aimbotRange
                                        autoAimingConfig.OuterRange.SpeedRateSight = aimbotSpeed
                                        autoAimingConfig.OuterRange.CrouchRate = 1.0
                                        autoAimingConfig.OuterRange.ProneRate = 1.0
                                    end
                                    if autoAimingConfig.InnerRange then
                                        autoAimingConfig.InnerRange.Speed = aimbotSpeed
                                        autoAimingConfig.InnerRange.SpeedRate = aimbotSpeed
                                        autoAimingConfig.InnerRange.RangeRate = aimbotRange
                                        autoAimingConfig.InnerRange.RangeRateSight = aimbotRange
                                        autoAimingConfig.InnerRange.SpeedRateSight = aimbotSpeed
                                        autoAimingConfig.InnerRange.CrouchRate = 1.0
                                        autoAimingConfig.InnerRange.ProneRate = 1.0
                                    end
                                    shootWeaponEntity.AutoAimingConfig = autoAimingConfig
                                end
                            end
                        end
                    end)
                    currentWeapon.bIsAKModded = true
                    self.bForceWeaponMod = false
                end
            end
        end

        if self.Object == localPlayer then
            if not _G.AKModTickCount then _G.AKModTickCount = 0 end
            if not _G.MagicUpdateVersion then _G.MagicUpdateVersion = 1 end
            if _G.EnvRequiresUpdate == nil then _G.EnvRequiresUpdate = true end

            _G.AKModTickCount = _G.AKModTickCount + 1

            if _G.AKModTickCount % 50 == 0 then
                pcall(function()
                    local magicHeadVal, magicBodyVal, magicLegsVal = _G.AK_GetVal("MAGIC_HEAD"), _G.AK_GetVal("MAGIC_BODY"), _G.AK_GetVal("MAGIC_LEGS")
                    local noGrassVal, noTreesVal, noWaterVal, noFogVal = _G.AK_GetVal("NOGRASS"), _G.AK_GetVal("NOTREES"), _G.AK_GetVal("NOWATER"), _G.AK_GetVal("NOFOG")
                    local whiteBodyVal = _G.AK_GetVal("WHITE_BODY")
                    
                    _G.AK_LoadINI() 
                    
                    if magicHeadVal ~= _G.AK_GetVal("MAGIC_HEAD") or magicBodyVal ~= _G.AK_GetVal("MAGIC_BODY") or magicLegsVal ~= _G.AK_GetVal("MAGIC_LEGS") then
                        _G.MagicUpdateVersion = _G.MagicUpdateVersion + 1
                    end
                    if noGrassVal ~= _G.AK_GetVal("NOGRASS") or noTreesVal ~= _G.AK_GetVal("NOTREES") or noWaterVal ~= _G.AK_GetVal("NOWATER") or noFogVal ~= _G.AK_GetVal("NOFOG") or whiteBodyVal ~= _G.AK_GetVal("WHITE_BODY") then
                        _G.EnvRequiresUpdate = true
                    end
                end)
            end

            if not self.AK_NativeESP_Ready then
                pcall(function()
                    local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
                    local screenMarkConfig = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
                    
                    if screenMarkConfig then
                        if screenMarkConfig[1006] then
                            screenMarkConfig[1006].bBindBlocked = true     
                            screenMarkConfig[1006].bBindOutScreen = true   
                            screenMarkConfig[1006].MaxWidgetNum = 99
                            screenMarkConfig[1006].MaxShowDistance = 6000000
                            screenMarkConfig[1006].bScaleByDistance = false
                            screenMarkConfig[1006].BindSocketName = "root"
                            screenMarkConfig[1006].bUseLuaWorldSocketName = true
                            screenMarkConfig[1006].WorldPositionOffset = FVector(0, 0, -30)
                        end

                        if not screenMarkConfig[9999] then
                            screenMarkConfig[9999] = {
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
                            local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                            if InGameMarkTools and InGameMarkTools.ScreenMarkManager and InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
                                pcall(function() InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999) end)
                            end
                        end
                    end

                    for k, autoAimingConfig in pairs(package.loaded) do
                        if type(k) == "string" and string.find(k, "ScreenMarkConfig") then
                            if type(autoAimingConfig) == "table" then
                                if autoAimingConfig[1006] then
                                    autoAimingConfig[1006].bBindBlocked = true     
                                    autoAimingConfig[1006].bBindOutScreen = true   
                                    autoAimingConfig[1006].MaxWidgetNum = 99
                                    autoAimingConfig[1006].MaxShowDistance = 6000000
                                    autoAimingConfig[1006].bScaleByDistance = false
                                    autoAimingConfig[1006].BindSocketName = "root"
                                    autoAimingConfig[1006].bUseLuaWorldSocketName = true
                                    autoAimingConfig[1006].WorldPositionOffset = FVector(0, 0, -30)
                                end
                                autoAimingConfig[9999] = {
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
                            end
                        end
                    end

                    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                    local ClientHPBarSubSystem = SubsystemMgr:Get("ClientHPBarSubSystem")
                    if ClientHPBarSubSystem then
                        if ClientHPBarSubSystem.SetPauseCheck then ClientHPBarSubSystem:SetPauseCheck(true) end
                        if ClientHPBarSubSystem.FocusActorCheckParam then
                            ClientHPBarSubSystem.FocusActorCheckParam.CheckBlock = false 
                            ClientHPBarSubSystem.FocusActorCheckParam.CheckDistance = 1000000
                        end
                    end
                    
                    if UIManager and UIManager.GetUI then
                        local EnemyHpWidgetsMainUI = UIManager.GetUI(UIManager.UI_Config_InGame.EnemyHpWidgetsMain)
                        if slua.isValid(EnemyHpWidgetsMainUI) then
                            if EnemyHpWidgetsMainUI.SetCheckBlock then EnemyHpWidgetsMainUI:SetCheckBlock(false) end
                            if EnemyHpWidgetsMainUI.UIRoot and EnemyHpWidgetsMainUI.UIRoot.CanvasPanel_HPBarWidgets then
                                if EnemyHpWidgetsMainUI.UIRoot.CanvasPanel_HPBarWidgets.SetRenderScale then
                                    EnemyHpWidgetsMainUI.UIRoot.CanvasPanel_HPBarWidgets:SetRenderScale(FVector2D(1.5, 1.5))
                                end
                            end
                        end
                    end
                end)
                self.AK_NativeESP_Ready = true
            end

            if _G.EnvRequiresUpdate then
                _G.EnvRequiresUpdate = false 
                pcall(function()
                    local KismetSystemLibrary = import("KismetSystemLibrary")
                    local playerController = GameplayData.GetPlayerController()
                    
                    local function executeCMD(cmdKey, cmdValue)
                        if slua.isValid(KismetSystemLibrary) and slua.isValid(playerController) then
                            KismetSystemLibrary.ExecuteConsoleCommand(playerController, cmdKey .. " " .. cmdValue)
                        end
                        local gameInstance = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
                        if slua.isValid(gameInstance) and gameInstance.ExecuteCMD then gameInstance:ExecuteCMD(cmdKey, cmdValue) end
                    end

                    if slua.isValid(playerController) then
                        if _G.AK_GetVal("NOGRASS") == 1 then executeCMD("r.DisableGrassRender", "1") else executeCMD("r.DisableGrassRender", "0") end
                        if _G.AK_GetVal("NOTREES") == 1 then
                            executeCMD("foliage.DensityScale", "0"); executeCMD("r.Foliage.DensityScale", "0")
                            executeCMD("foliage.MinimumScreenSize", "10000"); executeCMD("r.DisableTreeRender", "1")
                        else
                            executeCMD("foliage.DensityScale", "1"); executeCMD("r.Foliage.DensityScale", "1")
                            executeCMD("foliage.MinimumScreenSize", "0.0001"); executeCMD("r.DisableTreeRender", "0")
                        end
                        if _G.AK_GetVal("NOWATER") == 1 then
                            executeCMD("r.Water.SingleLayer.Enable", "0"); executeCMD("r.Show.Water", "0")
                            executeCMD("r.Show.Translucency", "0"); executeCMD("r.DisableWaterRender", "1")
                        else
                            executeCMD("r.Water.SingleLayer.Enable", "1"); executeCMD("r.Show.Water", "1")
                            executeCMD("r.Show.Translucency", "1"); executeCMD("r.DisableWaterRender", "0")
                        end
                        if _G.AK_GetVal("NOFOG") == 1 then
                            executeCMD("r.SkyAtmosphere", "0"); executeCMD("r.Atmosphere", "0")
                            executeCMD("r.Fog", "0"); executeCMD("r.VolumetricFog", "0"); executeCMD("r.DisableSkyRender", "1")
                        else
                            executeCMD("r.SkyAtmosphere", "1"); executeCMD("r.Atmosphere", "1")
                            executeCMD("r.Fog", "1"); executeCMD("r.VolumetricFog", "1"); executeCMD("r.DisableSkyRender", "0")
                        end
                        if _G.AK_GetVal("WHITE_BODY") == 1 then
                            executeCMD("r.CharacterDiffuseOffset", "2")
                            executeCMD("r.CharacterDiffusePower", "5")
                            executeCMD("r.CharacterMinShadowFactor", "100")
                        else
                            executeCMD("r.CharacterDiffuseOffset", "0")
                            executeCMD("r.CharacterDiffusePower", "1")
                            executeCMD("r.CharacterMinShadowFactor", "0")
                        end
                    end
                end)
            end

            local playerCharactersList = {}
            if GameplayData.GetAllPlayerCharacters then
                playerCharactersList = GameplayData.GetAllPlayerCharacters()
            elseif GameplayData.GameCharacters then
                for _, char in pairs(GameplayData.GameCharacters) do table.insert(playerCharactersList, char) end
            end

            
            if not _G.AK_Active_Marks_Cache then _G.AK_Active_Marks_Cache = {} end

            
            for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
                local shouldRemoveMark = false
                if not slua.isValid(cacheData.actor) then 
                    shouldRemoveMark = true 
                else
                    pcall(function()
                        local cachedActor = cacheData.actor
                        
                        if cachedActor.bHidden or (cachedActor.Mesh and cachedActor.Mesh.bHidden) then shouldRemoveMark = true end
                        if type(cachedActor.IsDead) == "function" and cachedActor:IsDead() then shouldRemoveMark = true
                        elseif cachedActor.bIsDead == true or cachedActor.bIsDeadFlag == true then shouldRemoveMark = true end
                    end)
                end

                if shouldRemoveMark then
                    pcall(function()
                        if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                            InGameMarkTools.ClientRemoveMapMark(cacheData.hpMark)
                            if cacheData.distMark then InGameMarkTools.ClientRemoveMapMark(cacheData.distMark) end
                        end
                    end)
                    _G.AK_Active_Marks_Cache[cacheKey] = nil
                end
            end

            for _, enemy in pairs(playerCharactersList) do
                if slua.isValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                    local isDead = false
                    local isNearDeath = false

                    pcall(function()
                        
                        if type(enemy.IsNearDeath) == "function" then isNearDeath = enemy:IsNearDeath()
                        elseif enemy.bIsNearDeath ~= nil then isNearDeath = enemy.bIsNearDeath end

                        
                        if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
                        elseif enemy.bIsDead ~= nil then isDead = enemy.bIsDead
                        elseif enemy.bIsDeadFlag ~= nil then isDead = enemy.bIsDeadFlag end

                        
                        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end

                        
                        
                        if not isNearDeath then
                            local healthVal = 100
                            if type(enemy.GetHealth) == "function" then healthVal = enemy:GetHealth()
                            elseif enemy.Health ~= nil then healthVal = enemy.Health end
                            if healthVal <= 0 then isDead = true end
                        end
                    end)

                    if not isDead then
                        if enemy.bHasAKNativeHPBar and enemy.AK_LastKnockState ~= nil and enemy.AK_LastKnockState ~= isNearDeath then
                            pcall(function()
                                if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then 
                                    InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                    InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark)
                                end
                            end)
                            enemy.bHasAKNativeHPBar = false
                            _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
                        end
                        enemy.AK_LastKnockState = isNearDeath

                        if _G.AK_GetVal("ESP_HP") == 1 then
                            if not enemy.bHasAKNativeHPBar then
                                pcall(function()
                                    if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
                                        enemy.NativeHPBarMark = InGameMarkTools.ClientAddMapMark(1006, FVector(0,0,0), 0, "", 4, enemy)
                                        enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(9999, FVector(0,0,0), 0, "", 4, enemy)
                                        enemy.bHasAKNativeHPBar = true

                                        _G.AK_Active_Marks_Cache[tostring(enemy)] = {
                                            cachedActor = enemy,
                                            hpMark = enemy.NativeHPBarMark,
                                            distMark = enemy.NativeDistMark
                                        }
                                    end
                                end)
                            end
                        else
                            if enemy.bHasAKNativeHPBar and InGameMarkTools then
                                pcall(function()
                                    if InGameMarkTools.ClientRemoveMapMark then 
                                        InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                        if enemy.NativeDistMark then InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark) end
                                    else 
                                        InGameMarkTools.HideMapMark(enemy.NativeHPBarMark) 
                                        if enemy.NativeDistMark then InGameMarkTools.HideMapMark(enemy.NativeDistMark) end
                                    end
                                end)
                                enemy.NativeHPBarMark = nil
                                enemy.NativeDistMark = nil
                                enemy.bHasAKNativeHPBar = false
                                _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
                            end
                        end
                        
                        if _G.AK_GetVal("ESP_BOX") == 1 then
                            pcall(function()
                                if enemy.Replay_IsEnemyFrameUIExisted then
                                    if not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
                                    if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                end
                            end)
                        else
                            pcall(function() if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end end)
                        end
                        
                                    
                        local avatarMesh = enemy.Mesh or (enemy.getAvatarComponent2 and enemy:getAvatarComponent2())
                        if slua.isValid(avatarMesh) then
                            if not avatarMesh.LastHitboxUpdateVersion or avatarMesh.LastHitboxUpdateVersion ~= _G.MagicUpdateVersion then
                                avatarMesh.bIsAKHitboxModded = false
                            end
                            if not avatarMesh.bIsAKHitboxModded then
                                pcall(function()
                                    local physicsAsset = avatarMesh.PhysicsAssetOverride
                                    if not slua.isValid(physicsAsset) and avatarMesh.SkeletalMesh then physicsAsset = avatarMesh.SkeletalMesh.PhysicsAsset end

                                    if slua.isValid(physicsAsset) and physicsAsset.SkeletalBodySetups then
                                        
                                        if not _G.AK_OrigHitboxes then _G.AK_OrigHitboxes = {} end
                                        local physAssetName = ""
                                        pcall(function() physAssetName = physicsAsset:GetName() end)
                                        if physAssetName == "" then physAssetName = "DefaultPhys" end
                                        
                                        if not _G.AK_OrigHitboxes[physAssetName] then 
                                            _G.AK_OrigHitboxes[physAssetName] = {} 
                                        end
                                        local originalHitboxes = _G.AK_OrigHitboxes[physAssetName]

                                        local headScale = 1.0 + (_G.AK_GetVal("MAGIC_HEAD") / 100.0)
                                        local bodyScale = 1.0 + (_G.AK_GetVal("MAGIC_BODY") / 100.0)
                                        local legsScale = 1.0 + (_G.AK_GetVal("MAGIC_LEGS") / 100.0)

                                        
                                        local boneScaleMap = {
                                            ["head"] = headScale,
                                            ["pelvis"] = bodyScale,
                                            ["spine_03"] = bodyScale,
                                            ["thigh_l"] = legsScale, ["thigh_r"] = legsScale, 
                                            ["calf_l"] = legsScale, ["calf_r"] = legsScale,   
                                            ["foot_l"] = legsScale, ["foot_r"] = legsScale    
                                        }

                                        local lIl11IIIl11II = physicsAsset.SkeletalBodySetups
                                        for i = 1, 50 do 
                                            local bodySetup = nil
                                            pcall(function() bodySetup = type(lIl11IIIl11II.Get) == "function" and lIl11IIIl11II:Get(i-1) or lIl11IIIl11II[i] end)
                                            if not bodySetup then break end
                                            
                                            if slua.isValid(bodySetup) then
                                                local boneName = string.lower(tostring(bodySetup.BoneName))
                                                local boneNameKey = nil
                                                for k, _ in pairs(boneScaleMap) do
                                                    if string.find(boneName, k) then boneNameKey = k break end
                                                end

                                                if boneNameKey then
                                                    local scaleVal = boneScaleMap[boneNameKey]
                                                    local aggGeom = bodySetup.AggGeom
                                                    
                                                    local boxElems = aggGeom and aggGeom.BoxElems or bodySetup.BoxElems
                                                    local sphereElems = aggGeom and aggGeom.SphereElems or bodySetup.SphereElems
                                                    local sphylElems = aggGeom and aggGeom.SphylElems or bodySetup.SphylElems

                                                    
                                                    local boxElem = nil
                                                    if boxElems then pcall(function() boxElem = type(boxElems.Get) == "function" and boxElems:Get(0) or boxElems[1] end) end
                                                    local sphereElem = nil
                                                    if sphereElems then pcall(function() sphereElem = type(sphereElems.Get) == "function" and sphereElems:Get(0) or sphereElems[1] end) end
                                                    local sphylElem = nil
                                                    if sphylElems then pcall(function() sphylElem = type(sphylElems.Get) == "function" and sphylElems:Get(0) or sphylElems[1] end) end

                                                    
                                                    if not originalHitboxes[boneNameKey] then
                                                        originalHitboxes[boneNameKey] = { Box = nil, Sphere = nil, Sphyl = nil }
                                                        if boxElem then originalHitboxes[boneNameKey].Box = { X = boxElem.X, Y = boxElem.Y, Z = boxElem.Z } end
                                                        if sphereElem then originalHitboxes[boneNameKey].Sphere = { Radius = sphereElem.Radius } end
                                                        if sphylElem then originalHitboxes[boneNameKey].Sphyl = { Radius = sphylElem.Radius, Length = sphylElem.Length } end
                                                    end

                                                    
                                                    local origHitboxData = originalHitboxes[boneNameKey]

                                                    if origHitboxData.Box and boxElem then
                                                        boxElem.X = origHitboxData.Box.X * scaleVal
                                                        boxElem.Y = origHitboxData.Box.Y * scaleVal
                                                        boxElem.Z = origHitboxData.Box.Z * scaleVal
                                                        pcall(function() if type(boxElems.Set) == "function" then boxElems:Set(0, boxElem) else boxElems[1] = boxElem end end)
                                                        if aggGeom then aggGeom.BoxElems = boxElems; bodySetup.AggGeom = aggGeom else bodySetup.BoxElems = boxElems end
                                                    end

                                                    if origHitboxData.Sphere and sphereElem then
                                                        sphereElem.Radius = origHitboxData.Sphere.Radius * scaleVal
                                                        pcall(function() if type(sphereElems.Set) == "function" then sphereElems:Set(0, sphereElem) else sphereElems[1] = sphereElem end end)
                                                        if aggGeom then aggGeom.SphereElems = sphereElems; bodySetup.AggGeom = aggGeom else bodySetup.SphereElems = sphereElems end
                                                    end

                                                    if origHitboxData.Sphyl and sphylElem then
                                                        sphylElem.Radius = origHitboxData.Sphyl.Radius * scaleVal
                                                        sphylElem.Length = origHitboxData.Sphyl.Length * scaleVal
                                                        pcall(function() if type(sphylElems.Set) == "function" then sphylElems:Set(0, sphylElem) else sphylElems[1] = sphylElem end end)
                                                        if aggGeom then aggGeom.SphylElems = sphylElems; bodySetup.AggGeom = aggGeom else bodySetup.SphylElems = sphylElems end
                                                    end

                                                end
                                            end
                                        end
                                        pcall(function() 
                                            
                                            if avatarMesh.SetPhysicsAsset then avatarMesh:SetPhysicsAsset(physicsAsset) end
                                            avatarMesh.PhysicsAssetOverride = physicsAsset
                                            
                                            
                                            if avatarMesh.RecreatePhysicsState then avatarMesh:RecreatePhysicsState() end 
                                            
                                            
                                            if avatarMesh.WakeAllRigidBodies then avatarMesh:WakeAllRigidBodies() end
                                            
                                            
                                            if avatarMesh.ForceUpdateBones then avatarMesh:ForceUpdateBones() end
                                            if avatarMesh.UpdateBounds then avatarMesh:UpdateBounds() end
                                            
                                            
                                            avatarMesh.bEnableUpdateRateOptimizations = false
                                        end)

                                    end
                                end)
                                avatarMesh.bIsAKHitboxModded = true
                                avatarMesh.LastHitboxUpdateVersion = _G.MagicUpdateVersion

                            end
                        end
                    else
                        if enemy.bHasAKNativeHPBar and InGameMarkTools then
                            pcall(function()
                                if InGameMarkTools.ClientRemoveMapMark then 
                                    InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark)
                                    if enemy.NativeDistMark then InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark) end
                                else 
                                    InGameMarkTools.HideMapMark(enemy.NativeHPBarMark) 
                                    if enemy.NativeDistMark then InGameMarkTools.HideMapMark(enemy.NativeDistMark) end
                                end
                            end)
                            enemy.NativeHPBarMark = nil
                            enemy.NativeDistMark = nil
                            enemy.bHasAKNativeHPBar = false
                        end
                        pcall(function() if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end end)
                    end
                end
            end
        end
    end)
end





function _G.InitializeAntiReport()
    print('[AntiReport] Initializing System...')
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

    print('[AntiReport] System Fully Active!')
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
    print('[AntiCheat] Initializing bypass system...')
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
    print('[AntiCheat] Bypass system activated!')
end

function _G.InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end
        
        local GC = _G.GameplayCallbacks
        print('[GameplayBypass] Hooking GameplayCallbacks...')
        
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
        print('[ConnectionGuard] Initializing Shield...')
        
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
        print('[ConnectionGuard] Active & Protecting!')
    end)
end


function _G.InitializeLogBlocker()
    print('[LogBlocker] Initializing Ultimate Log/Crash Blocker...')
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

        
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        if GameplayData then
            local playerController = GameplayData.GetPlayerControllerSafety and GameplayData.GetPlayerControllerSafety() or GameplayData.GetPlayerController()
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
    print('[LogBlocker] Log/Crash/UGC Telemetry Systems Silenced!')
end


function _G.InitializeScannerBlocker()
    print('[ScannerBlocker] Initializing Scanner Blocker...')
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
    print('[ScannerBlocker] Scanners and Exception Detectors Bypassed!')
end


function _G.InitializeReplayTelemetryBlocker()
    print('[ReplayBlocker] Initializing Replay Telemetry Blocker...')
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
    print('[ReplayBlocker] Replay Evidence Collection Stopped!')
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

    
    local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
    if not GameplayData then return end

    pcall(function()
        local playerCharacter = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
        if slua.isValid(playerCharacter) then
            if BRPlayerCharacterBase.StartAdvancedSystems then
                playerCharacter.StartAdvancedSystems = BRPlayerCharacterBase.StartAdvancedSystems
            end
            
            
            if playerCharacter.bHasShownDevNotice == nil then
                playerCharacter.bHasShownDevNotice = false 
                playerCharacter.bHasShownExpiredNotice = false 
                playerCharacter.bIsDeadFlag = false
                playerCharacter.bForceWeaponMod = true
                playerCharacter.AK_NativeESP_Ready = false
            end
            
            
            if type(playerCharacter.StartAdvancedSystems) == "function" then
                pcall(function() 
                    playerCharacter:StartAdvancedSystems() 
                end)
            end
        end
    end)
end


pcall(function() 
    require("common.time_ticker").AddTimerOnce(2, InitializeAllBlockers) 
end)

local ClassSystem = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local BRPlayerCharacterBaseClass = ClassSystem(CharacterBase, nil, BRPlayerCharacterBase)

return require("combine_class").DeclareFeature(BRPlayerCharacterBaseClass, {
    { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" }
}, "BRPlayerCharacterBase")