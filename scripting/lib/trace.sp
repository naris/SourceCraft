/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: trace.sp
 * Description: Function library to trace execution.
 * Author(s): Naris (Murray Wilson)
 */

#pragma semicolon 1

new Handle:gTraceVar = INVALID_HANDLE;
new Handle:gTraceDepthVar = INVALID_HANDLE;
new Handle:gTraceIndentVar = INVALID_HANDLE;
new Handle:gTraceVerbosityVar = INVALID_HANDLE;
new Handle:gTraceCallLevelVar = INVALID_HANDLE;
new Handle:gTraceClassExVar = INVALID_HANDLE;
new Handle:gTraceClassVar = INVALID_HANDLE;
new Handle:gTraceCatExVar = INVALID_HANDLE;
new Handle:gTraceCatVar = INVALID_HANDLE;
new Handle:gCallStack = INVALID_HANDLE;

new String:gCategory[256] = "";

new String:gTraceCat[1024] = "";
new String:gExcludeCat[1024] = "";

new String:gTraceClass[1024] = "";
new String:gExcludeClass[1024] = "";

new gMaxDepth = 25;
new gVerbosity = 10;
new gCallLevel = 9;
new bool:gEnable = false;
new bool:gIndent = true;
new bool:gConfigLoaded = false;

new gCurrentDepth = 0;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("TraceInto",Native_TraceInto);
    CreateNative("TraceReturn",Native_TraceReturn);
    CreateNative("TraceMessage",Native_TraceMessage);
    CreateNative("TraceDump",Native_TraceDump);
    CreateNative("GetTraceCategory",Native_GetCategory);
    CreateNative("SetTraceCategory",Native_SetCategory);
    CreateNative("ResetTraceCategory",Native_ResetCategory);
    CreateNative("GetTraceMethod",Native_GetTraceMethod);

    RegPluginLibrary("trace");

    gConfigLoaded = LoadConfigFile();

    return APLRes_Success;
}

public OnPluginStart()
{
    decl String:buf[16];
    IntToString(gEnable, buf, sizeof(buf));
    gTraceVar           = CreateConVar("sm_trace", buf, "Enable Tracing");

    IntToString(gMaxDepth, buf, sizeof(buf));
    gTraceDepthVar      = CreateConVar("sm_trace_depth", buf, "Maximum call depth to trace");

    IntToString(gIndent, buf, sizeof(buf));
    gTraceIndentVar    = CreateConVar("sm_trace_indent", buf, "Set to true to indent based on call depth ");

    IntToString(gVerbosity, buf, sizeof(buf));
    gTraceVerbosityVar  = CreateConVar("sm_trace_verbosity", buf, "Maximum verbosity level to log");

    IntToString(gCallLevel, buf, sizeof(buf));
    gTraceCallLevelVar  = CreateConVar("sm_trace_call_level", buf, "Verbosity level to use for TraceInto/TraceReturn");

    gTraceCatVar        = CreateConVar("sm_trace_cat", gTraceCat, "List of categories to trace (null string, the default, traces all categories)");
    gTraceCatExVar      = CreateConVar("sm_trace_cat_exclude", gExcludeCat, "List of categories to exclude (null string, the default, excludes no categories)");
    gTraceClassVar      = CreateConVar("sm_trace_class", gTraceClass, "List of classes to trace (null string, the default, traces all classes)");
    gTraceClassExVar    = CreateConVar("sm_trace_class_exclude", gExcludeClass, "List of classes to exclude (null string, the default, excludes no classes)");

    HookConVarChange(gTraceVar, CvarChange);
    HookConVarChange(gTraceDepthVar, CvarChange);
    HookConVarChange(gTraceVerbosityVar, CvarChange);
    HookConVarChange(gTraceCallLevelVar, CvarChange);
    HookConVarChange(gTraceCatVar, CvarChange);
    HookConVarChange(gTraceCatExVar, CvarChange);
    HookConVarChange(gTraceClassVar, CvarChange);
    HookConVarChange(gTraceClassExVar, CvarChange);

    if (!gConfigLoaded) // !LoadConfigFile())
    {
        AutoExecConfig( true, "trace");
    }
}

