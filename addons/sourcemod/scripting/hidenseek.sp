/*
   _________________
 o Since last update

 * Fixed an unhandled case when a player throws a Molotov and leaves the server;
 * Fixed a bug introduced in the previous versions that disabled teleports;
 * Made the plugin compatible with other custom knife skins plugins;
   _______
 o Credits go to Exolent for the original HideNSeek mod.
   ______________
 o Special thanks to Ozzie who shared his private request CSS HNS plugin. Thanks to Oshizu for helping Ozzie.
 o Thanks to Ownkruid, TUSKEN1337 and wortexo for testing.
   _________
 o Thanks to Root, Bacardi, FrozDark, TESLA-X4, Doc-Holiday, Vladislav Dolgov and Jannik 'Peace-Maker' Hartung whose code helped me a lot.

*/

#include <sourcemod>
#include <protobuf>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required

#define PLUGIN_VERSION                "2.0.0-beta"
#define AUTHOR                        "ceLoFaN"

#include "hidenseek/penalties.sp"
#include "hidenseek/players.sp"
#include "hidenseek/spawns.sp"
#include "hidenseek/respawn.sp"

// ConVar Defines
#define HIDENSEEK_ENABLED             "1"
#define COUNTDOWN_TIME                "10.0"
#define ROUND_POINTS                  "3"
#define BONUS_POINTS                  "2"
#define MAXIMUM_WIN_STREAK            "5"
#define FLASHBANG_CHANCE              "0.6"
#define MOLOTOV_CHANCE                "0.05"
#define SMOKE_CHANCE                  "0.0"
#define DECOY_CHANCE                  "0.75"
#define HE_CHANCE                     "0.0"
#define FLASHBANG_MAXIMUM_AMOUNT      "2"
#define MOLOTOV_MAXIMUM_AMOUNT        "1"
#define SMOKE_MAXIMUM_AMOUNT          "1"
#define DECOY_MAXIMUM_AMOUNT          "1"
#define HE_MAXIMUM_AMOUNT             "1"
#define COUNTDOWN_FADE                "1"
#define NO_FLASH_BLIND                "2"
#define BLOCK_JOIN_TEAM               "1"
#define ATTACK_WHILE_FROZEN           "0"
#define FROSTNADES                    "1"
#define SELF_FREEZE                   "0"
#define FREEZE_GLOW                   "1"
#define FROSTNADES_TRAIL              "1"
#define FREEZE_DURATION               "3.0"
#define FREEZE_FADE                   "1"
#define FREEZE_RADIUS                 "175.0"
#define DETONATION_RING               "1"
#define BLOCK_CONSOLE_KILL            "1"
#define SUICIDE_POINTS_PENALTY        "3"
#define MOLOTOV_FRIENDLY_FIRE         "0"
#define HIDE_RADAR                    "1"
#define WELCOME_MESSAGE               "1"
// RespawnMode Defines
#define RESPAWN_MODE                  "1"
#define INVISIBILITY_DURATION         "5"
#define INVISIBILITY_BREAK_DISTANCE   "200.0"
#define BASE_RESPAWN_TIME             "5"
#define CT_RESPAWN_SLEEP_DURATION     "5"
#define RESPAWN_ROUND_DURATION        "25"

// Fade Defines
#define FFADE_IN               0x0001
#define FFADE_OUT              0x0002
#define FFADE_MODULATE         0x0004
#define FFADE_STAYOUT          0x0008
#define FFADE_PURGE            0x0010
#define COUNTDOWN_COLOR        {0,0,0,232}
#define FROST_COLOR            {20,63,255,255}
#define FREEZE_COLOR           {20,63,255,167}

// In-game Team Defines
#define JOINTEAM_RND       0
#define JOINTEAM_SPEC      1    
#define JOINTEAM_T         2
#define JOINTEAM_CT        3

// Grenade Defines
#define NADE_FLASHBANG    0
#define NADE_MOLOTOV      1
#define NADE_SMOKE        2
#define NADE_HE           3
#define NADE_DECOY        4
#define NADE_INCENDIARY   5

// Reason Defines
#define REASON_ENEMY_TOO_CLOSE  1
#define REASON_LADDER           2
#define REASON_GRENADE          3

// Freeze Type Defines
#define COUNTDOWN    0
#define FROSTNADE    1

// Sound Defines
#define SOUND_UNFREEZE             "physics/glass/glass_impact_bullet4.wav"
#define SOUND_FROSTNADE_EXPLODE    "ui/freeze_cam.wav"
#define SOUND_GOGOGO               "player\vo\fbihrt\radiobotgo01.wav"

#define HIDE_RADAR_CSGO 1<<12

#define RESPAWN_PROTECTION_TIME_ADDON 2.0

public Plugin myinfo =
{
    name = "HideNSeek",
    author = AUTHOR,
    description = "CTs with only knives chase the Ts",
    version = PLUGIN_VERSION,
    url = "steamcommunity.com/id/celofan"
};

ConVar g_hEnabled;
ConVar g_hCountdownTime;
ConVar g_hCountdownFade;
ConVar g_hRoundPoints;
ConVar g_hBonusPointsMultiplier;
ConVar g_hMaximumWinStreak;
ConVar g_hFlashbangChance;
ConVar g_hMolotovChance;
ConVar g_hSmokeGrenadeChance;
ConVar g_hDecoyChance;
ConVar g_hHEGrenadeChance;
ConVar g_hFlashbangMaximumAmount;
ConVar g_hMolotovMaximumAmount;
ConVar g_hSmokeGrenadeMaximumAmount;
ConVar g_hDecoyMaximumAmount;
ConVar g_hHEGrenadeMaximumAmount;
ConVar g_hFlashBlindDisable;
ConVar g_hBlockJoinTeam;
ConVar g_hFrostNades;
ConVar g_hSelfFreeze;
ConVar g_hAttackWhileFrozen;
ConVar g_hFreezeGlow;
ConVar g_hFreezeDuration;
ConVar g_hFreezeFade;
ConVar g_hFrostNadesTrail;
ConVar g_hFreezeRadius;
ConVar g_hFrostNadesDetonationRing;
ConVar g_hBlockConsoleKill;
ConVar g_hSuicidePointsPenalty;
ConVar g_hMolotovFriendlyFire;
ConVar g_hRespawnMode;
ConVar g_hBaseRespawnTime;
ConVar g_hInvisibilityDuration;
ConVar g_hCTRespawnSleepDuration;
ConVar g_hInvisibilityBreakDistance;
ConVar g_hHideRadar;
ConVar g_hRespawnRoundDuration;
ConVar g_hWelcomeMessage;

bool g_bEnabled;
float g_fCountdownTime;
bool g_bCountdownFade;
int g_iRoundPoints;
int g_iBonusPointsMultiplier;
int g_iMaximumWinStreak;
int g_iFlashBlindDisable;
bool g_bBlockJoinTeam;
bool g_bAttackWhileFrozen;
bool g_bFrostNades;
bool g_bSelfFreeze;
float g_fFreezeDuration;
bool g_bFreezeFade;
bool g_bFreezeGlow;
bool g_bFrostNadesTrail;
float g_fFreezeRadius;
bool g_bFrostNadesDetonationRing;
bool g_bBlockConsoleKill;
int g_iSuicidePointsPenalty;
bool g_bMolotovFriendlyFire;
float g_faGrenadeChance[6] = {0.0, ...};
int g_iaGrenadeMaximumAmounts[6] = {0, ...};
bool g_bRespawnMode;
float g_fBaseRespawnTime;
float g_fInvisibilityDuration;
float g_fCTRespawnSleepDuration;
float g_fInvisibilityBreakDistance;
bool g_bHideRadar;
int g_iRespawnRoundDuration;
bool g_bWelcomeMessage;

