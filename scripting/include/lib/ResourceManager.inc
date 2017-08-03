/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: ResourceManager.inc
 * Description: Plugin to manage precaching resources globally.
 * Author(s): Naris (Murray Wilson)
 */
 
#if defined _ResourceManager_included
 #endinput
#endif
#define _ResourceManager_included

#include <sdktools_sound>
#include <gametype>

#define AUTO_DOWNLOAD   -1
#define DONT_DOWNLOAD    0
#define DOWNLOAD         1
#define ALWAYS_DOWNLOAD  2

/**
 * Adds all the files in a directory to the Download Table
 *
 * @param directory		Name of the directory.
 * @param recursive		If true, descends child directories to recursively add all files therein.
 * @noreturn
 *
 */
stock AddFolderToDownloadTable(const String:directory[], bool:recursive=false)
{
#if defined REQUIRE_PLUGIN
	AddDirToDownloadTable(directory, recursive);
#else
	if (IsResourceManagerAvailable())
		AddDirToDownloadTable(directory, recursive);
#endif
}

native AddDirectoryToDownloadTable(const String:directory[], bool:recursive=false);

/**
 * Sets up a given model.
 *
 * @param model			Name of the model to precache.
 * @param index			Returns the model index (if precached).
 * @param download		If true the file will be added to the downloadables table.
 * @param precache		If true the file will be precached.
 * @param preload		If true the file will be precached before level startup.
 * @param files		    If set, it is a handle to an adt stack of strings
 *                      that list additional files to download (if any).
 * @return				Returns a model index (if precached).
 */
stock SetupModel(const String:model[], &index=0, bool:download=false,
				 bool:precache=false, bool:preload=false,
				 Handle:files=INVALID_HANDLE)
 {
#if defined REQUIRE_PLUGIN
		return PreSetupModel(model, index, download, precache, preload,files);
#else
	if (IsResourceManagerAvailable())
		return PreSetupModel(model, index, download, precache, preload,files);
	else
	{
		if (download && FileExists(model))
			AddFileToDownloadsTable(model);

		return (index = PrecacheModel(model, preload));
	}
#endif
 }

native PreSetupModel(const String:model[], &index=0, bool:download=false,
					 bool:precache=false, bool:preload=false,
					 Handle:files=INVALID_HANDLE);
					 
/**
 * Prepares a given model for use.
 *
 * @param decal			Name of the model to prepare.
 * @param index			Returns the model index.
 * @param preload		If preload is true the file will be precached before level startup (if required).
 * @return				Returns a model index.
 */
stock PrepareModel(const String:model[], &index=0, bool:preload=true)
{
#if defined REQUIRE_PLUGIN
	return PrepModel(model, index, preload);
#else
	return (IsResourceManagerAvailable())
			? PrepModel(model, index, preload)
			: (index = PrecacheModel(model, preload));
#endif
}

native PrepModel(const String:model[], &index=0, bool:preload=true);

/**
 * Sets up a given decal.
 *
 * @param decal			Name of the decal to precache.
 * @param index			Returns the decal index (if precached).
 * @param download		If download is true the file will be added to the downloadables table.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return				Returns a decal index (if precached).
 */
stock SetupDecal(const String:decal[], &index=0, bool:download=false,
                 bool:precache=false, bool:preload=false)
 {
#if defined REQUIRE_PLUGIN
	return PreSetupDecal(decal, index, download, precache, preload);
#else
	if (IsResourceManagerAvailable())
		return PreSetupDecal(decal, index, download, precache, preload);
	else
	{
		if (download && FileExists(decal))
			AddFileToDownloadsTable(decal);

		return (index = PrecacheDecal(decal, preload));
	}
#endif
 }

native PreSetupDecal(const String:decal[], &index=0, bool:download=false,
					 bool:precache=false, bool:preload=false);

/**
 * Prepares a given decal for use.
 *
 * @param decal			Name of the decal to prepare.
 * @param index			Returns the decal index.
 * @param preload		If preload is true the file will be precached before level startup (if required).
 * @return				Returns a decal index.
 */
stock PrepareDecal(const String:decal[], &index=0, bool:preload=true)
{
#if defined REQUIRE_PLUGIN
	return PrepDecal(decal, index, preload);
#else
	return (IsResourceManagerAvailable())
			? PrepDecal(decal, index, preload)
			: (index = PrecacheDecal(decal, preload));
#endif
}

native PrepDecal(const String:decal[], &index=0, bool:preload=true);

/**
 * Sets up a given sound.
 *
 * @param sound			Name of the sound to precache.
 * @param force		    If force is true the file will be precached even if the sound limit has been reached.
 * @param download		If download is 2 the file will be added to the downloadables table,
 *                      If download is 1 the file be added if it's within the allotted number of files.
 * @param precache		If precache is true the file will be precached immediately.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return				Returns true if successfully precached.
 */
