--[[
* A system made by Quang and Zealot for DarkRP
* https://steamcommunity.com/id/NSGQuang/
* https://steamcommunity.com/id/thezealot35/
* 
* Notes:
* 
* There is no UI to the system, just a simple command
* /rob, /mug or /pickpocket
* when you perform the command, you can specify a percent of cash to take:
* /mug 20 will take 20% of your targets' total cash, 35 will do 35% and so on (not exceeding 15k) (also not exceeding 40%)
* if you are dead, the pickpocketing will not occur
* if you are far away, the pickpocketing will not occur
* 
* 
--]]

local DefaultPercent = 10 --added to ply.PPS_Percent to create the chance you are caught (PPS_Percent = 20? chance to get caught = 30%)
local DefaultTime = 30 --default cooldown

local ThingsToSay = { --things that you will say if you rob someone...
	[0]="*Coughs Nervously*",
	[1]="*Bumps into you* Sorry...",
	[2]="Excuse me... Passing through...",
	[3]="..."
}

hook.Add( "PlayerInitialSpawn", "Pickpocket_System_Initialize", function(ply) --add variables to each player as they join
	ply.PPS_Timer = 0 --the variable that controls how long you have until you have completely pickpocketed someone
	ply.PPS_Pocketing = false --the variable that controls if you are pickpocketing (see more below)
	ply.PPS_Percent = 0 --the percent of cash you will steal
	ply.RobCD = 0 --the total cooldown before you can perform the command again
end )

