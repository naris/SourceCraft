/**
 * vim: set ai ts=4 sw=4 syntax=cpp :
 * File: log.inc
 * Description: Writes message to console and log.
 * Author(s): Naris (Murray Wilson)
 */

stock Log(String:message[])
{
    PrintToServer(message);
    LogMessage(message);
}

stock Error(String:message[])
{
    PrintToServer(message);
    LogError(message);
}

stock Fail(String:message[])
{
    PrintToServer(message);
    SetFailState(message);
}

