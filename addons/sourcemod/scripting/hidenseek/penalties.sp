new g_iaSuicidePenaltyStacks[MAXPLAYERS + 1] = {0, ...};
new g_iMaxSuicidePenaltyStacks = 5;

public SetSuicidePenaltyStacks(iClient, iCount)
{
    g_iaSuicidePenaltyStacks[iClient] = iCount;
    if(g_iaSuicidePenaltyStacks[iClient] > g_iMaxSuicidePenaltyStacks)
        g_iaSuicidePenaltyStacks[iClient] = g_iMaxSuicidePenaltyStacks;
    else if(g_iaSuicidePenaltyStacks[iClient] < 0)
        g_iaSuicidePenaltyStacks[iClient] = 0;

    PrintToServer("Client %d now has %d stacks.", iClient, g_iaSuicidePenaltyStacks[iClient]);
    return g_iaSuicidePenaltyStacks[iClient];
}

public ResetSuicidePenaltyStacks(iClient)
{
    g_iaSuicidePenaltyStacks[iClient] = 0;

    return g_iaSuicidePenaltyStacks[iClient];
}

public GetSuicidePenaltyStacks(iClient)
{
    return g_iaSuicidePenaltyStacks[iClient];
}

public Float:RespawnPenaltyTime(iClient)
{
    new iStacks = GetSuicidePenaltyStacks(iClient);
    PrintToServer("Respawn time for client %d: %f", iClient, float(2 * iStacks * iStacks + 3 * iStacks));

    return float(2 * iStacks * iStacks + 3 * iStacks);
}