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

--add variables to each player as they join
hook.Add("PlayerInitialSpawn", "Pickpocket_System_Initialize", function(ply)
    ply.PPS_Timer = 0 --the variable that controls how long you have until you have completely pickpocketed someone
    ply.PPS_Pocketing = false --the variable that controls if you are pickpocketing (see more below)
    ply.PPS_Percent = 0 --the percent of cash you will steal
    ply.RobCD = 0 --the total cooldown before you can perform the command again
end)

--first round for system, ran when we commit the robbery.
local function RobPlayer(ply, args)
    --args is the percent used for ply.PPS_Percent (read above)
    --ply is the player performing the command
    local i = math.random(0, #ZQPickpocket.ThingsToSay) --used in line 86

    if args == "" or not tonumber(args) then
        args = ZQPickpocket.DefaultPercent
    end

    if (tonumber(args) > ZQPickpocket.MaxPercent) then
        args = ZQPickpocket.MaxPercent
        DarkRP.notify(ply, 2, 4, "You can't take more than" .. " " ..  ZQPickpocket.MaxPercent .. "!" .. " " .. "Auto-set to" .. " " ..  ZQPickpocket.MaxPercent .. ".")
    end

    if (tonumber(args) < 0) then
        DarkRP.notify(ply, 2, 4, "You can't put money in pockets! That's not evil!")
    end

    local Target = ply:GetEyeTrace().Entity --the player we are going to steal from
    local playerdistance = ply:EyePos():DistToSqr(Target:GetPos()) --the distance you are from that player (really stupid number, see line 55)
    if not Target:IsPlayer() then return "" end --is our target a player?
    if not ply:IsPlayer() then return "" end --are WE a player?
    if ply.PPS_Pocketing ~= false then return "" end --if it equals anything but false, don't even think about moving forward

    --this is about 5~ feet from the target, careful changing this number
    if playerdistance > 19600 then
        DarkRP.notify(ply, 2, 4, "You aren't close enough!")
    elseif ply:isArrested() then
        --obviously, you can't mug someone in jail... *sniff*
        DarkRP.notify(ply, 2, 4, "You can't rob in jail!")
    elseif Target:IsNPC() then
        --tf are you doing mugging npcs
        DarkRP.notify(ply, 2, 4, "You cannot rob an NPC you dolt!")
    elseif Target:IsFrozen() then
        --for the cuck mods that fwill freeze you first and run you dry of cash
        DarkRP.notify(ply, 2, 4, "Did you seriously just try to rob a frozen guy?")
    elseif (Target:isCP() or Target:Team() == TEAM_MAYOR) and not ply:isWanted() and math.random(1, 2) == 1 then
        --mugging the government eh? thats a paddlin
        ply:wanted(Target, "Robbery", 600)
    elseif ply.RobCD ~= nil and ply.RobCD >= CurTime() and not ply:isArrested() then
        --cooldown message
        DarkRP.notify(ply, 2, 4, "Must wait " .. math.ceil(ply.RobCD - CurTime()) .. " seconds before pickpocketing!")
    end

    --if you're pickpocketing someone with a cop around...
    for k, v in pairs(ents.FindInSphere(ply:GetPos(), 1000)) do
        if v:IsPlayer() and v:isCP() and not ply:isWanted() and math.random(1, 4) == 1 then
            DarkRP.notify(ply, 3, 4, "There is a cop nearby! They caught you!")
            ply:wanted(nil, "Robbery", 600)
            break
        end
    end

    --the following things are preparing the shit, could probably make it better config wise
    for Job, PickpocketTime in pairs(ZQPickpocket.PickpocketJobTimes) do
        if ply:Team() == Job then
            ply.PPS_Timer = PickpocketTime
        else
            ply.PPS_Timer = math.random(8, 10)
        end
    end

    ply.PPS_Pocketing = true --to make sure you're actually pickpocketing
    ply.PPS_Target = Target --keep track of who we're pickpocketing
    ply.PPS_Percent = tonumber(args) --the percent of cash we will be taking, and a part of our "get caught" equation
    DarkRP.notify(ply, 3, 4, "Attempting rob... Time: " .. tostring(ply.PPS_Timer))

    --this is the gravy right here
    timer.Create(tostring(ply:Nick() .. ply.PPS_Target:Nick()), ply.PPS_Timer, 1, function()
        HandleRob(ply)
    end)

    for k, v in pairs(ZQPickpocket.PickpocketJobCD) do
        if ZQPickpocket.PickpocketJobCD == k then
            ply.RobCD = v
        else
            ply.RobCD = ZQPickpocket.PickpocketDefaultTime
        end
    end

    if ZQPickpocket.EnableThingsToSay then
        ply:Say(ZQPickpocket.ThingsToSay[i]) --will say a random thing from the table at the top, making you suspicious
    end

    return ""
end

--everything past here happens 8 to 10 seconds after the above function, a few of the same if checks for continuity and shit
--function that actually handles the "pickpocketing" part
function HandleRob(ply) -- can't be local b/c this is after HandleRob is called (I think?)
    local target = ply.PPS_Target --get our target again
    local playerdistance = ply:EyePos():DistToSqr(target:GetPos()) --check the distance between us again
    local amount = math.Round(math.Clamp(target:getDarkRPVar("money") * (ply.PPS_Percent / 100), ZQPickpocket.MinRobCash, ZQPickpocket.MaxRobCash)) --amount of moolah to do stuff with

    --same distance as above
    if playerdistance > 19600 then
        DarkRP.notify(ply, 2, 4, "You have left range of your target!")
        ply.PPS_Pocketing = false
    end

    --if either of us are dead, wtf are we still doing then
    if (not ply:Alive() or not target:Alive()) then
        DarkRP.notify(ply, 2, 4, "One of you died! Whoops...")
        ply.PPS_Pocketing = false
    end

    --if the amount of money they have is less than what we're taking, take all of it and make sure they dont go below 0
    if target:getDarkRPVar("money") <= amount then
        DarkRP.notify(ply, 2, 4, "Your target did not have enough money! Stealing all of it!!!")
        amount = target:getDarkRPVar("money")
    end

    --chance for being caught, percent of cash taken + 10% by default (or whatever you put in the config)
    if math.random(0, 100) <= (ply.PPS_Percent + ZQPickpocket.DefaultPercent) then
        DarkRP.notify(ply, 2, 4, "You have been caught in the act of pickpocketing!")
        ply:wanted(nil, "Attempted Robbery", 600)
        ply.PPS_Pocketing = false
    end

    --if we somehow fail pickpocketing this happens
    if ply.PPS_Pocketing == false then
        DarkRP.notify(ply, 4, 4, ZQPickpocket.FailRob)
        DarkRP.notify(target, 4, 4, ZQPickpocket.FailRobTarget)
        timer.Remove(tostring(ply:Nick() .. ply.PPS_Target:Nick()))
    else --if we succeed, the following happens
        DarkRP.notify(ply, 4, 4, ZQPickpocket.SuccessRob .. " " .. DarkRP.formatMoney(amount))
        DarkRP.notify(target, 4, 4, ZQPickpocket.SuccessRobTarget)
        ply.PPS_Pocketing = false
        target:addMoney(-amount)
        ply:addMoney(amount)
        timer.Remove(tostring(ply:Nick() .. ply.PPS_Target:Nick()))
    end
end

--the commands we can perform, feel free to add more here (and make sure to add them to sh_declarecommands.lua as well)
DarkRP.defineChatCommand("rob", RobPlayer)
DarkRP.defineChatCommand("mug", RobPlayer)
DarkRP.defineChatCommand("pickpocket", RobPlayer)
