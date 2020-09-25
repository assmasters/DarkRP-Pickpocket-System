ZQPickpocket = {}
---------------------
--added to ply.PPS_Percent to create the chance you are caught (PPS_Percent = 20? chance to get caught = 30%)
ZQPickpocket.DefaultPercent = 10
-- The maximum percent you can steal from someone
ZQPickpocket.MaxPercent = 40
-- The maximum amount of cash you can steal, regardless of the players money amount
ZQPickpocket.MaxRobCash = 15000
-- The minimum amount of cash you can steal
ZQPickpocket.MinRobCash = 150
-- If the job isn't listed below, go to this value for cooldowns
ZQPickpocket.PickpocketDefaultTime = 30
-- How long it takes for each job to pickpocket. Job on the left, time on the right.
ZQPickpocket.PickpocketJobTimes = {
    [TEAM_CITIZEN] = 10,
}

-- How long it takes for each job to run the pickpocket command. Job on the left, time on the right.
ZQPickpocket.PickpocketJobCD = {
    [TEAM_CITIZEN] = 5,
}

-- Whether or not you want to say what is in the table below if you rob someone
ZQPickpocket.EnableThingsToSay = true

--things that you will say if you rob someone...
ZQPickpocket.ThingsToSay = {
    [0] = "*Coughs Nervously*",
    [1] = "*Bumps into you* Sorry...",
    [2] = "Excuse me... Passing through...",
    [3] = "..."
}


-- what to show the robber if he succeeds the pickpocket
ZQPickpocket.SuccessRob = "You have succeeded the pickpocket! You got"
-- what to show the robber if he fails the pickpocket
ZQPickpocket.FailRob = "You failed the pickpocket!"
-- what to show the target if the robber succeeds
ZQPickpocket.SuccessRobTarget = "You feel your pockets get suspiciously lighter..."
-- what to show the target if the robber fails
ZQPickpocket.FailRobTarget = "A thief tried to fleece your pockets!"