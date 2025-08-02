QueryBuilder = {}
QueryBuilder.__index = QueryBuilder

QB, DB = QueryBuilder, QueryBuilder -- aliases

local function quote(val)
    if type(val) == "string" then
        return "'" .. val:gsub("'", "''") .. "'"
    elseif val == nil then
        return "NULL"
    elseif type(val) == "boolean" then
        return val and "TRUE" or "FALSE"
    else
        return tostring(val)
    end
end

-- constructors
function QueryBuilder:new(operation, tableName)
    local instance = setmetatable({}, self)
    instance.operation = operation or nil
    instance.tableName = tableName or nil
    instance.conditions = {}
    instance.limitCount = nil
    instance.offsetCount = nil
    instance.ordering = {}
    instance.columnsData = nil
    instance.joins = {}
    instance._first = false
    instance._page = 1
    return instance
end

function QueryBuilder:table(tableName)
    self.tableName = tableName
    return self
end

function QueryBuilder:select(tableName)
    return self:new("select", tableName)
end

function QueryBuilder:insert(tableName)
    return self:new("insert", tableName)
end

function QueryBuilder:update(tableName)
    return self:new("update", tableName)
end

function QueryBuilder:delete(tableName)
    return self:new("delete", tableName)
end

function QueryBuilder:exists(tableName)
    return self:select(tableName):columns("1"):limit(1)
end

-- methodes
function QueryBuilder:columns(data)
    self.columnsData = type(data) == "table" and data or {data}
    return self
end

function QueryBuilder:_addCondition(condType, field, op, val)
    if val == nil then
        val = op
        op = "="
    end
    table.insert(self.conditions, {type = condType, condition = {field=field, operator=op, value=val}})
    return self
end

function QueryBuilder:where(field, op, val)
    return self:_addCondition("AND", field, op, val)
end

function QueryBuilder:orWhere(field, op, val)
    return self:_addCondition("OR", field, op, val)
end

function QueryBuilder:whereRaw(rawSql)
    table.insert(self.conditions, {type = "AND", raw = rawSql})
    return self
end

function QueryBuilder:orWhereRaw(rawSql)
    table.insert(self.conditions, {type = "OR", raw = rawSql})
    return self
end

function QueryBuilder:groupClause(conditions)
    local groupConditions = {}
    for _, cond in ipairs(conditions) do
        local field, op, val
        if #cond == 2 then
            field, val = cond[1], cond[2]
            op = "="
        elseif #cond == 3 then
            field, op, val = cond[1], cond[2], cond[3]
        else
            error("Invalid condition in groupClause")
        end
        table.insert(groupConditions, {field=field, operator=op, value=val})
    end
    table.insert(self.conditions, {type = "AND", group = groupConditions})
    return self
end

function QueryBuilder:limit(count, offset)
    self.limitCount = count
    self.offsetCount = offset
    return self
end

function QueryBuilder:orderBy(field, direction)
    direction = direction or "asc"
    direction = direction:lower()
    if direction ~= "asc" and direction ~= "desc" then
        error("Invalid order direction: " .. tostring(direction))
    end
    table.insert(self.ordering, {field=field, direction=direction})
    return self
end

function QueryBuilder:first()
    self.limitCount = 1
    self._first = true
    return self
end

function QueryBuilder:latest()
    return self:orderBy("created_at", "desc")
end

-- paginate
function QueryBuilder:paginate(perPage, page)
    perPage = tonumber(perPage) or error("perPage must be a number")
    page = tonumber(page) or self._page or 1
    if page < 1 then page = 1 end

    self.limitCount = perPage
    self.offsetCount = perPage * (page - 1)
    self._page = page
    return self
end

function QueryBuilder:page(pageNumber)
    pageNumber = tonumber(pageNumber) or 1
    if pageNumber < 1 then pageNumber = 1 end
    self._page = pageNumber
    return self
end

-- aggregate
function QueryBuilder:_aggregate(fn, column, alias)
    alias = alias or fn:lower()
    column = column or (fn:lower() == "count" and "*" or error(fn .. " requires a column name"))
    self.operation = "select"
    self.columnsData = {string.format("%s(%s) as %s", fn:upper(), column, alias)}
    return self
end

function QueryBuilder:count(column, alias)
    return self:_aggregate("count", column or "*", alias)
end

function QueryBuilder:sum(column, alias)
    return self:_aggregate("sum", column, alias)
end

function QueryBuilder:avg(column, alias)
    return self:_aggregate("avg", column, alias)
end

function QueryBuilder:min(column, alias)
    return self:_aggregate("min", column, alias)
end

function QueryBuilder:max(column, alias)
    return self:_aggregate("max", column, alias)
end

-- join 
function QueryBuilder:_addJoin(joinType, tableName, first, operator, second)
    table.insert(self.joins, {
        type = joinType,
        table = tableName,
        first = first,
        operator = operator,
        second = second
    })
    return self
