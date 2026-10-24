from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import json
from typing import Any

router = APIRouter()
metaData: dict | None = None


class ColumnMeta(BaseModel):
    params: list[str]
    mods: str = "None"


class QueryRequest(BaseModel):
    command: str
    tableName: str
    args: dict[str, Any] = {}
    where: dict[str, Any] = {}
    columns: list[str] | None = None

def _apply_mod(mod: str, value: Any) -> Any:
    if value is None:
        return None
    if mod == "dict":
        return value if isinstance(value, str) else json.dumps(value)
    if mod == "integer":
        return int(value)
    return value

def _check(meta: dict, table: str, cols) -> dict:
    if table not in meta:
        raise ValueError(f"Unknown table: {table}")
    unknown = [c for c in cols if c not in meta[table]]
    if unknown:
        raise ValueError(f"Unknown column(s) for {table}: {unknown}")
    return meta[table]

def build_query(
    meta: dict,
    command: str,
    table: str,
    args: dict[str, Any] | None = None,    # values for INSERT / UPDATE SET
    where: dict[str, Any] | None = None,   # equality filters
    columns: list[str] | None = None,      # SELECT columns (default: all)
) -> tuple[str, list[Any]]:
    """Returns (sql, values) ready for cursor.execute(sql, values)."""
    command = command.upper()
    args = args or {}
    where = where or {}

    schema = _check(meta, table, [*args, *where, *(columns or [])])
    values: list[Any] = []

    def where_clause() -> str:
        if not where:
            return ""
        parts = []
        for col, val in where.items():
            parts.append(f'"{col}" = ?')
            values.append(_apply_mod(schema[col]["mods"], val))
        return " WHERE " + " AND ".join(parts)

    if command == "CREATE":
        cols = ", ".join(f'"{c}" {spec["params"][0]}' for c, spec in schema.items())
        return f'CREATE TABLE IF NOT EXISTS "{table}" ({cols})', []

    if command == "INSERT":
        if not args:
            raise ValueError("INSERT requires args")
        cols = list(args)
        values = [_apply_mod(schema[c]["mods"], args[c]) for c in cols]
        names = ", ".join(f'"{c}"' for c in cols)
        marks = ", ".join("?" for _ in cols)
        return f'INSERT INTO "{table}" ({names}) VALUES ({marks})', values

    if command == "SELECT":
        cols = ", ".join(f'"{c}"' for c in columns) if columns else "*"
        sql = f'SELECT {cols} FROM "{table}"'
        return sql + where_clause(), values

    if command == "UPDATE":
        if not args:
            raise ValueError("UPDATE requires args")
        if not where:
            raise ValueError("UPDATE requires a where clause")
        sets = []
        for col, val in args.items():
            sets.append(f'"{col}" = ?')
            values.append(_apply_mod(schema[col]["mods"], val))
        sql = f'UPDATE "{table}" SET {", ".join(sets)}'
        return sql + where_clause(), values

    if command == "DELETE":
        if not where:
            raise ValueError("DELETE requires a where clause")
        return f'DELETE FROM "{table}"' + where_clause(), values

    raise ValueError(f"Unsupported command: {command}")

@router.post("/updateTableMeta")
def update_table_meta(data: dict[str, dict[str, ColumnMeta]]):
    global metaData
    # store as plain dicts so build_query's schema[col]["mods"] works unchanged
    metaData = {
        table: {col: spec.model_dump() for col, spec in cols.items()}
        for table, cols in data.items()
    }
    return {"detail": "Table data updated"}


@router.post("/formQuery")
def form_query(req: QueryRequest):
    if metaData is None:
        raise HTTPException(status_code=409, detail="Table metadata not set")
    try:
        sql, values = build_query(
            metaData,
            req.command,
            req.tableName,
            args=req.args,
            where=req.where,
            columns=req.columns,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return {"sql": sql, "values": values}