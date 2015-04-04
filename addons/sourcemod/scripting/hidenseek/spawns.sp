#define MAXIMUM_SPAWN_POINTS    40

int g_iaRandomSpawnEntities[MAXIMUM_SPAWN_POINTS] = {0, ...};
int g_iRandomSpawns = 0;
float g_fDistanceBetweenSpawns = 550.0;

public int GetMapRandomSpawnEntities()
{
    int iEntity = -1;
    while((iEntity = FindEntityByClassname(iEntity, "info_deathmatch_spawn")) != -1) {
        if(g_iRandomSpawns >= MAXIMUM_SPAWN_POINTS)
            break;
        g_iaRandomSpawnEntities[g_iRandomSpawns] = iEntity;
        g_iRandomSpawns++;
    }

    return g_iRandomSpawns;
}

public int ResetMapRandomSpawnPoints()
{
    for(int i = 0; i < g_iRandomSpawns; i++)
        g_iaRandomSpawnEntities[i] = 0;
    g_iRandomSpawns = 0;

    return g_iRandomSpawns;
}

public int TrackRandomSpawnEntity(int iEntity)
{
    if(g_iRandomSpawns >= MAXIMUM_SPAWN_POINTS)
        return -1;

    g_iaRandomSpawnEntities[g_iRandomSpawns] = iEntity;
    g_iRandomSpawns++;

    return g_iRandomSpawns - 1;
}

public int CreateRandomSpawnEntity(float faOrigin[3])
{
    int iRandomSpawnEntity = CreateEntityByName("info_deathmatch_spawn");
    if(iRandomSpawnEntity != -1) {
        DispatchSpawn(iRandomSpawnEntity);
        TeleportEntity(iRandomSpawnEntity, faOrigin, NULL_VECTOR, NULL_VECTOR);
    }

    return iRandomSpawnEntity;
}

public bool IsRandomSpawnPointValid(float faOrigin[3])
{
    for(int i = 0; i < g_iRandomSpawns; i++) {
        float faCompareOrigin[3];
        GetEntPropVector(g_iaRandomSpawnEntities[i], Prop_Data, "m_vecOrigin", faCompareOrigin);
        if(GetVectorDistance(faOrigin, faCompareOrigin) < g_fDistanceBetweenSpawns)
            return false;
    }

    return true;
}

public bool CanPlayerGenerateRandomSpawn(int iClient)
{
    int iFlags = GetEntityFlags(iClient);
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
