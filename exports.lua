-- buildQuery(tableName, operation, options)
-- options can include keys like:
--   columns (table or string)
--   where (array of conditions for .where calls)
--   orWhere (array of conditions for .orWhere calls)
--   whereRaw (array of raw where strings)
--   joins (array of join specs)
--   orderBy (array of {field, direction})
--   limit (number)
--   paginate (number)
--   page (number)
--   aggregate (table with keys: fn, column, alias) or array of such tables
--   first (boolean)
--   latest (boolean)
--   etc.

function buildQuery(tableName, operation, options)
    options = options or {}

    local qb = QueryBuilder:new(operation, tableName)

    -- columns
    if options.columns then
        qb:columns(options.columns)
    end

    -- where conditions (array of {field, operator, value} or {field, value})
    if options.where then
        for _, cond in ipairs(options.where) do
            if #cond == 2 then
                qb:where(cond[1], cond[2])
            elseif #cond == 3 then
                qb:where(cond[1], cond[2], cond[3])
            else
                error("Invalid where condition")
            end
        end
    end

    -- orWhere conditions
    if options.orWhere then
        for _, cond in ipairs(options.orWhere) do
            if #cond == 2 then
                qb:orWhere(cond[1], cond[2])
            elseif #cond == 3 then
                qb:orWhere(cond[1], cond[2], cond[3])
            else
                error("Invalid orWhere condition")
            end
        end
    end

    -- whereRaw conditions (array of strings)
    if options.whereRaw then
        for _, raw in ipairs(options.whereRaw) do
            qb:whereRaw(raw)
        end
    end

    -- joins (array of {type = "inner"/"left"/..., tableName, first, operator, second})
    if options.joins then
        for _, join in ipairs(options.joins) do
            local joinType = (join.type or "inner"):lower()
            if joinType == "inner" then
                qb:join(join.tableName, join.first, join.operator, join.second)
            elseif joinType == "left" then
                qb:leftJoin(join.tableName, join.first, join.operator, join.second)
            elseif joinType == "right" then
                qb:rightJoin(join.tableName, join.first, join.operator, join.second)
            elseif joinType == "cross" then
                qb:crossJoin(join.tableName)
            else
                error("Unknown join type: " .. tostring(join.type))
            end
        end
    end

    -- orderBy (array of {field, direction})
    if options.orderBy then
        for _, ord in ipairs(options.orderBy) do
            qb:orderBy(ord[1], ord[2])
        end
    end

    -- limit
    if options.limit then
        qb:limit(options.limit, options.offset)
    end

    -- paginate
    if options.paginate then
        qb:paginate(options.paginate, options.page)
    elseif options.page then
        qb:page(options.page)
    end

    -- aggregate (single or array of aggregates)
    if options.aggregate then
        local function applyAggregate(agg)
            if agg.fn and agg.column then
                local alias = agg.alias
                local fn = agg.fn:lower()
                if fn == "count" then
                    qb:count(agg.column, alias)
                elseif fn == "sum" then
                    qb:sum(agg.column, alias)
                elseif fn == "avg" then
                    qb:avg(agg.column, alias)
                elseif fn == "min" then
                    qb:min(agg.column, alias)
                elseif fn == "max" then
                    qb:max(agg.column, alias)
                else
                    error("Unknown aggregate function: " .. tostring(agg.fn))
                end
            else
                error("Aggregate must have fn and column")
            end
        end

        if type(options.aggregate) == "table" and #options.aggregate > 0 then
            for _, agg in ipairs(options.aggregate) do
                applyAggregate(agg)
            end
        else
            applyAggregate(options.aggregate)
        end
    end

    -- first
    if options.first then
        qb:first()
    end

    -- latest
    if options.latest then
        qb:latest()
    end

    return qb:build()
end