" Vim syntax file
" Language:	SourcePawn
" Maintainer:	Murray Wilson
" Last Change:	2007 Dec 21

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" A bunch of useful C keywords
syn keyword	cStatement	goto break return continue assert state sleep exit
syn keyword	cLabel		case default
syn keyword	cConditional	if else switch
syn keyword	cRepeat		while for do

syn keyword	cTodo		contained TODO FIXME XXX

" cCommentGroup allows adding matches for special things in comments
syn cluster	cCommentGroup	contains=cTodo

" String and Character constants
" Highlight special characters (those which have a backslash) differently
syn match	cSpecial	display contained "\\\(x\x\+\|\o\{1,3}\|.\|$\)"
if !exists("c_no_utf")
  syn match	cSpecial	display contained "\\\(u\x\{4}\|U\x\{8}\)"
endif
if exists("c_no_cformat")
  syn region	cString		start=+L\="+ skip=+\\\\\|\\"+ end=+"+ contains=cSpecial,@Spell
  " cCppString: same as cString, but ends at end of line
  syn region	cCppString	start=+L\="+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end='$' contains=cSpecial,@Spell
else
  if !exists("c_no_c99") " ISO C99
    syn match	cFormat		display "%\(\d\+\$\)\=[-+' #0*]*\(\d*\|\*\|\*\d\+\$\)\(\.\(\d*\|\*\|\*\d\+\$\)\)\=\([hlLjzt]\|ll\|hh\)\=\([aAbdiuoxXDOUfFeEgGcCsSpn]\|\[\^\=.[^]]*\]\)" contained
  else
    syn match	cFormat		display "%\(\d\+\$\)\=[-+' #0*]*\(\d*\|\*\|\*\d\+\$\)\(\.\(\d*\|\*\|\*\d\+\$\)\)\=\([hlL]\|ll\)\=\([bdiuoxXDOUfeEgGcCsSpn]\|\[\^\=.[^]]*\]\)" contained
  endif
  syn match	cFormat		display "%%" contained
  syn region	cString		start=+L\="+ skip=+\\\\\|\\"+ end=+"+ contains=cSpecial,cFormat,@Spell
  " cCppString: same as cString, but ends at end of line
  syn region	cCppString	start=+L\="+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end='$' contains=cSpecial,cFormat,@Spell
endif

syn match	cCharacter	"L\='[^\\]'"
syn match	cCharacter	"L'[^']*'" contains=cSpecial
if exists("c_gnu")
  syn match	cSpecialError	"L\='\\[^'\"?\\abefnrtv]'"
  syn match	cSpecialCharacter "L\='\\['\"?\\abefnrtv]'"
else
  syn match	cSpecialError	"L\='\\[^'\"?\\abfnrtv]'"
  syn match	cSpecialCharacter "L\='\\['\"?\\abfnrtv]'"
endif
syn match	cSpecialCharacter display "L\='\\\o\{1,3}'"
syn match	cSpecialCharacter display "'\\x\x\{1,2}'"
syn match	cSpecialCharacter display "L'\\x\x\+'"

"when wanted, highlight trailing white space
if exists("c_space_errors")
  if !exists("c_no_trail_space_error")
    syn match	cSpaceError	display excludenl "\s\+$"
  endif
  if !exists("c_no_tab_space_error")
    syn match	cSpaceError	display " \+\t"me=e-1
  endif
endif

" This should be before cErrInParen to avoid problems with #define ({ xxx })
syntax region	cBlock		start="{" end="}" transparent fold

"catch errors caused by wrong parenthesis and brackets
" also accept <% for {, %> for }, <: for [ and :> for ] (C99)
" But avoid matching <::.
syn cluster	cParenGroup	contains=cParenError,cIncluded,cSpecial,cCommentSkip,cCommentString,cComment2String,@cCommentGroup,cCommentStartError,cUserCont,cUserLabel,cCommentSkip,cCppOut,cCppOut2,cCppSkip,cFormat,cNumber,cFloat,cNumbersCom
if exists("c_no_curly_error")
  syn region	cParen		transparent start='(' end=')' contains=ALLBUT,@cParenGroup,cCppParen,cCppString,@Spell
  " cCppParen: same as cParen but ends at end-of-line; used in cDefine
  syn region	cCppParen	transparent start='(' skip='\\$' excludenl end=')' end='$' contained contains=ALLBUT,@cParenGroup,cParen,cString,@Spell
  syn match	cParenError	display ")"
  syn match	cErrInParen	display contained "^[{}]\|^<%\|^%>"
