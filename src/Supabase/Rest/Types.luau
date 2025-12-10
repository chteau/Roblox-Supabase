--!strict
-- Types.lua
-- Final Luau type definitions for a Supabase/PostgREST-like REST client.
-- Option B semantics: Filters FIRST, then Modifiers. Once a modifier is used,
-- filters are no longer available in that chain branch.
-- This version fixes the update/delete modifier-collapse issue by introducing
-- distinct ModifierStage types for mutation flows.
-- Paste this file directly into your project.

local Types = {}

---------------------------------------------------------------------
-- Base execution interface (available everywhere)
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
-- Filters return Next. Use self-referential Next where we want repeatable filters.
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
-- Full modifier stage (used by SELECT and RPC)
-- Modifiers return ModifierFinal (chainable), and filters are not present there.
---------------------------------------------------------------------
export type ModifierFinal = BaseExec & {
	order: (self: any, column: string, options: OrderOptions?) -> ModifierFinal,
	limit: (self: any, count: number, options: LimitOptions?) -> ModifierFinal,
	range: (self: any, from: number, to: number, options: RangeOptions?) -> ModifierFinal,
	single: (self: any) -> ModifierFinal,
	maybeSingle: (self: any) -> ModifierFinal,
	csv: (self: any) -> ModifierFinal,
	returns: (self: any, representation: "minimal" | "representation") -> ModifierFinal,
	overrideTypes: (self: any, schema: table) -> ModifierFinal,
	explain: (self: any, options: ExplainOptions?) -> ModifierFinal,
}

---------------------------------------------------------------------
-- Mutation modifier stage (used by insert, update, delete, upsert)
-- Mutation modifiers are chainable and keep execution available.
---------------------------------------------------------------------
export type MutationModifierFinal = BaseExec & {
	select: (self: any, columns: string) -> MutationModifierFinal,
	returns: (self: any, representation: "minimal" | "representation") -> MutationModifierFinal,
	single: (self: any) -> MutationModifierFinal,
	maybeSingle: (self: any) -> MutationModifierFinal,
	csv: (self: any) -> MutationModifierFinal,
}

---------------------------------------------------------------------
-- SELECT (filters first, then modifiers)
-- - SelectFilterStage: filters chain (return same stage). Transitioning modifiers
--   move to SelectModifierStage (no filters).
-- - SelectModifierStage: modifiers chain and expose execute.
---------------------------------------------------------------------
export type SelectModifierStage = ModifierFinal

export type SelectFilterStage = BaseExec & {
	-- Chainable filters (return same stage)
	eq: (self: any, column: string, value: any) -> SelectFilterStage,
	neq: (self: any, column: string, value: any) -> SelectFilterStage,
	gt: (self: any, column: string, value: any) -> SelectFilterStage,
	gte: (self: any, column: string, value: any) -> SelectFilterStage,
	lt: (self: any, column: string, value: any) -> SelectFilterStage,
	lte: (self: any, column: string, value: any) -> SelectFilterStage,
	like: (self: any, column: string, pattern: string) -> SelectFilterStage,
	ilike: (self: any, column: string, pattern: string) -> SelectFilterStage,
	is: (self: any, column: string, value: boolean | "null") -> SelectFilterStage,
	in_: (self: any, column: string, values: {any}) -> SelectFilterStage,
	contains: (self: any, column: string, value: any) -> SelectFilterStage,
	containedBy: (self: any, column: string, value: any) -> SelectFilterStage,
	rangeGt: (self: any, column: string, range: string) -> SelectFilterStage,
	rangeGte: (self: any, column: string, range: string) -> SelectFilterStage,
	rangeLt: (self: any, column: string, range: string) -> SelectFilterStage,
	rangeLte: (self: any, column: string, range: string) -> SelectFilterStage,
	rangeAdjacent: (self: any, column: string, range: string) -> SelectFilterStage,
	overlaps: (self: any, column: string, value: any) -> SelectFilterStage,
	match: (self: any, query: {[string]: any}) -> SelectFilterStage,
	not_: (self: any, column: string, operator: string, value: any) -> SelectFilterStage,
	filter: (self: any, column: string, operator: string, value: any) -> SelectFilterStage,
	or_: (self: any, filters: string, options: OrFilterOptions?) -> SelectFilterStage,

	-- Transitioning modifiers (move to SelectModifierStage)
	order: (self: any, column: string, options: OrderOptions?) -> SelectModifierStage,
	limit: (self: any, count: number, options: LimitOptions?) -> SelectModifierStage,
	range: (self: any, from: number, to: number, options: RangeOptions?) -> SelectModifierStage,
	single: (self: any) -> SelectModifierStage,
	maybeSingle: (self: any) -> SelectModifierStage,
	csv: (self: any) -> SelectModifierStage,
	returns: (self: any, representation: "minimal" | "representation") -> SelectModifierStage,
	overrideTypes: (self: any, schema: table) -> SelectModifierStage,
	explain: (self: any, options: ExplainOptions?) -> SelectModifierStage,
}

