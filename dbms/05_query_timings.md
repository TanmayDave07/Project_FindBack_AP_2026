
# Query Performance Timings

## Environment
- Database: PostgreSQL
- Database name: findback_db
- PostgreSQL client: 18.6
- Benchmark method: EXPLAIN (ANALYZE, BUFFERS)
- Number of runs per query: 3
- Unit: milliseconds (ms)

## Query Execution Timings

| Query | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---:|---:|---:|---:|
| Q01 | 0.407 | 0.130 | 0.127 | 0.221 |
| Q02 | 0.028 | 0.051 | 0.047 | 0.042 |
| Q03 | 0.617 | 0.077 | 0.074 | 0.256 |
| Q04 | 0.855 | 0.133 | 0.069 | 0.352 |
| Q05 | 0.041 | 0.044 | 0.048 | 0.044 |
| Q06 | 0.238 | 0.243 | 0.441 | 0.307 |
| Q07 | Pending | Pending | Pending | Pending |
| Q08 | Pending | Pending | Pending | Pending |
| Q09 | Pending | Pending | Pending | Pending |
| Q10 | Pending | Pending | Pending | Pending |
| Q11 | Pending | Pending | Pending | Pending |
| Q12 | Pending | Pending | Pending | Pending |
| Q13 | Pending | Pending | Pending | Pending |
| Q14 | Pending | Pending | Pending | Pending |
| Q15 | Pending | Pending | Pending | Pending |
| Q16 | Pending | Pending | Pending | Pending |
| Q17 | Pending | Pending | Pending | Pending |
| Q18 | Pending | Pending | Pending | Pending |
| Q19 | Pending | Pending | Pending | Pending |
| Q20 | Pending | Pending | Pending | Pending |
| Q21 | Pending | Pending | Pending | Pending |
| Q22 | Pending | Pending | Pending | Pending |
| Q23 | Pending | Pending | Pending | Pending |
| Q24 | Pending | Pending | Pending | Pending |

## Methodology

Each query is executed three times using PostgreSQL's EXPLAIN ANALYZE with BUFFERS enabled.

Average execution time is calculated as:

(Run 1 + Run 2 + Run 3) / 3

Execution times are recorded in milliseconds.