//RespawnMode vars
Handle g_haInvisible[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
bool g_baAvailableToSwap[MAXPLAYERS + 1] = {false, ...};
bool g_baDiedBecauseRespawning[MAXPLAYERS + 1] = {false, ...};
int g_iRoundDuration = 0;
int g_iMapTimelimit = 0;
int g_iMapRounds = 0;
Handle g_hRoundTimer = INVALID_HANDLE;
Handle g_haSpawnGenerateTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
bool g_bEnoughRespawnPoints = false;
bool g_baRespawnProtection[MAXPLAYERS + 1] = {true, ...};
Handle g_haRespawnProtectionTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

//Roundstart vars
float g_fRoundStartTime;    // Records the time when the round started
int g_iInitialTerroristsCount;    // Counts the number of Ts at roundstart
bool g_bBombFound;            // Records if the bomb has been found
float g_fCountdownOverTime;    // The time when the countdown should be over
Handle g_hStartCountdown = INVALID_HANDLE;
Handle g_hShowCountdownMessage = INVALID_HANDLE;
int g_iCountdownCount;

//Mapstart vars
int g_iTWinsInARow;    // How many rounds the terrorist won in a row
int g_iConnectedClients;     // How many clients are currently connected
int g_iGlowSprite;
int g_iBeamSprite;
int g_iHaloSprite;

//Pluginstart vars
float g_fGrenadeSpeedMultiplier;
char g_sGameDirName[10];

//Realtime vars
  //frostnades
Handle g_haFreezeTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
bool g_baFrozen[MAXPLAYERS + 1] = {false, ...};

  //game
bool g_baToggleKnife[MAXPLAYERS + 1] = {true, ...};
int g_iaInitialTeamTrack[MAXPLAYERS + 1] = {0, ...};
int g_iaAlivePlayers[2] = {0, ...};
int g_iTerroristsDeathCount;
bool g_baWelcomeMsgShown[MAXPLAYERS + 1] = {false, ...};

//Grenade consts
char g_saGrenadeWeaponNames[][] = {
    "weapon_flashbang",
    "weapon_molotov",
    "weapon_smokegrenade",
    "weapon_hegrenade",
    "weapon_decoy",
    "weapon_incgrenade"
};
char g_saGrenadeChatNames[][] = {
    "Flashbang",
    "Molotov",
    "Smoke Grenade",
    "HE Grenade",
    "Decoy Grenade",
    "Incendiary Grenade"
};
int g_iaGrenadeOffsets[] = {15, 17, 16, 14, 18, 17};

//Add your Preset ConVars here!
char g_saPresetConVars[][] = {
    "sv_airaccelerate",
    "mp_limitteams",
    "mp_freezetime",
    "sv_alltalk",
    "mp_playerid",
    "mp_solid_teammates",
    "mp_halftime",
    "mp_playercashawards",
    "mp_teamcashawards",
    "mp_friendlyfire",
    "ammo_grenade_limit_default",
    "ammo_grenade_limit_flashbang",
    "ammo_grenade_limit_total",
    "sv_staminajumpcost",
    "sv_staminalandcost"
};
int g_iaDefaultValues[] = {
    100,      // sv_airaccelerate
    1,        // mp_limitteams
    0,        // mp_freezetime
    1,        // sv_alltalk
    1,        // mp_playerid
    0,        // mp_solid_teammates
    0,        // mp_halftime
    0,        // mp_playercashawards
    0,        // mp_teamcashawards
    0,        // mp_friendlyfire
    9999,     // ammo_grenade_limit_default
    9999,     // ammo_grenade_limit_flashbang
    9999,     // ammo_grenade_limit_total
    0,        // sv_staminajumpcost
    0,        // sv_staminalandcost
};

public void OnPluginStart()
{
    //Load Translations
    LoadTranslations("hidenseek.phrases");

    //ConVars here
    CreateConVar("hidenseek_version", PLUGIN_VERSION, "Version of HideNSeek", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_hEnabled = CreateConVar("hns_enabled", HIDENSEEK_ENABLED, "Turns the mod On/Off (0=OFF, 1=ON)", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCountdownTime = CreateConVar("hns_countdown_time", COUNTDOWN_TIME, "The countdown duration during which CTs are frozen", _, true, 0.0, true, 15.0);
    g_hCountdownFade = CreateConVar("hns_countdown_fade", COUNTDOWN_FADE, "Fades the screen for CTs during countdown (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hRoundPoints = CreateConVar("hns_round_points", ROUND_POINTS, "Round points for every player in the winning team", _, true, 0.0);
    g_hBonusPointsMultiplier = CreateConVar("hns_bonus_points_multiplier", BONUS_POINTS, "Bonus points for kills (CTs) and for surviving (Ts)", _, true, 1.0, true, 3.0);
    g_hMaximumWinStreak = CreateConVar("hns_maximum_win_streak", MAXIMUM_WIN_STREAK, "The number of consecutive rounds won by T before the teams get swapped (0=DSBL)", _, true, 0.0);
    g_hFlashbangChance = CreateConVar("hns_flashbang_chance", FLASHBANG_CHANCE, "The chance of getting a Flashbang as a Terrorist", _, true, 0.0, true, 1.0);
    g_hMolotovChance = CreateConVar("hns_molotov_chance", MOLOTOV_CHANCE, "The chance of getting a Molotov as a Terrorist", _, true, 0.0, true, 1.0);
    g_hSmokeGrenadeChance = CreateConVar("hns_smoke_grenade_chance", SMOKE_CHANCE, "The chance of getting a Smoke Grenade as a Terrorist", _, true, 0.0, true, 1.0);
    g_hDecoyChance = CreateConVar("hns_decoy_chance", DECOY_CHANCE, "The chance of getting a Decoy as a Terrorist", _, true, 0.0, true, 1.0);
    g_hHEGrenadeChance = CreateConVar("hns_he_grenade_chance", HE_CHANCE, "The chance of getting a HE Grenade as a Terrorist", _, true, 0.0, true, 1.0);
    g_hFlashbangMaximumAmount = CreateConVar("hns_flashbang_maximum_amount", FLASHBANG_MAXIMUM_AMOUNT, "The maximum number of Flashbang a T can receive", _, true, 0.0, true, 10.0);
    g_hMolotovMaximumAmount = CreateConVar("hns_molotov_maximum_amount", MOLOTOV_MAXIMUM_AMOUNT, "The maximum number of Molotovs a T can receive", _, true, 0.0, true, 10.0);
    g_hSmokeGrenadeMaximumAmount = CreateConVar("hns_smoke_grenade_maximum_amount", SMOKE_MAXIMUM_AMOUNT, "The maximum number of Smoke Grenades a T can receive", _, true, 0.0, true, 10.0);
    g_hDecoyMaximumAmount = CreateConVar("hns_decoy_maximum_amount", DECOY_MAXIMUM_AMOUNT, "The maximum number of Decoy Grenades a T can receive", _, true, 0.0, true, 10.0);
    g_hHEGrenadeMaximumAmount = CreateConVar("hns_he_grenade_maximum_amount", HE_MAXIMUM_AMOUNT, "The maximum number of HE Grenades a T can receive", _, true, 0.0, true, 10.0);
    g_hFlashBlindDisable = CreateConVar("hns_flash_blind_disable", NO_FLASH_BLIND, "Removes the flashbang blind effect for Ts and Spectators (0=NONE, 1=T, 2=T&SPEC)", _, true, 0.0, true, 2.0);
    g_hBlockJoinTeam = CreateConVar("hns_block_jointeam", BLOCK_JOIN_TEAM, "Blocks the players' ability of changing teams", _, true, 0.0, true, 1.0);
    g_hFrostNades = CreateConVar("hns_frostnades", FROSTNADES, "Turns Decoys into FrostNades (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hSelfFreeze = CreateConVar("hns_self_freeze", SELF_FREEZE, "Allows players to freeze themselves (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hFreezeRadius = CreateConVar("hns_freeze_radius", FREEZE_RADIUS, "The radius in which the players can get frozen (units)", _, true, 0.0, true, 500.0);
    g_hAttackWhileFrozen = CreateConVar("hns_attack_while_frozen", ATTACK_WHILE_FROZEN, "Allows frozen players to attack (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hFreezeDuration = CreateConVar("hns_freeze_duration", FREEZE_DURATION, "Freeze duration caused by FrostNades", _, true, 0.0, true, 15.0);
    g_hFreezeFade = CreateConVar("hns_freeze_fade", FREEZE_FADE, "Fades the screen for frozen player (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hFreezeGlow = CreateConVar("hns_freeze_glow", FREEZE_GLOW, "Creates a glowing sprite around frozen players (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hFrostNadesTrail = CreateConVar("hns_frostnades_trail", FROSTNADES_TRAIL, "Leaves a trail on the FrostNades path (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hFrostNadesDetonationRing = CreateConVar("hns_frostnades_detonation_ring", DETONATION_RING, "Adds a detonation effect to FrostNades (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hBlockConsoleKill = CreateConVar("hns_block_console_kill", BLOCK_CONSOLE_KILL, "Blocks the kill command (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hSuicidePointsPenalty = CreateConVar("hns_suicide_points_penalty", SUICIDE_POINTS_PENALTY, "The amount of points players lose when dying by fall without enemy assists", _, true, 0.0);
    g_hMolotovFriendlyFire = CreateConVar("hns_molotov_friendly_fire", MOLOTOV_FRIENDLY_FIRE, "Allows molotov friendly fire (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hRespawnMode = CreateConVar("hns_respawn_mode", RESPAWN_MODE, "Turns the Respawn mode On/Off (0=OFF, 1=ON)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hBaseRespawnTime = CreateConVar("hns_base_respawn_time", BASE_RESPAWN_TIME, "The minimum time, without additions, it takes to respawn", _, true, 0.0);
    g_hInvisibilityDuration = CreateConVar("hns_respawn_invisibility_duration", INVISIBILITY_DURATION, "The time in seconds Ts get invisibility after respawning.", _, true, 0.0);
    g_hInvisibilityBreakDistance = CreateConVar("hns_invisibility_break_distance", INVISIBILITY_BREAK_DISTANCE, "The max. distance from an invisible player to an enemy required to break the invisibility.", _, true, 0.0);
    g_hCTRespawnSleepDuration = CreateConVar("hns_ct_respawn_sleep_duration", CT_RESPAWN_SLEEP_DURATION, "The duration after respawning during which CTs are asleep in Respawn mode", _, true, 0.0);
    g_hHideRadar = CreateConVar("hns_hide_radar", HIDE_RADAR, "Hide radar (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    g_hRespawnRoundDuration = CreateConVar("hns_respawn_mode_roundtime", RESPAWN_ROUND_DURATION, "The duration of a round in respawn mode", _, true, 0.0, true, 60.0);
    g_hWelcomeMessage = CreateConVar("hns_welcome_message", WELCOME_MESSAGE, "Displays a welcome message when a player first joins a team (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
    // Remember to add HOOKS to OnCvarChange and modify OnConfigsExecuted
    AutoExecConfig(true, "hidenseek");

    //Set some server ConVars
    for(int i = 0; i < sizeof(g_saPresetConVars); i++)
    {
        FindConVar(g_saPresetConVars[i]).IntValue = g_iaDefaultValues[i];
    }
    g_hEnabled.AddChangeHook(OnCvarChange);
    g_hCountdownTime.AddChangeHook(OnCvarChange);
    g_hCountdownFade.AddChangeHook(OnCvarChange);
    g_hRoundPoints.AddChangeHook(OnCvarChange);
    g_hBonusPointsMultiplier.AddChangeHook(OnCvarChange);
    g_hMaximumWinStreak.AddChangeHook(OnCvarChange);
    g_hFlashbangChance.AddChangeHook(OnCvarChange);
    g_hMolotovChance.AddChangeHook(OnCvarChange);
    g_hSmokeGrenadeChance.AddChangeHook(OnCvarChange);
    g_hDecoyChance.AddChangeHook(OnCvarChange);
    g_hHEGrenadeChance.AddChangeHook(OnCvarChange);
    g_hFlashbangMaximumAmount.AddChangeHook(OnCvarChange);
    g_hMolotovMaximumAmount.AddChangeHook(OnCvarChange);
    g_hSmokeGrenadeMaximumAmount.AddChangeHook(OnCvarChange);
    g_hDecoyMaximumAmount.AddChangeHook(OnCvarChange);
    g_hHEGrenadeMaximumAmount.AddChangeHook(OnCvarChange);
    g_hFlashBlindDisable.AddChangeHook(OnCvarChange);
    g_hBlockJoinTeam.AddChangeHook(OnCvarChange);
    g_hFrostNades.AddChangeHook(OnCvarChange);
    g_hSelfFreeze.AddChangeHook(OnCvarChange);
    g_hAttackWhileFrozen.AddChangeHook(OnCvarChange);
    g_hFreezeDuration.AddChangeHook(OnCvarChange);
    g_hFreezeFade.AddChangeHook(OnCvarChange);
    g_hFreezeGlow.AddChangeHook(OnCvarChange);
    g_hFrostNadesTrail.AddChangeHook(OnCvarChange);
    g_hFreezeRadius.AddChangeHook(OnCvarChange);
    g_hFrostNadesDetonationRing.AddChangeHook(OnCvarChange);
    g_hBlockConsoleKill.AddChangeHook(OnCvarChange);
    g_hSuicidePointsPenalty.AddChangeHook(OnCvarChange);
    g_hMolotovFriendlyFire.AddChangeHook(OnCvarChange);
    g_hRespawnMode.AddChangeHook(OnCvarChange);
    g_hBaseRespawnTime.AddChangeHook(OnCvarChange);
    g_hInvisibilityDuration.AddChangeHook(OnCvarChange);
    g_hInvisibilityBreakDistance.AddChangeHook(OnCvarChange);
    g_hCTRespawnSleepDuration.AddChangeHook(OnCvarChange);
    g_hHideRadar.AddChangeHook(OnCvarChange);
    g_hRespawnRoundDuration.AddChangeHook(OnCvarChange);
    g_hWelcomeMessage.AddChangeHook(OnCvarChange);

    //Hooked'em
    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", OnRoundEnd);
    HookEvent("item_pickup", OnItemPickUp);
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("player_blind", OnPlayerFlash, EventHookMode_Pre);
    HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Pre);
    HookEvent("player_team", OnPlayerTeam);
    HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);

    AddCommandListener(Command_JoinTeam, "jointeam");
    AddCommandListener(Command_Kill, "kill");
    AddCommandListener(Command_Kill, "explode");
    AddCommandListener(Command_Spectate, "spectate");

    g_fGrenadeSpeedMultiplier = 250.0 / 245.0;
    g_bEnabled = true;

    RegConsoleCmd("toggleknife", Command_ToggleKnife);
    RegConsoleCmd("respawn", Command_Respawn);

    ServerCommand("mp_backup_round_file \"\"");
    ServerCommand("mp_backup_round_file_last \"\"");
    ServerCommand("mp_backup_round_file_pattern \"\"");
    ServerCommand("mp_backup_round_auto 0");
    
    // Radar hide. Get game folder name and do hook for css if it needed.
    GetGameFolderName(g_sGameDirName, 10);
    if(StrContains(g_sGameDirName, "cstrike") != -1)
        HookEvent("player_blind", OnPlayerFlash_Post);
}

public void OnConfigsExecuted()
{
    g_bEnabled = g_hEnabled.BoolValue;
    g_bRespawnMode = g_hRespawnMode.BoolValue;
    g_iRespawnRoundDuration = g_hRespawnRoundDuration.IntValue;
    GameModeSetup();
    g_fCountdownTime = g_hCountdownTime.FloatValue;
    g_bCountdownFade = g_hCountdownFade.BoolValue;

    g_iRoundPoints = g_hRoundPoints.IntValue;
    g_iBonusPointsMultiplier = g_hBonusPointsMultiplier.IntValue;
    g_iMaximumWinStreak = g_hMaximumWinStreak.IntValue; 
    g_fBaseRespawnTime = g_hBaseRespawnTime.FloatValue;
    g_fInvisibilityDuration = g_hInvisibilityDuration.FloatValue;
    g_fInvisibilityBreakDistance = g_hInvisibilityBreakDistance.FloatValue + 64.0;
    g_fCTRespawnSleepDuration = g_hCTRespawnSleepDuration.FloatValue;
    g_bHideRadar = g_hHideRadar.BoolValue;
    g_bWelcomeMessage = g_hWelcomeMessage.BoolValue;
    
    g_faGrenadeChance[NADE_FLASHBANG] = g_hFlashbangChance.FloatValue;
    g_faGrenadeChance[NADE_MOLOTOV] = g_hMolotovChance.FloatValue;
    g_faGrenadeChance[NADE_SMOKE] = g_hSmokeGrenadeChance.FloatValue;
    g_faGrenadeChance[NADE_DECOY] = g_hDecoyChance.FloatValue;
    g_faGrenadeChance[NADE_HE] = g_hHEGrenadeChance.FloatValue;
    g_iaGrenadeMaximumAmounts[NADE_FLASHBANG] = g_hFlashbangMaximumAmount.IntValue;
    g_iaGrenadeMaximumAmounts[NADE_MOLOTOV] = g_hMolotovMaximumAmount.IntValue;
    g_iaGrenadeMaximumAmounts[NADE_SMOKE] = g_hSmokeGrenadeMaximumAmount.IntValue;
    g_iaGrenadeMaximumAmounts[NADE_DECOY] = g_hDecoyMaximumAmount.IntValue;
    g_iaGrenadeMaximumAmounts[NADE_HE] = g_hHEGrenadeMaximumAmount.IntValue;
    
    g_iFlashBlindDisable = g_hFlashBlindDisable.IntValue;
    g_bBlockJoinTeam = g_hBlockJoinTeam.BoolValue;
    g_bFrostNades = g_hFrostNades.BoolValue;
    g_bSelfFreeze = g_hSelfFreeze.BoolValue;
    g_fFreezeRadius = g_hFreezeRadius.FloatValue;
    g_bAttackWhileFrozen = g_hAttackWhileFrozen.BoolValue;
    g_fFreezeDuration = g_hFreezeDuration.FloatValue;
    g_bFreezeFade = g_hFreezeFade.BoolValue;
    g_bFreezeGlow = g_hFreezeGlow.BoolValue;
    g_bFrostNadesDetonationRing = g_hFrostNadesDetonationRing.BoolValue;
    g_bFrostNadesTrail = g_hFrostNadesTrail.BoolValue;
    g_bBlockConsoleKill = g_hBlockConsoleKill.BoolValue;
    g_iSuicidePointsPenalty = g_hSuicidePointsPenalty.IntValue;
    g_bMolotovFriendlyFire = g_hMolotovFriendlyFire.BoolValue;
}

public void OnCvarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
    char sConVarName[64];
    hConVar.GetName(sConVarName, sizeof(sConVarName));

    if(StrEqual("hns_enabled", sConVarName)) {
        if(g_bEnabled != hConVar.BoolValue) {
            g_bEnabled = hConVar.BoolValue;
            GameModeSetup();
        }
    } else
    if(StrEqual("hns_countdown_time", sConVarName))
        g_fCountdownTime = StringToFloat(sNewValue); else
    if(StrEqual("hns_countdown_fade", sConVarName))
        g_bCountdownFade = hConVar.BoolValue; else
    if(StrEqual("hns_round_points", sConVarName))
        g_iRoundPoints = StringToInt(sNewValue); else
    if(StrEqual("hns_bonus_points_multiplier", sConVarName))
        g_iBonusPointsMultiplier = StringToInt(sNewValue); else
    if(StrEqual("hns_maximum_win_streak", sConVarName))
        g_iMaximumWinStreak = StringToInt(sNewValue); else
    if(StrEqual("hns_flashbang_chance", sConVarName))
        g_faGrenadeChance[NADE_FLASHBANG] = StringToFloat(sNewValue); else
    if(StrEqual("hns_molotov_chance", sConVarName))
        g_faGrenadeChance[NADE_MOLOTOV] = StringToFloat(sNewValue); else
    if(StrEqual("hns_smoke_grenade_chance", sConVarName))
        g_faGrenadeChance[NADE_SMOKE] = StringToFloat(sNewValue); else
    if(StrEqual("hns_decoy_chance", sConVarName))
        g_faGrenadeChance[NADE_DECOY] = StringToFloat(sNewValue); else
    if(StrEqual("hns_he_grenade_chance", sConVarName))
        g_faGrenadeChance[NADE_HE] = StringToFloat(sNewValue); else
    if(StrEqual("hns_flashbang_maximum_amount", sConVarName))
        g_iaGrenadeMaximumAmounts[NADE_FLASHBANG] = StringToInt(sNewValue); else
    if(StrEqual("hns_molotov_maximum_amount", sConVarName))
        g_iaGrenadeMaximumAmounts[NADE_MOLOTOV] = StringToInt(sNewValue); else
    if(StrEqual("hns_smoke_grenade_maximum_amount", sConVarName))
        g_iaGrenadeMaximumAmounts[NADE_SMOKE] = StringToInt(sNewValue); else
    if(StrEqual("hns_decoy_maximum_amount", sConVarName))
        g_iaGrenadeMaximumAmounts[NADE_DECOY] = StringToInt(sNewValue); else
    if(StrEqual("hns_he_grenade_maximum_amount", sConVarName))
        g_iaGrenadeMaximumAmounts[NADE_HE] = StringToInt(sNewValue); else
    if(StrEqual("hns_flash_blind_disable", sConVarName))
        g_iFlashBlindDisable = StringToInt(sNewValue); else
    if(StrEqual("hns_attack_while_frozen", sConVarName))
        g_bAttackWhileFrozen = hConVar.BoolValue; else
    if(StrEqual("hns_frostnades", sConVarName))
        g_bFrostNades = hConVar.BoolValue; else
    if(StrEqual("hns_self_freeze", sConVarName))
        g_bSelfFreeze = hConVar.BoolValue; else
    if(StrEqual("hns_freeze_glow", sConVarName))
        g_bFreezeGlow = hConVar.BoolValue; else
    if(StrEqual("hns_freeze_duration", sConVarName))
        g_fFreezeDuration = StringToFloat(sNewValue); else
    if(StrEqual("hns_freeze_fade", sConVarName))
        g_bFreezeFade = hConVar.BoolValue; else
    if(StrEqual("hns_frostnades_trail", sConVarName))
        g_bFrostNadesTrail = hConVar.BoolValue; else
    if(StrEqual("hns_freeze_radius", sConVarName))
        g_fFreezeRadius = StringToFloat(sNewValue); else
    if(StrEqual("hns_frostnades_detonation_ring", sConVarName))
        g_bFrostNadesDetonationRing = hConVar.BoolValue; else
    if(StrEqual("hns_block_console_kill", sConVarName))
        g_bBlockConsoleKill = hConVar.BoolValue; else
    if(StrEqual("hns_suicide_points_penalty", sConVarName))
        g_iSuicidePointsPenalty = StringToInt(sNewValue); else
    if(StrEqual("hns_molotov_friendly_fire", sConVarName))
        g_bMolotovFriendlyFire = hConVar.BoolValue; else
    if(StrEqual("hns_respawn_mode", sConVarName)) {
        if(g_bRespawnMode != hConVar.BoolValue) {
            g_bRespawnMode = hConVar.BoolValue;
            GameModeSetup();
        }
    } else
    if(StrEqual("hns_base_respawn_time", sConVarName))
        g_fBaseRespawnTime = hConVar.FloatValue; else
    if(StrEqual("hns_respawn_invisibility_duration", sConVarName))
        g_fInvisibilityDuration = hConVar.FloatValue; else
    if(StrEqual("hns_invisibility_break_distance", sConVarName))
        g_fInvisibilityBreakDistance = hConVar.FloatValue + 64.0; else
    if(StrEqual("hns_ct_respawn_sleep_duration", sConVarName))
        g_fCTRespawnSleepDuration = hConVar.FloatValue; else
    if (StrEqual("hns_hide_radar", sConVarName))
        g_bHideRadar = hConVar.BoolValue; else
    if (StrEqual("hns_respawn_mode_roundtime", sConVarName))
        g_iRespawnRoundDuration = hConVar.IntValue; else
    if (StrEqual("hns_welcome_message", sConVarName))
        g_bWelcomeMessage = hConVar.BoolValue;
}

public void OnMapStart()
{
    //Precaches
    g_iGlowSprite = PrecacheModel("sprites/blueglow1.vmt");
    g_iBeamSprite = PrecacheModel("materials/sprites/physbeam.vmt");
    g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
    PrecacheSound(SOUND_UNFREEZE);
    PrecacheSound(SOUND_FROSTNADE_EXPLODE);
    PrecacheSound(SOUND_GOGOGO);
    
    g_fCountdownOverTime = 0.0;
    g_iaAlivePlayers[0] = 0; g_iaAlivePlayers[1] = 0;

    //Set some server ConVars
    for(int i = 0; i < sizeof(g_saPresetConVars); i++)
    {
        SetConVarInt(FindConVar(g_saPresetConVars[i]), g_iaDefaultValues[i], true);
    }

    if(g_bEnabled) {
        FindConVar("mp_autoteambalance").IntValue = 1; // this need to be changed for RM
    
        g_iTWinsInARow = 0;
        g_iConnectedClients = 0;
    
        CreateHostageRescue();    // Make sure T wins when the time runs out
        RemoveBombsites();
    }

    CreateTimer(1.0, RespawnDeadPlayersTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    g_bEnoughRespawnPoints = false;
    ResetMapRandomSpawnPoints();
    CreateTimer(1.0, GetMapRandomSpawnEntitiesTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action GetMapRandomSpawnEntitiesTimer(Handle hTimer)
{
    GetMapRandomSpawnEntities();
}

public void OnMapTimeLeftChanged()
{
    if(g_hRoundTimer != INVALID_HANDLE) {
        KillTimer(g_hRoundTimer);
        g_hRoundTimer = INVALID_HANDLE;
    }

    int iRoundTime = GameRules_GetProp("m_iRoundTime");
    g_hRoundTimer = CreateTimer(float(iRoundTime - 1), EnableRoundObjectives);
}

public Action EnableRoundObjectives(Handle hTimer)
{
    FindConVar("mp_ignore_round_win_conditions").IntValue = 0;
    g_hRoundTimer = INVALID_HANDLE;
}

public Action RespawnDeadPlayersTimer(Handle hTimer) 
{
    if(g_bRespawnMode) {
        for(int iClient = 1; iClient < MaxClients; iClient++) {
            if(IsClientInGame(iClient))
                if(GetClientTeam(iClient) == CS_TEAM_T || GetClientTeam(iClient) == CS_TEAM_CT)
                    if(!IsPlayerAlive(iClient))
                        RespawnPlayerLazy(iClient, g_fBaseRespawnTime + RespawnPenaltyTime(iClient));
        }
    }
    return Plugin_Continue;
}

public void OnMapEnd() 
{
    for(int iClient = 1; iClient <= MaxClients; iClient++) {
        if(g_haFreezeTimer[iClient] != INVALID_HANDLE) {
            KillTimer(g_haFreezeTimer[iClient]);
            g_haFreezeTimer[iClient] = INVALID_HANDLE;
            g_iCountdownCount = 0;
        }
        CloseRespawnFreezeCountdown(iClient);
        CancelPlayerRespawn(iClient);
        if(g_haSpawnGenerateTimer[iClient] != INVALID_HANDLE) {
            KillTimer(g_haSpawnGenerateTimer[iClient]);
            g_haSpawnGenerateTimer[iClient] = INVALID_HANDLE;
        }
    }
    if(g_hRoundTimer != INVALID_HANDLE) {
        KillTimer(g_hRoundTimer);
        g_hRoundTimer = INVALID_HANDLE;
    }
    if(g_bRespawnMode) {
        FindConVar("mp_ignore_round_win_conditions").IntValue = 1;
    }
}

public void OnRoundStart(Event hEvent, const char[] sName, bool dontBroadcast)
{
    if(!g_bEnabled)
        return;

    g_bBombFound = false;
    
    float fFraction = g_fCountdownTime - RoundToFloor(g_fCountdownTime);
    g_fRoundStartTime = GetGameTime();
    g_fCountdownOverTime = g_fRoundStartTime + g_fCountdownTime + 0.1;
    
    g_iTerroristsDeathCount = 0;
    g_iInitialTerroristsCount = GetTeamClientCount(CS_TEAM_T);

    RemoveHostages();
    
    if(g_fCountdownTime > 0.0 && (g_fCountdownOverTime - GetGameTime() + 0.1) < g_fCountdownTime + 1.0) {
        if(g_hStartCountdown != INVALID_HANDLE) {
            KillTimer(g_hStartCountdown);
            g_hStartCountdown = INVALID_HANDLE;
        }
        if(!g_bRespawnMode)
            g_hStartCountdown = CreateTimer(fFraction, StartCountdown);
    }
    return;
}

public Action StartCountdown(Handle hTimer)
{
    g_hStartCountdown = INVALID_HANDLE;
    for(int iClient = 1; iClient < MaxClients; iClient++) {
        CreateTimer(0.1, FirstCountdownMessage, iClient);
    }
    if(g_hShowCountdownMessage != INVALID_HANDLE) {
        KillTimer(g_hShowCountdownMessage);
        g_iCountdownCount = 0;
    }
    g_iCountdownCount = 0;
    g_hShowCountdownMessage = CreateTimer(1.0, ShowCountdownMessage, _, TIMER_REPEAT);
}

public Action FirstCountdownMessage(Handle hTimer, any iClient)
{
    int iCountdownTimeFloor = RoundToFloor(g_fCountdownTime);
    if(IsClientInGame(iClient))
        PrintCenterText(iClient, "\n  %t", "Start Countdown", iCountdownTimeFloor, (iCountdownTimeFloor == 1) ? "" : "s");
}

public Action ShowCountdownMessage(Handle hTimer, any iTarget)
{
    int iCountdownTimeFloor = RoundToFloor(g_fCountdownTime);
    g_iCountdownCount++;
    if(g_iCountdownCount < g_fCountdownTime) {
        for(int iClient = 1; iClient < MaxClients; iClient++) {
            if(IsClientInGame(iClient)) {
                int iTimeDelta = iCountdownTimeFloor - g_iCountdownCount;
                PrintCenterText(iClient, "\n  %t", "Start Countdown", iTimeDelta, (iTimeDelta == 1) ? "" : "s");
            }
        }
        return Plugin_Continue;
    }
    else {
        g_iCountdownCount = 0;
        g_iInitialTerroristsCount = GetTeamClientCount(CS_TEAM_T);
        for(int iClient = 1; iClient < MaxClients; iClient++) {
            if(IsClientInGame(iClient))
                PrintCenterText(iClient, "\n  %t", "Round Start");
        }
        //EmitSoundToAll(SOUND_GOGOGO);
        g_hShowCountdownMessage = INVALID_HANDLE;
        return Plugin_Stop;
    }
}

public void OnWeaponFire(Event hEvent, const char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    int iWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon"); 
    if(IsValidEntity(iWeapon)) {
        char sWeaponName[64];
        GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
        if(IsWeaponGrenade(sWeaponName)) {
            int i;
            for(i = 0; i < sizeof(g_saGrenadeWeaponNames) && !StrEqual(sWeaponName, g_saGrenadeWeaponNames[i]); i++) {}
            int iCount = GetEntProp(iClient, Prop_Send, "m_iAmmo", _, g_iaGrenadeOffsets[i]) - 1;
            DataPack hPack = new DataPack();
            if(g_haInvisible[iClient] != INVALID_HANDLE) 
                BreakInvisibility(iClient, REASON_GRENADE);
            CreateDataTimer(0.2, SwapToNade, hPack);
            hPack.WriteCell(iClient);
            hPack.WriteCell(iWeapon);
            hPack.WriteCell(iCount);
        }
    }
}

public Action SwapToNade(Handle hTimer, DataPack hPack)
{
    hPack.Reset();
    int iClient = hPack.ReadCell();
    int iWeaponThrown = hPack.ReadCell();
    int count = hPack.ReadCell();
    delete hPack;
    if(!IsClientInGame(iClient))
        return Plugin_Continue;
    int iWeaponTemp = -1;
    if(!count) {
        if(IsValidEntity(iWeaponThrown)) {
            RemovePlayerItem(iClient, iWeaponThrown);
            RemoveEdict(iWeaponThrown);
        }
        iWeaponTemp = GetPlayerWeaponSlot(iClient, 3);
    }
    if(iWeaponThrown == iWeaponTemp)
        return Plugin_Continue; //won't even get here but eh, you nevah know
    if(count)
        iWeaponTemp = iWeaponThrown;
    if(!IsValidEntity(iWeaponTemp))
        return Plugin_Continue;
    char weapon_name[64];
    GetEntityClassname(iWeaponTemp, weapon_name, sizeof(weapon_name));
    int i;
    for(i = 0; i < sizeof(g_saGrenadeWeaponNames) && !StrEqual(weapon_name, g_saGrenadeWeaponNames[i]); i++) {}
    SetEntProp(iClient, Prop_Send, "m_iAmmo", GetEntProp(iClient, Prop_Send, "m_iAmmo", _, g_iaGrenadeOffsets[i]) - 1, _, g_iaGrenadeOffsets[i]);
    RemovePlayerItem(iClient, iWeaponTemp);
    RemoveEdict(iWeaponTemp);
    iWeaponTemp = GivePlayerItem(iClient, weapon_name);
    SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeaponTemp);
    SetEntPropFloat(iWeaponTemp, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.1);
    SetEntPropFloat(iWeaponTemp, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 1.1);
    return Plugin_Continue;
}

public Action Command_ToggleKnife(int iClient, int args)
{
    if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient)) {
        g_baToggleKnife[iClient] = !g_baToggleKnife[iClient];
        PrintToChat(iClient, "  \x04[HNS] %t", g_baToggleKnife[iClient] ? "Toggle Knife On" : "Toggle Knife Off");
        
        int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
        if(!IsValidEntity(iWeapon))
            return Plugin_Handled;
        char sWeaponName[64];
        GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
        if(IsWeaponKnife(sWeaponName))
            SetViewmodelVisibility(iClient, g_baToggleKnife[iClient]);
    }
    return Plugin_Handled;
}

public Action Command_Respawn(int iClient, int args)
{
    if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient)) {
        if(!g_bRespawnMode)
            PrintToChat(iClient, "  \x04[HNS] %t", "Respawn Aborted Off");
        else if(IsPlayerRespawning(iClient))
            PrintToChat(iClient, "  \x04[HNS] %t", "Respawn Aborted Alive");
        else if(!(GetEntityFlags(iClient) & FL_ONGROUND))
            PrintToChat(iClient, "  \x04[HNS] %t", "Respawn Aborted In Flight");
        else {
            int iClientTeam = GetClientTeam(iClient);
            for(int iTarget = 1; iTarget < MaxClients; iTarget ++) {
                if(IsClientInGame(iTarget)) {
                    int iTargetTeam = GetClientTeam(iTarget);
                    if(iClientTeam != iTargetTeam && iTargetTeam != CS_TEAM_SPECTATOR) {
                        float faTargetCoord[3];
                        float faClientCoord[3];
                        GetClientAbsOrigin(iTarget, faTargetCoord);
                        GetClientAbsOrigin(iClient, faClientCoord);
                        if(GetVectorDistance(faTargetCoord, faClientCoord) <= 500) {
                            PrintToChat(iClient, "  \x04[HNS] %t", "Respawn Aborted Enemy Near");
                            return Plugin_Handled;
                        }
                    }
                }
            }
            Freeze(iClient, g_fBaseRespawnTime, FROSTNADE);
            RespawnPlayerLazy(iClient, g_fBaseRespawnTime + RespawnPenaltyTime(iClient));
        }
    }
    return Plugin_Handled;
}

public void SetViewmodelVisibility(int iClient, bool bVisible)
{
    SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", bVisible);
}

public void MakeClientInvisible(int iClient, float fDuration)
{
    SDKHook(iClient, SDKHook_SetTransmit, Hook_SetTransmit);
    PrintToChat(iClient, "  \x04[HNS] %t", "Invisible On", fDuration);

    if(g_haInvisible[iClient] != INVALID_HANDLE)
        KillTimer(g_haInvisible[iClient]);
    g_haInvisible[iClient] = CreateTimer(g_fInvisibilityDuration, MakeClientVisible, iClient, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(0.5, CheckDistanceToEnemies, iClient, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}  

public Action MakeClientVisible(Handle hTimer, any iClient)
{
    SDKUnhook(iClient, SDKHook_SetTransmit, Hook_SetTransmit);
    g_haInvisible[iClient] = INVALID_HANDLE;
    if(IsPlayerAlive(iClient))
        PrintToChat(iClient, "  \x04[HNS] %t", "Invisible Off");
}

public void BreakInvisibility(int iClient, int iReason)
{
    if(g_haInvisible[iClient] != INVALID_HANDLE) {
        KillTimer(g_haInvisible[iClient]);
        g_haInvisible[iClient] = INVALID_HANDLE;
        SDKUnhook(iClient, SDKHook_SetTransmit, Hook_SetTransmit);
        if(iReason == REASON_ENEMY_TOO_CLOSE)
            PrintToChat(iClient, "  \x04[HNS] %t", "Invisibility Broken Enemy Near");
        else if(iReason == REASON_LADDER)
            PrintToChat(iClient, "  \x04[HNS] %t", "Invisibility Broken Climb");
        else if(iReason == REASON_GRENADE)
            PrintToChat(iClient, "  \x04[HNS] %t", "Invisibility Broken Threw Grenade");
    }
}

public Action CheckDistanceToEnemies(Handle hTimer, any iClient)
{
    if(g_haInvisible[iClient] == INVALID_HANDLE)
        return Plugin_Stop;
    int iClientTeam = GetClientTeam(iClient);
    for(int iTarget = 1; iTarget < MaxClients; iTarget ++) {
        if(IsClientInGame(iTarget)) {
            int iTargetTeam = GetClientTeam(iTarget);
            if(iClientTeam != iTargetTeam && iTargetTeam != CS_TEAM_SPECTATOR) {
                float faTargetCoord[3];
                float faClientCoord[3];
                GetClientAbsOrigin(iTarget, faTargetCoord);
                GetClientAbsOrigin(iClient, faClientCoord);
                if(GetVectorDistance(faTargetCoord, faClientCoord) <= g_fInvisibilityBreakDistance) {
                    BreakInvisibility(iClient, REASON_ENEMY_TOO_CLOSE);
                    return Plugin_Stop;
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action Hook_SetTransmit(int iClient, int iEntity)
{
    if(iEntity > 0 && iEntity < MaxClients) {
        if(GetClientTeam(iClient) == GetClientTeam(iEntity))
            return Plugin_Continue;
    }
    return Plugin_Handled;
}

public int OnEntityCreated(int iEntity, const char[] sClassName)
{
    if(g_bEnabled) {    
        if(g_bFrostNades) {
            if(StrEqual(sClassName, "decoy_projectile")) {
                SDKHook(iEntity, SDKHook_StartTouch, StartTouch_Decoy);
                SDKHook(iEntity, SDKHook_SpawnPost, SpawnPost_Decoy);

                if(g_bFrostNadesTrail)
                    CreateBeamFollow(iEntity, g_iBeamSprite, FROST_COLOR);
            }
        }
    }
} 

public Action StartTouch_Decoy(int iEntity)
{
    if(!g_bEnabled || !g_bFrostNades)
        return Plugin_Continue;
    SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);

    int iRef = EntIndexToEntRef(iEntity);
    CreateTimer(1.0, DecoyDetonate, iRef);
    return Plugin_Continue;
}

public Action SpawnPost_Decoy(int iEntity)
{
    if(!g_bEnabled || !g_bFrostNades)
        return Plugin_Continue;
    SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);
    SetEntityRenderColor(iEntity, 20, 200, 255, 255);
    
    int iRef = EntIndexToEntRef(iEntity);
    CreateTimer(1.5, DecoyDetonate, iRef);
    CreateTimer(0.5, Redo_Tick, iRef);
    CreateTimer(1.0, Redo_Tick, iRef);
    CreateTimer(1.5, Redo_Tick, iRef);
    return Plugin_Continue;
}

public Action Redo_Tick(Handle hTimer, any iRef)
{
    int iEntity = EntRefToEntIndex(iRef);
    if(iEntity != INVALID_ENT_REFERENCE)
        SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);
}

public Action DecoyDetonate(Handle hTimer, any iRef)
{
    int iEntity = EntRefToEntIndex(iRef);
    if(iEntity != INVALID_ENT_REFERENCE) {
        float faDecoyCoord[3];
        GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", faDecoyCoord);
        EmitAmbientSound(SOUND_FROSTNADE_EXPLODE, faDecoyCoord, iEntity, SNDLEVEL_NORMAL);
        //faDecoyCoord[2] += 32.0;
        int iThrower = GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
        AcceptEntityInput(iEntity, "Kill");
        int ThrowerTeam = GetClientTeam(iThrower);
        
        for(int iClient = 1; iClient <= MaxClients; iClient++) {
            if(iThrower && IsClientInGame(iClient)) {
                if(IsPlayerAlive(iClient) && !g_baRespawnProtection[iClient] && ((GetClientTeam(iClient) != ThrowerTeam) || 
                (g_bSelfFreeze && iClient == iThrower))) {
                    float targetCoord[3];
                    GetClientAbsOrigin(iClient, targetCoord);
                    if (GetVectorDistance(faDecoyCoord, targetCoord) <= g_fFreezeRadius)
                        Freeze(iClient, g_fFreezeDuration, FROSTNADE, iThrower);
                }
            }
        }
        if(g_bFrostNadesDetonationRing) {
            TE_SetupBeamRingPoint(faDecoyCoord, 10.0, g_fFreezeRadius * 2, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 8.0, 0.0, FROST_COLOR, 10, 0);
            TE_SendToAll();
        }
    }
}

public void OnClientConnected(int iClient)
{
    g_iConnectedClients++;
    g_iaInitialTeamTrack[iClient] = 0;
    ResetSuicidePenaltyStacks(iClient);
}

public void OnClientDisconnect(int iClient)
{
    g_iConnectedClients--;
    SDKUnhook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
    SDKUnhook(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);
    SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKUnhook(iClient, SDKHook_SetTransmit, Hook_SetTransmit);

    if(g_baFrozen[iClient]) {
        if(g_haFreezeTimer[iClient] != INVALID_HANDLE) {
            KillTimer(g_haFreezeTimer[iClient])
            g_haFreezeTimer[iClient] = INVALID_HANDLE;
        }
        g_baFrozen[iClient] = false;
    }
    if(g_haInvisible[iClient] != INVALID_HANDLE) {
        KillTimer(g_haInvisible[iClient]);
        g_haInvisible[iClient] = INVALID_HANDLE;
    }
    CloseRespawnFreezeCountdown(iClient);
    if(g_haSpawnGenerateTimer[iClient] != INVALID_HANDLE) {
        KillTimer(g_haSpawnGenerateTimer[iClient]);
        g_haSpawnGenerateTimer[iClient] = INVALID_HANDLE;
    }
    g_baToggleKnife[iClient] = true;
    
   
    // Respawn Protection
    if(g_haRespawnProtectionTimer[iClient] != INVALID_HANDLE) {
        KillTimer(g_haRespawnProtectionTimer[iClient]);
        g_haRespawnProtectionTimer[iClient] = INVALID_HANDLE;
        g_baRespawnProtection[iClient] = false;
    }
}

public Action OnWeaponCanUse(int iClient, int iWeapon)
{
    if(!g_bEnabled)
        return Plugin_Continue;
    char sWeaponName[64];
    GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
    if(GetClientTeam(iClient) == CS_TEAM_T)
        return Plugin_Continue;
    else if(GetClientTeam(iClient) == CS_TEAM_CT && IsWeaponGrenade(sWeaponName))
        return Plugin_Handled;
    return Plugin_Continue;
}

public void OnPlayerSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    if(!g_bEnabled)
        return;
    int iId =  hEvent.GetInt("userid");
    int iClient = GetClientOfUserId(iId);
    int iTeam = GetClientTeam(iClient);

    if(g_bRespawnMode) {
        if(iTeam == CS_TEAM_T)
            MakeClientInvisible(iClient, g_fInvisibilityDuration);
    }
    
    if(iTeam == CS_TEAM_CT) {
        // Respawn Protection
        g_baRespawnProtection[iClient] = true;
    }

    g_baAvailableToSwap[iClient] = false;
    g_baDiedBecauseRespawning[iClient] = false;

    CreateTimer(0.1, OnPlayerSpawnDelay, iId);
    
    CreateTimer(0.0, RemoveRadar, iClient);

    if(g_haSpawnGenerateTimer[iClient] != INVALID_HANDLE) {
        KillTimer(g_haSpawnGenerateTimer[iClient]);
        g_haSpawnGenerateTimer[iClient] = INVALID_HANDLE;
    }
    if(!g_bEnoughRespawnPoints)
        g_haSpawnGenerateTimer[iClient] = CreateTimer(5.0, GenerateRandomSpawns, iClient, TIMER_REPEAT);
    
    return;
}

public Action GenerateRandomSpawns(Handle hTimer, any iClient) {
    if(IsPlayerAlive(iClient) && CanPlayerGenerateRandomSpawn(iClient)) {
        float faCoord[3];
        GetClientAbsOrigin(iClient, faCoord);
        if(IsRandomSpawnPointValid(faCoord)) {
            int iSpawn = CreateRandomSpawnEntity(faCoord);
            int iSpawnID = TrackRandomSpawnEntity(iSpawn);
            if(iSpawnID >= MAXIMUM_SPAWN_POINTS)
                g_bEnoughRespawnPoints = true;
        }
        return Plugin_Continue;
    }
    else {
        g_haSpawnGenerateTimer[iClient] = INVALID_HANDLE;
        return Plugin_Stop;
    }
}



public Action OnPlayerSpawnDelay(Handle hTimer, any iId)
{
    int iClient = GetClientOfUserId(iId);
    if(iClient == 0 || iClient > MaxClients)
        return Plugin_Continue;
        
    if(IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
        float fDefreezeTime = g_fCountdownOverTime - GetGameTime() + 0.1;

        SetEntProp(iClient, Prop_Send, "m_iAccount", 0);    //Set spawn money to 0$
        RemoveNades(iClient);

        int iEntity = GetPlayerWeaponSlot(iClient, 2);
        if(IsValidEdict(iEntity)) {
            char sWeaponName[64];
            GetEntityClassname(iEntity, sWeaponName, sizeof(sWeaponName));
            RemovePlayerItem(iClient, iEntity);
            AcceptEntityInput(iEntity, "Kill");
            GivePlayerItem(iClient, sWeaponName);
        }
        else 
            GivePlayerItem(iClient, "weapon_knife");        //prevents a visual bug
            
        SetViewmodelVisibility(iClient, g_baToggleKnife[iClient]);  //might fix a game bug
                
        if(g_baFrozen[iClient])
            SilentUnfreeze(iClient);
        int iWeapon = GetPlayerWeaponSlot(iClient, 2);
        int iTeam = GetClientTeam(iClient);
        if(iTeam == CS_TEAM_T) {
            GiveGrenades(iClient);
            if(IsValidEntity(iWeapon)) {
                SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 9001.0);     //change the firerate so we don't have weird clientside animations going on
                SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 9001.0);
            }
        }
        else if(iTeam == CS_TEAM_CT) {
            if(g_bRespawnMode) {
                if(g_fCTRespawnSleepDuration) {
                    Freeze(iClient, g_fCTRespawnSleepDuration, COUNTDOWN);
                    int iCountdownTimeFloor = RoundToFloor(g_fCTRespawnSleepDuration);
                    PrintCenterText(iClient, "\n  %t", "Wake Up", iCountdownTimeFloor, (iCountdownTimeFloor == 1) ? "" : "s");
                    StartRespawnFreezeCountdown(iClient, g_fCTRespawnSleepDuration);
                    // Respawn Protection
                    if(g_haRespawnProtectionTimer[iClient] != INVALID_HANDLE) {
                        KillTimer(g_haRespawnProtectionTimer[iClient]);
                        g_haRespawnProtectionTimer[iClient] = INVALID_HANDLE;
                    }
                    g_haRespawnProtectionTimer[iClient] = CreateTimer(g_fCTRespawnSleepDuration+RESPAWN_PROTECTION_TIME_ADDON, RemoveRespawnProtection, iClient);
                }
            }
            else if(g_fCountdownTime > 0.0 && fDefreezeTime > 0.0 && (fDefreezeTime < g_fCountdownTime + 1.0)) {
                if(g_iConnectedClients > 1) {
                    Freeze(iClient, fDefreezeTime, COUNTDOWN);
                    // Respawn Protection
                    if(g_haRespawnProtectionTimer[iClient] != INVALID_HANDLE) {
                        KillTimer(g_haRespawnProtectionTimer[iClient]);
                        g_haRespawnProtectionTimer[iClient] = INVALID_HANDLE;
                    }
                    g_haRespawnProtectionTimer[iClient] = CreateTimer(fDefreezeTime+RESPAWN_PROTECTION_TIME_ADDON, RemoveRespawnProtection, iClient);
                } else {
                    // Respawn Protection
                    if(g_haRespawnProtectionTimer[iClient] != INVALID_HANDLE) {
                        KillTimer(g_haRespawnProtectionTimer[iClient]);
                        g_haRespawnProtectionTimer[iClient] = INVALID_HANDLE;
                    }
                    g_haRespawnProtectionTimer[iClient] = CreateTimer(RESPAWN_PROTECTION_TIME_ADDON, RemoveRespawnProtection, iClient);
                }
            }
            else if(GetEntityMoveType(iClient) == MOVETYPE_NONE) {
                SetEntityMoveType(iClient, MOVETYPE_WALK);
                // Respawn Protection
                if(g_haRespawnProtectionTimer[iClient] != INVALID_HANDLE) {
                    KillTimer(g_haRespawnProtectionTimer[iClient]);
                    g_haRespawnProtectionTimer[iClient] = INVALID_HANDLE;
                }
                g_haRespawnProtectionTimer[iClient] = CreateTimer(RESPAWN_PROTECTION_TIME_ADDON, RemoveRespawnProtection, iClient);
            }
        }    
    }
    return Plugin_Continue;
}

public void GameModeSetup() {
    FindConVar("mp_randomspawn").BoolValue = g_bEnabled && g_bRespawnMode;
    if(g_bEnabled && g_bRespawnMode) {
        if(!g_iRoundDuration) {
            g_iRoundDuration = FindConVar("mp_roundtime").IntValue;
            if(!g_iRoundDuration)
                g_iRoundDuration = g_iRespawnRoundDuration;
        }
        if(!g_iMapRounds) {
            g_iMapRounds = FindConVar("mp_maxrounds").IntValue;
        }
        if(!g_iMapTimelimit) {
            g_iMapTimelimit = FindConVar("mp_timelimit").IntValue;
        }
        FindConVar("mp_death_drop_gun").IntValue = 0;
        FindConVar("mp_death_drop_grenade").IntValue = 0;
        FindConVar("mp_maxrounds").IntValue = 1;
        FindConVar("mp_timelimit").IntValue = g_iRespawnRoundDuration;
        FindConVar("mp_ignore_round_win_conditions").IntValue = 1;
        SetRoundTime(g_iRespawnRoundDuration, true);
        for(int iClient = 0; iClient < MaxClients; iClient++) {
            ResetSuicidePenaltyStacks(iClient);
        }
    }
    else {
        FindConVar("mp_death_drop_gun").IntValue = 1;
        FindConVar("mp_death_drop_grenade").IntValue = 1;
        FindConVar("mp_ignore_round_win_conditions").IntValue = 0;
        if(g_iMapRounds)
            FindConVar("mp_maxrounds").IntValue = g_iMapRounds;
        if(g_iMapTimelimit)
            FindConVar("mp_timelimit").IntValue = g_iMapTimelimit;
        if(g_iRoundDuration)
            SetRoundTime(g_iRoundDuration, true);
        if(g_hRoundTimer != INVALID_HANDLE) {
            KillTimer(g_hRoundTimer);
            g_hRoundTimer = INVALID_HANDLE;
        }
    }
}

public void OnClientPutInServer(int iClient)
{
    SDKHook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
    SDKHook(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);
    SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
    
    g_baWelcomeMsgShown[iClient] = false;
}

public Action Command_Spectate(int iClient, const char[] sCommand, int iArgCount)
{
    if(!g_bEnabled)
        return Plugin_Continue;
    if(!g_bBlockJoinTeam || iClient == 0 || iClient > MaxClients)
        return Plugin_Continue;

    int iTeam = GetClientTeam(iClient);
    if(iTeam == CS_TEAM_CT || CS_TEAM_T) {
        if(IsPlayerAlive(iClient)) {
            PrintToConsole(iClient, "  \x04[HNS] %t", "Spectate Deny Alive");
            return Plugin_Stop;
        }
        else {
            g_iaInitialTeamTrack[iClient] = iTeam;
            SilentUnfreeze(iClient);
            return Plugin_Continue;
        }
    }
    return Plugin_Continue;
}

public Action Command_JoinTeam(int iClient, const char[] sCommand, int iArgCount)
{
    if(!g_bEnabled)
        return Plugin_Continue;

    int iTeam = GetClientTeam(iClient);
    char sChosenTeam[2];
    GetCmdArg(1, sChosenTeam, sizeof(sChosenTeam));
    int iChosenTeam = StringToInt(sChosenTeam);
    if(iChosenTeam == CS_TEAM_SPECTATOR && IsPlayerRespawning(iClient)) {
        CancelPlayerRespawn(iClient);
    }

    if(!g_bBlockJoinTeam || iClient == 0 || iClient > MaxClients)
        return Plugin_Continue;

    int iLimitTeams = FindConVar("mp_limitteams").IntValue;
    int iDelta = GetTeamPlayerCount(CS_TEAM_T) - GetTeamPlayerCount(CS_TEAM_CT);
    if(iTeam == CS_TEAM_T || iTeam == CS_TEAM_CT) {
        if(iChosenTeam == JOINTEAM_T || iChosenTeam == JOINTEAM_CT || iChosenTeam == JOINTEAM_RND) {
            if(IsPlayerAlive(iClient)) {
                PrintToChat(iClient, "  \x04[HNS] %t", "Team Change Deny Alive");
                return Plugin_Stop;
            }
            else if(iDelta > iLimitTeams || -iDelta > iLimitTeams) {
                g_iaInitialTeamTrack[iClient] = iChosenTeam;
                return Plugin_Continue;
            }
            else {
                PrintToChat(iClient, "  \x04[HNS] %t", "Team Change Deny Balanced");
                return Plugin_Stop;
            }
        }
        else if(iChosenTeam == JOINTEAM_SPEC) {
            if(IsPlayerAlive(iClient)) {
                PrintToConsole(iClient, "  \x04[HNS] %T", "Spectate Deny Alive", iClient);
                return Plugin_Stop;
            }
            else {
                g_iaInitialTeamTrack[iClient] = iTeam;
                SilentUnfreeze(iClient);
                return Plugin_Continue;
            }
        }
        else {
            PrintToConsole(iClient, "  \x04[HNS] %T", "Invalid Team Console", iClient);
            return Plugin_Stop;
        }
    }
    else if(iTeam == CS_TEAM_SPECTATOR) {
        if(iDelta > iLimitTeams || -iDelta > iLimitTeams) {
            if(iChosenTeam == JOINTEAM_T || iChosenTeam == JOINTEAM_CT || iChosenTeam == JOINTEAM_RND) {
                g_iaInitialTeamTrack[iClient] = iChosenTeam;
            }
            return Plugin_Continue;
        }
        else if(g_iaInitialTeamTrack[iClient]) {
            PrintToChat(iClient, "  \x04[HNS] %t", (g_iaInitialTeamTrack[iClient] == CS_TEAM_T) ? "Assigned To Team T" : "Assigned To Team CT");
            CS_SwitchTeam(iClient, g_iaInitialTeamTrack[iClient]);
            return Plugin_Stop;
        }
        if(iChosenTeam == JOINTEAM_T || iChosenTeam == JOINTEAM_CT || iChosenTeam == JOINTEAM_RND)
        return Plugin_Continue;
    }
    SilentUnfreeze(iClient);
    return Plugin_Continue;
}

public Action Command_Kill(int iClient, const char[] sCommand, int iArgCount)
{
    if(!g_bEnabled)
        return Plugin_Continue;
    if (!g_bBlockConsoleKill || iClient == 0 || iClient > MaxClients)
        return Plugin_Continue;
    PrintToConsole(iClient, "  \x04[HNS] %T", "Kill Deny", iClient);
    return Plugin_Stop;
}

public void OnItemPickUp(Event hEvent, const char[] szName, bool bDontBroadcast)
{
    if(!g_bEnabled)
        return;
    char sItem[64];
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    hEvent.GetString("item", sItem, sizeof(sItem));
    if(!g_bBombFound)
        if(StrEqual(sItem, "weapon_c4", false)) {
            RemovePlayerItem(iClient, GetPlayerWeaponSlot(iClient, 4));    //Remove the bomb
            g_bBombFound = true;
            return;
        }
    for(int i = 0; i < 2; i++)
        RemoveWeaponBySlot(iClient, i);
    return;
}

public void OnWeaponSwitchPost(int iClient, int iWeapon)
{
    if(g_bEnabled) {
        char sWeaponName[64];
        GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
        if(IsWeaponGrenade(sWeaponName)) {
            SetClientSpeed(iClient, g_fGrenadeSpeedMultiplier);
            SetViewmodelVisibility(iClient, true);
        }
        else {
            SetClientSpeed(iClient, 1.0);
            if(IsWeaponKnife(sWeaponName))
                SetViewmodelVisibility(iClient, g_baToggleKnife[iClient]); 
        }
        
        float fCurrentTime = GetGameTime();
        if(fCurrentTime < g_fCountdownOverTime && !g_bRespawnMode) {
            SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", g_fCountdownOverTime);
            SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", g_fCountdownOverTime);
        }
        else if(GetClientTeam(iClient) == CS_TEAM_T && IsWeaponKnife(sWeaponName)) {
            SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fCurrentTime + 9001.0);
            SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", fCurrentTime + 9001.0);
        }
    }
}

public Action OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &iDamage, int &iDamageType)
{
    if(!g_bEnabled)
        return Plugin_Continue;
    if(iVictim == 0)
        return Plugin_Continue;
    else {
        if(!g_bMolotovFriendlyFire)
            if(iDamageType & DMG_BURN) {
                if(!iAttacker || iAttacker > MaxClients)
                    return Plugin_Handled;
                if(!IsClientInGame(iAttacker))
                    if(GetClientTeam(iVictim) == g_iaInitialTeamTrack[iAttacker])
                        return Plugin_Handled;
                if(GetClientTeam(iVictim) == GetClientTeam(iAttacker))
                    return Plugin_Handled;
            }
    }
    return Plugin_Continue;
}

public void OnPlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    if(!g_bEnabled)
        return;
    int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
    int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
    int iAssister = GetClientOfUserId(hEvent.GetInt("assister"));

    int iVictimTeam = GetClientTeam(iVictim);

    if(iVictim > 0 && iVictim <= MaxClients) {
        if(iVictimTeam == CS_TEAM_T) {
            g_iTerroristsDeathCount++;
            if(iAttacker > 0 && iAttacker <= MaxClients) {
                int iAttackerTeam = GetClientTeam(iAttacker);
                if(iAttackerTeam == CS_TEAM_CT) {
                    SetEntProp(iAttacker, Prop_Send, "m_iAccount", 0);    //Make sure the player doesn't get the money
                    CS_SetClientContributionScore(iAttacker, CS_GetClientContributionScore(iAttacker) + g_iBonusPointsMultiplier - 1); 
                    char sNickname[MAX_NAME_LENGTH];                    
                    GetClientName(iVictim, sNickname, sizeof(sNickname));

                    SetSuicidePenaltyStacks(iVictim, GetSuicidePenaltyStacks(iVictim) - 1);
                    SetSuicidePenaltyStacks(iAttacker, GetSuicidePenaltyStacks(iAttacker) - 1);
                    
                    if(!g_bRespawnMode)
                        PrintToChat(iAttacker, "  \x04[HNS] %t", 
                            "Points For Killing", g_iBonusPointsMultiplier, (g_iBonusPointsMultiplier == 1) ? "" : "s", sNickname);
                    else {
                        g_baAvailableToSwap[iVictim] = false;
                        g_baAvailableToSwap[iAttacker] = false;

                        g_baDiedBecauseRespawning[iAttacker] = true;

                        DealDamage(iAttacker, 9999, 69); //this should do the trick
                        SetClientFrags(iVictim, GetClientFrags(iAttacker) + 1);

                        CS_SwitchTeam(iAttacker, CS_TEAM_T);
                        g_iaInitialTeamTrack[iAttacker] = CS_TEAM_T;
                        CS_SwitchTeam(iVictim, CS_TEAM_CT);
                        g_iaInitialTeamTrack[iVictim] = CS_TEAM_CT;

                        CancelPlayerRespawn(iAttacker);
                        RespawnPlayerLazy(iAttacker, 0.0 + RespawnPenaltyTime(iAttacker));

                        PrintToChat(iAttacker, "  \x04[HNS] %t", 
                            "Killing Notify Attacker", sNickname, g_iBonusPointsMultiplier, (g_iBonusPointsMultiplier == 1) ? "" : "s");

                        GetClientName(iAttacker, sNickname, sizeof(sNickname));
                        PrintToChat(iVictim, "  \x04[HNS] %t", "Killing Notify Victim", sNickname);
                    }
                }
            }
        }
    }
    if(g_baFrozen[iVictim])
        SilentUnfreeze(iVictim);

    if(iVictim > 0 && iVictim <= MaxClients && iAttacker == 0) {
        if(!(iAssister > 0 && iAssister <= MaxClients)) {
            if(!g_baDiedBecauseRespawning[iVictim]) {
                SetClientFrags(iVictim, GetClientFrags(iVictim) + 1);
                if(iVictimTeam == CS_TEAM_T) {
                    SetSuicidePenaltyStacks(iVictim, GetSuicidePenaltyStacks(iVictim) + 1);
                    g_baAvailableToSwap[iVictim] = true;
                }
                if(g_iSuicidePointsPenalty) {
                    CS_SetClientContributionScore(iVictim, CS_GetClientContributionScore(iVictim) - g_iSuicidePointsPenalty);
                    PrintToChat(iVictim, "  \x04[HNS] %t", "Died By Falling", g_iSuicidePointsPenalty);
                }
            }
        }
        if(iVictimTeam == CS_TEAM_CT) {
            if(!g_baDiedBecauseRespawning[iVictim])
                g_baAvailableToSwap[iVictim] = true;
        }
    }

    if(g_bRespawnMode) {
        if(g_baAvailableToSwap[iVictim]) {
            TrySwapPlayers(iVictim);
            RespawnPlayerLazy(iVictim, g_fBaseRespawnTime + RespawnPenaltyTime(iVictim));
        }
    }
    return;
}

public void TrySwapPlayers(int iClient) 
{
    int iClientTeam = GetClientTeam(iClient);
    for(int iTarget = 1; iTarget < MaxClients; iTarget++) {
        if(IsClientInGame(iTarget))
            if(!IsPlayerAlive(iTarget)) {
                int iTargetTeam = GetClientTeam(iTarget);
                if((iClientTeam == CS_TEAM_CT && iTargetTeam == CS_TEAM_T) || (iClientTeam == CS_TEAM_T && iTargetTeam == CS_TEAM_CT))
                    if(g_baAvailableToSwap[iTarget]) {
                        CS_SwitchTeam(iClient, iTargetTeam);
                        g_iaInitialTeamTrack[iClient] = iTargetTeam;

                        CS_SwitchTeam(iTarget, iClientTeam);
                        g_iaInitialTeamTrack[iTarget] = iClientTeam;

                        g_baAvailableToSwap[iClient] = false;
                        g_baAvailableToSwap[iTarget] = false;

                        char sNickname[MAX_NAME_LENGTH];
                        GetClientName(iTarget, sNickname, sizeof(sNickname));
                        PrintToChat(iClient, "  \x04[HNS] %t", "Swapped", sNickname);

                        GetClientName(iClient, sNickname, sizeof(sNickname));
                        PrintToChat(iTarget, "  \x04[HNS] %t", "Swapped", sNickname);
                    }
            }
    }
}

public Action OnPlayerFlash(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    if(!g_bEnabled)
        return Plugin_Continue;
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    int iTeam = GetClientTeam(iClient);
    
    if(g_iFlashBlindDisable) {
        if(iTeam == CS_TEAM_T)
            SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);
        else
            if(g_iFlashBlindDisable == 2 && iTeam == CS_TEAM_SPECTATOR)
                SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);
    }
    
    if(g_baRespawnProtection[iClient])
        SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);
    
    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float faVelocity[3], float faAngles[3], int &iWeapon)
{
    if(!g_bEnabled)
        return Plugin_Continue;
    
    if(!g_bAttackWhileFrozen && g_baFrozen[iClient]) {
        iButtons &= ~(IN_ATTACK | IN_ATTACK2);
        return Plugin_Changed;
    }
    
    if(g_haInvisible[iClient] != INVALID_HANDLE)
        if(GetEntityMoveType(iClient) == MOVETYPE_LADDER)
            BreakInvisibility(iClient, REASON_LADDER);

    float fCurrentTime = GetGameTime();
    if(GetClientTeam(iClient) == CS_TEAM_T) {
        if (iButtons & (IN_ATTACK | IN_ATTACK2)) {  //this might be unnecessary
            int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
            if(IsValidEntity(iActiveWeapon)) {
                char sWeaponName[64];
                GetEntityClassname(iActiveWeapon, sWeaponName, sizeof(sWeaponName));
                if(IsWeaponKnife(sWeaponName)) {
                    SetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", fCurrentTime + 9001.0);
                    SetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", fCurrentTime + 9001.0);
                    iButtons &= ~(IN_ATTACK | IN_ATTACK2);    //Block attacks for Ts
                    return Plugin_Changed;
                }
                else if(IsWeaponGrenade(sWeaponName) && fCurrentTime < g_fCountdownOverTime && !g_bRespawnMode) {
                    SetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", g_fCountdownOverTime);
                    SetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", g_fCountdownOverTime);
                    iButtons &= ~(IN_ATTACK | IN_ATTACK2);    //Block attacks for Ts
                    return Plugin_Changed;
                }
            }
            else
                return Plugin_Continue;
        }
    }
    else if(GetClientTeam(iClient) == CS_TEAM_CT)
        if (iButtons & (IN_ATTACK)) {
            iButtons &= ~(IN_ATTACK);    //Block attack1 for CTs but use attack2 instead
            iButtons |= IN_ATTACK2;
            return Plugin_Changed;
        }
    return Plugin_Continue;
}

public void OnRoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
    if(!g_bEnabled)
        return;
    int iWinningTeam = hEvent.GetInt("winner");
    int iCTScore = CS_GetTeamScore(CS_TEAM_CT);
    int iPoints;
    
    if(iWinningTeam == CS_TEAM_T) {
        if(!g_iMaximumWinStreak || ++g_iTWinsInARow < g_iMaximumWinStreak)
            PrintToChatAll("  \x04[HNS] %t", "T Win");
        else {
            SwapTeams();
            g_iTWinsInARow = 0;
            //Set the team scores
            CS_SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T) + 1);
            SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T) + 1);
            CS_SetTeamScore(CS_TEAM_T, iCTScore);
            SetTeamScore(CS_TEAM_T, iCTScore);
            if(g_iMaximumWinStreak)
                PrintToChatAll("  \x04[HNS] %t", "T Win Team Swap");
        }

        for(int iClient = 1; iClient < MaxClients; iClient++) {
            if(IsClientInGame(iClient))
                if(GetClientTeam(iClient) == CS_TEAM_T) {
                    CS_SetClientContributionScore(iClient, CS_GetClientContributionScore(iClient) + g_iRoundPoints);
                    if(IsPlayerAlive(iClient) && g_iTerroristsDeathCount) {
                        int iDivider = g_iInitialTerroristsCount - g_iTerroristsDeathCount;
                        if(iDivider < 1)
                            iDivider = 1; //getting the actual number of terrorists would be better
                        iPoints = g_iBonusPointsMultiplier * g_iTerroristsDeathCount / iDivider;            
                        CS_SetClientContributionScore(iClient, CS_GetClientContributionScore(iClient) + iPoints);
                        PrintToChat(iClient, "  \x04[HNS] %t", "Points For T Surviving and Win", iPoints, g_iRoundPoints);
                    }
                    else
                        PrintToChat(iClient, "  \x04[HNS] %t", "Points For Win", g_iRoundPoints);
                }
        }
    }
    else if(iWinningTeam == CS_TEAM_CT)
    {
        for(int iClient = 1; iClient < MaxClients; iClient++) {
            if(IsClientInGame(iClient))
                if(GetClientTeam(iClient) == CS_TEAM_CT) {
                    CS_SetClientContributionScore(iClient, CS_GetClientContributionScore(iClient) + g_iRoundPoints);
                    PrintToChat(iClient, "  \x04[HNS] %t", "Points For Win", g_iRoundPoints);
                }
        }
        SwapTeams();
        PrintToChatAll("  \x04[HNS] %t", "CT Win");
        g_iTWinsInARow = 0;
        //Set the team scores
        CS_SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T));
        SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T));
        CS_SetTeamScore(CS_TEAM_T, iCTScore);
        SetTeamScore(CS_TEAM_T, iCTScore);
    }
    return;
}

