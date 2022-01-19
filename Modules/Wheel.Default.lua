local SongAttributes = LoadModule "SongAttributes.lua"
local jk = LoadModule"Jacket.lua"

local counter = 0
local targetDelta = 1/60
local timer = GetUpdateTimer(targetDelta)

--displays 3 digit numbers 000, 111, 222... 999, 000... every 1/60 of a second (about)
local function RandomBPM(self, _)
	local s = self:GetChild("BPM")
	s:settext("BPM "..string.rep(tostring(counter),3))
	counter = (counter+1)%10
end

local function textBPM(dispBPM)
	return string.format("BPM %03d", math.floor(dispBPM+0.5))
end

local function VariedBPM(self, _)
	local s = self:GetChild("BPM")
	s:settextf("BPM %03d - %03d",math.floor(dispBPMs[1]+0.5),math.floor(dispBPMs[2]+0.5))
end

-- Difficulty Colours
local DiffColors={
	color("#88ffff"), -- Difficulty_Beginner
	color("#ffc0cb"), -- Difficulty_Easy
	color("#ff8888"), -- Difficulty_Medium
	color("#88ff88"), -- Difficulty_Hard
	color("#8888ff"), -- Difficulty_Challenge
	color("#888888") -- Difficulty_Edit
}

-- Difficulty Names.
local DiffNames={
	"BEGIN", -- Difficulty_Beginner
	"PARAPARA", -- Difficulty_Easy
	"NORMAL", -- Difficulty_Medium
	"HARD ", -- Difficulty_Hard
	"EXPERT", -- Difficulty_Challenge
	"EDIT" -- Difficulty_Edit
}

-- We define the curent song if no song is selected.
if not CurSong then CurSong = 1 end

-- We define the current group to be empty if no group is defined.
if not CurGroup then GurGroup = "" end

-- The player joined.
if not Joined then Joined = {} end

-- The increase offset for when we move with postive.
local IncOffset = 1

-- The decrease offset for when we move with negative.
local DecOffset = 10

-- The center offset of the wheel.
local XOffset = 5

