/**
 * =============================================================================
 * War3Source Mana System (SourceMod Extension)
 * Copyright (C) 2012 DonRevan.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 
 /* Defines the current Interface version
  * History:
  * 1 = development version
  * 2 = public release
  * 3 = public version which had some improvements
  * 4 = reworked version
  */
 #define W3MANA_IFACE 4
 
 enum ManaType {
	iValue = 0, //Current amount of mana
	iRegen, //Amount of Mana regenerated per second
	iSpawnValue, //Amount of Mana which should be given on player spawn(gets added to MANA_ROUND if not respawned)
	iRoundValue, //Amount of Mana which should be given on round start
	iMaxCap, //Amount of Mana the client can carry
	szPrefix, //String which is pre-appended before the value (ex. Mana: 28 ..where mana is the prefix)
	bActive, //Pass true/false as 3. param and raceid as 4. param
	aColor //Color of the mana message which is shown onscreen(pass 4 cells r,g,b,a)
};
 
 /**
 * Changes the given value which is handled by the mana system
 *
 * NOTE: If you wan't to set:
 * bActive you need to pass thisRaceID as optional param
 * aColor you need to pass 4 cells(r,g,b,a)
 *
 * @param client	Client index.
 * @param type		Type of the value which should be changed.
 * @param value		New Value.
 * @param ...		Optional Parameter, used by bActive and aColor
 * @noreturn
 * @error			Error will be thrown if client index is invalid, client is not ingame or invalid ManaType
 */
native W3SetMana(client,ManaType:type,any:value,any:...);

 /**
 * Retrieves the wanted value from the mana system
 *
 * NOTE: If you wan't to fetch:
 * szPrefix you need to pass return buffer as 3. optional param and maxlen as 4. optional param
 * aColor you need to pass a cell array with 4 members as the 3. optional param
 *
 * @param client	Client index.
 * @param type		Type of the value which should be retrieved.
 * @param ...		Optional Parameters, used by szPrefix and aColor
 * @return			Target value or noreturn on szPrefix and aColor(see retbuf param)
 * @error			Error will be thrown if client index is invalid, client is not ingame or invalid ManaType/optional params
 */
native any:W3GetMana(client,ManaType:type,any:...);

 /**
 * Prints the current mana value regardless of MANA_ACTIVE
 *
 * @param client	Client index.
 * @param duration	Time in seconds for the message to be displayed(minimun is 10 seconds but message will be overwritten by others)
 * @param rgba		In which color should the message be displayed?
 * @noreturn
 * @error			Error will be thrown if client index is invalid or client is not ingame
 */
native W3PrintMana(client,duration,rgba[4]);

/**
 * Dynamic Extension Loading
 * Do not edit anything below this line!
 */
/**
public Extension:__ext_mana = 
{
	name = "W3Mana",
	file = "w3mana.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
 */