stock void RemoveNades(int iClient)
{
    while(RemoveWeaponBySlot(iClient, 3)){}
    for(int i = 0; i < 6; i++)
        SetEntProp(iClient, Prop_Send, "m_iAmmo", 0, _, g_iaGrenadeOffsets[i]);
}

stock void GiveGrenades(int iClient)
{
    int iaReceived[6] = {0, ...};
    int iLastType = -1;
    int iFirstType = -1;
    bool bAtLeastTwo = false;
    for(int i = 0; i < sizeof(iaReceived); i++) {
        for(int j = 0; j < g_iaGrenadeMaximumAmounts[i]; j++)
            if(GetRandomFloat(0.0, 1.0) < g_faGrenadeChance[i])
                iaReceived[i]++;
        if(iaReceived[i]) {
            GivePlayerItem(iClient, g_saGrenadeWeaponNames[i]);
            SetEntProp(iClient, Prop_Send, "m_iAmmo", iaReceived[i], _, g_iaGrenadeOffsets[i]);
            if(iLastType != -1)
                bAtLeastTwo = true;
            if(iFirstType == -1)
                iFirstType = i;
            iLastType = i;
        }
    }

    if(iLastType == -1)
        PrintToChat(iClient, "  \x04[HNS] %t", "No Grenades");
    else {
        char sGrenadeMessage[256];
        for(int i = 0; i < sizeof(iaReceived); i++) {
            if(iaReceived[i]) {
                if(bAtLeastTwo && i != iFirstType) {
                    if(i == iLastType)
                        Format(sGrenadeMessage, sizeof(sGrenadeMessage), "%s %T ", sGrenadeMessage, "And", iClient);
                    else
                        StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), ", ");
                }
                char sNumberTemp[5];
                IntToString(iaReceived[i], sNumberTemp, sizeof(sNumberTemp));
                StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), sNumberTemp);
                StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), " ");
                if(i == NADE_DECOY && g_bFrostNades)
                    Format(sGrenadeMessage, sizeof(sGrenadeMessage), "%s%T", sGrenadeMessage, "FrostNade", iClient);
                else
                    Format(sGrenadeMessage, sizeof(sGrenadeMessage), "%s%T", sGrenadeMessage, g_saGrenadeChatNames[i], iClient);
                if(iaReceived[i] > 1)
                    Format(sGrenadeMessage, sizeof(sGrenadeMessage), "%s%T", sGrenadeMessage, "Plural", iClient);
                else
                    Format(sGrenadeMessage, sizeof(sGrenadeMessage), "%s%T", sGrenadeMessage, "Singular", iClient);
            }
        }
        PrintToChat(iClient, "  \x04[HNS] %t", "Grenades Received", sGrenadeMessage);
    }
}

