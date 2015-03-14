new g_iaSuicidePenaltyStacks[MAXPLAYERS + 1] = {0, ...};
new g_iMaxSuicidePenaltyStacks = 5;

stock AddSuicidePenaltyStacks(iClient, iCount = 1)
{
    if(iCount < 0)
        return g_iaSuicidePenaltyStacks[iClient];

    g_iaSuicidePenaltyStacks[iClient] += iCount;
    if(g_iaSuicidePenaltyStacks[iClient] > g_iMaxSuicidePenaltyStacks)
        g_iaSuicidePenaltyStacks[iClient] = g_iMaxSuicidePenaltyStacks;

    return g_iaSuicidePenaltyStacks[iClient];
}

stock RemoveSuicidePenaltyStacks(iClient, iCount = 1)
{
    if(iCount < 0)
        return g_iaSuicidePenaltyStacks[iClient];

    g_iaSuicidePenaltyStacks[iClient] -= iCount;
    if(g_iaSuicidePenaltyStacks[iClient] < 0)
        g_iaSuicidePenaltyStacks[iClient] = 0;

    return g_iaSuicidePenaltyStacks[iClient];
}

stock ResetSuicidePenaltyStacks(iClient)
{
    g_iaSuicidePenaltyStacks[iClient] = 0;

    return g_iaSuicidePenaltyStacks[iClient];
}

stock GetSuicidePenaltyStacks(iClient)
{
    return g_iaSuicidePenaltyStacks[iClient];
}

stock Float:RespawnPenaltyTime(iClient)
{
    new iStacks = GetSuicidePenaltyStacks(iClient);

    return Float:(2 * iStacks * iStacks + 3 * iStacks);
}