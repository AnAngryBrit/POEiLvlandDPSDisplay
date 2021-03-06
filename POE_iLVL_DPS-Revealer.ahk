; original script can be found here:
; https://www.pathofexile.com/forum/view-thread/594346
; If you have any questions or comments please post them there as well. If you think you can help
; improve this project. I am looking for contributors. So Pm me if you think you can help.
;
;
; If you have a issue please post what version you are using.
; Reason being is that something that might be a issue might already be fixed.
; Version: 1.2d
;
; 
;


#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
StringCaseSense, On ; Match strings with case.
 
; Options
; Base item level display.
DisplayBaseLevel = 1 ; Enabled by default change to 0 to disable

; Pixels mouse must move to auto-dismiss tooltip
MouseMoveThreshold := 40

;How many ticks to wait before removing tooltip. 1 tick = 100ms. Example, 50 ticks = 5secends, 75 Ticks = 7.5Secends
ToolTipTimeoutTicks := 50

; Font size for the tooltip, leave empty for default
FontSize := 12

; Menu tooltip
Menu, Tray, Tip, POE Ilevel DPS and Resist Display
 
; Create font for later use
FixedFont := CreateFont()
 
; Creates a font for later use
CreateFont()
{
	global FontSize
	Options :=
	If (!(FontSize = ""))
	{
		Options = s%FontSize%
	}
	Gui Font, %Options%, Courier New
	Gui Font, %Options%, Consolas
	Gui Add, Text, HwndHidden, 
	SendMessage, 0x31,,,, ahk_id %Hidden%
	return ErrorLevel
}
 
; Sets the font for a created ahk tooltip
SetFont(Font)
{
	SendMessage, 0x30, Font, 1,, ahk_class tooltips_class32 ahk_exe autohotkey.exe
}
 
; Parse elemental damage
ParseDamage(String, DmgType, ByRef DmgLo, ByRef DmgHi)
{
	IfInString, String, %DmgType% Damage
	{
		IfInString, String, Converted to or IfInString, String, taken as
		 Return
		IfNotInString, String, increased
		{
			StringSplit, Arr, String, %A_Space%
			StringSplit, Arr, Arr2, -
			DmgLo := Arr1
			DmgHi := Arr2
		}
	}
}

