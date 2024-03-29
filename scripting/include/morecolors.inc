// MOAR COLORS
// By Dr. McKay
// Inspired by: https://forums.alliedmods.net/showthread.php?t=96831

#if defined _colors_included
 #endinput
#endif
#define _colors_included

#define MORE_COLORS_VERSION "1.1.0BETA"
#define MAX_MESSAGE_LENGTH 250

#define COLOR_RED 0xFF4040
#define COLOR_BLUE 0x99CCFF
#define COLOR_GRAY 0xCCCCCC
#define COLOR_GREEN 0x3EFF3E

new bool:CSkipList[MAXPLAYERS + 1] = {false, ...};
new Handle:CTrie = INVALID_HANDLE;

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 * 
 * @param client		Client index.
 * @param message		Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:		If the client is not connected an error will be thrown.
 */
stock CPrintToChat(client, const String:message[], any:...) {
	CCheckTrie();
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	if(!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}
	decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 3);
	CReplaceColorCodes(buffer2);
	PrintToChat(client, buffer2);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags.
 * 
 * @param client		Client index.
 * @param message		Message (formatting rules).
 * @noreturn
 */
stock CPrintToChatAll(const String:message[], any:...) {
	CCheckTrie();
	decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i) || CSkipList[i]) {
			CSkipList[i] = false;
			continue;
		}
		SetGlobalTransTarget(i);
		Format(buffer, sizeof(buffer), "\x01%s", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 2);
		CReplaceColorCodes(buffer2);
		PrintToChat(i, buffer2);
	}
}

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags and teamcolor tag.
 * 
 * @param client		Client index.
 * @param author		Author index whose color will be used for teamcolor tag.
 * @param message		Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:		If the client or author are not connected an error will be thrown
 */
stock CPrintToChatEx(client, author, const String:message[], any:...) {
	CCheckTrie();
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	if(!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}
	if(author <= 0 || author > MaxClients) {
		ThrowError("Invalid client index %i", author);
	}
	if(!IsClientInGame(author)) {
		ThrowError("Client %i is not in game", author);
	}
	decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	CReplaceColorCodes(buffer2, author);
	PrintToChat(client, buffer2);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags and teamcolor tag.
 *
 * @param author	  Author index whos color will be used for teamcolor tag.
 * @param message   Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:   If the author is not connected an error will be thrown.
 */
stock CPrintToChatAllEx(author, const String:message[], any:...) {
	CCheckTrie();
	if(author <= 0 || author > MaxClients) {
		ThrowError("Invalid client index %i", author);
	}
	if(!IsClientInGame(author)) {
		ThrowError("Client %i is not in game", author);
	}
	decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i) || CSkipList[i]) {
			CSkipList[i] = false;
			continue;
		}
		SetGlobalTransTarget(i);
		Format(buffer, sizeof(buffer), "\x01%s", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 3);
		CReplaceColorCodes(buffer2, author);
		PrintToChat(i, buffer2);
	}
}

/**
 * This function should only be used right in front of
 * CPrintToChatAll or CPrintToChatAllEx and it tells
 * to those funcions to skip specified client when printing
 * message to all clients. After message is printed client will
 * no more be skipped.
 * 
 * @param client   Client index
 * @noreturn
 */
stock CSkipNextClient(client) {
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	CSkipList[client] = true;
}

/**
 * Checks if the colors trie is initialized and initializes it if it's not (used internally)
 * 
 * @return			No return
 */
stock CCheckTrie() {
	if(CTrie == INVALID_HANDLE) {
		CTrie = InitColorTrie();
	}
}

/**
 * Replaces color tags in a string with color codes (used internally by CPrintToChat, CPrintToChatAll, CPrintToChatEx, and CPrintToChatAllEx
 *
 * @param buffer		String.
 * @param author		Optional client index to use for {teamcolor} tags, or 0 for none
 * @param removeTags	Optional boolean value to determine whether we're replacing tags with colors, or just removing tags, used by CRemoveTags
 * @param maxlen		Optional value for max buffer length, used by CRemoveTags
 * @noreturn
 * 
 * On error/Errors:		If the client index passed for author is invalid or not in game.
 */