elseif exists("c_no_bracket_error")
  syn region	cParen		transparent start='(' end=')' contains=ALLBUT,@cParenGroup,cCppParen,cCppString,@Spell
  " cCppParen: same as cParen but ends at end-of-line; used in cDefine
  syn region	cCppParen	transparent start='(' skip='\\$' excludenl end=')' end='$' contained contains=ALLBUT,@cParenGroup,cParen,cString,@Spell
  syn match	cParenError	display ")"
  syn match	cErrInParen	display contained "[{}]\|<%\|%>"
else
  syn region	cParen		transparent start='(' end=')' contains=ALLBUT,@cParenGroup,cCppParen,cErrInBracket,cCppBracket,cCppString,@Spell
  " cCppParen: same as cParen but ends at end-of-line; used in cDefine
  syn region	cCppParen	transparent start='(' skip='\\$' excludenl end=')' end='$' contained contains=ALLBUT,@cParenGroup,cErrInBracket,cParen,cBracket,cString,@Spell
  syn match	cParenError	display "[\])]"
  syn match	cErrInParen	display contained "[\]{}]\|<%\|%>"
  syn region	cBracket	transparent start='\[\|<::\@!' end=']\|:>' contains=ALLBUT,@cParenGroup,cErrInParen,cCppParen,cCppBracket,cCppString,@Spell
  " cCppBracket: same as cParen but ends at end-of-line; used in cDefine
  syn region	cCppBracket	transparent start='\[\|<::\@!' skip='\\$' excludenl end=']\|:>' end='$' contained contains=ALLBUT,@cParenGroup,cErrInParen,cParen,cBracket,cString,@Spell
  syn match	cErrInBracket	display contained "[);{}]\|<%\|%>"
endif

"integer number, or floating point number without a dot and with "f".
syn case ignore
syn match	cNumbers	display transparent "\<\d\|\.\d" contains=cNumber,cFloat
" Same (for comments)
syn match	cNumbersCom	display contained transparent "\<\d\|\.\d" contains=cNumber,cFloat
syn match	cNumber		display contained "\d\+\(u\=l\{0,2}\|ll\=u\)\>"
"hex number
syn match	cNumber		display contained "0x\x\+\(u\=l\{0,2}\|ll\=u\)\>"
syn match	cFloat		display contained "\d\+f"
"floating point number, with dot, optional exponent
syn match	cFloat		display contained "\d\+\.\d*\(e[-+]\=\d\+\)\=[fl]\="
"floating point number, starting with a dot, optional exponent
syn match	cFloat		display contained "\.\d\+\(e[-+]\=\d\+\)\=[fl]\=\>"
"floating point number, without dot, with exponent
syn match	cFloat		display contained "\d\+e[-+]\=\d\+[fl]\=\>"
if !exists("c_no_c99")
  "hexadecimal floating point number, optional leading digits, with dot, with exponent
  syn match	cFloat		display contained "0x\x*\.\x\+p[-+]\=\d\+[fl]\=\>"
  "hexadecimal floating point number, with leading digits, optional dot, with exponent
  syn match	cFloat		display contained "0x\x\+\.\=p[-+]\=\d\+[fl]\=\>"
endif

syn case match

if exists("c_comment_strings")
  " A comment can contain cString, cCharacter and cNumber.
  " But a "*/" inside a cString in a cComment DOES end the comment!  So we
  " need to use a special type of cString: cCommentString, which also ends on
  " "*/", and sees a "*" at the start of the line as comment again.
  " Unfortunately this doesn't very well work for // type of comments :-(
  syntax match	cCommentSkip	contained "^\s*\*\($\|\s\+\)"
  syntax region cCommentString	contained start=+L\=\\\@<!"+ skip=+\\\\\|\\"+ end=+"+ end=+\*/+me=s-1 contains=cSpecial,cCommentSkip
  syntax region cComment2String	contained start=+L\=\\\@<!"+ skip=+\\\\\|\\"+ end=+"+ end="$" contains=cSpecial
  syntax region  cCommentL	start="//" skip="\\$" end="$" keepend contains=@cCommentGroup,cComment2String,cCharacter,cNumbersCom,cSpaceError,@Spell
  if exists("c_no_comment_fold")
    " Use "extend" here to have preprocessor lines not terminate halfway a
    " comment.
    syntax region cComment	matchgroup=cCommentStart start="/\*" end="\*/" contains=@cCommentGroup,cCommentStartError,cCommentString,cCharacter,cNumbersCom,cSpaceError,@Spell extend
  else
    syntax region cComment	matchgroup=cCommentStart start="/\*" end="\*/" contains=@cCommentGroup,cCommentStartError,cCommentString,cCharacter,cNumbersCom,cSpaceError,@Spell fold extend
  endif
