--!strict
-- ModuleScript: RestTypesTest.luau
-- Provides: RestTypesTest.run()

local RestTypesTest = {}

---------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------

local function hasKey(t: table, k: string)
	return t[k] ~= nil
end

---------------------------------------------------------------------
-- Runtime mocks required for chaining validation
---------------------------------------------------------------------

local FinalStageMock = {
	execute = function(self)
		return {}, nil
	end,
	executeTyped = function(self)
		return {}, nil
	end,
}

-- Mutation.select() stage
local MutationSelectStageMock: any = {}
function MutationSelectStageMock:single()
	return FinalStageMock
end
function MutationSelectStageMock:maybeSingle()
	return FinalStageMock
end
function MutationSelectStageMock:returns()
	return FinalStageMock
end
function MutationSelectStageMock:csv()
	return FinalStageMock
end
function MutationSelectStageMock:execute()
	return FinalStageMock.execute(self)
end
function MutationSelectStageMock:executeTyped()
	return FinalStageMock.executeTyped(self)
end

-- Mutation initial stage
local MutationInitialStageMock: any = {}
function MutationInitialStageMock:returns()
	return FinalStageMock
end
function MutationInitialStageMock:csv()
	return FinalStageMock
end
function MutationInitialStageMock:select()
	return MutationSelectStageMock
end
function MutationInitialStageMock:execute()
	return FinalStageMock.execute(self)
end
function MutationInitialStageMock:executeTyped()
	return FinalStageMock.executeTyped(self)
end

-- UpdateFilterStage
local UpdateFilterStageMock: any = {}

-- chainable filters
function UpdateFilterStageMock:eq() return UpdateFilterStageMock end
function UpdateFilterStageMock:neq() return UpdateFilterStageMock end
function UpdateFilterStageMock:gt() return UpdateFilterStageMock end
function UpdateFilterStageMock:gte() return UpdateFilterStageMock end
function UpdateFilterStageMock:lt() return UpdateFilterStageMock end
function UpdateFilterStageMock:lte() return UpdateFilterStageMock end
function UpdateFilterStageMock:in_() return UpdateFilterStageMock end
function UpdateFilterStageMock:contains() return UpdateFilterStageMock end
function UpdateFilterStageMock:or_() return UpdateFilterStageMock end

-- transition modifiers
function UpdateFilterStageMock:returns() return FinalStageMock end
function UpdateFilterStageMock:csv() return FinalStageMock end
function UpdateFilterStageMock:select() return MutationSelectStageMock end
function UpdateFilterStageMock:execute() return FinalStageMock.execute(self) end
function UpdateFilterStageMock:executeTyped() return FinalStageMock.executeTyped(self) end

-- Delete mirrors Update
local DeleteFilterStageMock: any = {}
for k, v in pairs(UpdateFilterStageMock) do
	DeleteFilterStageMock[k] = v
end

-- Select modifier stage
local SelectModifierStageMock: any = {}
function SelectModifierStageMock:order() return SelectModifierStageMock end
function SelectModifierStageMock:limit() return SelectModifierStageMock end
function SelectModifierStageMock:range() return SelectModifierStageMock end

function SelectModifierStageMock:single() return FinalStageMock end
function SelectModifierStageMock:maybeSingle() return FinalStageMock end
function SelectModifierStageMock:csv() return FinalStageMock end
function SelectModifierStageMock:returns() return FinalStageMock end

function SelectModifierStageMock:execute() return FinalStageMock.execute(self) end
function SelectModifierStageMock:executeTyped() return FinalStageMock.executeTyped(self) end

-- Select filter stage
local SelectFilterStageMock: any = {}

-- chainable filters
function SelectFilterStageMock:eq() return SelectFilterStageMock end
function SelectFilterStageMock:neq() return SelectFilterStageMock end
function SelectFilterStageMock:gt() return SelectFilterStageMock end
function SelectFilterStageMock:gte() return SelectFilterStageMock end
function SelectFilterStageMock:lt() return SelectFilterStageMock end
function SelectFilterStageMock:lte() return SelectFilterStageMock end
function SelectFilterStageMock:in_() return SelectFilterStageMock end
function SelectFilterStageMock:contains() return SelectFilterStageMock end

-- transitioning modifiers
function SelectFilterStageMock:order() return SelectModifierStageMock end
function SelectFilterStageMock:limit() return SelectModifierStageMock end
function SelectFilterStageMock:range() return SelectModifierStageMock end

function SelectFilterStageMock:single() return FinalStageMock end
function SelectFilterStageMock:maybeSingle() return FinalStageMock end
function SelectFilterStageMock:csv() return FinalStageMock end
function SelectFilterStageMock:returns() return FinalStageMock end

function SelectFilterStageMock:execute() return FinalStageMock.execute(self) end
function SelectFilterStageMock:executeTyped() return FinalStageMock.executeTyped(self) end

-- RPC mirrors select
local RPCFilterStageMock = SelectFilterStageMock

---------------------------------------------------------------------
-- Rest client mock
---------------------------------------------------------------------
local RestClientMock: any = {}
function RestClientMock:from()
	return {
		select = function(_, _cols) return SelectFilterStageMock end,
		insert = function(_, _values) return MutationInitialStageMock end,
		update = function(_, _values) return UpdateFilterStageMock end,
		delete = function(_, _opts) return DeleteFilterStageMock end,
		upsert = function(_, _values) return MutationInitialStageMock end,
		rpc = function(_, _fnName, _params) return RPCFilterStageMock end,
	}
end

---------------------------------------------------------------------
-- All tests executed here
---------------------------------------------------------------------
local function runTests()
	local client = RestClientMock
	local root = client:from()

	-- update without select
	local u = root:update({ name = "x" })
	assert(hasKey(u, "select"), "update should expose select")
	assert(not hasKey(u, "single"), "update should NOT expose single initially")
	assert(not hasKey(u, "maybeSingle"), "update should NOT expose maybeSingle initially")

	-- update.select chain
	local usel = u:select("*")
	assert(hasKey(usel, "single"), "update.select must expose single")
	assert(hasKey(usel, "maybeSingle"), "update.select must expose maybeSingle")

	local finalU = usel:single()
	assert(hasKey(finalU, "execute"), "final stage must expose execute")
	assert(not hasKey(finalU, "select"), "final must not expose select")

	-- insert
	local ins = root:insert({ a = 1 })
	assert(not hasKey(ins, "single"), "insert initial must NOT expose single")
	assert(hasKey(ins, "select"), "insert initial must expose select")

	local insSel = ins:select("*")
	assert(hasKey(insSel, "maybeSingle"), "insert.select must expose maybeSingle")
	local insFinal = insSel:maybeSingle()
	assert(hasKey(insFinal, "execute"), "insert final must expose execute")

	-- delete
	local d = root:delete()
	assert(not hasKey(d, "single"), "delete initial must NOT expose single")
	assert(hasKey(d, "select"), "delete must expose select")

	-- select filter → modifier → final
	local s = root:select("*")
	local s2 = s:eq("id", 1):gt("age", 10)
	local smod = s2:order("name")
	assert(hasKey(smod, "limit"), "modifier stage must allow more modifiers")

	local sfinal = smod:single()
	assert(hasKey(sfinal, "execute"), "select final must expose execute")
	assert(not hasKey(sfinal, "eq"), "final stage must NOT allow filters")

	print("[RestTypesTest] All runtime shape tests passed successfully.")
end

---------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------
function RestTypesTest.run()
	runTests()
end

return RestTypesTest
