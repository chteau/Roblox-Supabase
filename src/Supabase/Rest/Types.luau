local Types = {}

---------------------------------------------------------------------
-- Base execution interface (available on final stage & also included
-- in intermediate stages so execute() is available anywhere).
---------------------------------------------------------------------
export type BaseExec = {
	-- Execute the query; returns (result, error?)
	execute: (self: any) -> (any, string?),
	-- Execute with typed result (consumer interprets)
	executeTyped: (self: any) -> (any, string?),
}

---------------------------------------------------------------------
-- Option types
---------------------------------------------------------------------
export type OrFilterOptions = {
	foreignTable: string?,
}

export type OrderOptions = {
	ascending: boolean?,
	nullsFirst: boolean?,
	foreignTable: string?,
	referencedTable: string?,
}

export type LimitOptions = {
	foreignTable: string?,
	referencedTable: string?,
}

export type RangeOptions = {
	foreignTable: string?,
	referencedTable: string?,
}

export type ExplainOptions = {
	analyze: boolean?,
	verbose: boolean?,
	settings: boolean?,
	buffers: boolean?,
	wal: boolean?,
	format: "text" | "json" | "yaml"?,
}

export type InsertOptions = {
	returning: "minimal" | "representation"?,
	count: "exact" | "planned" | "estimated"?,
	defaultToNull: boolean?,
	onConflict: string?,
	ignoreDuplicates: boolean?,
	upsert: boolean?,
}

export type UpdateOptions = {
	returning: "minimal" | "representation"?,
	count: "exact" | "planned" | "estimated"?,
}

export type DeleteOptions = {
	returning: "minimal" | "representation"?,
	count: "exact" | "planned" | "estimated"?,
}

---------------------------------------------------------------------
-- Generic Filter stage (parametrized with Next)
-- Filters return Next. To allow repeated filters and modifiers
-- at the same stage we will use self-referential Next types where needed.
---------------------------------------------------------------------
export type FilterStage<Next> = BaseExec & {
	eq: (self: any, column: string, value: any) -> Next,
	neq: (self: any, column: string, value: any) -> Next,
	gt: (self: any, column: string, value: any) -> Next,
	gte: (self: any, column: string, value: any) -> Next,
	lt: (self: any, column: string, value: any) -> Next,
	lte: (self: any, column: string, value: any) -> Next,
	like: (self: any, column: string, pattern: string) -> Next,
	ilike: (self: any, column: string, pattern: string) -> Next,
	is: (self: any, column: string, value: boolean | "null") -> Next,
	in_: (self: any, column: string, values: {any}) -> Next,
	contains: (self: any, column: string, value: any) -> Next,
	containedBy: (self: any, column: string, value: any) -> Next,
	rangeGt: (self: any, column: string, range: string) -> Next,
	rangeGte: (self: any, column: string, range: string) -> Next,
	rangeLt: (self: any, column: string, range: string) -> Next,
	rangeLte: (self: any, column: string, range: string) -> Next,
	rangeAdjacent: (self: any, column: string, range: string) -> Next,
	overlaps: (self: any, column: string, value: any) -> Next,
	match: (self: any, query: {[string]: any}) -> Next,
	not_: (self: any, column: string, operator: string, value: any) -> Next,
	filter: (self: any, column: string, operator: string, value: any) -> Next,
	or_: (self: any, filters: string, options: OrFilterOptions?) -> Next,
}

---------------------------------------------------------------------
-- Modifier stage for SELECT/RPC (non-final modifiers).
-- Transitioning modifiers (order/limit/range) return ModifierStage.
-- Finalizers (single/maybeSingle/csv/returns/explain) collapse to FinalStage.
---------------------------------------------------------------------
export type ModifierStage = BaseExec & {
	-- Non-final modifiers (remain in modifier stage)
	order: (self: any, column: string, options: OrderOptions?) -> ModifierStage,
	limit: (self: any, count: number, options: LimitOptions?) -> ModifierStage,
	range: (self: any, from: number, to: number, options: RangeOptions?) -> ModifierStage,

	-- Finalizers (collapse to FinalStage)
	single: (self: any) -> FinalStage,
	maybeSingle: (self: any) -> FinalStage,
	csv: (self: any) -> FinalStage,
	returns: (self: any, representation: "minimal" | "representation") -> FinalStage,
	overrideTypes: (self: any, schema: table) -> FinalStage,
	explain: (self: any, options: ExplainOptions?) -> FinalStage,
}

---------------------------------------------------------------------
-- Mutation initial stage (for insert/upsert/update/delete before select)
-- This stage exposes returns/csv/execute but NOT single/maybeSingle.
-- Calling select(...) transitions to MutationSelectStage (which exposes single/maybeSingle).
---------------------------------------------------------------------
export type MutationInitialStage = BaseExec & {
	returns: (self: any, representation: "minimal" | "representation") -> FinalStage,
	csv: (self: any) -> FinalStage,
	select: (self: any, columns: string) -> MutationSelectStage,
}