---------------------------------------------------------------------
-- RPC (filters first, then modifiers) — mirrors SELECT semantics
---------------------------------------------------------------------
export type RPCModifierStage = ModifierFinal

export type RPCFilterStage = BaseExec & {
	-- Chainable filters
	eq: (self: any, column: string, value: any) -> RPCFilterStage,
	neq: (self: any, column: string, value: any) -> RPCFilterStage,
	gt: (self: any, column: string, value: any) -> RPCFilterStage,
	gte: (self: any, column: string, value: any) -> RPCFilterStage,
	lt: (self: any, column: string, value: any) -> RPCFilterStage,
	lte: (self: any, column: string, value: any) -> RPCFilterStage,
	like: (self: any, column: string, pattern: string) -> RPCFilterStage,
	ilike: (self: any, column: string, pattern: string) -> RPCFilterStage,
	is: (self: any, column: string, value: boolean | "null") -> RPCFilterStage,
	in_: (self: any, column: string, values: {any}) -> RPCFilterStage,
	contains: (self: any, column: string, value: any) -> RPCFilterStage,
	containedBy: (self: any, column: string, value: any) -> RPCFilterStage,
	rangeGt: (self: any, column: string, range: string) -> RPCFilterStage,
	rangeGte: (self: any, column: string, range: string) -> RPCFilterStage,
	rangeLt: (self: any, column: string, range: string) -> RPCFilterStage,
	rangeLte: (self: any, column: string, range: string) -> RPCFilterStage,
	rangeAdjacent: (self: any, column: string, range: string) -> RPCFilterStage,
	overlaps: (self: any, column: string, value: any) -> RPCFilterStage,
	match: (self: any, query: {[string]: any}) -> RPCFilterStage,
	not_: (self: any, column: string, operator: string, value: any) -> RPCFilterStage,
	filter: (self: any, column: string, operator: string, value: any) -> RPCFilterStage,
	or_: (self: any, filters: string, options: OrFilterOptions?) -> RPCFilterStage,

	-- Transitioning modifiers (move to RPCModifierStage)
	order: (self: any, column: string, options: OrderOptions?) -> RPCModifierStage,
	limit: (self: any, count: number, options: LimitOptions?) -> RPCModifierStage,
	range: (self: any, from: number, to: number, options: RangeOptions?) -> RPCModifierStage,
	single: (self: any) -> RPCModifierStage,
	maybeSingle: (self: any) -> RPCModifierStage,
	csv: (self: any) -> RPCModifierStage,
	returns: (self: any, representation: "minimal" | "representation") -> RPCModifierStage,
	overrideTypes: (self: any, schema: table) -> RPCModifierStage,
	explain: (self: any, options: ExplainOptions?) -> RPCModifierStage,

	-- Optional convenience
	get: (self: any) -> RPCFilterStage,
}

---------------------------------------------------------------------
-- INSERT / UPSERT (no filters — unchanged)
---------------------------------------------------------------------
export type InsertModifiers = MutationModifierFinal
export type InsertQuery = InsertModifiers
export type UpsertQuery = InsertModifiers

---------------------------------------------------------------------
-- UPDATE / DELETE (filters first, then mutation modifiers)
-- Corrected design:
-- - UpdateFilterStage: chainable filters, transition mutation modifiers -> UpdateModifierStage
-- - UpdateModifierStage: chainable mutation modifiers + execute
---------------------------------------------------------------------
export type UpdateModifierStage = MutationModifierFinal

export type UpdateFilterStage = BaseExec & {
	-- Chainable filters
	eq: (self: any, column: string, value: any) -> UpdateFilterStage,
	neq: (self: any, column: string, value: any) -> UpdateFilterStage,
	gt: (self: any, column: string, value: any) -> UpdateFilterStage,
	gte: (self: any, column: string, value: any) -> UpdateFilterStage,
	lt: (self: any, column: string, value: any) -> UpdateFilterStage,
	lte: (self: any, column: string, value: any) -> UpdateFilterStage,
	like: (self: any, column: string, pattern: string) -> UpdateFilterStage,
	ilike: (self: any, column: string, pattern: string) -> UpdateFilterStage,
	is: (self: any, column: string, value: boolean | "null") -> UpdateFilterStage,
	in_: (self: any, column: string, values: {any}) -> UpdateFilterStage,
	contains: (self: any, column: string, value: any) -> UpdateFilterStage,
	containedBy: (self: any, column: string, value: any) -> UpdateFilterStage,
	rangeGt: (self: any, column: string, range: string) -> UpdateFilterStage,
	rangeGte: (self: any, column: string, range: string) -> UpdateFilterStage,
	rangeLt: (self: any, column: string, range: string) -> UpdateFilterStage,
	rangeLte: (self: any, column: string, range: string) -> UpdateFilterStage,
	rangeAdjacent: (self: any, column: string, range: string) -> UpdateFilterStage,
	overlaps: (self: any, column: string, value: any) -> UpdateFilterStage,
	match: (self: any, query: {[string]: any}) -> UpdateFilterStage,
	not_: (self: any, column: string, operator: string, value: any) -> UpdateFilterStage,
	filter: (self: any, column: string, operator: string, value: any) -> UpdateFilterStage,
	or_: (self: any, filters: string, options: OrFilterOptions?) -> UpdateFilterStage,

	-- Transitioning mutation modifiers (move to UpdateModifierStage)
	select: (self: any, columns: string) -> UpdateModifierStage,
	returns: (self: any, representation: "minimal" | "representation") -> UpdateModifierStage,
	single: (self: any) -> UpdateModifierStage,
	maybeSingle: (self: any) -> UpdateModifierStage,
	csv: (self: any) -> UpdateModifierStage,
}

