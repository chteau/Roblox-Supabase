--[[
	Type definitions for the Supabase REST client.

	@module Rest.Types
]]
local Types = {}

--[[
	Options for the `or_` filter method.

	@within Rest.Types
	@prop foreignTable string? -- Optional foreign table name for the filter
]]
export type OrFilterOptions = {
    foreignTable: string?,
}

--[[
	Options for ordering operations.

	@within Rest.Types
	@prop ascending boolean? -- Sort in ascending order (default: true)
	@prop nullsFirst boolean? -- Put null values first (default: false)
	@prop foreignTable string? -- Order by foreign table column
	@prop referencedTable string? -- Order by referenced table
]]
export type OrderOptions = {
    ascending: boolean?,
    nullsFirst: boolean?,
    foreignTable: string?,
    referencedTable: string?,
}

--[[
	Options for limit operations.

	@within Rest.Types
	@prop foreignTable string? -- Limit on foreign table
	@prop referencedTable string? -- Limit on referenced table
]]
export type LimitOptions = {
    foreignTable: string?,
    referencedTable: string?,
}

--[[
	Options for range operations.

	@within Rest.Types
	@prop foreignTable string? -- Range on foreign table
	@prop referencedTable string? -- Range on referenced table
]]
export type RangeOptions = {
    foreignTable: string?,
    referencedTable: string?,
}

--[[
	Options for explain operations.

	@within Rest.Types
	@prop analyze boolean? -- Include actual run times
	@prop verbose boolean? -- Include additional information
	@prop settings boolean? -- Include settings
	@prop buffers boolean? -- Include buffer usage
	@prop wal boolean? -- Include WAL usage
	@prop format "text" | "json" | "yaml"? -- Output format
]]
export type ExplainOptions = {
    analyze: boolean?,
    verbose: boolean?,
    settings: boolean?,
    buffers: boolean?,
    wal: boolean?,
    format: "text" | "json" | "yaml"?,
}

--[[
	Options for insert operations.

	@within Rest.Types
	@prop returning "minimal" | "representation"? -- Return preference
	@prop count "exact" | "planned" | "estimated"? -- Count preference
	@prop defaultToNull boolean? -- Use default values for missing columns
	@prop onConflict string? -- Columns to check for conflicts (for upsert)
	@prop ignoreDuplicates boolean? -- Ignore duplicate rows
	@prop upsert boolean? -- Perform upsert operation
]]
export type InsertOptions = {
    returning: "minimal" | "representation"?,
    count: "exact" | "planned" | "estimated"?,
    defaultToNull: boolean?,
    onConflict: string?,
    ignoreDuplicates: boolean?,
    upsert: boolean?,
}

--[[
	Options for update operations.

	@within Rest.Types
	@prop returning "minimal" | "representation"? -- Return preference
	@prop count "exact" | "planned" | "estimated"? -- Count preference
]]
export type UpdateOptions = {
    returning: "minimal" | "representation"?,
    count: "exact" | "planned" | "estimated"?,
}

--[[
	Options for delete operations.

	@within Rest.Types
	@prop returning "minimal" | "representation"? -- Return preference
	@prop count "exact" | "planned" | "estimated"? -- Count preference
]]
export type DeleteOptions = {
    returning: "minimal" | "representation"?,
    count: "exact" | "planned" | "estimated"?,
}

--[[
	Base query interface with execution methods.

	@within Rest.Types
]]
export type BaseQuery = {
    execute: (self: any) -> (any, string?),
    executeTyped: (self: any) -> (any, string?),
}

