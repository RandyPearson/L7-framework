* L7App.PRG
*
#INCLUDE L7.H
#UNDEF THIS_DEBUG_OBJECTS 
#DEFINE THIS_DEBUG_OBJECTS .F.

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


*!*  * You create something like this:
*!*  *** ========================================================= ***
*!*  DEFINE CLASS MyApp AS L7App 
*!*    cApplication              = "My"
*!*    cTitle                    = "My Application"
*!*    cPageAlias                = "MyPages"
*!*    nPageCreation             = L7_PAGECREATION_FACTORY + L7_PAGECREATION_DIRECT
*!*    cDefaultPage              = "home"
*!*  ENDDEFINE && MyApp

*** ========================================================= ***
DEFINE CLASS L7App AS FORM
  DataSession               = 2     && private datasession
  cApplication              = NULL  && acronym passed into INIT
  cTitle                    = "My Level 7 Application"
  
  * Error handling:
  cErrorReturnMethod        = ""
  lError                    = .F.
  lErrorMsg                 = .F.
  oDebugInfo                = NULL
  cErrorMessage             = ""
  cErrorTitle               = ""
  nErrorPageInfo            = L7_NONE && L7_NONE && additive (see L7.H for values) 
  nErrorEmailInfo           = L7_ERRORINFO_TYPICAL            && additive (see L7.H for values) 
  
  * Hacker handling:
  lHack                     = .F. && flag for hacker detection
  cHackInfo                 = ""  && extra logging info for hack attempts
  cLogHackClass             = "L7LogHack"

  HIDDEN FW_Is_Setup
  FW_Is_Setup               = .F. 

  cClassPrefix              = ""   && for converting URL page to class name
  cClassSuffix              = ""   && same as above

  oActivePage               = NULL
  cActivePageClass          = ""   && used by framework to decide which current class to call
  cActivePage               = ""
  cActivePageExtension      = ""   && hit-specific
  cPageExtension            = ""   && determined by access method from Config setting
  cVirtualPath              = ""   &&   -- ditto --
  
  * This property is used if you want a "class factory" approach for your pages:
  cPageAlias                = NULL
  * - defaults to cApplication + "Pages" unless specified in subclass
  oPageFactory              = NULL
  nPageCreation             = L7_PAGECREATION_FACTORY + L7_PAGECREATION_DIRECT

  cUserClass                = null  && new attempt to get this object early
  
  oSession                  = NULL
  cSessionClass             = "L7Session"  && bridge
  nSessionTimeout           = 3600  && 1 hour
  cSessionTableName         = NULL  && defaults to <cApplication> + "Session"
  
  oBrowser                  = NULL
  cBrowserClass             = "L7Browser"
  cBrowserName              = "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt)"

  oSecurity                 = NULL
  cSecurityClass            = ""  && you must provide if you have one
  
  oConfig                   = NULL
  cConfigClass              = "L7AppConfig"  && bridge (see L7wwServer, for example)
  oCacheManager             = NULL
  
  oParseManager             = NULL
  cParseManagerClass        = "L7Parsers"
  
  oResponseManager          = NULL
  cResponseManagerClass     = "L7ResponseManager"  && collection of handlers
  cDefaultResponse          = "StandardResponse"
  cActiveResponse           = NULL  && NULL means use default
  cErrorResponse            = NULL  && NULL meand use cErrorResponse class suggested by ActiveResponse class
  lOutputDelivered          = .F.
  cOutputFile               = ""

  cIniFile                  = ""  && override in subclass [DEPRECATED - USE CONFIG OBJECT]
  cDefaultPage              = ""  && override in your app
  lAppOpen                  = .F.
  nHits                     = 0
  nCurrentHits              = 0   && since last maintenance event

  tLastMaintenanceCheck     = NULL
  lMaintenanceFlag          = .F.
  cMaintenanceMessage       = "Server Maintenance in Progress -- Please Come Back Later"
  nMaintenanceCheckInterval = 30  && seconds (0 = check on every hit, -1 = no checks)

  cHTMLPagePath             = ""
  
  * Request logging:
  lLogRequests              = .T.
  cLogRequestClass          = "L7LogRequest"  && Bridge Pattern
  cLogRequestBaseName       = NULL  && see access method (can be overridden)
  cLogPath                  = NULL  && NULL means get it from Config
  oRequestLog               = NULL

  * AUTH logging:
  cAuthLogClass          = "L7AuthLog"  && Bridge Pattern
  cAuthLogBaseName       = NULL  && see access method (can be overridden)
  * cLogPath               = NULL  && same path as request log
  oAuthLog               = NULL

  * Message queueing:
  cMessageQueueClass        = "L7MessageQueue"
  lMailServerAvailable      = .T.   
  cMessagingPath            = NULL  && (see Access method)

  nDatabases                = 0  && Must specify in your application.
  * DIMENSION aDatabases[1]
  
  * DEPRECATED (in favor of multiple L7Database classes):
  nDatabaseRevision         = 0   && update in application
  cDataBase                 = ""
  cDataPath                 = ""
  cBackupDataPath           = ""  && See Access method.

  ADD OBJECT PrivateVars AS Collection
  * --------------------------------------------------------- *
  FUNCTION cLogRequestBaseName_ACCESS
    IF ISNULL(THIS.cLogRequestBaseName)
      THIS.cLogRequestBaseName = THIS.cApplication + "RequestLog"
    ENDIF
    RETURN THIS.cLogRequestBaseName
  ENDFUNC  
  * --------------------------------------------------------- *
  FUNCTION cAuthLogBaseName_ACCESS
    IF ISNULL(THIS.cAuthLogBaseName)
      THIS.cAuthLogBaseName = THIS.cApplication + "AuthLog"
    ENDIF
    RETURN THIS.cAuthLogBaseName
  ENDFUNC  
  * --------------------------------------------------------- *
  FUNCTION cVirtualPath_ACCESS
    LOCAL lcStr
    IF VARTYPE( THIS.oConfig) <> 'O'
      lcStr = GetIniSetting( THIS.cIniFile, THIS.cApplication, "VirtualPath")
    ELSE
      lcStr = THIS.oConfig.cVirtualPath
    ENDIF
    RETURN m.lcStr
  ENDFUNC  && cVirtualPath_ACCESS
  * --------------------------------------------------------- *
  FUNCTION cPageExtension_ACCESS
    LOCAL lcStr
    IF VARTYPE( THIS.oConfig) <> 'O'
    	lcStr = GetIniSetting( THIS.cIniFile, THIS.cApplication, "PageExtension")
    ELSE
    	lcStr = THIS.oConfig.cPageExtension
    ENDIF
    RETURN m.lcStr
  ENDFUNC  && cPageExtension_ACCESS
  * --------------------------------------------------------- *
  FUNCTION cDataPath_ACCESS
    IF VARTYPE( THIS.oConfig) <> 'O'
    	RETURN GetIniSetting( THIS.cIniFile, THIS.cApplication, "DataPath")
    ELSE
    	RETURN THIS.oConfig.cDataPath
    ENDIF
  ENDFUNC  && cDataPath_ACCESS
  * --------------------------------------------------------- *
  FUNCTION cBackupDataPath_ACCESS
    IF EMPTY( THIS.cBackupDataPath)
      LOCAL lcPath
      IF VARTYPE( THIS.oConfig) <> 'O'
        lcPath = GetIniSetting( THIS.cIniFile, THIS.cApplication, ;
          "BackupDataPath")
      ELSE
        IF VARTYPE( THIS.oConfig.cBackupDataPath) = "C"
          lcPath = THIS.oConfig.cBackupDataPath
        ENDIF
      ENDIF
      IF EMPTY( m.lcPath)
        lcPath = ADDBS( THIS.cDataPath) + "backup\"
      ENDIF
      THIS.cBackupDataPath = m.lcPath
    ENDIF
    RETURN THIS.cBackupDataPath
  ENDFUNC  && cBackupDataPath_ACCESS
  * --------------------------------------------------------- *
  FUNCTION cLogPath_ACCESS
    IF ISNULL( THIS.cLogPath)
      LOCAL lcPath
      IF VARTYPE( THIS.oConfig) <> 'O'
        lcPath = GetIniSetting( THIS.cIniFile, THIS.cApplication, ;
          "LogPath")
      ELSE
        IF VARTYPE( THIS.oConfig.cLogPath) = "C"
          lcPath = THIS.oConfig.cLogPath
        ENDIF
      ENDIF
      IF EMPTY( m.lcPath)
        lcPath = ADDBS( THIS.cDataPath) + "logs\"
      ENDIF
      IF NOT DIRECTORY(m.lcPath)
        MKDIR (m.lcPath)  && hope this succeeds
      ENDIF
      THIS.cLogPath = m.lcPath
    ENDIF
    RETURN THIS.cLogPath
  ENDFUNC  && cLogPath_ACCESS
  * --------------------------------------------------------- *
  FUNCTION cMessagingPath_ACCESS
    IF ISNULL(THIS.cMessagingPath)
      LOCAL lcPath
      IF VARTYPE(THIS.oConfig) <> 'O'
        lcPath = GetIniSetting( THIS.cIniFile, THIS.cApplication, ;
          "MessagingPath")
      ELSE && config object exists
        IF VARTYPE(THIS.oConfig.cMessagingPath) = "C"
          lcPath = THIS.oConfig.cMessagingPath
        ENDIF
      ENDIF
      IF EMPTY( m.lcPath) && no path in config
        lcPath = ADDBS( THIS.cDataPath) + "messaging\"
      ENDIF
      IF NOT DIRECTORY(m.lcPath)
        MKDIR (m.lcPath)  && hope this succeeds
      ENDIF
      THIS.cMessagingPath = m.lcPath
    ENDIF
    RETURN THIS.cMessagingPath
  ENDFUNC  && cMessagingPath_ACCESS
  * --------------------------------------------------------- *
  FUNCTION cHTMLPagePath_ACCESS
    IF VARTYPE( THIS.oConfig) <> 'O'
    	RETURN GetIniSetting( THIS.cIniFile, THIS.cApplication, "HtmlPagePath")
    ELSE
    	RETURN THIS.oConfig.cHTMLPagePath
    ENDIF
  ENDFUNC  && cHTMPPagePath_ACCESS
  * --------------------------------------------------------- *
  FUNCTION cErrorTitle_ACCESS
    IF EMPTY( THIS.cErrorTitle)
      RETURN "Application Error"
    ELSE
      RETURN THIS.cErrorTitle
    ENDIF
  ENDFUNC  && cHTMPPagePath_ACCESS
  * --------------------------------------------------------- *
  FUNCTION INIT(lcApp)
    * NOTE: cApplication _should_ be defined as a property in your subclass!
    DO StandardVfpSettings
    IF ISNULL(THIS.cApplication)
      THIS.cApplication = EVL(m.lcApp, "XXXX")
    ENDIF
    * Add all other application procedures:
    THIS.SetAppProcedures()
    * NOTE: Most other "init-like" stuff appears in Setup() method below.
    
    #IF THIS_DEBUG_OBJECTS
    DEBUGOUT THIS.Name + [ (] + THIS.Class + [) initialized.]
    #ENDIF
  ENDFUNC  && INIT
  * --------------------------------------------------------- *
  FUNCTION BeforeSetup  && (blocking) pre-processing hook
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION AfterSetup   && post-processing hook
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION Setup  && called by AppManager.DoSetup
    IF THIS.IsDisabled()
      RETURN
    ENDIF
    PRIVATE goL7App
    goL7App = THIS  && available to everything called in SetupObjects()
    IF THIS.BeforeSetup()  && blocking hook
      *** ISAPI behavior object:
      *** THIS.oConnector = CREATEOBJECT(THIS.cConnectorClass)
      THIS.SetupSessionObject()
      THIS.SetupBrowserObject()  && added 2/23/07
      THIS.SetupPageFactory()
      THIS.SetupSecurity()
      THIS.SetupParseManager()
      * Load response handlers:
      THIS.SetupResponseManager()
      THIS.AfterSetup()  && hook (for additional objects)
    ENDIF
    THIS.FW_Is_Setup = .T.
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION GarbageCollect
    THIS.oActivePage = NULL
    THIS.TearDownSecurity()
    THIS.TearDownResponseManager()
    THIS.oDebugInfo = NULL
    THIS.oSession = NULL
    THIS.oBrowser = NULL
    THIS.oPageFactory = NULL
    THIS.oParseManager = NULL
    THIS.oRequestLog = NULL
    THIS.oAuthLog = NULL
    THIS.oConfig = NULL
    ** THIS.oConnector = NULL
    * If a subclass includes any object pointers, do this:
    * FUNCTION GarbageCollect
    *   DODEFAULT()
    *   THIS.oPointer1 = NULL
    *   THIS.oPointer2 = NULL
    *   etc.
    * ENDFUNC
  ENDFUNC   && GarbageCollect
  * ------------------------------------------------------------------- *
  PROCEDURE RELEASE
    THIS.GarbageCollect()
    RELEASE THIS
  ENDFUNC  && RELEASE
  * --------------------------------------------------------- *
  FUNCTION DESTROY
    THIS.OnLastHit()
    THIS.GarbageCollect()
    #IF THIS_DEBUG_OBJECTS
    DEBUGOUT THIS.Name + [ (] + THIS.Class + [) destroyed.]
    #ENDIF
  ENDFUNC  && Destroy
  * --------------------------------------------------------- *
  FUNCTION SetupDebugInfo
    IF ISNULL(THIS.oDebugInfo)
      THIS.oDebugInfo = CREATEOBJECT("L7DebugInfoElement")
    ENDIF
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION AddDebugObject(loObj, llToPage, llToEmail, lcName)
    THIS.SetupDebugInfo()
    THIS.oDebugInfo.AddDebugObject(m.loObj, m.llToPage, m.llToEmail, m.lcName)      
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION AddStandardDebugInfo(lnPageInfo, lnEmailInfo)
    THIS.SetupDebugInfo()
    THIS.oDebugInfo.AddStandardInfo(m.lnPageInfo, m.lnEmailInfo)
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION SetError(lcMessage, lcTitle, loException)
    IF VARTYPE(m.loException) = "O" AND loException.ErrorNo = L7_CUSTOMERROR_ERRORMSG
      THIS.lErrorMsg = .T.
    ELSE
      THIS.lError = .T.
    ENDIF
    THIS.cErrorMessage = EVL(m.lcMessage, "An error occurred.")
    THIS.cErrorTitle = EVL(m.lcTitle, THIS.cApplication + " Application Error")
    * If a real error, populate debugInfo object:
    IF THIS.lError
      LOCAL lnEmailInfo, lnPageInfo, llPage, llEmail
      lnPageInfo  = THIS.nErrorPageInfo
      lnEmailInfo = THIS.nErrorEmailInfo
      IF VARTYPE(THIS.oActivePage) = "O"
        lnPageInfo  = BITOR(m.lnPageInfo,  THIS.oActivePage.nErrorPageInfo)
        lnEmailInfo = BITOR(m.lnEmailInfo, THIS.oActivePage.nErrorEmailInfo)
      ENDIF
      * Error info:
      IF VARTYPE(m.loException) = "O"
        llPage  = BITAND(m.lnPageInfo,  L7_ERRORINFO_EXCEPTION_INFO) > 0
        llEmail = BITAND(m.lnEmailInfo, L7_ERRORINFO_EXCEPTION_INFO) > 0
        IF m.llEmail OR m.llPage
          THIS.AddDebugObject(m.loException, m.llPage, m.llEmail, "Error Info")
        ENDIF
      ENDIF
      * Remainder of standard L7 error info:
      ** THIS.AddDebugObject(THIS, m.llPage, m.llEmail, "App Info")
      THIS.AddStandardDebugInfo(m.lnPageInfo, m.lnEmailInfo)
    ENDIF
    RETURN 
  ENDFUNC  && SetError
  * --------------------------------------------------------- *
  #IF DEBUGMODE = .F.
    FUNCTION Error( lnError, lcMethod, lnLine )
      * Following debugging approach courtesy of Nancy Folsom.
      * See: http://www.hentzenwerke.com/catalogpricelists/debugvfp.htm
      SET ASSERTS ON
      ASSERT .F. MESSAGE MESSAGE()
      * The following is useful because in debugger you can
      * set either RETURN or RETRY as the next statement to 
      * execute. So, you can temporarily correct the code error
      * and continue execution.
      IF .F.
        RETURN
        RETRY
      ENDIF
      * End: Nancy Folsom debugging approach.

      * Set flag so we know error occurred:
      THIS.lError = .T.
      local lcMsg
      lcMsg = MESSAGE()
      THIS.cErrorMessage = THIS.cErrorMessage + ;
        [Error: "] + EncodeHTML(m.lcMsg) + [" in line ] + TRANSFORM(m.lnLine) + ;
        [ of *] + m.lcMethod + [*] + L7BR
      * Try to build an exception object to describe the condition:
      LOCAL loException AS Exception
      TRY
        loException = L7ErrorToException(m.lnError, m.lcMethod, m.lnLine)
      CATCH TO loExc
        loException = m.loExc
        loException.Comment = "Exception occurred trying to convert application error to exception object."
      ENDTRY
      * Store error info to object properties and build debugging response info:
      TRY
        THIS.SetError( ;
          THIS.cErrorMessage, ;
          THIS.cApplication + " Error: " + m.lcMsg, ;
          m.loException)

          * THIS.cApplication + " Application Error"
      CATCH
        = .F.
      ENDTRY
      * Abort any uncommitted changes, if possible:
      TRY
        RevertTables()
      CATCH
        = .F.
      ENDTRY
      LOCAL lcReturnTo
      lcReturnTo = THIS.cErrorReturnMethod
      IF NOT EMPTY(m.lcReturnTo)
        RETURN TO &lcReturnTo
      ENDIF
    ENDFUNC  && Error
  #ENDIF
  * --------------------------------------------------------- *
  FUNCTION ClearErrors
    * NOTE -- This is called in a few places:
    * a) from here at the beginning of ProcessPage()
    * b) from the AppManager, after up-front errors have been reported
    
    THIS.lError = .F.
    THIS.lErrorMsg = .F.
    THIS.cErrorMessage = ""
    THIS.cErrorTitle = ""
    THIS.oDebugInfo = NULL
  ENDFUNC  && ClearErrors
  * --------------------------------------------------------- *
  FUNCTION SetAppProcedures
    * override in your subclass with lots of:
    * SET PROCEDURE TO ... ADDITIVE
  ENDFUNC  && SetAppProcedures
  * --------------------------------------------------------- *
  FUNCTION SetConfigObject(loConfigObject)
    THIS.oConfig = m.loConfigObject
    * Note: We don't do anything further here, because the
    * actual config *file* may not have been read yet.
  ENDFUNC  
  * --------------------------------------------------------- *
  FUNCTION IsDisabled
    RETURN THIS.oConfig.lDisabled
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION SetupSessionObject
    THIS.oSession = CREATEOBJECT(THIS.cSessionClass)
    THIS.oSession.SetTableName(NVL(THIS.cSessionTableName, THIS.cApplication + "Session"))
    THIS.oSession.SetTimeout(THIS.nSessionTimeout)
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION GetSessionObject
    THIS.oSession.Reset()
    RETURN THIS.oSession
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION SetupBrowserObject
    THIS.oBrowser = CREATEOBJECT(THIS.cBrowserClass)
    THIS.oBrowser.SetBrowser( THIS.cBrowserName)
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION GetBrowserObject
    ** THIS.oBrowser.ResetProperties() called eleswhere
    RETURN THIS.oBrowser
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION SetupPageFactory
    * Create Page class factory, if used:
    IF BITAND(THIS.nPageCreation, L7_PAGECREATION_FACTORY) > 0
      * Factory supported.
      IF ISNULL(THIS.cPageAlias) OR EMPTY(THIS.cPageAlias)
        THIS.cPageAlias = THIS.cApplication + "Pages"
      ENDIF
      THIS.oPageFactory = CREATEOBJECT("L7PageFactory") && see L7Factory.PRG
      THIS.oPageFactory.SetAlias(THIS.cPageAlias)
      THIS.oPageFactory.LOAD()
    ENDIF
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION SetupParseManager
    IF NOT EMPTY(THIS.cParseManagerClass)
      THIS.oParseManager = CREATEOBJECT(THIS.cParseManagerClass)
      THIS.oParseManager.Config(THIS.oConfig)
    ENDIF
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION SetupSecurity
    * You can provide a compliant bridge class, or override
    * this factory method altogether.
    IF NOT EMPTY(THIS.cSecurityClass)
      THIS.oSecurity = CREATEOBJECT(THIS.cSecurityClass, THIS.oConfig)
    ENDIF
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION TearDownSecurity
    IF VARTYPE(THIS.oSecurity) = "O"
      IF PEMSTATUS(THIS.oSecurity, "GarbageCollect", 5)
        * It's "OK" if developer doesn't have such a method.
        THIS.oSecurity.GarbageCollect()
      ENDIF
      THIS.oSecurity = NULL
    ENDIF
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION SetupResponseManager
    THIS.oResponseManager = CREATEOBJECT(THIS.cResponseManagerClass)
    THIS.oResponseManager.AddItem("L7StandardResponse", "StandardResponse")
    THIS.oResponseManager.AddItem("L7ErrorResponse",    "ErrorResponse")
    THIS.oResponseManager.AddItem("L7TemplateResponse", "TemplateResponse")
    THIS.oResponseManager.AddItem("L7FileResponse",     "FileResponse")
    THIS.oResponseManager.AddItem("L7JsonResponse",     "JsonResponse")
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION TearDownResponseManager
    IF VARTYPE(THIS.oResponseManager) = "O"
      THIS.oResponseManager.Remove(-1)
      THIS.oResponseManager = NULL
    ENDIF
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION IsMyRequest
    * Does this App claim this hit? In multi-app situations
    * be sure to set Config VirtualPath or PageExtension settings!
    * Template method for extension/path pieces.
    LOCAL llResult
    llResult = THIS.IsMyRequest_Extension()
    llResult = m.llResult and THIS.IsMyRequest_Path()
    RETURN m.llResult
  ENDFUNC  && IsMyRequest
  * --------------------------------------------------------- *
  FUNCTION IsMyRequest_Extension
    LOCAL lcPhysicalPath, lcExtension, llScriptMap, llResult
    llResult = .T.
    IF m.llResult AND NOT EMPTY(THIS.cPageExtension) AND THIS.cPageExtension <> "*"
      lcPhysicalPath = Request.GetPhysicalPath()
      lcExtension = UPPER( JUSTEXT( m.lcPhysicalPath))
      llScriptMap = NOT INLIST( m.lcExtension, "DLL", "EXE")
      IF NOT m.llScriptMap  && old "wc.dll?app~class" format
        lcExtension = UPPER( Request.QueryString(1))
      ENDIF
      llResult = m.lcExtension == UPPER( THIS.cPageExtension)
    ENDIF
    RETURN m.llResult
  ENDFUNC  && IsMyRequest_Extension
  * --------------------------------------------------------- *
  FUNCTION IsMyRequest_Path
    LOCAL lcLogicalPath, lcExtension, llResult, lcOKPaths, lcOKPath, lnPath
    llResult = .T.
    lcOKPaths = THIS.cVirtualPath
    IF m.llResult AND NOT EMPTY(m.lcOKPaths) AND m.lcOKPaths <> "*"
      lcLogicalPath = UPPER(Request.GetLogicalPath())
      llResult = .F.
      lcLogicalPath = STRTRAN("/" + m.lcLogicalPath + "/", "//", "/")
      FOR lnPath = 1 TO GETWORDCOUNT(m.lcOKPaths, [,])
        lcOKPath = ALLTRIM(UPPER(GETWORDNUM(m.lcOKPaths, m.lnPath, [,])))
        IF NOT EMPTY(m.lcOkPath) 
          lcOKPath = STRTRAN("/" + m.lcOKPath + "/", "//", "/")
          IF m.lcOKPath $ m.lcLogicalPath  && approximate, need some further pattern work here
            llResult = .T.
            EXIT
          ENDIF
        ENDIF
      ENDFOR 
    ENDIF
    RETURN m.llResult
  ENDFUNC  && IsMyRequest_Path
  * --------------------------------------------------------- *
  PROTECTED FUNCTION OnHit( llServerCheck )
    ** NOTE: Above parameter never used--what was our idea?
    LOCAL llRetVal
    llRetVal = .T.

    * Parameter is a flag to allow server to check periodically even with no hit incoming.
    IF THIS.lMaintenanceFlag = .T.
    	* App currently in maintenance mode.
    	IF THIS.MaintenanceInProgress()
    		* Check right away, so we can service hits ASAP following maintenance release.
    		RETURN .F.
    	ELSE
    		THIS.OnMaintenanceRelease()
    		THIS.lMaintenanceFlag = .F.  && should OnMaintenanceRelease clear this?
    	ENDIF
    ELSE
    	* App wasn't in maintenance mode when last we checked.
    	IF THIS.nMaintenanceCheckInterval = 0 OR ;
    		( THIS.nMaintenanceCheckInterval > 0 AND ;
    		( 	ISNULL( THIS.tLastMaintenanceCheck ) OR ;
    			DATETIME() - THIS.tLastMaintenanceCheck >= THIS.nMaintenanceCheckInterval ))
    		* Time for a check.
    		THIS.tLastMaintenanceCheck = DATETIME()
    		IF THIS.MaintenanceInProgress()
    			THIS.OnMaintenance()
    			THIS.lMaintenanceFlag = .T.  && should OnMaintenance set this?
    			RETURN .F.
    		ENDIF
    	ENDIF
    ENDIF
    IF THIS.nHits = 0
    	llRetVal = THIS.OnFirstHit()
    	THIS.lAppOpen = .T.
    ENDIF
    IF m.llRetVal AND NOT THIS.lError 
    	THIS.nHits = THIS.nHits + 1
    	THIS.nCurrentHits = THIS.nCurrentHits + 1
    	llRetVal = THIS.AfterOnHit() && Application Hook!
    ENDIF
    RETURN m.llRetVal AND NOT THIS.lError
  ENDFUNC  && OnHit
  * --------------------------------------------------------- *
  FUNCTION AfterOnHit
    * Application Hook
  ENDFUNC  && AfterOnHit
  * --------------------------------------------------------- *
  FUNCTION OnFirstHit
    RETURN THIS.OnFirstPostMaintenanceHit() AND NOT THIS.lError
  ENDFUNC  && OnFirstHit
  * --------------------------------------------------------- *
  FUNCTION OnFirstPostMaintenanceHit
    * You can override this if you want.
    * Good place to open database for performance reasons.
    RETURN .T.
  ENDFUNC  && OnFirstPostMaintenanceHit
  * --------------------------------------------------------- *
  FUNCTION OnMaintenanceRelease
  ENDFUNC  && OnMaintenanceRelease
  * --------------------------------------------------------- *
  FUNCTION OnMaintenance
    CLOSE DATABASE ALL  && or something like that
    THIS.nCurrentHits = 0
  ENDFUNC  && OnMaintenance
  * --------------------------------------------------------- *
  FUNCTION GetMaintenanceMessage
    RETURN THIS.cMaintenanceMessage
  ENDFUNC  && OnMaintenance
  * --------------------------------------------------------- *
  FUNCTION MaintenanceInProgress
    * Check both server-wide and app-specific flags.
    RETURN FILE( ".\MAINTAIN.TXT" ) OR ;
    	FILE(  ".\MAINTAIN_" + THIS.cApplication + ".TXT" )
  ENDFUNC  && MaintenanceInProgress
  * --------------------------------------------------------- *
  FUNCTION SetMaintenanceFlag
    * Set app-specific flag.
    STRTOFILE( "maintenance flag", ;
      ".\MAINTAIN_" + THIS.cApplication + ".TXT", 0 )
    THIS.OnMaintenance()
    THIS.lMaintenanceFlag = .T. && force flag
  ENDFUNC  && MaintenanceInProgress
  * --------------------------------------------------------- *
  FUNCTION ClearMaintenanceFlag
    * Clear app-specific flag.
    ERASE (".\MAINTAIN_" + THIS.cApplication + ".TXT")
  ENDFUNC  && MaintenanceInProgress
  * --------------------------------------------------------- *
  FUNCTION OnLastHit
    IF THIS.lAppOpen = .T.
    	THIS.OnMaintenance()
    ENDIF
    THIS.lAppOpen = .F.
  ENDFUNC  && OnLastHit
  * --------------------------------------------------------- *
  FUNCTION GetDefaultPage
    * Class method can be overridden, if necessary.
    RETURN THIS.cDefaultPage
  ENDFUNC  && GetDefaultPage
  * --------------------------------------------------------- *
  FUNCTION BeforeExecute
    * Hook called from ProcessPage() template method.
  ENDFUNC  && BeforeExecute
  * --------------------------------------------------------- *
  FUNCTION AfterExecute
    * Hook called from ProcessPage() template method.
  ENDFUNC  && AfterExecute
  * --------------------------------------------------------- *
  FUNCTION AdjustActivePage
    * Hook to alter Page based on Request params.
    * EXPERIMENTAL CODE -- REFACTORING ALMOST ASSURED <S>!!
    * TO DO: Need to give App a way to make this conditional.
    LOCAL lnOcc
    lnOcc = OCCURS("_", THIS.cActivePage)
    IF m.lnOcc >= 2
      Request.FilenameToQueryString("_")
      THIS.cActivePage = LEFT(THIS.cActivePage, ;
        AT("_", THIS.cActivePage, 1 + MOD(m.lnOcc, 2)) - 1)
    ENDIF
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION ResetProperties
    * Called by AppManager just before ProcessPage.
    THIS.ClearErrors()  && from previous hits
    THIS.oActivePage = NULL
    ** THIS.lHack = .F.      && clear flag for next hit
    ** THIS.cHackInfo = ""
    THIS.SetHack(.F.) && clear flag for next hit
    THIS.cActiveResponse = NULL
    THIS.cErrorResponse = NULL
    THIS.lOutputDelivered = .F.
    THIS.cOutputFile = ""
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION DetermineActivePage
    LOCAL lcPhysicalPath, lcExtension, llScriptMap, lcClass
    lcPhysicalPath = Request.GetPhysicalPath()
    lcExtension = UPPER( JUSTEXT( m.lcPhysicalPath))
    llScriptMap = NOT INLIST( m.lcExtension, "DLL", "EXE")
    IF NOT m.llScriptMap
      * old "wc.dll?app~class" format
      lcExtension = UPPER( Request.QueryString(1))
      THIS.cActivePage = Request.QueryString(2)
      THIS.cActivePageExtension = m.lcExtension 
    ELSE
      THIS.cActivePage = JUSTSTEM( m.lcPhysicalPath )
      THIS.cActivePageExtension = JUSTEXT( m.lcPhysicalPath )
      * Temporary approach:
      THIS.AdjustActivePage()
    ENDIF
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  function determineBrowser()
    THIS.cBrowserName = Request.cBrowser
    return 
  endfunc 
  * --------------------------------------------------------- *
  function BeforeProcessPage && blocking hook
    * determineBrowser has been run, and Environ is available here, but little else
    return .T.  && override should likely return dodefault() unless returning .F. (blocking)
  endfunc  
  * --------------------------------------------------------- *
  function getClientCRC() && called from Page, may be overridden (ex: IA headers)
    * page:  THIS.oSession.cClientCRC = THIS.oApp.getClientCRC()  
    return Request.cClientCRC
  endfunc
  * --------------------------------------------------------- *
  FUNCTION ProcessPage

    *** called from L7AppManager.HandleRequest()

    IF NOT THIS.FW_Is_Setup
      ERROR "Application " + TRANSFORM(THIS.cApplication) + " was not setup!"
    ENDIF
    
    * Get browser object available early, in case app wants to react to crawlers, for example.