else
  syn region	cCommentL	start="//" skip="\\$" end="$" keepend contains=@cCommentGroup,cSpaceError,@Spell
  if exists("c_no_comment_fold")
    syn region	cComment	matchgroup=cCommentStart start="/\*" end="\*/" contains=@cCommentGroup,cCommentStartError,cSpaceError,@Spell
  else
    syn region	cComment	matchgroup=cCommentStart start="/\*" end="\*/" contains=@cCommentGroup,cCommentStartError,cSpaceError,@Spell fold
  endif
endif
" keep a // comment separately, it terminates a preproc. conditional
syntax match	cCommentError	display "\*/"
syntax match	cCommentStartError display "/\*"me=e-1 contained

syn keyword	cOperator	sizeof tagof state defined char

syn keyword	cTag 		any bool Fixed Float String Function functag funcenum

syn keyword	cStructure	enum
syn keyword	cStorageClass	static const stock native forward

" Constants
" ======
syn keyword 	cConstant 	cellbits cellmax cellmin charbits charmax charmin ucharmax __Pawn debug
syn keyword 	cConstant 	true false
"
" admin.inc
" ------
syn keyword 	cConstant 	Admin_Reservation Admin_Generic Admin_Kick Admin_Ban Admin_Unban Admin_Slay Admin_Changemap
syn keyword 	cConstant 	Admin_Convars Admin_Config Admin_Chat Admin_Vote Admin_Password Admin_RCON Admin_Cheats
syn keyword 	cConstant 	Admin_Root Admin_Custom1 Admin_Custom2 Admin_Custom3 Admin_Custom4 Admin_Custom5 Admin_Custom6

