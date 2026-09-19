-- Append-only table for the raw delta from the "source"."orders" table. --
CREATE OR REPLACE TABLE "stage"."orders_stg" (
    "order_id"                  NUMBER                   NOT NULL,
    "customer_id"               NUMBER                   NOT NULL,
    "status"                    VARCHAR(20)              NOT NULL,
    "total_amount"              NUMBER(10,2)             NOT NULL,
    "shipping_city"             VARCHAR(40),
    "updated_at"                TIMESTAMP_NTZ            NOT NULL,
    "is_deleted"                BOOLEAN                  DEFAULT FALSE,
    "source_seq"                NUMBER                   NOT NULL,
    "stg_loaded_at"             TIMESTAMP_NTZ            DEFAULT CURRENT_TIMESTAMP()
);

-- Watermark. It is used to "remember" the last processed record from "source"."orders" with the highest "source_seq" value.
-- One row for each table that is beeing processed. --

CREATE OR REPLACE TABLE "stage"."etl_watermark" (
    "table_name"                VARCHAR(50)              NOT NULL,
    "last_processed_seq"        NUMBER                   NOT NULL
);

-- Setting the seed value with a starting point of 0. --
INSERT INTO "stage"."etl_watermark" ("table_name", "last_processed_seq")
VALUES ('orders', 0);

-- Check. --
SELECT * FROM "stage"."etl_watermark";
