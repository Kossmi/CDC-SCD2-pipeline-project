CREATE OR REPLACE SEQUENCE "source"."orders_seq"
    START = 1
    INCREMENT = 1;

CREATE OR REPLACE TABLE "source"."orders" (
    "order_id"      NUMBER        NOT NULL,
    "customer_id"   NUMBER        NOT NULL,
    "status"        VARCHAR(20)   NOT NULL,
    "total_amount"  NUMBER(10,2)  NOT NULL,
    "shipping_city" VARCHAR(40),
    "updated_at"    TIMESTAMP_NTZ NOT NULL,
    "is_deleted"    BOOLEAN       DEFAULT FALSE,
    "source_seq"    NUMBER        NOT NULL
);