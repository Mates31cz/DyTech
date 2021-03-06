require "defines"
require "databases/buildingdatabase"
require "databases/craftingdatabase"
require "databases/killingdatabase"
require "databases/miningdatabase"
require "scripts/functions"
require "scripts/oninit"
require "scripts/onload"
require "scripts/gui"
--require "scripts/recycler-database"

--[[Debug Functions]]--
debug_master = false -- Master switch for debugging, shows most things!
debug_ontick = false -- Ontick switch for debugging, shows all ontick event debugs
debug_chunks = false -- shows the chunks generated with this on
function debug(str)
	if debug_master then
		PlayerPrint(str)
	end
end

function PlayerPrint(message)
	for _,player in pairs(game.players) do
		player.print(message)
	end
end

local RubberSeedTypeName = "RubberTree"
local RubberGrowingStates = {
	"rubber-seed",
	"small-rubber-tree",
	"medium-rubber-tree",
	"mature-rubber-tree"
}
local RubberOutput = {"resin", 3}
local RubberTileEfficiency = {
	["grass"] = 1.00,
	["grass-medium"] = 1.50,
	["grass-dry"] = 0.75,
	["dirt"] = 1.25,
	["dirt-dark"] = 1.25,
	["hills"] = 0.80,
	["sand"] = 0.25,
	["sand-dark"] = 0.25,
	["other"] = 0
}
local RubberBasicGrowingTime = 7500
local RubberRandomGrowingTime = 4500
local RubberFertilizerBoost = 1.45
local allInOne = {
	["name"] = RubberSeedTypeName,
	["states"] = RubberGrowingStates,
	["output"] = RubberOutput,
	["efficiency"] = RubberTileEfficiency,
	["basicGrowingTime"] = RubberBasicGrowingTime,
	["randomGrowingTime"] = RubberRandomGrowingTime,
	["fertilizerBoost"] = RubberFertilizerBoost
}

game.oninit(function()
	Init.OnInit()
end)

game.onsave(function()

end)

game.onload(function()
	Load.OnLoad()
	fs.ModuleChecker()
	if game.itemprototypes.charcoal and remote.interfaces["treefarm"] then -- item "charcoal" is available, that means treefarm-mod is probably used
	debug("Treefarm installed")
        local errorMsg = remote.call("treefarm", "addSeed", allInOne) -- call the interface and store the return value
            -- the remote function will return nil on success, otherwise a string with the error-msg
			if errorMsg == nil then -- everything worked fine
				glob.compatibility.treefarm = true
			else
				if errorMsg ~= "seed type already present" then PlayerPrint(errorMsg) end
			end
	else -- charcoal isn't available, so treefarm-mod isn't installed
	debug("Treefarm not installed")
		glob.compatibility.treefarm = false
		for seedTypeName, seedTypeInfo in pairs (glob.trees.seedTypes) do
			if game.itemprototypes[seedTypeInfo.states[1]] == nil then
				glob.trees.isGrowing[seedTypeName] = nil
				glob.trees.seedTypes[seedTypeName] = nil
			end
		end
	end
end)

game.onevent(defines.events.onplayercrafteditem, function(event)
	if not glob.CraftedItems[event.itemstack.name] then
		glob.CraftedItems[event.itemstack.name] = event.itemstack.count
		debug("No CraftedItems ("..tostring(event.itemstack.name)..")")
	else
		glob.CraftedItems[event.itemstack.name] = glob.CraftedItems[event.itemstack.name] + event.itemstack.count
		debug("CraftedItems increased by "..tostring(event.itemstack.count).." ("..tostring(event.itemstack.name)..")")
	end
	fs.incrementDynamicCounters(event.itemstack)
end)

