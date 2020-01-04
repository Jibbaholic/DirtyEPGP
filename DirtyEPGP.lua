_dirtyepgp = LibStub("AceAddon-3.0"):NewAddon("_dirtyepgp", "AceTimer-3.0", "AceComm-3.0", "AceSerializer-3.0", "NickTag-1.0")
_CoreRankText = "Core";
_CoreRankValue = 5;
_OfficerAltRankValue = 4;

do
	local _CreateFrame = CreateFrame --api locals
	local _UIParent = UIParent --api locals
	
	--> Info Window
		_dirtyepgp.janela_info = _CreateFrame ("Frame", "DetailsPlayerDetailsWindow", _UIParent)
		_dirtyepgp.PlayerDetailsWindow = _dirtyepgp.janela_info
		
	--> Event Frame
		_dirtyepgp.listener = _CreateFrame ("Frame", nil, _UIParent)
		_dirtyepgp.listener:RegisterEvent ("ADDON_LOADED")
		_dirtyepgp.listener:SetFrameStrata ("LOW")
		_dirtyepgp.listener:SetFrameLevel (9)
		_dirtyepgp.listener.FrameTime = 0
end


function DirtyEpGp_OnLoad(self)
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
end

-- slash commands
function DirtyEpGp_OnEvent(self, event, ...)
	SlashCmdList["EPGP"] = Priority_SlashCmdHandler;
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



function Priority_SlashCmdHandler(param)

---------------------------------------------
if (not _dirtyepgp.fontstring_len ) then
	_dirtyepgp.fontstring_len = _dirtyepgp.listener:CreateFontString (nil, "background", "GameFontNormal")
end
local _, fontSize = FCF_GetChatWindowInfo (1)
if (fontSize < 1) then
	fontSize = 10
end
local fonte, _, flags = _dirtyepgp.fontstring_len:GetFont()
_dirtyepgp.fontstring_len:SetFont (fonte, fontSize, flags)
_dirtyepgp.fontstring_len:SetText ("DEFAULT NAME")
local biggest_len = _dirtyepgp.fontstring_len:GetStringWidth()
---------------------------------------------



	aPlayers = {};
	
	-- change this
	n = 0;
	max_namelen = 0;

	-- get passed arguments
	_, _, sArg1, sArg2 = string.find( param, "%s?(%w+)%s?(.*)" )

	sArg2 = string.lower(sArg2);
	sArg1 = string.lower(sArg1);

	-- load all guild members
	iGuildMembers = GetNumGuildMembers();

	for i = 1, iGuildMembers do

		insert = 0;
		sName, sRank, iRankIndex, iLevel, sClass, _, _, sEpGp = GetGuildRosterInfo(i);
		sCleanName = strsub( sName, 1, string.find(sName, "-")-1 );

		iEp, iGp = strsplit( ",", sEpGp );
		if (iEp == nil or iGp == nil ) then
			iEp = 0;
			iGp = 0;
			dPriority = 0;
		else 
			dPriority = round( (( tonumber(iEp) or 0 ) / ( tonumber(iGp) or 0 )),2 )
		end 

		_, _, _, sColor = GetClassColor( string.upper(sClass) );
		if ( sCleanName == UnitName("player") ) then sColor = "ffffff00" end


		bIsInGroup = UnitInRaid( sCleanName );

		if ( bIsInGroup ~= nil ) then 
			bIsInGroup = 1;
		else
			bIsInGroup = 0;
		end 

		-- get officers+ in core rank
		if ( iRankIndex <= _CoreRankValue and iRankIndex ~= _OfficerAltRankValue ) then 
			sRank = _CoreRankText
			iRankIndex = _CoreRankValue
		end 
		
		-- get specs
		if ( sClass == "Warrior" or sClass == "Rogue") then 
			sSpec = "Melee"
		elseif ( sClass == "Mage" or sClass == "Warlock" or sClass == "Priest" or sClass == "Druid" or sClass == "Shaman" ) then
			sSpec = "Caster"
		elseif ( sClass == "Hunter" ) then 
			sSpec = "Ranged"
		end 

		-- fix later
		-- if /ep core {spec|class}
		if ( sArg1 == string.lower(_CoreRankText) and string.lower(sRank) == string.lower(_CoreRankText) ) then
			if ( sArg2 == string.lower(sClass) or sArg2 == string.lower(sSpec) ) then
				insert = 1;
			end 

		-- if /ep raid {spec|class}
		elseif (sArg1 == "raid" and bIsInGroup == 1) then
			if ( sArg2 == string.lower(sClass) or sArg2 == string.lower(sSpec) ) then
				insert = 1;
			end 

		-- if /ep guild {spec|class}
		elseif ( sArg1 == "guild" ) then
			if ( sArg2 == string.lower(sClass) or sArg2 == string.lower(sSpec) ) then
				insert = 1;
			end 

		-- if /ep player {player_name}
		elseif ( sArg1 == "player" ) then
			if ( sArg2 == string.lower(sCleanName) ) then
				insert = 1;
			end

		-- if /ep show entire raid
		elseif ( sArg1 == "" and bIsInGroup == 1 ) then
			insert = 1;
		end

		-- if the command was valid
		if ( insert == 1 ) then 
			
			-- populate the array
			n = n + 1;
			aPlayers[n] = 
			{
				name = sCleanName,
				rank = sRank,
				class = sClass,
				spec = sSpec,
				color = sColor,
				ep = iEp,
				gp = iGp,
				prio = dPriority,
				ingroup = bIsInGroup
			}

		end
		
		_dirtyepgp.fontstring_len:SetText ( sCleanName )
		local len = _dirtyepgp.fontstring_len:GetStringWidth()
		if (len > biggest_len) then
			biggest_len = len
		end

	end


	if (biggest_len > 130) then
		biggest_len = 130
	end


	-- sort it
	table.sort(aPlayers, tableSortPrio);

 	print("");
	print("|cff00ff00<Dirty> EPGP: Priority Rank for: " .. sArg1 .. " - " .. sArg2);
	 
	for i, player in ipairs(aPlayers) do
		
		
		v1 = player.name .. " "
			_dirtyepgp.fontstring_len:SetText (v1)
			local len = _dirtyepgp.fontstring_len:GetStringWidth()
			
			while (len < biggest_len) do 
				v1 = v1 .. "."
				_dirtyepgp.fontstring_len:SetText (v1)
				len = _dirtyepgp.fontstring_len:GetStringWidth()
			end			


		--local _, name_len = string.gsub(player.name, "[^\128-\193]", "")
		--z = 14;
		--if ( name_len < 7 ) then z = 15 end;
		--spacer = strsub ( "..........................................", 1, (z - name_len ));
		
		dPointsBehind = aPlayers[1].prio - player.prio;


		--sOutput = --[["|c".. player.color .. --]] string.format("%02d", tostring(i)) .. ". ";
		sOutput = "|c".. player.color .. string.format("%02d", tostring(i)) .. ". ";
		sOutput = sOutput .. v1 .. " " --player.name .. " " .. spacer .. " " 
		sOutput = sOutput .. string.format("%03d", player.ep );
		sOutput = sOutput .. "/" .. string.format("%02d", player.gp );
		sOutput = sOutput .. " (" .. string.format("%.2f", player.prio ) .. ")";
		--sOutput = sOutput .. ", -" .. tostring( string.format("%.2f", dPointsBehind) ) .. ")"

		print( sOutput );
		--SendChatMessage( sOutput, "PARTY" );
	end

	print("");
end 