---------------------------------------------------------------------
-- MutationSelectStage: result of calling .select(...) on a mutation.
-- This stage exposes single/maybeSingle which are finalizers that collapse
-- directly to FinalStage (execute-only).
---------------------------------------------------------------------
export type MutationSelectStage = BaseExec & {
	single: (self: any) -> FinalStage,
	maybeSingle: (self: any) -> FinalStage,
	returns: (self: any, representation: "minimal" | "representation") -> FinalStage,
	csv: (self: any) -> FinalStage,
	-- execute available as well
}

---------------------------------------------------------------------
-- Final stage: the chain collapsed to execution only.
-- Only execute() and executeTyped() are available here.
---------------------------------------------------------------------
export type FinalStage = {
	execute: (self: any) -> (any, string?),
	executeTyped: (self: any) -> (any, string?),
}

---------------------------------------------------------------------
-- SELECT types
-- select(...) -> SelectFilterStage (filters chainable).
-- Transitioning non-final modifiers move to ModifierStage.
-- Finalizers collapse to FinalStage.
---------------------------------------------------------------------
export type SelectModifierStage = ModifierStage

export type SelectFilterStage = FilterStage<SelectFilterStage> & {
	-- Transitioning non-final modifiers to move to SelectModifierStage
	order: (self: any, column: string, options: OrderOptions?) -> SelectModifierStage,
	limit: (self: any, count: number, options: LimitOptions?) -> SelectModifierStage,
	range: (self: any, from: number, to: number, options: RangeOptions?) -> SelectModifierStage,

	-- Finalizers collapse to FinalStage
	single: (self: any) -> FinalStage,
	maybeSingle: (self: any) -> FinalStage,
	csv: (self: any) -> FinalStage,
	returns: (self: any, representation: "minimal" | "representation") -> FinalStage,
	overrideTypes: (self: any, schema: table) -> FinalStage,
	explain: (self: any, options: ExplainOptions?) -> FinalStage,
}

---------------------------------------------------------------------
-- RPC types — mirror SELECT semantics and finalizers
---------------------------------------------------------------------
export type RPCModifierStage = ModifierStage

export type RPCFilterStage = FilterStage<RPCFilterStage> & {
	order: (self: any, column: string, options: OrderOptions?) -> RPCModifierStage,
	limit: (self: any, count: number, options: LimitOptions?) -> RPCModifierStage,
	range: (self: any, from: number, to: number, options: RangeOptions?) -> RPCModifierStage,

	-- Finalizers collapse to FinalStage
	single: (self: any) -> FinalStage,
	maybeSingle: (self: any) -> FinalStage,
	csv: (self: any) -> FinalStage,
	returns: (self: any, representation: "minimal" | "representation") -> FinalStage,
	overrideTypes: (self: any, schema: table) -> FinalStage,
	explain: (self: any, options: ExplainOptions?) -> FinalStage,

	-- Optional convenience
	get: (self: any) -> RPCFilterStage,
}

---------------------------------------------------------------------
-- INSERT / UPSERT (start in MutationInitialStage)
---------------------------------------------------------------------
export type InsertQuery = MutationInitialStage
export type UpsertQuery = MutationInitialStage

---------------------------------------------------------------------
-- UPDATE / DELETE (filters first, then mutation select or direct finalizers)
-- - update(...).eq(...).returns() -> FinalStage
-- - update(...).eq(...).select(...).single() -> FinalStage
-- .select() on mutation returns MutationSelectStage (NO filters)
---------------------------------------------------------------------
export type UpdateFilterStage = FilterStage<UpdateFilterStage> & {
	select: (self: any, columns: string) -> MutationSelectStage,
	returns: (self: any, representation: "minimal" | "representation") -> FinalStage,
	csv: (self: any) -> FinalStage,
}

export type UpdateQuery = UpdateFilterStage

export type DeleteFilterStage = FilterStage<DeleteFilterStage> & {
	select: (self: any, columns: string) -> MutationSelectStage,
	returns: (self: any, representation: "minimal" | "representation") -> FinalStage,
	csv: (self: any) -> FinalStage,
}

export type DeleteQuery = DeleteFilterStage

---------------------------------------------------------------------
-- ROOT QUERY
---------------------------------------------------------------------
export type RootQuery = {
	-- SELECT: returns SelectFilterStage (filters chainable)
	select: (self: any, columns: string) -> SelectFilterStage,

	-- INSERT: returns InsertQuery (mutation initial stage)
	insert: (self: any, values: {any}, options: InsertOptions?) -> InsertQuery,

	-- UPDATE: returns UpdateQuery (filters chainable; mutation select/finalizers)
	update: (self: any, values: {any}, options: UpdateOptions?) -> UpdateQuery,

	-- DELETE: returns DeleteQuery (filters chainable; mutation select/finalizers)
	delete: (self: any, options: DeleteOptions?) -> DeleteQuery,

	-- UPSERT: returns UpsertQuery (mutation initial stage)
	upsert: (self: any, values: {any}, options: InsertOptions?) -> UpsertQuery,

	-- RPC: returns RPCFilterStage (filters chainable; finals collapse)
	rpc: (self: any, fnName: string, params: {any}?) -> RPCFilterStage,
}

---------------------------------------------------------------------
-- RestClient
---------------------------------------------------------------------
export type RestClient = {
	from: (self: RestClient, tableName: string) -> RootQuery,
}

return Types