game.onevent(defines.events.onplayermineditem, function(event)
local Player = game.players[event.playerindex]
	glob.counter2.mine = glob.counter2.mine + event.itemstack.count
	if MineDatabase.mineitems[event.itemstack.name] then
		for counter, ingredients in pairs(MineDatabase.mineitems[event.itemstack.name]) do 
			glob.counter[counter]=glob.counter[counter]+(event.itemstack.count*ingredients)
			debug("Mining: "..tostring(counter).." increased by "..tostring((event.itemstack.count*ingredients)))
		end
	end
	if event.itemstack.name == "raw-wood" then
		if math.random(50) == 25 then
		local amount = math.random(1,5)
			Player.insert{name="resin",count=amount}
			Player.print({"msg-rubber"})
			debug("Player given "..tostring(amount).." Rubber Resin")
		end
	end
	if not glob.MinedItems[event.itemstack.name] then
		glob.MinedItems[event.itemstack.name] = event.itemstack.count
		debug("MinedItems not found".." ("..tostring(event.itemstack.name)..")")
	else
		glob.MinedItems[event.itemstack.name] = glob.MinedItems[event.itemstack.name] + event.itemstack.count
		debug("MinedItems increased by "..tostring(event.itemstack.count).." ("..tostring(event.itemstack.name)..")")
	end
end)

game.onevent(defines.events.onrobotmined, function(event)
	glob.counter2.mine = glob.counter2.mine + event.itemstack.count
	if not glob.RobotMinedItems[event.itemstack.name] then
		glob.RobotMinedItems[event.itemstack.name] = event.itemstack.count
		debug("RobotMinedItems not found".." ("..tostring(event.itemstack.name)..")")
	else
		glob.RobotMinedItems[event.itemstack.name] = glob.RobotMinedItems[event.itemstack.name] + event.itemstack.count
		debug("RobotMinedItems increased by "..tostring(event.itemstack.count).." ("..tostring(event.itemstack.name)..")")
	end
end)

game.onevent(defines.events.onentitydied, function(event)
	glob.counter2.died = glob.counter2.died + 1
	if KillDatabase.kill[event.entity.name] and event.entity.force.name == "enemy" then
		for counter, ingredients in pairs(KillDatabase.kill[event.entity.name]) do 
			glob.combat[counter]=glob.combat[counter] + ingredients
		end
	end
	if not glob.EntityDied[event.entity.name] then
		glob.EntityDied[event.entity.name] = 1
		debug("EntityDied not found".." ("..tostring(event.entity.name)..")")
	else
		glob.EntityDied[event.entity.name] = glob.EntityDied[event.entity.name] + 1
		debug("EntityDied increased by 1".." ("..tostring(event.entity.name)..")")
	end
end)

game.onevent(defines.events.onsectorscanned, function(event)
	glob.counter2.sectorscanned = glob.counter2.sectorscanned + 1
end)

game.onevent(defines.events.onmarkedfordeconstruction, function(event)
	if not glob.MarkedForDeconstruction[event.entity.name] then
		glob.MarkedForDeconstruction[event.entity.name] = 1
		debug("MarkedForDeconstruction not found ("..tostring(event.entity.name)..")")
	else
		glob.MarkedForDeconstruction[event.entity.name] = glob.MarkedForDeconstruction[event.entity.name] + 1
		debug("MarkedForDeconstruction increased by 1 ("..tostring(event.entity.name)..")")
	end	
end)

game.onevent(defines.events.oncanceleddeconstruction, function(event)
	if not glob.CanceledDeconstruction[event.entity.name] then
		glob.CanceledDeconstruction[event.entity.name] = 1
		debug("CanceledDeconstruction not found ("..tostring(event.entity.name)..")")
	else
		glob.CanceledDeconstruction[event.entity.name] = glob.CanceledDeconstruction[event.entity.name] + 1
		debug("CanceledDeconstruction increased by 1 ("..tostring(event.entity.name)..")")
	end	
end)

game.onevent(defines.events.onpickedupitem, function(event)
	glob.counter2.pickup = glob.counter2.pickup + event.itemstack.count
	if not glob.PickedItems[event.itemstack.name] then
		glob.PickedItems[event.itemstack.name] = event.itemstack.count
		debug("PickedItems not found ("..tostring(event.itemstack.name)..")")
	else
		glob.PickedItems[event.itemstack.name] = glob.PickedItems[event.itemstack.name] + event.itemstack.count
		debug("PickedItems increased by "..tostring(event.itemstack.count).." ("..tostring(event.itemstack.name)..")")
	end
end)