syn keyword 	cConstant 	ADMFLAG_RESERVATION ADMFLAG_GENERIC ADMFLAG_KICK ADMFLAG_BAN ADMFLAG_UNBAN ADMFLAG_SLAY
syn keyword 	cConstant 	ADMFLAG_CHANGEMAP ADMFLAG_CONVARS ADMFLAG_CONFIG ADMFLAG_CHAT ADMFLAG_VOTE ADMFLAG_PASSWORD
syn keyword 	cConstant 	ADMFLAG_RCON ADMFLAG_CHEATS ADMFLAG_ROOT ADMFLAG_CUSTOM1 ADMFLAG_CUSTOM2 ADMFLAG_CUSTOM3
syn keyword 	cConstant 	ADMFLAG_CUSTOM4 ADMFLAG_CUSTOM5 ADMFLAG_CUSTOM6 AUTHMETHOD_STEAM AUTHMETHOD_IP AUTHMETHOD_NAME
syn keyword 	cConstant 	AdminFlags_TOTAL INVALID_GROUP_ID INVALID_ADMIN_ID
syn keyword 	cConstant 	Override_Command Override_CommandGroup Command_Deny Command_Allow Immunity_Default Immunity_Global
syn keyword 	cConstant 	Access_Real Access_Effective AdminCache_Overrides AdminCache_Groups AdminCache_Admins
"
" commandfilters.inc
" ------
syn keyword 	cConstant 	MAX_TARGET_LENGTH COMMAND_FILTER_ALIVE COMMAND_FILTER_DEAD COMMAND_FILTER_CONNECTED
syn keyword 	cConstant 	COMMAND_FILTER_NO_IMMUNITY COMMAND_FILTER_NO_MULTI COMMAND_FILTER_NO_BOTS
syn keyword 	cConstant 	COMMAND_TARGET_NONE COMMAND_TARGET_NOT_ALIVE COMMAND_TARGET_NOT_DEAD
syn keyword 	cConstant 	COMMAND_TARGET_NOT_IN_GAME COMMAND_TARGET_IMMUNE COMMAND_TARGET_EMPTY_FILTER
syn keyword 	cConstant 	COMMAND_TARGET_NOT_HUMAN COMMAND_TARGET_AMBIGUOUS
"
" console.inc
" ------
syn keyword 	cConstant 	FCVAR_NONE FCVAR_UNREGISTERED FCVAR_LAUNCHER FCVAR_GAMEDLL FCVAR_CLIENTDLL FCVAR_MATERIAL_SYSTEM
syn keyword 	cConstant 	FCVAR_PROTECTED FCVAR_SPONLY FCVAR_ARCHIVE FCVAR_NOTIFY FCVAR_USERINFO FCVAR_PRINTABLEONLY
syn keyword 	cConstant 	FCVAR_UNLOGGED FCVAR_NEVER_AS_STRING FCVAR_REPLICATED FCVAR_CHEAT FCVAR_STUDIORENDER FCVAR_DEMO
syn keyword 	cConstant 	FCVAR_DONTRECORD FCVAR_PLUGIN FCVAR_DATACACHE FCVAR_TOOLSYSTEM FCVAR_FILESYSTEM FCVAR_NOT_CONNECTED
syn keyword 	cConstant 	FCVAR_SOUNDSYSTEM FCVAR_ARCHIVE_XBOX FCVAR_INPUTSYSTEM FCVAR_NETWORKSYSTEM FCVAR_VPHYSICS
syn keyword 	cConstant 	INVALID_FCVAR_FLAGS QUERYCOOKIE_FAILED SM_REPLY_TO_CONSOLE SM_REPLY_TO_CHAT
syn keyword 	cConstant 	ConVarBound_Upper ConVarBound_Lower ConVarQuery_Okay ConVarQuery_NotFound
syn keyword 	cConstant 	ConVarQuery_NotValid ConVarQuery_Protected
"
" core.inc
" ------
syn keyword 	cConstant 	__version Plugin_Continue Plugin_Handled Plugin_Stop Plugin_Changed
syn keyword 	cConstant 	Plugin_Running Plugin_Paused Plugin_Error Plugin_Loaded Plugin_Failed
syn keyword 	cConstant 	Plugin_Created Plugin_Uncompiled Plugin_BadLoad PlInfo_Name PlInfo_Author
syn keyword 	cConstant 	PlInfo_Description PlInfo_Version PlInfo_URL Identity_Core Identity_Extension Identity_Plugin
syn keyword 	cConstant 	NULL_VECTOR NULL_STRING INVALID_FUNCTION SOURCEMOD_VERSION SOURCEMOD_PLUGINAPI_VERSION
"
" cstrike.inc
" ------
"
syn keyword 	cConstant	CS_TEAM_NONE CS_TEAM_SPECTATOR CS_TEAM_T CS_TEAM_CT CS_SLOT_PRIMARY	
syn keyword 	cConstant	CS_SLOT_SECONDARY CS_SLOT_GRENADE CS_SLOT_C4
" files.inc
" ------
syn keyword 	cConstant 	FileType_Unknown FileType_Directory FileType_File
syn keyword 	cConstant 	PLATFORM_MAX_PATH SEEK_SET SEEK_CUR SEEK_END Path_SM
"
" float.inc
" ------
syn keyword 	cConstant 	floatround_round floatround_floor floatround_ceil floatround_tozero FLOAT_PI
"
" handles.inc
" ------
syn keyword 	cConstant 	INVALID_HANDLE
"
" sourcemod.inc
" ------
syn keyword 	cConstant 	myinfo
syn keyword 	cConstant 	MAPLIST_FLAG_MAPSFOLDER MAPLIST_FLAG_CLEARARRAY MAPLIST_FLAG_NO_DEFAULT
"
" client.inc
" ------
syn keyword 	cConstant 	NetFlow_Outgoing NetFlow_Incoming NetFlow_Both
syn keyword 	cConstant 	MAXPLAYERS MAX_NAME_LENGTH
"
" dbi.inc
" ------
syn keyword 	cConstant 	DBVal_Error DBVal_TypeMismatch DBVal_Null DBVal_Data DBBind_Int
syn keyword 	cConstant 	DBBind_Float DBBind_String DBPrio_High DBPrio_Normal DBPrio_Low
"
" textparse.inc
" ------
syn keyword 	cConstant 	SMCParse_Continue SMCParse_Halt SMCParse_HaltFail
syn keyword 	cConstant 	SMCError_Okay SMCError_StreamOpen SMCError_StreamError SMCError_Custom SMCError_InvalidSection1
syn keyword 	cConstant 	SMCError_InvalidSection2 SMCError_InvalidSection3 SMCError_InvalidSection4 SMCError_InvalidSection5
syn keyword 	cConstant 	SMCError_InvalidTokens SMCError_TokenOverflow SMCError_InvalidProperty1

