#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define pAuthor "ijre"
#define pName    "Remove Weapons"
#define pDesc    "Remove a single target's weapons, or remove everyone's."
#define pVersion    "1.0.0"
#define pURL        "https://github.com/ijre/Remove-Weapons"

public Plugin:myinfo = {name = pName, author = pAuthor, description = pDesc, version = pVersion, url = pURL}

static bool allWepsRemoved = false;
static bool:removedWepsBool[MAXPLAYERS] = false;
static bool:removedWepsExempt[MAXPLAYERS] = false;

public OnPluginStart()
{
	RegAdminCmd("rw", removeWeps, (1<<14), "Toggle. Add individuals or leave empty to select everyone.");
	RegAdminCmd("removeWeps", removeWeps, (1<<14), "Add individuals or leave empty to select everyone.");
}
public OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || IsClientReplay(i) || IsClientSourceTV(i))
			continue;
		
		if(allWepsRemoved || removedWepsBool[i])
			TF2_RegeneratePlayer(i);
	}
}



public Action removeWeps(int client, int args)
{
	if(args == 0)
	{
		if(!allWepsRemoved)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientConnected(i) || IsClientReplay(i) || IsClientSourceTV(i))
				continue;
				
				TF2_RemoveAllWeapons(i);
				removedWepsBool[i] = true;
			}
			allWepsRemoved = true;
			PrintToChatAll("Removed weapons from everyone");
		}
		else
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientConnected(i) || IsClientReplay(i) || IsClientSourceTV(i))
				continue;
				
				TF2_RegeneratePlayer(i);
				removedWepsBool[i] = false;
			}
			allWepsRemoved = false;
			PrintToChatAll("Returned weapons to everyone");
		}
		return Plugin_Handled;
	}
	else if(args >= 1)
	{
		new String:argBuff[127];
		GetCmdArg(1, argBuff,sizeof(argBuff));
		new target = FindTarget(client, argBuff, false, true);
		
		if(!IsClientConnected(target) || IsClientReplay(target) || IsClientSourceTV(target))
		{
			ReplyToCommand(client, "Invalid Target");
			return Plugin_Stop;
		}
		
		if(!removedWepsBool[target])
		{
			new String:reply[127] = "[SM] Removed weapons from ";
			GetClientName(target, reply[26], sizeof(reply) - 26);
			
			TF2_RemoveAllWeapons(target);
			removedWepsBool[target] = true;
			removedWepsExempt[target] = false;
			ReplyToCommand(client, reply);
		}
		else
		{
			new String:reply[127] = "[SM] Returned weapons to ";
			GetClientName(target, reply[25], sizeof(reply) - 25);
			
			TF2_RegeneratePlayer(target);
			removedWepsBool[target] = false;
			removedWepsExempt[target] = true;
			ReplyToCommand(client, reply)
		}
		
		return Plugin_Handled;
	}
	else return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client) // LOOP FOR JOINING PLAYERS AND PEOPLE TIMING OUT
{
	if(!IsClientConnected(client) || IsClientReplay(client) || IsClientSourceTV(client))
		return Plugin_Continue;
	
	if(!removedWepsExempt[client] && (allWepsRemoved || removedWepsBool[client]) && IsPlayerAlive(client))
		if(GetPlayerWeaponSlot(client, 1) != -1)
		{
			TF2_RemoveAllWeapons(client);
			removedWepsBool[client] = true;
		}
	
	return Plugin_Continue;
}