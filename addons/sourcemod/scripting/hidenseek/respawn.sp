new Handle:g_haRespawn[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new Handle:g_haRespawnFreezeCountdown[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new g_iaRespawnCountdownCount[MAXPLAYERS + 1] = {0, ...};

public RespawnPlayerLazy(iClient, Float:fDelay)
{
    if(!IsPlayerRespawning(iClient)) {
        if(GetClientTeam(iClient) == CS_TEAM_T || GetClientTeam(iClient) == CS_TEAM_CT) {
            CloseRespawnFreezeCountdown(iClient);
            CancelPlayerRespawn(iClient);
            g_haRespawn[iClient] = CreateTimer(fDelay, RespawnPlayerDelayed, iClient);
            PrintToChat(iClient, "  \x04[HNS] %t", "Respawn Countdown", fDelay);
        }
        else
            PrintToChat(iClient, "  \x04[HNS] %t", "Invalid Team");
    }
}

public StartRespawnFreezeCountdown(iClient, Float:fDuration)
{
    new iDuration = RoundToFloor(fDuration);
    CloseRespawnFreezeCountdown(iClient);

    new Handle:hPack;
    WritePackCell(hPack, iClient);
    WritePackCell(hPack, iDuration);
    g_haRespawnFreezeCountdown[iClient] = CreateDataTimer(1.0, RespawnFreezeCountdownTimer, hPack, TIMER_REPEAT);
}

public Action:RespawnFreezeCountdownTimer(Handle:hTimer, Handle:hPack) {
    ResetPack(hPack);
    new iClient = ReadPackCell(hPack);
    new iDuration = ReadPackCell(hPack);

    g_iaRespawnCountdownCount[iClient]++;
    if(g_iaRespawnCountdownCount[iClient] < iDuration) {
        if(IsClientInGame(iClient)) {
            new iTimeDelta = iDuration - g_iaRespawnCountdownCount[iClient];
            PrintCenterText(iClient, "\n  %t", "Wake Up", iTimeDelta, (iTimeDelta == 1) ? "" : "s");
        }
        return Plugin_Continue;
    }
    else {
        if(IsClientInGame(iClient))
            PrintCenterText(iClient, "\n  %t", "Awake");
        //EmitSoundToAll(SOUND_GOGOGO);
        CloseRespawnFreezeCountdown(iClient);
        return Plugin_Stop;
    }
}

public CloseRespawnFreezeCountdown(iClient)
{
    if(g_haRespawnFreezeCountdown[iClient] != INVALID_HANDLE) {
        KillTimer(g_haRespawnFreezeCountdown[iClient], true);
        g_haRespawnFreezeCountdown[iClient] = INVALID_HANDLE;
        g_iaRespawnCountdownCount[iClient] = 0;
    }
}

public Action:RespawnPlayerDelayed(Handle:hTimer, any:iClient)
{
    RespawnPlayer(iClient);
}

public RespawnPlayer(iClient)
{
    if(iClient > 0 && iClient < MaxClients && IsClientInGame(iClient)) {
        if(GetClientTeam(iClient) == CS_TEAM_T || GetClientTeam(iClient) == CS_TEAM_CT)
            CS_RespawnPlayer(iClient);
    }
    g_haRespawn[iClient] = INVALID_HANDLE;
}

public bool:IsPlayerRespawning(iClient)
{
    return g_haRespawn[iClient] != INVALID_HANDLE;
}

public CancelPlayerRespawn(iClient)
{
    if(IsPlayerRespawning(iClient)) {
        KillTimer(g_haRespawn[iClient]);
        g_haRespawn[iClient] = INVALID_HANDLE;
    }
}

public RespawnDeadPlayers(Float:fDelay)
{
    for(new iClient = 1; iClient < MaxClients; iClient++) {
        if(IsClientInGame(iClient))
            if(GetClientTeam(iClient) == CS_TEAM_T || GetClientTeam(iClient) == CS_TEAM_CT)
                if(!IsPlayerAlive(iClient))
                    RespawnPlayerLazy(iClient, fDelay);
    }
}