-- Move the wheel, We define the Offset using +1 or -1.
-- We parse the Songs also so we can get the amount of songs.
local function MoveSelection(self,offset,Songs)
	-- Curent Song + Offset.
	CurSong = CurSong + offset
	
	-- Check if curent song is further than Songs if so, reset to 1.
	if CurSong > #Songs then CurSong = 1 end
	-- Check if curent song is lower than 1 if so, grab last song.
	if CurSong < 1 then CurSong = #Songs end
	
	-- Set the offsets for increase and decrease.
	DecOffset = DecOffset + offset
	IncOffset = IncOffset + offset

	if DecOffset > 10 then DecOffset = 1 end
	if IncOffset > 10 then IncOffset = 1 end

	if DecOffset < 1 then DecOffset = 10 end
    if IncOffset < 1 then IncOffset = 10 end
    
    -- Set the offset for the center of the wheel.	
	XOffset = XOffset + offset
	if XOffset > 10 then XOffset = 1 end
	if XOffset < 1 then XOffset = 10 end
    
    -- If we are calling this command with an offset that is not 0 then do stuff.
	if offset ~= 0 then

		-- For every part on the wheel do.
		for i = 1,10 do	
		
			-- Calculate current position based on song with a value to get center.
            local pos = CurSong+(4*offset)
            
            if offset == 1 then
                pos = CurSong+(5*offset)
            end
		
			-- Keep it within reasonable values.
			while pos > #Songs do pos = pos-#Songs end
			while pos < 1 do pos = #Songs+pos end
		
			-- Transform the wheel, As in make it move.
			self:GetChild("SongWheel"):GetChild("CD"..i):finishtweening():decelerate(0.15):addx((offset*-280))

			-- Here we define what the wheel does if it is outside the values.
			-- So that when a part is at the bottom it will move to the top.
			if (i == IncOffset and offset == -1) or (i == DecOffset and offset == 1) then

				-- Move wheelpart instantly to new location.
                self:GetChild("SongWheel"):GetChild("CD"..i):sleep(0):addx((offset*-280)*-10)

                if type(Songs[pos]) ~= "string" then
					self:GetChild("SongWheel"):GetChild("CD"..i):GetChild("JacketOverlay"):visible(false)
                    if Songs[pos][1]:HasJacket() then 
						self:GetChild("SongWheel"):GetChild("CD"..i):GetChild("JacketTexture"):Load(Songs[pos][1]:GetJacketPath()) 
                    elseif Songs[pos][1]:HasBackground() then 
						self:GetChild("SongWheel"):GetChild("CD"..i):GetChild("JacketTexture"):Load(Songs[pos][1]:GetBackgroundPath())
					else 
						self:GetChild("SongWheel"):GetChild("CD"..i):GetChild("JacketTexture"):Load(THEME:GetPathG("","white.png"))
                    end
                else
                    if jk.GetGroupGraphicPath(Songs[pos],"Jacket","SortOrder_Group") ~= "" then 
						self:GetChild("SongWheel"):GetChild("CD"..i):GetChild("JacketTexture"):Load(jk.GetGroupGraphicPath(Songs[pos],"Jacket","SortOrder_Group"))
						self:GetChild("SongWheel"):GetChild("CD"..i):GetChild("JacketOverlay"):visible(true)
					else 
						self:GetChild("SongWheel"):GetChild("CD"..i):GetChild("JacketTexture"):Load(THEME:GetPathG("","white.png"))
                    end
                end
                self:GetChild("SongWheel"):GetChild("CD"..i):GetChild("JacketTexture"):zoomto(230,230) 
            end
        end

		-- Check if its a song.
		if type(Songs[CurSong]) ~= "string" then
			-- Set the Centered Banner.
			self:GetChild("Banner"):visible(true):Load(Songs[CurSong][1]:GetJacketPath())

			self:GetChild("GroupLabel"):linear(0.15):diffusealpha(1)
			self:GetChild("GroupLabel"):GetChild("GroupBacker"):linear(0.15):cropright(0)
			self:GetChild("GroupLabel"):GetChild("GroupText"):linear(0.15):cropright(0)
			
			self:GetChild("BannerInfo"):visible(true)
			self:GetChild("BannerInfo"):GetChild("Title"):settext(ToUpper(Songs[CurSong][1]:GetDisplayMainTitle())):y(-6):diffuse(SongAttributes.GetMenuColor(Songs[CurSong][1]))
				:strokecolor(ColorDarkTone(SongAttributes.GetMenuColor(Songs[CurSong][1])))
			self:GetChild("BannerInfo"):GetChild("Artist"):settext(ToUpper(Songs[CurSong][1]:GetDisplayArtist())):diffuse(SongAttributes.GetMenuColor(Songs[CurSong][1]))
				:strokecolor(ColorDarkTone(SongAttributes.GetMenuColor(Songs[CurSong][1])))

			if Songs[CurSong][1]:IsDisplayBpmRandom() or Songs[CurSong][1]:IsDisplayBpmSecret() then
				counter = 0
				timer = GetUpdateTimer(targetDelta)
				self:GetChild("BPM"):visible(true):diffuse(Color.Red)
				self:GetChild("BPM"):aux(-1):settext("BPM 999"):GetParent():SetUpdateFunction(RandomBPM)
			else
				self:GetChild("BPM"):visible(true):diffuse(Color.White)
				local dispBPMs = Songs[CurSong][1]:GetDisplayBpms()
				if Songs[CurSong][1]:IsDisplayBpmConstant() then
					self:GetChild("BPM"):settextf("BPM %03d",math.floor(dispBPMs[1]+0.5)):GetParent():SetUpdateFunction(nil)
				else
					self:GetChild("BPM"):visible(true):settextf("BPM %03d - %03d",math.floor(dispBPMs[1]+0.5),math.floor(dispBPMs[2]+0.5)):GetParent():SetUpdateFunction(nil)
				end
			end

		-- Its a group.
		else	
			-- Set banner.
			if jk.GetGroupGraphicPath(Songs[CurSong],"Jacket","SortOrder_Group") ~= "" then
				self:GetChild("Banner"):visible(true):Load(jk.GetGroupGraphicPath(Songs[CurSong],"Jacket","SortOrder_Group"))
			end
			self:GetChild("BannerInfo"):visible(true)
			self:GetChild("BannerInfo"):GetChild("Title"):settext(SongAttributes.GetGroupName(Songs[CurSong])):y(6):diffuse(SongAttributes.GetGroupColor(Songs[CurSong]))
				:strokecolor(ColorDarkTone(SongAttributes.GetGroupColor(Songs[CurSong])))
			self:GetChild("BannerInfo"):GetChild("Artist"):settext(""):diffuse(SongAttributes.GetGroupColor(Songs[CurSong]))
			:strokecolor(ColorDarkTone(SongAttributes.GetGroupColor(Songs[CurSong])))

			self:GetChild("GroupLabel"):linear(0.15):diffusealpha(0)
			self:GetChild("GroupLabel"):GetChild("GroupBacker"):linear(0.15):cropright(1)
			self:GetChild("GroupLabel"):GetChild("GroupText"):linear(0.15):cropright(1)

			self:GetChild("BPM"):visible(false)
		end

		-- Resize the Centered Banner  to be w(512/8)*5 h(160/8)*5
		self:GetChild("Banner"):zoomto(378,378)
    else
        -- For every part of the wheel do.
		for i = 1,10 do	

			-- Offset for the wheel items.
			off = i + XOffset

			-- Stay withing limits.
			while off > 10 do off = off-10 end
			while off < 1 do off = off+10 end

			-- Get center position.
			local pos = CurSong+i

			-- If item is above 5 then we do a -10 to fix the display.
			if i > 5 then
				pos = CurSong+i-10
			end

			-- Keep pos withing limits.
			while pos > #Songs do pos = pos-#Songs end
            while pos < 1 do pos = #Songs+pos end

            if type(Songs[pos]) ~= "string" then
				self:GetChild("SongWheel"):GetChild("CD"..off):GetChild("JacketOverlay"):visible(false)
                if Songs[pos][1]:HasJacket() then self:GetChild("SongWheel"):GetChild("CD"..off):GetChild("JacketTexture"):Load(jk.GetSongGraphicPath(Songs[pos][1]))
                elseif Songs[pos][1]:HasBackground() then 
					self:GetChild("SongWheel"):GetChild("CD"..off):GetChild("JacketTexture"):Load(Songs[pos][1]:GetBackgroundPath())
				else 
					self:GetChild("SongWheel"):GetChild("CD"..off):GetChild("JacketTexture"):Load(THEME:GetPathG("","white.png"))
                end
            else
                if jk.GetGroupGraphicPath(Songs[pos],"Jacket","SortOrder_Group") ~= "" then 
					self:GetChild("SongWheel"):GetChild("CD"..off):GetChild("JacketOverlay"):visible(true)
					self:GetChild("SongWheel"):GetChild("CD"..off):GetChild("JacketTexture"):Load(jk.GetGroupGraphicPath(Songs[pos],"Jacket","SortOrder_Group")) 
				else 
					self:GetChild("SongWheel"):GetChild("CD"..off):GetChild("JacketTexture"):Load(THEME:GetPathG("","white.png"))
                end
            end
            self:GetChild("SongWheel"):GetChild("CD"..off):GetChild("JacketTexture"):zoomto(230,230) 
        end
    end

    -- Check if offset is not 0.
	if offset ~= 0 then
		-- Stop all the music playing, Which is the Song Music
		
		-- Check if its a song.
		if type(Songs[CurSong]) ~= "string" then
			SOUND:StopMusic()
			-- Play Current selected Song Music.
			if Songs[CurSong][1]:GetMusicPath() then
				SOUND:PlayMusicPart(Songs[CurSong][1]:GetMusicPath(),Songs[CurSong][1]:GetSampleStart(),Songs[CurSong][1]:GetSampleLength(),1,1.5,true)
			end
		else
			SOUND:PlayMusicPart(THEME:GetPathS("","MenuMusic/common/Default (loop).ogg"),0,132,0,0,true)
		end
	end
