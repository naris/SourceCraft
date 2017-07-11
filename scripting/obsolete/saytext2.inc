/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: saytext2.inc
 * Description: stock for SayText2
 * Author(s): Naris (using code by Tauphi)
 */

#if defined _saytext2_included
 #endinput
#endif
#define _saytext2_included


stock SayText2( client_index , author_index , const String:message[] ) {
    new Handle:buffer = StartMessageOne("SayText2", client_index);
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
} 

