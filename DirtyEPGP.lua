function DirtyEpGp_OnLoad(self)
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
end

-- slash commands
function DirtyEpGp_OnEvent(self, event, ...)
	SlashCmdList["EPGP"] =  CalculatePriority_SlashCmdHandler;
	SLASH_EPGP1 = "/epgp";
	SLASH_EPGP2 = "/ep";
	SLASH_EPGP3 = "/gp";

	GuildRoster();
end

-- round function
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- sort by prio function
function tableSortPrio(a,b)
	if(a.prio > b.prio) then
		return true
	elseif (a.prio < b.prio) then
		return false
	else 
		return a.name < b.name
	end 
end

-- slash command
function CalculatePriority_SlashCmdHandler(msg)

	_, _, arg1, arg2 = string.find(msg, "%s?(%w+)%s?(.*)")

	if (arg1 == nil) then 
		arg1 = ""
	end

	if (arg2 == nil) then 
		arg2 = ""
	end

	if (arg1 == "" or arg2 == "") then
		filter = "all"
	else 
		filter = arg1 .. " - " .. arg2
	end

	spec = "";
	color = "";

	nGuildMembers = GetNumGuildMembers(true);
	array = {}

	raid_members = 0;

	-- im bad
	max_namelen = 0;
	junk = " ............................................";

	for i = 1, nGuildMembers do

		-- get guild info
		g_name, g_rank, g_rankIndex, g_level, g_class, g_zone, g_note, g_officernote = GetGuildRosterInfo(i);

		-- clean name, check if their in raid with me
		tname = strsub( g_name, 1, strlen(g_name)-7);
		ingroup = UnitInRaid(tname);

		-- spit officer note to ep / gp, calculate priority
		ep, gp = strsplit(",", g_officernote);
		priority = round( ((tonumber(ep) or 0) / (tonumber(gp) or 0)),2 );

		-- do some shifty shit to check role
		if (g_class == "Warrior") then
			spec = "Melee";
			color = "|cffc79c6e";
		elseif (g_class == "Warlock") then
			spec = "Caster";
			color = "|cff9482c9";
		elseif (g_class == "Mage") then
			spec = "Caster";
			color = "|cff69ccf0";
		elseif (g_class == "Druid") then
			spec = "Misc";
			color = "|cffff7d0a";
		elseif (g_class == "Priest") then
			spec = "Caster";
			color = "|cffffffff";
		elseif (g_class == "Rogue") then
			spec = "Melee";
			color = "|cfffff569";
		elseif (g_class == "Shaman") then
			spec = "Caster";
			color = "|cff0070de";
		elseif (g_class == "Hunter") then
			spec = "Ranged";
			color = "|cffabd473";
		else 
			spec = "Unknown";
			color = "";
		end 

		if (g_rank == "Officer" or g_rank == "Raid Leader" or g_rank == "PvP Leader" or g_rank == "Guild Master" ) then
			g_rank = "Core"
		end

		-- check if in group
		
		-- raid filter
		--if (string.lower(arg1) ~= "player" and ingroup ~= nil) then
		-- if filter by spec
		if (string.lower(arg1) == "spec" and ingroup ~= nil and string.lower(arg2) == string.lower(spec)) then
			raid_members = raid_members + 1;
			array[raid_members] = { ["name"] = tname, ["rank"] = g_rank, ["class"] = g_class, ["ep"] = ep, ["gp"] = gp, ["prio"] = priority, ["spec"] = spec, ["color"] = color }	

		-- if filter by class
		elseif (string.lower(arg1) == "class" and ingroup ~= nil and string.lower(arg2) == string.lower(g_class)) then
			raid_members = raid_members + 1;
			array[raid_members] = { ["name"] = tname, ["rank"] = g_rank, ["class"] = g_class, ["ep"] = ep, ["gp"] = gp, ["prio"] = priority, ["spec"] = spec, ["color"] = color }	

		-- else entire raid
		elseif(arg1 == "" and ingroup ~= nil ) then
			raid_members = raid_members + 1;
			array[raid_members] = { ["name"] = tname, ["rank"] = g_rank, ["class"] = g_class, ["ep"] = ep, ["gp"] = gp, ["prio"] = priority, ["spec"] = spec, ["color"] = color }	
				--end

		-- 1 player
		elseif (string.lower(arg1) == "player" and string.lower(arg2) == string.lower(tname)) then
			raid_members = raid_members + 1;
			array[raid_members] = { ["name"] = tname, ["rank"] = g_rank, ["class"] = g_class, ["ep"] = ep, ["gp"] = gp, ["prio"] = priority, ["spec"] = spec, ["color"] = color }	

		-- show core class
		elseif (string.lower(arg1) == "core" and g_rank == "Core" and string.lower(arg2) == string.lower(g_class)) then
			raid_members = raid_members + 1;
			array[raid_members] = { ["name"] = tname, ["rank"] = g_rank, ["class"] = g_class, ["ep"] = ep, ["gp"] = gp, ["prio"] = priority, ["spec"] = spec, ["color"] = color }	

		-- show core spec
		elseif (string.lower(arg1) == "core" and g_rank == "Core" and string.lower(arg2) == string.lower(spec)) then
			raid_members = raid_members + 1;
			array[raid_members] = { ["name"] = tname, ["rank"] = g_rank, ["class"] = g_class, ["ep"] = ep, ["gp"] = gp, ["prio"] = priority, ["spec"] = spec, ["color"] = color }	

		end
		
		if( raid_members ~= 0 ) then
			local _, name_len = string.gsub(array[raid_members].name, "[^\128-\193]", "")
			if (name_len > max_namelen) then
				max_namelen = name_len;
			end 
		end
	end

	table.sort(array, tableSortPrio);
	print("");
	print("|cff00ff00<Dirty> EPGP: Priority Rank for: " .. filter);
	for i, members in ipairs(array) do

		-- clean up
		local _, name_len = string.gsub(array[i].name, "[^\128-\193]", "")

		-- format the strings
		-- if name has special char
		if (name_len ~= strlen(array[i].name)) then 
			_name = strsub( array[i].name .. junk, 1, ( max_namelen ) + 5 );
		else 
			_name = strsub( array[i].name .. junk, 1, ( max_namelen ) + 4 );
		end
		_ep = string.format("%03d", array[i].ep);
		_gp = string.format("%02d", array[i].gp);
		_prio = string.format("%.2f", array[i].prio);
		
		color = array[i].color;
		-- highlight you
		if (array[i].name == UnitName("player")) then
			color = "|cffffff00"
		end

		-- print cause lazy
		print(color .. string.format("%02d", tostring(i)) .. ". " .. _name .. " " .. _ep .. "/" .. _gp .. " (" .. _prio .. ")" );
	end
	print("");


end

