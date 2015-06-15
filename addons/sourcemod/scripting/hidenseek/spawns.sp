#include <string>
#include <files>
#include "map_workshop_functions"

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

public void DeleteMapRandomSpawnPoints()
{
    int iEntity = -1;
    while((iEntity = FindEntityByClassname(iEntity, "info_deathmatch_spawn")) != -1)
        if(IsValidEdict(iEntity))
            AcceptEntityInput(iEntity, "kill");
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

public bool LoadSpawnPointsFromFile(bool bOverride)
{
    char sSpawnsPath[PLATFORM_MAX_PATH];
    bool bSpawns = GetCurrentMapSpawnsPath(sSpawnsPath, sizeof(sSpawnsPath));

    // if the spawns file doesn't exist
    if(!bSpawns)
        return false;

    if(bOverride) {
        DeleteMapRandomSpawnPoints();
        ResetMapRandomSpawnPoints();
    }

    //open the spawns file in read mode
    Handle hFileHandle = OpenFile(sSpawnsPath, "r");

    // parsing one line at a time until the end of the file
    char sLine[128];
    int iCount = 0;
    while(!IsEndOfFile(hFileHandle) && ReadFileLine(hFileHandle, sLine, sizeof(sLine))) {
        char saCoords[6][20];
        ExplodeString(sLine, " ", saCoords, sizeof(saCoords), sizeof(saCoords[]));

        float faOrigin[3]; // faAngles[3];
        for(int i = 0; i <= 2; i++)
            faOrigin[i] = StringToFloat(saCoords[i]);

        int iEntity = CreateRandomSpawnEntity(faOrigin);
        TrackRandomSpawnEntity(iEntity);
        iCount++;
    }

    if(hFileHandle != INVALID_HANDLE) {
        CloseHandle(hFileHandle);
        hFileHandle = INVALID_HANDLE;
    }

    if(iCount){
        PrintToServer("There are %d spawnpoint%s, of which %d have been loaded from %s.", 
            g_iRandomSpawns, (g_iRandomSpawns > 1) ? "s" : "", iCount, sSpawnsPath);
        return true;
    }
    else {
        PrintToServer("No spawnpoints have been loaded from %s.", sSpawnsPath);
        return false;
    }
}

public bool SaveSpawnPointsToFile(bool bOverride)
{
    char sSpawnsPath[PLATFORM_MAX_PATH];
    bool bSpawns = GetCurrentMapSpawnsPath(sSpawnsPath, sizeof(sSpawnsPath));

    // if the file already exists
    if(bSpawns)
        if(!bOverride)
            return false;
        else
            DeleteFile(sSpawnsPath);

    // create a file in write mode at the specified path
    Handle hFileHandle = OpenFile(sSpawnsPath, "w");

    int iEntity = -1;
    int iCount = 0;
    while((iEntity = FindEntityByClassname(iEntity, "info_deathmatch_spawn")) != -1) {
        float faCoord[3];
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", faCoord);
        WriteFileLine(hFileHandle, "%f %f %f", faCoord[0], faCoord[1], faCoord[2]);
        iCount++;
    }

    if(hFileHandle != INVALID_HANDLE) {
        CloseHandle(hFileHandle);
        hFileHandle = INVALID_HANDLE;
    }

    if(iCount) {
        PrintToServer("%d spawnpoint%s have been written to %s.", 
            iCount, (iCount > 1) ? "s" : "", sSpawnsPath);
        return true
    }
    else {
        PrintToServer("No spawnpoints have been written to %s.", sSpawnsPath);
        return false;
    }
}

stock void GetCurrentMapName(char[] sName, int iLength)
{
    char sMapPath[PLATFORM_MAX_PATH];
    GetCurrentMap(sMapPath, sizeof(sMapPath));
    RemoveMapPath(sMapPath, sName, iLength);
}

stock bool GetCurrentMapSpawnsPath(char[] sPath, int iLength)
{
    char sMapName[64];
    GetCurrentMapName(sMapName, sizeof(sMapName));
    BuildPath(Path_SM, sPath, iLength, "data/hidenseek_spawns/%s.txt", sMapName);

    if(!FileExists(sPath))
        return false;
    return true;
}