local lib, oldMinor = LibStub:NewLibrary("LibBankTabSuitableItems-1.0", 1)
if not lib then return end

local itemRestrictions = Flags_CreateMask(
	-- Enum.BagSlotFlags.DisableAutoSort,
	Enum.BagSlotFlags.ClassEquipment,
	Enum.BagSlotFlags.ClassConsumables,
	Enum.BagSlotFlags.ClassProfessionGoods,
	Enum.BagSlotFlags.ClassJunk,
	Enum.BagSlotFlags.ClassQuestItems,
	-- Enum.BagSlotFlags.ExcludeJunkSell,
	Enum.BagSlotFlags.ClassReagents,
	Enum.BagSlotFlags.ExpansionCurrent,
	Enum.BagSlotFlags.ExpansionLegacy
)
local expansionRestrictions = Flags_CreateMask(
	Enum.BagSlotFlags.ExpansionCurrent,
	Enum.BagSlotFlags.ExpansionLegacy
)

local classMap = {
	[Enum.BagSlotFlags.ClassEquipment] = {
		Enum.ItemClass.Weapon,
		Enum.ItemClass.Armor,
		Enum.ItemClass.Gem, -- TEST
		Enum.ItemClass.Projectile, -- obsolete
		Enum.ItemClass.Quiver, -- obsolete
	},
	[Enum.BagSlotFlags.ClassConsumables] = {
		Enum.ItemClass.Consumable
	},
	[Enum.BagSlotFlags.ClassProfessionGoods] = {
		Enum.ItemClass.Profession, -- TEST
		Enum.ItemClass.Tradegoods,
		Enum.ItemClass.ItemEnhancement, -- TEST
		Enum.ItemClass.Recipe, -- TEST
		Enum.ItemClass.Glyph, -- TEST
	},
	[Enum.BagSlotFlags.ClassJunk] = {
		Enum.ItemClass.Miscellaneous, -- TEST
		Enum.ItemClass.Battlepet, -- TEST
		Enum.ItemClass.WoWToken, -- TEST
		Enum.ItemClass.Key, -- TEST
		Enum.ItemClass.Container, -- TEST
		Enum.ItemClass.CurrencyTokenObsolete, -- TEST
		Enum.ItemClass.PermanentObsolete, -- TEST
	},
	[Enum.BagSlotFlags.ClassQuestItems] = {
		Enum.ItemClass.Questitem,
	},
	[Enum.BagSlotFlags.ClassReagents] = {
		-- Does this also need to test the isCraftingReagent return from GetItemInfo?
		Enum.ItemClass.Reagent, -- TEST
	},
}

function lib:IsItemLocationSuitableForTab(itemLocation, bankType, tabID)
	if not C_Bank.IsItemAllowedInBankType(bankType, itemLocation) then
		return false
	end
	return self:IsItemSuitableForTab(C_Item.GetItemID(itemLocation), bankType, tabID)
end

--- Does the item fit the rules for the tab?
-- @param itemInfo Any valid argument for GetItemInfoInstant
-- @param bankType Enum.BankType
-- @param tabID number
-- @return Whether the item is appropriate; if nil, the data wasn't fetchable
function lib:IsItemSuitableForTab(itemInfo, bankType, tabID)
	-- See: https://warcraft.wiki.gg/wiki/API_C_Bank.FetchPurchasedBankTabData
	local data = self:GetTabData(bankType, tabID)
	if not (data and data.depositFlags) then return end
	local depositFlags = data.depositFlags
	if not FlagsUtil.IsAnySet(depositFlags, itemRestrictions) then
		-- There are no restrictions, so it must be fine
		return true
	end
	-- From here the item needs to affirmatively match the restrictions
	local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(itemInfo)
	if not itemID then
		return
	end

	for flag, itemClasses in pairs(classMap) do
		if FlagsUtil.IsSet(depositFlags, flag) and tContains(itemClasses, classID) then
			return true
		end
	end

	if FlagsUtil.IsAnySet(depositFlags, expansionRestrictions) then
		local expansionID = select(15, C_Item.GetItemInfo(itemInfo))
		if FlagsUtil.IsSet(depositFlags, Enum.BagSlotFlags.ExpansionCurrent) then
			return expansionID == LE_EXPANSION_LEVEL_CURRENT
		end
		return expansionID ~= LE_EXPANSION_LEVEL_CURRENT
	end
	return false
end

-- @return data, tabIndex, numTabs
function lib:GetTabData(bankType, tabID)
	-- This API will only return values when the bank is open
	if not C_Bank.CanViewBank(bankType) then return end
	local data = C_Bank.FetchPurchasedBankTabData(bankType)
	if not (data and #data > 0) then return end

	for i, tab in ipairs(data) do
		if tab.ID == tabID then
			return tab, i, #data
		end
	end
	-- If we reached here, you either have no purchased tabs of the correct
	-- type, or data wasn't loaded fully somehow
	return nil, nil, #data
end