stock void SwapTeams()
{
    for(int iClient = 1; iClient < MaxClients; iClient++) {
        if(IsClientInGame(iClient)) {
            int team = GetClientTeam(iClient);
            if(team == CS_TEAM_T) {
                CS_SwitchTeam(iClient, CS_TEAM_CT);
                g_iaInitialTeamTrack[iClient] = CS_TEAM_CT;
            }
            else if(team == CS_TEAM_CT) {
                CS_SwitchTeam(iClient, CS_TEAM_T);
                g_iaInitialTeamTrack[iClient] = CS_TEAM_T;
            }
            else {
                if(g_iaInitialTeamTrack[iClient] == CS_TEAM_T)
                    g_iaInitialTeamTrack[iClient] = CS_TEAM_CT;
                else if(g_iaInitialTeamTrack[iClient] == CS_TEAM_CT)
                    g_iaInitialTeamTrack[iClient] = CS_TEAM_T;
            }
        }
    }
}

stock void ScreenFade(int iClient, int iFlags = FFADE_PURGE, int iaColor[4] = {0, 0, 0, 0}, int iDuration = 0, int iHoldTime = 0)
{
    Handle hScreenFade = StartMessageOne("Fade", iClient);
    PbSetInt(hScreenFade, "duration", iDuration * 500);
    PbSetInt(hScreenFade, "hold_time", iHoldTime * 500);
    PbSetInt(hScreenFade, "flags", iFlags);
    PbSetColor(hScreenFade, "clr", iaColor);
    EndMessage();
}