" Natives and Stocks
" ======
"
" admin.inc
" ------
syn keyword 	cFunction 	AddCommandOverride GetCommandOverride UnsetCommandOverride CreateAdmGroup DumpAdminCache FindAdmGroup
syn keyword 	cFunction 	SetAdmGroupAddFlag GetAdmGroupAddFlag GetAdmGroupAddFlags SetAdmGroupImmunity GetAdmGroupImmunity
syn keyword 	cFunction 	SetAdmGroupImmuneFrom GetAdmGroupImmuneFrom GetAdmGroupImmuneCount AddAdmGroupCmdOverride
syn keyword 	cFunction 	GetAdmGroupCmdOverride RegisterAuthIdentType CreateAdmin GetAdminUsername BindAdminIdentity
syn keyword 	cFunction 	SetAdminFlag GetAdminFlag GetAdminFlags AdminInheritGroup GetAdminGroupCount GetAdminGroup
syn keyword 	cFunction 	SetAdminPassword GetAdminPassword FindAdminByIdentity RemoveAdmin FlagBitsToBitArray FlagBitArrayToBits
syn keyword 	cFunction 	FlagArrayToBits FlagBitsToArray FlagToBit BitToFlag
syn keyword 	cFunction 	FindFlagByName FindFlagByChar ReadFlagString CanAdminTarget
syn keyword 	cFunction 	CreateAuthMethod SetAdmGroupImmunityLevel GetAdmGroupImmunityLevel
syn keyword 	cFunction 	SetAdminImmunityLevel GetAdminImmunityLevel
"
" adminmenu.inc
" ------
syn keyword 	cFunction 	GetAdminTopMenu AddTargetsToMenu AddTargetsToMenu2 RedisplayAdminMenu
"
" adt_array.inc
" ------
syn keyword 	cFunction 	ByteCountToCells CreateArray ClearArray CloneArray ResizeArray GetArraySize
syn keyword 	cFunction 	PushArrayCell PushArrayString PushArrayArray GetArrayCell GetArrayString
syn keyword 	cFunction 	GetArrayArray SetArrayCell SetArrayString SetArrayArray ShiftArrayUp
syn keyword 	cFunction 	RemoveFromArray SwapArrayItems FindStringInArray FindValueInArray
"
" adt_trie.inc
" ------
syn keyword 	cFunction 	CreateTrie SetTrieValue SetTrieArray SetTrieString GetTrieValue
syn keyword 	cFunction 	GetTrieArray GetTrieString RemoveFromTrie ClearTrie GetTrieSize
"
" banning.inc
" ------
syn keyword 	cFunction 	BanClient BanIdentity RemoveBan
"
" bitbuffer.inc
" ------
syn keyword 	cFunction 	BfWriteBool BfWriteByte BfWriteChar BfWriteShort BfWriteWord BfWriteNum
syn keyword 	cFunction 	BfWriteFloat BfWriteString BfWriteEntity BfWriteAngle BfWriteCoord BfWriteVecCoord
syn keyword 	cFunction 	BfWriteVecNormal BfWriteAngles BfGetNumBytesLeft
syn keyword 	cFunction 	BfReadBool BfReadByte BfReadChar BfReadShort BfReadWord BfReadNum
syn keyword 	cFunction 	BfReadFloat BfReadString BfReadEntity BfReadAngle BfReadCoord BfReadVecCoord
syn keyword 	cFunction 	BfReadVecNormal BfReadAngles
"
" client.inc
" ------
syn keyword 	cFunction 	GetMaxClients GetClientCount GetClientName GetClientIP GetClientAuthString GetClientUserId
syn keyword 	cFunction 	GetUserAdmin AddUserFlags RemoveUserFlags SetUserFlagBits GetUserFlagBits
syn keyword 	cFunction 	IsClientConnected IsClientInGame IsClientAuthorized IsFakeClient GetClientInfo SetUserAdmin
syn keyword 	cFunction 	IsClientInKickQueue IsClientObserver IsPlayerAlive GetClientTeam
syn keyword 	cFunction 	CanUserTarget RunAdminCacheChecks NotifyPostAdminCheck CreateFakeClient
syn keyword 	cFunction 	SetFakeClientConVar GetClientHealth GetClientModel GetClientWeapon
syn keyword 	cFunction 	GetClientMaxs GetClientMins GetClientAbsAngles GetClientAbsOrigin
syn keyword 	cFunction 	GetClientArmor GetClientDeaths GetClientFrags GetClientDataRate
syn keyword 	cFunction 	IsClientTimingOut GetClientTime GetClientLatency GetClientAvgLatency
syn keyword 	cFunction 	GetClientAvgLoss GetClientAvgChoke GetClientAvgData GetClientAvgPackets
syn keyword 	cFunction 	GetClientOfUserId KickClient ChangeClientTeam
"
" commandfilters.inc
" ------
syn keyword 	cFunction 	ProcessTargetString ReplyToTargetError
"
" console.inc
" ------
syn keyword 	cFunction 	PrintToServer PrintToConsole CreateConVar FindConVar HookConVarChange UnhookConVarChange GetConVarBool
syn keyword 	cFunction 	SetConVarBool GetConVarInt SetConVarInt GetConVarFloat SetConVarFloat GetConVarString SetConVarString
syn keyword 	cFunction 	GetConVarFlags SetConVarFlags GetConVarName GetConVarMin GetConVarMax ResetConVar
syn keyword 	cFunction 	ServerCommand InsertServerCommand ServerExecute ClientCommand
syn keyword 	cFunction 	FakeClientCommand FakeClientCommandEx ReplyToCommand GetCmdReplySource
syn keyword 	cFunction 	SetCmdReplySource IsChatTrigger ShowActivity ShowActivity2 ShowActivityEx
syn keyword 	cFunction 	RegServerCmd RegConsoleCmd RegAdminCmd GetCmdArgs GetCmdArg GetCmdArgString
syn keyword 	cFunction 	GetConVarBounds SetConVarBounds QueryClientConVar GetCommandIterator
syn keyword 	cFunction 	ReadCommandIterator CheckCommandAccess IsValidConVarChar GetCommandFlags
syn keyword 	cFunction 	SetCommandFlags FindFirstConCommand FindNextConCommand SendConVarValue
"
" cstrike.inc
" ------
syn keyword 	cFunction 	CS_RespawnPlayer CS_SwitchTeam
"
" datapack.inc
" ------
syn keyword 	cFunction 	CreateDataPack WritePackCell WritePackFloat WritePackString ReadPackCell ReadPackFloat ReadPackString
syn keyword 	cFunction 	ResetPack GetPackPosition SetPackPosition IsPackReadable
"
" dbi.inc
" ------
syn keyword 	cFunction 	SQL_Connect SQL_DefConnect SQL_ConnectEx SQL_CheckConfig SQL_GetDriver
syn keyword 	cFunction 	SQL_ReadDriver SQL_GetDriverIdent SQL_GetDriverProduct SQL_GetAffectedRows
syn keyword 	cFunction 	SQL_GetInsertId SQL_GetError SQL_EscapeString SQL_QuoteString
syn keyword 	cFunction 	SQL_FastQuery SQL_Query SQL_PrepareQuery SQL_FetchMoreResults
syn keyword 	cFunction 	SQL_HasResultSet SQL_GetRowCount SQL_GetFieldCount SQL_FieldNumToName
syn keyword 	cFunction 	SQL_FieldNameToNum SQL_FetchRow SQL_MoreRows SQL_Rewind SQL_FetchString
syn keyword 	cFunction 	SQL_FetchFloat SQL_FetchInt SQL_IsFieldNull SQL_FetchSize SQL_BindParamInt
syn keyword 	cFunction 	SQL_BindParamFloat SQL_BindParamString SQL_Execute SQL_LockDatabase
syn keyword 	cFunction 	SQL_UnlockDatabase SQL_IsSameConnection SQL_TConnect SQL_TQuery
"
" files.inc
" ------
syn keyword 	cFunction 	BuildPath OpenDirectory ReadDirEntry OpenFile DeleteFile ReadFileLine IsEndOfFile FileSeek
syn keyword 	cFunction 	FilePosition FileExists RenameFile DirExists FileSize RemoveDir WriteFileLine
"
" float.inc
" ------
syn keyword 	cFunction 	float FloatStr FloatFraction FloatRound SquareRoot Pow Exponential Logarithm Sine
syn keyword 	cFunction 	Cosine Tangent FloatAbs ArcTangent ArcCosine ArcSine ArcTangent2 DegToRad RadToDeg
"
" handles.inc
" ------
syn keyword 	cFunction 	IsValidHandle CloseHandle CloneHandle
"
" helpers.inc
" ------
syn keyword 	cFunction 	FormatUserLogText
"
" geoip.inc
" ------
syn keyword 	cFunction 	GeoipCode2 GeoipCode3 GeoipCountry
"
" lang.inc
" ------
syn keyword 	cFunction 	LoadTranslations
"
" sourcemod.inc
" ------
syn keyword 	cFunction 	GetMyHandle GetPluginIterator MorePlugins ReadPlugin GetPlugin GetPluginFilename
syn keyword 	cFunction 	IsPluginDebugging GetPluginInfo FindPluginByNumber GameConfGetOffset GameConfGetKeyValue
syn keyword 	cFunction 	GetTime FormatTime LoadGameConfigFile GetSysTickCount AutoExecConfig MarkNativeAsOptional
syn keyword 	cFunction 	RegPluginLibrary LibraryExists GetExtensionFileStatus ReadMapList SetMapListCompatBind
syn keyword 	cFunction 	SetFailState ThrowError
"
" logging.inc
" ------
syn keyword 	cFunction 	LogToGame LogMessage LogMessageEx LogError LogAction LogToFile LogToFileEx AddGameLogHook RemoveGameLogHook
"
" string.inc
" ------
syn keyword 	cFunction 	strlen StrContains StrCompare StrEqual StrCopy Format FormatEx VFormat StringToInt
syn keyword 	cFunction 	IntToString StringToFloat FloatToString
"
" textparse.inc
" ------
syn keyword 	cFunction 	SMC_CreateParser SMC_ParseFile SMC_GetErrorString SMC_SetParseStart
syn keyword 	cFunction 	SMC_SetParseEnd SMC_SetReaders SMC_SetRawLine


