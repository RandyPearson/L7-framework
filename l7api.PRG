* L7Api.PRG

#IF .F.
***** BEGIN LICENSE BLOCK *****
Version: MPL 1.1

The contents of this file are subject to the Mozilla Public License Version 
1.1 (the "License"); you may not use this file except in compliance with 
the License. You may obtain a copy of the License at 
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
for the specific language governing rights and limitations under the
License.

The Original Code is "Level 7 Framework for Web Connection" and 
"Level 7 Toolkit" (collectively referred to as "L7").

The Initial Developer of the Original Code is Randy Pearson of 
Cycla Corporation.

Portions created by the Initial Developer are Copyright (C) 2004 by
the Initial Developer. All Rights Reserved.

***** END LICENSE BLOCK *****
#ENDIF


#DEFINE TIME_ZONE_INFORMATION REPL( CHR(0), 172)

* ------------------------------------------------ *
FUNCTION L7Beep(lnFreq, lnDur)
  lnFreq = EVL(m.lnFreq, 300)
  lnDur = EVL(m.lnDur, 50)
  DECLARE Integer Beep IN WIN32API ;
    Integer frequency, Integer duration
  Beep(m.lnFreq, m.lnDur)
ENDFUNC
* ------------------------------------------------ *
FUNCTION GetTimeZoneOffset
  * Returns time sone offset in *minutes*.
  * Divide by 60 in your app for Hours!.
  DECLARE INTEGER GetTimeZoneInformation ;
  	IN Kernel32.DLL ;
  	STRING @lpTimeZoneInformation
  LOCAL lpTimeZoneInformation
  lpTimeZoneInformation = TIME_ZONE_INFORMATION
  = GetTimeZoneInformation( @lpTimeZoneInformation )
  RETURN LongToInt( LEFT( m.lpTimeZoneInformation, 4) )
ENDFUNC
* ------------------------------------------------ *
FUNCTION LongToInt
  LPARAMETER lcLong
  LOCAL lnInt, ii, lnDigit
  lnInt = 0
  IF VARTYPE( m.lcLong) <> "C" OR LEN( m.lcLong) <> 4
  	lnInt = 0
  ELSE
  	FOR ii = 4 TO 1 STEP -1  && longs are backward
  		lnDigit = ASC( SUBSTR( m.lcLong, m.ii, 1) )
  		lnInt = m.lnInt + m.lnDigit
  		IF m.ii > 1
  			lnInt = m.lnInt * 256
  		ENDIF
  	ENDFOR
  	IF m.lnInt > 2147483647  && Longs are signed.
  		lnInt = m.lnInt - 0x100000000
  	ENDIF
  ENDIF
  RETURN m.lnInt
ENDFUNC  && LongToInt
* ------------------------------------------------ *
FUNCTION GetIniSetting
  LPARAMETERS lcIniFile, lcSection, lcSetting
  LOCAL lcValue, lnLength

  lcValue = SPACE( 254 )

  lnLength = GetPrivateProfileString( ;
  	lcSection, lcSetting, "*None*", ;
  	@lcValue, LEN( m.lcValue), m.lcIniFile)

  * Remove null terminator:
  lcValue = SUBSTR( m.lcValue, 1, m.lnLength )

  IF m.lcValue == "*None*"
     lcValue = ""
  ENDIF
  RETURN lcValue
ENDFUNC  && GetIniSetting
* ------------------------------------------------ *
* End: L7Api.PRG