stock bool RemoveWeaponBySlot(int iClient, int iSlot)
{
    int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
    if(IsValidEdict(iEntity)) {
        RemovePlayerItem(iClient, iEntity);
        AcceptEntityInput(iEntity, "Kill");
        return true;
    }
    return false;
}

stock void CreateHostageRescue()
{
    int iEntity = -1;
    if((iEntity = FindEntityByClassname(iEntity, "func_hostage_rescue")) == -1) {
        int iHostageRescueEnt = CreateEntityByName("func_hostage_rescue");
        DispatchKeyValue(iHostageRescueEnt, "targetname", "fake_hostage_rescue");
        DispatchKeyValue(iHostageRescueEnt, "origin", "-3141 -5926 -5358");
        DispatchSpawn(iHostageRescueEnt);
    }
}

stock void RemoveHostages()
{
    int iEntity = -1;
    while((iEntity = FindEntityByClassname(iEntity, "hostage_entity")) != -1)     //Find hostages
        AcceptEntityInput(iEntity, "kill");
}

stock void RemoveBombsites()
{
    int iEntity = -1;
    while((iEntity = FindEntityByClassname(iEntity, "func_bomb_target")) != -1)    //Find bombsites
        AcceptEntityInput(iEntity, "kill");    //Destroy the entity
}