" Forwards
" ======
"
" admin.inc
" ------
syn keyword 	cForward  	OnRebuildAdminCache
"
" adminmenu.inc
" ------
syn keyword 	cForward  	OnAdminMenuCreated OnAdminMenuReady
"
" banning.inc
" ------
syn keyword 	cForward  	OnBanClient OnBanIdentity OnRemoveBan
"
" sourcemod.inc
" ------
syn keyword 	cForward  	OnPluginStart AskPluginLoad OnPluginEnd OnPluginPauseChange OnClientConnect
syn keyword 	cForward  	OnConfigsExecuted OnAllPluginsLoaded OnLibraryAdded OnLibraryRemoved
syn keyword 	cForward  	OnGameFrame OnMapStart OnMapEnd OnClientFloodCheck OnClientFloodResult
"
" client.inc
" ------
syn keyword 	cForward  	OnClientPutInServer OnClientDisconnect OnClientDisconnect_Post OnClientCommand
syn keyword 	cForward  	OnClientSettingsChanged OnClientAuthorized OnClientPreAdminCheck OnClientPostAdminFilter OnClientPostAdminCheck
"
" logging.inc
" ------
syn keyword 	cForward  	OnLogAction
"
" console.inc
" ------
syn keyword	cForward 	OnConVarChanged
"
" Tags/types
" ======
"
" logging.inc
" ------
syn keyword	cTag 		GameLogHook
"
" admin.inc
" ------
syn keyword	cTag 		AdminFlag OverrideType OverrideRule ImmunityType
syn keyword	cTag 		GroupId AdminId AdmAccessMode AdminCachePart
"
" console.inc
" ------
syn keyword	cTag 		ConVarBounds QueryCookie ReplySource ConVarQueryResult
syn keyword	cTag 		ConVarQueryFinished ConVarChanged ConCmd SrvCmd
"
" core.inc
" ------
syn keyword	cTag 		Extension Result PlVers Action Identity PluginStatus PluginInfo SharedPlugin
"
" dbi.inc
" ------
syn keyword	cTag 		DBResult DBBindType DBPriority SQLTCallback
"
" files.inc
" ------
syn keyword	cTag 		FileType PathType
"
" float.inc
" ------
syn keyword	cTag 		floatround_method
"
" handles.inc
" ------
syn keyword	cTag 		Handle
"
" sourcemod.inc
" ------
syn keyword	cTag 		Plugin
"
" client.inc
" ------
syn keyword	cTag 		NetFlow
"
" textparse.inc
" ------
syn keyword	cTag 		SMCResult SMCError SMC_ParseStart SMC_ParseEnd
syn keyword	cTag 		SMC_NewSection SMC_KeyValue SMC_EndSection SMC_RawLine


