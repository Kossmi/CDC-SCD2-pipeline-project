CREATE OR REPLACE SEQUENCE "dwh"."orders_scd2_sk_seq"
    START = 1
    INCREMENT = 1;

CREATE OR REPLACE TABLE "dwh"."orders_scd2" (
    "order_sk"                NUMBER                     NOT NULL,
    "order_id"                 NUMBER                     NOT NULL,
    "customer_id"              NUMBER                     NOT NULL,
    "status"                   VARCHAR(20)                NOT NULL,
    "total_amount"             NUMBER(10,2)               NOT NULL,
    "shipping_city"            VARCHAR(40),
    "is_deleted"               BOOLEAN                    DEFAULT FALSE,
    "valid_from"               TIMESTAMP_NTZ              NOT NULL,
    "valid_to"                 TIMESTAMP_NTZ,
    "is_current"               BOOLEAN                    DEFAULT TRUE,
    "source_seq"               NUMBER                     NOT NULL
);

-- Check. --
SHOW TABLES IN SCHEMA "dwh";
SELECT * FROM "dwh"."orders_scd2";