stock void SetRoundTime(int iTime, bool bRestartRound = false)
{
    FindConVar("mp_roundtime_defuse").IntValue = 0;
    FindConVar("mp_roundtime_hostage").IntValue = 0;
    FindConVar("mp_roundtime").IntValue = iTime;
    if(bRestartRound)
        FindConVar("mp_restartgame").IntValue = 1;
}

stock bool IsWeaponKnife(const char[] sWeaponName)
{
    return StrContains(sWeaponName, "knife", false) != -1;
}

stock bool IsWeaponGrenade(const char[] sWeaponName)
{
    for(int i = 0; i < sizeof(g_saGrenadeWeaponNames); i++)
        if(StrEqual(g_saGrenadeWeaponNames[i], sWeaponName))
            return true;
    return false;
}

stock void SetClientSpeed(int iClient, float speed)
{
    SetEntPropFloat(iClient, Prop_Send, "m_flLaggedMovementValue", speed);
}

stock void Freeze(int iClient, float fDuration, int iType, int iAttacker = 0)
{
    SetEntityMoveType(iClient, MOVETYPE_NONE);
    if(!g_bAttackWhileFrozen && (GetClientTeam(iClient) == CS_TEAM_CT)) {
        float defreezetime = GetGameTime() + fDuration;
        int knife = GetPlayerWeaponSlot(iClient, 2);
        if(IsValidEntity(knife)) {
            SetEntPropFloat(knife, Prop_Send, "m_flNextPrimaryAttack", defreezetime);
            SetEntPropFloat(knife, Prop_Send, "m_flNextSecondaryAttack", defreezetime);
        }
    }
    if(iType == FROSTNADE && g_bFreezeGlow) {
        float coord[3];
        GetClientEyePosition(iClient, coord);
        coord[2] -= 32.0;
        CreateGlowSprite(g_iGlowSprite, coord, fDuration);
        LightCreate(coord, fDuration);
    }
    if(iAttacker == 0) {
        PrintToChat(iClient, "  \x04[HNS] %t", "Frozen", fDuration);
    }
    else if(iAttacker == iClient) {
        PrintToChat(iClient, "  \x04[HNS] %t", "Frozen Yourself", fDuration);
    }
    else if(iAttacker <= MaxClients) {
        if(IsClientInGame(iAttacker)) {
            char sAttackerName[MAX_NAME_LENGTH];
            GetClientName(iAttacker, sAttackerName, sizeof(sAttackerName));
            PrintToChat(iClient, "  \x04[HNS] %t", "Frozen By", sAttackerName, fDuration);
        }
    }
    if(g_baFrozen[iClient]) {
        if(g_haFreezeTimer[iClient] != INVALID_HANDLE) {
            KillTimer(g_haFreezeTimer[iClient]);
            if(iType == FROSTNADE)
                g_haFreezeTimer[iClient] = CreateTimer(fDuration, Unfreeze, iClient);
            else if(iType == COUNTDOWN)
                g_haFreezeTimer[iClient] = CreateTimer(fDuration, UnfreezeCountdown, iClient);
        }
    }
    else {
        g_baFrozen[iClient] = true;
        if(iType == FROSTNADE)
            g_haFreezeTimer[iClient] = CreateTimer(fDuration, Unfreeze, iClient);
        else if(iType == COUNTDOWN)
            g_haFreezeTimer[iClient] = CreateTimer(fDuration, UnfreezeCountdown, iClient);
    }
    if(iType == FROSTNADE && g_bFreezeFade)
        ScreenFade(iClient, FFADE_IN|FFADE_PURGE|FFADE_MODULATE, FREEZE_COLOR, 2, RoundToFloor(fDuration - 0.5));
    else if(iType == COUNTDOWN && g_bCountdownFade)
        ScreenFade(iClient, FFADE_IN|FFADE_PURGE, COUNTDOWN_COLOR, 2, RoundToFloor(fDuration));
}