" Accept %: for # (C99)
syn region	cPreCondit	start="^\s*\(%:\|#\)\s*\(if\|ifdef\|ifndef\|elif\)\>" skip="\\$" end="$" end="//"me=s-1 contains=cComment,cCppString,cCharacter,cCppParen,cParenError,cNumbers,cCommentError,cSpaceError
syn match	cPreCondit	display "^\s*\(%:\|#\)\s*\(else\|endif\)\>"
if !exists("c_no_if0")
  if !exists("c_no_if0_fold")
    syn region	cCppOut		start="^\s*\(%:\|#\)\s*if\s\+0\+\>" end=".\@=\|$" contains=cCppOut2 fold
  else
    syn region	cCppOut		start="^\s*\(%:\|#\)\s*if\s\+0\+\>" end=".\@=\|$" contains=cCppOut2
  endif
  syn region	cCppOut2	contained start="0" end="^\s*\(%:\|#\)\s*\(endif\>\|else\>\|elif\>\)" contains=cSpaceError,cCppSkip
  syn region	cCppSkip	contained start="^\s*\(%:\|#\)\s*\(if\>\|ifdef\>\|ifndef\>\)" skip="\\$" end="^\s*\(%:\|#\)\s*endif\>" contains=cSpaceError,cCppSkip
