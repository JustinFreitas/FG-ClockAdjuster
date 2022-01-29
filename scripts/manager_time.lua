--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

CAL_CLOCKADJUSTERNOTIFY = "calendar.clockadjusternotify";
CAL_CHK_DAY = "calendar.check.day";
CAL_CUR_DAY = "calendar.current.day";
CAL_CUR_HOUR = "calendar.current.hour";
CAL_CUR_MIN = "calendar.current.minute";
CAL_CUR_MONTH = "calendar.current.month";
CAL_CUR_YEAR = "calendar.current.year";
CAL_NEWCAMPAIGN = "calendar.newcampaign";
CLOCKADJUSTER_DEFAULT_HOURS = "CLOCKADJUSTER_DEFAULT_HOURS";
CLOCKADJUSTER_DEFAULT_MINUTES = "CLOCKADJUSTER_DEFAULT_MINUTES";
CLOCKADJUSTER_DEFAULT_DAYS = "CLOCKADJUSTER_DEFAULT_DAYS";
CLOCKADJUSTER_DEFAULT_MONTHS = "CLOCKADJUSTER_DEFAULT_MONTHS";
CLOCKADJUSTER_DEFAULT_YEARS = "CLOCKADJUSTER_DEFAULT_YEARS";
CLOCKADJUSTER_DEFAULT_LONG = "CLOCKADJUSTER_DEFAULT_LONG";
CLOCKADJUSTER_DEFAULT_SHORT = "CLOCKADJUSTER_DEFAULT_SHORT";
CLOCKADJUSTER_HOURS_OPTIONS = "1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23";
CLOCKADJUSTER_MINUTES_OPTIONS = "1|2|3|4|5|6|7|8|9|10|15|20|25|30|45|59";
CLOCKADJUSTER_DAYS_OPTIONS = "1|2|3|4|5|6|7|8|9|10|15|20|25|28|29|30";
CLOCKADJUSTER_MONTHS_OPTIONS = "1|2|3|4|5|6|7|8|9|10|11";
CLOCKADJUSTER_YEARS_OPTIONS = "1|2|3|4|5|6|7|8|9|10|15|20|25|50|75|100|150|200|250|500";
CLOCKADJUSTER_LONG_OPTIONS = "1|4|8|9|10|11|12|24|36|48";
CLOCKADJUSTER_SHORT_OPTIONS = "1|5|10|15|20|25|30|45|60|90|120";
REMINDER_REPEATTIME = "reminder.repeattime";

local bNoticePosted = false;

function onInit()
	initializeNotificationMechanism();

	-- Options for the Clock Manager add defaults
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_HOURS, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_HOURS", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_HOURS_OPTIONS, values = CLOCKADJUSTER_HOURS_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_MINUTES, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_MINUTES", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_MINUTES_OPTIONS, values = CLOCKADJUSTER_MINUTES_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_DAYS, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_DAYS", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_DAYS_OPTIONS, values = CLOCKADJUSTER_DAYS_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_MONTHS, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_MONTHS", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_MONTHS_OPTIONS, values = CLOCKADJUSTER_MONTHS_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_YEARS, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_YEARS", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_YEARS_OPTIONS, values = CLOCKADJUSTER_YEARS_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_LONG, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_LONG", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_LONG_OPTIONS, values = CLOCKADJUSTER_LONG_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_SHORT, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_SHORT", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_SHORT_OPTIONS, values = CLOCKADJUSTER_SHORT_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });

	OptionsManager.registerOption2("TIMEROUNDS", false, "option_header_CLOCKADJUSTER", "opt_lab_time_rounds", "option_entry_cycler",
		{ labels = "enc_opt_time_rounds_slow", values = "slow", baselabel = "enc_opt_time_rounds_fast", baseval = "fast", default = "fast" });
end

function initializeNotificationMechanism()
	DB.addHandler("calendar.log", "onChildUpdate", onEventsChanged);
	DB.deleteNode("calendar.dateinminutes"); -- clean up after old mechanism, no longer needed.
	DB.deleteNode("calendar.dateinminutesstring"); -- clean up after old mechanism, no longer needed.
	DB.setValue(CAL_CLOCKADJUSTERNOTIFY, "number", 0); -- initialize the new notification mechanism