local function RobPlayer(ply, args) --first round for system, ran when we commit the robbery.
	--args is the percent used for ply.PPS_Percent (read above)
	--ply is the player performing the command
	local i = math.random(0, #ThingsToSay) --used in line 86
	if args == "" or not tonumber(args) then args = 10 end
	if ( tonumber(args) > 40 ) then 
		args = 40 
		DarkRP.notify(ply, 2, 4, "You can't take more than 40%! Auto-set to 40%.")
	end
	if ( tonumber(args) < 0 ) then DarkRP.notify(ply, 2, 4, "You can't put money in pockets! That's not evil!") return "" end
    local Target = ply:GetEyeTrace().Entity --the player we are going to steal from
    local playerdistance = ply:EyePos():DistToSqr(Target:GetPos()) --the distance you are from that player (really stupid number, see line 55)
    if not Target:IsPlayer() then return end --is our target a player?
    if not ply:IsPlayer() then return end --are WE a player?
	if ply.PPS_Pocketing ~= false then return end --if it equals anything but false, don't even think about moving forward

    if playerdistance > 19600 then --this is about 5~ feet from the target, careful changing this number
        DarkRP.notify(ply, 2, 4, "You aren't close enough!")
        return ""
    elseif ply:isArrested() then --obviously, you can't mug someone in jail... *sniff*
        DarkRP.notify(ply, 2, 4, "You can't rob in jail!")
        return ""
    elseif Target:IsNPC() then --tf are you doing mugging npcs
        DarkRP.notify(ply, 2, 4, "You cannot rob an NPC you dolt!")
        return ""
    elseif Target:IsFrozen() then --for the cuck mods that fwill freeze you first and run you dry of cash
        DarkRP.notify(ply, 2, 4, "Did you seriously just try to rob a frozen guy?")
        return ""
    elseif (Target:isCP() or Target:Team() == TEAM_MAYOR) and not ply:isWanted() and math.random(1, 2) == 1 then --mugging the government eh? thats a paddlin
        ply:wanted(Target, "Robbery", 600)
    elseif ply.RobCD ~= nil and ply.RobCD >= CurTime() and not ply:isArrested() then --cooldown message
        DarkRP.notify(ply, 2, 4, "Must wait " .. math.ceil(ply.RobCD - CurTime()) .. " seconds before pickpocketing!")
    return end

    for k, v in pairs(ents.FindInSphere(ply:GetPos(), 1000)) do --if you're pickpocketing someone with a cop around...
        if v:IsPlayer() and v:isCP() and not ply:isWanted() and math.random(1, 4) == 1 then
			DarkRP.notify(ply, 3, 4, "There is a cop nearby! They caught you!")
            ply:wanted(nil, "Robbery", 600)
            break
        end
    end
	--the following things are preparing the shit, could probably make it better config wise
	ply.PPS_Timer = math.random(8, 10) --time before you're finished "pickpocketing"
	ply.PPS_Pocketing = true --to make sure you're actually pickpocketing
	ply.PPS_Target = Target --keep track of who we're pickpocketing
	ply.PPS_Percent = tonumber(args) --the percent of cash we will be taking, and a part of our "get caught" equation
	
	DarkRP.notify(ply, 3, 4, "Attempting rob... Time: " .. tostring(ply.PPS_Timer))
	timer.Create( tostring( ply:Nick() .. ply.PPS_Target:Nick() ), ply.PPS_Timer, 1, function() HandleRob(ply) end ) --this is the gravy right here

    ply.RobCD = CurTime() + DefaultTime
	ply:Say( ThingsToSay[i] ) --will say a random thing from the table at the top, making you suspicious
	return ""
end
--everything past here happens 8 to 10 seconds after the above function, a few of the same if checks for continuity and shit
function HandleRob( player ) --function that actually handles the "pickpocketing" part
	local target = player.PPS_Target --get our target again
	local playerdistance = player:EyePos():DistToSqr(target:GetPos()) --check the distance between us again
	local amount = math.Round( math.Clamp( target:getDarkRPVar( "money" ) * (player.PPS_Percent / 100), 150, 15000 ) ) --amount of moolah to do stuff with
	
	if playerdistance > 19600 then --same distance as above
		DarkRP.notify(player, 2, 4, "You have left range of your target!")
		player.PPS_Pocketing = false
	end
	
	if ( !player:Alive() or !target:Alive() ) then --if either of us are dead, wtf are we still doing then
		DarkRP.notify(player, 2, 4, "One of you died! Whoops...")
		player.PPS_Pocketing = false
	end
	
	if target:getDarkRPVar( "money" ) <= amount then --if the amount of money they have is less than what we're taking, take all of it and make sure they dont go below 0
		DarkRP.notify(player, 2, 4, "Your target did not have enough money! Stealing all of it!!!")
		amount = target:getDarkRPVar( "money" )
	end
	
	if math.random( 0, 100 ) <= ( player.PPS_Percent + DefaultPercent ) then --chance for being caught, percent of cash taken + 10% by default
		DarkRP.notify(player, 2, 4, "You have been caught in the act of pickpocketing!")
		player:wanted(nil, "Attempted Robbery", 600)
		player.PPS_Pocketing = false
	end
	
	if player.PPS_Pocketing == false then --if we somehow fail pickpocketing this happens
		DarkRP.notify(player, 4, 4, "You failed the pickpocket!")
		DarkRP.notify(target, 4, 4, "A thief tried to fleece your pockets!")
		timer.Remove( tostring( player:Nick() .. player.PPS_Target:Nick() ) )
	else --if we succeed, the following happens
		DarkRP.notify(player, 4, 4, "You have succeeded the pickpocket! You get " .. DarkRP.formatMoney(amount))
		DarkRP.notify(target, 4, 4, "You feel your pockets get suspiciously lighter...")
		player.PPS_Pocketing = false
		target:addMoney( -amount )
		player:addMoney( amount )
		timer.Remove( tostring( player:Nick() .. player.PPS_Target:Nick() ) )
	end
end
--the commands we can perform, feel free to add more here (and make sure to add them to sh_declarecommands.lua as well)
DarkRP.defineChatCommand("rob", RobPlayer)
DarkRP.defineChatCommand("mug", RobPlayer)
DarkRP.defineChatCommand("pickpocket", RobPlayer)