public bool:LoadConfigFile()
{
    new bool:loaded = false;
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM,path,sizeof(path),"configs/trace.cfg");

    new Handle:traceConfigHandle = CreateKeyValues("trace");
    if (FileToKeyValues(traceConfigHandle,path))
    {
        // Load values
        gMaxDepth=KvGetNum(traceConfigHandle, "depth");
        gVerbosity=KvGetNum(traceConfigHandle, "verbosity");
        gCallLevel=KvGetNum(traceConfigHandle, "call_level");
        gIndent=bool:KvGetNum(traceConfigHandle, "indent");
        gEnable=bool:KvGetNum(traceConfigHandle, "enable");

        // Load category configuration
        KvRewind(traceConfigHandle);
        if (KvJumpToKey(traceConfigHandle,"category", false))
        {
            KvGetString(traceConfigHandle,"include",gTraceCat, sizeof(gTraceCat));
            KvGetString(traceConfigHandle,"exclude",gExcludeCat, sizeof(gExcludeCat));
        }

        // Load class configuration
        KvRewind(traceConfigHandle);
        if (KvJumpToKey(traceConfigHandle,"class", false))
        {
            KvGetString(traceConfigHandle,"include",gTraceClass, sizeof(gTraceClass));
            KvGetString(traceConfigHandle,"exclude",gExcludeClass, sizeof(gExcludeClass));
        }

        LogMessage("Loaded Trace categories: %s", gTraceCat);
        LogMessage("Loaded Exclude categories: %s", gExcludeCat);
        LogMessage("Loaded Trace classes: %s", gTraceClass);
        LogMessage("Loaded Exclude classes: %s", gExcludeClass);
        loaded = true;
    }
    
    CloseHandle(traceConfigHandle);
    return loaded;
}

public OnConfigsExecuted()
{
    gMaxDepth   = GetConVarInt(gTraceDepthVar);
    gVerbosity  = GetConVarInt(gTraceVerbosityVar);
    gCallLevel  = GetConVarInt(gTraceCallLevelVar);
    gIndent     = GetConVarBool(gTraceIndentVar);
    gEnable     = GetConVarBool(gTraceVar);

    GetConVarString(gTraceCatVar, gTraceCat, sizeof(gTraceCat));
    GetConVarString(gTraceCatExVar, gExcludeCat, sizeof(gExcludeCat));

    GetConVarString(gTraceClassVar, gTraceClass, sizeof(gTraceClass));
    GetConVarString(gTraceClassExVar, gExcludeClass, sizeof(gExcludeClass));

    /**/
    LogMessage("Config Trace categories: %s", gTraceCat);
    LogMessage("Config Exclude categories: %s", gExcludeCat);
    LogMessage("Config Trace classes: %s", gTraceClass);
    LogMessage("Config Exclude classes: %s", gExcludeClass);
    /**/
} 

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (convar == gTraceVar)
        gEnable = bool:StringToInt(newValue);
    else if (convar == gTraceIndentVar)
        gIndent = bool:StringToInt(newValue);
    else if (convar == gTraceDepthVar)
        gMaxDepth = StringToInt(newValue);
    else if (convar == gTraceVerbosityVar)
        gVerbosity = StringToInt(newValue);
    else if (convar == gTraceCallLevelVar)
        gCallLevel = StringToInt(newValue);
    else if (convar == gTraceCatVar)
    {
        strcopy(gTraceCat, sizeof(gTraceCat), newValue);
        LogMessage("Trace categories: %s", gTraceCat);
    }
    else if (convar == gTraceCatExVar)
    {
        strcopy(gExcludeCat, sizeof(gExcludeCat), newValue);
        LogMessage("Exclude categories: %s", gExcludeCat);
    }
    else if (convar == gTraceClassVar)
    {
        strcopy(gTraceClass, sizeof(gTraceClass), newValue);
        LogMessage("Trace classes: %s", gTraceClass);
    }
    else if (convar == gTraceClassExVar)
    {
        strcopy(gExcludeClass, sizeof(gExcludeClass), newValue);
        LogMessage("Exclude classes: %s", gExcludeClass);
    }
}

