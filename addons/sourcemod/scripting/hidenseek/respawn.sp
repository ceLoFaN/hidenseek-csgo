Handle g_haRespawn[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
Handle g_haRespawnFreezeCountdown[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
int g_iaRespawnCountdownCount[MAXPLAYERS + 1] = {0, ...};

public void RespawnPlayerLazy(int iClient, float fDelay)
{
    if(!IsPlayerRespawning(iClient)) {
        if(GetClientTeam(iClient) == CS_TEAM_T || GetClientTeam(iClient) == CS_TEAM_CT) {
            CloseRespawnFreezeCountdown(iClient);
            CancelPlayerRespawn(iClient);
            g_haRespawn[iClient] = CreateTimer(fDelay, RespawnPlayerDelayed, iClient);
            if(fDelay > 0.0)
                PrintToChat(iClient, "  \x04[HNS] %t", "Respawn Countdown", fDelay);
        }
        else
            PrintToChat(iClient, "  \x04[HNS] %t", "Invalid Team");
    }
}

public void StartRespawnFreezeCountdown(int iClient, float fDuration)
{
    int iDuration = RoundToFloor(fDuration);
    CloseRespawnFreezeCountdown(iClient);

    Handle hPack = CreateDataPack();
    g_haRespawnFreezeCountdown[iClient] = CreateDataTimer(1.0, RespawnFreezeCountdownTimer, hPack, TIMER_REPEAT);
    WritePackCell(hPack, iClient);
    WritePackCell(hPack, iDuration);
}

public Action RespawnFreezeCountdownTimer(Handle hTimer, Handle hPack) {
    ResetPack(hPack);
    int iClient = ReadPackCell(hPack);
    int iDuration = ReadPackCell(hPack);

    g_iaRespawnCountdownCount[iClient]++;
    if(g_iaRespawnCountdownCount[iClient] < iDuration) {
        if(IsClientInGame(iClient)) {
            int iTimeDelta = iDuration - g_iaRespawnCountdownCount[iClient];
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

public void CloseRespawnFreezeCountdown(int iClient)
{
    if(g_haRespawnFreezeCountdown[iClient] != INVALID_HANDLE) {
        KillTimer(g_haRespawnFreezeCountdown[iClient], true);
        g_haRespawnFreezeCountdown[iClient] = INVALID_HANDLE;
        g_iaRespawnCountdownCount[iClient] = 0;
    }
}

public Action RespawnPlayerDelayed(Handle hTimer, any iClient)
{
    RespawnPlayer(iClient);
}

public void RespawnPlayer(int iClient)
{
    if(iClient > 0 && iClient < MaxClients && IsClientInGame(iClient)) {
        if(GetClientTeam(iClient) == CS_TEAM_T || GetClientTeam(iClient) == CS_TEAM_CT)
            CS_RespawnPlayer(iClient);
    }
    g_haRespawn[iClient] = INVALID_HANDLE;
}

public bool IsPlayerRespawning(int iClient)
{
    return g_haRespawn[iClient] != INVALID_HANDLE;
}

public void CancelPlayerRespawn(int iClient)
{
    if(IsPlayerRespawning(iClient)) {
        KillTimer(g_haRespawn[iClient]);
        g_haRespawn[iClient] = INVALID_HANDLE;
    }
}
