export type Pair<T> = {
    first: T,
    second: T,
}

export type Row<T> = {
    [string]: T,
}

export type QueryResult<T> = {
    data: { Row<T> }?,
    error: string?,
}