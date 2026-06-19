local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.ArtAcademy.Config)

local MonetizationService = {}
local PlayerDataService = nil
local pushData = nil

local function grantBundle(player: Player)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	for _, itemId in { "brush_neon", "palette_candy", "title_quick_thinker" } do
		if not table.find(data.owned, itemId) then
			table.insert(data.owned, itemId)
		end
	end
	PlayerDataService.markDirty(player)
	pushData(player)
end

function MonetizationService.init(playerDataService, dataPushCallback)
	PlayerDataService = playerDataService
	pushData = dataPushCallback

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
		if purchased and gamePassId == Config.MONETIZATION.COSMETIC_BUNDLE_GAMEPASS_ID then
			grantBundle(player)
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local amount = nil
		if receiptInfo.ProductId == Config.MONETIZATION.COIN_PACK_SMALL_PRODUCT_ID then
			amount = 500
		elseif receiptInfo.ProductId == Config.MONETIZATION.COIN_PACK_LARGE_PRODUCT_ID then
			amount = 1500
		end
		if not amount then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local receiptKey = "receipt_" .. tostring(receiptInfo.PurchaseId)
		if PlayerDataService.grantReceipt(player, receiptKey, amount) then
			pushData(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function MonetizationService.onPlayerLoaded(player: Player)
	local id = Config.MONETIZATION.COSMETIC_BUNDLE_GAMEPASS_ID
	if id <= 0 then
		return
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
	end)
	if ok and owns then
		grantBundle(player)
	end
end

function MonetizationService.prompt(player: Player, productType: string)
	if productType == "bundle" then
		local id = Config.MONETIZATION.COSMETIC_BUNDLE_GAMEPASS_ID
		if id > 0 then
			MarketplaceService:PromptGamePassPurchase(player, id)
			return true
		end
	elseif productType == "coins_small" then
		local id = Config.MONETIZATION.COIN_PACK_SMALL_PRODUCT_ID
		if id > 0 then
			MarketplaceService:PromptProductPurchase(player, id)
			return true
		end
	elseif productType == "coins_large" then
		local id = Config.MONETIZATION.COIN_PACK_LARGE_PRODUCT_ID
		if id > 0 then
			MarketplaceService:PromptProductPurchase(player, id)
			return true
		end
	end
	return false
end

return MonetizationService