end

function QueryBuilder:join(tableName, first, operator, second)
    return self:_addJoin("INNER JOIN", tableName, first, operator, second)
end

function QueryBuilder:leftJoin(tableName, first, operator, second)
    return self:_addJoin("LEFT JOIN", tableName, first, operator, second)
end

function QueryBuilder:rightJoin(tableName, first, operator, second)
    return self:_addJoin("RIGHT JOIN", tableName, first, operator, second)
end

function QueryBuilder:crossJoin(tableName)
    table.insert(self.joins, {
        type = "CROSS JOIN",
        table = tableName,
        first = nil,
        operator = nil,
        second = nil
    })
    return self
end

-- build the query
function QueryBuilder:_buildWhere()
    if #self.conditions == 0 then
        return " WHERE 1"
    end

    local parts = {}
    for i, cond in ipairs(self.conditions) do
        local prefix = ""
        if i > 1 then
            prefix = cond.type .. " "
        end

        if cond.raw then
            -- Insert raw condition as is
            table.insert(parts, prefix .. cond.raw)
        elseif cond.group then
            local groupParts = {}
            for _, c in ipairs(cond.group) do
                table.insert(groupParts, string.format("%s %s %s", c.field, c.operator, quote(c.value)))
            end
            table.insert(parts, prefix .. "(" .. table.concat(groupParts, " AND ") .. ")")
        else
            local c = cond.condition
            table.insert(parts, prefix .. string.format("%s %s %s", c.field, c.operator, quote(c.value)))
        end
    end

    return " WHERE " .. table.concat(parts, " ")
end

function QueryBuilder:_buildOrderBy()
    if #self.ordering == 0 then
        return ""
    end
    local parts = {}
    for _, ord in ipairs(self.ordering) do
        table.insert(parts, string.format("%s %s", ord.field, ord.direction:upper()))
    end
    return " ORDER BY " .. table.concat(parts, ", ")
end

function QueryBuilder:_buildJoins()
    if #self.joins == 0 then
        return ""
    end
    local parts = {}
    for _, join in ipairs(self.joins) do
        if join.type == "CROSS JOIN" then
            table.insert(parts, string.format("%s %s", join.type, join.table))
        else
            table.insert(parts, string.format("%s %s ON %s %s %s", join.type, join.table, join.first, join.operator, join.second))
        end
    end
    return " " .. table.concat(parts, " ")
end

function QueryBuilder:build()
    assert(self.operation, "No operation specified")
    assert(self.tableName, "Table name not specified")

    local sql = ""

    if self.operation == "select" then
        local cols = "*"
        if self.columnsData then
            if type(self.columnsData) == "table" then
                local isArray = true
                for k, _ in pairs(self.columnsData) do
                    if type(k) ~= "number" then
                        isArray = false
                        break
                    end
                end
                if isArray then
                    cols = table.concat(self.columnsData, ", ")
                else
                    cols = "*"
                end
            end
        end

        sql = "SELECT " .. cols .. " FROM " .. self.tableName
        sql = sql .. self:_buildJoins()
        sql = sql .. self:_buildWhere()
        sql = sql .. self:_buildOrderBy()
        if self.limitCount then
            sql = sql .. " LIMIT " .. self.limitCount
            if self.offsetCount then
                sql = sql .. " OFFSET " .. self.offsetCount
            end
        end

    elseif self.operation == "insert" then
        assert(self.columnsData and type(self.columnsData) == "table", "Insert data must be provided as table to columns()")
        local keys = {}
        local values = {}
        for k, v in pairs(self.columnsData) do
            table.insert(keys, k)
            table.insert(values, quote(v))
        end
        sql = string.format("INSERT INTO %s (%s) VALUES (%s)", self.tableName, table.concat(keys, ", "), table.concat(values, ", "))

    elseif self.operation == "update" then
        assert(self.columnsData and type(self.columnsData) == "table", "Update data must be provided as table to columns()")

        local sets = {}
        for k, v in pairs(self.columnsData) do
            table.insert(sets, string.format("%s = %s", k, quote(v)))
        end
        sql = "UPDATE " .. self.tableName .. " SET " .. table.concat(sets, ", ")
        sql = sql .. self:_buildJoins()
        sql = sql .. self:_buildWhere()
        if self.limitCount then
            sql = sql .. " LIMIT " .. self.limitCount
            if self.offsetCount then
                sql = sql .. " OFFSET " .. self.offsetCount
            end
        end

    elseif self.operation == "delete" then
        sql = "DELETE FROM " .. self.tableName
        sql = sql .. self:_buildJoins()
        sql = sql .. self:_buildWhere()
        if self.limitCount then
            sql = sql .. " LIMIT " .. self.limitCount
            if self.offsetCount then
                sql = sql .. " OFFSET " .. self.offsetCount
            end
        end

    else
        error("Unknown operation: " .. tostring(self.operation))
    end

    return sql
end
