#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <saxtonhale>

#pragma newdecls required

//For damage tracking...
int Damage[MAXPLAYERS+1];
int RGBA[MAXPLAYERS+1][4];
int damageTracker[MAXPLAYERS+1];
Handle damageHUD;

#define RED 0
#define GREEN 1
#define BLUE 2
#define ALPHA 3

public Plugin myinfo = {
	name = "Versus Saxton Hale Damage Tracker",
	author = "Aurora",
	description = "A live damage tracker for Versus Saxton Hale. Like the one that appears at the end of the round!",
	version = "1.0",
	url = "http://tajdeluca.com"
};

public void OnPluginStart()
{
	RegConsoleCmd("haledmg", Command_damagetracker, "haledmg - Enable/disable the damage tracker.");
	CreateTimer(0.1, Timer_Millisecond);
	CreateTimer(180.0, Timer_Advertise);
	damageHUD = CreateHudSynchronizer();
}

public void OnPluginEnd()
{
	damageHUD.Close();
}

public Action Timer_Advertise(Handle timer)
{
	CreateTimer(180.0, Timer_Advertise);
	CPrintToChatAll("{olive}[VSH]{default} Type \"!haledmg on\" to display the top 3 players! Type \"!haledmg off\" to turn it off again.");
	return Plugin_Handled;
}

public Action Command_damagetracker(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("[VSH] The damage tracker cannot be enabled by Console.");
		return Plugin_Handled;
	}
	if (args == 0)
	{
		char playersetting[3];
		if (damageTracker[client] == 0) playersetting = "Off";
		if (damageTracker[client] > 0) playersetting = "On";
		CPrintToChat(client, "{olive}[VSH]{default} The damage tracker is {olive}%s{default}.\n{olive}[VSH]{default} Change it by saying \"!haledmg on [R] [G] [B] [A]\" or \"!haledmg off\"!", playersetting);
		return Plugin_Handled;
	}
	char arg1[64];
	int newval = 3;
	GetCmdArg(1, arg1, sizeof(arg1));
	if (StrEqual(arg1,"off",false)) damageTracker[client] = 0;
	if (StrEqual(arg1,"on",false)) damageTracker[client] = 3;
	if (StrEqual(arg1,"0",false)) damageTracker[client] = 0;
	if (StrEqual(arg1,"of",false)) damageTracker[client] = 0;
	if (!StrEqual(arg1,"off",false) && !StrEqual(arg1,"on",false) && !StrEqual(arg1,"0",false) && !StrEqual(arg1,"of",false))
	{
		newval = StringToInt(arg1);
		char newsetting[3];
		if (newval > 8) newval = 8;
		if (newval != 0) damageTracker[client] = newval;
		if (newval != 0 && damageTracker[client] == 0) newsetting = "off";
		if (newval != 0 && damageTracker[client] > 0) newsetting = "on";
		CPrintToChat(client, "{olive}[VSH]{default} The damage tracker is now {lightgreen}%s{default}!", newsetting);
	}
	
	char r[4], g[4], b[4], a[4];
	
	if(args >= 2)
	{
		GetCmdArg(2, r, sizeof(r));
		if(!StrEqual(r, "_"))
			RGBA[client][RED] = StringToInt(r);
	}
	
	if(args >= 3)
	{
		GetCmdArg(3, g, sizeof(g));
		if(!StrEqual(g, "_"))
			RGBA[client][GREEN] = StringToInt(g);
	}
	
	if(args >= 4)
	{
		GetCmdArg(4, b, sizeof(b));
		if(!StrEqual(b, "_"))
			RGBA[client][BLUE] = StringToInt(b);
	}
	
	if(args >= 5)
	{
		GetCmdArg(5, a, sizeof(a));
		if(!StrEqual(a, "_"))
			RGBA[client][ALPHA] = StringToInt(a);
	}
	
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	damageTracker[client] = 0;
	RGBA[client][RED] = 255;
	RGBA[client][GREEN] = 255;
	RGBA[client][BLUE] = 255;
	RGBA[client][ALPHA] = 255;
}

public Action Timer_Millisecond(Handle timer)
{
	CreateTimer(0.1, Timer_Millisecond);
	for(int i=1; i<=GetMaxClients(); i++)
	{
		Damage[i] = VSH_GetClientDamage(i);
	}
	
	int top[3];
	Damage[0] = 0;
	for (int i = 0; i <= MaxClients; i++)
	{
		if (Damage[i] >= Damage[top[0]])
		{
			top[2]=top[1];
			top[1]=top[0];
			top[0]=i;
		}
		else if (Damage[i] >= Damage[top[1]])
		{
			top[2]=top[1];
			top[1]=i;
		}
		else if (Damage[i] >= Damage[top[2]])
		{
			top[2]=i;
		}
	}
	for (int z = 1; z <= GetMaxClients(); z++)
	{
		if (IsValidClient(z) && damageTracker[z] > 0)
		{
			int a_index = GetClientOfUserId(VSH_GetSaxtonHaleUserId());
			if (a_index != z) // client is not Hale
			{
				SetHudTextParams(0.0, 0.0, 0.2, RGBA[z][RED], RGBA[z][GREEN], RGBA[z][BLUE], RGBA[z][ALPHA]);
				char first[64], second[64], third[64];
				if(IsValidClient(top[0]))
					Format(first, sizeof(first), "[1] %N - %d\n", top[0], Damage[top[0]]);
				else
					Format(first, sizeof(first), "[1] N/A - 0\n");
				if(IsValidClient(top[1]))
					Format(second, sizeof(second), "[2] %N - %d\n", top[1], Damage[top[1]]);
				else
					Format(second, sizeof(second), "[2] N/A - 0\n");
				if(IsValidClient(top[2]))
					Format(third, sizeof(third), "[3] %N - %d\n", top[2], Damage[top[2]]);
				else
					Format(third, sizeof(third), "[3] N/A - 0\n");
				ShowSyncHudText(z, damageHUD, "%s%s%s", first, second, third);
			}
		}
	}
	return Plugin_Handled;
}

stock bool IsValidClient(int client, bool nobots=true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }

    return IsClientInGame(client); 
}  
