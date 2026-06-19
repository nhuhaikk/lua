local BRPlayerCharacterBase={
ServerRPC={},
ClientRPC={},
MulticastRPC={}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue={
Reliable=true,
Params={}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox={
Reliable=true,
Params={
UEnums.EPropertyClass.Object
}
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction={
Reliable=true,
Params={
UEnums.EPropertyClass.Int
}
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction={
Reliable=true,
Params={
UEnums.EPropertyClass.Int
}
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall={
Reliable=true,
Params={
UEnums.EPropertyClass.Bool
}
}
local ENetRole=import("ENetRole")
local EPawnState=import("EPawnState")
local GameplayData=require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools=require("GameLua.Mod.BaseMod.Common.GamePlayTools")
function BRPlayerCharacterBase:ctor()
end
function BRPlayerCharacterBase:_PostConstruct()
BRPlayerCharacterBase.__super._PostConstruct(self)
self:InitAddSpecialMoveInfo()
self.bCanNearDeathGiveup=true
print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end
function BRPlayerCharacterBase:ReceiveBeginPlay()
BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
local CheckFallingDistanceComponent_C=import("CheckFallingDistanceComponent")
if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
end
end
if slua.isValid(self.STCharacterMovement) then
self.STCharacterMovement.bPositiveBlowUp=true
end
if self.Role==ENetRole.ROLE_AutonomousProxy then
self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
AttrName={
"bCanSelfRescue"
}
}, self.CharacterAttrChangeEvent, self)
end
if Client then
printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
GameplayData.AddCharacter(self.Object)
self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
else
self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
[1]="FinishedState"
}, self.HandleFinishedState, self)
end
end
function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle)
if not slua.isValid(uVehicle) then
return
end
print(bWriteLog and string.format("BRPlayerCharacterBase:HandleOnAttachedToVehicle", Game:GetObjName(uVehicle)))
if self.Role==ENetRole.ROLE_SimulatedProxy then
self:ClearAttachToVehicleTimer()
self.nUpdatePlayerAttachToVehicleCount=0
self.nUpdatePlayerAttachToVehicleTimer=self:AddGameTimer(5, true,
function()
if slua.isValid(self.Object) and slua.isValid(uVehicle) then
self:UpdatePlayerAttachToVehicle(uVehicle)
end
end)
self.nFixMeshContainerTimer=self:AddGameTimer(3, true,
function()
if slua.isValid(self.Object) and slua.isValid(uVehicle) then
self:FixMeshContainerOffsetIfNeeded(uVehicle)
end
end)
end
end
function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle)
if not slua.isValid(uLastVehicle) then
return
end
print(bWriteLog and "BRPlayerCharacterBase:HandleOnDetachedFromVehicle", uLastVehicle)
if self.Role==ENetRole.ROLE_SimulatedProxy then
self:ClearAttachToVehicleTimer()
self.nUpdatePlayerAttachToVehicleCount=0
end
end
function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle(uVehicle)
if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then
return
end
if not slua.isValid(self.CapsuleComponent) or not slua.isValid(self.Mesh) or not slua.isValid(self.MeshContainer) then
return
end
if not slua.isValid(self:GetCurrentVehicle()) then
return
end
if Game:IsDriver(self.Object) then
return
end
if not self.nUpdatePlayerAttachToVehicleCount then
self.nUpdatePlayerAttachToVehicleCount=0
end
local ESTEPoseState=import("ESTEPoseState")
local bStand=self.PoseState==ESTEPoseState.Stand
local uActorRelativeLocation=self.CapsuleComponent:GetRelativeTransform():GetLocation()
local uMeshRelativeLocation=self.Mesh:GetRelativeTransform():GetLocation()
local uMeshContainerRelativeLocationZ=self.MeshContainer:GetRelativeTransform():GetLocation().Z
local nCapsuleRadius=self.CapsuleComponent:GetScaledCapsuleRadius()
local nCapsuleHalfHeight=self.CapsuleComponent:GetScaledCapsuleHalfHeight()
local uMeshContainerExpectedZ=-1*self.StandHalfHeight
local nExpectedCapsuleRadius=self.StandRadius
local nExpectedCapsuleHalfHeight=self.StandHalfHeight
local uMeshExpectedRL=FVector(0, 0, 0)
local uActorExpectedRL=FVector(0, 0, self.StandHalfHeight)
local nTolerance=1.0
local bCapsuleRLCorrect=uActorRelativeLocation:Equals(uActorExpectedRL, nTolerance)
local bMeshRLCorrect=uMeshRelativeLocation:Equals(uMeshExpectedRL, nTolerance)
local bMeshContainerRLCorrect=nTolerance > math.abs(uMeshContainerRelativeLocationZ-uMeshContainerExpectedZ)
local bCapsuleRadiusCorrect=nTolerance > math.abs(nCapsuleRadius-nExpectedCapsuleRadius)
local bCapsuleHalfHeightCorrect=nTolerance > math.abs(nCapsuleHalfHeight-nExpectedCapsuleHalfHeight)
local bAllCorrect=bStand and bCapsuleRLCorrect and bMeshRLCorrect and bMeshContainerRLCorrect and bCapsuleRadiusCorrect and bCapsuleHalfHeightCorrect
if not bAllCorrect then
self.nUpdatePlayerAttachToVehicleCount=self.nUpdatePlayerAttachToVehicleCount+1
else
self.nUpdatePlayerAttachToVehicleCount=0
end
print(bWriteLog and string.format("BRPlayerCharacterBase:UpdatePlayerAttachToVehicle PlayerKey:%s. bAllCorrect=%s Check Result:%d %d %d %d %d %d, Count:%d", tostring(self.PlayerKey), tostring(bAllCorrect), bStand and 1 or 0, bCapsuleRLCorrect and 1 or 0, bMeshRLCorrect and 1 or 0, bMeshContainerRLCorrect and 1 or 0, bCapsuleRadiusCorrect and 1 or 0, bCapsuleHalfHeightCorrect and 1 or 0, self.nUpdatePlayerAttachToVehicleCount))
if self.nUpdatePlayerAttachToVehicleCount >=3 and not bAllCorrect then
local GameplayData=require("GameLua.GameCore.Data.GameplayData")
local uPlayerController=GameplayData.GetPlayerController()
if uPlayerController.ReportCrashKitFeature and uPlayerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException then
local sReportInfo=string.format("VehicleShapeType:%s PlayerKey:%s. Check Result:%d %d %d %d %d %d. Capsule.RelativeLoc:%s Capsule.Radius:%s Capsule.HalfHeight:%s Mesh.RelativeLoc:%s MeshContainer.RelativeLocZ:%s", tostring(uVehicle.VehicleShapeType), tostring(self.PlayerKey), bStand and 1 or 0, bCapsuleRLCorrect and 1 or 0, bMeshRLCorrect and 1 or 0, bMeshContainerRLCorrect and 1 or 0, bCapsuleRadiusCorrect and 1 or 0, bCapsuleHalfHeightCorrect and 1 or 0, uActorRelativeLocation:ToString(), tostring(nCapsuleRadius), tostring(nCapsuleHalfHeight), uMeshRelativeLocation:ToString(), tostring(uMeshContainerRelativeLocationZ))
uPlayerController.ReportCrashKitFeature:ReportCharacterAttachedOnVehicleException(sReportInfo)
end
self.nUpdatePlayerAttachToVehicleCount=0
end
end
function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded(uVehicle)
if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then
return
end
if not slua.isValid(self.MeshContainer) then
return
end
if not slua.isValid(self:GetCurrentVehicle()) then
return
end
if Game:IsDriver(self.Object) then
return
end
local nTolerance=1.0
local uMeshContainerExpectedZ=-1*self.StandHalfHeight
local uMeshContainerRelativeLocationZ=self.MeshContainer:GetRelativeTransform():GetLocation().Z
if nTolerance <=math.abs(uMeshContainerRelativeLocationZ-uMeshContainerExpectedZ) then
print(bWriteLog and string.format("BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded PlayerKey:%s. SetMeshContainerOffsetZ from:%s to:%s", tostring(uMeshContainerRelativeLocationZ), tostring(uMeshContainerExpectedZ)))
self:SetMeshContainerOffsetZ(uMeshContainerExpectedZ)
end
end
function BRPlayerCharacterBase:ClearAttachToVehicleTimer()
if self.nUpdatePlayerAttachToVehicleTimer then
self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
self.nUpdatePlayerAttachToVehicleTimer=nil
end
if self.nFixMeshContainerTimer then
self:RemoveGameTimer(self.nFixMeshContainerTimer)
self.nFixMeshContainerTimer=nil
end
end
function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
if self.Object ~=uPawn then
return
end
if self.Role==ENetRole.ROLE_AutonomousProxy and AttrName=="bCanSelfRescue" then
local uPlayerController=self:GetPlayerControllerSafety()
if slua.isValid(uPlayerController) then
uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
end
end
end
function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
print("BRPlayerCharacterBase:OnPawnStateChange:", PawnState)
local EPawnState=import("EPawnState")
if PawnState==EPawnState.SwitchPP then
local uPlayerController=self:GetPlayerControllerSafety()
if slua.isValid(uPlayerController) then
uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
end
end
end
function BRPlayerCharacterBase:HandleFinishedState()
print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
end
end
function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
local EGameModeType=import("EGameModeType")
local MatchModeIds=require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")
local GameModeType=CGameMode.GameModeType
local GameModeID=tonumber(CGameState.GameModeID)
local bModeTypeSatisfy=GameModeType==EGameModeType.ETypicalGameMode or GameModeType==EGameModeType.EFourInOneGameMode or GameModeType==EGameModeType.EHeavyWeaponGameMode
local bModeIDSatisfy=not MatchModeIds[GameModeID]
print(bWriteLog and bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", GameModeType, GameModeID, bModeTypeSatisfy, bModeIDSatisfy)
return bModeTypeSatisfy and bModeIDSatisfy
end
return false
end
function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
local EParachuteState=import("EParachuteState")
if not Client then
local uCurrentPlayerControl=self:GetPlayerControllerSafety()
if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
if NewParachuteState==EParachuteState.PS_Opening then
if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
end
elseif NewParachuteState==EParachuteState.PS_None then
if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
end
if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
end
end
end
end
end
function BRPlayerCharacterBase:OnLanded()
printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", self.PlayerKey)
if self.HandleOnLanded then
self:HandleOnLanded(-1)
end
if not Client then
local uCurrentPlayerControl=self:GetPlayerControllerSafety()
if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
end
if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
end
end
end
end
function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
if Client then
GameplayData.RemoveCharacter(self.Object)
end
end
function BRPlayerCharacterBase:IsWarGameMode()
local GameplayData=require("GameLua.GameCore.Data.GameplayData")
local uGameState=GameplayData:GetGameState()
local STExtraGameStateBase=import("STExtraGameStateBase")
if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
local EGameModeType=import("EGameModeType")
return uGameState.GameModeType==EGameModeType.EWarGameMode
else
return false
end
end
function BRPlayerCharacterBase:BPOnRecycled()
print(bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(self.Object)))
if Client then
self:ResetMeshRelativeLocationAndRotation()
end
end
function BRPlayerCharacterBase:BPOnRespawned()
print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
if Client then
self:ResetMeshRelativeLocationAndRotation()
end
end
function BRPlayerCharacterBase:ReceiveOnRecycle()
print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
if Client then
self:ResetMeshRelativeLocationAndRotation()
GameplayData.RemoveCharacter(self.Object)
end
end
function BRPlayerCharacterBase:ReceiveOnSpawn()
print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
if Client then
self:ResetMeshRelativeLocationAndRotation()
GameplayData.AddCharacter(self.Object)
end
end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
local uDefaultMeshRot=FRotator(0,-90, 0)
local uDefaultMeshRelativeLoc=FVector(0, 0, 0)
if self.Mesh.K2_SetRelativeRotation then
self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
end
self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
local vRelativeRot=self.Mesh.RelativeRotation
local vBaseRotationOffset=self.BaseRotationOffset
local vBaseRotation=Game:QuatToRotator(vBaseRotationOffset)
print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(vRelativeRot.Pitch), tostring(vRelativeRot.Yaw), tostring(vRelativeRot.Roll), tostring(vBaseRotation.Pitch), tostring(vBaseRotation.Yaw), tostring(vBaseRotation.Roll)))
end
end
function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
local EMovementMode=import("EMovementMode")
if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode==EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
self.CharacterMovement:SetBase(nil, "", true)
end
if self.Role==ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode==EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
end
end
function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end
function BRPlayerCharacterBase:PreAttachedToVehicle()
local UKismetSystemLibrary=import("KismetSystemLibrary")
local IsDS=UKismetSystemLibrary.IsDedicatedServer(self)
if not IsDS then
return
end
local MainPlayerController=self:GetPlayerControllerSafety()
if not slua.isValid(MainPlayerController) then
return
end
local CharacterAvatarComp2_BP=self.CharacterAvatarComp2_BP
if not slua.isValid(CharacterAvatarComp2_BP) then
return
end
local CommerAvatarDataUtil=require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
local changedVehicleId=CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
local ESTExtraVehicleShapeType=import("ESTExtraVehicleShapeType")
if changedVehicleId then
local UAvatarUtils=import("AvatarUtils")
if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId)==ESTExtraVehicleShapeType.VST_Horse then
local uCurPlayerState=self:GetPlayerStateSafety()
if slua.isValid(uCurPlayerState) then
print(bWriteLog and "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: " .. tostring(changedVehicleId))
uCurPlayerState:AddGeneralCount(468, 1, false)
end
end
end
end
BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment={
Reliable=true,
Params={
UEnums.EPropertyClass.UInt32,
UEnums.EPropertyClass.UInt32
}
}
function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
print(bWriteLog and string.format("BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment Type=%d, Param=%s", Type, Param))
EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
end
function BRPlayerCharacterBase:ParachuteJump()
local uPlayerController=self:GetControllerSafety()
if slua.isValid(uPlayerController) then
if not self:GetEnsure() then
local EStateType=import("EStateType")
if uPlayerController:GetCurrentStateType() ~=EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~=EStateType.State_ParachuteOpen then
local ESTEPoseState=import("ESTEPoseState")
self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
uPlayerController:ReInitParachuteItem()
uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
end
print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
else
EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
end
end
end
function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
if uCharacter ~=self.Object then
return
end
print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s-> %s", uCharacter, uOldMovementBase, uNewMovementBase))
local MedievalCrane=self:GetMedievalCraneFromBase(uNewMovementBase)
if MedievalCrane and MedievalCrane.AddCharacter then
MedievalCrane:AddCharacter(self.Object)
else
MedievalCrane=self:GetMedievalCraneFromBase(uOldMovementBase)
if MedievalCrane and MedievalCrane.RemoveCharacter then
MedievalCrane:RemoveCharacter(self.Object)
end
end
end
function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
if not slua.isValid(Base) or not Base.GetOwner then
return
end
local Lifter=Base:GetOwner()
if not slua.isValid(Lifter) then
return
end
if not Lifter.AddCharacter then
return
end
return Lifter
end
function BRPlayerCharacterBase:CheckForbidFlaregun()
local uPlayerState=self:GetPlayerStateSafety()
if not slua.isValid(uPlayerState) then
return false
end
if uPlayerState.CanUseFlaregun==false and self:IsLocallyControlled() then
local uPlayerController=self:GetPlayerControllerSafety()
if slua.isValid(uPlayerController) then
uPlayerController:DisplayGameTipWithMsgID(48532)
end
end
return not uPlayerState.CanUseFlaregun
end
function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
self:HandleNearDeathGiveupRescue()
end
function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
local uNearDeathComp=self.NearDeatchComponent
if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup==true then
local uPlayerState=self:GetPlayerStateSafety()
if slua.isValid(uPlayerState) then
uPlayerState:AddGeneralCount(1613, 1, false)
end
uNearDeathComp:TriggerGotoDieExplictly(self.Object)
end
end
function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: " .. tostring(actionId))
local USTExtraBlueprintFunctionLibrary=import("STExtraBlueprintFunctionLibrary")
if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: " .. tostring(actionId))
self:MulticastRPC_GmPlayAction(actionId)
end
end
function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
if not Client then
return
end
log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
local uPlayEmoteComp=self:GetPlayEmoteComponent()
if not slua.isValid(uPlayEmoteComp) then
return
end
local LogFilter=require("common.log_filter")
LogFilter.SetLogTreeEnable(true)
local animCfg=CDataTable.GetTableData("EmoteBPTable", actionId)
if not animCfg then
return
end
local handlePath=animCfg.Path
local EmoteHandleAsset=slua.loadObject(handlePath)
local assetsArray=slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
local handle=EmoteHandleAsset()
uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): " .. tostring(assetsArray:Num()))
local tb=FuncUtil.LuaArrayToTable(assetsArray)
local asset_util=require("common.asset_util")
local loadLater=function()
uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
end
asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end
function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
print(bWriteLog and "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall " .. tostring(bServerSyncShouldCheckPassWall))
if slua.isValid(self.ParachuteComponent) then
self.ParachuteComponent.bServerSyncShouldCheckPassWall=bServerSyncShouldCheckPassWall
end
end
function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
self.Super:OnPlayerEnterCarryBoxState()
local CharName=self:GetPlayerNameSafety()
print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName)))
if self.CarryDeadBoxFeature then
self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
end
end
function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
local CharName=self:GetPlayerNameSafety()
print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName), tostring(bInIsInterrupt)))
if self.CarryDeadBoxFeature then
self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
end
end
function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
end
end
function BRPlayerCharacterBase:SetAreaID(AreaID)
self:SetAttrValue("AreaID", AreaID,-1)
end
function BRPlayerCharacterBase:GetAreaID()
return math.floor(self:GetAttrValue("AreaID")+0.5)
end
function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
return self.bCannotChangeIntoPetSpectator
end
function BRPlayerCharacterBase:DoModChangeToBT()
print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(self.PlayerKey)))
if self:HasState(EPawnState.SpecialSuit) then
self:TriggerEntrySkillWithID(4301101, true)
print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(self.PlayerKey)))
end
end
function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
self.Super:SwitchCameraToParachuteOpening()
if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
self.ParachuteFormation:OverlayFormationCameraParams()
print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening-Formation camera overlaid")
end
end
function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
self.Super:SwitchCameraToParachuteFalling()
if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
self.ParachuteFormation:OverlayFormationCameraParams()
print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling-Formation camera overlaid")
end
end
function BRPlayerCharacterBase:SwitchCameraToNormal()
print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
self.Super:SwitchCameraToNormal()
if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
self.ParachuteFormation:OnLandingClearFormationCamera()
end
end
function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
if self:HasState(EPawnState.AttachToOther) then
local Weapon=self:GetWeaponBySlot(Slot)
if slua.isValid(Weapon) then
local WeaponID=Weapon:GetWeaponID()
local AttachToOtherConfig=GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: " .. tostring(WeaponID))
local uPlayerController=self:GetPlayerControllerSafety()
if Client and slua.isValid(uPlayerController) and uPlayerController.Role==ENetRole.ROLE_AutonomousProxy then
uPlayerController:DisplayGameTipWithMsgID(47306)
end
return false
end
end
end
return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end
local function Notify(msg) local s="[DUNG0610 VIP] " .. tostring(msg)
pcall(function() if _G.LexusNotify then _G.LexusNotify(s) end end)
pcall(function() local sh=import("ScriptHelperClient") if sh and
sh.AddOnScreenDebugMessage then sh.AddOnScreenDebugMessage(s,-1, 3.0, {R=1,
G=1, B=0, A=1}, {X=1.2, Y=1.2}) end end) print(s) end
local _slua=rawget(_G, "slua")
local function Valid(obj) if not obj then return false end if _slua and
_slua.isValid then local ok, v=pcall(_slua.isValid, obj) if not ok or not v
then return false end end return true end
_G.LexusConfig=_G.LexusConfig or {
MagicBullet=false,
CustomMagicBullet=false,
AutoHead=false,
EspVip=false,
EspDistance=false,
EspVipPro=false,
EspRadar=false,
EspLoai5=false,
EspLoai6=false,
EspLoai7=false,
EspAntenna=false,
EspOutline=false,
OutlineThickness=10,
UnlockFPS=false,
IpadView=false,
AimbotMode="None",
CustomAimbot=false,
AimbotDyingRate=false,
LessRecoil=false,
CustomHRecoil=false,
VerticalRecoil=false,
CustomVRecoil=false,
LessShake=false,
RemoveGrass=false,
RemoveFog=false,
WhiteBody=false,
ColorBodyV2=false,
WallXuyenTuong=false,
Crosshair=false,
Accuracy=false,
GodMode=false,
WallClimb=false,
FastCar=false,
ModSkin=false
}
_G.LexusState=_G.LexusState or {
LoopToken=0,
NativeESPReady=false,
GraphicsUnlocked=false,
MenuStep=0,
LastCmdTime=0,
TrackedMarks={},
EnemyMarks={},
LastAimbotCheckTime=0,
CustomTextData=nil,
LastAimbotConfigString="",
LastSkinConfigString=nil,
MagicUpdateVersion=1,
LastMagicConfigHash=""
}
local currentTime=os.time(os.date("!*t")) local limitTime=os.time({ year=2026, month=6, day=3, hour=23, min=59, sec=0 })
local isExpired=(currentTime > limitTime)
function _G.InitializeSkinBypass()
pcall(function()
local puffer_tlog=package.loaded["client.slua.logic.download.report.puffer_tlog"]
if puffer_tlog then
puffer_tlog.ReportEvent=function() end
puffer_tlog.ReportDownloadResult=function() end
puffer_tlog.ReportODPTDError=function() end
end
local AvatarUtils=package.loaded["AvatarUtils"]
if AvatarUtils then
AvatarUtils.CheckIsWeaponInBlackList=function() return false end
AvatarUtils.IsValidAvatar=function() return true end
end
local SubsystemMgr=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
local fileCheckSubsystem=SubsystemMgr:Get("FileCheckSubsystem")
if fileCheckSubsystem then
fileCheckSubsystem.StartCheck=function() end
fileCheckSubsystem.ReportAbnormalFile=function() end
end
local equipmentException=package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
if equipmentException then
equipmentException.Report=function() end
end
end)
print('[SkinBypass] Resource & Skin Scanners Bypassed!')
end
function _G.InitializeLogBlocker()
print('[LogBlocker] Initializing Ultimate Log/Crash/Screenshot Blocker V11...')
pcall(function()
local ScreenshotMTDer=import("ScreenshotMTDer")
if ScreenshotMTDer then
ScreenshotMTDer.MTDePicture=function() return "" end
ScreenshotMTDer.ReMTDePicture=function() return "" end
ScreenshotMTDer.HasCaptured=function() return true end
end
local TLog=package.loaded["TLog"] or _G.TLog
if TLog then
TLog.Info=function() end; TLog.Warning=function() end
TLog.Error=function() end; TLog.Debug=function() end; TLog.Report=function() end
end
local CrashSight=package.loaded["CrashSight"] or _G.CrashSight
if CrashSight then
CrashSight.ReportException=function() end
CrashSight.SetCustomData=function() end; CrashSight.Log=function() end
end
local GameReportUtils=package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
if GameReportUtils then
GameReportUtils.BugglyPostExceptionFull=function() return false end
GameReportUtils.CheckCanBugglyPostException=function() return false end
GameReportUtils.ReplayReportData=function() end
GameReportUtils.ReportGameException=function() end
end
local ClientToolsReport=package.loaded["client.slua.logic.report.ClientToolsReport"]
if ClientToolsReport then
ClientToolsReport.SendReport=function() end; ClientToolsReport.SendException=function() end
end
local TLogReportUtils=package.loaded["client.slua.config.tlog.tlog_report_utils"]
if TLogReportUtils then
TLogReportUtils.ReportTLogEvent=function() end
end
local UGCReport=package.loaded["client.slua.logic.ugc.UGCNewTLogReport"] or package.loaded["client.slua.data.BasicData.BasicDataTLogReport"]
if UGCReport then
UGCReport.SendExposeReq=function() end
UGCReport.SendInteractionReq=function() end
UGCReport.TLogReport=function() end
end
local logic_ugc_tlog=package.loaded["client.slua.logic.ugc.logic_ugc_tlog"]
if logic_ugc_tlog then
logic_ugc_tlog.SendModTLog=function() end
logic_ugc_tlog.ReportStay=function() end
end
local ClientTLogUtil=package.loaded["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"]
if ClientTLogUtil then
ClientTLogUtil.ReportGeneralCountByBRPhase=function() end
ClientTLogUtil.ReportCommonTLogDataByBRPhase=function() end
end
local GameplayData=require("GameLua.GameCore.Data.GameplayData")
if GameplayData then
local PlayerController=GameplayData.GetPlayerControllerSafety and GameplayData.GetPlayerControllerSafety() or GameplayData.GetPlayerController()
if slua.isValid(PlayerController) and PlayerController.ReportCrashKitFeature then
PlayerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException=function() end
end
end
end)
print('[LogBlocker] Log/Crash/Buggly & Silent Screenshots Bypassed!')
end
function _G.InitializeScannerBlocker()
print('[ScannerBlocker] Initializing Scanner Blocker V11...')
pcall(function()
local SubsystemMgr=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
if SubsystemMgr then
local AFKReportor=SubsystemMgr:Get("AFKReportorSubsystem")
if AFKReportor then
AFKReportor.PlayerHaveAction=function() end; AFKReportor.ReportAFK=function() end
end
local DataStatistcs=SubsystemMgr:Get("ClientDataStatistcsSubsystem")
if DataStatistcs then
DataStatistcs.StartToCheck=function() end
DataStatistcs.DelayCount=0
if DataStatistcs.ReportPingDelayTimer then
DataStatistcs:RemoveGameTimer(DataStatistcs.ReportPingDelayTimer)
DataStatistcs.ReportPingDelayTimer=nil
end
end
local AvatarException=SubsystemMgr:Get("AvatarExceptionSubsystem")
if AvatarException then
AvatarException.ReportException=function() end
AvatarException.BindPlayerCharacter=function() end
AvatarException.CheckAvatarValid=function() return true end
end
local ShootVerify=SubsystemMgr:Get("ShootVerifySubSystemClient")
if ShootVerify then
ShootVerify.ReportVerifyFail=function() end
ShootVerify.OnVerifyFailed=function() end
end
end
local CreativeModeBlueprintLibrary=import("CreativeModeBlueprintLibrary")
if CreativeModeBlueprintLibrary then
CreativeModeBlueprintLibrary.MD5HashByteArray=function() return "BYPASSED_MD5_HASH" end
CreativeModeBlueprintLibrary.GetContentDiffData=function() return true, "BYPASSED" end
end
local AvatarExceptionPlayerInst=package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
if AvatarExceptionPlayerInst then
AvatarExceptionPlayerInst.CheckAvatarException=function() end
AvatarExceptionPlayerInst.CheckAvatarExceptionOnce=function() end
AvatarExceptionPlayerInst.ReportAvatarException=function() end
AvatarExceptionPlayerInst.CheckSlotMeshVisible=function() return false end
AvatarExceptionPlayerInst.CheckPawnVisible=function() return false end
AvatarExceptionPlayerInst.CheckCanBugglyPostException=function() return false end
end
local AvatarCheckerModule=package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
if AvatarCheckerModule then
AvatarCheckerModule.CheckAvatar=function() return true end
AvatarCheckerModule.ReportException=function() end
end
local logic_memory_warning=package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
if logic_memory_warning then
logic_memory_warning.OnMemoryWarning=function() end
logic_memory_warning.ReportMemoryWarning=function() end
end
local logic_store_game_interface=package.loaded["client.slua.logic.store.logic_store_game_interface"]
if logic_store_game_interface then
logic_store_game_interface.IsStoreGameSupported=function() return true end
logic_store_game_interface.NotifyGetPGSLoginInfo=function() end
end
local VoiceChatSubsystem=package.loaded["GameLua.Mod.BaseMod.Client.Voice.VoiceChatSubsystem"]
if VoiceChatSubsystem then
VoiceChatSubsystem.OnPlayerSubmitComplaint=function() end
end
local TssSdk=package.loaded["TssSdk"] or _G.TssSdk
if TssSdk then
local originalOnRecvData=TssSdk.OnRecvData
TssSdk.OnRecvData=function(data)
if type(data)=="string" and (string.find(data, "report") or string.find(data, "exception")) then
return
end
if originalOnRecvData then originalOnRecvData(data) end
end
TssSdk.SendReportInfo=function() end
TssSdk.ScanMemory=function() return true end
TssSdk.IsEmulator=function() return false end
TssSdk.GetTssSdkReportInfo=function() return "" end
end
end)
print('[ScannerBlocker] Magic Bullet/MD5 Checks/TSS/OS Scans Bypassed!')
end
function _G.InitializeReplayTelemetryBlocker()
print('[ReplayBlocker] Initializing Replay Telemetry Blocker V11...')
pcall(function()
local SubsystemMgr=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
local RescueBtnReplayTraceSubsystem=SubsystemMgr and SubsystemMgr:Get("RescueBtnReplayTraceSubsystem")
if RescueBtnReplayTraceSubsystem then
RescueBtnReplayTraceSubsystem.ReportTrace=function() end; RescueBtnReplayTraceSubsystem.StartTickMonitor=function() end
RescueBtnReplayTraceSubsystem.TickMonitorCheck=function() end; RescueBtnReplayTraceSubsystem.ReportTickMonitorHeartbeat=function() end
end
local GameReportSubsystem=SubsystemMgr and SubsystemMgr:Get("GameReportSubsystem")
if GameReportSubsystem then
GameReportSubsystem.ReplayReportData=function() return false end
GameReportSubsystem.CheckCanBugglyPostException=function() return false end
GameReportSubsystem.BugglyPostExceptionFull=function() return false end
GameReportSubsystem.GetClientReplayDataReporter=function() return nil end
if GameReportSubsystem.Reporter then
GameReportSubsystem.Reporter.ReportIntArrayData=function() end
GameReportSubsystem.Reporter.ReportUInt8ArrayData=function() end
GameReportSubsystem.Reporter.ReportFloatArrayData=function() end
end
end
local logic_report_replay=package.loaded["client.slua.logic.replay.logic_report_replay"]
if logic_report_replay then
logic_report_replay.ReportReplay=function() end
logic_report_replay.SendReportReq=function() end
end
local logic_home_report=package.loaded["client.slua.logic.home.logic_home_report"]
if logic_home_report then
logic_home_report.ShowInGameReportUI=function() end
logic_home_report.SendReport=function() end
end
end)
print('[ReplayBlocker] Replay Evidence Collection Stopped!')
end
function _G.DisableHiggsBoson()
local PlayerController=slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if not PlayerController or not slua.isValid(PlayerController) then return end
if PlayerController.HiggsBoson then
PlayerController.HiggsBoson.bMHActive=false
PlayerController.HiggsBoson.bCallPreReplication=false
end
if PlayerController.HiggsBosonComponent then
PlayerController.HiggsBosonComponent.bMHActive=false
PlayerController.HiggsBosonComponent:ControlMHActive(0)
end
end
function _G.InitializeAntiCheatHooks()
print('[AntiCheat] Initializing bypass system...')
pcall(function()
local HiggsBosonComponent=require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
if HiggsBosonComponent and HiggsBosonComponent.StaticShowSecurityAlertInDev then
HiggsBosonComponent.StaticShowSecurityAlertInDev=function() end
end
end)
if _G.AvatarCheckCallback then
_G.AvatarCheckCallback.StartAvatarCheck=function(obj) end
_G.AvatarCheckCallback.OnReportItemID=function(obj) end
_G.AvatarCheckCallback.PostPlayerControllerLoginInit=function(PlayerController)
if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then
PlayerController.HiggsBosonComponent:ControlMHActive(0)
PlayerController.HiggsBosonComponent.bMHActive=false
end
end
end
pcall(function()
local HiggsBosonComponent=require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
if HiggsBosonComponent and HiggsBosonComponent.BlackList then
for k in pairs(HiggsBosonComponent.BlackList) do HiggsBosonComponent.BlackList[k]=nil end
end
end)
_G.BlackList={}
pcall(function()
_G.GlobalPlayerCoronaData=_G.GlobalPlayerCoronaData or {}
_G.GlobalPlayerCheatTimes=_G.GlobalPlayerCheatTimes or {}
local mt=getmetatable(_G.GlobalPlayerCoronaData) or {}
mt.__newindex=function(t, k, v) end
setmetatable(_G.GlobalPlayerCoronaData, mt)
end)
pcall(function()
if _G.GameSafeCallbacks and _G.GameSafeCallbacks.RecordStrategyTimestampInReplay then
_G.GameSafeCallbacks.RecordStrategyTimestampInReplay=function(...) end
_G.GameSafeCallbacks.DoAttackFlowStrategy=function() end
_G.GameSafeCallbacks.GetScriptReportContent=function() return "" end
end
end)
pcall(function()
local STExtraBlueprintFunctionLibrary=import("STExtraBlueprintFunctionLibrary")
if STExtraBlueprintFunctionLibrary then
STExtraBlueprintFunctionLibrary.IsDevelopment=function() return false end
end
end)
print('[AntiCheat] Bypass system activated!')
end
function _G.InitializeAntiReport()
print('[AntiReport] Initializing System...')
pcall(function()
local paths={ "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem" }
local ClientReportPlayerSubsystem=nil
for _, path in ipairs(paths) do
if package.loaded[path] then ClientReportPlayerSubsystem=package.loaded[path] break end
local success, reqModule=pcall(require, path)
if success and reqModule then ClientReportPlayerSubsystem=reqModule break end
end
if ClientReportPlayerSubsystem then
ClientReportPlayerSubsystem.OnInit=function(self) return end
ClientReportPlayerSubsystem._OnPlayerKilledOtherPlayer=function() return end
ClientReportPlayerSubsystem._RecordFatalDamager=function() return end
ClientReportPlayerSubsystem._OnDeathReplayDataWhenFatalDamaged=function() return end
ClientReportPlayerSubsystem._RecordMurdererFromDeathReplayData=function() return end
ClientReportPlayerSubsystem._RecordTeammatePlayerInfo=function() return end
ClientReportPlayerSubsystem._OnBattleResult=function() return end
ClientReportPlayerSubsystem._OnShowQuickReportMutualExclusiveUI=function() return end
ClientReportPlayerSubsystem.GetFatalDamagerMap=function() return {} end
ClientReportPlayerSubsystem.GetCachedTeammateName2InfoMap=function() return {} end
ClientReportPlayerSubsystem.GetTeammateName2InfoMapDuringBattle=function() return {} end
ClientReportPlayerSubsystem.GetCurrentNotInTeamHistoricalTeammateMap=function() return {} end
ClientReportPlayerSubsystem.GetInTeamIndexFromHistoricalTeammateInfo=function() return-1 end
end
end)
pcall(function()
local dsPaths={ "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem", "GameLua.Mod.BaseMod.Client.Security.DSReportPlayerSubsystem" }
local DSReportPlayerSubsystem=nil
for _, path in ipairs(dsPaths) do
if package.loaded[path] then DSReportPlayerSubsystem=package.loaded[path] break end
local success, reqModule=pcall(require, path)
if success and reqModule then DSReportPlayerSubsystem=reqModule break end
end
if DSReportPlayerSubsystem then
DSReportPlayerSubsystem.OnInit=function(self) return end
DSReportPlayerSubsystem._OnNearDeathOrRescued=function() return end
DSReportPlayerSubsystem._OnCharacterDied=function() return end
DSReportPlayerSubsystem._OnTeammateDamage=function() return end
DSReportPlayerSubsystem._OnPlayerSettlementStart=function() return end
DSReportPlayerSubsystem._AddKnockDownerToBattleResult=function() return end
DSReportPlayerSubsystem._AddKillerToBattleResult=function() return end
DSReportPlayerSubsystem._AddTeammateMurderToBattleResult=function() return end
DSReportPlayerSubsystem._AddFatalDamagerMapToBattleResult=function() return end
DSReportPlayerSubsystem._AddMLKillerUIDToBattleResult=function() return end
DSReportPlayerSubsystem._SaveHistoricalTeammateInfo=function() return end
DSReportPlayerSubsystem._RecordFatalDamager=function() return end
DSReportPlayerSubsystem._RecordTeammateMurderer=function() return end
end
end)
pcall(function()
local ReportPlayerUtils=require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
if ReportPlayerUtils then
ReportPlayerUtils.RecordFatalDamager=function() return end
ReportPlayerUtils.IsUsingHistoricalTeammateInfo=function() return false end
ReportPlayerUtils.IsCharacterDeliverAI=function() return false end
end
end)
pcall(function()
local SecurityCommonUtils=require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
if SecurityCommonUtils then
SecurityCommonUtils.ExtractPlayerBasicInfo=function() return {} end
SecurityCommonUtils.LogIf=function() return false end
end
end)
pcall(function()
local ClientQuickReportMaliciousTeammate=require("GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate")
if ClientQuickReportMaliciousTeammate then
ClientQuickReportMaliciousTeammate.OnShowMutualExclusiveUI=function() return end
ClientQuickReportMaliciousTeammate.OnHideMutualExclusiveUI=function() return end
end
end)
print('[AntiReport] System Fully Active!')
end
function _G.InitializeGameplayBypass()
pcall(function()
if not _G.GameplayCallbacks or _G.GameplayCallbacks.IsBypassed then return end
local GC=_G.GameplayCallbacks
print('[GameplayBypass] Hooking GameplayCallbacks...')
local originalDSPlayerState=GC.OnDSPlayerStateChanged
GC.OnDSPlayerStateChanged=function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
if InPlayerState and string.lower(tostring(InPlayerState))=="cheatdetected" then return end
if originalDSPlayerState then return originalDSPlayerState(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
end
local function NoOpVoid() return end
local function NoOpTable() return {} end
local function NoOpNil() return nil end
GC.ReportAttackFlow=NoOpVoid
GC.ReportSecAttackFlow=NoOpVoid
GC.ReportHurtFlow=NoOpVoid
GC.ReportFireArms=NoOpVoid
GC.ReportVerifyInfoFlow=NoOpVoid
GC.ReportMrpcsFlow=NoOpVoid
GC.ReportPlayerBehavior=NoOpVoid
GC.ReportTeammatHurt=NoOpVoid
GC.ReportMisKillByTeammate=NoOpVoid
GC.ReportForbitPick=NoOpVoid
GC.ReportPlayerMoveRoute=NoOpVoid
GC.ReportPlayerPosition=NoOpVoid
GC.ReportVehicleMoveFlow=NoOpVoid
GC.ReportSecTgameMovingFlow=NoOpVoid
GC.ReportParachuteData=NoOpVoid
GC.SendTssSdkAntiDataToLobby=NoOpVoid
GC.SendDSErrorLogToLobby=NoOpVoid
GC.SendDSErrorLogToLobbyOnece=NoOpVoid
GC.SendDSHawkEyePatrolLogToLobby=NoOpVoid
GC.ReportEquipmentFlow=NoOpVoid
GC.ReportAimFlow=NoOpVoid
GC.GetWeaponReport=NoOpTable
GC.GetOneWeaponReport=NoOpTable
GC.ReportHeavyWeaponBoxSpawnFlow=NoOpVoid
GC.ReportHeavyWeaponBoxActivationFlow=NoOpVoid
GC.ReportHeavyWeaponBoxOpenPlayerFlow=NoOpVoid
GC.ReportHeavyWeaponBoxItemFlow=NoOpVoid
GC.ReportPlayersPing=NoOpVoid
GC.ReportPlayerIP=NoOpVoid
GC.ReportPlayerFramePingRecord=NoOpVoid
GC.OnDSConnectionSaturated=NoOpVoid
GC.ReportDSNetSaturation=NoOpVoid
GC.ReportNetContinuousSaturate=NoOpVoid
GC.ReportDSNetRate=NoOpVoid
GC.SendClientStats=NoOpVoid
GC.SendServerAvgTickDelta=NoOpVoid
GC.ReportCircleFlow=NoOpVoid
GC.ReportDSCircleFlow=NoOpVoid
GC.ReportJumpFlow=NoOpVoid
GC.ReportAIStrategyInfo=NoOpVoid
GC.SendAIDeliveryInfo=NoOpVoid
GC.ReportDailyTaskInfo=NoOpVoid
GC.ReportMatchRoomData=NoOpVoid
GC.SendPlayerSpectatingLog=NoOpVoid
GC.ReportIDCardProduceFlow=NoOpVoid
GC.ReportIDCardPickUpFlow=NoOpVoid
GC.ReportIDCardDestroyFlow=NoOpVoid
GC.ReportRevivalFlow=NoOpVoid
GC.ReportGameSetting=NoOpVoid
GC.ReportGameSettingNew=NoOpVoid
GC.ReportAntsVoiceTeamCreate=NoOpVoid
GC.ReportAntsVoiceTeamQuit=NoOpVoid
GC.ReportCommonInfo=NoOpVoid
GC.ReportLightweightStat=NoOpVoid
GC.SendSecTLog=NoOpVoid
GC.SendDataMiningTLog=NoOpVoid
GC.SendActivityTLog=NoOpVoid
GC.GetGeneralTLogData=NoOpNil
GC.IsBypassed=true
end)
pcall(function()
if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
local originalSendPacket=NetUtil.SendPacket
local blockedPackets={
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
NetUtil.SendPacket=function(packetName, ...)
if blockedPackets[packetName] then return end
return originalSendPacket(packetName, ...)
end
NetUtil.IsBypassed=true
end
end)
end
function _G.InitializeConnectionGuard()
pcall(function()
if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then return end
print('[ConnectionGuard] Initializing Shield...')
local GC=_G.GameplayCallbacks
local originalDSPlayerState=GC.OnDSPlayerStateChanged
GC.OnDSPlayerStateChanged=function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
local stateStr=InPlayerState and string.lower(tostring(InPlayerState)) or ""
local blockedStates={
["cheatdetected"]=true, ["connectionlost"]=true,
["connectiontimeout"]=true, ["connectionexception"]=true,
["netdrivererror"]=true
}
if blockedStates[stateStr] then return end
if originalDSPlayerState then
pcall(originalDSPlayerState, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
end
end
GC.OnPlayerNetConnectionClosed=function(GameID, UID, Reason, ErrorMessage) end
GC.OnPlayerActorChannelError=function(GameID, UID, Reason, ErrorMessage) end
GC.OnPlayerRPCValidateFailed=function(GameID, UID, Reason, ErrorMessage) end
GC.OnPlayerSpectateException=function(GameID, UID, Reason, ErrorMessage) end
GC.OnShutdownAfterError=function(GameID) end
_G.ConnectionGuardInitialized=true
print('[ConnectionGuard] Active & Protecting!')
end)
end
local function SafeAddMark(id, pos, z, str, size, actor)
local mark=nil
pcall(function()
local InGameMarkTools=require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
mark=InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
if mark then _G.LexusState.TrackedMarks[mark]=true end
end
end)
return mark
end
local function SafeRemoveMark(mark)
if not mark then return end
pcall(function()
local InGameMarkTools=require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
if InGameMarkTools and InGameMarkTools.HideMapMark then
InGameMarkTools.HideMapMark(mark)
end
end)
_G.LexusState.TrackedMarks[mark]=nil
end
local function CheckIsAI(pawn)
local isAI=false
pcall(function()
if pawn.bIsAI ~=nil then isAI=(pawn.bIsAI==true) end
if not isAI and pawn.IsAI ~=nil then isAI=(pawn.IsAI==true) end
if not isAI and pawn.IsBot ~=nil then isAI=(pawn.IsBot==true) end
if not isAI and pawn.PlayerState then
if pawn.PlayerState.bIsABot ~=nil then
isAI=(pawn.PlayerState.bIsABot==true)
end
end
if not isAI then
local name=""
if pawn.PlayerName then name=pawn.PlayerName
elseif type(pawn.GetPlayerName)=="function" then name=pawn:GetPlayerName() end
if name:find("Cobra") or name:find("BOT") or name:find("Target") then
isAI=true
end
end
end)
return isAI
end
local function GetConfigPaths(fileName)
local paths={
"//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
"/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
"/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName,
"/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
"/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName,
"ShadowTrackerExtra/Saved/Paks/" .. fileName,
"../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
"../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
"../../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
fileName
}
pcall(function()
if os and os.getenv then
local homeDir=os.getenv("HOME")
if homeDir and homeDir ~="" then
table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName)
table.insert(paths, 2, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName)
end
end
end)
return paths
end
_G.CustomConfigPathCache=_G.CustomConfigPathCache or false
_G.LastCustomScanTime=_G.LastCustomScanTime or 0
local function ReadCustomConfig()
local config={}
local file=nil
if type(_G.CustomConfigPathCache)=="string" then
file=io.open(_G.CustomConfigPathCache, "r")
end
if not file then
if os.clock()-_G.LastCustomScanTime < 5.0 then return nil end
_G.LastCustomScanTime=os.clock()
local paths=GetConfigPaths("dung0610custom.txt")
for _, path in ipairs(paths) do
file=io.open(path, "r")
if file then
_G.CustomConfigPathCache=path
break
end
end
end
if not file then return nil end
for line in file:lines() do
if line:match("=") then
local key, value=line:match("([%w_]+)%s*=%s*(.+)")
if key and value then
if tonumber(value) then config[key]=tonumber(value)
elseif value=="true" then config[key]=true
elseif value=="false" then config[key]=false
else config[key]=value end
end
end
end
file:close()
return config
end
function _G.InitializeAutoHeadHooks()
pcall(function()
local EAvatarDamagePosition=import("EAvatarDamagePosition")
if not EAvatarDamagePosition then return end
local modulesToHook={
"GameLua.Mod.BaseMod.Common.Weapon.ShootWeaponEntity",
"GameLua.Logic.Weapon.ShootWeaponEntity"
}
for _, path in ipairs(modulesToHook) do
local hitLogic=package.loaded[path]
if hitLogic then
local original_GetHitBodyType=hitLogic.GetHitBodyType
hitLogic.GetHitBodyType=function(self, ImpactResult, InImpactVec)
if _G.LexusConfig.AutoHead then return EAvatarDamagePosition.BigHead end
if original_GetHitBodyType then return original_GetHitBodyType(self, ImpactResult, InImpactVec) end
end
local original_GetHitBodyTypeByHitPos=hitLogic.GetHitBodyTypeByHitPos
hitLogic.GetHitBodyTypeByHitPos=function(self, InImpactVec)
if _G.LexusConfig.AutoHead then return EAvatarDamagePosition.BigHead end
if original_GetHitBodyTypeByHitPos then return original_GetHitBodyTypeByHitPos(self, InImpactVec) end
end
end
end
end)
end
_G.MenuConfigPathCache=_G.MenuConfigPathCache or false
_G.LastMenuScanTime=_G.LastMenuScanTime or 0
local MenuDelayStartTime=os.clock()
local function ReadMenuSettingFile()
local config={}
local file=nil
if type(_G.MenuConfigPathCache)=="string" then
file=io.open(_G.MenuConfigPathCache, "r")
end
if not file then
if os.clock()-_G.LastMenuScanTime < 5.0 then return nil end
_G.LastMenuScanTime=os.clock()
local paths=GetConfigPaths("dung0610_setting.txt")
for _, path in ipairs(paths) do
file=io.open(path, "r")
if file then
_G.MenuConfigPathCache=path
break
end
end
end
if not file then return nil end
local hasData=false
for line in file:lines() do
if line and not line:match("^%s*%-") and line:match("=") then
local key, value=line:match("([%w_]+)%s*=%s*(.+)")
if key and value then
value=value:match("^%s*(.-)%s*$")
if value=="true" then config[key]=true; hasData=true
elseif value=="false" then config[key]=false
elseif tonumber(value) then config[key]=tonumber(value); hasData=true
else config[key]=value; hasData=true end
end
end
end
file:close()
return hasData and config or nil
end
local function ShowLexusVIPMenu()
if _G.LexusMenuAlreadyShown then return end
if _G.LexusState.MenuStep ~=0 then return end
if os.clock()-MenuDelayStartTime < 8.0 then return end
pcall(function()
local autoConfig=ReadMenuSettingFile()
local isAutoLoaded=false
if autoConfig then
for k, v in pairs(autoConfig) do
if _G.LexusConfig[k] ~=nil then
_G.LexusConfig[k]=v
if v==true or (type(v)=="string" and v ~="None") then
isAutoLoaded=true
end
end
end
end
if isAutoLoaded then
Notify("BERHASIL MEMUAT FUNGSI DARI FILE SETTING VIP!")
_G.LexusState.MenuStep=99
_G.LexusMenuAlreadyShown=true
return
end
local Msg=require("client.slua.logic.common.logic_common_msg_box")
if not Msg or not Msg.Show then return end
local function ResetConfig()
for k, v in pairs(_G.LexusConfig) do
if type(v)=="boolean" then _G.LexusConfig[k]=false
elseif k=="AimbotMode" then _G.LexusConfig[k]="None"
elseif k=="OutlineThickness" then _G.LexusConfig[k]=10 end
end
end
local Step_Combo1, Step_Combo2, Step_Combo3
Step_Combo3=function()
Msg.Show(2, "KOMBO MOD 3", "Fitur yang akan diaktifkan sekaligus:\n-Ipad View\n-Buka FPS 165\n-ESP Tipe 3\n-Outline Tipis\n-Recoil Berkurang",
function() ResetConfig(); _G.LexusConfig.IpadView=true; _G.LexusConfig.UnlockFPS=true; _G.LexusConfig.EspVipPro=true; _G.LexusConfig.EspOutline=true; _G.LexusConfig.OutlineThickness=2; _G.LexusConfig.LessRecoil=true; Notify("Kombo 3 Diaktifkan!"); _G.LexusState.MenuStep=99; _G.LexusMenuAlreadyShown=true end,
function() Step_Combo1() end, "PILIH KOMBO 3", "LIHAT KOMBO LAIN")
end
Step_Combo2=function()
Msg.Show(2, "KOMBO MOD 2", "Fitur yang akan diaktifkan sekaligus:\n-Ipad View\n-Buka FPS 165\n-Wallhack & Warna Tubuh\n-Aimbot Jarak Jauh\n-Crosshair Kecil\n-Guncangan Berkurang",
function() ResetConfig(); _G.LexusConfig.IpadView=true; _G.LexusConfig.UnlockFPS=true; _G.LexusConfig.WallXuyenTuong=true; _G.LexusConfig.ColorBodyV2=true; _G.LexusConfig.AimbotMode="Far"; _G.LexusConfig.AimbotDyingRate=true; _G.LexusConfig.Crosshair=true; _G.LexusConfig.LessShake=true; Notify("Kombo 2 Diaktifkan!"); _G.LexusState.MenuStep=99; _G.LexusMenuAlreadyShown=true end,
function() Step_Combo3() end, "PILIH KOMBO 2", "LIHAT KOMBO LAIN")
end
Step_Combo1=function()
Msg.Show(2, "KOMBO MOD 1", "Fitur yang akan diaktifkan sekaligus:\n-Ipad View\n-Buka FPS 165\n-ESP Tipe 1\n-Aimbot Jarak Dekat\n-Recoil Berkurang",
function() ResetConfig(); _G.LexusConfig.IpadView=true; _G.LexusConfig.UnlockFPS=true; _G.LexusConfig.EspVip=true; _G.LexusConfig.AimbotMode="Close"; _G.LexusConfig.AimbotDyingRate=true; _G.LexusConfig.LessRecoil=true; Notify("Kombo 1 Diaktifkan!"); _G.LexusState.MenuStep=99; _G.LexusMenuAlreadyShown=true end,
function() Step_Combo2() end, "PILIH KOMBO 1", "LIHAT KOMBO LAIN")
end
local function Step_ScamAlert()
Msg.Show(1, "PERINGATAN MOD PALSU", "Bergabunglah dengan Telegram Saya untuk Menghindari Mod Palsu. WA 0922520900 TELE @dung0610", function() local Web=require("client.slua.logic.url.logic_webview_sdk"); if Web and Web.OpenURL then Web:OpenURL("https://t.me/TV89AAsSEHYxMTE9") end end, function() end, "GABUNG", "TUTUP")
_G.LexusState.MenuStep=99
_G.LexusMenuAlreadyShown=true
end
local function Step_ModSkin()
Msg.Show(2, "MOD SKIN", "Aktifkan Mod Skin? (Resiko Ban 1 Detik)",
function() _G.LexusConfig.ModSkin=true; Notify("Mod Skin: AKTIF"); Step_ScamAlert() end,
function() _G.LexusConfig.ModSkin=false; Step_ScamAlert() end, "AKTIF", "NONAKTIF")
end
local function Step_FastCar()
Msg.Show(2, "MOBIL CEPAT TERBANG", "Aktifkan Mobil Cepat Terbang?",
function() _G.LexusConfig.FastCar=true; Notify("Mobil Cepat: AKTIF"); Step_ModSkin() end,
function() _G.LexusConfig.FastCar=false; Step_ModSkin() end, "AKTIF", "NONAKTIF")
end
local function Step_WallClimb()
Msg.Show(2, "PANJAT DINDING", "Aktifkan Panjat Dinding?",
function() _G.LexusConfig.WallClimb=true; Notify("Panjat Dinding: AKTIF"); Step_FastCar() end,
function() _G.LexusConfig.WallClimb=false; Step_FastCar() end, "AKTIF", "NONAKTIF")
end
local function Step_CustomMagicBullet()
Msg.Show(2, "MAGIC BULLET KUSTOM", "Aktifkan Magic Bullet Kustom dari File?",
function() _G.LexusConfig.CustomMagicBullet=true; Notify("Magic Bullet Kustom: AKTIF"); Step_WallClimb() end,
function() _G.LexusConfig.CustomMagicBullet=false; Step_WallClimb() end, "AKTIF", "NONAKTIF")
end
local function Step_MagicBullet()
Msg.Show(2, "MAGIC BULLET BIASA", "Aktifkan Magic Bullet Biasa (Hanya Head)?",
function() _G.LexusConfig.MagicBullet=true; Notify("Magic Bullet: AKTIF"); Step_CustomMagicBullet() end,
function() _G.LexusConfig.MagicBullet=false; Step_WallClimb() end, "AKTIF", "NONAKTIF")
end
local function Step_GodMode()
Msg.Show(2, "GOD MODE", "Aktifkan God Mode (Damage Besar)?",
function() _G.LexusConfig.GodMode=true; Notify("God Mode: AKTIF"); Step_MagicBullet() end,
function() _G.LexusConfig.GodMode=false; Step_MagicBullet() end, "AKTIF", "NONAKTIF")
end
local function Step_Accuracy()
Msg.Show(2, "AKURASI PELURU", "Aktifkan Peluru Lurus?",
function() _G.LexusConfig.Accuracy=true; Notify("Peluru Lurus: AKTIF"); Step_GodMode() end,
function() _G.LexusConfig.Accuracy=false; Step_GodMode() end, "PELURU LURUS", "NORMAL")
end
local function Step_Crosshair()
Msg.Show(2, "CROSSHAIR", "Aktifkan Crosshair Kecil?",
function() _G.LexusConfig.Crosshair=true; Notify("Crosshair Kecil: AKTIF"); Step_Accuracy() end,
function() _G.LexusConfig.Crosshair=false; Step_Accuracy() end, "CROSSHAIR KECIL", "NORMAL")
end
local function Step_LessShake()
Msg.Show(2, "KURANGI GUNCANGAN", "Aktifkan Pengurangan Guncangan & Scope?",
function() _G.LexusConfig.LessShake=true; Notify("Kurang Guncang: AKTIF"); Step_Crosshair() end,
function() _G.LexusConfig.LessShake=false; Step_Crosshair() end, "AKTIF", "NONAKTIF")
end
local function Step_CustomVRecoil()
Msg.Show(2, "KURANGI RECOIL VERTIKAL KUSTOM", "Aktifkan Recoil Vertikal Kustom dari File?",
function() _G.LexusConfig.CustomVRecoil=true; Notify("Recoil Vertikal Kustom: AKTIF"); Step_LessShake() end,
function() _G.LexusConfig.CustomVRecoil=false; Step_LessShake() end, "AKTIF", "NONAKTIF")
end
local function Step_VerticalRecoil()
Msg.Show(2, "KURANGI RECOIL VERTIKAL", "Aktifkan Pengurangan Recoil Vertikal?",
function() _G.LexusConfig.VerticalRecoil=true; Notify("Recoil Vertikal: AKTIF"); Step_CustomVRecoil() end,
function() _G.LexusConfig.VerticalRecoil=false; Step_LessShake() end, "AKTIF", "NONAKTIF")
end
local function Step_CustomHRecoil()
Msg.Show(2, "KURANGI RECOIL HORIZONTAL KUSTOM", "Aktifkan Recoil Horizontal Kustom dari File?",
function() _G.LexusConfig.CustomHRecoil=true; Notify("Recoil Horizontal Kustom: AKTIF"); Step_VerticalRecoil() end,
function() _G.LexusConfig.CustomHRecoil=false; Step_VerticalRecoil() end, "AKTIF", "NONAKTIF")
end
local function Step_LessRecoil()
Msg.Show(2, "KURANGI RECOIL HORIZONTAL", "Aktifkan Pengurangan Recoil Horizontal?",
function() _G.LexusConfig.LessRecoil=true; Notify("Recoil Horizontal: AKTIF"); Step_CustomHRecoil() end,
function() _G.LexusConfig.LessRecoil=false; Step_VerticalRecoil() end, "AKTIF", "NONAKTIF")
end
local function Step_AutoHead()
Msg.Show(2, "AIMBOT HEAD", "Aktifkan Aimbot Kepala? (Resiko Ban Tinggi)",
function() _G.LexusConfig.AutoHead=true; Notify("Auto Head: AKTIF"); Step_LessRecoil() end,
function() _G.LexusConfig.AutoHead=false; Step_LessRecoil() end, "AKTIF", "NONAKTIF")
end
local function Step_CustomAimbot()
Msg.Show(2, "AIMBOT KUSTOM DARI FILE", "Aktifkan Aimbot Kustom dari File?",
function() _G.LexusConfig.CustomAimbot=true; Notify("Aimbot Kustom: AKTIF"); Step_AutoHead() end,
function() _G.LexusConfig.CustomAimbot=false; Step_AutoHead() end, "AKTIF", "NONAKTIF")
end
local function Step_Aimbot()
Msg.Show(2, "PENGATURAN AIMBOT", "Pilih Jarak Aimbot (Dekat atau Jauh)\nJika Aimbot Tidak Bekerja, Keluarkan Senjata dan Masukkan Lagi",
function() _G.LexusConfig.AimbotMode="Close"; _G.LexusConfig.AimbotDyingRate=true; Step_CustomAimbot() end,
function() _G.LexusConfig.AimbotMode="Far"; _G.LexusConfig.AimbotDyingRate=true; Step_CustomAimbot() end,
"AIM DEKAT", "AIM JAUH")
end
local function Step_WallAndColor()
Msg.Show(2, "WALLHACK & WARNA TUBUH", "Aktifkan Wallhack dan Warna Tubuh?",
function() _G.LexusConfig.WallXuyenTuong=true; _G.LexusConfig.ColorBodyV2=true; Notify("Wall & Warna Tubuh: AKTIF"); Step_Aimbot() end,
function() _G.LexusConfig.WallXuyenTuong=false; _G.LexusConfig.ColorBodyV2=false; Step_Aimbot() end,
"AKTIF", "NONAKTIF")
end
local function Step_WhiteBody()
Msg.Show(2, "TUBUH PUTIH", "Aktifkan Tubuh Putih?",
function() _G.LexusConfig.WhiteBody=true; Notify("Tubuh Putih: AKTIF"); Step_WallAndColor() end,
function() _G.LexusConfig.WhiteBody=false; Step_WallAndColor() end, "AKTIF", "NONAKTIF")
end
local function Step_RemoveFog()
Msg.Show(2, "HAPUS KABUT", "Aktifkan Penghapusan Kabut?",
function() _G.LexusConfig.RemoveFog=true; Notify("Hapus Kabut: AKTIF"); Step_WhiteBody() end,
function() _G.LexusConfig.RemoveFog=false; Step_WhiteBody() end, "AKTIF", "NONAKTIF")
end
local function Step_RemoveGrass()
Msg.Show(2, "HAPUS RUMPUT", "Aktifkan Penghapusan Rumput?",
function() _G.LexusConfig.RemoveGrass=true; Notify("Hapus Rumput: AKTIF"); Step_RemoveFog() end,
function() _G.LexusConfig.RemoveGrass=false; Step_RemoveFog() end, "AKTIF", "NONAKTIF")
end
local function Step_OutlineThickness()
Msg.Show(2, "KETEBALAN OUTLINE", "Pilih Ketebalan Outline Tebal atau Tipis?",
function() _G.LexusConfig.OutlineThickness=10; Step_RemoveGrass() end,
function() _G.LexusConfig.OutlineThickness=2; Step_RemoveGrass() end,
"OUTLINE TEBAL", "OUTLINE TIPIS")
end
local function Step_OutlineToggle()
Msg.Show(2, "OUTLINE MUSUH", "Aktifkan Outline Warna Musuh?",
function() _G.LexusConfig.EspOutline=true; Step_OutlineThickness() end,
function() _G.LexusConfig.EspOutline=false; Step_RemoveGrass() end,
"AKTIF", "NONAKTIF")
end
local function Step_EspAntenna()
Msg.Show(2, "ANTENA ESP", "Aktifkan Antena di Atas Kepala?",
function() _G.LexusConfig.EspAntenna=true; Notify("ESP Antena: AKTIF"); Step_OutlineToggle() end,
function() _G.LexusConfig.EspAntenna=false; Step_OutlineToggle() end, "AKTIF", "NONAKTIF")
end
local function Step_EspLoai7()
Msg.Show(2, "ESP TIPE 7", "TIPE 7: Bedakan Bot & Pemain, Info Senjata\nAktifkan?",
function() _G.LexusConfig.EspLoai7=true; Notify("ESP Tipe 7: AKTIF"); Step_EspAntenna() end,
function() _G.LexusConfig.EspLoai7=false; Step_EspAntenna() end, "AKTIF", "NONAKTIF")
end
local function Step_EspLoai6()
Msg.Show(2, "ESP TIPE 6", "TIPE 6: Tulang/Bone ESP\nAktifkan?",
function() _G.LexusConfig.EspLoai6=true; Notify("ESP Tipe 6: AKTIF"); Step_EspLoai7() end,
function() _G.LexusConfig.EspLoai6=false; Step_EspLoai7() end, "AKTIF", "NONAKTIF")
end
local function Step_EspLoai5()
Msg.Show(2, "ESP TIPE 5", "TIPE 5: Kotak/Kotak Hitpoint\nAktifkan?",
function() _G.LexusConfig.EspLoai5=true; Notify("ESP Tipe 5: AKTIF"); Step_EspLoai6() end,
function() _G.LexusConfig.EspLoai5=false; Step_EspLoai6() end, "AKTIF", "NONAKTIF")
end
local function Step_EspRadar()
Msg.Show(2, "ESP TIPE 4", "TIPE 4: Radar 360\u00b0 di Minimap\nAktifkan?",
function() _G.LexusConfig.EspRadar=true; Notify("ESP Tipe 4: AKTIF"); Step_EspLoai5() end,
function() _G.LexusConfig.EspRadar=false; Step_EspLoai5() end, "AKTIF", "NONAKTIF")
end
local function Step_EspVipPro()
Msg.Show(2, "ESP TIPE 3", "TIPE 3: Health Bar Vertikal & Nama\nAktifkan?",
function() _G.LexusConfig.EspVipPro=true; Notify("ESP Tipe 3: AKTIF"); Step_EspRadar() end,
function() _G.LexusConfig.EspVipPro=false; Step_EspRadar() end, "AKTIF", "NONAKTIF")
end
local function Step_EspDistance()
Msg.Show(2, "ESP TIPE 2", "TIPE 2: Jarak dalam Meter\nAktifkan?",
function() _G.LexusConfig.EspDistance=true; Notify("ESP Tipe 2: AKTIF"); Step_EspVipPro() end,
function() _G.LexusConfig.EspDistance=false; Step_EspVipPro() end, "AKTIF", "NONAKTIF")
end
local function Step_EspVip()
Msg.Show(2, "ESP TIPE 1", "TIPE 1: Notifikasi 360\u00b0, HP, Nama, Jarak\nAktifkan?",
function() _G.LexusConfig.EspVip=true; Notify("ESP Tipe 1: AKTIF"); Step_EspDistance() end,
function() _G.LexusConfig.EspVip=false; Step_EspDistance() end, "AKTIF", "NONAKTIF")
end
local function Step_IpadView()
Msg.Show(2, "IPAD VIEW", "Aktifkan IPad View (FOV Lebar)?",
function() _G.LexusConfig.IpadView=true; Notify("Ipad View: AKTIF"); Step_EspVip() end,
function() _G.LexusConfig.IpadView=false; Step_EspVip() end, "AKTIF", "NONAKTIF")
end
local function Step_165FPS()
Msg.Show(2, "BUKA KUNCI 165 FPS", "Aktifkan Buka Kunci UI dan 165 FPS?",
function() _G.LexusConfig.UnlockFPS=true; Notify("165 FPS: AKTIF"); Step_IpadView() end,
function() _G.LexusConfig.UnlockFPS=false; Step_IpadView() end, "AKTIF", "NONAKTIF")
end
local function Step_Welcome()
Msg.Show(2, "SELAMAT DATANG", "Halo, ini adalah Tool VIP. File pengaturan tidak ditemukan. Ingin mengatur manual atau pilih kombo mod?\n\nPeringatan: Jangan aktifkan terlalu banyak fitur karena bisa menyebabkan lag!\nHati-hati saat menembak, jangan terlalu mencolok. Mod Skin resiko ban 1 detik!",
function() Step_165FPS() end,
function() Step_Combo1() end, "PILIH FITUR MANUAL", "PILIH KOMBO MOD")
end
_G.LexusState.MenuStep=1
Step_Welcome()
end)
end
local function InitializeGraphicsUnlock()
if isExpired then return end
if _G.LexusState.GraphicsUnlocked or currentTime > limitTime then return end
pcall(function()
local SettingCfg=require("client.logic.setting.setting_config")
local GraphicSettingDB=require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
if SettingCfg then
if SettingCfg.TpViewValue then SettingCfg.TpViewValue.max=140 end
if SettingCfg.FpViewValue then SettingCfg.FpViewValue.max=140 end
end
if GraphicSettingDB then
if GraphicSettingDB.TpViewValue then GraphicSettingDB.TpViewValue.max=140 end
end
end)
pcall(function()
local logic_setting_graphics=require("client.slua.logic.setting.logic_setting_graphics")
local GSC_FPS=require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
local GSC_FPSFT=require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
local GraphicSettingDB=require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
local KismetMathLibrary=import("KismetMathLibrary") or _G.KismetMathLibrary
local FLinearColor=import("LinearColor") or _G.FLinearColor
if logic_setting_graphics then
local old_SetFPS=logic_setting_graphics.SetFPS
function logic_setting_graphics.SetFPS(gameInstance, FPSLevel)
if old_SetFPS then old_SetFPS(gameInstance, FPSLevel) end
if FPSLevel==8 then
gameInstance:ExecuteCMD("t.MaxFPS", "165")
gameInstance:ExecuteCMD("r.FrameRateLimit", "165")
end
end
end
if GSC_FPS and GSC_FPS.__inner_impl then
local fps_impl=GSC_FPS.__inner_impl
function fps_impl:GetMaxFPSLevel() return 8, 8 end
function fps_impl:InitRealSupportFPS()
local RealSupportFPS={}
for i=1, 8 do RealSupportFPS[i]={true, true} end
if GraphicSettingDB then GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, RealSupportFPS, false) end
return RealSupportFPS
end
function fps_impl:UpdateSelectedFPSState(selectedLevel)
if not slua.isValid(self.UIRoot) then return end
for level=2, 8 do
local name="NodeFps" .. (({[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120})[level] or 120)
local widget=self.UIRoot[name]
if slua.isValid(widget) then
widget:SetIsEnabled(true)
pcall(function() widget:SetRenderOpacity(1.0) end)
local switcher=self.UIRoot["WidgetSwitcher_" .. level]
if slua.isValid(switcher) then
switcher:SetActiveWidgetIndex(level==selectedLevel and 0 or 1)
end
end
end
end
end
if GSC_FPSFT and GSC_FPSFT.__inner_impl then
local ft_impl=GSC_FPSFT.__inner_impl
local NMinFPS, NStep=90, 5
local function clamp(value, min, max)
if value < min then return min end
if max < value then return max end
return value
end
local function lerp(a, b, t) return a+(b-a)*t end
local function _getColorByPercent(start, finish, percent)
if not FLinearColor then return nil end
return FLinearColor(lerp(start.R, finish.R, percent), lerp(start.G, finish.G, percent), lerp(start.B, finish.B, percent), lerp(start.A, finish.A, percent))
end
ft_impl.ShowOrHide=function(self)
self:SelfHitTestInvisible()
if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end
end
ft_impl.InitFPSFTSwitch=function(self)
local FPSFineTuneSwitch=GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(FPSFineTuneSwitch, true) end
if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, FPSFineTuneSwitch) end
if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
end
ft_impl.InitFPSFTValue165=function(self)
local itemRoot=self.UIRoot
local FPSFineTuneSwitch=GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
local FPSFineTuneNum=165
if FPSFineTuneSwitch then
FPSFineTuneNum=GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165
itemRoot.Slider_screen3:SetLocked(false)
if FLinearColor then
itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 1.0, 1.0, 1.0))
itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 1.0, 1.0, 1.0))
end
else
itemRoot.Slider_screen3:SetLocked(true)
if FLinearColor then
itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 0.625, 0.6, 1))
itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 0.625, 0.6, 1.0))
end
end
local FPSFineTunePer=(FPSFineTuneNum-NMinFPS)/(165-NMinFPS)
itemRoot.Veihclescreen3:SetText(tostring(FPSFineTuneNum))
itemRoot.Slider_screen3:SetValue(FPSFineTunePer)
itemRoot.ProgressBar_screen3:SetPercent(FPSFineTunePer)
if FLinearColor then
local startColor=FLinearColor(1.0, 1.0, 1.0, 1.0)
local midColor=FLinearColor(1.0, 0.54, 0.11, 1.0)
local endColor=FLinearColor(1.0, 0.23, 0.15, 1.0)
local sliderColor=FPSFineTunePer < 0.4 and startColor or _getColorByPercent(midColor, endColor, (FPSFineTunePer-0.4)/0.6)
itemRoot.Slider_screen3:SetSliderHandleColor(sliderColor)
end
end
ft_impl.OnFPSFTValueChange3=function(self, FPSFineTuneNum)
GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, FPSFineTuneNum)
if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
local gameInstance=GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
if gameInstance then
gameInstance:ExecuteCMD("t.MaxFPS", tostring(FPSFineTuneNum))
gameInstance:ExecuteCMD("r.FrameRateLimit", tostring(FPSFineTuneNum))
end
end
ft_impl.OnFPSFTSliderValueChange3=function(self, value)
if GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) and KismetMathLibrary then
local FPSFineTuneNum=KismetMathLibrary.FCeil(value*(165-NMinFPS)/NStep)*NStep+NMinFPS
self:OnFPSFTValueChange3(clamp(FPSFineTuneNum, NMinFPS, 165))
end
end
ft_impl.OnFPSFTAdd=ft_impl.OnFPSFTAdd3
ft_impl.OnFPSFTMinus=ft_impl.OnFPSFTMinus3
ft_impl.OnFPSFTAdd2=ft_impl.OnFPSFTAdd3
ft_impl.OnFPSFTMinus2=ft_impl.OnFPSFTMinus3
ft_impl.OnFPSFTSliderValueChange=ft_impl.OnFPSFTSliderValueChange3
ft_impl.OnFPSFTSliderValueChange2=ft_impl.OnFPSFTSliderValueChange3
end
end)
_G.LexusState.GraphicsUnlocked=true
Notify("Graphics & FPS 165Hz Unlocked (Upgraded Version)")
end
local function InitializeNativeESP()
if _G.LexusState.NativeESPReady then return end
pcall(function()
local GamePlayTools=require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local currentMarkCfg=GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
local function ApplyCfg(cfg)
if not cfg then return end
if cfg[1006] then
cfg[1006].bBindBlocked=true;
cfg[1006].bBindOutScreen=true;
cfg[1006].MaxWidgetNum=99
cfg[1006].MaxShowDistance=6000000;
cfg[1006].bScaleByDistance=false
cfg[1006].BindSocketName="root";
cfg[1006].bUseLuaWorldSocketName=true
cfg[1006].WorldPositionOffset=FVector(0, 0,-30)
end
if cfg[1003] then
cfg[1003].bBindBlocked=true;
cfg[1003].bBindOutScreen=true;
cfg[1003].MaxWidgetNum=99
cfg[1003].MaxShowDistance=6000000;
cfg[1003].bScaleByDistance=false
cfg[1003].BindSocketName="head";
cfg[1003].bUseLuaWorldSocketName=true
end
cfg[9999]={
UIPathName="/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
MaxWidgetNum=99,
MaxShowDistance=6000000,
bBindOutScreen=true,
bBindBlocked=true,
bIsBindingActor=true,
BindSocketName="head",
bUseLuaWorldSocketName=true,
WorldPositionOffset=FVector(0, 0, 50),
bNeedPreLoad=true,
Priority=2
}
end
ApplyCfg(currentMarkCfg)
for k, cfg in pairs(package.loaded) do
if type(k)=="string" and string.find(k, "ScreenMarkConfig") and type(cfg)=="table" then
ApplyCfg(cfg)
end
end
end)
_G.LexusState.NativeESPReady=true
Notify("Native ESP System Initialized")
end
local C_GREEN={R=0, G=255, B=0, A=255}
local function GetAllSkeletalMeshes(enemy)
local curTime=os.clock()
if enemy.AK_CACHED_MESHES and enemy.AK_CACHED_MESH_TIME and (curTime-enemy.AK_CACHED_MESH_TIME < 3.0) then
local valid_cache={}
for _, m in ipairs(enemy.AK_CACHED_MESHES) do
if Valid(m) then table.insert(valid_cache, m) end
end
if #valid_cache > 0 then return valid_cache end
end
local meshes={}
if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
pcall(function()
local SkeletalMeshClass=import("SkeletalMeshComponent")
if SkeletalMeshClass and type(enemy.GetComponentsByClass)=="function" then
local childs=enemy:GetComponentsByClass(SkeletalMeshClass)
if childs then
local count=type(childs.Num)=="function" and childs:Num() or #childs
for i=1, count do
local comp=type(childs.Get)=="function" and childs:Get(i-1) or childs[i]
if Valid(comp) and comp ~=enemy.Mesh then
table.insert(meshes, comp)
end
end
end
end
end)
enemy.AK_CACHED_MESHES=meshes
enemy.AK_CACHED_MESH_TIME=curTime
return meshes
end
local function ApplyWallXuyenTuong(enemy)
pcall(function()
local meshes=GetAllSkeletalMeshes(enemy)
for _, mesh in ipairs(meshes) do
for i=0, 10 do
local matInterface=mesh:GetMaterial(i)
if Valid(matInterface) then
local baseMat=matInterface:GetBaseMaterial()
if Valid(baseMat) then
baseMat.bDisableDepthTest=true
baseMat.BlendMode=2
end
end
end
end
end)
end
local function ApplyColorBodyV2(enemy, pc)
pcall(function()
local meshes=GetAllSkeletalMeshes(enemy)
if #meshes==0 then return end
local hidden=true
pcall(function()
if Valid(pc) and type(pc.LineOfSightTo)=="function" then
if pc:LineOfSightTo(enemy) then hidden=false else hidden=true end
end
end)
local cData=_G.LexusState.CustomTextData or {}
local hiddenColor={
R=cData.HiddenR or 150,
G=cData.HiddenG or 0,
B=cData.HiddenB or 0,
A=cData.HiddenA or 25
}
local visibleColor={
R=cData.VisibleR or 0,
G=cData.VisibleG or 150,
B=cData.VisibleB or 0,
A=cData.VisibleA or 25
}
local finalColor=hidden and hiddenColor or visibleColor
local colorHash=string.format("%d_%d_%d_%d", finalColor.R, finalColor.G, finalColor.B, finalColor.A)
local currentMeshCount=#meshes
local isMeshChanged=(enemy.AK_LAST_MESH_COUNT ~=currentMeshCount)
if not isMeshChanged and enemy.AK_LAST_HIDDEN_STATE==hidden and enemy.AK_LAST_COLOR_HASH==colorHash then
return
end
enemy.AK_LAST_HIDDEN_STATE=hidden
enemy.AK_LAST_MESH_COUNT=currentMeshCount
enemy.AK_LAST_COLOR_HASH=colorHash
local scale={R=3, G=3, B=0, A=0}
for _, mesh in ipairs(meshes) do
pcall(function()
mesh.LDMaxDrawDistance=-99999
mesh.MaxDrawDistanceOffset=-99999
mesh.CachedMaxDrawDistance=-99999
mesh.UseScopeDistanceCulling=true
mesh.PrimitiveShadingStrategy=1
mesh.ShadingRate=6
end)
for i=0, 20 do
local matInterface=mesh:GetMaterial(i)
if Valid(matInterface) then
local baseMat=matInterface:GetBaseMaterial()
if Valid(baseMat) then
local matName=tostring(baseMat)
if string.find(matName, "Master_Mask", 1, true) then
local mid=mesh:CreateAndSetMaterialInstanceDynamic(i)
if Valid(mid) then
mid:SetVectorParameterValue("颜色", finalColor)
mid:SetVectorParameterValue("Extra Light Color", finalColor)
mid:SetVectorParameterValue("Para_Color", finalColor)
mid:SetVectorParameterValue("Para_ColorTint", finalColor)
mid:SetVectorParameterValue("Para_Color_1", finalColor)
mid:SetVectorParameterValue("Tint", finalColor)
mid:SetVectorParameterValue("Color", finalColor)
mid:SetVectorParameterValue("BaseColor", finalColor)
mid:SetVectorParameterValue("BodyColor", finalColor)
mid:SetVectorParameterValue("MainColor", finalColor)
mid:SetVectorParameterValue("DiffuseColor", finalColor)
mid:SetVectorParameterValue("EmissiveColor", finalColor)
mid:SetVectorParameterValue("ParaScaleOffset", scale)
end
end
end
end
end
end
end)
end
local function MainLoop()
if isExpired then return end
local okData, GameplayData=pcall(require, "GameLua.GameCore.Data.GameplayData")
if not okData or not GameplayData then return end
local pc=GameplayData.GetPlayerController()
local localPlayer=nil
if Valid(pc) then localPlayer=pc:GetPlayerCharacterSafety() end
if not Valid(localPlayer) then
if _G.LexusState.TrackedMarks then
for markId, _ in pairs(_G.LexusState.TrackedMarks) do
SafeRemoveMark(markId)
end
end
_G.LexusState.EnemyMarks={}
return
end
local Cached_PPM=nil
pcall(function() Cached_PPM=import("PostProcessManager").GetInstance() end)
local Cached_SecurityCommonUtils=nil
pcall(function() Cached_SecurityCommonUtils=require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)
local Cached_MyHUD=pc and pc.MyHUD or nil
if _G.LexusConfig.UnlockFPS then InitializeGraphicsUnlock() end
InitializeNativeESP()
ShowLexusVIPMenu()
pcall(function()
local SubsystemMgr=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
local SettingSubsystem=SubsystemMgr:Get("SettingSubsystem")
if SettingSubsystem and _G.LexusConfig.IpadView then
local rawSliderValue=SettingSubsystem:GetUserSettings_Int("TpViewValue") or 90
local targetTPP=(rawSliderValue > 80 and rawSliderValue <=90) and (80+(rawSliderValue-80)*6.0) or rawSliderValue
local uTPPCam=localPlayer.ThirdPersonCameraComponent
if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
if uTPPCam.FieldOfView ~=targetTPP then uTPPCam.FieldOfView=targetTPP end
end
end
end)
if _G.LexusConfig.WallClimb then
pcall(function()
local charMove=localPlayer.CharacterMovement
if Valid(charMove) then
charMove.WalkableFloorAngle=199.0
charMove.MaxStepHeight=999.0
end
end)
end
if _G.LexusConfig.FastCar then
pcall(function()
local currentVehicle=localPlayer.CurrentVehicle or (type(localPlayer.GetVehicle)=="function" and localPlayer:GetVehicle())
if Valid(currentVehicle) then
local rootComp=currentVehicle.RootComponent or (type(currentVehicle.K2_GetRootComponent)=="function" and currentVehicle:K2_GetRootComponent())
if Valid(rootComp) and type(rootComp.SetAllPhysicsLinearVelocity)=="function" then
local isAccelerating=false
local moveComp=currentVehicle.VehicleMovement or currentVehicle.MovementComponent
if Valid(moveComp) then
local throttle=moveComp.ThrottleInput or 0
if type(moveComp.GetThrottleInput)=="function" then
throttle=moveComp:GetThrottleInput()
end
if throttle > 0.05 or throttle <-0.05 then
isAccelerating=true
end
end
if currentVehicle.bIsPressingGas or (currentVehicle.Throttle and currentVehicle.Throttle ~=0) then
isAccelerating=true
end
local currentVel=nil
if type(currentVehicle.GetVelocity)=="function" then
currentVel=currentVehicle:GetVelocity()
elseif type(rootComp.GetPhysicsLinearVelocity)=="function" then
currentVel=rootComp:GetPhysicsLinearVelocity()
elseif rootComp.ComponentVelocity then
currentVel=rootComp.ComponentVelocity
end
if currentVel then
local currentSpeed=math.sqrt(currentVel.X^2+currentVel.Y^2)
local minSpeedToBoost=50.0
local maxSpeed=4444.0
local accelFactor=1.5
local brakeFactor=0.85
if currentSpeed > minSpeedToBoost then
local dirX=currentVel.X/currentSpeed
local dirY=currentVel.Y/currentSpeed
if isAccelerating then
local targetSpeed=currentSpeed*accelFactor
if targetSpeed > maxSpeed then
targetSpeed=maxSpeed
end
local newX=dirX*targetSpeed
local newY=dirY*targetSpeed
local newZ=currentVel.Z
rootComp:SetAllPhysicsLinearVelocity(FVector(newX, newY, newZ), false)
else
local targetSpeed=currentSpeed*brakeFactor
if targetSpeed > minSpeedToBoost then
local newX=dirX*targetSpeed
local newY=dirY*targetSpeed
local newZ=currentVel.Z
rootComp:SetAllPhysicsLinearVelocity(FVector(newX, newY, newZ), false)
end
end
end
end
end
end
end)
end
local now=os.clock()
if (_G.LexusConfig.RemoveGrass or _G.LexusConfig.RemoveFog or _G.LexusConfig.WhiteBody or _G.LexusConfig.ColorBodyV2) and (now-_G.LexusState.LastCmdTime > 5.0) then
pcall(function()
local lsg=require("client.slua.logic.setting.logic_setting_graphics")
local gi=lsg.GetGameInstance()
if gi then
if _G.LexusConfig.RemoveGrass then
gi:ExecuteCMD("grass.DensityScale", "0")
gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
end
if _G.LexusConfig.RemoveFog then
gi:ExecuteCMD("r.SkyAtmosphere", "1")
gi:ExecuteCMD("r.Fog", "0")
gi:ExecuteCMD("r.VolumetricFog", "0")
end
if _G.LexusConfig.WhiteBody then
gi:ExecuteCMD("r.CharacterDiffuseOffset", "2")
gi:ExecuteCMD("r.CharacterDiffusePower", "5")
gi:ExecuteCMD("r.CharacterMinShadowFactor", "100")
end
if _G.LexusConfig.ColorBodyV2 then
gi:ExecuteCMD("r.CharacterMinShadowFactor", "4")
gi:ExecuteCMD("r.CharacterDiffuseOffset", "200")
gi:ExecuteCMD("r.CharacterDiffusePower", "200")
end
end
end)
_G.LexusState.LastCmdTime=now
end
pcall(function()
local weapon=nil
pcall(function()
local weaponManager=localPlayer.WeaponManagerComponent
if Valid(weaponManager) and type(weaponManager.GetCurrentWeapon)=="function" then
weapon=weaponManager:GetCurrentWeapon()
end
end)
if not Valid(weapon) then
if type(localPlayer.GetCurrentShootWeapon)=="function" then weapon=localPlayer:GetCurrentShootWeapon()
elseif type(localPlayer.GetCurrentWeapon)=="function" then weapon=localPlayer:GetCurrentWeapon() end
end
if Valid(weapon) then
local entities={}
if Valid(weapon.ShootWeaponEntity_GEN_VARIABLE) then table.insert(entities, weapon.ShootWeaponEntity_GEN_VARIABLE) end
if Valid(weapon.ShootWeaponEntity) then table.insert(entities, weapon.ShootWeaponEntity) end
if Valid(weapon.ShootWeaponComponent) and Valid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent) then
table.insert(entities, weapon.ShootWeaponComponent.ShootWeaponEntityComponent)
end
if _G.LexusConfig.AutoHead then
pcall(function()
local autoComp=nil
if localPlayer.AutoAimComp then autoComp=localPlayer.AutoAimComp
elseif weapon.AutoAimComp then autoComp=weapon.AutoAimComp end
if Valid(autoComp) then
autoComp.Bones={ "Head", "Head", "Head" }
end
end)
end
for _, entity in ipairs(entities) do
if _G.LexusConfig.GodMode then
entity.GameDeviationFactor=0.0
entity.GameDeviationAccuracy=0.0
entity.BulletFireSpeed=500000000.0
entity.ShootInterval=0.001
entity.BaseDamage=6000005.0
entity.HitDamage=60005.0
end
if _G.LexusConfig.Crosshair then entity.GameDeviationFactor=0.1 end
if _G.LexusConfig.Accuracy then entity.GameDeviationAccuracy=0.1 end
if _G.LexusConfig.CustomHRecoil and _G.LexusState.CustomTextData and _G.LexusState.CustomTextData.HRecoil ~=nil then
entity.AccessoriesHRecoilFactor=_G.LexusState.CustomTextData.HRecoil
elseif _G.LexusConfig.LessRecoil then
entity.AccessoriesHRecoilFactor=0.3
end
if _G.LexusConfig.CustomVRecoil and _G.LexusState.CustomTextData and _G.LexusState.CustomTextData.VRecoil ~=nil then
entity.AccessoriesVRecoilFactor=_G.LexusState.CustomTextData.VRecoil
elseif _G.LexusConfig.VerticalRecoil then
entity.AccessoriesVRecoilFactor=0.3
end
if _G.LexusConfig.LessShake then
entity.RecoilKick=0.0
entity.RecoilKickADS=0.0
entity.AnimationKick=0.0
entity.RecoilModifierStand=0
entity.RecoilModifierCrouch=0
entity.RecoilModifierProne=0
if entity.RecoilInfo then
entity.RecoilInfo.VerticalRecoilMin=0.0
entity.RecoilInfo.VerticalRecoilMax=0.0
entity.RecoilInfo.RecoilSpeedVertical=0.0
entity.RecoilInfo.RecoilSpeedHorizontal=0.0
end
end
if entity.AutoAimingConfig then
if _G.LexusConfig.AutoHead then
pcall(function() entity.AutoAimingConfig.Bones={ "Head", "Head", "Head" } end)
end
if _G.LexusConfig.CustomAimbot and _G.LexusState.CustomTextData then
local cData=_G.LexusState.CustomTextData
if entity.AutoAimingConfig.OuterRange then
if cData.OuterSpeed then entity.AutoAimingConfig.OuterRange.Speed=cData.OuterSpeed end
if cData.OuterRangeRate then entity.AutoAimingConfig.OuterRange.RangeRate=cData.OuterRangeRate end
if cData.OuterSpeedRate then entity.AutoAimingConfig.OuterRange.SpeedRate=cData.OuterSpeedRate end
if cData.OuterRangeRateSight then entity.AutoAimingConfig.OuterRange.RangeRateSight=cData.OuterRangeRateSight end
if cData.OuterSpeedRateSight then entity.AutoAimingConfig.OuterRange.SpeedRateSight=cData.OuterSpeedRateSight end
if cData.OuterCrouchRate then entity.AutoAimingConfig.OuterRange.CrouchRate=cData.OuterCrouchRate end
if cData.OuterProneRate then entity.AutoAimingConfig.OuterRange.ProneRate=cData.OuterProneRate end
end
if entity.AutoAimingConfig.InnerRange then
if cData.InnerSpeed then entity.AutoAimingConfig.InnerRange.Speed=cData.InnerSpeed end
if cData.InnerRangeRate then entity.AutoAimingConfig.InnerRange.RangeRate=cData.InnerRangeRate end
if cData.InnerSpeedRate then entity.AutoAimingConfig.InnerRange.SpeedRate=cData.InnerSpeedRate end
if cData.InnerRangeRateSight then entity.AutoAimingConfig.InnerRange.RangeRateSight=cData.InnerRangeRateSight end
if cData.InnerSpeedRateSight then entity.AutoAimingConfig.InnerRange.SpeedRateSight=cData.InnerSpeedRateSight end
if cData.InnerCrouchRate then entity.AutoAimingConfig.InnerRange.CrouchRate=cData.InnerCrouchRate end
if cData.InnerProneRate then entity.AutoAimingConfig.InnerRange.ProneRate=cData.InnerProneRate end
end
if cData.DyingRate then
if entity.AutoAimingConfig.OuterRange then entity.AutoAimingConfig.OuterRange.DyingRate=cData.DyingRate end
if entity.AutoAimingConfig.InnerRange then entity.AutoAimingConfig.InnerRange.DyingRate=cData.DyingRate end
end
else
if _G.LexusConfig.AimbotMode=="Close" then
if entity.AutoAimingConfig.OuterRange then entity.AutoAimingConfig.OuterRange.Speed=10 end
if entity.AutoAimingConfig.InnerRange then entity.AutoAimingConfig.InnerRange.Speed=10 end
elseif _G.LexusConfig.AimbotMode=="Far" then
if entity.AutoAimingConfig.OuterRange then
entity.AutoAimingConfig.OuterRange.Speed=5
entity.AutoAimingConfig.OuterRange.RangeRate=0.7
entity.AutoAimingConfig.OuterRange.SpeedRate=1.3
entity.AutoAimingConfig.OuterRange.RangeRateSight=1.8
entity.AutoAimingConfig.OuterRange.SpeedRateSight=2.2
entity.AutoAimingConfig.OuterRange.CrouchRate=1.1
entity.AutoAimingConfig.OuterRange.ProneRate=1
end
if entity.AutoAimingConfig.InnerRange then
entity.AutoAimingConfig.InnerRange.Speed=5
entity.AutoAimingConfig.InnerRange.RangeRate=0.7
entity.AutoAimingConfig.InnerRange.SpeedRate=1.3
entity.AutoAimingConfig.InnerRange.RangeRateSight=1.8
entity.AutoAimingConfig.InnerRange.SpeedRateSight=2.2
entity.AutoAimingConfig.InnerRange.CrouchRate=1.1
entity.AutoAimingConfig.InnerRange.ProneRate=1
end
end
if _G.LexusConfig.AimbotDyingRate then
if entity.AutoAimingConfig.OuterRange then entity.AutoAimingConfig.OuterRange.DyingRate=0.0 end
if entity.AutoAimingConfig.InnerRange then entity.AutoAimingConfig.InnerRange.DyingRate=0.0 end
end
end
end
end
end
end)
pcall(function()
for eKey, data in pairs(_G.LexusState.EnemyMarks) do
local eObj=data.enemy
local bIsDead=true
if Valid(eObj) then
bIsDead=false
pcall(function()
if type(eObj.IsDead)=="function" then bIsDead=eObj:IsDead()
elseif eObj.bIsDead ~=nil then bIsDead=eObj.bIsDead
elseif eObj.bIsDeadFlag ~=nil then bIsDead=eObj.bIsDeadFlag end
if eObj.HealthStatus ~=nil and eObj.HealthStatus==2 then bIsDead=true end
end)
end
if bIsDead then
SafeRemoveMark(data.radarMark)
SafeRemoveMark(data.hpMark)
SafeRemoveMark(data.distMark)
data.radarMark=nil
data.hpMark=nil
data.distMark=nil
pcall(function()
if Valid(eObj) then
if eObj.Replay_SetVisiableOfFrameUI then eObj:Replay_SetVisiableOfFrameUI(false) end
local uiComp=eObj.EnemyFrameUI or (type(eObj.GetEnemyFrameUI)=="function" and eObj:GetEnemyFrameUI())
if Valid(uiComp) then
if type(uiComp.SetVisibility)=="function" then uiComp:SetVisibility(2) end
if type(uiComp.SetHiddenInGame)=="function" then uiComp:SetHiddenInGame(true) end
end
eObj.AK_WALLHACK_ON=nil
eObj.AK_LAST_HIDDEN_STATE=nil
eObj.AK_LAST_MESH_COUNT=nil
eObj.AK_LAST_COLOR_HASH=nil
eObj.LastRadarUpdate=nil
local eMesh=eObj.Mesh or (type(eObj.getAvatarComponent2)=="function" and eObj:getAvatarComponent2() or nil)
if Valid(eMesh) then
eMesh.AKMOD_INJECT_HOOK=nil
eMesh.AKMOD_CURRENT_HASH=nil
eMesh.bIsAKHitboxModded=nil
end
end
local PPM=Cached_PPM
local avatarComp=Valid(eObj) and (type(eObj.getAvatarComponent2)=="function") and eObj:getAvatarComponent2() or nil
if Valid(avatarComp) and Valid(PPM) then PPM:EnableAvatarOutline(avatarComp, false) end
end)
_G.LexusState.EnemyMarks[eKey]=nil
end
end
end)
local mHead_Global, mBody_Global, mLegs_Global=1.0, 1.0, 1.0
local runInject_Global=false
pcall(function()
if _G.LexusConfig.CustomMagicBullet then
runInject_Global=true
mHead_Global=1.5; mBody_Global=1.5; mLegs_Global=1.5
if _G.LexusState.CustomTextData then
local cData=_G.LexusState.CustomTextData
if cData.MagicHead ~=nil then mHead_Global=tonumber(cData.MagicHead) or mHead_Global end
if cData.MagicBody ~=nil then mBody_Global=tonumber(cData.MagicBody) or mBody_Global end
if cData.MagicLegs ~=nil then mLegs_Global=tonumber(cData.MagicLegs) or mLegs_Global end
end
elseif _G.LexusConfig.MagicBullet then
runInject_Global=true
mHead_Global=1.7; mBody_Global=1.0; mLegs_Global=1.0
end
if runInject_Global then
local currentMagicHash="M_"..tostring(mHead_Global).."_"..tostring(mBody_Global).."_"..tostring(mLegs_Global)
if _G.LexusState.LastMagicConfigHash ~=currentMagicHash then
_G.LexusState.MagicUpdateVersion=(_G.LexusState.MagicUpdateVersion or 0)+1
_G.LexusState.LastMagicConfigHash=currentMagicHash
end
end
end)
pcall(function()
local allCharacters={}
if GameplayData.GetAllPlayerCharacters then allCharacters=GameplayData.GetAllPlayerCharacters()
elseif GameplayData.GameCharacters then for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end end
local realCount=0
local aiCount=0
local function GetFirstElemSafe(elemArray)
if elemArray and type(elemArray.Num)=="function" and elemArray:Num() > 0 then
if type(elemArray.Get)=="function" then return elemArray:Get(0) end
elseif elemArray and type(elemArray)=="table" and #elemArray > 0 then
return elemArray[1]
end
return nil
end
local magicInjectedThisTick=0
for _, enemy in pairs(allCharacters) do
if Valid(enemy) and enemy ~=localPlayer and enemy.TeamID ~=localPlayer.TeamID then
local bIsReallyDead=false
pcall(function()
if type(enemy.IsDead)=="function" then bIsReallyDead=enemy:IsDead()
elseif enemy.bIsDead ~=nil then bIsReallyDead=enemy.bIsDead
elseif enemy.bIsDeadFlag ~=nil then bIsReallyDead=enemy.bIsDeadFlag end
if enemy.HealthStatus ~=nil and enemy.HealthStatus==2 then bIsReallyDead=true end
end)
if not bIsReallyDead then
local eMesh=nil
pcall(function() eMesh=enemy.Mesh or (type(enemy.getAvatarComponent2)=="function" and enemy:getAvatarComponent2() or nil) end)
local aLoc=nil
pcall(function() if type(enemy.K2_GetActorLocation)=="function" then aLoc=enemy:K2_GetActorLocation() end end)
if runInject_Global then
pcall(function()
local EnemyMesh=eMesh
if slua.isValid(EnemyMesh) then
if not EnemyMesh.LastHitboxUpdateVersion or EnemyMesh.LastHitboxUpdateVersion ~=_G.LexusState.MagicUpdateVersion then
EnemyMesh.bIsAKHitboxModded=false
end
if not EnemyMesh.bIsAKHitboxModded and magicInjectedThisTick < 1 then
magicInjectedThisTick=magicInjectedThisTick+1
pcall(function()
local PhysicsAsset=EnemyMesh.PhysicsAssetOverride
if not slua.isValid(PhysicsAsset) and EnemyMesh.SkeletalMesh then PhysicsAsset=EnemyMesh.SkeletalMesh.PhysicsAsset end
if slua.isValid(PhysicsAsset) and PhysicsAsset.SkeletalBodySetups then
if not _G.AK_OrigHitboxes then _G.AK_OrigHitboxes={} end
local PhysAssetName=""
pcall(function() PhysAssetName=PhysicsAsset:GetName() end)
if PhysAssetName=="" then PhysAssetName="DefaultPhys" end
if not _G.AK_OrigHitboxes[PhysAssetName] then
_G.AK_OrigHitboxes[PhysAssetName]={}
end
local OrigHitboxData=_G.AK_OrigHitboxes[PhysAssetName]
local BoneScaleMap={
["head"]=mHead_Global,
["neck_01"]=mHead_Global,
["pelvis"]=mBody_Global,
["spine_01"]=mBody_Global,
["spine_02"]=mBody_Global,
["spine_03"]=mBody_Global,
["thigh_l"]=mLegs_Global, ["thigh_r"]=mLegs_Global,
["calf_l"]=mLegs_Global, ["calf_r"]=mLegs_Global,
["foot_l"]=mLegs_Global, ["foot_r"]=mLegs_Global
}
local SkeletalBodySetups=PhysicsAsset.SkeletalBodySetups
local numSetups=type(SkeletalBodySetups.Num)=="function" and SkeletalBodySetups:Num() or #SkeletalBodySetups
local limit=numSetups > 50 and 50 or numSetups
for i=1, limit do
local BodySetup=type(SkeletalBodySetups.Get)=="function" and SkeletalBodySetups:Get(i-1) or SkeletalBodySetups[i]
if slua.isValid(BodySetup) then
local LowerBoneName=string.lower(tostring(BodySetup.BoneName))
local MatchedBoneKey=nil
for k, _ in pairs(BoneScaleMap) do
if string.find(LowerBoneName, k, 1, true) then MatchedBoneKey=k break end
end
if MatchedBoneKey then
local TargetScale=BoneScaleMap[MatchedBoneKey]
local AggGeom=BodySetup.AggGeom
local BoxElems=AggGeom and AggGeom.BoxElems or BodySetup.BoxElems
local SphereElems=AggGeom and AggGeom.SphereElems or BodySetup.SphereElems
local SphylElems=AggGeom and AggGeom.SphylElems or BodySetup.SphylElems
local BoxElem=GetFirstElemSafe(BoxElems)
local SphereElem=GetFirstElemSafe(SphereElems)
local SphylElem=GetFirstElemSafe(SphylElems)
if not OrigHitboxData[MatchedBoneKey] then
OrigHitboxData[MatchedBoneKey]={ Box=nil, Sphere=nil, Sphyl=nil }
if BoxElem then OrigHitboxData[MatchedBoneKey].Box={ X=BoxElem.X, Y=BoxElem.Y, Z=BoxElem.Z } end
if SphereElem then OrigHitboxData[MatchedBoneKey].Sphere={ Radius=SphereElem.Radius } end
if SphylElem then OrigHitboxData[MatchedBoneKey].Sphyl={ Radius=SphylElem.Radius, Length=SphylElem.Length } end                                                        end
local OrigElemData=OrigHitboxData[MatchedBoneKey]
if OrigElemData.Box and BoxElem then
BoxElem.X=OrigElemData.Box.X*TargetScale
BoxElem.Y=OrigElemData.Box.Y*TargetScale
BoxElem.Z=OrigElemData.Box.Z*TargetScale
if type(BoxElems.Set)=="function" then BoxElems:Set(0, BoxElem) else BoxElems[1]=BoxElem end
if AggGeom then AggGeom.BoxElems=BoxElems; BodySetup.AggGeom=AggGeom else BodySetup.BoxElems=BoxElems end
end
if OrigElemData.Sphere and SphereElem then
SphereElem.Radius=OrigElemData.Sphere.Radius*TargetScale
if type(SphereElems.Set)=="function" then SphereElems:Set(0, SphereElem) else SphereElems[1]=SphereElem end
if AggGeom then AggGeom.SphereElems=SphereElems; BodySetup.AggGeom=AggGeom else BodySetup.SphereElems=SphereElems end
end
if OrigElemData.Sphyl and SphylElem then
SphylElem.Radius=OrigElemData.Sphyl.Radius*TargetScale
SphylElem.Length=OrigElemData.Sphyl.Length*TargetScale
if type(SphylElems.Set)=="function" then SphylElems:Set(0, SphylElem) else SphylElems[1]=SphylElem end
if AggGeom then AggGeom.SphylElems=SphylElems; BodySetup.AggGeom=AggGeom else BodySetup.SphylElems=SphylElems end
end
end
end
end
pcall(function()
if EnemyMesh.SetPhysicsAsset then EnemyMesh:SetPhysicsAsset(PhysicsAsset) end
EnemyMesh.PhysicsAssetOverride=PhysicsAsset
if EnemyMesh.RecreatePhysicsState then EnemyMesh:RecreatePhysicsState() end
end)
end
end)
EnemyMesh.bIsAKHitboxModded=true
EnemyMesh.LastHitboxUpdateVersion=_G.LexusState.MagicUpdateVersion
end
end
end)
end
local eKey=tostring(enemy)
_G.LexusState.EnemyMarks[eKey]=_G.LexusState.EnemyMarks[eKey] or { enemy=enemy }
local markData=_G.LexusState.EnemyMarks[eKey]
if markData.AK_IS_BOT==nil or markData.AK_IS_BOT==false then
markData.AK_IS_BOT=CheckIsAI(enemy)
end
local isBot=markData.AK_IS_BOT
if _G.LexusConfig.WallXuyenTuong then
if not enemy.AK_WALLHACK_ON then
ApplyWallXuyenTuong(enemy)
enemy.AK_WALLHACK_ON=true
end
end
if _G.LexusConfig.ColorBodyV2 then ApplyColorBodyV2(enemy, pc) end
local distM=0
pcall(function() distM=localPlayer:GetDistanceTo(enemy)/100 end)
local currentHp, maxHp=100, 100
if _G.LexusConfig.EspLoai5 or _G.LexusConfig.EspVipPro or _G.LexusConfig.EspVip then
pcall(function()
if enemy.Health then currentHp=enemy.Health elseif type(enemy.GetHealth)=="function" then currentHp=enemy:GetHealth() end
if enemy.HealthMax then maxHp=enemy.HealthMax elseif type(enemy.GetHealthMax)=="function" then maxHp=enemy:GetHealthMax() end
end)
if maxHp <=0 then maxHp=100 end
end
local hpRatio=currentHp/maxHp
if _G.LexusConfig.EspAntenna then
pcall(function()
local MyHUD=Cached_MyHUD
if Valid(MyHUD) and distM <=400 then
local loopCount=8
local zStep=1000
local baseZ=105
local topZ=baseZ+(loopCount*zStep)
for i=1, loopCount do
local zOffset=baseZ+(i*zStep)
MyHUD:AddDebugText("|", enemy, 0.15,
{X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset},
C_GREEN, true, false, true, nil, 1.2, true)
end
MyHUD:AddDebugText("I", enemy, 0.15,
{X=0, Y=0, Z=topZ+60}, {X=0, Y=0, Z=topZ+60},
C_GREEN, true, false, true, nil, 1.5, true)
end
end)
end
if _G.LexusConfig.EspLoai6 then
pcall(function()
local MyHUD=Cached_MyHUD
if Valid(MyHUD) then
if Valid(eMesh) and type(eMesh.GetSocketLocation)=="function" then
if distM <=400 then
if aLoc then
local cRed={R=255, G=0, B=0, A=255}
local cCyan={R=0, G=255, B=255, A=255}
local cYellow={R=255, G=255, B=0, A=255}
local boneLocs={}
local boneList={
"head", "neck_01", "pelvis",
"upperarm_r", "lowerarm_r", "hand_r",
"upperarm_l", "lowerarm_l", "hand_l",
"thigh_l", "calf_l", "foot_l",
"thigh_r", "calf_r", "foot_r"
}
for _, bName in ipairs(boneList) do
local shouldDraw=true
if distM > 150 and (bName ~="head" and bName ~="pelvis" and bName ~="neck_01") then
shouldDraw=false
end
if shouldDraw then
local wLoc=nil
if type(eMesh.GetSocketLocation)=="function" then wLoc=eMesh:GetSocketLocation(bName) end
if wLoc then
local ox=wLoc.X-aLoc.X
local oy=wLoc.Y-aLoc.Y
local oz=wLoc.Z-aLoc.Z
boneLocs[bName]={X=ox, Y=oy, Z=oz}
local mark="▪"
local fixedSize=0.25
local color=cCyan
if bName=="head" then mark="●"; fixedSize=0.45; color=cRed
elseif bName=="pelvis" or bName=="neck_01" then mark="▪"; fixedSize=0.35; color=cYellow end
MyHUD:AddDebugText(mark, enemy, 0.15, boneLocs[bName], boneLocs[bName], color, true, false, true, nil, fixedSize, true)
end
end
end
if distM <=100 then
local connections={
{"neck_01", "pelvis", cYellow},
{"neck_01", "upperarm_l", cCyan}, {"upperarm_l", "lowerarm_l", cCyan}, {"lowerarm_l", "hand_l", cCyan},
{"neck_01", "upperarm_r", cCyan}, {"upperarm_r", "lowerarm_r", cCyan}, {"lowerarm_r", "hand_r", cCyan},
{"pelvis", "thigh_l", cCyan}, {"thigh_l", "calf_l", cCyan}, {"calf_l", "foot_l", cCyan},
{"pelvis", "thigh_r", cCyan}, {"thigh_r", "calf_r", cCyan}, {"calf_r", "foot_r", cCyan}
}
for _, pair in ipairs(connections) do
local p1=boneLocs[pair[1]]
local p2=boneLocs[pair[2]]
if p1 and p2 then
local col=pair[3]
local dx=p2.X-p1.X; local dy=p2.Y-p1.Y; local dz=p2.Z-p1.Z
local length=math.sqrt(dx*dx+dy*dy+dz*dz)
local segments=math.floor(length/8)
if segments > 15 then segments=15 end
if segments < 3 then segments=3 end
for i=1, segments do
local fraction=i/(segments+1)
local mid={ X=p1.X+dx*fraction, Y=p1.Y+dy*fraction, Z=p1.Z+dz*fraction }
MyHUD:AddDebugText("•", enemy, 0.15, mid, mid, col, true, false, true, nil, 0.35, true)
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
if _G.LexusConfig.EspLoai7 then
pcall(function()
local MyHUD=Cached_MyHUD
if Valid(MyHUD) then
if distM <=600 then if isBot then aiCount=aiCount+1 else realCount=realCount+1 end end
if distM <=400 then
local stateText=""
local pose=nil
if enemy.PoseState then pose=enemy.PoseState
elseif type(enemy.GetPoseState)=="function" then pose=enemy:GetPoseState() end
if pose==0 or pose=="Stand" then stateText="Berdiri"
elseif pose==1 or pose=="Crouch" then stateText="Jongkok"
elseif pose==2 or pose=="Prone" then stateText="Tiarap"
else stateText="Berdiri" end
local curTime=os.clock()
if markData.AK_LAST_WEP_TIME==nil or curTime > markData.AK_LAST_WEP_TIME+1.5 then
local eWeapon=nil
if enemy.CurrentWeapon then eWeapon=enemy.CurrentWeapon
elseif type(enemy.GetCurrentWeapon)=="function" then eWeapon=enemy:GetCurrentWeapon()
elseif enemy.WeaponManagerComponent then eWeapon=enemy.WeaponManagerComponent.CurrentWeaponReplicated end
local weaponName="Senjata"
if Valid(eWeapon) then if type(eWeapon.GetWeaponName)=="function" then weaponName=eWeapon:GetWeaponName() end
else weaponName="Tidak Ada" end
markData.AK_CACHED_WEP_NAME=tostring(weaponName)
markData.AK_LAST_WEP_TIME=curTime
end
stateText=stateText .. "-" .. (markData.AK_CACHED_WEP_NAME or "Senjata")
if isBot then stateText=stateText .. " [BOT]" else stateText=stateText .. " [PEMAIN]" end
local textColor=isBot and {R=0,G=255,B=255,A=255} or {R=255,G=255,B=0,A=255}
local dynamicScale=math.max(0.5, 0.8-(distM/400))
MyHUD:AddDebugText(stateText, enemy, 0.15, {X=0, Y=0, Z=100}, {X=0, Y=0, Z=100}, textColor, true, false, true, nil, dynamicScale, true)
end
end
end)
end
if _G.LexusConfig.EspLoai5 then
pcall(function()
local SecurityCommonUtils=Cached_SecurityCommonUtils
local show=true
if enemy.HealthStatus and SecurityCommonUtils and SecurityCommonUtils.IsHealthStatusAlive then
if not SecurityCommonUtils.IsHealthStatusAlive(enemy.HealthStatus) then show=false end
end
local mLoc=nil
if type(localPlayer.K2_GetActorLocation)=="function" then mLoc=localPlayer:K2_GetActorLocation() end
if show and mLoc then
if aLoc and SecurityCommonUtils and SecurityCommonUtils.IsVector then
if SecurityCommonUtils.IsVector(aLoc) and SecurityCommonUtils.IsVector(mLoc) then
if aLoc.Z >=150000 or FVector.Dist2D(mLoc, aLoc) > 50000 then show=false end
end
end
end
if show then
if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end
local uiComp=enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI)=="function" and enemy:GetEnemyFrameUI())
if Valid(uiComp) then
if type(uiComp.SetVisibility)=="function" then uiComp:SetVisibility(0) end
if type(uiComp.SetHiddenInGame)=="function" then uiComp:SetHiddenInGame(false) end
end
end
end)
end
if _G.LexusConfig.EspVipPro then
pcall(function()
local hud=Cached_MyHUD
if Valid(hud) and hud.AddDebugText then
if distM <=400 then
local dynamicScale=math.max(0.55, 0.95-(distM/400))
local hpPercent=hpRatio
local isKnock=(currentHp <=0 and enemy.HealthStatus==1)
local enemyName="Musuh"
pcall(function() if enemy.PlayerName then enemyName=enemy.PlayerName elseif type(enemy.GetPlayerName)=="function" then enemyName=enemy:GetPlayerName() end end)
if enemyName=="" then enemyName="Musuh" end
if isKnock then enemyName="ROBOH: " .. enemyName end
local hpColor={R=0,G=255,B=0,A=255}
if hpPercent < 0.3 then hpColor={R=255,G=0,B=0,A=255}
elseif hpPercent < 0.7 then hpColor={R=255,G=255,B=0,A=255} end
if isKnock then hpColor={R=255,G=0,B=0,A=255} end
hud:AddDebugText(enemyName, enemy, 0.15, {X=0, Y=0, Z=-370}, {X=0, Y=0, Z=-370}, {R=255,G=255,B=255,A=255}, true, false, true, nil, dynamicScale*1.1, true)
if not isKnock then
local segments=6
local filled=math.floor(hpPercent*segments)
local startZ=20
local spacing=10.0*dynamicScale
for j=1, segments do
local color=(j <=filled) and hpColor or {R=30,G=30,B=30,A=180}
hud:AddDebugText("█", enemy, 0.15, {X=0, Y=-115, Z=startZ+(j*spacing)}, {X=0, Y=-115, Z=startZ+(j*spacing)}, color, true, false, true, nil, dynamicScale*1.2, true)
end
hud:AddDebugText(string.format("%d%%", math.floor(hpPercent*100)), enemy, 0.15, {X=0, Y=-60, Z=startZ-12}, {X=0, Y=-60, Z=startZ-12}, hpColor, true, false, true, nil, dynamicScale*0.8, true)
else
hud:AddDebugText("ROBOH", enemy, 0.15, {X=0, Y=-115, Z=50}, {X=0, Y=-115, Z=50}, {R=255,G=0,B=0,A=255}, true, false, true, nil, dynamicScale*1.0, true)
end
end
end
end)
end
if _G.LexusConfig.EspDistance then
pcall(function()
local hud=Cached_MyHUD
if Valid(hud) and hud.AddDebugText then
if distM <=400 then
local dynamicScale=math.max(0.55, 0.95-(distM/400))
hud:AddDebugText(string.format("[%dm]", math.floor(distM)), enemy, 0.15, {X=0, Y=115, Z=20}, {X=0, Y=115, Z=20}, {R=0,G=200,B=255,A=255}, true, false, true, nil, dynamicScale*1.5, true)
end
end
end)
end
if _G.LexusConfig.EspVip then
if markData.hpMark==nil then markData.hpMark=SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
if markData.distMark==nil then markData.distMark=SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
pcall(function()
local curTime=os.clock()
markData.LastEspVipUpdate=markData.LastEspVipUpdate or 0
if curTime > markData.LastEspVipUpdate+0.5 then
if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then
enemy:Replay_CreateEnemyFrameUI(true, true)
end
if enemy.Replay_SetVisiableOfFrameUI then
enemy:Replay_SetVisiableOfFrameUI(true)
end
local uiComp=enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI)=="function" and enemy:GetEnemyFrameUI())
if Valid(uiComp) then
if type(uiComp.SetVisibility)=="function" then uiComp:SetVisibility(0) end
if type(uiComp.SetHiddenInGame)=="function" then uiComp:SetHiddenInGame(false) end
end
markData.LastEspVipUpdate=curTime
end
if enemy.Replay_UpdateEnemyFrameUI then
if markData.LastHpRatio ~=hpRatio then
enemy:Replay_UpdateEnemyFrameUI(hpRatio)
markData.LastHpRatio=hpRatio
end
end
end)
end
if _G.LexusConfig.EspRadar then
pcall(function()
local UGameplayStatics=import("GameplayStatics")
local CGameWorld=slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
local curTime=(UGameplayStatics and CGameWorld) and UGameplayStatics.GetTimeSeconds(CGameWorld) or os.clock()
enemy.LastRadarUpdate=enemy.LastRadarUpdate or 0
if curTime > enemy.LastRadarUpdate+0.5 then
local headLoc=nil
if type(enemy.GetHeadLocation)=="function" then headLoc=enemy:GetHeadLocation(false) end
if headLoc then
local InGameMarkTools=require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
if markData.radarMark and InGameMarkTools and InGameMarkTools.HideMapMark then
InGameMarkTools.HideMapMark(markData.radarMark)
end
if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
markData.radarMark=InGameMarkTools.ClientAddMapMark(1003, headLoc, 0, "", 4, nil)
end
enemy.LastRadarUpdate=curTime
end
end
end)
end
if _G.LexusConfig.EspOutline then
pcall(function()
local PPM=Cached_PPM
local avatarComp=(type(enemy.getAvatarComponent2)=="function") and enemy:getAvatarComponent2() or nil
if Valid(avatarComp) and Valid(PPM) then
PPM.OutlineThickness=_G.LexusConfig.OutlineThickness
if PPM.OutlineColor then PPM.OutlineColor={r=1, g=0, b=0, a=1} end
PPM:EnableAvatarOutline(avatarComp, true)
end
end)
end
end
end
end
if _G.LexusConfig.EspLoai7 then
pcall(function()
local MyHUD=Cached_MyHUD
if Valid(MyHUD) then
local text=string.format("Pemain: %d  |  Bot: %d", realCount, aiCount)
MyHUD:AddDebugText(text, localPlayer, 1.5, {X=0, Y=0, Z=0}, {X=0, Y=0, Z=0}, {R=255, G=50, B=50, A=255}, true, false, true, nil, 0.8, true)
end
end)
end
end)
end
_G.LexusState.LoopToken=(_G.LexusState.LoopToken or 0)+1
local myToken=_G.LexusState.LoopToken
local function ExpiredTick()
if not _G.LexusNotifiedPopup then
pcall(function()
local Msg=require("client.slua.logic.common.logic_common_msg_box")
if Msg and Msg.Show then
Msg.Show(1, "MASA AKTIF HABIS", "VERSI MOD ANDA TELAH KADALUWARSA!\nHUBUNGI ZALO 0922520900 TELE @dung0610 UNTUK PERPANJANG.",
function()
local Web=require("client.slua.logic.url.logic_webview_sdk")
if Web and Web.OpenURL then Web:OpenURL("https://zalo.me/0922520900") end
end,
function() end, "HUBUNGI", "TUTUP")
_G.LexusNotifiedPopup=true
end
end)
if not _G.LexusNotifiedPopup then
local okTicker, ticker=pcall(require, "common.time_ticker")
if okTicker and ticker and ticker.AddTimerOnce then
ticker.AddTimerOnce(2.0, ExpiredTick)
end
end
end
end
local function FastTick()
if isExpired then
if not _G.LexusNotifiedExpire then
Notify("TOOL TELAH KADALUWARSA! HUBUNGI ZALO 0922520900 UNTUK PERPANJANG!")
_G.LexusNotifiedExpire=true
ExpiredTick()
end
return
end
if myToken ~=_G.LexusState.LoopToken then return end
pcall(MainLoop)
local okTicker, ticker=pcall(require, "common.time_ticker")
if okTicker and ticker and ticker.AddTimerOnce then
ticker.AddTimerOnce(0.05, FastTick)
end
end
if not isExpired then
FastTick()
Notify("Anda sedang menggunakan Mod VIP dari @dung0610. Hubungi WA 0922520900 untuk info lengkap!")
else
FastTick()
end
local function InitAllModSystems()
if isExpired then return end
pcall(function()
if _G.InitializeAntiReport then _G.InitializeAntiReport() end
if _G.InitializeAntiCheatHooks then _G.InitializeAntiCheatHooks() end
if _G.InitializeGameplayBypass then _G.InitializeGameplayBypass() end
if _G.InitializeConnectionGuard then _G.InitializeConnectionGuard() end
if _G.DisableHiggsBoson then _G.DisableHiggsBoson() end
if _G.InitializeLogBlocker then _G.InitializeLogBlocker() end
if _G.InitializeScannerBlocker then _G.InitializeScannerBlocker() end
if _G.InitializeReplayTelemetryBlocker then _G.InitializeReplayTelemetryBlocker() end
if _G.InitializeSkinBypass then _G.InitializeSkinBypass() end
end)
local GameplayData=package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
if not GameplayData then return end
pcall(function()
local LocalPlayer=GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
if slua.isValid(LocalPlayer) then
if LocalPlayer.bHasShownDevNotice==nil then
LocalPlayer.bHasShownDevNotice=false
LocalPlayer.bHasShownExpiredNotice=false
LocalPlayer.bIsDeadFlag=false
end
end
end)
end
if not isExpired then
pcall(function()
require("common.time_ticker").AddTimerOnce(0.5, InitAllModSystems)
end)
end
local class=require("class")
local CCharacterBase=require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase=class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
{
SkyTransition="GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
},
{
CarryDeadBoxFeature="GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"
},
{
SpecialSuitFeature="GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"
},
{
TeleportPawnFeature="GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"
},
{
LifterControl="GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"
},
{
FinalKillEffect="GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
},
{
CampFeature="GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature"
},
{
BuildSkateFeature="GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
},
{
CommonBornlandTransformFeature="GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
},
{
ParachuteFormation="GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
}
}, "BRPlayerCharacterBase")