CheckCategory()
{
    //LogMessage("CheckCategory, category=%s, exclude=%s, trace=%s", gCategory, gExcludeCat, gTraceCat);
    if (gExcludeCat[0] == '\0' && gTraceCat[0] == '\0')
    {
        return 0;
    }
    else if (StrContains(gCategory, ",") < 0)
    {
        //LogMessage("CheckCategory, cont-excl=%d, cont-trace=%d", StrContains(gExcludeCat, gCategory, false), StrContains(gTraceCat, gCategory, false));
        if (gExcludeClass[0] == '\0' || StrContains(gExcludeCat, gCategory, false) < 0)
        {
            return -1;
        }
        else if (gTraceCat[0] == '\0' || StrContains(gTraceCat, gCategory, false) >= 0)
        {
            return 1;
        }
        else
        {
            return (gTraceCat[0] == '\0') ? 0 : -1;
        }
    }
    else
    {
        new idx, pos=0;
        new ok = (gTraceCat[0] == '\0') ? 0 : -1;
        decl String:aCategory[64];
        while ((idx = SplitString(gCategory[pos], ",", aCategory, sizeof(aCategory))) != -1)
        {
            pos += idx;
            //LogMessage("CheckCategory, cat=%s, cont-excl=%d, cont-trace=%d", aCategory, StrContains(gExcludeCat, aCategory, false), StrContains(gTraceCat, aCategory, false));
            if (gExcludeClass[0] != '\0' && StrContains(gExcludeCat, aCategory, false) < 0)
            {
                ok = -1;
                break;
            }
            else if (gTraceCat[0] != '\0' && StrContains(gTraceCat, aCategory, false) >= 0)
            {
                ok = 1;
            }
            else if (gCategory[pos] == '\0')
            {
                break;
            }
        }
        //LogMessage("CheckCategory=%d",ok);
        return ok;
    }
}

CheckClass(const String:class[])
{
    if (gExcludeClass[0] != '\0' && StrContains(gExcludeClass, class, false) < 0)
    {
        //LogMessage("CheckClass, class=%s, exclude=%s, trace=%s, cont-excl=%d, cont-trace=%d, return=-1",
        //            class, gExcludeClass, gTraceClass, StrContains(gExcludeClass, class, false), StrContains(gTraceClass, class, false));
        return -1;
    }
    else if (gTraceClass[0] != '\0' && StrContains(gTraceClass, class, false) >= 0)
    {
        //LogMessage("CheckClass, class=%s, exclude=%s, trace=%s, cont-excl=%d, cont-trace=%d, return=1",
        //            class, gExcludeClass, gTraceClass, StrContains(gExcludeClass, class, false), StrContains(gTraceClass, class, false));
        return 1;
    }
    else
    {
        return (gTraceClass[0] == '\0') ? 0 : -1;
    }
}

ExtractName(const String:prefix[], String:name[], maxlength)
{
    if (SplitString(prefix, "{", name, maxlength) < 0)
    {
        if (SplitString(prefix, " ", name, maxlength) < 0)
            strcopy(name, maxlength, prefix);
    }
}

CheckPrefix(const String:prefix[])
{
    if (gTraceClass[0] == '\0' && gExcludeClass[0] == '\0')
    {
        //LogMessage("CheckPrefix=0");
        return 0;
    }
    else
    {
        decl String:name[64];
        ExtractName(prefix, name, sizeof(name));

        decl String:class[64];
        if (SplitString(name, "::", class, sizeof(class)) >= 0)
        {
            //LogMessage("CheckPrefix=checkClass=%d",CheckClass(class));
            return CheckClass(class);
        }
        else
        {
            //LogMessage("CheckPrefix=%d",(gTraceClass[0] == '\0') ? 0 : -1);
            return (gTraceClass[0] == '\0') ? 0 : -1;
        }
    }
}

/**
 * Trace Into a Function and push it onto the trace stack
 * @param class: The name of the class/module tracing into.
 * @param method: The name of the method tracing into.
 * @param fmt: The format string for the message
 * @param ...: Format arguments (if any)
 * @noreturn
 * native TraceInto(const String:class[], const String:method[], const String:fmt[], any:...);
 */
