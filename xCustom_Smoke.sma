/*
_____/\\\\\\\\\_____/\\\\____________/\\\\__/\\\_______/\\\__/\\\_______/\\\________________/\\\\\\\\\\\\\_______/\\\\\\\\\\\\_        
 ___/\\\\\\\\\\\\\__\/\\\\\\________/\\\\\\_\///\\\___/\\\/__\///\\\___/\\\/________________\/\\\/////////\\\___/\\\//////////__       
  __/\\\/////////\\\_\/\\\//\\\____/\\\//\\\___\///\\\\\\/______\///\\\\\\/__________________\/\\\_______\/\\\__/\\\_____________      
   _\/\\\_______\/\\\_\/\\\\///\\\/\\\/_\/\\\_____\//\\\\__________\//\\\\_______/\\\\\\\\\\\_\/\\\\\\\\\\\\\\__\/\\\____/\\\\\\\_     
    _\/\\\\\\\\\\\\\\\_\/\\\__\///\\\/___\/\\\______\/\\\\___________\/\\\\______\///////////__\/\\\/////////\\\_\/\\\___\/////\\\_    
     _\/\\\/////////\\\_\/\\\____\///_____\/\\\______/\\\\\\__________/\\\\\\___________________\/\\\_______\/\\\_\/\\\_______\/\\\_   
      _\/\\\_______\/\\\_\/\\\_____________\/\\\____/\\\////\\\______/\\\////\\\_________________\/\\\_______\/\\\_\/\\\_______\/\\\_  
       _\/\\\_______\/\\\_\/\\\_____________\/\\\__/\\\/___\///\\\__/\\\/___\///\\\_______________\/\\\\\\\\\\\\\/__\//\\\\\\\\\\\\/__ 
        _\///________\///__\///______________\///__\///_______\///__\///_______\///________________\/////////////_____\////////////____
					__/\\\________/\\\_______________________________/\\\______________________________________                                            
					 _\/\\\_______\/\\\______________________________\/\\\______________________________________                                           
					  _\/\\\_______\/\\\______________________________\/\\\______________________________________                                          
					   _\/\\\\\\\\\\\\\\\__/\\\____/\\\_____/\\\\\\\\__\/\\\__________/\\\____/\\\_____/\\\\\\\\__                                         
					    _\/\\\/////////\\\_\/\\\___\/\\\___/\\\/////\\\_\/\\\\\\\\\\__\/\\\___\/\\\___/\\\/////\\\_                                        
					     _\/\\\_______\/\\\_\/\\\___\/\\\__/\\\\\\\\\\\__\/\\\/////\\\_\/\\\___\/\\\__/\\\\\\\\\\\__                                       
					      _\/\\\_______\/\\\_\/\\\___\/\\\_\//\\///////___\/\\\___\/\\\_\/\\\___\/\\\_\//\\///////___                                      
					       _\/\\\_______\/\\\_\//\\\\\\\\\___\//\\\\\\\\\\_\/\\\___\/\\\_\//\\\\\\\\\___\//\\\\\\\\\\_                                     
					        _\///________\///___\/////////_____\//////////__\///____\///___\/////////_____\//////////__
*/


#include <amxmodx>

/* Common include libraries */
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <reapi>


new const g_szClassname[] = "xcustom_smokenade"

new g_IsInSmoke[MAX_PLAYERS + 1]

enum eCVars
{
	COLOR_SMOKE[MAX_NAME_LENGTH],
	Float:RADIUS,
	Float:SPEED_INSIDE,
	Float:DAMAGE_IN_SMOKE,
	TEAM_SLOWED[MAX_NAME_LENGTH],
	SPRITE_DEPTH_INNER,
	SPRITE_DEPTH_OUT
}

new g_eCvars[eCVars]

enum _:SpriteColors
{
	RED = 0,
	GREEN,
	BLUE,
	YELLOW,
	ORANGE,
	MAGENTA,
	WHITE,
	GRAY,
	BLACK
}

new g_szSmokeSprite[SpriteColors]

new Float:g_flOrigin[3]