end

-- This is the main function, Its the function that contains the wheel.
return function(Style)

    -- Load the songs from the Songs.Loader module.
	local Songs = LoadModule("Songs.Loader.lua")(Style)
	
	-- Sort the Songs and Group.
    local GroupsAndSongs = LoadModule("Group.Sort.lua")(Songs,CurGroup)
    
    -- We define here is we load the Options menu when people double press,
	-- Because they need to double press it starts at false.
	local StartOptions = false

    -- The main songwheel that contains all the songs.
    local SongWheel = Def.ActorFrame{Name="SongWheel"}

	local DiffStars = Def.ActorFrame{Name="DiffStars"}

    for i = 1,10 do

        -- Position of current song, We want the cd in the front, So its the one we change.
		local pos = CurSong+i-5
		
		-- Stay within limits.
		while pos > #GroupsAndSongs do pos = pos-#GroupsAndSongs end
		while pos < 1 do pos = #GroupsAndSongs+pos end

        SongWheel[#SongWheel+1] = Def.ActorFrame{
            Name="CD"..i,
            OnCommand=function(self)
                self:x((-280*5)+(280*i))
            end,
			Def.Quad{
				InitCommand=function(s)
					s:zoomto(234,234):diffuse(Alpha(Color.White,0.5))
				end,
			};
            Def.Sprite{
                Name="JacketTexture",
                Texture=THEME:GetPathG("","white.png"),
                OnCommand=function(self)
                    if type(GroupsAndSongs[pos]) ~= "string" then
                        if GroupsAndSongs[pos][1]:HasJacket() then self:Load(jk.GetSongGraphicPath(GroupsAndSongs[pos][1]))
                        elseif GroupsAndSongs[pos][1]:HasBackground() then self:Load(GroupsAndSongs[pos][1]:GetBackgroundPath()) 
                        end
                    else
                        if SONGMAN:GetSongGroupBannerPath(GroupsAndSongs[pos]) ~= "" then self:Load(jk.GetGroupGraphicPath(GroupsAndSongs[pos],"Jacket","SortOrder_Group")) end
                    end
                    self:zoomto(230,230) 
                end
			},

			Def.ActorFrame{
				Name="JacketOverlay",
				OnCommand=function(s)
					if type(GroupsAndSongs[pos]) == "string" then
						s:visible(true)
					else
						s:visible(false)
					end
				end,
				Def.Sprite{
					Texture=THEME:GetPathG("","_jackets/glow.png"),
					InitCommand=function(s) s:zoomto(230,230) end,
				};
				Def.BitmapText{
					Font="_avenirnext lt pro bold/10px",
					Text=THEME:GetString("MusicWheel","GROUPTop"),
					InitCommand=function(s) s:diffusealpha(0.9):y(-107):strokecolor(Alpha(Color.Black,0.5)) end,
				};
				Def.BitmapText{
					Font="_avenirnext lt pro bold/10px",
					Text=THEME:GetString("MusicWheel","GROUPBot"),
					InitCommand=function(s) s:diffusealpha(0.9):y(107):strokecolor(Alpha(Color.Black,0.5)) end,
				};
			};
        }


    end

     -- Here we return the actual Music Wheel Actor.
    return Def.ActorFrame{
        OnCommand=function(self)
            -- We use a Input function from the Scripts folder.
			-- It uses a Command function. So you can define all the Commands,
			-- Like MenuLeft is MenuLeftCommand.
			SCREENMAN:GetTopScreen():AddInputCallback(TF_WHEEL.Input(self))
			
			-- Sleep for 0.2 sec, And then load the current song music.
			self:sleep(0.2):queuecommand("PlayCurrentSong")

        end,
        
        -- Play Music at start of screen,.
		PlayCurrentSongCommand=function(self)
			if type(GroupsAndSongs[CurSong]) ~= "string" and GroupsAndSongs[CurSong][1]:GetMusicPath() then
				SOUND:PlayMusicPart(GroupsAndSongs[CurSong][1]:GetMusicPath(),GroupsAndSongs[CurSong][1]:GetSampleStart(),GroupsAndSongs[CurSong][1]:GetSampleLength(),1,1.5,true)
			else
				SOUND:PlayMusicPart(THEME:GetPathS("","MenuMusic/common/Default (loop).ogg"),0,132,0,0,true)
			end
        end,
        
        -- Do stuff when a user presses left on Pad or Menu buttons.
        MenuLeftCommand=function(self) 
			MoveSelection(self,-1,GroupsAndSongs)
			self:GetChild("WheelSound"):play()
			self:GetChild("Select"):GetChild("LeftCon"):stoptweening():x(-20):decelerate(0.5):x(0)
			self:GetChild("Select"):GetChild("LeftCon"):GetChild("LeftArrow"):stoptweening():diffuse(color("#ff00ea")):sleep(0.5):diffuse(color("#00f0ff"))
		end,
		
		-- Do stuff when a user presses Right on Pad or Menu buttons.
        MenuRightCommand=function(self) 
			MoveSelection(self,1,GroupsAndSongs)
			self:GetChild("WheelSound"):play()
			self:GetChild("Select"):GetChild("RightCon"):stoptweening():x(20):decelerate(0.5):x(0)
			self:GetChild("Select"):GetChild("RightCon"):GetChild("RightArrow"):stoptweening():diffuse(color("#ff00ea")):sleep(0.5):diffuse(color("#00f0ff"))
		 end,

		-- Do stuff when a user presses the Down on Pad or Menu buttons.
		MenuDownCommand=function(self) end,
		
		-- Do stuff when a user presses the Down on Pad or Menu buttons.
		MenuUpCommand=function(self) end,

        -- Do stuff when a user presses the Back on Pad or Menu buttons.
		BackCommand=function(self) 
			-- Check if User is joined.
			if Joined[self.pn] then
				if Joined[PLAYER_1] and Joined[PLAYER_2] then
					-- If both players are joined, We want to unjoin the player that pressed back.
					GAMESTATE:UnjoinPlayer(self.pn)
					Joined[self.pn] = false
					
					MoveSelection(self,0,GroupsAndSongs)
				else
					-- Go to the previous screen.
					SCREENMAN:GetTopScreen():SetNextScreenName(SCREENMAN:GetTopScreen():GetPrevScreenName()):StartTransitioningScreen("SM_GoToNextScreen") 
				end
			end
		end,

        -- Do stuff when a user presses the Start on Pad or Menu buttons.
		StartCommand=function(self)

			-- Check if we want to go to ScreenPlayerOptions instead of ScreenGameplay.
			if StartOptions then
				SCREENMAN:GetTopScreen():SetNextScreenName("ScreenPlayerOptions"):StartTransitioningScreen("SM_GoToNextScreen")
			end
			-- Check if player is joined.
			if Joined[self.pn] then 
			
				-- Check if we are on a group.
				if type(GroupsAndSongs[CurSong]) == "string" then
					self:GetChild("ExpandSound"):play()
				
					-- Check if we are on the same group thats currently open,
					-- If not we set the curent group to our new selection.
					if CurGroup ~= GroupsAndSongs[CurSong] then			
						CurGroup = GroupsAndSongs[CurSong]
						
					-- Same group, Close it.
					else
						CurGroup = ""
					end
					
					-- Reset the groups location so we dont bug.
					GroupsAndSongs = LoadModule("Group.Sort.lua")(Songs,"")
					MoveSelection(self,0,GroupsAndSongs)
					
					-- Set CurSong to the right group.
					for i,v in ipairs(GroupsAndSongs) do
						if v == CurGroup then
							CurSong = i
						end
					end

					-- Set the current group.
					GroupsAndSongs = LoadModule("Group.Sort.lua")(Songs,CurGroup)
					MoveSelection(self,0,GroupsAndSongs)
					
				-- Not on a group, Start song.
				else

					--We use PlayMode_Regular for now.
					GAMESTATE:SetCurrentPlayMode("PlayMode_Regular")
				
					--Set the song we want to play.
					GAMESTATE:SetCurrentSong(GroupsAndSongs[CurSong][1])
				
					-- Check if 2 players are joined.
					if Joined[PLAYER_1] and Joined[PLAYER_2] then
				
						-- If they are, We will use Versus.
						GAMESTATE:SetCurrentStyle('versus')
					
						-- Save Profiles.
						PROFILEMAN:SaveProfile(PLAYER_1)
						PROFILEMAN:SaveProfile(PLAYER_2)
					
						-- Set the Current Steps to use.
						GAMESTATE:SetCurrentSteps(PLAYER_1,GroupsAndSongs[CurSong][CurDiff])
						GAMESTATE:SetCurrentSteps(PLAYER_2,GroupsAndSongs[CurSong][CurDiff])
					else
				
						-- If we are single player, Use Single.
						GAMESTATE:SetCurrentStyle(TF_WHEEL.StyleDB[Style])
					
						-- Save Profile.
						PROFILEMAN:SaveProfile(self.pn)
					
						-- Set the Current Step to use.
						GAMESTATE:SetCurrentSteps(self.pn,GroupsAndSongs[CurSong][CurDiff])
					end
				
					-- We want to go to player options when people doublepress, So we set the StartOptions to true,
					-- So when the player presses Start again, It will go to player options.
					StartOptions = true

					-- Wait 0.4 sec before we go to next screen.
					self:sleep(0.4):queuecommand("StartSong")
				end
			else
				-- If no player is active Join.
				GAMESTATE:JoinPlayer(self.pn)
				
				-- Load the profles.
				GAMESTATE:LoadProfiles()
				
				-- Add to joined list.
				Joined[self.pn] = true
				
				MoveSelection(self,0,GroupsAndSongs)
			end			
		end,
		
		-- Change to ScreenGameplay.
		StartSongCommand=function(self)
			SCREENMAN:GetTopScreen():SetNextScreenName("ScreenGameplay"):StartTransitioningScreen("SM_GoToNextScreen")
		end,
		
		Def.Sprite{
			Texture=THEME:GetPathG("","_SelectMusic/wheelunder.png"),
			InitCommand=function(s) 
				s:xy(_screen.cx,_screen.cy+246)
			end,
			OnCommand=function(s) s:zoomtowidth(0):linear(0.2):zoomtowidth(SCREEN_WIDTH) end,
			OffCommand=function(s) s:sleep(0.3):decelerate(0.3):zoomtowidth(0) end,
		},

		SongWheel..{
			OnCommand=function(self)            
                self:xy(_screen.cx,_screen.cy+254):z(-200)
            end
		},

		Def.ActorFrame{
			Name="GroupLabel",
			InitCommand=function(s) s:xy(SCREEN_LEFT,_screen.cy+80):visible(false) end,
			Def.Sprite{
				Name="GroupBacker",
				Texture=THEME:GetPathG("","_SelectMusic/GLabel"),
				InitCommand=function(s) s:cropright(1) end,
				OnCommand=function(s) s:halign(0)
					if type(GroupsAndSongs[CurSong]) ~= "string" then
						s:diffuse(SongAttributes.GetGroupColor(GroupsAndSongs[CurSong][1]:GetGroupName()))
						:linear(0.15):cropright(0)
					end
				end,
			};
			Def.BitmapText{
				Name="GroupText",
				Font="_avenirnext lt pro bold/20px",
				InitCommand=function(s) s:cropright(1) end,
				OnCommand=function(s) s:halign(0)
					if type(GroupsAndSongs[CurSong]) ~= "string" then
						s:strokecolor(ColorDarkTone(SongAttributes.GetGroupColor(GroupsAndSongs[CurSong][1]:GetGroupName())))
						:settext("GROUP/"..SongAttributes.GetGroupName(GroupsAndSongs[CurSong][1]:GetGroupName()))
						:linear(0.15):cropright(0)
					end
				end,
			};
		},

		Def.ActorFrame{
			OnCommand=function(self)
				self:xy(_screen.cx,_screen.cy-190)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG("","_shared/_jacket back.png")
			},
		},

		-- Load the Global Centered Banner.
		Def.Sprite{
			Name="Banner",
			Texture=THEME:GetPathG("","white.png"),
			OnCommand=function(self)
				-- Check if we are on song
				if type(GroupsAndSongs[CurSong]) ~= "string" then
					self:Load(jk.GetSongGraphicPath(GroupsAndSongs[CurSong][1]))
					
				-- Not on song, Show group banner.
				else
					if jk.GetGroupGraphicPath(GroupsAndSongs[CurSong],"Jacket","SortOrder_Group") ~= "" then
						self:Load(jk.GetGroupGraphicPath(GroupsAndSongs[CurSong],"Jacket","SortOrder_Group"))
					else
						self:visible(false)
					end
				end
			
				self:xy(_screen.cx,_screen.cy-190):zoomto(378,378)
			end				
		},

		Def.ActorFrame{
			Name="BannerInfo",
			OnCommand=function(self)
				self:xy(_screen.cx,_screen.cy+60)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG("","_shared/titlebox.png")
			},
			Def.BitmapText{
				Name="Title",
				Font="_avenirnext lt pro bold/20px",
				OnCommand=function(self)
					self:maxwidth(400)
					-- Check if we are on song
					if type(GroupsAndSongs[CurSong]) ~= "string" then
						self:settext(ToUpper(GroupsAndSongs[CurSong][1]:GetDisplayMainTitle())):y(-6)
						:diffuse(SongAttributes.GetMenuColor(GroupsAndSongs[CurSong][1]))
						:strokecolor(ColorDarkTone(SongAttributes.GetMenuColor(GroupsAndSongs[CurSong][1])))
					else
						self:settext(SongAttributes.GetGroupName(GroupsAndSongs[CurSong])):y(6)
						:diffuse(SongAttributes.GetGroupColor(GroupsAndSongs[CurSong]))
						:strokecolor(ColorDarkTone(SongAttributes.GetGroupColor(GroupsAndSongs[CurSong])))
					end
				end
			},
			Def.BitmapText{
				Name="Artist",
				Font="_avenirnext lt pro bold/20px",
				OnCommand=function(self)
					self:y(20)
						:maxwidth(400)
					-- Check if we are on song
					if type(GroupsAndSongs[CurSong]) ~= "string" then
						self:settext(ToUpper(GroupsAndSongs[CurSong][1]:GetDisplayArtist()))
						:diffuse(SongAttributes.GetMenuColor(GroupsAndSongs[CurSong][1]))
						:strokecolor(ColorDarkTone(SongAttributes.GetMenuColor(GroupsAndSongs[CurSong][1])))
					end
				end
			}
		},

		Def.BitmapText{
			Name="BPM",
			Font="_avenirnext lt pro bold/25px",
			OnCommand=function(self)
				self:diffuse(1,1,1,1):aux(0)
				:xy(_screen.cx,_screen.cy+120):strokecolor(Alpha(Color.Black,0.5))
				-- Check if we are on song
				if type(GroupsAndSongs[CurSong]) ~= "string" then
					if GroupsAndSongs[CurSong][1]:IsDisplayBpmRandom() or GroupsAndSongs[CurSong][1]:IsDisplayBpmSecret() then
						counter = 0
						timer = GetUpdateTimer(targetDelta)
						self:diffuse(Color.Red)
						:aux(-1):settext("BPM 999"):GetParent():SetUpdateFunction(RandomBPM)
					else
						self:diffuse(Color.White)
						local dispBPMs = GroupsAndSongs[CurSong][1]:GetDisplayBpms()
						if GroupsAndSongs[CurSong][1]:IsDisplayBpmConstant() then
							self:settextf("BPM %03d",math.floor(dispBPMs[1]+0.5)):GetParent():SetUpdateFunction(nil)
						else
							self:settextf("BPM %03d - %03d",math.floor(dispBPMs[1]+0.5),math.floor(dispBPMs[2]+0.5)):GetParent():SetUpdateFunction(nil)
						end
					end
				end
			end
		},

		Def.ActorFrame{
			Name="Select",
			OnCommand=function(self)
				self:xy(_screen.cx,_screen.cy+264)
			end,
			Def.ActorFrame{
				Name="LeftCon",
				Def.ActorFrame{
					Name="Left",
					OnCommand=function(self)
						self:x(-155):bounce():effectclock("beat"):effectperiod(1):effectmagnitude(-10,0,0):effectoffset(0.2)
					end,
					Def.Sprite{ Texture=THEME:GetPathG("","_shared/arrows/base"), };
				},
				Def.Sprite{
					Name="LeftArrow",
					Texture=THEME:GetPathG("","_shared/arrows/color"),
					OnCommand=function(self)
						self:diffuse(color("#00f0ff")):x(-155):bounce():effectclock("beat"):effectperiod(1):effectmagnitude(-10,0,0):effectoffset(0.2)
					end
				}
			},
			Def.ActorFrame{
				Name="RightCon",
				Def.ActorProxy{
					OnCommand=function(self)
						self:SetTarget(self:GetParent():GetParent():GetChild("LeftCon"):GetChild("Left")):zoomx(-1)
					end
				},
				Def.Sprite{
					Name="RightArrow",
					Texture=THEME:GetPathG("","_shared/arrows/color"),
					OnCommand=function(self)
						self:diffuse(color("#00f0ff")):x(155):rotationy(180):bounce():effectclock("beat"):effectperiod(1):effectmagnitude(10,0,0):effectoffset(0.2)
					end
				}
			},
		};
		loadfile(THEME:GetPathB("","_HudPanels/Header/default.lua"))();
		loadfile(THEME:GetPathB("","_HudPanels/Help/default.lua"))();
		Def.BitmapText{
			Font="_stagetext",
			Text=ToEnumShortString(GAMESTATE:GetCurrentStage()):upper().." STAGE",
			OnCommand=function(self)
				self:diffuse(color("#dff0ff"))
					:strokecolor(Alpha(color("#00baff"),0.5))
					:xy(_screen.cx,SCREEN_TOP+104)
			end
		},

		Def.Sound{
			Name="WheelSound",
			File=THEME:GetPathS("","MWChange/Default_MWC.ogg"),
		},

		Def.Sound{
			Name="ExpandSound",
			File=THEME:GetPathS("","MusicWheel expand.ogg"),
		},
    }
end