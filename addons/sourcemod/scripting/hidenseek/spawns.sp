g_iaRandomSpawnEntities[64] = {0, ...};
g_iRandomSpawns = 0;
g_fDistanceBetweenSpawns = 600.0;

public GetMapRandomSpawnEntities()
{
    while((iEntity = FindEntityByClassname(iEntity, "info_deathmatch_spawn")) != -1) {
        if(g_iRandomSpawns >= 64)
            break;
        g_iaRandomSpawnEntities[g_iRandomSpawns] = iEntity;
        g_iRandomSpawns++;
    }

    return g_iRandomSpawns;
}

public ResetMapRandomSpawnPoints()
{
    for(new i = 0; i < g_iRandomSpawns; i++)
        g_iaRandomSpawnEntities[i] = 0;
    g_iRandomSpawns = 0;

    return g_iRandomSpawns;
}

public TrackRandomSpawnEntity(iEntity)
{
    if(g_iRandomSpawns >= 64)
        return -1;

    g_iaRandomSpawnEntities[g_iRandomSpawns] = iEntity;
    g_iRandomSpawns++;

    return g_iRandomSpawns - 1;
}

public CreateRandomSpawnEntity(faOrigin[3])
{
    new iRandomSpawnEntity = CreateEntityByName("info_deathmatch_spawn");
    if(iRandomSpawnEntity != -1) {
        DispatchSpawn(iRandomSpawnEntity);
        TeleportEntity(iRandomSpawnEntity, faOrigin, NULL_VECTOR, NULL_VECTOR);
    }

    return iRandomSpawnEntity;
}

public bool:IsRandomSpawnPointValid(faOrigin[3])
{
    for(new i = 0; i < g_iRandomSpawns; i++) {
        new Float:faCompareOrigin[3];
        Entity_GetAbsOrigin(g_iaRandomSpawnEntities[i], faCompareOrigin);
        if(GetVectorDistance(faOrigin, faCompareOrigin) < g_fDistanceBetweenSpawns)
            return false;
    }

    return true;
}

public bool:CanClientGenerateRandomSpawn(iClient)
{
    iFlags = GetEntityFlags(iClient);
    if(!(iFlags & FL_ONGROUND))
        return false;
    if((iFlags & FL_INWATER))
        return false;
    if(!(iFlags & FL_DUCKING))
        return false;
    if(GetPlayerSpeed(iClient) > 275.0)
        return false;

    return true;
}