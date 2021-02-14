-- Module for date and time calculations

nut.date = nut.date or {}
nut.date.start = nut.date.start or os.time()

if (not nut.config) then
    include("nutscript/gamemode/core/sh_config.lua")
end

nut.config.add("year", tonumber(os.date("%Y")), "The current year of the schema." , nil, {
    data = {min = 0, max = 4000},
    category = "date"
}
)

nut.config.add("month", tonumber(os.date("%m")), "The current month of the schema." , nil, {
    data = {min = 1, max = 12},
    category = "date"
}
)

nut.config.add("day", tonumber(os.date("%d")), "The current day of the schema." , nil, {
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
        hour=os.date("%H"),
        min=os.date("%M"),
        sec=os.date("%S")
    })
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

		timer.Create("nutUpdateDate", 300, 0, function()
			local configTime = os.time({
				year = tonumber(os.date("%Y")),
				month = tonumber(nut.config.get("month")),
				day = tonumber(nut.config.get("day")),
				hour = tonumber(os.date("%H")),
				min = os.date("%M"),
				sec = os.date("%S")
			}) + os.difftime(os.time(), nut.date.start)

			nut.config.set("month", tonumber(os.date("%m", configTime)))
			nut.config.set("day", tonumber(os.date("%d", configTime)))
			nut.date.start = os.time()
		end)
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
end