end

--- Timer Functions
function setStartTime(nodeActor, nStartTimeOverride, nStartTimeYearOverride)
	local nStartTime = nStartTimeOverride;
	local nStartTimeYear = nStartTimeYearOverride;
	if not nStartTimeOverride or not nStartTimeYearOverride then
		nStartTime = getCurrentDateWithoutYearsInMinutes();
		nStartTimeYear = getCurrentYear();
	end

	DB.setValue(nodeActor, "starttime", "number", nStartTime);
	DB.setValue(nodeActor, "starttimeyear", "number", nStartTimeYear);
end

function getCurrentYear()
	return DB.getValue(CAL_CUR_YEAR, 0);
end

function getStartTime(nodeActor)
	local nStartTime = DB.getValue(nodeActor, "starttime", 0);
	local nStartTimeYear = DB.getValue(nodeActor, "starttimeyear", 1);
	return nStartTime, nStartTimeYear;
end

-- prints a big error message in the Chatwindow
function bigMessage(msgtxt, broadcast, rActor)
	local msg = ChatManager.createBaseMessage(rActor);
	msg.text = msg.text .. msgtxt;
	msg.font = "reference-header";

	if broadcast then
		Comm.deliverChatMessage(msg);
	else
		msg.secret = true;
		Comm.addChatMessage(msg);
	end
end

function getCurrentDate()
	local nMinutes = DB.getValue(CAL_CUR_MIN, 0);
	local nHours = DB.getValue(CAL_CUR_HOUR, 0);
	local nDays = DB.getValue(CAL_CUR_DAY, 0);
	local nMonths = DB.getValue(CAL_CUR_MONTH, 0);
	local nYears = DB.getValue(CAL_CUR_YEAR, 0);

	if bNoticePosted == false and
	   (not DB.getValue("calendar.data.complete") or
	   (not nMinutes or not nHours or not nDays or not nMonths or not nYears)) then
		bigMessage(Interface.getString("error_calendar_not_configured"));
		bNoticePosted = true;
	end

	return nMinutes, nHours, nDays, nMonths, nYears;
end

function getCurrentDateWithoutYearsInMinutes()
	local nMinutes, nHours, nDays, nMonths, nYears = getCurrentDate();
	local nRounds = math.max(DB.getValue(CombatManager.CT_ROUND, 0), 0) % 10;  -- Prevent negative
	local nRoundsinMinutes = 0.1 * nRounds;
	local nHoursinMinutes = convertHourstoMinutes(nHours);
	local nDaysinMinutes = convertDaystoMinutes(nDays);
	local nMonthsinMinutes = convertMonthssnowtoMinutes(nMonths, nYears);
	local nDateinMinutes = nRoundsinMinutes + nHoursinMinutes + nDaysinMinutes + nMonthsinMinutes + nMinutes;
	return nDateinMinutes;
end

--- Compare times, only called from list_timedreminder.onTimeChanged() in desktop_panels.xml.
function isTimeGreaterThan(nodeTimedReminder, nRepeatTime, nReminderCycle)
	-- For reminder cycle, 0 is minute, 1 is hour, 2 is day.
	local nCompareBy = nReminderCycle;
	if nRepeatTime == 1 then
		nCompareBy = nReminderCycle * 60;
	elseif nRepeatTime == 2 then
		nCompareBy = nReminderCycle * 60 * 24;
	end

	local nStartTime, nStartTimeYear = getStartTime(nodeTimedReminder);
	local nCurrentTime = getCurrentDateWithoutYearsInMinutes();
	local nCurrentYear = getCurrentYear();
	local nDifferenceYearInMinutes = convertYearsnowtoMinutes(nCurrentYear) - convertYearsnowtoMinutes(nStartTimeYear);
	local nDifference = math.abs(nCurrentTime - nStartTime); -- Fix for current/saved getting swapped.
	if nDifference + nDifferenceYearInMinutes >= nCompareBy then
		setStartTime(nodeTimedReminder, nCurrentTime, nCurrentYear);
		return true;
	end

	return false;
