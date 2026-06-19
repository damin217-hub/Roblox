local AnalyticsService = game:GetService("AnalyticsService")

local TelemetryService = {}

function TelemetryService.log(player: Player, eventName: string, value: number?, fields)
	if not player or player.Parent == nil then
		return
	end
	pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value, fields)
	end)
end

function TelemetryService.logMany(players, eventName: string, value: number?, fields)
	for _, player in players do
		TelemetryService.log(player, eventName, value, fields)
	end
end

return TelemetryService