stock bool:SetupSound(const String:sound[], bool:force=false, download=AUTO_DOWNLOAD,
                       bool:precache=false, bool:preload=false)
 {
#if defined REQUIRE_PLUGIN
	return PreSetupSound(sound, force=false, download, false, preload);
#else
	if (IsResourceManagerAvailable())
		return PreSetupSound(sound, force=false, download, false, preload);
	else
	{
		if (download != DONT_DOWNLOAD && FileExists(sound))
			AddFileToDownloadsTable(sound);

		index = PrecacheSound(sound,preload);
	}
#endif
 }

native bool:PreSetupSound(const String:sound[], bool:force=false, download=AUTO_DOWNLOAD,
						  bool:precache=false, bool:preload=false);

/**
 * Prepares a given sound for use.
 *
 * @param sound			Name of the sound to prepare.
 * @param force		    If force is true the file will be precached even if the sound limit has been reached.
 * @param preload		If preload is true the file will be precached before level startup (if required).
 * @return				Returns false if the sound limit has been reached.
 */
stock bool:PrepareSound(const String:sound[], bool:force=false, bool:preload=true)
{
#if defined REQUIRE_PLUGIN
	return PrepSound(sound, force, preload);
#else
	return (IsResourceManagerAvailable())
			? PrepSound(sound, force, preload)
			: (index = PrecacheSound(sound, preload));
#endif
}

native bool:PrepSound(const String:sound[], bool:force=false, bool:preload=true);

/**
 * Prepares and Emits an ambient sound.
 *
 * @param name		Sound file name relative to the "sounds" folder.
 * @param pos		Origin of sound.
 * @param entity	Entity index to associate sound with.
 * @param level		Sound level (from 0 to 255).
 * @param flags		Sound flags.
 * @param vol		Volume (from 0.0 to 1.0).
 * @param pitch		Pitch (from 0 to 255).
 * @param delay		Play delay.
 * @noreturn
 */
stock PrepareAndEmitAmbientSound(const String:name[],
                                 const Float:pos[3],
                                 entity = SOUND_FROM_WORLD,
                                 level = SNDLEVEL_NORMAL,
                                 flags = SND_NOFLAGS,
                                 Float:vol = SNDVOL_NORMAL,
                                 pitch = SNDPITCH_NORMAL,
                                 Float:delay = 0.0)
{
    if (GetGameType() == csgo)
    {
        for (new i=1; i<=MaxClients; i++)
        {
            if (IsClientInGame(i))
                ClientCommand(i, "playgamesound \"*%s\"", name);
        }
    }
    else
    {
#if defined REQUIRE_PLUGIN
        if (PrepareSound(name))
#else
        if (!IsResourceManagerAvailable() || PrepareSound(name))
#endif
        {
            EmitAmbientSound(name, pos, entity, level,
                             flags, vol, pitch, delay);
        }
    }
}

/**
 * Prepares and Emits a sound to a list of clients.
 *
 * @param clients		Array of client indexes.
 * @param numClients	Number of clients in the array.
 * @param sample		Sound file name relative to the "sounds" folder.
 * @param entity		Entity to emit from.
 * @param channel		Channel to emit with.
 * @param level			Sound level.
 * @param flags			Sound flags.
 * @param volume		Sound volume.
 * @param pitch			Sound pitch.
 * @param speakerentity	Unknown.
 * @param origin		Sound origin.
 * @param dir			Sound direction.
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for.
 * @noreturn
 * @error				Invalid client index.
 */
stock PrepareAndEmitSound(const clients[],
                          numClients,
                          const String:sample[],
                          entity = SOUND_FROM_PLAYER,
                          channel = SNDCHAN_AUTO,
                          level = SNDLEVEL_NORMAL,
                          flags = SND_NOFLAGS,
                          Float:volume = SNDVOL_NORMAL,
                          pitch = SNDPITCH_NORMAL,
                          speakerentity = -1,
                          const Float:origin[3] = NULL_VECTOR,
                          const Float:dir[3] = NULL_VECTOR,
                          bool:updatePos = true,
                          Float:soundtime = 0.0)
{
    if (GetGameType() == csgo)
    {
        for (new i=0; i<numClients; i++)
            ClientCommand(clients[i], "playgamesound \"*%s\"", sample);
    }
    else
    {
#if defined REQUIRE_PLUGIN
        if (PrepareSound(name))
#else
        if (!IsResourceManagerAvailable() || PrepareSound(name))
#endif
        {
            EmitSound(clients, numClients, sample, entity, channel,
                      level, flags, volume, pitch, speakerentity,
                      origin, dir, updatePos, soundtime);
        }
    }
}