public Native_TraceInto(Handle:plugin,numParams)
{
    if (gEnable)
    {
        gCurrentDepth++;

        decl String:indent[32];
        if (gIndent)
        {
            new i = 0;
            for (; i < gCurrentDepth && i < sizeof(indent)-1; i++)
                indent[i] = '-';

            indent[i] = '\0';
            if (i > 0)
                indent[i-1] = '>';
        }
        else
            Format(indent, sizeof(indent),"[%d] ", gCurrentDepth);

        decl String:class[64],String:method[64];
        GetNativeString(1,class,sizeof(class));
        GetNativeString(2,method,sizeof(method));

        decl String:prefix[256];
        if (gCategory[0] == '\0')
            Format(prefix, sizeof(prefix), "%s::%s %s", class, method, indent);
        else
            Format(prefix, sizeof(prefix), "%s::%s{%s} %s", class, method, gCategory, indent);

        if (gCallStack == INVALID_HANDLE)
            gCallStack = CreateArray(255);

        new size = GetArraySize(gCallStack);
        if (size > gMaxDepth && gMaxDepth > 0)
            SetArrayString(gCallStack, size-1, prefix);
        else
            PushArrayString(gCallStack, prefix);

        new checkOK = CheckCategory();
        if (checkOK > 0 || (checkOK == 0 && CheckClass(class) >= 0))
        {
            if (gCallLevel <= gVerbosity)
            {
                decl String:buffer[1024], written;
                if (numParams >= 3)
                {
                    FormatNativeString(0, /* Use an output buffer */
                                       3, /* Format param */
                                       4, /* Format argument #1 */
                                       sizeof(buffer), /* Size of output buffer */
                                       written, /* Store # of written bytes */
                                       buffer); /* Use our buffer */
                }
                else
                    written = 0;

                if (written == 0 && gCallLevel < gVerbosity)
                {
                    // Effectively check gCallLevel+1 to log an Entering message
                    strcopy(buffer, sizeof(buffer), "Entering...");
                    written = 11; // strlen(buffer);
                }

                if (written > 0)
                {
                    LogMessage("+%s%s", prefix, buffer);
                    PrintToServer("+%s%s", prefix, buffer);
                }
            }
        }
    }
}

/**
 * Trace Return (out of) a Function and pop it off the trace stack
 * @param fmt: The format string for the message
 * @param ...: Format arguments (if any)
 * @noreturn
 * native TraceReturn(const String:fmt[], any:...);
 */
public Native_TraceReturn(Handle:plugin,numParams)
{
    if (gEnable)
    {
        decl String:prefix[255];
        if (gCallStack == INVALID_HANDLE)
            prefix[0] = '\0';
        else
        {
            new last = GetArraySize(gCallStack)-1;
            if (last >= 0)
            {
                GetArrayString(gCallStack, last, prefix, sizeof(prefix));
                RemoveFromArray(gCallStack, last);
            }
            else
                prefix[0] = '\0';
        }

        new checkOK = CheckCategory();
        if (checkOK > 0 || (checkOK == 0 && CheckPrefix(prefix) >= 0))
        {
            if (gCallLevel <= gVerbosity)
            {
                decl String:buffer[1024], written;
                if (numParams >= 1)
                {
                  FormatNativeString(0, /* Use an output buffer */
                                     1, /* Format param */
                                     2, /* Format argument #1 */
                                     sizeof(buffer), /* Size of output buffer */
                                     written, /* Store # of written bytes */
                                     buffer); /* Use our buffer */
                }
                else
                    written = 0;

                if (written == 0 && gCallLevel < gVerbosity)
                {
                    // Effectively check gCallLevel+1 to log a Leaving message
                    strcopy(buffer, sizeof(buffer), "Leaving");
                    written = 7; // strlen(buffer);
                }

                if (written > 0)
                {
                    LogMessage("-%s%s", prefix, buffer);
                    PrintToServer("-%s%s", prefix, buffer);
                }
            }
        }

        if (gCurrentDepth > 0)
            gCurrentDepth--;
    }

    gCategory[0] = '\0';
}

/**
 * Trace (inside) a Function
 * @param verbosity: The verbosity of the message
 * @param fmt: The format string for the message
 * @param ...: Format arguments (if any)
 * @noreturn
 * native Trace(const String:fmt[], any:...);
 */
