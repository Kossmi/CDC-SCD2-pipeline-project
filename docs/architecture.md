# Architecture

In this section you can take a closer look at the data flow. Pipeline is built out of three layers. For each layer separate schema was created 
and each schema stores one main table. This document provides details about architecture. You won't find here explanation of every design
choice that was made before I started actual work on this project. 

## Layer diagram

``` mermaid
  graph LR
    subgraph SOURCE
    A[Source orders - simulated]
    end
    subgraph STAGE
    B[Deduplicated, tiebroken]
    end
    subgraph DWH SCD2
    C[Full history]
    end

  A --> |delta extraction| B --> |indempotent MERGE| C

```

## Data flow in details

1. **SOURCE** - (`source.orders`) it is our model of transactional system. The procedure `simulate_changes` performs inserts,
   updates and soft-deletes - each of them stamped with `updated_at` and `source_seq`.
   
2.   **STAGE** - (`stage.orders.stg`) is append only. Each cycle only rows with source_seq greater than the last processed value
   are extracted (it's called: the delta). If the delta contains multiple versions of the same `order_id` deduplication keeps
   only the row with the highest `source_seq`.

3. **DWH/SCD2** - it is the historized target. The MERGE reads the deduplicated stage delta and per-row performs operations:
   if an attribute changed it closes version from the table, it inserts a new version with updated `valid_from` or it does
   nothing if the change is no-op (which means: no tracked attribute actually changed).

## Schemas and tables

`source.orders`
| Column | Type | Notes |
|--------|------|-------|
| `order_id` | NUMBER | Business key |
| `customer_id` | NUMBER | - |
| `status` | VARCHAR | `NEW`, `SHIPPED`, `CANCELLED`... |
| `total_amount` | NUMBER(10,2) | - |
| `shipping_city` | VARCHAR | - |
| `updated_at` | TIMESTAMP_NTZ | Set by the source system on every write |
| `is_deleted` | BOOLEAN | Soft-delete flag |
| `source_seq` | NUMBER | From `source.orders_seq`; increases on every write, used for tiebreaking |

`stage.orders_stg`

DO UZUPEŁNIENIA!!!

`dwh.orders_scd2`
| Column | Type | Notes |
|--------|------|-------|
| `order_sk` | NUMBER | Surrogate key, one per historical version |
| `order_id` | NUMBER | Business key |
| `status` | VARCHAR | `NEW`, `SHIPPED`, `CANCELLED`... |
| `total_amount` | NUMBER(10,2) | - |
| `shipping_city` | VARCHAR | - |
| `valid_from` | TIMESTAMP_NTZ | When this version became current |
| `valid_to` | TIMESTAMP_NTZ | When this version stopped being current (NULL for current row) |
| `is_current` | BOOLEAN | TRUE for exactly one row per `order_id` |
| `is_deleted` | BOOLEAN | Carried through from source |

## Related documents

* [README.md](../README.md) - project overview, design decisions, how to run and more.