export type UpdateQuery = UpdateFilterStage

---------------------------------------------------------------------
-- Delete: same corrected pattern as Update
---------------------------------------------------------------------
export type DeleteModifierStage = MutationModifierFinal

export type DeleteFilterStage = BaseExec & {
	-- Chainable filters
	eq: (self: any, column: string, value: any) -> DeleteFilterStage,
	neq: (self: any, column: string, value: any) -> DeleteFilterStage,
	gt: (self: any, column: string, value: any) -> DeleteFilterStage,
	gte: (self: any, column: string, value: any) -> DeleteFilterStage,
	lt: (self: any, column: string, value: any) -> DeleteFilterStage,
	lte: (self: any, column: string, value: any) -> DeleteFilterStage,
	like: (self: any, column: string, pattern: string) -> DeleteFilterStage,
	ilike: (self: any, column: string, pattern: string) -> DeleteFilterStage,
	is: (self: any, column: string, value: boolean | "null") -> DeleteFilterStage,
	in_: (self: any, column: string, values: {any}) -> DeleteFilterStage,
	contains: (self: any, column: string, value: any) -> DeleteFilterStage,
	containedBy: (self: any, column: string, value: any) -> DeleteFilterStage,
	rangeGt: (self: any, column: string, range: string) -> DeleteFilterStage,
	rangeGte: (self: any, column: string, range: string) -> DeleteFilterStage,
	rangeLt: (self: any, column: string, range: string) -> DeleteFilterStage,
	rangeLte: (self: any, column: string, range: string) -> DeleteFilterStage,
	rangeAdjacent: (self: any, column: string, range: string) -> DeleteFilterStage,
	overlaps: (self: any, column: string, value: any) -> DeleteFilterStage,
	match: (self: any, query: {[string]: any}) -> DeleteFilterStage,
	not_: (self: any, column: string, operator: string, value: any) -> DeleteFilterStage,
	filter: (self: any, column: string, operator: string, value: any) -> DeleteFilterStage,
	or_: (self: any, filters: string, options: OrFilterOptions?) -> DeleteFilterStage,

	-- Transitioning mutation modifiers (move to DeleteModifierStage)
	select: (self: any, columns: string) -> DeleteModifierStage,
	returns: (self: any, representation: "minimal" | "representation") -> DeleteModifierStage,
	single: (self: any) -> DeleteModifierStage,
	maybeSingle: (self: any) -> DeleteModifierStage,
	csv: (self: any) -> DeleteModifierStage,
}

export type DeleteQuery = DeleteFilterStage

---------------------------------------------------------------------
-- ROOT QUERY (entrypoint)
---------------------------------------------------------------------
export type RootQuery = {
	-- SELECT: returns SelectFilterStage (filters chainable; modifiers transition)
	select: (self: any, columns: string) -> SelectFilterStage,

	-- INSERT: returns InsertQuery (no filters; only mutation modifiers)
	insert: (self: any, values: {any}, options: InsertOptions?) -> InsertQuery,

	-- UPDATE: returns UpdateQuery (filters chainable; modifiers transition)
	update: (self: any, values: {any}, options: UpdateOptions?) -> UpdateQuery,

	-- DELETE: returns DeleteQuery (filters chainable; modifiers transition)
	delete: (self: any, options: DeleteOptions?) -> DeleteQuery,

	-- UPSERT: returns UpsertQuery (no filters; only mutation modifiers)
	upsert: (self: any, values: {any}, options: InsertOptions?) -> UpsertQuery,

	-- RPC: returns RPCFilterStage (filters chainable; modifiers transition)
	rpc: (self: any, fnName: string, params: {any}?) -> RPCFilterStage,
}

---------------------------------------------------------------------
-- RestClient
---------------------------------------------------------------------
export type RestClient = {
	from: (self: RestClient, tableName: string) -> RootQuery,
}

return Types