game.onevent(defines.events.ontick, function(event)
	fs.Timer(event)
	if game.tick%300==0 then
		fs.ModuleChecker()
		if debug_ontick then debug("Module Checker activated") end
	end
	if game.tick%60==1 then
		glob.counter.dytech=0
		glob.combat.dytech=0
		glob.counter2.dytech=0
		if debug_ontick then debug("Module Checker activated") end
		for _, counter in pairs(glob.counter) do 
			if (counter~=glob.counter.dytech) then glob.counter.dytech=glob.counter.dytech+counter end
		end
		if debug_ontick then debug("Global Counter set") end
		for _, counter in pairs(glob.counter2) do 
			if (counter~=glob.counter2.dytech) then glob.counter2.dytech=glob.counter2.dytech+counter end
		end
		if debug_ontick then debug("Global Counter2 set") end
		for _, counter in pairs(glob.combat) do 
			if (counter~=glob.combat.dytech) then glob.combat.dytech=glob.combat.dytech+counter end
		end
		if debug_ontick then debug("Global Combat Counter set") end
	end
	if glob.compatibility.treefarm == false then
		for seedTypeName, seedType in pairs(glob.trees.isGrowing) do
			if (seedType[1] ~= nil) and (game.tick >= seedType[1].nextUpdate)then
				local removedEntity = table.remove(seedType, 1)
				fs.updateEntityState(removedEntity)
				debug("Trees update entity state")
			end
		end
	end
	--[[Stone Collector]]--
    if glob.stone~=nil and event.tick%12==0 then
		fs.CollectByPosition("stone", 1.5, false)
		fs.CollectByPosition("stone", 1.5, true)
		if debug_ontick then debug("Stone Collector done") end
	end
	--[[Sand Collector]]--
	if glob.sand~=nil and event.tick%12==0 then
		fs.CollectByPosition("sand", 1.5, false)
		fs.CollectByPosition("sand", 1.5, true)
		if debug_ontick then debug("Sand Collector done") end
	end
	--[[Coal Collector]]--
	if glob.coal~=nil and event.tick%12==0 then
		fs.CollectByPosition("coal", 1.5, false)
		fs.CollectByPosition("coal", 1.5, true)
		if debug_ontick then debug("Coal Collector done") end
	end
	--[[DyTech Item Collector]]--
	if glob.dytechitem~=nil and event.tick%60==0 then
		fs.DyTechItemCollect(dytechitem, 50)
		if debug_ontick then debug("DyTech Item Collector done") end
	end
   --[[Radar and Minimap]]--
	if glob.radar~=nil then
		for k,v in pairs(glob.radar) do --the first variable is used for the key or index in the table, the second is for the value of that key
			if v.valid and (v.energy > 0) and glob.minimap~= true then
				game.disableminimap() --enable map
			elseif not v.valid then
            table.remove(glob.radar, k)
				if glob.minimap==true then
					game.disableminimap()
					glob.minimap=false
					PlayerPrint("Because of the lack of radar(s), the minimap has been disabled!")
				end
			elseif not (v.energy > 0) then 
				if glob.minimap==true then
					game.disableminimap()
					glob.minimap=false
					PlayerPrint("Minimap has been disabled to due to radar(s) losing power!")
				end
			end
		end
	end    
end)

