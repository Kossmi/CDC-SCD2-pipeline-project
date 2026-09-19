USE DATABASE "CDC-SCD2-project";
USE SCHEMA "source";
CREATE OR REPLACE PROCEDURE "source"."simulate_changes"(cycle_number NUMBER)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    -- Insert new orders --
    INSERT INTO "source"."orders" ( 
        "order_id", "customer_id", "status", "total_amount", "shipping_city", "updated_at", "is_deleted", "source_seq"
    )
    SELECT  
        (:cycle_number * 1000) + SEQ4()                                        AS "order_id",
        UNIFORM(1, 50, RANDOM())                                               AS "customer_id",
        'NEW'                                                                  AS "status",
        UNIFORM(20, 500, RANDOM())                                             AS "total_amount",
        ARRAY_CONSTRUCT('Poznan', 'Warszawa', 'Krakow', 'Wroclaw', 'Gdansk',
                        'Szczecin', 'Lodz', 'Katowice', 'Lublin', 'Bydgoszcz')
                        [UNIFORM(0, 9, RANDOM())]                              AS "shipping_city",
        CURRENT_TIMESTAMP()                                                    AS "updated_at",
        FALSE                                                                  AS "is_deleted",
        "source"."orders_seq".NEXTVAL                                          AS "source_seq"
    FROM TABLE(GENERATOR(ROWCOUNT => 15));

    -- Update some existing orders --
    UPDATE "source"."orders"
    SET
        "status" = 'SHIPPED',
        "updated_at" = CURRENT_TIMESTAMP(),
        "source_seq" = "source"."orders_seq".NEXTVAL
    WHERE "order_id" IN (
        SELECT "order_id"
        FROM "source"."orders"
        SAMPLE (30)
        WHERE "status" = 'NEW'
    );

    -- Soft-delete some existing orders --
    UPDATE "source"."orders"
    SET
        "is_deleted" = TRUE,
        "updated_at" = CURRENT_TIMESTAMP(),
        "source_seq" = "source"."orders_seq".NEXTVAL
    WHERE "order_id" IN (
        SELECT "order_id"
        FROM "source"."orders"
        SAMPLE (10)
    );

    RETURN 'Cycle ' || :cycle_number || ' completed successfully.';
END;
$$;

SHOW PROCEDURES;

CALL "source"."simulate_changes"(1);

SELECT * FROM "source"."orders";