end

function onTimeChangedEvent(nodeEvent, sName, nCompleted, nVisibleAll, nEventMinute, nEventHour, nEventDay, nEventMonth, nEventYear)
	local nCurrentDateinMinutes = getCurrentDateWithoutYearsInMinutes();
	local nCurrentYear = getCurrentYear();
	local nHoursinMinutes = convertHourstoMinutes(nEventHour);
	local nDaysinMinutes = convertDaystoMinutes(nEventDay);
	local nMonthsinMinutes = convertMonthssnowtoMinutes(nEventMonth, nEventYear);
	local nDateinMinutes = nHoursinMinutes + nDaysinMinutes + nMonthsinMinutes + nEventMinute;
	if nCompleted == 0 and (nCurrentYear > nEventYear or nCurrentDateinMinutes >= nDateinMinutes) then
		local msg = {font = "reference-r", text = "[" .. nEventHour .. ":" .. nEventMinute .. "/" .. nEventDay .. "/" .. nEventMonth .. "/" .. nEventYear .. "] " .. sName .. "", secret = nVisibleAll == 0};
		Comm.deliverChatMessage(msg);
		if TableManager.findTable(sName) then
			TableManager.processTableRoll("", sName);
		end

		addLogEntry(nEventMonth, nEventDay, nEventYear, nVisibleAll == 0, nodeEvent);
		return 1;
	end

	return 0;
end

function onTimeChangedReminder(nodeTimedReminder, sName, nRepeatTime, nReminderCycle, nVisibleAll, nActive)
	local nDate = CalendarManager.getCurrentDateString();
	local nTime = CalendarManager.getCurrentTimeString();
	local nDateAndTime = "" .. nTime .. " " .. nDate .. "";
	if nActive == 1 and isTimeGreaterThan(nodeTimedReminder, nRepeatTime, nReminderCycle) then
		local msg = {font = "reference-r", text = "[" .. nDateAndTime .. "] " .. sName .. "", secret = nVisibleAll == 0};
		Comm.deliverChatMessage(msg);
		if TableManager.findTable(sName) then
			TableManager.processTableRoll("", sName);
		end
	end
end

--- Time conversion functions
function convertHourstoMinutes(nNumber)
	return nNumber * 60;
end

function convertDaystoHours(nNumber)
	return nNumber * 24;
end

function convertDaystoMinutes(nNumber)
	local nDaysinHours = convertDaystoHours(nNumber);
	local nMinutesTotaled = convertHourstoMinutes(nDaysinHours);
	return nMinutesTotaled;
end

function convertMonthtoMinutes(nMonth, nYear)
	local nDays = getDaysInMonth(nMonth, nYear);
	local nMinutesTotaled = convertDaystoMinutes(nDays);
	return nMinutesTotaled;
end

function convertYeartoHours(nNumber)
	local nYearInDays = 365;
	if isLeapYear(nNumber) then
		nYearInDays = nYearInDays + 1;
	end

	return nYearInDays * 24;
end

function convertYearsnowtoMinutes(nYear)
	local nMinutesTotaled = 0
	for nYearCount = 1, nYear do
		local nYearinHours = convertYeartoHours(nYearCount);
		nMinutesTotaled = nMinutesTotaled + convertHourstoMinutes(nYearinHours);
	end

	return nMinutesTotaled;
end

function convertMonthssnowtoMinutes(nMonth, nYear)
	local nMinutes = 0;
	for nCount = 1, nMonth do
		nMinutes = convertMonthtoMinutes(nCount, nYear) + nMinutes;
	end

	return nMinutes;
end

--- Extra calculations
function getDaysInMonth(nMonth, nYear)
	local nVar = 0;
	local nDays = DB.getValue("calendar.data.periods.period" .. nMonth .. ".days", 0);
	if nMonth == 2 and isLeapYear(nYear) then
		nVar = nVar + 1;
	end

	return nDays + nVar;
end

function isLeapYear(nYear)
	return nYear % 4 == 0 and
		   (nYear % 100 ~= 0 or nYear % 400 == 0);
