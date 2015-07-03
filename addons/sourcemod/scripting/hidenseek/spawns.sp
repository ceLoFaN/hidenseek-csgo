#include <string>
#include <files>
#include "map_workshop_functions"

// compile defines
//#define USE_FILE // Comment this for use KeyValues or uncomment for use File handle

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

#if defined USE_FILE
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
    File hFileHandle = OpenFile(sSpawnsPath, "r");

    // parsing one line at a time until the end of the file
    char sLine[128];
    int iCount = 0;
    while(!hFileHandle.EndOfFile() && hFileHandle.ReadLine(sLine, sizeof(sLine))) {
        char saCoords[6][20];
        ExplodeString(sLine, " ", saCoords, sizeof(saCoords), sizeof(saCoords[]));

        float faOrigin[3]; // faAngles[3];
        for(int i = 0; i <= 2; i++)
            faOrigin[i] = StringToFloat(saCoords[i]);

        int iEntity = CreateRandomSpawnEntity(faOrigin);
        TrackRandomSpawnEntity(iEntity);
        iCount++;
    }

    if(hFileHandle != null) {
        delete hFileHandle;
        hFileHandle = null;
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
#else
public bool LoadSpawnPointsFromFile(bool bOverride)
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "data/hidenseek_spawns/hidenseek_spawns.txt");

    // if the spawns file doesn't exist
    if (!FileExists(sPath))
        return false;

    KeyValues hKv = new KeyValues("Spawnpoints");
    hKv.ImportFromFile(sPath);

    char sMapName[64];
    GetCurrentMapName(sMapName, sizeof(sMapName));

    // if the record about map doesn't exist
    if (!CheckMapSpawns(hKv, sMapName)) {
        delete hKv;
        return false;
    }

    if(bOverride) {
        DeleteMapRandomSpawnPoints();
        ResetMapRandomSpawnPoints();
    }

    hKv.JumpToKey(sMapName, true);

    hKv.GotoFirstSubKey(false);

    float faOrigin[3];
    int iEntity, iCount = 0;
    do {
        hKv.GetVector(NULL_STRING, faOrigin);

        iEntity = CreateRandomSpawnEntity(faOrigin);
        TrackRandomSpawnEntity(iEntity);
        iCount++;
    } while (hKv.GotoNextKey(false));

    delete hKv;

    if(iCount){
        PrintToServer("There are %d spawnpoint%s, of which %d have been loaded for %s map.", 
            g_iRandomSpawns, (g_iRandomSpawns > 1) ? "s" : "", iCount, sMapName);
        return true;
    }
    else {
        PrintToServer("No spawnpoints have been loaded for %s map.", sMapName);
        return false;
    }
}
#endif

#if defined USE_FILE
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
    File hFileHandle = OpenFile(sSpawnsPath, "w");

    int iEntity = -1;
    int iCount = 0;
    while((iEntity = FindEntityByClassname(iEntity, "info_deathmatch_spawn")) != -1) {
        float faCoord[3];
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", faCoord);
        hFileHandle.WriteLine("%f %f %f", faCoord[0], faCoord[1], faCoord[2]);
        iCount++;
    }

    if(hFileHandle != null) {
        delete hFileHandle;
        hFileHandle = null;
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
#else
public bool SaveSpawnPointsToFile(bool bOverride)
{
    KeyValues hKv = new KeyValues("Spawnpoints");

    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "data/hidenseek_spawns/hidenseek_spawns.txt");

    char sMapName[64];
    GetCurrentMapName(sMapName, sizeof(sMapName));

    // if the file already exists
    if (FileExists(sPath)) {
        hKv.ImportFromFile(sPath);
        // if the record about map exist
        if (CheckMapSpawns(hKv, sMapName))
            if (bOverride)
                DeleteMapSpawns(hKv, sMapName);
            else {
                delete hKv;
                return false;
            }
    }

    int iPointer;
    hKv.JumpToKey(sMapName, true);

    if (hKv.GotoFirstSubKey(false)) {
        iPointer++;

        while (hKv.GotoNextKey(false))
            iPointer++;

        hKv.GoBack();
    }

    int iEntity = -1;
    int iCount = 0;
    char sPointer[8];

    while((iEntity = FindEntityByClassname(iEntity, "info_deathmatch_spawn")) != -1) {
        float faCoord[3];
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", faCoord);
        IntToString(iPointer++, sPointer, sizeof(sPointer));
        hKv.SetVector(sPointer, faCoord);
        iCount++;
    }
    
    if (!iCount)
        hKv.DeleteThis();

    hKv.Rewind();
    // save KeyValues in file with specific path
    hKv.ExportToFile(sPath);

    delete hKv;

    if(iCount) {
        PrintToServer("%d spawnpoint%s have been written for %s map.", 
            iCount, (iCount > 1) ? "s" : "", sMapName);
        return true;
    }
    else {
        PrintToServer("No spawnpoints have been written for %s map.", sMapName);
        return false;
    }
}
#endif

stock void GetCurrentMapName(char[] sName, int iLength)
{
    char sMapPath[PLATFORM_MAX_PATH];
    GetCurrentMap(sMapPath, sizeof(sMapPath));
    RemoveMapPath(sMapPath, sName, iLength);
}

#if defined USE_FILE
stock bool GetCurrentMapSpawnsPath(char[] sPath, int iLength)
{
    char sMapName[64];
    GetCurrentMapName(sMapName, sizeof(sMapName));
    BuildPath(Path_SM, sPath, iLength, "data/hidenseek_spawns/%s.txt", sMapName);

    if(!FileExists(sPath))
        return false;
    return true;
}
#else
stock bool CheckMapSpawns(KeyValues hKv, const char[] sMapName)
{
    if (!hKv.JumpToKey(sMapName))
        return false;

    hKv.Rewind();

    return true;
}

stock void DeleteMapSpawns(KeyValues hKv, const char[] sMapName)
{
    hKv.JumpToKey(sMapName);
    hKv.DeleteThis();
    hKv.Rewind();
}
#endif