game.onevent(defines.events.onbuiltentity, function(event)
	if event.createdentity.type == "tree" then
		if glob.compatibility.treefarm == false then
			local currentSeedTypeName = fs.getSeedTypeByEntityName(event.createdentity.name)
			if currentSeedTypeName ~= nil then
				fs.seedPlaced(event.createdentity, currentSeedTypeName)
				debug("Tree Seed Placed")
				return
			end
		end
	--[[Stone Collector Build]]--
	elseif event.createdentity.name == "stone-collector-1" or event.createdentity.name == "stone-collector" then
		glob.stonecount=glob.stonecount+1
		glob.stone[glob.stonecount]={}
		glob.stone[glob.stonecount].position=event.createdentity.position
		debug("Stone Collector Build at "..serpent.block(event.createdentity.position))
		--[[Coal Collector Build]]--
	elseif event.createdentity.name == "coal-collector-1" or event.createdentity.name == "coal-collector" then	
		glob.coalcount=glob.coalcount+1
		glob.coal[glob.coalcount]={}
		glob.coal[glob.coalcount].position=event.createdentity.position
		debug("Coal Collector Build at "..serpent.block(event.createdentity.position))
	elseif event.createdentity.name == "dytech-item-collector" then				
		glob.dytechitemcount=glob.dytechitemcount+1
		glob.dytechitem[glob.dytechitemcount]={}
		glob.dytechitem[glob.dytechitemcount].position=event.createdentity.position
		debug("DyTech Item Collector Build at "..serpent.block(event.createdentity.position))
	--[[Sand Collector Build]]--
	elseif event.createdentity.name == "sand-collector-1" or event.createdentity.name == "sand-collector" then				
		glob.sandcount=glob.sandcount+1
		glob.sand[glob.sandcount]={}
		glob.sand[glob.sandcount].position=event.createdentity.position
		debug("Sand Collector Build at "..serpent.block(event.createdentity.position))
	elseif debug_master==true then
		debug(tostring(event.createdentity.name).." created at "..serpent.block(event.createdentity.position))
	end
	glob.counter2.build = glob.counter2.build + 1
	fs.incrementDynamicCountersBuild(event.createdentity)
	if glob.BuildEntity[event.createdentity.name] then
		glob.BuildEntity[event.createdentity.name] = glob.BuildEntity[event.createdentity.name] + 1
		debug("BuildEntity increased by 1 ("..tostring(event.createdentity.name)..")")
	else
		glob.BuildEntity[event.createdentity.name] = 1
		debug("BuildEntity not found ("..tostring(event.createdentity.name)..")")
	end
end)

game.onevent(defines.events.onrobotbuiltentity, function(event)
	if event.createdentity.type == "tree" then
		if glob.compatibility.treefarm == false then
			local currentSeedTypeName = fs.getSeedTypeByEntityName(event.createdentity.name)
			if currentSeedTypeName ~= nil then
				fs.seedPlaced(event.createdentity, currentSeedTypeName)
				debug("Tree Seed Placed")
				return
			end
		end
	--[[Stone Collector Build]]--
	elseif event.createdentity.name == "stone-collector-1" or event.createdentity.name == "stone-collector" then
		glob.stonecount=glob.stonecount+1
		glob.stone[glob.stonecount]={}
		glob.stone[glob.stonecount].position=event.createdentity.position
		debug("Stone Collector Build at "..serpent.block(event.createdentity.position))
		--[[Coal Collector Build]]--
	elseif event.createdentity.name == "coal-collector-1" or event.createdentity.name == "coal-collector" then	
		glob.coalcount=glob.coalcount+1
		glob.coal[glob.coalcount]={}
		glob.coal[glob.coalcount].position=event.createdentity.position
		debug("Coal Collector Build at "..serpent.block(event.createdentity.position))
	elseif event.createdentity.name == "dytech-item-collector" then				
		glob.dytechitemcount=glob.dytechitemcount+1
		glob.dytechitem[glob.dytechitemcount]={}
		glob.dytechitem[glob.dytechitemcount].position=event.createdentity.position
		debug("DyTech Item Collector Build at "..serpent.block(event.createdentity.position))
	--[[Sand Collector Build]]--
	elseif event.createdentity.name == "sand-collector-1" or event.createdentity.name == "sand-collector" then				
		glob.sandcount=glob.sandcount+1
		glob.sand[glob.sandcount]={}
		glob.sand[glob.sandcount].position=event.createdentity.position
		debug("Sand Collector Build at "..serpent.block(event.createdentity.position))
	elseif debug_master==true then
		debug(tostring(fs.EntityNameLocale(event.createdentity.name)).." created at "..serpent.block(event.createdentity.position))
	end
	glob.counter2.build = glob.counter2.build + 1
	fs.incrementDynamicCountersBuild(event.createdentity)
	if glob.RobotBuildEntity[event.createdentity.name] then
		glob.RobotBuildEntity[event.createdentity.name] = glob.RobotBuildEntity[event.createdentity.name] + 1
		debug("RobotBuildEntity increased by 1 ("..tostring(event.createdentity.name)..")")
	else
		glob.RobotBuildEntity[event.createdentity.name] = 1
		debug("RobotBuildEntity not found ("..tostring(event.createdentity.name)..")")
	end
end)

game.onevent(defines.events.onchunkgenerated, function(event)
	glob.counter2.chunks = glob.counter2.chunks + 1
	if debug_chunks then debug("Chunk Generated, chunks counter is now "..tostring(glob.counter2.chunks)) end
end)

