/** MOAR COLORS (Lite)
 * By Dr. McKay
 * v1.0.0
*/

#define COLOR_GRAY 0xCCCCCC
#define COLOR_RED 0xFF4040
#define COlOR_BLUE 0x99CCFF
#define COLOR_GREEN 0x3EFF3E

/**
 * Returns the hexadecimal representation of a client's team color (will NOT initialize the trie)
 *
 * @param client		Client to get the team color for
 * @return				Client's team color in hexadecimal, or green if unknown
 * On error/Errors:		If the client index passed is invalid or not in game.
 */
stock CGetTeamColor(client) {
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	if(!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}
	new value;
	switch(GetClientTeam(client)) {
		case 1: {
			value = COLOR_GRAY;
		}
		case 2: {
			value = COLOR_RED;
		}
		case 3: {
			value = COLOR_BLUE;
		}
		default: {
			value = COLOR_GREEN;
		}
	}
	return value;
}