; Parse elemental resistance
ParseResistance(String, ResType, ByRef Res)
{
	IfInString, String, %ResType% Resistance
	{
	StringSplit, Arr, String, %A_Space%, +`%
	Res += Arr1
	}
}

; Added fuction for reading itemlist.txt added fuction by kongyuyu
if DisplayBaseLevel = 1
{
ItemListArray = 0
    Loop, Read, %A_WorkingDir%\ItemList.txt   ; This loop retrieves each line from the file, one at a time.
    {
      ItemListArray += 1  ; Keep track of how many items are in the array.
      StringSplit, NameLevel, A_LoopReadLine, |,
      Array%ItemListArray%1 := NameLevel1  ; Store this line in the next array element.
      Array%ItemListArray%2 := NameLevel2
    }
}
;;;Function that check item name against the array
;;;Then add base lvl to the ItemName
CheckBaseLevel(ByRef ItemName)
{
Global
	Loop %ItemListArray%
	{
		element := Array%A_Index%1
		IfInString, ItemName, %element%
		{
			BaseLevel := "   " + Array%A_Index%2
			StringRight, BaseLevel, BaseLevel, 3
			ItemName := ItemName . "Base lvl:  " . BaseLevel . "`n"
		}		
	}
}

 
; Parse clipboard content for item level and dps
ParseClipBoardChanges()
{
	NameIsDone := False
	ItemName := 
	ItemLevel := -1
	IsWeapon := False
	HasResistance := False
	PhysLo := 0
	PhysHi := 0
	Quality := 0
	AttackSpeed := 0
	PhysMult := 0
	ChaoLo := 0
	ChaoHi := 0
	ColdLo := 0
	ColdHi := 0
	FireLo := 0
	FireHi := 0
	LighLo := 0
	LighHi := 0
	ColdRes := 0
	FireRes := 0
	LightningRes := 0
	ChaosRes := 0
 
	Loop, Parse, Clipboard, `n, `r
	{
		; Clipboard must have "Rarity:" in the first line
		If A_Index = 1
		{
			IfNotInString, A_LoopField, Rarity:
			{
				Exit
			}
			Else
			{
				Continue
			}
		}
 
		; Get name
		If Not NameIsDone
		{
			If A_LoopField = --------
			{
				NameIsDone := True
			}
			Else
			{
				ItemName := ItemName . A_LoopField . "`n" ; Add a line of name
				CheckBaseLevel(ItemName) ; Checking for base item level.
			}
			Continue
		}
 
		; Get item level
		IfInString, A_LoopField, Itemlevel:
		{
			StringSplit, ItemLevelArray, A_LoopField, %A_Space%
			ItemLevel := ItemLevelArray2
			Continue
		}
 
		; Get quality
		IfInString, A_LoopField, Quality:
		{
			StringSplit, Arr, A_LoopField, %A_Space%, +`%
			Quality := Arr2
			Continue
		}
		
		; Check and Parse for Two-Stone Rings
		IfInString, ItemName, Two-Stone Ring
		{
			HasResistance := true
			
			IfInString, A_LoopField, Fire and Cold
			{
				StringSplit, Arr, A_LoopField, %A_Space%, +`%
				FireRes += Arr1
				ColdRes += Arr1
				;MsgBox, , , %FireRes% and %ColdRes%
				Continue
			}
			
			IfInString, A_LoopField, Cold and Lightning
			{
				StringSplit, Arr, A_LoopField, %A_Space%, +`%
				ColdRes += Arr1
				LightningRes += Arr1
				;MsgBox, , , %ColdRes% and %LightningRes%
				Continue
			}
			
			IfInString, A_LoopField, Fire and Lightning
			{
				StringSplit, Arr, A_LoopField, %A_Space%, +`%
				FireRes += Arr1
				LightningRes += Arr1
				;MsgBox, , , %FireRes% and %Lightning%
				Continue
			}
		}
		
		;Check for all elemental resistances
		IfInString, A_LoopField, to all Elemental Resistances
		{
			HasResistance := true
			StringSplit, Arr, A_LoopField, %A_Space%, +`%
			ColdRes += Arr1
			FireRes += Arr1
			LightningRes += Arr1
			continue
		}
		
		;Check for elemental resistance
		IfInString, A_LoopField, Resistance
		{
			HasResistance := true
			ParseResistance(A_LoopField, "Cold", ColdRes)
			ParseResistance(A_LoopField, "Fire", FireRes)
			ParseResistance(A_LoopField, "Lightning", LightningRes)
			ParseResistance(A_LoopField, "Chaos", ChaosRes)
			continue
		}
		
		; Get total physical damage
		IfInString, A_LoopField, Physical Damage:
		{
			IsWeapon = True
			StringSplit, Arr, A_LoopField, %A_Space%
			StringSplit, Arr, Arr3, -
			PhysLo := Arr1
			PhysHi := Arr2
			Continue
		}
		;Fix for Elemental damage only weapons. Like the Oro's Sacrifice
		IfInString, A_LoopField, Elemental Damage:
		{
			IsWeapon = True
			Continue
		}
			 
		; These only make sense for weapons
		If IsWeapon 
		{
			; Get attack speed
			IfInString, A_LoopField, Attacks per Second:
			{
				StringSplit, Arr, A_LoopField, %A_Space%
				AttackSpeed := Arr4
				Continue
			}
 
			; Get percentage physical damage increase
			IfInString, A_LoopField, increased Physical Damage
			{
				StringSplit, Arr, A_LoopField, %A_Space%, `%
				PhysMult := Arr1
				Continue
			}
      
      ;Lines to skip fix for converted type damage. Like the Voltaxic Rift
      IfInString, A_LoopField, Converted to
       Goto, SkipDamageParse
      IfInString, A_LoopField, can Shock
       Goto, SkipDamageParse
      
			; Parse elemental damage
			ParseDamage(A_LoopField, "Chaos", ChaoLo, ChaoHi)
			ParseDamage(A_LoopField, "Cold", ColdLo, ColdHi)
			ParseDamage(A_LoopField, "Fire", FireLo, FireHi)
			ParseDamage(A_LoopField, "Lightning", LighLo, LighHi)
			
		  SkipDamageParse:
		}
	}
	If ItemLevel = -1 ; Something without an itemlevel
	{
		Exit
	}
	; Get position of mouse cursor
	global X
	global Y
	MouseGetPos, X, Y
 
	; All items should show name and item level
	; Pad to 3 places
	ItemLevel := "   " + ItemLevel
	StringRight, ItemLevel, ItemLevel, 3
	TT = %ItemName%Item lvl:  %ItemLevel%
 
	; DPS calculations
	If IsWeapon {
		SetFormat, FloatFast, 5.1
 
		PhysDps := ((PhysLo + PhysHi) / 2) * AttackSpeed
		EleDps := ((ChaoLo + ChaoHi + ColdLo + ColdHi + FireLo + FireHi + LighLo + LighHi) / 2) * AttackSpeed
		TotalDps := PhysDps + EleDps
 
		TT = %TT%`nPhys DPS:  %PhysDps%`nElem DPS:  %EleDps%`nTotal DPS: %TotalDps%
 
		; Only show Q20 values if item is not Q20
		If Quality < 20
		{
			TotalPhysMult := (PhysMult + Quality + 100) / 100
			BasePhysDps := PhysDps / TotalPhysMult
			Q20Dps := BasePhysDps * ((PhysMult + 120) / 100) + EleDps
 
			TT = %TT%`nQ20 DPS:   %Q20Dps%
		}
	}
	
	;Add Resistances to ToolTip
	if HasResistance {
		TT = %TT%`nFire Resistance:	%FireRes%`nCold Resistance:	%ColdRes%`nLightning Resistance:	%LightningRes%`nChaos Resistance:	%ChaosRes%
	}
	 
        ; Replaces Clipboard with tooltip data
        StringReplace, clipboard, TT, `n, %A_SPACE% , All

	; Show tooltip, with fixed width font
	ToolTip, %TT%, X + 35, Y + 35
	global FixedFont
	SetFont(FixedFont)
	; Set up count variable and start timer for tooltip timeout
	global ToolTipTimeout := 0
	SetTimer, ToolTipTimer, 100
}

 
; Tick every 100 ms
; Remove tooltip if mouse is moved or 5 seconds pass
ToolTipTimer:
ToolTipTimeout += 1
MouseGetPos, CurrX, CurrY
MouseMoved := (CurrX - X)**2 + (CurrY - Y)**2 > MouseMoveThreshold**2
If (MouseMoved or ToolTipTimeout >= ToolTipTimeoutTicks)
{
	SetTimer, ToolTipTimer, Off
	ToolTip
}
return
 
OnClipBoardChange:
ParseClipBoardChanges()