--[[
	Filter methods interface.
]]
export type FilterMethods = BaseQuery &{
    eq: (self: any, column: string, value: any) -> FilterMethods & ModifierMethods,
    neq: (self: any, column: string, value: any) -> FilterMethods & ModifierMethods,
    gt: (self: any, column: string, value: any) -> FilterMethods & ModifierMethods,
    gte: (self: any, column: string, value: any) -> FilterMethods & ModifierMethods,
    lt: (self: any, column: string, value: any) -> FilterMethods & ModifierMethods,
    lte: (self: any, column: string, value: any) -> FilterMethods & ModifierMethods,
    like: (self: any, column: string, pattern: string) -> FilterMethods & ModifierMethods,
    ilike: (self: any, column: string, pattern: string) -> FilterMethods & ModifierMethods,
    is: (self: any, column: string, value: boolean | "null") -> FilterMethods & ModifierMethods,
    in_: (self: any, column: string, values: {any}) -> FilterMethods & ModifierMethods,
    contains: (self: any, column: string, value: any) -> FilterMethods & ModifierMethods,
    containedBy: (self: any, column: string, value: any) -> FilterMethods & ModifierMethods,
    rangeGt: (self: any, column: string, range: string) -> FilterMethods & ModifierMethods,
    rangeGte: (self: any, column: string, range: string) -> FilterMethods & ModifierMethods,
    rangeLt: (self: any, column: string, range: string) -> FilterMethods & ModifierMethods,
    rangeLte: (self: any, column: string, range: string) -> FilterMethods & ModifierMethods,
    rangeAdjacent: (self: any, column: string, range: string) -> FilterMethods & ModifierMethods,
    overlaps: (self: any, column: string, value: any) -> FilterMethods & ModifierMethods,
    match: (self: any, query: {[string]: any}) -> FilterMethods & ModifierMethods,
    not_: (self: any, column: string, operator: string, value: any) -> FilterMethods & ModifierMethods,
    filter: (self: any, column: string, operator: string, value: any) -> FilterMethods & ModifierMethods,
    or_: (self: any, filters: string, options: OrFilterOptions) -> FilterMethods & ModifierMethods,
}

--[[
	Modifier methods interface.
]]
export type ModifierMethods = {
    order: (self: any, column: string, options: OrderOptions?) -> any,
    limit: (self: any, count: number, options: LimitOptions?) -> any,
    range: (self: any, from: number, to: number, options: RangeOptions?) -> any,
    single: (self: any) -> any,
    maybeSingle: (self: any) -> any,
    csv: (self: any) -> any,
    returns: (self: any, representation: "minimal" | "representation") -> any,
    overrideTypes: (self: any, schema: table) -> any,
    explain: (self: any, options: ExplainOptions?) -> any,
}

--[[
	SELECT query interface with all filters and modifiers.
]]
export type SelectQuery = FilterMethods & ModifierMethods & {
    select: (self: any, columns: string) -> any,
}

--[[
	INSERT query interface with limited modifiers.
]]
export type InsertQuery = BaseQuery & {
    select: (self: any, columns: string) -> InsertQuery,
    returns: (self: any, representation: "minimal" | "representation") -> InsertQuery,
    single: (self: any) -> InsertQuery,
    maybeSingle: (self: any) -> InsertQuery,
    csv: (self: any) -> InsertQuery,
}

--[[
	UPDATE query interface with filters but no select.
]]
export type UpdateQuery = FilterMethods & {
    returns: (self: any, representation: "minimal" | "representation") -> UpdateQuery,
}

--[[
	DELETE query interface with filters.
]]
export type DeleteQuery = FilterMethods & {
    returns: (self: any, representation: "minimal" | "representation") -> DeleteQuery,
}

--[[
	UPSERT query interface (same as insert).
]]
export type UpsertQuery = InsertQuery

--[[
	Root query interface with starting methods only.

	@within Rest.Types
]]
export type RootQuery = {
    select: (self: any, columns: string) -> SelectQuery,
    insert: (self: any, values: {any}, options: InsertOptions?) -> InsertQuery,
    update: (self: any, values: table, options: UpdateOptions?) -> UpdateQuery,
    delete: (self: any, options: DeleteOptions?) -> DeleteQuery,
    upsert: (self: any, values: {any}, options: InsertOptions?) -> UpsertQuery,
}

--[[
    RPC query interface for calling stored procedures.

    @within Rest.Types
]]
export type RPCQuery = FilterMethods & ModifierMethods & {
    get: (self: any) -> RPCQuery,
}

--[[
	Main REST client for Supabase PostgREST API.

	@within Rest.Types
	@prop from (self: RestClient, tableName: string) -> RootQuery
]]
export type RestClient = {
    from: (self: RestClient, tableName: string) -> RootQuery,
}

return Types