*!*      if !this.determineBrowser()
*!*        return .t.
*!*      endif 
    private Browser
    Browser = THIS.oBrowser
    Browser.ResetProperties()
    this.determineBrowser()
    *!*      THIS.cBrowserName = Request.cBrowser
    Browser.SetBrowser( THIS.cBrowserName )
    
*!*      * 06/22/2010: experimental, add CurrentUser now so it stays available for CheckLog processing.
*!*      private CurrentUser, TrueUser
*!*      if not isnull(this.cUserClass)
*!*        CurrentUser = createobject(this.cUserClass)
*!*        TrueUser = CurrentUser
*!*      else
*!*        store null to CurrentUser, TrueUser
*!*      endif 
* 07/21/2010: moved down lower so structure mods can happen above w/o User table open

    THIS.cErrorReturnMethod = "HandleRequest"  && fail to AppManager for now
    
    LOCAL llRetVal
    llRetVal = .T.
    IF NOT THIS.BeforeProcessPage() && alternative--must call DeliverOutput separately
      this.checkLog(m.Environ)  && DRY issue ... consider refactor to (another) template method
      return .T. && True, because from AppManager standpoint, the page has been processed.
    ENDIF 
    
    THIS.DetermineActivePage()

    #IF L7_MONITOR_PROCESS
      LOCAL loProcMon
      loProcMon = goL7AppManager.oProcessMonitor
      IF NOT m.loProcMon.BeforeAppProcessPage(THIS)
        RETURN .F.
      ENDIF
    #ENDIF

