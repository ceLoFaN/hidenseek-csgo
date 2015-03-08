g_iaRandomSpawnEntities[64] = {0, ...};
g_iRandomSpawns = 0;

public GetMapRandomSpawnPoints()
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
		return Plugin_Handled;

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