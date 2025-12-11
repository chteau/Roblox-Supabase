--[[
    Unit testing framework for Supabase REST client in Luau.

    This module provides comprehensive unit tests for all Supabase REST client functionality,
    including filters, modifiers, mutations, and complex query combinations. All tests are
    specifically designed against the exact data structure and values in the 'unittests' table.

    @module UnitTests
    @private
]]
local UnitTests = {}
UnitTests.__index = UnitTests

local RestTypesTest = require(script:FindFirstChild("RestTypesTest"))

export type UnitTests = {
    client: any, -- SupabaseClient

    new: (client: any) -> UnitTests,
    runAllTests: (self: UnitTests) -> (),
}

--[[
    Creates a new UnitTests instance.

    @param client any -- Supabase client instance to test
    @return UnitTests -- New UnitTests instance
]]
function UnitTests.new(client: any)
    local self = setmetatable({}, UnitTests)

    self.client = client
    return self
end

--[[
    Tests equality filters (eq operator) against specific records in the database.

    Tests John Doe (id=1, email=john.doe@example.com) and JSON Test (id=7, email=json.test@example.com)

    @throws AssertionError if tests fail
]]
function UnitTests:runEqualityTest()
    print("SUPABASE> Running Equality Test...")

    -- Test for JSON Test record (id=7, email=json.test@example.com)
    local DataTest1, ErrorTest1 = self.client
        :from("unittests")
        :select()
        :eq("id", 7)
        :execute()

    -- Test for John Doe record (id=1, email=john.doe@example.com)
    local DataTest2, ErrorTest2 = self.client
        :from("unittests")
        :select()
        :eq("email", "john.doe@example.com")
        :execute()

    -- Check that both queries returned a not empty result
    assert(DataTest1 ~= nil and #DataTest1 > 0, "SUPABASE> First equality test returned no results.")
    assert(DataTest2 ~= nil and #DataTest2 > 0, "SUPABASE> Second equality test returned no results.")

    -- Verify specific values
    assert(DataTest1[1].name == "JSON Test", "SUPABASE> First test didn't return JSON Test record.")
    assert(DataTest2[1].name == "John Doe", "SUPABASE> Second test didn't return John Doe record.")

    -- Check for errors
    assert(ErrorTest1 == nil, "SUPABASE> Error in first equality test: " .. tostring(ErrorTest1))
    assert(ErrorTest2 == nil, "SUPABASE> Error in second equality test: " .. tostring(ErrorTest2))

    print("SUPABASE> Equality Test Passed.")
end

--[[
    Tests inequality filters (neq operator) against status values.

    Should return all records except Bob Johnson (id=3) and Range Test (id=8) which have status='inactive'

    @throws AssertionError if tests fail
]]
function UnitTests:runInequalityTest()
    print("SUPABASE> Running Inequality Test...")

    local DataTest, ErrorTest = self.client
        :from("unittests")
        :select("id, name, status")
        :neq("status", "inactive")
        :execute()

    -- Check that the query returned results (should return 7 records, excluding the 2 inactive ones)
    assert(DataTest ~= nil and #DataTest > 0, "SUPABASE> Inequality test returned no results.")
    assert(#DataTest == 7, "SUPABASE> Expected 7 non-inactive records, got " .. #DataTest)

    -- Check that none of the returned rows have status "inactive"
    for _, row in ipairs(DataTest) do
        assert(row.status ~= "inactive", "SUPABASE> Inequality test failed: found a row with status 'inactive'.")
    end

    -- Check for errors
    assert(ErrorTest == nil, "SUPABASE> Error in inequality test: " .. tostring(ErrorTest))

    print("SUPABASE> Inequality Test Passed.")
end

--[[
    Tests comparison operators against actual data values.

    Tests:
    - gt("age", 30): Should return Bob Johnson (35), Search Test User (42), JSON Test (33), Range Test (45)
    - gte("price", 99.99): Should return John Doe (99.99), Jane Smith (149.99), Search Test User (299.99), JSON Test (399.99), Range Test (599.99)
    - lt("rating", 4.0): Should return Alice Williams (3.9), Array Test (3.5), Range Test (2.5), Minimal Record (0)
    - lte("score", 65): Should return Array Test (65), Minimal Record (0)

    @throws AssertionError if tests fail
]]
function UnitTests:runComparaisonTest()
    print("SUPABASE> Running Comparison Tests...")

    -- Greater Than Test: age > 30
    local DataGT, ErrorGT = self.client
        :from("unittests")
        :select("id, name, age")
        :gt("age", 30)
        :execute()

    assert(DataGT ~= nil and #DataGT == 4, "SUPABASE> Greater Than test expected 4 records, got " .. (#DataGT or 0))
    for _, row in ipairs(DataGT) do
        assert(row.age > 30, "SUPABASE> Greater Than test failed: " .. row.name .. " has age " .. row.age .. " <= 30")
    end
    assert(ErrorGT == nil, "SUPABASE> Error in Greater Than test: " .. tostring(ErrorGT))

    -- Greater Than or Equal Test: price >= 99.99
    local DataGTE, ErrorGTE = self.client
        :from("unittests")
        :select("id, name, price")
        :gte("price", 99.99)
        :execute()

    assert(DataGTE ~= nil and #DataGTE == 5, "SUPABASE> Greater Than or Equal test expected 5 records, got " .. (#DataGTE or 0))
    for _, row in ipairs(DataGTE) do
        assert(row.price >= 99.99, "SUPABASE> Greater Than or Equal test failed: " .. row.name .. " has price " .. row.price .. " < 99.99")
    end
    assert(ErrorGTE == nil, "SUPABASE> Error in Greater Than or Equal test: " .. tostring(ErrorGTE))

    -- Less Than Test: rating < 4.0
    local DataLT, ErrorLT = self.client
        :from("unittests")
        :select("id, name, rating")
        :lt("rating", 4.0)
        :execute()

    assert(DataLT ~= nil and #DataLT == 4, "SUPABASE> Less Than test expected 4 records, got " .. (#DataLT or 0))
    for _, row in ipairs(DataLT) do
        assert(row.rating < 4.0, "SUPABASE> Less Than test failed: " .. row.name .. " has rating " .. row.rating .. " >= 4.0")
    end
    assert(ErrorLT == nil, "SUPABASE> Error in Less Than test: " .. tostring(ErrorLT))

    -- Less Than or Equal Test: score <= 65
    local DataLTE, ErrorLTE = self.client
        :from("unittests")
        :select("id, name, score")
        :lte("score", 65)
        :execute()

    assert(DataLTE ~= nil and #DataLTE == 3, "SUPABASE> Less Than or Equal test expected 2 records, got " .. (#DataLTE or 0))
    for _, row in ipairs(DataLTE) do
        assert(row.score <= 65, "SUPABASE> Less Than or Equal test failed: " .. row.name .. " has score " .. row.score .. " > 65")
    end
    assert(ErrorLTE == nil, "SUPABASE> Error in Less Than or Equal test: " .. tostring(ErrorLTE))

    print("SUPABASE> Comparison Tests Passed.")
end

--[[
    Tests text search operators against specific text patterns.

    Tests:
    - like("%John%"): Should match "John Doe" and "Bob Johnson"
    - ilike("%software%"): Should match John Doe's description

    @throws AssertionError if tests fail
]]
function UnitTests:runTextSearch()
    print("SUPABASE> Running Text Search Test...")

    -- Like Test: name containing "John"
    local DataLike, ErrorLike = self.client
        :from("unittests")
        :select("id, name")
        :like("name", "%John%")
        :execute()

    assert(DataLike ~= nil and #DataLike == 2, "SUPABASE> Like test expected 2 records, got " .. (#DataLike or 0))
    for _, row in ipairs(DataLike) do
        assert(string.find(row.name, "John"), "SUPABASE> Like test failed: " .. row.name .. " doesn't contain 'John'")
    end
    assert(ErrorLike == nil, "SUPABASE> Error in Like test: " .. tostring(ErrorLike))

    -- ILike Test: description containing "software" (case insensitive)
    local DataILike, ErrorILike = self.client
        :from("unittests")
        :select("id, name, description")
        :ilike("description", "%software%")
        :execute()

    assert(DataILike ~= nil and #DataILike == 1, "SUPABASE> ILike test expected 1 record, got " .. (#DataILike or 0))
    assert(string.find(string.lower(DataILike[1].description), "software"),
        "SUPABASE> ILike test failed: description doesn't contain 'software'")
    assert(ErrorILike == nil, "SUPABASE> Error in ILike test: " .. tostring(ErrorILike))

    print("SUPABASE> Text Search Test Passed.")
end

--[[
    Tests null and boolean value checks against specific records.

    Tests:
    - is("description", "null"): Should return Alice Williams (id=4) and Minimal Record (id=9)
    - is("is_verified", true): Should return John Doe, Bob Johnson, Search Test User, Array Test, Range Test

    @throws AssertionError if tests fail
]]
function UnitTests:runIsChecks()
    print("SUPABASE> Running Is Checks Test...")

    -- Is Description Null Test
    local DataIsNull, ErrorIsNull = self.client
        :from("unittests")
        :select("id, name, description")
        :is("description", "null")
        :execute()

    assert(DataIsNull ~= nil and #DataIsNull == 2, "SUPABASE> Is Null test expected 2 records, got " .. (#DataIsNull or 0))
    for _, row in ipairs(DataIsNull) do
        assert(row.description == nil, "SUPABASE> Is Null test failed: " .. row.name .. " has non-null description")
    end
    assert(ErrorIsNull == nil, "SUPABASE> Error in Is Null test: " .. tostring(ErrorIsNull))

    -- Is Verified True Test
    local DataIsTrue, ErrorIsTrue = self.client
        :from("unittests")
        :select("id, name, is_verified")
        :is("is_verified", true)
        :execute()

    assert(DataIsTrue ~= nil and #DataIsTrue == 5, "SUPABASE> Is True test expected 5 records, got " .. (#DataIsTrue or 0))
    for _, row in ipairs(DataIsTrue) do
        assert(row.is_verified == true, "SUPABASE> Is True test failed: " .. row.name .. " has is_verified = " .. tostring(row.is_verified))
    end
    assert(ErrorIsTrue == nil, "SUPABASE> Error in Is True test: " .. tostring(ErrorIsTrue))

    print("SUPABASE> Is Checks Test Passed.")
end

--[[
    Tests IN operator against status values.

    Should return all records with status "active" or "pending" (7 records total)

    @throws AssertionError if tests fail
]]
function UnitTests:runInChecks()
    print("SUPABASE> Running In Checks Test...")

    local DataIn, ErrorIn = self.client
        :from("unittests")
        :select("id, name, status")
        :in_("status", { "active", "pending" })
        :execute()

    assert(DataIn ~= nil and #DataIn == 7, "SUPABASE> In test expected 7 records, got " .. (#DataIn or 0))
    for _, row in ipairs(DataIn) do
        assert(row.status == "active" or row.status == "pending",
            "SUPABASE> In test failed: " .. row.name .. " has status '" .. tostring(row.status) .. "' not in ('active', 'pending')")
    end
    assert(ErrorIn == nil, "SUPABASE> Error in In test: " .. tostring(ErrorIn))

    print("SUPABASE> In Checks Test Passed.")
end

--[[
    Tests array and JSON operations against specific data.

    Tests:
    - contains("tags", {"developer", "backend"}): Should return John Doe
    - containedBy("tags", {"a","b","c","d","e","f","g"}): Should return Array Test
    - contains("metadata", { level = "senior" }): Should return John Doe and Bob Johnson
    - containedBy("metadata", { department = "design", skills = { "figma", "sketch", "adobe-xd" } }): Should return Alice Williams

    @throws AssertionError if tests fail
]]
function UnitTests:runArrayOperationsTest()
    print("SUPABASE> Running Array Operations Test...")

    -- Contains Test: tags containing both "developer" and "backend"
    local DataContains, ErrorContains = self.client
        :from("unittests")
        :select("id, name, tags")
        :contains("tags", { "developer", "backend" })
        :execute()

    assert(DataContains ~= nil and #DataContains == 1, "SUPABASE> Contains test expected 1 record, got " .. (#DataContains or 0))
    assert(DataContains[1].name == "John Doe", "SUPABASE> Contains test failed: expected John Doe")

    local hasDeveloper = false
    local hasBackend = false
    for _, tag in ipairs(DataContains[1].tags) do
        if tag == "developer" then hasDeveloper = true end
        if tag == "backend" then hasBackend = true end
    end
    assert(hasDeveloper and hasBackend, "SUPABASE> Contains test failed: John Doe doesn't have both 'developer' and 'backend' tags")
    assert(ErrorContains == nil, "SUPABASE> Error in Contains test: " .. tostring(ErrorContains))

    -- Contained By Test: tags contained by {"a","b","c","d","e","f","g"}
    local DataContainedBy, ErrorContainedBy = self.client
        :from("unittests")
        :select("id, name, tags")
        :containedBy("tags", { "a", "b", "c", "d", "e", "f", "g" })
        :execute()

    assert(DataContainedBy ~= nil and #DataContainedBy == 1, "SUPABASE> Contained By test expected 1 record, got " .. (#DataContainedBy or 0))
    assert(DataContainedBy[1].name == "Array Test", "SUPABASE> Contained By test failed: expected Array Test")

    for _, tag in ipairs(DataContainedBy[1].tags) do
        local valid = false
        for _, allowed in ipairs({ "a", "b", "c", "d", "e", "f", "g" }) do
            if tag == allowed then valid = true; break end
        end
        assert(valid, "SUPABASE> Contained By test failed: Array Test has tag '" .. tag .. "' not in allowed set")
    end
    assert(ErrorContainedBy == nil, "SUPABASE> Error in Contained By test: " .. tostring(ErrorContainedBy))

    -- Contains With Json Test: metadata containing level = "senior"
    local DataContainsJson, ErrorContainsJson = self.client
        :from("unittests")
        :select("id, name, metadata")
        :contains("metadata", { level = "senior" })
        :execute()

    assert(DataContainsJson ~= nil and #DataContainsJson == 2, "SUPABASE> Contains with JSON test expected 2 records, got " .. (#DataContainsJson or 0))
    for _, row in ipairs(DataContainsJson) do
        assert(row.metadata.level == "senior",
            "SUPABASE> Contains with JSON test failed: " .. row.name .. " has metadata.level = '" .. tostring(row.metadata.level) .. "'")
    end
    assert(ErrorContainsJson == nil, "SUPABASE> Error in Contains with JSON test: " .. tostring(ErrorContainsJson))

    -- Contained By With Json Test: metadata contained by specific structure
    local DataContainedByJson, ErrorContainedByJson = self.client
        :from("unittests")
        :select("id, name, metadata")
        :containedBy("metadata", {
            department = "design",
            skills = { "figma", "sketch", "adobe-xd" }
        })
        :execute()

    assert(DataContainedByJson ~= nil and #DataContainedByJson == 1,
        "SUPABASE> Contained By with JSON test expected 1 record, got " .. (#DataContainedByJson or 0))
    assert(DataContainedByJson[1].name == "Alice Williams",
        "SUPABASE> Contained By with JSON test failed: expected Alice Williams")
    assert(DataContainedByJson[1].metadata ~= nil,
        "SUPABASE> Contained By with JSON test failed: Alice Williams has nil metadata")
    assert(ErrorContainedByJson == nil,
        "SUPABASE> Error in Contained By with JSON test: " .. tostring(ErrorContainedByJson))

    print("SUPABASE> Array Operations Test Passed.")
end

--[[
    Tests PostgreSQL range operations against specific range data.

    Tests specific ranges from the database:
    - rangeGt("valid_daterange", "[2023-01-01,2023-12-31)"): Should return dates after 2023
    - rangeLt("valid_int8range", "[5000, 6000]"): Should return int ranges before 5000
    - rangeGte("valid_numrange", "[100.5, 200.5]"): Should return num ranges >= 100.5
    - rangeLte("valid_tsrange", "[2024-01-01 00:00:00, 2024-12-31 23:59:59]"): Should return timestamps <= 2024
    - rangeAdjacent("valid_int8range", "[3001, 5000)"): Should return adjacent int ranges
    - overlaps("valid_daterange", "[2023-06-01, 2023-12-31)"): Should return overlapping date ranges

    @throws AssertionError if tests fail
]]
function UnitTests:runRangeOperationsTest()
    print("SUPABASE> Running Range Operations Test...")

    -- Range Strictly Greater Than Test: dates after 2023
    local DataRangeGT, ErrorRangeGT = self.client
        :from("unittests")
        :select("id, name, valid_daterange")
        :rangeGt("valid_daterange", "[2023-01-01,2023-12-31)")
        :execute()

    assert(DataRangeGT ~= nil and #DataRangeGT > 0, "SUPABASE> Range Greater Than test returned no results.")
    for _, row in ipairs(DataRangeGT) do
        assert(row.valid_daterange ~= nil, "SUPABASE> Range has nil daterange: " .. row.name)
        -- Dates should be strictly after 2023
        local startStr = string.match(row.valid_daterange, "%[(.-),")
        assert(startStr > "2023-12-31",
            "SUPABASE> Range Greater Than test failed: " .. row.name .. " starts at " .. startStr .. " not after 2023-12-31")
    end
    assert(ErrorRangeGT == nil, "SUPABASE> Error in Range Greater Than test: " .. tostring(ErrorRangeGT))

    -- Range Strictly Less Than Test: int ranges before 5000
    local DataRangeLT, ErrorRangeLT = self.client
        :from("unittests")
        :select("id, name, valid_int8range")
        :rangeLt("valid_int8range", "[5000, 6000]")
        :execute()

    assert(DataRangeLT ~= nil and #DataRangeLT == 3,
        "SUPABASE> Range Less Than test expected 3 records, got " .. (#DataRangeLT or 0))
    for _, row in ipairs(DataRangeLT) do
        local rangeStr = row.valid_int8range
        local _, endStr = string.match(rangeStr, "%[(.-),(.-)%)")
        assert(tonumber(endStr) <= 5000,
            "SUPABASE> Range Less Than test failed: " .. row.name .. " ends at " .. endStr .. " not before 5000")
    end
    assert(ErrorRangeLT == nil, "SUPABASE> Error in Range Less Than test: " .. tostring(ErrorRangeLT))

    -- Range Greater Than or Equal Test: num ranges >= 100.5
    local DataRangeGTE, ErrorRangeGTE = self.client
        :from("unittests")
        :select("id, name, valid_numrange")
        :rangeGte("valid_numrange", "[100.5, 200.5]")
        :execute()

    assert(DataRangeGTE ~= nil and #DataRangeGTE == 5,
        "SUPABASE> Range Greater Than or Equal test expected 5 records, got " .. (#DataRangeGTE or 0))
    for _, row in ipairs(DataRangeGTE) do
        local rangeStr = row.valid_numrange
        local startStr, _ = string.match(rangeStr, "%[(.-),(.-)%]")
        assert(tonumber(startStr) >= 100.5,
            "SUPABASE> Range Greater Than or Equal test failed: " .. row.name .. " starts at " .. startStr .. " not >= 100.5")
    end
    assert(ErrorRangeGTE == nil, "SUPABASE> Error in Range Greater Than or Equal test: " .. tostring(ErrorRangeGTE))

    -- Range Less Than or Equal Test: timestamp ranges <= 2023
    local DataRangeLTE, ErrorRangeLTE = self.client
        :from("unittests")
        :select("id, name, valid_tsrange")
        :rangeLte("valid_tsrange", "[2023-01-01 00:00:00, 2023-12-31 23:59:59]")
        :execute()

    assert(DataRangeLTE ~= nil and #DataRangeLTE == 1,
        "SUPABASE> Range Less Than or Equal test expected 1 record, got " .. (#DataRangeLTE or 0))
    assert(DataRangeLTE[1].name == "Bob Johnson",
        "SUPABASE> Range Less Than or Equal test failed: expected Bob Johnson (2023 dates)")
    assert(ErrorRangeLTE == nil, "SUPABASE> Error in Range Less Than or Equal test: " .. tostring(ErrorRangeLTE))

    -- Range Adjacent Test: int ranges adjacent to [3001, 5000)
    local DataRangeAdj, ErrorRangeAdj = self.client
        :from("unittests")
        :select("id, name, valid_int8range")
        :rangeAdjacent("valid_int8range", "[3001, 5000)")
        :execute()

    assert(DataRangeAdj ~= nil and #DataRangeAdj == 2,
        "SUPABASE> Range Adjacent test expected 2 records, got " .. (#DataRangeAdj or 0))
    for _, row in ipairs(DataRangeAdj) do
        local rangeStr = row.valid_int8range
        local startStr, endStr = string.match(rangeStr, "%[(.-),(.-)%)")
        local startNum = tonumber(startStr)
        local endNum = tonumber(endStr)
        -- Check if adjacent: end == 3001 or start == 5000
        assert(endNum == 3001 or startNum == 5000,
            "SUPABASE> Range Adjacent test failed: " .. row.name .. " range [" .. startStr .. "," .. endStr .. ") not adjacent to [3001,5000)")
    end
    assert(ErrorRangeAdj == nil, "SUPABASE> Error in Range Adjacent test: " .. tostring(ErrorRangeAdj))

    -- Range Overlaps Test: date ranges overlapping with mid-2023 to end-2023
    local DataRangeOv, ErrorRangeOv = self.client
        :from("unittests")
        :select("id, name, valid_daterange")
        :overlaps("valid_daterange", "[2023-06-01, 2023-12-31)")
        :execute()

    assert(DataRangeOv ~= nil and #DataRangeOv == 1,
        "SUPABASE> Range Overlaps test expected 1 record, got " .. (#DataRangeOv or 0))
    assert(DataRangeOv[1].name == "Bob Johnson",
        "SUPABASE> Range Overlaps test failed: expected Bob Johnson (2023 dates)")
    assert(ErrorRangeOv == nil, "SUPABASE> Error in Range Overlaps test: " .. tostring(ErrorRangeOv))

    print("SUPABASE> Range Operations Test Passed.")
end

--[[
    Tests advanced query operators against specific data.

    Tests:
    - filter("age", "gt", 25): Age > 25
    - in_("status", { "active", "pending", "archived" }): Status in active/pending
    - or_("status.eq.active,status.eq.pending"): Same as above
    - match({ is_verified = false }): Is_verified = false

    @throws AssertionError if tests fail
]]
function UnitTests:runOperatorsTest()
    print("SUPABASE> Running Operators Test...")

    -- Filter Test: age > 25
    local DataFilter, ErrorFilter = self.client
        :from("unittests")
        :select("id, name, age")
        :filter("age", "gt", 25)
        :execute()

    assert(DataFilter ~= nil and #DataFilter == 7,
        "SUPABASE> Filter test expected 7 records, got " .. (#DataFilter or 0))
    for _, row in ipairs(DataFilter) do
        assert(row.age > 25, "SUPABASE> Filter test failed: " .. row.name .. " age " .. row.age .. " <= 25")
    end
    assert(ErrorFilter == nil, "SUPABASE> Error in Filter test: " .. tostring(ErrorFilter))

    -- In Test: status in active, pending, archived
    local DataInOp, ErrorInOp = self.client
        :from("unittests")
        :select("id, name, status")
        :in_("status", { "active", "pending", "archived" })
        :execute()

    assert(DataInOp ~= nil and #DataInOp == 7,
        "SUPABASE> In operator test expected 7 records, got " .. (#DataInOp or 0))
    for _, row in ipairs(DataInOp) do
        assert(row.status == "active" or row.status == "pending",
            "SUPABASE> In operator test failed: " .. row.name .. " status '" .. row.status .. "' not in allowed set")
    end
    assert(ErrorInOp == nil, "SUPABASE> Error in In operator test: " .. tostring(ErrorInOp))

    -- Or Test: status = active OR status = pending
    local DataOr, ErrorOr = self.client
        :from("unittests")
        :select("id, name, status")
        :or_("status.eq.active,status.eq.pending")
        :execute()

    assert(DataOr ~= nil and #DataOr == 7,
        "SUPABASE> Or operator test expected 7 records, got " .. (#DataOr or 0))
    for _, row in ipairs(DataOr) do
        assert(row.status == "active" or row.status == "pending",
            "SUPABASE> Or operator test failed: " .. row.name .. " status not 'active' or 'pending'")
    end
    assert(ErrorOr == nil, "SUPABASE> Error in Or operator test: " .. tostring(ErrorOr))

    -- Match Test: is_verified = false
    local DataMatch, ErrorMatch = self.client
        :from("unittests")
        :select("id, name, is_verified")
        :match({ is_verified = false })
        :execute()

    assert(DataMatch ~= nil and #DataMatch == 4,
        "SUPABASE> Match operator test expected 4 records, got " .. (#DataMatch or 0))
    for _, row in ipairs(DataMatch) do
        assert(row.is_verified == false,
            "SUPABASE> Match operator test failed: " .. row.name .. " is_verified = " .. tostring(row.is_verified))
    end
    assert(ErrorMatch == nil, "SUPABASE> Error in Match operator test: " .. tostring(ErrorMatch))

    print("SUPABASE> Operators Test Passed.")
end

--[[
    Tests ordering modifiers against specific data.

    Tests:
    - order("age", { ascending = false }): Age descending
    - order("score", { ascending = true, nullsFirst = true }): Score ascending with nulls first

    @throws AssertionError if tests fail
]]
function UnitTests:runOrderingTest()
    print("SUPABASE> Running Ordering Test...")

    -- Descending Order Test by age
    local DataOrder, ErrorOrder = self.client
        :from("unittests")
        :select("id, name, age")
        :order("age", { ascending = false })
        :execute()

    assert(DataOrder ~= nil and #DataOrder > 0, "SUPABASE> Ordering test returned no results.")
    for i = 2, #DataOrder do
        assert(DataOrder[i].age <= DataOrder[i - 1].age,
            "SUPABASE> Ordering test failed: " .. DataOrder[i].name .. " age " .. DataOrder[i].age ..
            " > " .. DataOrder[i-1].name .. " age " .. DataOrder[i-1].age)
    end
    assert(ErrorOrder == nil, "SUPABASE> Error in Ordering test: " .. tostring(ErrorOrder))

    -- Ascending Order with Nulls First Test by score
    local DataOrderAsc, ErrorOrderAsc = self.client
        :from("unittests")
        :select("id, name, score")
        :order("score", { ascending = true, nullsFirst = true })
        :execute()

    assert(DataOrderAsc ~= nil and #DataOrderAsc > 0, "SUPABASE> Ascending Ordering test returned no results.")

    -- Check that nulls come first
    local foundNonNull = false
    for i = 1, #DataOrderAsc do
        if DataOrderAsc[i].score == nil then
            assert(not foundNonNull, "SUPABASE> Ascending Ordering test failed: null found after non-null value at position " .. i)
        else
            foundNonNull = true
            -- Once we start seeing non-nulls, check ascending order
            if i > 1 and DataOrderAsc[i-1].score ~= nil then
                assert(DataOrderAsc[i].score >= DataOrderAsc[i - 1].score,
                    "SUPABASE> Ascending Ordering test failed: scores not in ascending order at position " .. i)
            end
        end
    end
    assert(ErrorOrderAsc == nil, "SUPABASE> Error in Ascending Ordering test: " .. tostring(ErrorOrderAsc))

    print("SUPABASE> Ordering Test Passed.")
end

--[[
    Tests row limiting modifier.

    Tests limit(5): Should return exactly 5 rows

    @throws AssertionError if tests fail
]]
function UnitTests:runLimitingTest()
    print("SUPABASE> Running Limiting Test...")

    local DataLimit, ErrorLimit = self.client
        :from("unittests")
        :select("*")
        :limit(5)
        :execute()

    assert(DataLimit ~= nil, "SUPABASE> Limiting test returned nil data.")
    assert(#DataLimit == 5, "SUPABASE> Limiting test failed: expected 5 rows, got " .. tostring(#DataLimit))
    assert(ErrorLimit == nil, "SUPABASE> Error in Limiting test: " .. tostring(ErrorLimit))

    print("SUPABASE> Limiting Test Passed.")
end

--[[
    Tests range-based pagination.

    Tests range(3, 7): Should return rows 3 through 7 (5 rows total)

    @throws AssertionError if tests fail
]]
function UnitTests:runRangeLimitingTest()
    print("SUPABASE> Running Range Limiting Test...")

    local DataRangeLimit, ErrorRangeLimit = self.client
        :from("unittests")
        :select("*")
        :range(3, 7)
        :execute()

    assert(DataRangeLimit ~= nil, "SUPABASE> Range Limiting test returned nil data.")
    assert(#DataRangeLimit == 5, "SUPABASE> Range Limiting test failed: expected 5 rows, got " .. tostring(#DataRangeLimit))
    assert(ErrorRangeLimit == nil, "SUPABASE> Error in Range Limiting test: " .. tostring(ErrorRangeLimit))

    print("SUPABASE> Range Limiting Test Passed.")
end

--[[
    Tests single row retrieval modifiers.

    Tests:
    - single(): John Doe by id=1
    - maybeSingle(): John Doe by id=1

    @throws AssertionError if tests fail
]]
function UnitTests:runSingleTest()
    print("SUPABASE> Running Single Test...")

    -- Single Test: John Doe by id=1
    local DataSingle, ErrorSingle = self.client
        :from("unittests")
        :select("*")
        :eq("id", 1)
        :single()
        :execute()

    assert(DataSingle ~= nil, "SUPABASE> Single test returned nil data.")
    assert(type(DataSingle) == "table", "SUPABASE> Single test failed: expected a single row table.")
    assert(DataSingle.id == 1, "SUPABASE> Single test failed: returned row does not have id = 1.")
    assert(DataSingle.name == "John Doe", "SUPABASE> Single test failed: returned row is not John Doe.")
    assert(ErrorSingle == nil, "SUPABASE> Error in Single test: " .. tostring(ErrorSingle))

    -- MaybeSingle Test: John Doe by id=1
    local DataMaybeSingle, ErrorMaybeSingle = self.client
        :from("unittests")
        :select()
        :eq("id", 1)
        :maybeSingle()
        :execute()

    assert(DataMaybeSingle ~= nil, "SUPABASE> MaybeSingle test returned nil data.")
    assert(type(DataMaybeSingle) == "table", "SUPABASE> MaybeSingle test failed: expected a single row table.")
    assert(DataMaybeSingle.id == 1, "SUPABASE> MaybeSingle test failed: returned row does not have id = 1.")
    assert(DataMaybeSingle.name == "John Doe", "SUPABASE> MaybeSingle test failed: returned row is not John Doe.")
    assert(ErrorMaybeSingle == nil, "SUPABASE> Error in MaybeSingle test: " .. tostring(ErrorMaybeSingle))

    print("SUPABASE> Single Test Passed.")
end

--[[
    Tests response format modifiers.

    Tests:
    - csv(): Returns data in CSV format
    - returns("minimal"): Returns minimal representation (true on success)

    @throws AssertionError if tests fail
]]
function UnitTests:runFormatTests()
    print("SUPABASE> Running Format Tests...")

    -- CSV Format Test
    local DataCSV, ErrorCSV = self.client
        :from("unittests")
        :select()
        :eq("id", 1)
        :csv()
        :execute()

    assert(DataCSV ~= nil, "SUPABASE> CSV Format test returned nil data.")
    assert(type(DataCSV) == "string", "SUPABASE> CSV Format test failed: expected string data.")
    assert(string.find(DataCSV, "John Doe"), "SUPABASE> CSV Format test failed: CSV doesn't contain expected data")
    assert(ErrorCSV == nil, "SUPABASE> Error in CSV Format test: " .. tostring(ErrorCSV))

    -- Returns Minimal Format Test (for insert/update/delete operations)
    -- Note: We need to use a mutation for returns("minimal") to work properly
    local DataMinimal, ErrorMinimal = self.client
        :from("unittests")
        :update({ name = "John Doe" })  -- Update with same value
        :eq("id", 1)
        :returns("minimal")
        :execute()

    assert(DataMinimal == true, "SUPABASE> Returns Minimal test failed: expected true as data, got " .. tostring(DataMinimal))
    assert(ErrorMinimal == nil, "SUPABASE> Error in Returns Minimal test: " .. tostring(ErrorMinimal))

    print("SUPABASE> Format Tests Passed.")
end

--[[
    Tests CRUD mutation operations with cleanup.

    Tests insert, update, upsert, and delete operations.
    Creates a test record, modifies it, and cleans up after testing.

    @throws AssertionError if tests fail
]]
function UnitTests:runMutationTests()
    print("SUPABASE> Running Mutation Tests...")

    local testEmail = "unittest.insert@example.com"
    local testExternalId = "ext-unittest-" .. tostring(os.time())

    -- Clean up any existing test record first
    self.client
        :from("unittests")
        :delete()
        :eq("external_id", testExternalId)
        :returns("minimal")
        :execute()

    -- Insert Test
    local InsertData, InsertError = self.client
        :from("unittests")
        :insert({
            name = "Unit Test User",
            email = testEmail,
            age = 99,
            external_id = testExternalId,
            status = "active",
            is_active = true
        })
        :execute()

    assert(InsertData ~= nil and #InsertData > 0, "SUPABASE> Insert test returned no data.")
    assert(InsertError == nil, "SUPABASE> Error in Insert test: " .. tostring(InsertError))
    assert(InsertData[1].name == "Unit Test User", "SUPABASE> Insert test failed: name incorrect")
    assert(InsertData[1].email == testEmail, "SUPABASE> Insert test failed: email incorrect")

    local insertedRowId = InsertData[1].id

    -- Update Test
    local UpdateData, UpdateError = self.client
        :from("unittests")
        :update({
            age = 100,
            name = "Unit Test User Updated"
        })
        :eq("id", insertedRowId)
        :execute()

    assert(UpdateData ~= nil and #UpdateData > 0, "SUPABASE> Update test returned no data.")
    assert(UpdateData[1].age == 100, "SUPABASE> Update test failed: age was not updated correctly.")
    assert(UpdateData[1].name == "Unit Test User Updated", "SUPABASE> Update test failed: name was not updated correctly.")
    assert(UpdateError == nil, "SUPABASE> Error in Update test: " .. tostring(UpdateError))

    -- Upsert Test (update existing)
    local UpsertData, UpsertError = self.client
        :from("unittests")
        :upsert({
            id = insertedRowId,
            name = "Unit Test User Upserted",
            email = testEmail,
            age = 101,
            external_id = testExternalId,
            status = "active"
        })
        :execute()

    assert(UpsertData ~= nil and #UpsertData > 0, "SUPABASE> Upsert test returned no data.")
    assert(UpsertData[1].name == "Unit Test User Upserted", "SUPABASE> Upsert test failed: name was not updated correctly.")
    assert(UpsertData[1].age == 101, "SUPABASE> Upsert test failed: age was not updated correctly.")
    assert(UpsertError == nil, "SUPABASE> Error in Upsert test: " .. tostring(UpsertError))

    -- Upsert with onConflict Test
    local UpsertConflictData, UpsertConflictError = self.client
        :from("unittests")
        :upsert({
            name = "Unit Test User Upserted Conflict",
            email = testEmail, -- This email already exists
            age = 102,
            external_id = testExternalId,
            status = "active"
        }, {
            onConflict = "email"
        })
        :single()
        :execute()

    assert(UpsertConflictData ~= nil and (#UpsertConflictData > 0 or type(UpsertConflictData) == "table"), "SUPABASE> Upsert test returned no data.")
    assert(UpsertConflictError == nil, "SUPABASE> Error in Upsert test: ".. tostring(UpsertConflictError))

    -- Delete Test
    local DeleteData, DeleteError = self.client
        :from("unittests")
        :delete()
        :eq("id", insertedRowId)
        :execute()

    assert(DeleteData ~= nil and #DeleteData > 0, "SUPABASE> Delete test returned no data.")
    assert(DeleteError == nil, "SUPABASE> Error in Delete test: " .. tostring(DeleteError))

    -- Verify deletion
    local VerifyData, VerifyError = self.client
        :from("unittests")
        :select()
        :eq("id", insertedRowId)
        :execute()

    assert(VerifyData ~= nil and #VerifyData == 0, "SUPABASE> Delete verification failed: record still exists.")
    assert(VerifyError == nil, "SUPABASE> Error in delete verification: " .. tostring(VerifyError))

    print("SUPABASE> Mutation Tests Passed.")
end

--[[
    Tests complex query combinations with multiple conditions.

    Tests a complex query with multiple filters, OR conditions, and modifiers.
    Finds active users over age 25, ordered by age descending, limited to 10.

    @throws AssertionError if tests fail
]]
function UnitTests:runComplexQueriesTest()
    print("SUPABASE> Running Complex Queries Test...")

    -- Complex Query: Active users over 25, OR rating > 4.0, ordered by age descending
    local DataComplex, ErrorComplex = self.client
        :from("unittests")
        :select("id, name, age, status, rating")
        :eq("status", "active")
        :or_("age.gte.30,rating.gt.4.0")
        :gt("age", 25)
        :order("age", { ascending = false })
        :limit(10)
        :execute()

    assert(DataComplex ~= nil and #DataComplex > 0, "SUPABASE> Complex Queries test returned no data.")

    for _, row in ipairs(DataComplex) do
        assert(row.status == "active",
            "SUPABASE> Complex Queries test failed: " .. row.name .. " has status '" .. row.status .. "' not 'active'")
        assert(row.age > 25,
            "SUPABASE> Complex Queries test failed: " .. row.name .. " age " .. row.age .. " <= 25")
        -- Verify OR condition: age >= 30 OR rating > 4.0
        assert(row.age >= 30 or row.rating > 4.0,
            "SUPABASE> Complex Queries test failed: " .. row.name .. " doesn't satisfy age>=30 OR rating>4.0")
    end

    -- Check ordering (descending by age)
    for i = 2, #DataComplex do
        assert(DataComplex[i].age <= DataComplex[i - 1].age,
            "SUPABASE> Complex Queries test failed: not in descending order by age at position " .. i)
    end

    assert(ErrorComplex == nil, "SUPABASE> Error in Complex Queries test: " .. tostring(ErrorComplex))

    print("SUPABASE> Complex Queries Test Passed.")
end

--[[
    Tests basic Edge Function invocation.

    Tests the invoke method with and without payloads, expecting proper JSON responses.
    Note: This test requires you to have at least one Edge Function deployed.

    @throws AssertionError if tests fail
]]
function UnitTests:runEdgeFunctionsTest()
    print("SUPABASE> Running Edge Functions Test...")

    local functions = {
        {
            name = "hello-world",
            payload = nil,
            expectedResponse = "Hello, World!" -- Plain text response
        },
        {
            name = "test-echo",
            payload = { text = "Supabase Edge Functions" },
            expectedResponse = { text = "Supabase Edge Functions" }
        },
        {
            name = "non-existent-function",
            payload = nil,
            expectedError = true
        }
    }

    -- Iterate through each function test case
    for _, func in ipairs(functions) do
        local Data, Error = nil, nil
        if func.payload then
            Data, Error = self.client.functions
                :invoke(func.name, func.payload)
        else
            Data, Error = self.client.functions
                :invoke(func.name)
        end

        if func.expectedError then
            assert(Error ~= nil, "SUPABASE> Edge Function test failed: expected error for function '" .. func.name .. "'")
        else
            assert(Error == nil, "SUPABASE> Edge Function test failed: unexpected error for function '" .. func.name .. "': " .. tostring(Error))
            if type(func.expectedResponse) == "table" then
                for key, value in pairs(func.expectedResponse) do
                    assert(Data[key] == value,
                        "SUPABASE> Edge Function test failed: function '" .. func.name .. "' expected key '" .. key ..
                        "' to be '" .. tostring(value) .. "', got '" .. tostring(Data[key]) .. "'")
                end
            else
                assert(Data == func.expectedResponse,
                    "SUPABASE> Edge Function test failed: function '" .. func.name ..
                    "' expected response '" .. tostring(func.expectedResponse) .. "', got '" .. tostring(Data) .. "'")
            end
        end
    end

    print("SUPABASE> Edge Functions Test Passed.")
end

--[[
    Tests basic RPC function calls.

    Tests the rpc method with parameters, expecting proper JSON responses.
    Note: This test requires you to have at least one RPC function deployed.

    @throws AssertionError if tests fail
]]
function UnitTests:runRPCTests()
    print("SUPABASE> Running RPC Tests...")

    -- Test RPC call with parameters
    local rpcResult, rpcError = self.client
        :rpc("test_hello", { name = "Supabase" })
        :execute()

    assert(rpcError == nil, "SUPABASE> RPC test failed with error: " .. tostring(rpcError))
    assert(rpcResult ~= nil, "SUPABASE> RPC test returned no data.")
    assert(rpcResult.message == "Hello, Supabase!", "SUPABASE> RPC test failed: unexpected greeting '" .. tostring(rpcResult.message) .. "'")


    -- Test RPC call with filtering
    local rpcFilterResult, rpcFilterError = self.client
        :rpc("get_users_by_status", { status_filter = "active" })
        :order("age", { ascending = true })
        :limit(2)
        :execute()

    assert(rpcFilterError == nil, "SUPABASE> RPC filter test failed with error: " .. tostring(rpcFilterError))
    assert(rpcFilterResult ~= nil and #rpcFilterResult == 2,
        "SUPABASE> RPC filter test expected 2 records, got " .. (#rpcFilterResult or 0))
    for _, row in ipairs(rpcFilterResult) do
        assert(row.status == "active",
            "SUPABASE> RPC filter test failed: " .. row.name .. " has status '" .. row.status .. "' not 'active'")

        for i = 2, #rpcFilterResult do
            assert(rpcFilterResult[i].age >= rpcFilterResult[i - 1].age,
                "SUPABASE> RPC filter test failed: ages not in ascending order at position " .. i)
        end
    end
    assert(rpcFilterError == nil, "SUPABASE> Error in RPC filter test: " .. tostring(rpcFilterError))

    -- Test RPC call with GET method for immutable functions
    local rpcGetResult, rpcGetError = self.client
        :rpc("get_current_time")
        :get()
        :execute()

    assert(rpcGetError == nil, "SUPABASE> RPC GET test failed with error: " .. tostring(rpcGetError))

    print("SUPABASE> RPC Tests Passed.")
end

--[[
    Runs all unit tests in sequence.

    Executes all test categories in the recommended order:
    1. Filter tests
    2. Modifier tests
    3. Mutation tests
    4. Complex query tests

    Each test is isolated and cleans up after itself where necessary.

    @throws AssertionError if any test fails
]]
function UnitTests:runAllTests()
    print("SUPABASE> ===========================================")
    print("SUPABASE> Running Supabase Unit Tests...")
    print("SUPABASE> Testing against actual database records")
    print("SUPABASE> ===========================================")

    -- Filter Tests
    print("\nSUPABASE> --- FILTER TESTS ---")
    self:runEqualityTest()
    self:runInequalityTest()
    self:runComparaisonTest()
    self:runTextSearch()
    self:runIsChecks()
    self:runInChecks()
    self:runArrayOperationsTest()
    self:runRangeOperationsTest()
    self:runOperatorsTest()

    -- Modifier Tests
    print("\nSUPABASE> --- MODIFIER TESTS ---")
    self:runOrderingTest()
    self:runLimitingTest()
    self:runRangeLimitingTest()
    self:runSingleTest()
    self:runFormatTests()

    -- Mutations Tests
    print("\nSUPABASE> --- MUTATION TESTS ---")
    self:runMutationTests()

    -- Complex Queries Test
    print("\nSUPABASE> --- COMPLEX QUERY TESTS ---")
    self:runComplexQueriesTest()

    -- Edge Functions Test
    print("\nSUPABASE> --- EDGE FUNCTIONS TESTS ---")
    self:runEdgeFunctionsTest()

    -- RPC Tests
    print("\nSUPABASE> --- RPC TESTS ---")
    self:runRPCTests()

    -- Type tests
    print("\nSUPABASE> --- TYPE TESTS ---")
    RestTypesTest.run()

    print("\nSUPABASE> ===========================================")
    print("SUPABASE> All tests completed successfully!")
    print("SUPABASE> ===========================================")
end

return UnitTests