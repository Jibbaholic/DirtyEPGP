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
		filter = "FILTER: " .. arg1 .. " - " .. arg2
	end

	spec = "";

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

		-- check if in group
		-- check fiter args
		if (ingroup ~= nil) then

			-- do some shifty shit to check role
			if (g_class == "Warrior") then
				spec = "Melee";
			elseif (g_class == "Warlock") then
				spec = "Caster";
			elseif (g_class == "Mage") then
				spec = "Caster";
			elseif (g_class == "Druid") then
				spec = "Misc";
			elseif (g_class == "Priest") then
				spec = "Caster";
			elseif (g_class == "Rogue") then
				spec = "Melee";
			elseif (g_class == "Shaman") then
				spec = "Caster";
			elseif (g_class == "Hunter") then
				spec = "Ranged";
			else 
				spec = "Unknown";
			end 

			-- if filter by spec
			if (string.lower(arg1) == "spec" and string.lower(arg2) == string.lower(spec)) then
				raid_members = raid_members + 1;
				array[raid_members] = { ["name"] = tname, ["rank"] = g_rank, ["class"] = g_class, ["ep"] = ep, ["gp"] = gp, ["prio"] = priority, ["spec"] = spec }	

			-- if filter by class
			elseif (string.lower(arg1) == "class" and string.lower(arg2) == string.lower(g_class)) then
				raid_members = raid_members + 1;
				array[raid_members] = { ["name"] = tname, ["rank"] = g_rank, ["class"] = g_class, ["ep"] = ep, ["gp"] = gp, ["prio"] = priority, ["spec"] = spec }	

			-- else entire raid
			elseif(arg1 == "") then
				raid_members = raid_members + 1;
				array[raid_members] = { ["name"] = tname, ["rank"] = g_rank, ["class"] = g_class, ["ep"] = ep, ["gp"] = gp, ["prio"] = priority, ["spec"] = spec }	
			end

			if (strlen(tname) > max_namelen) then
				max_namelen = strlen(tname);
			end 

		end 
	end

	table.sort(array, tableSortPrio);

	print("<Dirty> EPGP: " .. filter);
	for i, members in ipairs(array) do

		if (strlen( array[i].name ) == max_namelen) then 
			_name = strsub( array[i].name .. junk, 1, ( max_namelen ) + 4 );
		else
			_name = strsub( array[i].name .. junk, 1, ( max_namelen ) + 5 );
		end 

		-- highlight you
		if (array[i].name == UnitName("player")) then
			color = "|cffffff00"
		else 
			color = ""
		end

		-- print cause lazy
		print(color .. tostring(i) .. ". " .. _name .. " " .. array[i].ep .. "/" .. array[i].gp .. " (" .. array[i].prio .. ")"
		);
	end

end