game.onevent(defines.events.onguiclick, function(event)
local Player = game.players[event.element.playerindex]
	if event.element.name:find(CoreGUI.guiNames.ExportButton) then
		remote.call("DyTech-Core", "ExportAll")
		CoreGUI.closeAllGUI(event.element.playerindex)
		PlayerPrint("Be sure to send the files from the script-output folder to Dysoch so he can use that for balancing!")
	elseif event.element.name:find(CoreGUI.guiNames.ExitButton) then
		CoreGUI.closeAllGUI(event.element.playerindex)
	elseif event.element.name:find(CoreGUI.guiNames.BackButton) then
		CoreGUI.closeAllGUI(event.element.playerindex)
		CoreGUI.showMasterGUI(event.element.playerindex)
	elseif event.element.name:find(CoreGUI.guiNames.AboutButton) then
		CoreGUI.closeAllGUI(event.element.playerindex)
		CoreGUI.showAboutGUI(event.element.playerindex)
	elseif event.element.name:find(CoreGUI.guiNames.CoreButton) then
		CoreGUI.closeMasterGUI(event.element.playerindex)
		CoreGUI.showCoreGUI(event.element.playerindex)
	elseif event.element.name:find(CoreGUI.guiNames.DynamicButton) then
		CoreGUI.closeMasterGUI(event.element.playerindex)
		CoreGUI.showDynamicGUI(event.element.playerindex)
	elseif event.element.name:find(CoreGUI.guiNames.DynamicSystemButton) then
		remote.call("DyTech-Dynamic", "ToggleDynamicSystem")
	elseif event.element.name:find(CoreGUI.guiNames.DynamicSystemHardButton) then
		remote.call("DyTech-Dynamic", "ToggleHardMode")
	elseif event.element.name:find(CoreGUI.guiNames.ToolsButton) then
		CoreGUI.closeMasterGUI(event.element.playerindex)
		CoreGUI.showToolsGUI(event.element.playerindex)
	elseif event.element.name:find(CoreGUI.guiNames.ToolsCraftingButton) then
		CoreGUI.closeAllGUI(event.element.playerindex)
		remote.call("DyTech-Tools", "showCraftingGUI")
	elseif event.element.name:find(CoreGUI.guiNames.ToolsItemButton) then
		CoreGUI.closeAllGUI(event.element.playerindex)
		Player.insert{name="tool-crafting-bench",count=1}
	elseif event.element.name:find(CoreGUI.guiNames.MetallurgyButton) then
		CoreGUI.closeMasterGUI(event.element.playerindex)
		CoreGUI.showMetallurgyGUI(event.element.playerindex)
	elseif event.element.name:find(CoreGUI.guiNames.MetallurgyFluidsButton) then
		remote.call("DyTech-Metallurgy", "RegenerateFluids")
	elseif event.element.name:find(CoreGUI.guiNames.MetallurgyOresButton) then
		remote.call("DyTech-Metallurgy", "RegenerateOres")
	end
end)