public plugin_init()
{
	register_plugin("xCustom Smoke Nades", "1.5", "Huehue")
	
	register_forward(FM_EmitSound, "FM__EmitSound")
	register_touch(g_szClassname, "worldspawn", "Touch_CustomSmoke")
	register_think(g_szClassname, "Think_CustomSmoke")

	new pCvar

	pCvar = create_cvar("csn_sprite_color", "Random", FCVAR_NONE, "Color type^nColors:^nDefault = Normal smoke | Random = Random color every smoke^nCustom Colors:^nRed | Green | Blue | Yellow | Orange | Magenta | White | Gray | Black")
	bind_pcvar_string(pCvar, g_eCvars[COLOR_SMOKE], charsmax(g_eCvars[COLOR_SMOKE]))
	pCvar = create_cvar("csn_sprite_radius", "150.0", FCVAR_NONE, "At what radius team chosen will be slowed inside the smoke")
	bind_pcvar_float(pCvar, g_eCvars[RADIUS])
	pCvar = create_cvar("csn_sprite_speed_inside", "100.0", FCVAR_NONE, "The maximum speed player will have in smoke if its chosen to be slowed")
	bind_pcvar_float(pCvar, g_eCvars[SPEED_INSIDE])
	pCvar = create_cvar("csn_sprite_damage_in_smoke", "3.0", FCVAR_NONE, "The damage player will take in smoke^nMinimum to work is 3.0 | Under 3.0 it will stop working")
	bind_pcvar_float(pCvar, g_eCvars[DAMAGE_IN_SMOKE])
	pCvar = create_cvar("csn_sprite_team_slow", "Any", FCVAR_NONE, "Which team will be slowed^nCT = Counter-Terrorist^nT = Terrorists^nAny = Both Teams")
	bind_pcvar_string(pCvar, g_eCvars[TEAM_SLOWED], charsmax(g_eCvars[TEAM_SLOWED]))
	pCvar = create_cvar("csn_sprite_depth_in", "400", FCVAR_NONE, "How many sprites will be shown after smoke explodes in the inner circle")
	bind_pcvar_num(pCvar, g_eCvars[SPRITE_DEPTH_INNER])
	pCvar = create_cvar("csn_sprite_depth_out", "550", FCVAR_NONE, "How many sprites will be shown after smoke explodes in the range")
	bind_pcvar_num(pCvar, g_eCvars[SPRITE_DEPTH_OUT])

	AutoExecConfig(true, "xCustom_Smoke", "HuehuePlugins_Config")

	set_task_ex(1.0, "ThinkingEntity", .flags = SetTask_Repeat)
}

public plugin_precache()
{
	g_szSmokeSprite[RED] = precache_model("sprites/xcustom_smoke/gas_puff_red.spr")
	g_szSmokeSprite[GREEN] = precache_model("sprites/xcustom_smoke/gas_puff_green.spr")
	g_szSmokeSprite[BLUE] = precache_model("sprites/xcustom_smoke/gas_puff_blue.spr")
	g_szSmokeSprite[YELLOW] = precache_model("sprites/xcustom_smoke/gas_puff_yellow.spr")
	g_szSmokeSprite[ORANGE] = precache_model("sprites/xcustom_smoke/gas_puff_orange.spr")
	g_szSmokeSprite[MAGENTA] = precache_model("sprites/xcustom_smoke/gas_puff_magenta.spr")
	g_szSmokeSprite[WHITE] = precache_model("sprites/xcustom_smoke/gas_puff_white.spr")
	g_szSmokeSprite[GRAY] = precache_model("sprites/xcustom_smoke/gas_puff_gray.spr")
	g_szSmokeSprite[BLACK] = precache_model("sprites/xcustom_smoke/gas_puff_black.spr")

	precache_sound("weapons/grenade_hit1.wav")
}

