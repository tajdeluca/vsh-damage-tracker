#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <saxtonhale>

#pragma newdecls required

//For damage tracking...
int g_iDamage[MAXPLAYERS+1];
int g_iRGBA[MAXPLAYERS+1][4];
int g_iDamageTracker[MAXPLAYERS+1];
Handle g_hDamageHUD;

#define RED 0
#define GREEN 1
#define BLUE 2
#define ALPHA 3

public Plugin myinfo = {
	name = "Versus Saxton Hale Damage Tracker",
	author = "Aurora",
	description = "A live damage tracker for Versus Saxton Hale. Like the one that appears at the end of the round!",
	version = "1.1",
	url = "http://tajdeluca.com"
};

bool g_iLate = false;
 
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_iLate = true;
	return APLRes_Success;
}

/**
 * On Plugin Start we want to register the command, create the advertisement and set up the HUD
 */
public void OnPluginStart()
{
	RegConsoleCmd("haledmg", Command_damagetracker, "haledmg - Enable/disable the damage tracker.");
	CreateTimer(0.1, Timer_Millisecond);
	CreateTimer(180.0, Timer_Advertise);
	g_hDamageHUD = CreateHudSynchronizer();

	if(g_iLate)
	{
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				InitDamageTracker(i);
			}
        }
	}
}

/**
 * On Plugin End we want to close the HUD handle
 */
public void OnPluginEnd()
{
	g_hDamageHUD.Close();
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

		if (g_iDamageTracker[client] == 0)
		{
			playersetting = "Off";
		}

		if (g_iDamageTracker[client] > 0) 
		{
			playersetting = "On";
		}

		CPrintToChat(client, "{olive}[VSH]{default} The damage tracker is {olive}%s{default}.\n{olive}[VSH]{default} Change it by saying \"!haledmg on [R] [G] [B] [A]\" or \"!haledmg off\"!", playersetting);
		return Plugin_Handled;
	}

	char arg1[64];
	int newval = 3;

	GetCmdArg(1, arg1, sizeof(arg1));

	if (StrEqual(arg1,"off",false)) 
	{
		g_iDamageTracker[client] = 0;
	}

	if (StrEqual(arg1,"on",false)) 
	{
		g_iDamageTracker[client] = 3;
	}

	if (StrEqual(arg1,"0",false)) 
	{
		g_iDamageTracker[client] = 0;
	}

	if (StrEqual(arg1,"of",false)) 
	{
		g_iDamageTracker[client] = 0;
	}

	if (!StrEqual(arg1,"off",false) && !StrEqual(arg1,"on",false) && !StrEqual(arg1,"0",false) && !StrEqual(arg1,"of",false))
	{
		newval = StringToInt(arg1);
		char newSetting[3];

		if (newval > 8) 
		{
			newval = 8;
		}

		if (newval > 0) 
		{
			g_iDamageTracker[client] = newval;
			newSetting = "on";
		}
		else
		{
			newSetting = "off";
		}

		CPrintToChat(client, "{olive}[VSH]{default} The damage tracker is now {lightgreen}%s{default}!", newSetting);
	}
	
	char r[4], g[4], b[4], a[4];
	
	if(args >= 2)
	{
		GetCmdArg(2, r, sizeof(r));

		if(!StrEqual(r, "_"))
		{
			g_iRGBA[client][RED] = StringToInt(r);
		}
	}
	
	if(args >= 3)
	{
		GetCmdArg(3, g, sizeof(g));

		if(!StrEqual(g, "_"))
		{
			g_iRGBA[client][GREEN] = StringToInt(g);
		}
	}
	
	if(args >= 4)
	{
		GetCmdArg(4, b, sizeof(b));

		if(!StrEqual(b, "_"))
		{
			g_iRGBA[client][BLUE] = StringToInt(b);
		}
	}
	
	if(args >= 5)
	{
		GetCmdArg(5, a, sizeof(a));

		if(!StrEqual(a, "_"))
		{
			g_iRGBA[client][ALPHA] = StringToInt(a);
		}
	}
	
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	InitDamageTracker(client);
}

