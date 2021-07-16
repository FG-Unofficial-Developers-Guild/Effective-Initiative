--  	Author: Ryan Hagelstrom
--	  	Copyright © 2021
--	  	This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--	  	https://creativecommons.org/licenses/by-sa/4.0/

function customRoundStart()
	if OptionsManager.isOption("HRIR", "on")  then
		local ctEntries = CombatManager.getSortedCombatantList()
		for _, nodeCT in pairs(ctEntries) do
			for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
				if (DB.getValue(nodeEffect, "duration", "") ~= 0) then
					local sSource = DB.getValue(nodeEffect, "source_name", "")
					if sSource == "" then
						sSource	= ActorManager.getCTPathFromActorNode(nodeCT)
					end
					local nodeSource = ActorManager.getCTNode(sSource)
					local nInit = DB.getValue(nodeSource, "initresult", 0)
					DB.setValue(nodeEffect, "init", "number", nInit)
				end
			end
		end
	end
end

function onInit()
	if Session.IsHost then
		CombatManager.setCustomRoundStart(customRoundStart)
	end
end