public ThinkingEntity()
{
	new iEntity
	while((iEntity = find_ent_by_class(iEntity, g_szClassname)) != 0)
	{
		new Float:vOrigin[3], iOwner = entity_get_edict(iEntity, EV_ENT_owner)
		entity_get_vector(iEntity, EV_VEC_origin, vOrigin)
		vOrigin[2] = vOrigin[2] + 50

		if (!is_valid_ent(iEntity))
			return

		new iPlayers[MAX_PLAYERS], iNum, id, iEnt
		iNum = find_sphere_class(iEntity, "player", g_eCvars[RADIUS], iPlayers, sizeof iPlayers, vOrigin)

		for (--iNum; iNum >= 0; iNum--)
		{
			id = iPlayers[iNum]

			while((iEnt = find_ent_in_sphere(iEnt, vOrigin, g_eCvars[RADIUS])) != 0)
			{
				if (g_eCvars[TEAM_SLOWED][0] == 'T' && get_user_team(id) == 1 || g_eCvars[TEAM_SLOWED][0] == 'C' && get_user_team(id) == 2 || g_eCvars[TEAM_SLOWED][0] == 'A' && get_user_team(id) != 3)
				{
					g_IsInSmoke[id] = true
					entity_set_float(id, EV_FL_maxspeed, g_eCvars[SPEED_INSIDE])
					set_task_ex(1.5, "CheckSpeed", id)
					if (g_eCvars[DAMAGE_IN_SMOKE] >= 3.0)
						rg_dmg_radius(vOrigin, id, iOwner, g_eCvars[DAMAGE_IN_SMOKE], g_eCvars[RADIUS], 0, DMG_NERVEGAS)
				}
			}
			g_IsInSmoke[id] = false
		}
	}
}

public CheckSpeed(id)
{
	if (!g_IsInSmoke[id])
	{
		entity_set_float(id, EV_FL_maxspeed, 250.0)
	}
}
public FM__EmitSound(iOriginEntity, iChannel, const szSample[], Float:fVol, Float:fAttn, iFlags, iPitch)
{
	if (equal(g_eCvars[COLOR_SMOKE], "Default"))
		return

	static const szSmokeSound[] = "weapons/sg_explode.wav"

	if (equal(szSample, szSmokeSound))
	{
		// Lets cache some stuff like origins, angles, and model
		new Float:vOrigin[3], Float:vAngles[3], szModel[MAX_NAME_LENGTH * 2]//, iOwner
		//iOwner = entity_get_edict(iOriginEntity, EV_ENT_owner)
		entity_get_vector(iOriginEntity, EV_VEC_origin, vOrigin)
		entity_get_vector(iOriginEntity, EV_VEC_angles, vAngles)
		entity_get_string(iOriginEntity, EV_SZ_model, szModel, charsmax(szModel))

		// Lets remove the original entity from the world..
		entity_set_vector(iOriginEntity, EV_VEC_origin, Float:{ 9999.9, 9999.9, 9999.9 })
		entity_set_int(iOriginEntity, EV_INT_flags, FL_KILLME)

		// After we deleted the original entity, lets create new one..
		new iEntity = create_entity("info_target")

		if (iEntity > 0)
		{
			entity_set_string(iEntity, EV_SZ_classname, g_szClassname)
				
			entity_set_origin(iEntity, vOrigin)
			g_flOrigin[0] = vOrigin[0]
			g_flOrigin[1] = vOrigin[1]
			g_flOrigin[2] = vOrigin[2] + 50
			entity_set_vector(iEntity, EV_VEC_angles, vAngles)
				
			entity_set_int(iEntity, EV_INT_movetype, MOVETYPE_TOSS)
			entity_set_int(iEntity, EV_INT_solid, SOLID_BBOX)
				
			entity_set_float(iEntity, EV_FL_nextthink, get_gametime() + 21.5)
			entity_set_float(iEntity, EV_FL_gravity, 0.5)
			entity_set_float(iEntity, EV_FL_friction, 0.8)
				
			entity_set_model(iEntity, szModel)

			new Float:vVelocity[3]
			vVelocity[0] = random_float(-220.0, 220.0)
			vVelocity[1] = random_float(-220.0, 220.0)
			vVelocity[2] = random_float(200.0, 300.0)
			entity_set_vector(iEntity, EV_VEC_velocity, vVelocity)
				
			emit_sound(iEntity, iChannel, szSample, fVol, fAttn, iFlags, iPitch)

			// Create fake smoke
			new iSmoke

			switch(g_eCvars[COLOR_SMOKE][0])
			{
				case 'R':
				{
					if (equal(g_eCvars[COLOR_SMOKE], "Red"))
						iSmoke = RED
					else if (equal(g_eCvars[COLOR_SMOKE], "Random"))
						iSmoke = random_num(RED, BLACK)
				}
				case 'G':
				{
					if (equal(g_eCvars[COLOR_SMOKE], "Green"))
						iSmoke = GREEN
					else if (equal(g_eCvars[COLOR_SMOKE], "Gray"))
						iSmoke = GRAY
				}
				case 'B':
				{
					if (equal(g_eCvars[COLOR_SMOKE], "Blue"))
						iSmoke = BLUE
					else if (equal(g_eCvars[COLOR_SMOKE], "Black"))
						iSmoke = BLACK
				}
				case 'Y': iSmoke = YELLOW
				case 'O': iSmoke = ORANGE
				case 'M': iSmoke = MAGENTA
				case 'W': iSmoke = WHITE
			}
				
			// Store the smoke number in entity, we will use it later
			entity_set_int(iEntity, EV_INT_iuser4, iSmoke)

			// Now lets create fake smoke.
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_FIREFIELD)
			engfunc(EngFunc_WriteCoord, vOrigin[0])
			engfunc(EngFunc_WriteCoord, vOrigin[1])
			engfunc(EngFunc_WriteCoord, vOrigin[2] + 50)
			write_short(100)
			write_short(g_szSmokeSprite[iSmoke])
			write_byte(g_eCvars[SPRITE_DEPTH_INNER]) // Smoke Count (Default: 100) (150)
			write_byte(TEFIRE_FLAG_ALPHA)
			write_byte(1000)
			message_end()
			
			// To make it more deep edit here	
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_FIREFIELD)
			engfunc(EngFunc_WriteCoord, vOrigin[0])
			engfunc(EngFunc_WriteCoord, vOrigin[1])
			engfunc(EngFunc_WriteCoord, vOrigin[2] + 50)
			write_short(150)
			write_short(g_szSmokeSprite[iSmoke])
			write_byte(g_eCvars[SPRITE_DEPTH_OUT]) // Smoke Count (Default: 10)
			write_byte(TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT)
			write_byte(1000)
			message_end()

			new id
			while((id = find_ent_in_sphere(id, vOrigin, g_eCvars[RADIUS])) != 0)
			{
				//if (!is_user_alive(id) || g_eCvars[TEAM_SLOWED][0] != 'T' || g_eCvars[TEAM_SLOWED][0] != 'C' || g_eCvars[TEAM_SLOWED][0] != 'A')
				//	return

				if (g_eCvars[TEAM_SLOWED][0] == 'T' && get_user_team(id) == 1 || g_eCvars[TEAM_SLOWED][0] == 'C' && get_user_team(id) == 2 || g_eCvars[TEAM_SLOWED][0] == 'A' && get_user_team(id) != 3)
					entity_set_float(id, EV_FL_maxspeed, g_eCvars[SPEED_INSIDE])
			}
		}
	}
}