end

local aEvents = {};

function buildEvent(nodeLogEntry)
	if not nodeLogEntry then return end;

	local nYear = DB.getValue(nodeLogEntry, "year", 0);
	local nMonth = DB.getValue(nodeLogEntry, "month", 0);
	local nDay = DB.getValue(nodeLogEntry, "day", 0);
	if not aEvents[nYear] then
		aEvents[nYear] = {};
	end

	if not aEvents[nYear][nMonth] then
		aEvents[nYear][nMonth] = {};
	end

	aEvents[nYear][nMonth][nDay] = nodeLogEntry;
end

function buildEvents()
	aEvents = {};
	for _, nodeLogEntry in pairs(DB.getChildren("calendar.log")) do
		buildEvent(nodeLogEntry);
	end
end

function onEventsChanged() -- addHandler() onChildUpdate(nodeParent, nodeChildUpdated)
	buildEvents();
end

function notifyControlsOfUpdate()
	DB.setValue(CAL_CLOCKADJUSTERNOTIFY, "number", DB.getValue(CAL_CLOCKADJUSTERNOTIFY, 0) + 1);
end

function onUpdateAddControl()
	notifyControlsOfUpdate();
	local nCurrentRound = DB.getValue(CombatManager.CT_ROUND, 0);
	nCurrentRound = nCurrentRound % 10
	DB.setValue(CombatManager.CT_ROUND, 'number', nCurrentRound);
end

function addLogEntry(nMonth, nDay, nYear, bGMVisible, nodeEvent)
	local nodeLogEntry;
	local sName = DB.getValue(nodeEvent, "name", "");
	local sString = DB.getValue(nodeEvent, "text", "");
	local nMinute = DB.getValue(nodeEvent, "minute", 0);
	local sMinute = tostring(nMinute);
	local nHour = DB.getValue(nodeEvent, "hour", 0);
	local sHour = tostring(nHour);

	if nHour < 10 then
		sHour = "0" .. sHour;
	end

	if nMinute < 10 then
		sMinute = "0" .. sMinute;
	end

	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		nodeLogEntry = aEvents[nYear][nMonth][nDay];
		local EventGMLog = DB.getValue(nodeLogEntry, "gmlogentry", "");
		local EventGMLogNew = string.gsub(EventGMLog, "%W", "");
		local EventLog = DB.getValue(nodeLogEntry, "logentry", "");
		local EventLogNew = string.gsub(EventLog, "%W", "");
		if bGMVisible then
			if not string.find(EventGMLogNew, sHour .. "" .. sMinute) then
				sString = EventGMLog .. "<h>" .. sName .. " [" .. sHour .. " hr : " .. sMinute .. " min]" .. "</h>" .. sString;
				DB.setValue(nodeLogEntry, "gmlogentry", "formattedtext", sString);
			end
		else
			if not string.find(EventLogNew, sHour .. "" .. sMinute) then
				sString = EventLog .. "<h>" .. sName .. " [" .. sHour .. " hr : " .. sMinute .. " min]" .. "</h>" .. sString;
				DB.setValue(nodeLogEntry, "logentry", "formattedtext", sString);
			end
		end
	elseif Session.IsHost then
		local nodeLog = DB.createNode("calendar.log");
		nodeLogEntry = nodeLog.createChild();
		sString = "<h>" .. sName .. " [" .. sHour .. " hr : " .. sMinute .. " min]" .. "</h>" .. sString;

		DB.setValue(nodeLogEntry, "epoch", "string", DB.getValue("calendar.current.epoch", ""));
		DB.setValue(nodeLogEntry, "year", "number", nYear);
		DB.setValue(nodeLogEntry, "month", "number", nMonth);
		DB.setValue(nodeLogEntry, "day", "number", nDay);
		if bGMVisible then
			DB.setValue(nodeLogEntry, "gmlogentry", "formattedtext", sString);
		else
			DB.setValue(nodeLogEntry, "logentry", "formattedtext", sString);
		end
	end

	if nodeLogEntry then
		Interface.openWindow("advlogentry", nodeLogEntry);
	end

	return nodeLogEntry;
end
