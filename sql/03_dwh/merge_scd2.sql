-- Watermark for merge step. Tracks the highest "source_seq" already loaded into the "dwh"."orders_scd2" table. --
USE DATABASE "CDC-SCD2-project";
USE SCHEMA "dwh";

CREATE OR REPLACE TABLE "dwh"."etl_watermark" (
    "table_name"                VARCHAR(50)              NOT NULL,
    "last_merged_seq"           NUMBER                   NOT NULL   
);

INSERT INTO "dwh"."etl_watermark" ("table_name", "last_merged_seq") VALUES ('orders', 0);

CREATE OR REPLACE PROCEDURE "dwh"."merge_scd2"()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_last_merged         NUMBER;
    v_new_max_seq         NUMBER;
    v_closed_count        NUMBER DEFAULT 0;
    v_inserted_count      NUMBER DEFAULT 0;
BEGIN
    SELECT "last_merged_seq" INTO :v_last_merged
    FROM "dwh"."etl_watermark"
    WHERE "table_name" = 'orders';

    -- Close existing records that have been updated. --
    MERGE INTO "dwh"."orders_scd2" AS tgt
    USING (
        SELECT * FROM "stage"."orders_stg" WHERE "source_seq" > :v_last_merged
    ) AS src
    ON tgt."order_id" = src."order_id" AND tgt."is_current" = TRUE
    WHEN MATCHED AND (
        tgt."status"         != src."status" OR
        tgt."total_amount"   != src."total_amount" OR
        COALESCE(tgt."shipping_city", '') != COALESCE(src."shipping_city", '') OR
        tgt."is_deleted"     != src."is_deleted"
    ) THEN UPDATE SET
        "valid_to" = src."updated_at",
        "is_current" = FALSE;

    v_closed_count := SQLROWCOUNT;

    -- Insert new records for brand new records, for updated records or do nothing for unchanged records. --
    INSERT INTO "dwh"."orders_scd2" (
        "order_sk", "order_id", "customer_id", "status", "total_amount", "shipping_city",
        "is_deleted", "valid_from", "valid_to", "is_current", "source_seq"
    )
    SELECT
        "dwh"."orders_scd2_sk_seq".NEXTVAL,
        src."order_id", src."customer_id", src."status", src."total_amount", src."shipping_city",
        src."is_deleted", src."updated_at", NULL, TRUE, src."source_seq"
    FROM "stage"."orders_stg" AS src
    WHERE src."source_seq" > :v_last_merged
        AND NOT EXISTS (
            SELECT 1 FROM "dwh"."orders_scd2" AS tgt
            WHERE tgt."order_id" = src."order_id"
              AND tgt."is_current" = TRUE
              AND tgt."status" = src."status"
              AND tgt."total_amount" = src."total_amount"
              AND COALESCE(tgt."shipping_city", '') = COALESCE(src."shipping_city", '')
              AND tgt."is_deleted" = src."is_deleted" 
        );

    v_inserted_count := SQLROWCOUNT;

    -- Update the watermark for merge. --
    SELECT MAX("source_seq") INTO :v_new_max_seq
    FROM "stage"."orders_stg"
    WHERE "source_seq" > :v_last_merged;

    IF (v_new_max_seq IS NOT NULL) THEN
        UPDATE "dwh"."etl_watermark"
        SET "last_merged_seq" = :v_new_max_seq
        WHERE "table_name" = 'orders';
    END IF;

    RETURN 'Closed ' || :v_closed_count || ' existing records. Inserted: ' || :v_inserted_count || ' new records. Watermark: ' 
        || COALESCE(:v_last_merged, 0) || ' -> ' || COALESCE(:v_new_max_seq, :v_last_merged);

END;
$$;

-- Check. --
CALL "dwh"."merge_scd2"();

SELECT * FROM "dwh"."orders_scd2" ORDER BY "order_id", "valid_from";