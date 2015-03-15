#define MAXIMUM_SPAWN_POINTS    40

new g_iaRandomSpawnEntities[MAXIMUM_SPAWN_POINTS] = {0, ...};
new g_iRandomSpawns = 0;
new Float:g_fDistanceBetweenSpawns = 550.0;

public GetMapRandomSpawnEntities()
{
    new iEntity = -1;
    while((iEntity = FindEntityByClassname(iEntity, "info_deathmatch_spawn")) != -1) {
        if(g_iRandomSpawns >= MAXIMUM_SPAWN_POINTS)
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
    if(g_iRandomSpawns >= MAXIMUM_SPAWN_POINTS)
        return -1;

    g_iaRandomSpawnEntities[g_iRandomSpawns] = iEntity;
    g_iRandomSpawns++;

    return g_iRandomSpawns - 1;
}

public CreateRandomSpawnEntity(Float:faOrigin[3])
{
    new iRandomSpawnEntity = CreateEntityByName("info_deathmatch_spawn");
    if(iRandomSpawnEntity != -1) {
        DispatchSpawn(iRandomSpawnEntity);
        TeleportEntity(iRandomSpawnEntity, faOrigin, NULL_VECTOR, NULL_VECTOR);
    }

    return iRandomSpawnEntity;
}

public bool:IsRandomSpawnPointValid(Float:faOrigin[3])
{
    for(new i = 0; i < g_iRandomSpawns; i++) {
        new Float:faCompareOrigin[3];
        GetEntPropVector(g_iaRandomSpawnEntities[i], Prop_Data, "m_vecOrigin", faCompareOrigin);
        if(GetVectorDistance(faOrigin, faCompareOrigin) < g_fDistanceBetweenSpawns)
            return false;
    }

    return true;
}

public bool:CanPlayerGenerateRandomSpawn(iClient)
{
    new iFlags = GetEntityFlags(iClient);
    if(!(iFlags & FL_ONGROUND))
        return false;
    if((iFlags & FL_INWATER))
        return false;
    if(iFlags & FL_DUCKING)
        return false;
    if(GetPlayerSpeed(iClient) > 275.0)
        return false;

    return true;
}