public Action Unfreeze(Handle hTimer, any iClient)
{
    if(iClient && IsClientInGame(iClient)) {
        if(g_baFrozen[iClient]) {
            SetEntityMoveType(iClient, MOVETYPE_WALK);
            g_baFrozen[iClient] = false;
            g_haFreezeTimer[iClient] = INVALID_HANDLE;
            float faCoord[3];
            GetClientEyePosition(iClient, faCoord);
            EmitAmbientSound(SOUND_UNFREEZE, faCoord, iClient, 55);
            if(IsPlayerAlive(iClient))
                PrintToChat(iClient, "  \x04[HNS] %t", "Unfreeze");
        }
    }
    return Plugin_Continue;
}

public Action UnfreezeCountdown(Handle hTimer, any iClient)
{
    if(iClient && IsClientInGame(iClient)) {
        SetEntityMoveType(iClient, MOVETYPE_WALK);
        g_baFrozen[iClient] = false;
        g_haFreezeTimer[iClient] = INVALID_HANDLE;
        if(IsPlayerAlive(iClient) && !g_bRespawnMode)
            PrintToChat(iClient, "  \x04[HNS] %t", "Round Start");
    }
    return Plugin_Continue;
}

stock void SilentUnfreeze(int iClient)
{
    g_baFrozen[iClient] = false;
    SetEntityMoveType(iClient, MOVETYPE_WALK);
    if(g_haFreezeTimer[iClient] != INVALID_HANDLE) {
        KillTimer(g_haFreezeTimer[iClient]);
        g_haFreezeTimer[iClient] = INVALID_HANDLE;
    }
    ScreenFade(iClient);
}

