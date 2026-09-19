CREATE OR REPLACE PROCEDURE "stage"."extract_delta"()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_last_seq       NUMBER;
    v_new_max_seq    NUMBER;
    v_rows_inserted  NUMBER;
BEGIN
    -- Read the watermark. --
    SELECT "last_processed_seq" INTO :v_last_seq
    FROM "stage"."etl_watermark"
    WHERE "table_name" = 'orders';

    -- Extract all records newer than the watermark + deduplicate (when order_id appears more than once, keep the row with 
    -- the highest source_seq). --
    INSERT INTO "stage"."orders_stg" ("order_id", "customer_id", "status", "total_amount", "shipping_city",
                "updated_at", "is_deleted", "source_seq"
    )
    SELECT
        "order_id", "customer_id", "status", "total_amount", "shipping_city",
        "updated_at", "is_deleted", "source_seq"
    FROM (
        SELECT *,
        ROW_NUMBER() OVER (PARTITION BY "order_id" ORDER BY "source_seq" DESC) AS "rn"
        FROM "source"."orders"
        WHERE "source_seq" > :v_last_seq
    )
    WHERE "rn" = 1;

    v_rows_inserted := SQLROWCOUNT;

    -- Update the watermark with the new maximum source_seq value. --
    SELECT MAX("source_seq") INTO :v_new_max_seq
    FROM "source"."orders"
    WHERE "source_seq" > :v_last_seq;

    IF (v_new_max_seq IS NOT NULL) THEN
        UPDATE "stage"."etl_watermark"
        SET "last_processed_seq" = :v_new_max_seq
        WHERE "table_name" = 'orders';
    END IF;

    RETURN 'Inserted ' || :v_rows_inserted || ' new records into "stage"."orders_stg". Watermark: ' || COALESCE(:v_last_seq, 0)
            || ' -> ' || COALESCE(:v_new_max_seq, :v_last_seq);
END;
$$;

-- Check the procedure. --
CALL "stage"."extract_delta"();
SELECT * FROM "stage"."orders_stg" ORDER BY "source_seq" DESC;
SELECT * FROM "stage"."etl_watermark";

-- Check: should not insert any new records. --
CALL "stage"."extract_delta"();