*[[ Replace with something else! Perhaps AppManager should be involved:
*[[
*!*      * Check for maintenance flag set/clear:
*!*      IF THIS.cActivePage == "set_maintenance" OR THIS.cActivePage == "clear_maintenance"
*!*        IF Request.IsAdministrator()
*!*          IF THIS.cActivePage == "set_maintenance"
*!*            THIS.SetMaintenanceFlag()
*!*          ELSE
*!*            THIS.ClearMaintenanceFlag()
*!*          ENDIF
*!*          THIS.cActivePage = ""
*!*          THIS.cActivePageExtension = ""
*!*        ELSE
*!*          * Just let this trigger an error later (class not found), so admin
*!*          * gets email (potential hack).
*!*        ENDIF
*!*      ENDIF

    IF EMPTY( THIS.cActivePage)
    	* No specific page in URL, so use default page to know
    	* which class to call. 
    	* (Problem here in that the QueryString does not contain this info, 
    	* so it is missing a parameter.)
    	THIS.cActivePage = THIS.GetDefaultPage()
      *[[[ How do we determine cActivePageExtension here??
    ENDIF

    THIS.BeforeExecute()  

    * Call OnHit() to see if it's OK to process the hit. This must be called
    * before the Page object is created, so that default tables can be opened, etc.
    goL7AppManager.oConnector.SetExtraStatusInfo("")
    IF NOT THIS.OnHit()
    	* Probably a maintenance flag set.
    	IF NOT THIS.lError
    		THIS.cErrorMessage = THIS.GetMaintenanceMessage()
    	ENDIF
    	RETURN .F.
    ENDIF

    * 07/21/2010: moved down here so structure mods can happen above w/o User table open
    private CurrentUser, TrueUser
    if not isnull(this.cUserClass)
      CurrentUser = createobject(this.cUserClass)
      TrueUser = CurrentUser
    else
      store null to CurrentUser, TrueUser
    endif 

    * Call your page class:
    local loPage
    loPage = THIS.GetPageObject()  && factory method
    
    local llDebugPageState, loPageState
    llDebugPageState = pemstatus(_screen, "_L7DebugPageState", 5) and _screen._L7DebugPageState = .t.
    * Execute to debug: addproperty(_screen, "_L7DebugPageState", .t.)

    if VARTYPE( m.loPage) <> "O" && no object created
      llRetVal = .F.
    else 

      if m.llDebugPageState
        loPageState = L7noteObjectState(m.loPage)
      endif 
      THIS.cErrorReturnMethod = "ProcessPage"  && fail to here
      THIS.oActivePage = m.loPage
      * Start the page with the application's title:
      IF ISNULL(loPage.cTitle)
        loPage.cTitle = THIS.cTitle
        * Page objects can modify this and/or can tack on cSubTitle.
      ENDIF
      
      * Create a few handy reference vars:
      PRIVATE Config, Page
      Page = m.loPage
      Config = THIS.oConfig

      * Declare any app-specific PRIVATE vars: 
      * (This puts these vars in "scope" for all page processing.) 
      LOCAL loPrivateVar, lcVarName
      FOR EACH loPrivateVar IN THIS.PrivateVars
        lcVarName = m.loPrivateVar.cVarName
        PRIVATE &lcVarName
        IF NOT EMPTY(m.loPrivateVar.cVarExpression)
          STORE EVALUATE(m.loPrivateVar.cVarExpression) TO (m.lcVarName)
        ELSE
          STORE .F. TO (m.lcVarName)
        ENDIF
      ENDFOR
      RELEASE loPrivateVar, lcVarName
        
      ***********************************************************
      * Main call to Page object:
      IF NOT THIS.lError
        loPage.ExecuteRequest()  
      ENDIF
      * ExecuteRequest() is a template method that eventually calls the (overridable) 
      * DoProcessRequest() method, which in turn is responsible for
      * calling the ProcessRequest() method for your individual page.
      ***********************************************************

      * Hack alert:
    	IF THIS.lHack
    		THIS.LogHackAttempt()
        THIS.SendHackAlert()
    	ENDIF  && hack
      
      * Error alert:
    	IF THIS.lError AND NOT THIS.lHack
        THIS.SendErrorAlert()
    	ENDIF  && error
      
      IF NOT THIS.lOutputDelivered  && various blocking hooks could pre-deliver, so check
        THIS.DeliverOutput()
      ENDIF
      llRetVal = m.llRetVal AND THIS.lOutputDelivered
      
      if m.llDebugPageState
        if !L7compareObjectState(m.loPage, m.loPageState)
          * look at Debug Output window
          environ.debugOutput()
        endif
      endif
    endif  && loPage [not] created

    * Hook:
    THIS.AfterExecute()  

    #IF L7_MONITOR_PROCESS
      m.loProcMon.AfterAppProcessPage(THIS)
    #ENDIF
    
    this.CheckLog(m.Environ)  && DRY problem. If BeforeProcessPage aborts, this doesn't get called.

    THIS.oActivePage = NULL
    release loPage, Page, Config
    release CurrentUser, TrueUser
    release Browser
    
    THIS.cErrorReturnMethod = ""  

    ** RETURN m.llRetVal AND NOT THIS.lError
    return m.llRetVal 
    * App Manager interprets .F. return as a failure to deliver a response. So
    * even delivering an error message should result in true return value.
  ENDFUNC  && ProcessPage

  * ---------------------------------------------------------- *
  FUNCTION SetHack(llFlag, lcHackInfo, lcUserTitle, lcUserDetails)
    * Support for previous interface:
    IF VARTYPE(m.llFlag) = "C"  
      lcHackInfo = m.llFlag
      llFlag = .T.
    ENDIF
    * Now the real method:
    IF NOT m.llFlag && cleaaring
      THIS.lHack = .F.
      THIS.cHackInfo = ""
    ELSE
      THIS.lHack = .T.
      LOCAL lcStr, loExc
      lcStr = ""
      TRY
        IF VARTYPE( m.lcUserTitle) = "C"
          lcStr = m.lcStr + [Message Heading: ] + m.lcUserTitle + L7BR + CR
        ENDIF
        IF VARTYPE( m.lcUserDetails) = "C"
          lcStr = m.lcStr + [Message to User: ] + m.lcUserDetails + L7BR + CR
        ENDIF
        IF VARTYPE( m.lcHackInfo) = "C"
          lcStr = m.lcStr + [Administrator Info: ] + m.lcHackInfo + L7BR + CR
        ENDIF
        IF VARTYPE(m.Request) = "O"
          lcStr = m.lcStr + Request.GetDebugInfo()
        ENDIF
        lcStr = m.lcStr + L7ShowStackInfo() 
        IF VARTYPE(m.CurrentUser) = "O"
          lcStr = m.lcStr + CurrentUser.GetDebugInfo()
        ENDIF
      CATCH TO loExc
        lcStr = "SetHack: Exception occurred while assembling hack info. " + loExc.Message
      ENDTRY
      THIS.cHackInfo = m.lcStr
    ENDIF
    RETURN 
  ENDFUNC
  * ---------------------------------------------------------- *
  FUNCTION SendHackAlert()
    ** IF VARTYPE( m.Server) = "O" AND Server.oConfig.lAdminSendErrorEmail
    LOCAL loConn
    loConn = goL7AppManager.oConnector
    IF m.loConn.lAdminSendErrorEmail
      LOCAL lcCC, lcAdminEmail
      lcAdminEmail = ""
      TRY
        lcAdminEmail = THIS.oConfig.cAdminEmail
        lcCC = THIS.oConfig.cAdminCC
      CATCH
        = .F.
      ENDTRY
      IF EMPTY(m.lcAdminEmail)
        lcAdminEmail = loConn.cAdminEmail
        lcCC = loConn.cAdminCC
      ENDIF
      THIS.QueueMessage( ;
        m.lcAdminEmail, ;
        THIS.cApplication + " Admin Alert!", ;
        THIS.cHackInfo, ;
        "L7 Application " + THIS.Class, ;
        m.lcAdminEmail, ;
        m.lcCC, ;
        .F., ;
        .F., ;
        "text/html" )
    ENDIF
    RETURN 
  ENDFUNC  && SendHackAlert
  * ---------------------------------------------------------- *
  FUNCTION SendErrorAlert()
    LOCAL loConn
    loConn = goL7AppManager.oConnector
    IF m.loConn.lAdminSendErrorEmail
      LOCAL lcCC, lcAdminEmail, lcMessage, lcSubject
      **lcAdminEmail = loConn.cAdminEmail
      **lcCC = loConn.cAdminCC
      ** loPage = THIS.oActivePage
      lcAdminEmail = ""
      lcSubject = evl(nvl(this.cErrorTitle, ""), THIS.cApplication + " Application Error")
      TRY
        lcAdminEmail = THIS.oConfig.cAdminEmail
        lcCC = THIS.oConfig.cAdminCC
      CATCH
        = .F.
      ENDTRY
      IF EMPTY(m.lcAdminEmail)
        lcAdminEmail = loConn.cAdminEmail
        lcCC = loConn.cAdminCC
      ENDIF

      IF VARTYPE(THIS.oDebugInfo) = "O"
        lcMessage = THIS.oDebugInfo.RenderForEmail()
      ELSE
        lcMessage = THIS.cErrorMessage + ;
          IIF( VARTYPE( Request) = "O", Request.GetDebugInfo(), []) + ;
          IIF( VARTYPE( CurrentUser) = "O", CurrentUser.GetDebugInfo("Current User Object"), [])
      ENDIF
      THIS.QueueMessage( ;
        m.lcAdminEmail, ;
        m.lcSubject, ;
        m.lcMessage, ;
        THIS.cApplication + " (L7 Application)", ;
        m.lcAdminEmail, ;
        m.lcCC, ;
        .F., ;
        .F., ;
        "text/html" )
    ENDIF
    RETURN 
  ENDFUNC  && SendErrorAlert
  * ---------------------------------------------------------- *
  FUNCTION BeforeDeliverOutput()
  ENDFUNC
  * ---------------------------------------------------------- *
  FUNCTION AfterDeliverOutput()
  ENDFUNC
  * ---------------------------------------------------------- *
  FUNCTION DeliverOutput(loPage, lcAltOutput)
    THIS.BeforeDeliverOutput()
    LOCAL llWasError, loResp, lcMethod, lcDestination, llSuccess, loConn
    loConn = goL7AppManager.oConnector 
    lcMethod = m.loConn.DeliverHow()   && ["ToFile", "ToProperty"]
    lcDestination = m.loConn.DeliverWhere()  && filename, property name
   
    DO WHILE NOT THIS.lOutputDelivered
      * DANGER HERE: If an error doesn't occur until the Render
      * activities take place, we're past the point where we decided not to
      * deliver an Error reponse instead. 
      llWasError = THIS.lError  && were we already dealing with an error?
      loResp = THIS.GetActiveResponseObject()
      llSuccess = EVALUATE("loResp." + m.lcMethod + "(m.lcDestination, THIS, m.lcAltOutput)")
      IF NOT m.llSuccess AND NOT THIS.lError
        THIS.SetError("Error delivering response. [L7App]")
      ENDIF
      IF THIS.lError AND NOT m.llWasError
        * Error triggered _during_ attempted delivery.
        LOOP  && have error-reporting object to deliver error response
      ENDIF
      THIS.lOutputDelivered = .T.
    ENDDO
    THIS.AfterDeliverOutput()
    RETURN 
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION GetActiveResponseObject()
    LOCAL lcKey, loObj
    * First, find the expected response object:
    lcKey = NVL(THIS.cActiveResponse, THIS.cDefaultResponse)
    TRY
      loObj = THIS.oResponseManager.Item(m.lcKey)
    CATCH
      THIS.SetError("Invalid response item key: " + TRANSFORM(m.lcKey))
      loObj = THIS.oResponseManager.Item("ErrorResponse")  && This must always exist.
    ENDTRY
    * Then, if in error condition, switch if necessary:
    IF (THIS.lError OR THIS.lErrorMsg) AND NOT loObj.lCanReportError
      lcKey = NVL(THIS.cErrorResponse, loObj.cErrorResponse)  && set to matching error response class, unless overridden here
      TRY
        loObj = NULL
        loObj = THIS.oResponseManager.Item(m.lcKey)
      CATCH  && last ditch fallback:
        loObj = THIS.oResponseManager.Item("ErrorResponse")  && This must always exist.
      ENDTRY
    ENDIF
    RETURN m.loObj 
  ENDFUNC  && GetAcetiveResponse
  * --------------------------------------------------------- *
  FUNCTION GetPageObject
    LOCAL loObj, llFound, loExc as Exception
    IF BITAND(THIS.nPageCreation, L7_PAGECREATION_FACTORY) > 0
      * Factory supported.
      *[[ TRY
        loObj = THIS.oPageFactory.GetObject(THIS) && must pass App ref -- more than just cActivePage property may be needed
      *[[ CATCH TO loExc
      *[[   THROW [Error ] + TRANSFORM(m.loExc.ErrorNo) + ;
      *[[    [, "] + loExc.Message + [", occurred in page factory.]
      *[[ ENDTRY
      llFound = VARTYPE(loObj) = "O"
    ENDIF
    IF NOT m.llFound  && "old" way -- assume SET PROC has it covered
      IF BITAND(THIS.nPageCreation, L7_PAGECREATION_DIRECT) > 0
        * Direct instantiation supported.
        * Convert URL-derived page name to VFP class name:
        IF UPPER(LEFT(THIS.cActivePage,2)) <> "L7"
          * Checking for L7 prefix allows us to build in some
          * pre-defined pages, such as "L7ForceError" without
          * needing each app to implement them, or to worry about
          * clashes with app-specific prefixes or suffixes.
          THIS.cActivePageClass = ;
            THIS.cClassPrefix + THIS.cActivePage + THIS.cClassSuffix
        ENDIF
        *[[ TRY
          loObj = CREATEOBJECT( THIS.cActivePageClass, THIS)
        *[[ CATCH TO loExc
        *[[  THIS.SetError([Error ] + TRANSFORM(m.loExc.ErrorNo) + ;
            [, "] + loExc.Message + [", occurred trying to create ] + ;
            THIS.cActivePageClass + [ object.], ;
            "Error Creating Page")
        *[[ ENDTRY
        * If there is no such class, the above command will
        * generate an error 1733, which will be trapped and reported back.
      ENDIF
    ENDIF
    RETURN loObj
  ENDFUNC  && GetPageObject
  * --------------------------------------------------------- *
  FUNCTION DoLogRequest
    * Called by L7Page, when CurrentUser and other information is available.
    LOCAL llFail
    IF THIS.lLogRequests
      llFail = NOT THIS.LogRequest()  && application hook
    ENDIF
    * Not a failure if logging is not turned on.
    RETURN NOT m.llFail
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION LogRequest  && hookable
    IF VARTYPE(THIS.oRequestLog) <> "O"
      THIS.oRequestLog = CREATEOBJECT( THIS.cLogRequestClass, ;
        THIS.cLogRequestBaseName )
      THIS.oRequestLog.cLogFilePath = THIS.cLogPath
    ENDIF
    THIS.oRequestLog.Log()
    RETURN
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION LogAuth(toAuth)
    IF VARTYPE(THIS.oAuthLog) <> "O"
      THIS.oAuthLog = CREATEOBJECT( THIS.cAuthLogClass, ;
        THIS.cAuthLogBaseName )
      THIS.oAuthLog.cLogFilePath = THIS.cLogPath
    ENDIF
    THIS.oAuthLog.Log(m.toAuth)
    RETURN
  ENDFUNC
  * --------------------------------------------------------- *
  FUNCTION LogHackAttempt
    LOCAL loHackLog
    loHackLog = CREATEOBJECT(THIS.cLogHackClass) && default is L7LogHack
    loHackLog.cPath = THIS.cMessagingPath
    loHackLog.Log(THIS)
    loHackLog = NULL
    RETURN
  ENDFUNC  && LogHackAttempt
  * --------------------------------------------------------- *
  function app_Log(tnSev, tcMsg, tvDetails, toPage)
    local loItem, loLog, lcDetType, loExc
    loLog = Environ.item("log")
    if vartype(m.tnSev) = "C"  && name like "Error"
      tnSev = L7SeverityNumber(m.tnSev)
    endif
    loItem = createobject("L7LogItem") && in L7Utils
    with loItem
      .Severity = m.tnSev
      .App = this.cApplication  && enable "own item" ID on post-process side
      if vartype(m.toPage) = "O"
        .Page = toPage.Class && called from Page 
      endif 
      .LogLine = m.tcMsg
      .Timestamp = datetime()
      * optional Details
      try
        lcDetType = vartype(m.tvDetails)
        do case
        case m.lcDetType == "C" 
          .Details = m.tvDetails
        case m.lcDetType == "O" 
          if pemstatus(m.tvDetails, 'render', 5)
            .Details = m.tvDetails.render()
          else
            .Details = HTWrap(L7JsonSerialize(m.tvDetails), 'pre')
          endif
        case m.lcDetType $ 'TDINY'
          .Details = transform(m.tvDetails)
        endcase
        
      catch to loExc
        .Details = 'Error determining details: ' + L7ExceptionMessage(m.loExc)
      endtry
    endwith 
    loLog.add(loItem)
    if loLog.nMinSeverity > loItem.Severity && worst so far
      loLog.nMinSeverity = loItem.Severity 
    endif
    return 
  endfunc 
  * --------------------------------------------------------- *
  function checkLog(toEnv)
    * Similar to appMamager check, but within app's range, and a Config is available.
    
    * If _any_ are unprocessed and important, then send all unprocessed items (for context).
    
    local lcDivStyle, lnK, lnN, loItem, ;
      lcSubj, lcMsg, lcDetails, lcTo, lcCC, lcStr, ;
      lcItemStyle, lcOut, loLog, ; 
      loExc, loConn, llThresh, lcStyle, ;
      lnThreshSeverity, ;  && severity threshhold for causing email to go
      lcFirstTrigger, ;    && first message that hit the worst level 
      lnTriggerSeverity, ; && level of worst message
      lnTriggerCount       && # of lines at worst level
      
    lcDivStyle = "font-size: x-small;"  && apply inline to all top <div>'s for email
    
    try 
      lnThreshSeverity = L7_SEVERITY_NOTICE 
      * decrease sensitivity if automated Testing user:
      if vartype(m.CurrentUser) = "O" and pemstatus(CurrentUser, "isTester", 5) and CurrentUser.isTester()
        lnThreshSeverity = L7_SEVERITY_ERROR
      endif
      loLog = toEnv.item["log"]
      lcOut = ""
      lcDetails = ""
      lcFirstTrigger = ""
      lnTriggerCount = 0
      lnN = 0
      
      * Did we reach trigger threshhold:
      llThresh = loLog.nMinSeverity <= m.lnThreshSeverity
      lnTriggerSeverity = loLog.nMinSeverity 
      
      for lnK = 1 to loLog.count
        loItem = loLog.item(m.lnK)
        if loItem.processed or !loItem.App == this.cApplication  
          loop  && [[ this means anything inserted by AppManager is ignored here. appropriate? maybe there's useful debugging...
        endif
        lnN = m.lnN + 1 && running number
        loItem.Processed = .t.  && keep app manager from handling, too
        
        if !m.llThresh && now we know the output answer and can avoid processing
          loop
        endif 
        
        if m.lnTriggerSeverity = loItem.Severity && one of the lines at worst level: count and use in Subject
          lnTriggerCount = m.lnTriggerCount + 1 
          if empty(m.lcFirstTrigger)
            lcFirstTrigger = loItem.LogLine
          endif 
        endif 

        lcMsg = loItem.Render()
        if vartype(loItem.Details) = "C" and !empty(loItem.Details)
          lcMsg = m.lcMsg + [&nbsp;<a href="#detail_] + transform(m.lnN) + [">Details...</a>]
          lcDetails = m.lcDetails + [<div style="] + m.lcDivStyle + ["><a name="detail_] + transform(m.lnN) + [">Detail #] + transform(m.lnN) + [</a><br />] + CRLF + ;
            loItem.Details + CRLF + [</div>] + CRLF
        endif
        lcItemStyle = icase(;
          loItem.Severity <= L7_SEVERITY_ERROR, [color: white; background-color: brown;], ;
          loItem.Severity <= L7_SEVERITY_WARNING, [color: brown; background-color: white;], ;
          loItem.Severity <= L7_SEVERITY_NOTICE, [color: blue; background-color: white;], ;
          loItem.Severity <= L7_SEVERITY_INFO, [color: black; background-color: white;], ;
          [color: #666; background-color: white;] ) && DRY to deal w/ HTML email style issues
          
        lcMsg = [<li style="] + m.lcItemStyle + [">] + m.lcMsg + [</li>] + CRLF
        lcOut = m.lcOut + m.lcMsg
      next && Item in log
      
      if m.llThresh && was: not empty(m.lcOut)

        try
          lcSubj = ;
            textmerge([<<THIS.cApplication>>.<<L7SeverityName(m.lnTriggerSeverity)>>]) + ;
            iif(m.lnTriggerCount <= 1, '', '(' + transform(m.lnTriggerCount) + ')') + ;
            iif(vartype(m.CurrentUser) = "O" and pemstatus(m.CurrentUser, "getUserId", 5), "." + trim(CurrentUser.getUserId()), "")
          lcSubj = "[" + lower(m.lcSubj) + "] " + left(m.lcFirstTrigger, 132)

          text to lcStyle noshow pretext 7
            <style type="text/css">
            table.DebugInfo{border-collapse: collapse; font-size: x-small;}
            table.DebugInfo TH{font-variant: small-caps;}
            .logitems {border: 2px solid purple;}
            .EMERGENCY, .ALERT, .CRITICAL, .ERROR {color: white; background-color: brown;}
            .EMERGENCY, .ALERT, .CRITICAL {font-size: larger;}
            .WARNING {color:brown; background-color: white;}
            .NOTICE, .INFO {color:black; background-color: white;}
            .DEBUG{color: #666; background-color: white;}
            
            .request{color:#303; background-color: #ccc;}
            
            </style>
            
          endtext
          lcOut = [<div class="logitems" style="] + m.lcDivStyle + [">] + CRLF + [<ol>] + CRLF + m.lcOut + [</ol>] + CRLF + [</div>] + CRLF 

          if vartype(m.CurrentUser) = "O" and pemstatus(m.CurrentUser, "getContactInfo", 5)
            lcOut = m.lcOut + HTWrap("User Info: " + CurrentUser.getContactInfo(), 'p')
          endif

          lcOut = m.lcOut + m.lcDetails
          if vartype(m.Environ) = 'O'
            lcOut = m.lcOut + [<div class="logitems" style="] + m.lcDivStyle + [">] + CRLF + ;
              Environ.getDebugInfo() + ;
              CRLF + [</div>] + CRLF 
          endif 

          lcOut = [<html>] + CRLF + ;
            [<head>] + CRLF + m.lcStyle + CRLF + [</head>] + CRLF + ;
            [<body>] + CRLF + ;
            [<p>The following application events occurred:</p>] + CRLF + CRLF + ;
            m.lcOut + ;
            [</body>] + CRLF + ;
            [</html>] + CRLF 
          
          lcTo = THIS.oConfig.cAdminEmail
          lcCC = THIS.oConfig.cAdminCC
          * If current user is Developer, send to self instead:
          try
            if vartype(m.CurrentUser) = "O"
              if pemstatus(CurrentUser, "isDeveloper", 5) and CurrentUser.isDeveloper()
                if pemstatus(CurrentUser, "getEmailAddress", 5)
                  lcStr = CurrentUser.getEmailAddress()
                  if IsValidEmail(m.lcStr)
                    lcTo = m.lcStr && if this works we'll switch to lcTo and set lcCc to ""
                    lcCC = ""
                  endif
                endif
              endif
            endif
          catch
          endtry 
          
          *!*  if version(2)=2 and !file('DEBUG_applog_email.html')
          *!*    strtofile(m.lcOut, 'DEBUG_applog_email.html')
          *!*  endif

          this.QueueMessage(;
            m.lcTo, ;
            m.lcSubj, ;
            m.lcOut, ;
            .f., THIS.oConfig.cAdminEmail, ;
            m.lcCC, "", ;
            "", "text/html", .f., ;
            "", ;
            icase(m.lnTriggerSeverity <= L7_SEVERITY_ERROR, "High", m.lnTriggerSeverity <= L7_SEVERITY_WARNING, "Normal", "Low"))

        catch to loExc
          * lcOut = [The following important application events occurred:] + CRLF + CRLF + m.lcOut
          loConn = goL7AppManager.oConnector
          loConn.ErrorEmail( "[" + THIS.cApplication + "] Application Event Warning", transform(m.lcOut) + CRLF + CRLF)
        endtry

      endif 
    catch to loExc
      = .f. && not good, but don't take down server for it
    endtry

    return 
  endfunc && checkLog 
  * --------------------------------------------------------- *
  function QueueMessage(lcTo, lcSubject, lcMessage, ;
    	lcFromName, lcFromEmail, ;
      lcCc, lcBcc, ;
    	lcAttachment, lcContentType, llNoImmediateSend, ;
      lcExtraHeaders, lcPriority)

    LOCAL loQueue, loState, loMsg, llSent, llAttemptSend, loExc
    loMsg = CREATEOBJECT("L7MailMessage")
    WITH loMsg
      .cTo = m.lcTo
      .cSubject = m.lcSubject
      .cMessage = m.lcMessage
      .cFromEmail = m.lcFromEmail
      if empty(m.lcFromName)
        .cFromName = THIS.cApplication + "." + trim(getwordnum(sys(0), 1, "#"))
      else
        .cFromName = m.lcFromName
      endif
      .cCC = m.lcCC
      .cBCC = m.lcBCC
      .cAttachment = m.lcAttachment
      .cContentType = m.lcContentType
      .cExtraHeaders = m.lcExtraHeaders
      .cPriority = m.lcPriority
    endwith
    
*!*    TRY

  loQueue = CREATEOBJECT(THIS.cMessageQueueClass)
  ** loQueue.cPath = THIS.cMessagingPath
  loQueue.ConfigFromApp(THIS, goWcServer)

  llAttemptSend = NOT m.llNoImmediateSend ;
    and THIS.lMailServerAvailable ;
    AND THIS.oConfig.lSendMailImmediately

  ** llSent = loQueue.Queue(loMsg, THIS, llNoImmediateSend)
  loState = loQueue.Queue(loMsg, m.llAttemptSend)
  llSent = loState.lSent


*!*      CATCH TO loExc
*!*        * Not sure what to do here? Don't want to THROW a 
*!*        * further exception (possibly) because we may already be
*!*        * reporting an error.
*!*        THROW [Error ] + TRANSFORM(loExc.ErrorNo) + ;
*!*          [, "] + loExc.Message + ;
*!*          [," occurred while queueing message: ] + ;
*!*          TRANSFORM(m.lcSubject) + [.<br>] + m.lcMessage
*!*      FINALLY

  loQueue = NULL
  loMsg = NULL

*!*      ENDTRY
    
    RETURN m.llSent  && .F. if only queued
  ENDFUNC && QueueMessage
  * --------------------------------------------------------- *
  * DEPRECATED: (individual databases should handle)
  FUNCTION OpenAllTables
    LOCAL llRet, loExc
    llRet = .T.
    TRY
      IF NOT EMPTY(THIS.cDatabase) AND DBUSED(THIS.cDatabase)
        SET DATABASE TO (THIS.cDatabase)
        LOCAL aa[1], ii, nn, lcCmd
        nn = ADBOBJECTS(aa,"TABLE")
        FOR ii = 1 TO nn
          ss = aa[m.ii]
          USE (m.ss) AGAIN ;
            ALIAS (m.ss+"_Performance") ;
            IN SELECT(m.ss+"_Performance")
        ENDFOR
      ENDIF
    CATCH TO loExc
      llRet = .F.
      THIS.SetError(loExc.Message, "Application Error on OpenAllTables()", loExc)
    ENDTRY
    RETURN m.llRet
  ENDFUNC
  * --------------------------------------------------------- *
ENDDEFINE  && L7App



#IF .F.
* 04/02/2002
*  - Renamed PreProcessRequest() to BeforeExecute().
*  - Added AfterExecute().

* 03/30/2002
*  - Added class factory approach for pages.
*  - Renamed property L7App.cScriptAlias to .cPageAlias.
*  - Included example dummy subclass (commented out).
*  - Fixed multiplicity issue with Request Logs.
*  - Improved Log performance by opening it permanently in its own datasession.

* 01/25/2002
*  - Added L7App::LogRequest().

* 02/01/2001
*  - Changed L7AppManager to use 1-dimensional array to support
*    FOR EACH calls from outside.

12/14/2002 - Renamed LogRequestTemplate() to CallLogRequest().
12/18/2002 - Changed GetPageObject to pass THIS to factory/pages.
12/24/2002 - Renamed CallLogRequest() to DoLogRequest().
01/02/2003 - Moved L7AppManager to its own PRG.
01/13/2003 - Removed oConfig from INIT parameters.
           - Changed default on cApplication to NULL.
           - Changed INIT logic.
           - Changed SetupObjects to have more bridge/factory/template flexibility.
01/14/2003 - Changed Page.Execute to Page.ExecuteRequest to allow unambiguous RETURN TO
01/20/2003 - Added SetHack(). Revised ProcessPage to check for abort of page w/o rendering.
03/04/2003 - Updated SetupParseManager() to use: THIS.oParseManager.Config(THIS.oConfig)
05/06/2003 - Revised base class from Session to Form, so we can addObject.
06/15/2003 - Changed L7_PAGE_DEBUG to DEBUGMODE.
           - Changed default page alias to singular (xxxPage vs xxxPages).
09/01/2003 - Endow page title with app title (unless property set in page constructor).
11/02/2003 - Remove oConnector -- moved up to AppManager.
12/02/2003 - added Nancy Folsom's approach to using ASSERT in ERROR() method
09/22/2004 - Adjusted SendHackAlert to use app's adminEmail instead of global
03/05/2007 - Moved Browser object creation from Page to persistent level within App. 
           - Added BeforeProcessPage as blocking hook from ProcessPage
           - Revised QueueMessage to pass config to message queue object
#ENDIF

* End: L7App.PRG