remote.addinterface("DyTech-Core",
{
  detectModule = function(name)
	if type(name) == "string" then
		if name == "all" then return glob.dytech else return glob.dytech[name] end
	elseif type(name) == "table" then
		local result = {}
			for _, name in ipairs(name) do
			result[name] = glob.dytech[name]
			end
	return result
	else
    return false -- could also use error("unknown name type", 2)
	end
  end,
  
  addModule = function(name)
	glob.dytech[name] = true
  end,

  Modules = function()
			PlayerPrint("This shows which module of DyTech is installed:")
			PlayerPrint("DyTech-Core:".." "..tostring(glob.dytech.core))
			PlayerPrint("DyTech-Automation:".." "..tostring(glob.dytech.automation))
			PlayerPrint("DyTech-Compatibility".." "..tostring(glob.dytech.compatibility))
			PlayerPrint("DyTech-Dynamic:".." "..tostring(glob.dytech.dynamic))
			PlayerPrint("DyTech-Energy:".." "..tostring(glob.dytech.energy))
			PlayerPrint("DyTech-Inserters:".." "..tostring(glob.dytech.inserters))
			PlayerPrint("DyTech-Logistic:".." "..tostring(glob.dytech.logistic))
			PlayerPrint("DyTech-Metallurgy:".." "..tostring(glob.dytech.metallurgy))
			PlayerPrint("DyTech-Meteors:".." "..tostring(glob.dytech.meteors))
			PlayerPrint("DyTech-Modules:".." "..tostring(glob.dytech.modules))
			PlayerPrint("DyTech-Storage:".." "..tostring(glob.dytech.storage))
			PlayerPrint("DyTech-Tools:".." "..tostring(glob.dytech.tools))
			PlayerPrint("DyTech-Transportation:".." "..tostring(glob.dytech.transportation))
			PlayerPrint("DyTech-Warfare:".." "..tostring(glob.dytech.warfare))
  end,
  
  ExportAll = function()
	game.makefile("DyTech-Counters.txt", serpent.block(glob.counter))
	game.makefile("DyTech-AdvancedCounters.txt", serpent.block(glob.counter2))
	game.makefile("DyTech-CombatCounters.txt", serpent.block(glob.combat))
	game.makefile("DyTech-Timer.txt", serpent.block(glob.timer))
	game.makefile("DyTech-ModulesInstalled.txt", serpent.block(glob.dytech))
	game.makefile("DyTech-CraftedItems.txt", serpent.block(glob.CraftedItems))
	game.makefile("DyTech-PickedItems.txt", serpent.block(glob.PickedItems))
	game.makefile("DyTech-MinedItems.txt", serpent.block(glob.MinedItems))
	game.makefile("DyTech-EntityDied.txt", serpent.block(glob.EntityDied))
	game.makefile("DyTech-BuildEntity.txt", serpent.block(glob.BuildEntity))
	game.makefile("DyTech-CanceledDeconstruction.txt", serpent.block(glob.CanceledDeconstruction))
	game.makefile("DyTech-MarkedForDeconstruction.txt", serpent.block(glob.MarkedForDeconstruction))
	game.makefile("DyTech-RobotBuildEntity.txt", serpent.block(glob.RobotBuildEntity))
	game.makefile("DyTech-RobotMinedItems.txt", serpent.block(glob.RobotMinedItems))
	PlayerPrint("Exported all data from Core!")
	if remote.interfaces["DyTech-Dynamic"]then
		remote.call("DyTech-Dynamic", "Export")
	end
	PlayerPrint("You can find all relevant data in the script-output folder!")
  end,
  
  checkCounter = function(name)
	if type(name) == "string" then
		if name == "all" then return glob.counter.dytech else return glob.counter[name] end
	elseif type(name) == "table" then
		local result = {}
			for _, name in ipairs(name) do
			result[name] = glob.counter[name]
			end
	return result
	else
    return false -- could also use error("unknown name type", 2)
	end
  end,
  
  checkTimer = function(name)
	return glob.timer[name]
  end,
  
  removefromCounter = function(name, Number)
	if type(name) == "string" then
	local RandomNumber = math.random(glob.counter[name]/Number)
		glob.counter[name] = (glob.counter[name]-RandomNumber)
		PlayerPrint({"msg-reduction-1"}.." "..tostring(name).." "..{"msg-reduction-2"}.." "..tostring(glob.counter[name]).." "..{"msg-reduction-3"}.." "..tostring(RandomNumber))
	end
  end,
  
  addtoCounter = function(name, Number)
	if type(name) == "string" then
		glob.counter[name] = (glob.counter[name]+Number)
	end
  end,
  
  GUI = function()
	if #game.players==1 then
		CoreGUI.showMasterGUI()
	else
		error("Due to buggyness in the GUI, this function has been disabled. For punishment, the game will crash! This will be fixed with later versions of Factorio(not DyTech). DO NOT USE GUI IN MULTIPLAYER!!! Apologies, Dysoch")
	end
  end,
  
  DynamicGUI = function()
	if #game.players==1 then
		CoreGUI.showDynamicGUI()
	else
		error("Due to buggyness in the GUI, this function has been disabled. For punishment, the game will crash! This will be fixed with later versions of Factorio(not DyTech). DO NOT USE GUI IN MULTIPLAYER!!! Apologies, Dysoch")
	end
  end,
  
  ModuleChecker = function()
	fs.ModuleChecker()
  end,
  
  ResetAll = function()
	game.force.resettechnologies()
	game.force.resetrecipes()
  end
})