-- Module for date and time calculations

nut.date = nut.date or {}
nut.date.diff = nut.date.diff or 0

if (not nut.config) then
    include("nutscript/gamemode/core/sh_config.lua")
end

if SERVER then
	util.AddNetworkString("syncClientTime")

	nut.date.syncClientTime = function(client)
		net.Start("syncClientTime")
		net.WriteString(tostring(nut.date.diff))
		net.Send(client)
	end
end

nut.config.add("year", tonumber(os.date("%Y")), "The current year of the schema." , function()
	if SERVER then
		for k, client in pairs(player.GetHumans()) do
			nut.date.syncClientTime(client)
		end
	end
end, {
    data = {min = 0, max = 4000},
    category = "date"
}
)

nut.config.add("month", tonumber(os.date("%m")), "The current month of the schema." , function()
	if SERVER then
		for k, client in pairs(player.GetHumans()) do
			nut.date.syncClientTime(client)
		end
	end
end, {
    data = {min = 1, max = 12},
    category = "date"
}
)

nut.config.add("day", tonumber(os.date("%d")), "The current day of the schema." , function()
	if SERVER then
		for k, client in pairs(player.GetHumans()) do
			nut.date.syncClientTime(client)
		end
	end
end, {
    data = {min = 1, max = 31},
    category = "date"
}
)

nut.config.add("yearAppendix", "", "Add a custom appendix to your date, if you use a non-conventional calender", nil, {
	data = {form = "Generic"},
	category = "date"
}
)

-- function returns a number that represents the custom time. the year is always the current year for 
-- compatibility, though it can be editted with nut.date.getFormatted

function nut.date.get()
	return os.time({
		year=os.date("%Y"),
		month=nut.config.get("month"),
		day=nut.config.get("day"),
		hour=os.date("!%H"),
		min=os.date("!%M"),
		sec=os.date("!%S")
	}) + (nut.date.diff or 0)
end

--function takes the time number if provided, or current time and applies a string format to it

function nut.date.getFormatted(format, dateNum)
	return os.date(format, dateNum or nut.date.get())
end

if SERVER then

	-- This is internal, though you can use it you probably shouldn't. 
	-- Checks the time difference between the old time values and current time, and updates month and day to advance in the time difference
	-- creates a timer that updates the month and day values, in case the server runs continuously without restarts.
	function nut.date.initialize()
		local function getTimeZoneDifference()
  			local now = os.time()
  			return now - os.time(os.date("!*t", now))
		end

		nut.date.diff = getTimeZoneDifference()

		-- Migrations
		if (istable(nut.data.get("date", os.time(), true))) then
			nut.data.set("date", os.time(), true, true)
		end

		local configTime = os.time({
			year = tonumber(os.date("%Y")),
			month = tonumber(nut.config.get("month")),
			day = tonumber(nut.config.get("day")),
			hour = tonumber(os.date("%H")),
			min = os.date("%M"),
        	sec = os.date("%S")
		}) + os.difftime(os.time(), nut.data.get("date", os.time(), true))

		nut.config.set("month", tonumber(os.date("%m", configTime)))
		nut.config.set("day", tonumber(os.date("%d", configTime)))

		-- internal function that calculates when the day ends, and updates the month/day when the next day comes.
		-- the reason for this complication instead of just upvaluing day/month by 1 is that some months have 28, 30 or 31 days.
		-- and its simpler for the server to decide what the next month should be rather than manually computing that
		local function updateDateConfigs()
			local curDateTable = os.date("*t") -- get the current date table
			local remainingSeconds = (curDateTable.hour * -3600 - curDateTable.min * 60 - curDateTable.sec) % 86400 -- get the remaining seconds until the new day

			timer.Simple(remainingSeconds, function() -- run this code only once the day changes
				local newTime = os.time({
					year = tonumber(os.date("%Y")),
					month = tonumber(nut.config.get("month")),
					day = tonumber(nut.config.get("day")),
					hour = tonumber(os.date("%H")),
					min = os.date("%M"),
					sec = os.date("%S")
				}) + 86400 -- 24 hours.

				nut.config.set("month", tonumber(os.date("%m", newTime)))
				nut.config.set("day", tonumber(os.date("%d", newTime)))
				updateDateConfigs() -- create a new timer for the next day
			end)
		end

		updateDateConfigs()
	end

	-- saves the current actual time. This allows the time to find the difference in elapsed time between server shutdown and startup
	function nut.date.save()
		nut.data.set("date", os.time(), true, true)
	end

	hook.Add("InitializedConfig", "nutInitializeTime", function()
		nut.date.initialize()
	end)

	hook.Add("SaveData", "nutDateSave", function()
		nut.date.save()
	end)

	net.Receive("syncClientTime", function(_, client)
		nut.date.syncClientTime(client)
	end)

elseif CLIENT then
	net.Receive("syncClientTime", function()
		nut.date.diff = tonumber(net.ReadString())
	end)

	hook.Add("InitPostEntity", "nutSyncTime", function()
		net.Start("syncClientTime")
		net.SendToServer()
	end)
end