public Native_TraceMessage(Handle:plugin,numParams)
{
    if (gEnable)
    {
        if (GetNativeCell(1) <= gVerbosity)
        {
            decl String:prefix[255];
            if (gCallStack == INVALID_HANDLE)
                prefix[0] = '\0';
            else
            {   
                new last = GetArraySize(gCallStack)-1;
                if (last >= 0)
                    GetArrayString(gCallStack, last, prefix, sizeof(prefix));
                else
                    prefix[0] = '\0';
            }

            new checkOK = CheckCategory();
            if (checkOK > 0 || (checkOK == 0 && CheckPrefix(prefix) >= 0))
            {
                decl String:buffer[1024], written;
                if (numParams >= 1)
                {
                    FormatNativeString(0, /* Use an output buffer */
                                       2, /* Format param */
                                       3, /* Format argument #1 */
                                       sizeof(buffer), /* Size of output buffer */
                                       written, /* Store # of written bytes */
                                       buffer); /* Use our buffer */
                }
                else
                    written = 0;

                if (written > 0)
                {
                    LogMessage(" %s%s", prefix, buffer);
                    PrintToServer(" %s%s", prefix, buffer);
                }
            }
        }
    }
}

/**
 * Dump the Trace Stack
 * @param fmt: The format string for the message
 * @param ...: Format arguments (if any)
 * @noreturn
 * native TraceDump(const String:fmt[], any:...);
 */
public Native_TraceDump(Handle:plugin,numParams)
{
    if (gEnable)
    {
        new last;
        decl String:prefix[255];
        if (gCallStack == INVALID_HANDLE)
        {
            last = 0;
            prefix[0] = '\0';
        }
        else
        {
            last = GetArraySize(gCallStack)-1;
            if (last >= 0)
                GetArrayString(gCallStack, last, prefix, sizeof(prefix));
            else
            {
                last = 0;
                prefix[0] = '\0';
            }
        }

        new checkOK = CheckCategory();
        if (checkOK > 0 || (checkOK == 0 && CheckPrefix(prefix) >= 0))
        {
            decl String:buffer[1024], written;
            if (numParams >= 1)
            {
                FormatNativeString(0, /* Use an output buffer */
                                   1, /* Format param */
                                   2, /* Format argument #1 */
                                   sizeof(buffer), /* Size of output buffer */
                                   written, /* Store # of written bytes */
                                   buffer); /* Use our buffer */
            }
            else
                written = 0;

            if (written > 0)
            {
                LogMessage("*%s%s", prefix, buffer);
                PrintToServer("*%s%s", prefix, buffer);
            }

            decl String:name[64];
            while (last > 0)
            {
                ExtractName(prefix, name, sizeof(name));
                LogMessage("*%d %s", last, name);
                PrintToServer("*%d %s", last, name);
                if (--last >= 0)
                    GetArrayString(gCallStack, last, prefix, sizeof(prefix));
                else
                    break;
            }
        }
    }
}

/**
 * Sets the current category
 * @param category: String to place into the category.
 * @noreturn
 */
public Native_SetCategory(Handle:plugin,numParams)
{
    GetNativeString(1,gCategory,sizeof(gCategory));
}

/**
 * Resets the current category to nothing
 * @noreturn
 */
public Native_ResetCategory(Handle:plugin,numParams)
{
    gCategory[0] = '\0';
}

/**
 * Retrieves the current category
 * @param category: String to place the category into.
 * @param maxlength: The size of the category buffer.
 * @noreturn
 */
public Native_GetCategory(Handle:plugin,numParams)
{
    SetNativeString(1, gCategory, GetNativeCell(2));
}

/**
 * Retrieves the name of the current trace function
 * @param name: String to place the name into.
 * @param maxlength: The size of the name buffer.
 * @noreturn
 */
public Native_GetTraceMethod(Handle:plugin,numParams)
{
    if (gEnable)
    {
        if (gCallStack == INVALID_HANDLE)
            return;

        new last = GetArraySize(gCallStack)-1;
        if (last >= 0)
        {
            decl String:prefix[255];
            GetArrayString(gCallStack, last, prefix, sizeof(prefix));

            decl String:name[64];
            ExtractName(prefix, name, sizeof(name));

            new maxlength = GetNativeCell(2);
            SetNativeString(1, name, maxlength);
        }
    }
}