/**
 * Wrapper to Prepare and emit sound to one client.
 *
 * @param client		Client index.
 * @param sample		Sound file name relative to the "sounds" folder.
 * @param entity		Entity to emit from.
 * @param channel		Channel to emit with.
 * @param level			Sound level.
 * @param flags			Sound flags.
 * @param volume		Sound volume.
 * @param pitch			Sound pitch.
 * @param speakerentity	Unknown.
 * @param origin		Sound origin.
 * @param dir			Sound direction.
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for.
 * @noreturn
 * @error				Invalid client index.
 */
stock PrepareAndEmitSoundToClient(client,
                                  const String:sample[],
                                  entity = SOUND_FROM_PLAYER,
                                  channel = SNDCHAN_AUTO,
                                  level = SNDLEVEL_NORMAL,
                                  flags = SND_NOFLAGS,
                                  Float:volume = SNDVOL_NORMAL,
                                  pitch = SNDPITCH_NORMAL,
                                  speakerentity = -1,
                                  const Float:origin[3] = NULL_VECTOR,
                                  const Float:dir[3] = NULL_VECTOR,
                                  bool:updatePos = true,
                                  Float:soundtime = 0.0)
{
    if (GetGameType() == csgo)
    {
        ClientCommand(client, "playgamesound \"*%s\"", sample);
    }
    else
    {
#if defined REQUIRE_PLUGIN
        if (PrepareSound(name))
#else
        if (!IsResourceManagerAvailable() || PrepareSound(name))
#endif
        {
            EmitSoundToClient(client, sample, entity, channel,
                              level, flags, volume, pitch, speakerentity,
                              origin, dir, updatePos, soundtime);
        }
    }
}

/**
 * Wrapper to Prepare and emit sound to all clients.
 *
 * @param sample		Sound file name relative to the "sounds" folder.
 * @param entity		Entity to emit from.
 * @param channel		Channel to emit with.
 * @param level			Sound level.
 * @param flags			Sound flags.
 * @param volume		Sound volume.
 * @param pitch			Sound pitch.
 * @param speakerentity	Unknown.
 * @param origin		Sound origin.
 * @param dir			Sound direction.
 * @param updatePos		Unknown (updates positions?)
 * @param soundtime		Alternate time to play sound for.
 * @noreturn
 * @error				Invalid client index.
 */
stock PrepareAndEmitSoundToAll(const String:sample[],
                               entity = SOUND_FROM_PLAYER,
                               channel = SNDCHAN_AUTO,
                               level = SNDLEVEL_NORMAL,
                               flags = SND_NOFLAGS,
                               Float:volume = SNDVOL_NORMAL,
                               pitch = SNDPITCH_NORMAL,
                               speakerentity = -1,
                               const Float:origin[3] = NULL_VECTOR,
                               const Float:dir[3] = NULL_VECTOR,
                               bool:updatePos = true,
                               Float:soundtime = 0.0)
{
    if (GetGameType() == csgo)
    {
        for (new i=1; i<=MaxClients; i++)
        {
            if (IsClientInGame(i))
                ClientCommand(i, "playgamesound \"*%s\"", sample);
        }
    }
    else
    {
#if defined REQUIRE_PLUGIN
        if (PrepareSound(name))
#else
        if (!IsResourceManagerAvailable() || PrepareSound(name))
#endif
        {
            EmitSoundToAll(sample, entity, channel,
                           level, flags, volume, pitch, speakerentity,
                           origin, dir, updatePos, soundtime);
        }
    }
}

#if !defined REQUIRE_PLUGIN
stock bool:m_ResourceManagerAvailable = false;

/**
 * Check if the plugin is available.
 *
 * @param	force	If true, sets the plugin is available flag
 * @return	Returns true if the plugin is available.
 */
stock bool:IsResourceManagerAvailable(bool:force=false)
{
    if (!m_ResourceManagerAvailable && (force || LibraryExists("ResourceManager")))
    {
        m_ResourceManagerAvailable = true;
    }
    return m_ResourceManagerAvailable;
}

/**
 * Function to call from OnLibraryAdded() to check the plugin name and set the flag.
 *
 * @param	name	the name parameter from the OnLibraryLoaded() call
 * @return	Returns true if name is for this plugin
 */
stock bool:WasResourceManagerAdded(const String:name[])
{
    if (StrEqual(name, "ResourceManager"))
	{
        m_ResourceManagerAvailable = true;
		return true;
	}
	else
		return false
}
#endif

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin:__pl_ResourceManager = 
{
	name = "ResourceManager",
	file = "ResourceManager.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_ResourceManager_SetNTVOptional()
{
	MarkNativeAsOptional("AddDirectoryToDownloadTable");
	MarkNativeAsOptional("PreSetupModel");
	MarkNativeAsOptional("PreSetupDecal");
	MarkNativeAsOptional("PreSetupSound");
	MarkNativeAsOptional("PrepModel");
	MarkNativeAsOptional("PrepDecal");
	MarkNativeAsOptional("PrepSound");
}
#endif
