int g_iaSuicidePenaltyStacks[MAXPLAYERS + 1] = {0, ...};
int g_iMaxSuicidePenaltyStacks = 4;

public int SetSuicidePenaltyStacks(int iClient, int iCount)
{
    g_iaSuicidePenaltyStacks[iClient] = iCount;
    if(g_iaSuicidePenaltyStacks[iClient] > g_iMaxSuicidePenaltyStacks)
        g_iaSuicidePenaltyStacks[iClient] = g_iMaxSuicidePenaltyStacks;
    else if(g_iaSuicidePenaltyStacks[iClient] < 0)
        g_iaSuicidePenaltyStacks[iClient] = 0;

    return g_iaSuicidePenaltyStacks[iClient];
}

public int ResetSuicidePenaltyStacks(int iClient)
{
    g_iaSuicidePenaltyStacks[iClient] = 0;

    return g_iaSuicidePenaltyStacks[iClient];
}

public int GetSuicidePenaltyStacks(int iClient)
{
    return g_iaSuicidePenaltyStacks[iClient];
}

public float RespawnPenaltyTime(int iClient)
{
    int iStacks = GetSuicidePenaltyStacks(iClient);

    return view_as<float>(8 * iStacks + 4 / iStacks);
}
