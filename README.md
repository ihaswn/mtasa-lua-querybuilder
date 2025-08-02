# Lua QueryBuilder
a lightweight Lua SQL query builder inspired by Laravel's Eloquent ORM 

## About

This project is a lightweight Lua SQL query builder inspired by Laravel's Eloquent ORM and its expressive query building syntax.

It aims to provide a fluent, chainable interface to construct SQL queries programmatically in Lua, supporting common operations such as `select`, `insert`, `update`, `delete`, as well as joins, aggregates, pagination, and raw where clauses.

The design follows the style and convenience of Laravel's query builder, adapted for Lua environments.

## Installation
- Download the latest version from Releases page.
- Extract the downloaded package to your server resources directory.
- Add the queryBuilder resource to your `mtaserver.conf`:
```xml
<resource src="queryBuilder" startup="1" protected="0" />
```
- Run your server.

## Usage
* There is two ways to use the `Query Builder`
### 1. OOP
- for using the oop version you need to import the class.lua file using `loadstring` on top of the script you want to use it, example:
```lua
-- load the class
loadstring(exports.queryBuilder:import())()

-- now you can use the QueryBuilder Class
local query = QueryBuilder:select("users")
    :where("score", ">=", 100)
    :orWhere("id", 1)
    :first()
    :build()
print(query)
-- output:
-- SELECT id, score, name FROM users WHERE score >= 100 OR id = 1 LIMIT 1
```
### 2. Helper Function
- if you dont want to use OOP version or dont like to use `loadstring()` you can use the helper function which is exported:

```lua
local query = exports.buildQuery("users", "select", {
    where = {
        {"score", ">=", 100},
    },
    orWhere = {
        {"id", 1}
    },
    first = true, -- or limit = 1
})
print(query)
-- output:
-- SELECT id, score, name FROM users WHERE score >= 100 OR id = 1 LIMIT 1

```

> [!WARNING]
> The current version is not using `dbPrepareString()`, it will be supported in the feature updates, but for know be careful with the queries and values to avoid sql injections

## Features (planned / implemented so far)

- Fluent API for building SQL queries  
- Support for `select`, `insert`, `update`, and `delete` operations  
- Chainable `where`, `orWhere`, and `whereRaw` conditions  
- Joins: inner, left, right, cross joins  
- Aggregate functions: `count`, `sum`, `avg`, `min`, `max`  
- Pagination and limit/offset support  
- Ordering of results  
- Ability to build raw SQL with flexible options  
- Non-OOP helper function to build queries quickly that does not need to be imported

## Contact

For questions or suggestions, please open an issue or contact me on Telegram/Discord (@ihaswn).

*Thank you for your patience!*