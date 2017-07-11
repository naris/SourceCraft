/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: util.inc
 * Description: Utility functions and variables
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _util_included
 #endinput
#endif
#define _util_included

#include <gametype>

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04 // Actually red for DOD
#define COLOR_OLIVE 0x05
#define COLOR_YELLOW 0x06

/**
 * Replaces lowercase characters in a string with uppercase characters.
 *
 * @param text			String to modify (in place).
 * @param maxlength		Maximum length of the string buffer (0 to calculate using strlen().
 * @noreturn
 */
stock StringToLower(String:text[], maxlength=0)
{
    if (maxlength == 0)
        maxlength = strlen(text);
        
    for(new i = 0; i < maxlength; i++)
    {
        new chr = text[i];
        if (i == '\0')
            break;
        else if (IsCharUpper(chr))
            text[i] = (chr | (1<<5));
    }

}


#define USE_RESMANAGER
#if defined USE_RESMANAGER
#include <ResourceManager>
stock SetupPreloadTrie()
{
    // Replaced with the ResourceManager
}
#else

#define FORCE_PRECACHE false

new Handle:g_precacheTrie = INVALID_HANDLE;

stock SetupPreloadTrie()
{
    if (g_precacheTrie == INVALID_HANDLE)
        g_precacheTrie = CreateTrie();
    else
        ClearTrie(g_precacheTrie);
}

stock SetupSound(const String:sound[], bool:download,
                 bool:precache, bool:preload=false)
{
    if (download)
    {
        decl String:file[PLATFORM_MAX_PATH+1];
        Format(file, PLATFORM_MAX_PATH, "sound/%s", sound);

        if (FileExists(file))
            AddFileToDownloadsTable(file);
    }

    if (precache || FORCE_PRECACHE)
    {
        PrecacheSound(sound,preload);
        SetTrieValue(g_precacheTrie, sound, true);
    }
}

stock PrepareSound(const String:sound[], bool:preload=false)
{
    //if (!IsSoundPrecached(sound))
    new bool:value;
    if (!GetTrieValue(g_precacheTrie, sound, value))
    {
        PrecacheSound(sound,preload);
        SetTrieValue(g_precacheTrie, sound, true);
    }
}

stock SetupModel(const String:model[], &index, bool:download,
                 bool:precache, bool:preload=false)
{
    if (download && FileExists(model))
        AddFileToDownloadsTable(model);

    if (precache || FORCE_PRECACHE)
        index = PrecacheModel(model,preload);
    else
        index = 0;
}

stock PrepareModel(const String:model[], &index, bool:preload=false)
{
    if (index <= 0)
        index = PrecacheModel(model,preload);

    return index;
}
#endif