endif
syn region	cIncluded	display contained start=+"+ skip=+\\\\\|\\"+ end=+"+
syn match	cIncluded	display contained "<[^>]*>"
syn match	cInclude	display "^\s*\(%:\|#\)\s*\(include\>\|tryinclude\>\)\s*["<]" contains=cIncluded
"syn match cLineSkip	"\\$"
syn cluster	cPreProcGroup	contains=cPreCondit,cIncluded,cInclude,cDefine,cErrInParen,cErrInBracket,cUserLabel,cSpecial,cOctalZero,cCppOut,cCppOut2,cCppSkip,cFormat,cNumber,cFloat,cOctal,cOctalError,cNumbersCom,cString,cCommentSkip,cCommentString,cComment2String,@cCommentGroup,cCommentStartError,cParen,cBracket,cMulti
syn region	cDefine		start="^\s*\(%:\|#\)\s*\(define\|undef\)\>" skip="\\$" end="$" end="//"me=s-1 keepend contains=ALLBUT,@cPreProcGroup,@Spell
syn region	cPreProc	start="^\s*\(%:\|#\)\s*\(assert\>\|emit\>\|endinput\>\|endscript\>\|pragma\>\|line\>\|section\>\|warning\>\|warn\>\|error\>\)" skip="\\$" end="$" keepend contains=ALLBUT,@cPreProcGroup,@Spell

" Highlight User Labels
syn cluster	cMultiGroup	contains=cIncluded,cSpecial,cCommentSkip,cCommentString,cComment2String,@cCommentGroup,cCommentStartError,cUserCont,cUserLabel,cCppOut,cCppOut2,cCppSkip,cFormat,cNumber,cFloat,cNumbersCom,cCppParen,cCppBracket,cCppString
syn region	cMulti		transparent start='?' skip='::' end=':' contains=ALLBUT,@cMultiGroup,@Spell
" Avoid matching foo::bar() in C++ by requiring that the next char is not ':'
syn cluster	cLabelGroup	contains=cUserLabel
syn match	cUserCont	display "^\s*\I\i*\s*:$" contains=@cLabelGroup
syn match	cUserCont	display ";\s*\I\i*\s*:$" contains=@cLabelGroup
syn match	cUserCont	display "^\s*\I\i*\s*:[^:]"me=e-1 contains=@cLabelGroup
syn match	cUserCont	display ";\s*\I\i*\s*:[^:]"me=e-1 contains=@cLabelGroup

syn match	cUserLabel	display "\I\i*" contained

" C++ extentions
syn keyword cppStatement	new decl
syn keyword cppAccess		public
syn keyword cppOperator		operator

if exists("c_minlines")
  let b:c_minlines = c_minlines
else
  if !exists("c_no_if0")
    let b:c_minlines = 50	" #if 0 constructs can be long
  else
    let b:c_minlines = 15	" mostly for () constructs
  endif
endif
exec "syn sync ccomment cComment minlines=" . b:c_minlines

" Define the default highlighting.
" Only used when an item doesn't have highlighting yet
hi def link cFormat		cSpecial
hi def link cCppString		cString
hi def link cCommentL		cComment
hi def link cCommentStart	cComment
hi def link cLabel		Label
hi def link cUserLabel		Label
hi def link cConditional	Conditional
hi def link cRepeat		Repeat
hi def link cCharacter		Character
hi def link cSpecialCharacter	cSpecial
hi def link cNumber		Number
hi def link cFloat		Float
hi def link cParenError		cError
hi def link cErrInParen		cError
hi def link cErrInBracket	cError
hi def link cCommentError	cError
hi def link cCommentStartError	cError
hi def link cSpaceError		cError
hi def link cSpecialError	cError
hi def link cOperator		Operator
hi def link cStructure		Structure
hi def link cStorageClass	StorageClass
hi def link cInclude		Include
hi def link cPreProc		PreProc
hi def link cDefine		Macro
hi def link cIncluded		cString
hi def link cError		Error
hi def link cStatement		Statement
hi def link cPreCondit		PreCondit
hi def link cTag 		Type
hi def link cConstant		Constant
hi def link cCommentString	cString
hi def link cComment2String	cString
hi def link cCommentSkip	cComment
hi def link cString		String
hi def link cComment		Comment
hi def link cSpecial		SpecialChar
hi def link cTodo		Todo
hi def link cCppSkip		cCppOut
hi def link cCppOut2		cCppOut
hi def link cCppOut		Comment

hi def link cppAccess		cppStatement
hi def link cppOperator		Operator
hi def link cppStatement	Statement

hi def link cFunction   	Function
hi def link cForward    	Function

let b:current_syntax = "sourcepawn"

" vim: ts=8