stock void CreateBeamFollow(int iEntity, int iSprite, int iaColor[4] = {0, 0, 0, 255})
{
    TE_SetupBeamFollow(iEntity, iSprite, 0, 1.5, 3.0, 3.0, 2, iaColor);
    TE_SendToAll();
}

stock void CreateGlowSprite(int iSprite, const float faCoord[3], const float fDuration)
{
    TE_SetupGlowSprite(faCoord, iSprite, fDuration, 2.2, 180);
    TE_SendToAll();
}

stock void LightCreate(float faCoord[3], float fDuration)   
{  
    int iEntity = CreateEntityByName("light_dynamic");
    DispatchKeyValue(iEntity, "inner_cone", "0");
    DispatchKeyValue(iEntity, "cone", "90");
    DispatchKeyValue(iEntity, "brightness", "1");
    DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
    DispatchKeyValue(iEntity, "pitch", "90");
    DispatchKeyValue(iEntity, "style", "1");
    DispatchKeyValue(iEntity, "_light", "20 63 255 255");
    DispatchKeyValueFloat(iEntity, "distance", 150.0);

    DispatchSpawn(iEntity);
    TeleportEntity(iEntity, faCoord, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(iEntity, "TurnOn");
    CreateTimer(fDuration, DeleteEntity, iEntity, TIMER_FLAG_NO_MAPCHANGE);
}

stock void SetClientFrags(int iClient, int iFrags)
{
    SetEntProp(iClient, Prop_Data, "m_iFrags", iFrags);
}

public Action DeleteEntity(Handle hTimer, any iEntity)
{
    if(IsValidEdict(iEntity))
        AcceptEntityInput(iEntity, "kill");
}

stock int GetTeamPlayerCount(int iTeam)
{
    int iCount = 0;
    for(int iClient = 1; iClient <= MaxClients; iClient++)
        if(IsClientInGame(iClient))
            if(GetClientTeam(iClient) == iTeam)
                iCount++;
    return iCount;
}

void DealDamage(int iVictim, int iDamage, int iAttacker = 0, int iDmgType = DMG_GENERIC, char[] sWeapon = "")
{
    // thanks to pimpinjuice
    if(iVictim>0 && IsValidEdict(iVictim) && IsClientInGame(iVictim) && IsPlayerAlive(iVictim) && iDamage > 0)
    {
        char sDmg[16];
        IntToString(iDamage, sDmg, 16);
        char sDmgType[32];
        IntToString(iDmgType, sDmgType, 32);
        int iPointHurt = CreateEntityByName("point_hurt");
        if(iPointHurt)
        {
            DispatchKeyValue(iVictim, "targetname", "war3_hurtme");
            DispatchKeyValue(iPointHurt, "DamageTarget", "war3_hurtme");
            DispatchKeyValue(iPointHurt, "Damage", sDmg);
            DispatchKeyValue(iPointHurt, "DamageType", sDmgType);
            if(!StrEqual(sWeapon, ""))
            {
                DispatchKeyValue(iPointHurt, "classname", sWeapon);
            }
            DispatchSpawn(iPointHurt);
            AcceptEntityInput(iPointHurt, "Hurt", (iAttacker > 0) ? iAttacker : -1);
            DispatchKeyValue(iPointHurt, "classname", "point_hurt");
            DispatchKeyValue(iVictim, "targetname", "war3_donthurtme");
            RemoveEdict(iPointHurt);
        }
    }
}

public Action RemoveRadar(Handle hTimer, any iClient)
{
    if (!g_bHideRadar)
        return;
    if (!IsClientInGame(iClient))
        return;
    if(StrContains(g_sGameDirName, "csgo") != -1)
        SetEntProp(iClient, Prop_Send, "m_iHideHUD", GetEntProp(iClient, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
    else
        if(StrContains(g_sGameDirName, "cstrike") != -1) {
            SetEntPropFloat(iClient, Prop_Send, "m_flFlashDuration", 3600.0);
            SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);
        }
}

public void OnPlayerFlash_Post(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    int iId = hEvent.GetInt("userid");
    int iClient = GetClientOfUserId(iId);
    if(iClient && GetClientTeam(iClient) > CS_TEAM_SPECTATOR) {
        float fDuration = GetEntPropFloat(iClient, Prop_Send, "m_flFlashDuration");
        CreateTimer(fDuration, RemoveRadar, iClient);
    }
}

public void OnPlayerTeam(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    int iId = hEvent.GetInt("userid");
    int iClient = GetClientOfUserId(iId);
    if(!g_bEnabled) {
        g_baWelcomeMsgShown[iClient] = true;
    }
    if(g_bWelcomeMessage && !g_baWelcomeMsgShown[iClient]) {
        g_baWelcomeMsgShown[iClient] = true;
        WriteWelcomeMessage(iClient);
    }
}

public void WriteWelcomeMessage(int iClient)
{
    PrintToChat(iClient, "  \x04[HNS] %t", "Welcome Msg", PLUGIN_VERSION, AUTHOR, g_bRespawnMode ? "Respawn Mode" : "Normal Mode");
}

public Action RemoveRespawnProtection(Handle hTimer, any iClient)
{
    g_haRespawnProtectionTimer[iClient] = INVALID_HANDLE;
    g_baRespawnProtection[iClient] = false;
}

public Action OnPlayerHurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    int iId = hEvent.GetInt("userid");
    int iClient = GetClientOfUserId(iId);
    int iAttackerId = hEvent.GetInt("attacker");
    int iAttackerClient = GetClientOfUserId(iAttackerId);
    
    if(g_baRespawnProtection[iClient] && iAttackerClient != 0) {
        bDontBroadcast = true
        return Plugin_Changed;
    }
    return Plugin_Continue;
}