public Touch_CustomSmoke(iEntity, iWorld)
{
	if (!is_valid_ent(iEntity))
		return PLUGIN_CONTINUE
	
	// Bounce hit sound
	emit_sound(iEntity, CHAN_VOICE, "weapons/grenade_hit1.wav", 0.25, ATTN_NORM, 0, PITCH_NORM)
	
	new Float:vVelocity[3]
	entity_get_vector(iEntity, EV_VEC_velocity, vVelocity)
	
	if (vVelocity[1] <= 0.0 && vVelocity[2] <= 0.0)
	{
		new Float:vOrigin[3]
		entity_get_vector(iEntity, EV_VEC_origin, vOrigin)
		entity_set_vector(iEntity, EV_VEC_origin, g_flOrigin)
		set_entity_visibility(iEntity, 0)

		new iSmoke = entity_get_int(iEntity, EV_INT_iuser4)
		
		// Make small smoke near grenade on ground
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_FIREFIELD)
		engfunc(EngFunc_WriteCoord, vOrigin[0])
		engfunc(EngFunc_WriteCoord, vOrigin[1])
		engfunc(EngFunc_WriteCoord, vOrigin[2] + 10)
		write_short(2)
		write_short(g_szSmokeSprite[iSmoke])
		write_byte(2)
		write_byte(TEFIRE_FLAG_ALLFLOAT | TEFIRE_FLAG_ALPHA)
		write_byte(30)
		message_end()
	}
	return PLUGIN_CONTINUE
}

public Think_CustomSmoke(iEntity)
{
	if (!is_valid_ent(iEntity))
		return PLUGIN_CONTINUE
	
	remove_entity(iEntity)
	
	return PLUGIN_CONTINUE
}