stock CReplaceColorCodes(String:buffer[], author=0, bool:removeTags=false, maxlen=MAX_MESSAGE_LENGTH) {
	CCheckTrie();
	if(!removeTags) {
		ReplaceString(buffer, maxlen, "{default}", "\x01", false);
	} else {
		ReplaceString(buffer, maxlen, "{default}", "", false);
		ReplaceString(buffer, maxlen, "{teamcolor}", "", false);
	}
	if(author != 0 && !removeTags) {
		if(author < 0 || author > MaxClients) {
			ThrowError("Invalid client index %i", author);
		}
		if(!IsClientInGame(author)) {
			ThrowError("Client %i is not in game", author);
		}
		decl String:team[16];
		Format(team, sizeof(team), "\x07%06X", CGetTeamColor(author));
		ReplaceString(buffer, maxlen, "{teamcolor}", team, false);
	}
	decl String:part[maxlen], String:find[32], String:replace[16];
	new value, first, last;
	new index = 0;
	for(new i = 0; i < 100; i++) { // conditions are failsafe, we'll return in the loop
		first = FindCharInString(buffer[index], '{');
		last = FindCharInString(buffer[index], '}');
		if(first == -1 || last == -1) {
			return; // no opening or closing brace
		}
		first++;
		last--;
		for(new j = 0; j <= last - first + 1; j++) { // everything from this point on is really confusing
			if(j == last - first + 1) {
				part[j] = 0;
				break;
			}
			part[j] = buffer[index + first + j];
		}
		index += last + 2;
		StrToLower(part);
		if(GetTrieValue(CTrie, part, value)) {
			Format(find, sizeof(find), "{%s}", part);
			Format(replace, sizeof(replace), "\x07%06X", value);
			if(!removeTags) {
				ReplaceString(buffer, maxlen, find, replace, false);
			} else {
				ReplaceString(buffer, maxlen, find, "", false);
			}
		}
	}
}

/**
 * Converts a string to lowercase
 * 
 * @param buffer		String to convert
 * @noreturn
 */
stock StrToLower(String:buffer[]) {
	new len = strlen(buffer);
	for(new i = 0; i < len; i++) {
		buffer[i] = CharToLower(buffer[i]);
	}
}

/**
 * Adds a color to the colors trie
 *
 * @param name			Color name, without braces
 * @param color			Hexadecimal representation of the color (0xRRGGBB)
 * @return				True if color was added successfully, false if a color already exists with that name
 */
stock bool:CAddColor(const String:name[], color) {
	CCheckTrie();
	new value;
	if(GetTrieValue(CTrie, name, value)) {
		return false;
	}
	decl String:newName[64];
	strcopy(newName, sizeof(newName), name);
	StrToLower(newName);
	SetTrieValue(CTrie, newName, color);
	return true;
}

/**
 * Removes color tags from a message
 * 
 * @param message		Message to remove tags from
 * @param maxlen		Maximum buffer length
 * @noreturn
 */
stock CRemoveTags(String:message[], maxlen) {
	CReplaceColorCodes(message, 0, true, maxlen);
}

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

