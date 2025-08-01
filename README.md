# Lua QueryBuilder

> **Work in Progress:** This README is currently under construction and will be updated soon with complete documentation.

---

## TODO

- [ ] Introduction and project overview  
- [ ] Installation instructions  
- [ ] Usage examples  
- [ ] FAQ and troubleshooting  

---

## About

This project is a lightweight Lua SQL query builder inspired by Laravel's Eloquent ORM and its expressive query building syntax.

It aims to provide a fluent, chainable interface to construct SQL queries programmatically in Lua, supporting common operations such as `select`, `insert`, `update`, `delete`, as well as joins, aggregates, pagination, and raw where clauses.

The design follows the style and convenience of Laravel's query builder, adapted for Lua environments.

---

## Note
The OOP version needs to be imported to other resources using `loadstring(exports.queryBuilder:import())()` since we can't export the class, or you can just use the helper function `exports.buildQuery(...)` if you dont want to use the OOP version, but you miss out the strong feature of the resource which is the chained query builder that was inspired by Laravel

---

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

---

## Contact

For questions or suggestions, please open an issue or contact me on Telegram/Discord (@ihaswn).

---

*Thank you for your patience!*