public Action Timer_Millisecond(Handle timer)
{
	CreateTimer(0.1, Timer_Millisecond);

	g_iDamage[0] = 0;

	for(int i=1; i <= GetMaxClients(); i++)
	{
		g_iDamage[i] = VSH_GetClientDamage(i);
	}
	
	int top[8];

	// Sort the damage
	for (int i=0; i <= MaxClients; i++)
	{
		if (g_iDamage[i] >= g_iDamage[top[0]])
		{
			top[7] = top[6];
			top[6] = top[5];
			top[5] = top[4];
			top[4] = top[3];
			top[3] = top[2];
			top[2] = top[1];
			top[1] = top[0];
			top[0] = i;
		}
		else if (g_iDamage[i] >= g_iDamage[top[1]])
		{
			top[7] = top[6];
			top[6] = top[5];
			top[5] = top[4];
			top[4] = top[3];
			top[3] = top[2];
			top[2] = top[1];
			top[1] = i;
		}
		else if (g_iDamage[i] >= g_iDamage[top[2]])
		{
			top[7] = top[6];
			top[6] = top[5];
			top[5] = top[4];
			top[4] = top[3];
			top[3] = top[2];
			top[2] = i;
		}
		else if (g_iDamage[i] >= g_iDamage[top[3]])
		{
			top[7] = top[6];
			top[6] = top[5];
			top[5] = top[4];
			top[4] = top[3];
			top[3] = i;
		}
		else if (g_iDamage[i] >= g_iDamage[top[4]])
		{
			top[7] = top[6];
			top[6] = top[5];
			top[5] = top[4];
			top[4] = i;
		}
		else if (g_iDamage[i] >= g_iDamage[top[5]])
		{
			top[7] = top[6];
			top[6] = top[5];
			top[5] = i;
		}
		else if (g_iDamage[i] >= g_iDamage[top[6]])
		{
			top[7] = top[6];
			top[6] = i;
		}
		else if (g_iDamage[i] >= g_iDamage[top[7]])
		{
			top[7] = i;
		}
	}

	int boss = GetClientOfUserId(VSH_GetSaxtonHaleUserId());

	for (int z=1; z <= GetMaxClients(); z++)
	{
		if (IsValidClient(z) && g_iDamageTracker[z] > 0)
		{
			if (boss != z) // client is not Hale
			{
				SetHudTextParams(0.0, 0.0, 0.3, g_iRGBA[z][RED], g_iRGBA[z][GREEN], g_iRGBA[z][BLUE], g_iRGBA[z][ALPHA]);

				char first[64], second[64], third[64], fourth[64], fifth[64], sixth[64], seventh[64], eighth[64];

				if(IsValidClient(top[0]))
				{
					Format(first, sizeof(first), "[1] %N - %d\n", top[0], g_iDamage[top[0]]);
				}
				else
				{
					Format(first, sizeof(first), "[1] N/A - 0\n");
				}

				// From here, every extra one is optional! (Up to 8)

				// Second
				if(g_iDamageTracker[z] >= 2)
				{
					if(IsValidClient(top[1]))
					{
						Format(second, sizeof(second), "[2] %N - %d\n", top[1], g_iDamage[top[1]]);
					}
					else
					{
						Format(second, sizeof(second), "[2] N/A - 0\n");
					}
				}
				else
				{
					Format(second, sizeof(second), "");
				}

				// Third
				if(g_iDamageTracker[z] >= 3)
				{
					if(IsValidClient(top[2]))
					{
						Format(third, sizeof(third), "[3] %N - %d\n", top[2], g_iDamage[top[2]]);
					}
					else
					{
						Format(third, sizeof(third), "[3] N/A - 0\n");
					}
				}
				else
				{
					Format(third, sizeof(third), "");
				}

				// Fourth
				if(g_iDamageTracker[z] >= 4)
				{
					if(IsValidClient(top[3]))
					{
						Format(fourth, sizeof(fourth), "[4] %N - %d\n", top[3], g_iDamage[top[3]]);
					}
					else
					{
						Format(fourth, sizeof(fourth), "[4] N/A - 0\n");
					}
				}
				else
				{
					Format(fourth, sizeof(fourth), "");
				}

				// Fifth
				if(g_iDamageTracker[z] >= 5)
				{
					if(IsValidClient(top[4]))
					{
						Format(fifth, sizeof(fifth), "[5] %N - %d\n", top[4], g_iDamage[top[4]]);
					}
					else
					{
						Format(fifth, sizeof(fifth), "[5] N/A - 0\n");
					}
				}
				else
				{
					Format(fifth, sizeof(fifth), "");
				}

				// Sixth
				if(g_iDamageTracker[z] >= 6)
				{
					if(IsValidClient(top[5]))
					{
						Format(sixth, sizeof(sixth), "[6] %N - %d\n", top[5], g_iDamage[top[5]]);
					}
					else
					{
						Format(sixth, sizeof(sixth), "[6] N/A - 0\n");
					}
				}
				else
				{
					Format(sixth, sizeof(sixth), "");
				}

				// Seventh
				if(g_iDamageTracker[z] >= 7)
				{
					if(IsValidClient(top[6]))
					{
						Format(seventh, sizeof(seventh), "[7] %N - %d\n", top[6], g_iDamage[top[6]]);
					}
					else
					{
						Format(seventh, sizeof(seventh), "[7] N/A - 0\n");
					}
				}
				else
				{
					Format(seventh, sizeof(seventh), "");
				}

				// Eighth
				if(g_iDamageTracker[z] >= 8)
				{
					if(IsValidClient(top[7]))
					{
						Format(eighth, sizeof(eighth), "[8] %N - %d\n", top[7], g_iDamage[top[7]]);
					}
					else
					{
						Format(eighth, sizeof(eighth), "[8] N/A - 0\n");
					}
				}
				else
				{
					Format(eighth, sizeof(eighth), "");
				}

				ShowSyncHudText(z, g_hDamageHUD, "%s%s%s%s%s%s%s%s", first, second, third, fourth, fifth, sixth, seventh, eighth);
			}
		}
	}
	return Plugin_Handled;
}

stock bool IsValidClient(int client, bool nobots=false)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }

    return IsClientInGame(client); 
}  

stock void InitDamageTracker(int client)
{
	g_iDamageTracker[client] = 0;
	g_iRGBA[client][RED] = 255;
	g_iRGBA[client][GREEN] = 255;
	g_iRGBA[client][BLUE] = 255;
	g_iRGBA[client][ALPHA] = 255;
}