stock Handle:InitColorTrie() {
	new Handle:hTrie = CreateTrie();
	SetTrieValue(hTrie, "aliceblue", 0xF0F8FF);
	SetTrieValue(hTrie, "antiquewhite", 0xFAEBD7);
	SetTrieValue(hTrie, "aqua", 0x00FFFF);
	SetTrieValue(hTrie, "aquamarine", 0x7FFFD4);
	SetTrieValue(hTrie, "azure", 0xF0FFFF);
	SetTrieValue(hTrie, "beige", 0xF5F5DC);
	SetTrieValue(hTrie, "bisque", 0xFFE4C4);
	SetTrieValue(hTrie, "black", 0x000000);
	SetTrieValue(hTrie, "blanchedalmond", 0xFFEBCD);
	SetTrieValue(hTrie, "blue", 0x99CCFF); // same as BLU/Counter-Terrorist team color
	SetTrieValue(hTrie, "blueviolet", 0x8A2BE2);
	SetTrieValue(hTrie, "brown", 0xA52A2A);
	SetTrieValue(hTrie, "burlywood", 0xDEB887);
	SetTrieValue(hTrie, "cadetblue", 0x5F9EA0);
	SetTrieValue(hTrie, "chartreuse", 0x7FFF00);
	SetTrieValue(hTrie, "chocolate", 0xD2691E);
	SetTrieValue(hTrie, "coral", 0xFF7F50);
	SetTrieValue(hTrie, "cornflowerblue", 0x6495ED);
	SetTrieValue(hTrie, "cornsilk", 0xFFF8DC);
	SetTrieValue(hTrie, "crimson", 0xDC143C);
	SetTrieValue(hTrie, "cyan", 0x00FFFF);
	SetTrieValue(hTrie, "darkblue", 0x00008B);
	SetTrieValue(hTrie, "darkcyan", 0x008B8B);
	SetTrieValue(hTrie, "darkgoldenrod", 0xB8860B);
	SetTrieValue(hTrie, "darkgray", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgrey", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgreen", 0x006400);
	SetTrieValue(hTrie, "darkkhaki", 0xBDB76B);
	SetTrieValue(hTrie, "darkmagenta", 0x8B008B);
	SetTrieValue(hTrie, "darkolivegreen", 0x556B2F);
	SetTrieValue(hTrie, "darkorange", 0xFF8C00);
	SetTrieValue(hTrie, "darkorchid", 0x9932CC);
	SetTrieValue(hTrie, "darkred", 0x8B0000);
	SetTrieValue(hTrie, "darksalmon", 0xE9967A);
	SetTrieValue(hTrie, "darkseagreen", 0x8FBC8F);
	SetTrieValue(hTrie, "darkslateblue", 0x483D8B);
	SetTrieValue(hTrie, "darkslategray", 0x2F4F4F);
	SetTrieValue(hTrie, "darkslategrey", 0x2F4F4F);
	SetTrieValue(hTrie, "darkturquoise", 0x00CED1);
	SetTrieValue(hTrie, "darkviolet", 0x9400D3);
	SetTrieValue(hTrie, "deeppink", 0xFF1493);
	SetTrieValue(hTrie, "deepskyblue", 0x00BFFF);
	SetTrieValue(hTrie, "dimgray", 0x696969);
	SetTrieValue(hTrie, "dimgrey", 0x696969);
	SetTrieValue(hTrie, "dodgerblue", 0x1E90FF);
	SetTrieValue(hTrie, "firebrick", 0xB22222);
	SetTrieValue(hTrie, "floralwhite", 0xFFFAF0);
	SetTrieValue(hTrie, "forestgreen", 0x228B22);
	SetTrieValue(hTrie, "fuchsia", 0xFF00FF);
	SetTrieValue(hTrie, "fullblue", 0x0000FF);
	SetTrieValue(hTrie, "fullred", 0xFF0000);
	SetTrieValue(hTrie, "gainsboro", 0xDCDCDC);
	SetTrieValue(hTrie, "ghostwhite", 0xF8F8FF);
	SetTrieValue(hTrie, "gold", 0xFFD700);
	SetTrieValue(hTrie, "goldenrod", 0xDAA520);
	SetTrieValue(hTrie, "gray", 0xCCCCCC); // same as spectator team color
	SetTrieValue(hTrie, "grey", 0xCCCCCC);
	SetTrieValue(hTrie, "green", 0x3EFF3E);
	SetTrieValue(hTrie, "greenyellow", 0xADFF2F);
	SetTrieValue(hTrie, "honeydew", 0xF0FFF0);
	SetTrieValue(hTrie, "hotpink", 0xFF69B4);
	SetTrieValue(hTrie, "indianred", 0xCD5C5C);
	SetTrieValue(hTrie, "indigo", 0x4B0082);
	SetTrieValue(hTrie, "ivory", 0xFFFFF0);
	SetTrieValue(hTrie, "khaki", 0xF0E68C);
	SetTrieValue(hTrie, "lavender", 0xE6E6FA);
	SetTrieValue(hTrie, "lavenderblush", 0xFFF0F5);
	SetTrieValue(hTrie, "lawngreen", 0x7CFC00);
	SetTrieValue(hTrie, "lemonchiffon", 0xFFFACD);
	SetTrieValue(hTrie, "lightblue", 0xADD8E6);
	SetTrieValue(hTrie, "lightcoral", 0xF08080);
	SetTrieValue(hTrie, "lightcyan", 0xE0FFFF);
	SetTrieValue(hTrie, "lightgoldenrodyellow", 0xFAFAD2);
	SetTrieValue(hTrie, "lightgray", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgrey", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgreen", 0x99FF99);
	SetTrieValue(hTrie, "lightpink", 0xFFB6C1);
	SetTrieValue(hTrie, "lightsalmon", 0xFFA07A);
	SetTrieValue(hTrie, "lightseagreen", 0x20B2AA);
	SetTrieValue(hTrie, "lightskyblue", 0x87CEFA);
	SetTrieValue(hTrie, "lightslategray", 0x778899);
	SetTrieValue(hTrie, "lightslategrey", 0x778899);
	SetTrieValue(hTrie, "lightsteelblue", 0xB0C4DE);
	SetTrieValue(hTrie, "lightyellow", 0xFFFFE0);
	SetTrieValue(hTrie, "lime", 0x00FF00);
	SetTrieValue(hTrie, "limegreen", 0x32CD32);
	SetTrieValue(hTrie, "linen", 0xFAF0E6);
	SetTrieValue(hTrie, "magenta", 0xFF00FF);
	SetTrieValue(hTrie, "maroon", 0x800000);
	SetTrieValue(hTrie, "mediumaquamarine", 0x66CDAA);
	SetTrieValue(hTrie, "mediumblue", 0x0000CD);
	SetTrieValue(hTrie, "mediumorchid", 0xBA55D3);
	SetTrieValue(hTrie, "mediumpurple", 0x9370D8);
	SetTrieValue(hTrie, "mediumseagreen", 0x3CB371);
	SetTrieValue(hTrie, "mediumslateblue", 0x7B68EE);
	SetTrieValue(hTrie, "mediumspringgreen", 0x00FA9A);
	SetTrieValue(hTrie, "mediumturquoise", 0x48D1CC);
	SetTrieValue(hTrie, "mediumvioletred", 0xC71585);
	SetTrieValue(hTrie, "midnightblue", 0x191970);
	SetTrieValue(hTrie, "mintcream", 0xF5FFFA);
	SetTrieValue(hTrie, "mistyrose", 0xFFE4E1);
	SetTrieValue(hTrie, "moccasin", 0xFFE4B5);
	SetTrieValue(hTrie, "navajowhite", 0xFFDEAD);
	SetTrieValue(hTrie, "navy", 0x000080);
	SetTrieValue(hTrie, "oldlace", 0xFDF5E6);
	SetTrieValue(hTrie, "olive", 0x9EC34F);
	SetTrieValue(hTrie, "olivedrab", 0x6B8E23);
	SetTrieValue(hTrie, "orange", 0xFFA500);
	SetTrieValue(hTrie, "orangered", 0xFF4500);
	SetTrieValue(hTrie, "orchid", 0xDA70D6);
	SetTrieValue(hTrie, "palegoldenrod", 0xEEE8AA);
	SetTrieValue(hTrie, "palegreen", 0x98FB98);
	SetTrieValue(hTrie, "paleturquoise", 0xAFEEEE);
	SetTrieValue(hTrie, "palevioletred", 0xD87093);
	SetTrieValue(hTrie, "papayawhip", 0xFFEFD5);
	SetTrieValue(hTrie, "peachpuff", 0xFFDAB9);
	SetTrieValue(hTrie, "peru", 0xCD853F);
	SetTrieValue(hTrie, "pink", 0xFFC0CB);
	SetTrieValue(hTrie, "plum", 0xDDA0DD);
	SetTrieValue(hTrie, "powderblue", 0xB0E0E6);
	SetTrieValue(hTrie, "purple", 0x800080);
	SetTrieValue(hTrie, "red", 0xFF4040); // same as RED/Terrorist team color
	SetTrieValue(hTrie, "rosybrown", 0xBC8F8F);
	SetTrieValue(hTrie, "royalblue", 0x4169E1);
	SetTrieValue(hTrie, "saddlebrown", 0x8B4513);
	SetTrieValue(hTrie, "salmon", 0xFA8072);
	SetTrieValue(hTrie, "sandybrown", 0xF4A460);
	SetTrieValue(hTrie, "seagreen", 0x2E8B57);
	SetTrieValue(hTrie, "seashell", 0xFFF5EE);
	SetTrieValue(hTrie, "sienna", 0xA0522D);
	SetTrieValue(hTrie, "silver", 0xC0C0C0);
	SetTrieValue(hTrie, "skyblue", 0x87CEEB);
	SetTrieValue(hTrie, "slateblue", 0x6A5ACD);
	SetTrieValue(hTrie, "slategray", 0x708090);
	SetTrieValue(hTrie, "slategrey", 0x708090);
	SetTrieValue(hTrie, "snow", 0xFFFAFA);
	SetTrieValue(hTrie, "springgreen", 0x00FF7F);
	SetTrieValue(hTrie, "steelblue", 0x4682B4);
	SetTrieValue(hTrie, "tan", 0xD2B48C);
	SetTrieValue(hTrie, "teal", 0x008080);
	SetTrieValue(hTrie, "thistle", 0xD8BFD8);
	SetTrieValue(hTrie, "tomato", 0xFF6347);
	SetTrieValue(hTrie, "turquoise", 0x40E0D0);
	SetTrieValue(hTrie, "violet", 0xEE82EE);
	SetTrieValue(hTrie, "wheat", 0xF5DEB3);
	SetTrieValue(hTrie, "white", 0xFFFFFF);
	SetTrieValue(hTrie, "whitesmoke", 0xF5F5F5);
	SetTrieValue(hTrie, "yellow", 0xFFFF00);
	SetTrieValue(hTrie, "yellowgreen", 0x9ACD32);
	return hTrie;
}