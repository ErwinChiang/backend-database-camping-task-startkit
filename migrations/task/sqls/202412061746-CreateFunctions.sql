--Task5
-- 建立使用教練名稱查詢課程的function
CREATE OR REPLACE FUNCTION GET_COURSES_BY_COACH_NAME_AND_START_AT(
    P_COACH_NAME VARCHAR,
    P_COURSE_NAME VARCHAR,
    P_COURSE_START_AT TIMESTAMP
) RETURNS TABLE (
    course_id INTEGER,
    coach_name VARCHAR,
    course_name VARCHAR,
    start_at TIMESTAMP,
    end_at TIMESTAMP,
    max_participants INTEGER,
    meeting_url VARCHAR
) AS $$
BEGIN
RETURN QUERY
SELECT
    "COURSE".id,
    "USER".name AS coach_name,
    "COURSE".name AS course_name,
    "COURSE".start_at,
    "COURSE".end_at,
    "COURSE".max_participants,
    "COURSE".meeting_url
FROM "COURSE"
LEFT JOIN "USER" ON "COURSE".user_id = "USER".id AND "USER".role = 'COACH'
WHERE LOWER("USER".name) = LOWER(P_COACH_NAME)
AND (LOWER("COURSE".name) = LOWER(P_COURSE_NAME) OR P_COURSE_NAME IS NULL)
AND ("COURSE".start_at = P_COURSE_START_AT OR P_COURSE_START_AT IS NULL);
END;
$$ LANGUAGE plpgsql;
-- 建立使用使用者EMAIL查詢所有預約紀錄的function
CREATE OR REPLACE FUNCTION GET_COURSES_BOOKING_BY_USER_EMAIL(
    P_USER_EMAIL VARCHAR(320)
) RETURNS TABLE (
    user_name VARCHAR(50),
    email VARCHAR(320),
    course_name VARCHAR(100),
    start_at TIMESTAMP,
    booking_at TIMESTAMP,
    status VARCHAR(20),
    join_at TIMESTAMP,
    leave_at TIMESTAMP,
    cancel_at TIMESTAMP,
    cancellation_reason VARCHAR
) AS $$
BEGIN
RETURN QUERY
SELECT
    "USER".name,
    "USER".email,
    "COURSE".name,
    "COURSE".start_at,
    "COURSE_BOOKING".booking_at,
    "COURSE_BOOKING".status,
    "COURSE_BOOKING".join_at,
    "COURSE_BOOKING".leave_at,
    "COURSE_BOOKING".cancel_at,
    "COURSE_BOOKING".cancellation_reason
FROM "USER"
LEFT JOIN "COURSE_BOOKING" ON "USER".id = "COURSE_BOOKING".user_id
JOIN "COURSE" ON "COURSE".id = "COURSE_BOOKING".course_id
WHERE "USER".Email = P_USER_EMAIL OR P_USER_EMAIL IS NULL;
END;
$$ LANGUAGE plpgsql;
-- 建立以EMAIL查詢課程購買數量的function
CREATE OR REPLACE FUNCTION GET_PURCHASED_CREDITS_BY_USER_EMAIL(
    P_USER_EMAIL VARCHAR(320) DEFAULT NULL
) RETURNS TABLE (
    user_id uuid,
    user_name varchar(50),
    purchased_credits_total Integer
) AS $$
BEGIN
RETURN QUERY
SELECT "USER".id as user_id, "USER".name as user_name, SUM(purchased_credits)::integer as purchased_credits_total
FROM "USER"
JOIN "CREDIT_PURCHASE"
ON "CREDIT_PURCHASE".user_id = "USER".id
WHERE "USER".email = P_USER_EMAIL OR P_USER_EMAIL IS NULL
GROUP BY "USER".id, "USER".name;
END;
$$ LANGUAGE plpgsql;
-- 建立以EMAIL查詢課程已使用數量的function
CREATE OR REPLACE FUNCTION GET_USED_CREDITS_BY_USER_EMAIL(
    P_USER_EMAIL VARCHAR(320) DEFAULT NULL
) RETURNS TABLE (
    user_id uuid,
    user_name varchar(50),
    used_credit_total Integer
) AS $$
BEGIN
RETURN QUERY
SELECT "USER".id as user_id, "USER".name, COUNT(1)::INTEGER as used_credit_total
FROM "USER"
JOIN "COURSE_BOOKING"
ON "COURSE_BOOKING".user_id = "USER".id
AND "COURSE_BOOKING".cancel_at IS NULL
WHERE "USER".email = P_USER_EMAIL OR P_USER_EMAIL IS NULL
GROUP BY "USER".id, "USER".name;
END;
$$ LANGUAGE plpgsql;
-- 建立以EMAIL查詢課程剩餘數量的function
CREATE OR REPLACE FUNCTION GET_REMAINING_CREDITS_BY_USER_EMAIL(
    P_USER_EMAIL VARCHAR(320) DEFAULT NULL
) RETURNS TABLE (
    user_id uuid,
    user_name varchar(50),
    purchased_credits_total Integer,
    used_credit_total Integer,
    remaining_credit Integer
) AS $$
BEGIN
RETURN QUERY
SELECT
    p.user_id as user_id,
    p.user_name as user_name,
    p.purchased_credits_total as purchased_credits_total,
    u.used_credit_total as used_credits_total,
    p.purchased_credits_total - u.used_credit_total as remaining_credit
FROM GET_PURCHASED_CREDITS_BY_USER_EMAIL(P_USER_EMAIL) p
LEFT JOIN GET_USED_CREDITS_BY_USER_EMAIL(P_USER_EMAIL) u
ON p.user_id = u.user_id;
END;
$$ LANGUAGE plpgsql;
-- Task6
-- 建立取得教練資料的function
CREATE OR REPLACE FUNCTION GET_COACH_ORDER_BY_EXPERIENCE_YEARS()
RETURNS TABLE (
    "教練名稱" varchar(50),
    "經驗年數" integer,
    "專長名稱" text,
    "技能數量" bigint
) AS $$
BEGIN
RETURN QUERY
SELECT
    "USER".NAME AS "教練名稱",
    "COACH".experience_years AS "經驗年數",
    STRING_AGG("SKILL".name, ';') AS "專長名稱",
    COUNT("SKILL".name) AS "技能數量"
FROM "COACH"
INNER JOIN "USER" ON "USER".role = 'COACH'
AND "USER".id = "COACH".user_id
LEFT JOIN "COACH_LINK_SKILL" ON "COACH_LINK_SKILL".coach_id = "COACH".id
LEFT JOIN "SKILL" ON "SKILL".id = "COACH_LINK_SKILL".skill_id
GROUP BY "USER".id, "COACH".experience_years
ORDER BY "COACH".experience_years;
END;
$$ LANGUAGE plpgsql;
-- 建立取得銷售紀錄資料的function
CREATE OR REPLACE FUNCTION REPORT_CREDIT_PACKAGE_PURCHASE_BY_TIMESTAMP(
    P_START_AT TIMESTAMP DEFAULT NULL,
    P_END_AT TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "月份" VARCHAR(10),
    "組合包方案名稱" VARCHAR(50),
    "銷售數量" INTEGER,
    "銷售金額" NUMERIC(10,2)
) AS $$
DECLARE
    v_start_at TIMESTAMP;
    v_end_at TIMESTAMP;
BEGIN
-- 設定 v_start_at 和 v_end_at 的值
    v_start_at := COALESCE(P_START_AT, DATE_TRUNC('month', CURRENT_DATE));
    v_end_at := COALESCE(P_END_AT, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day');
RETURN QUERY
SELECT
    TO_CHAR(DATE_TRUNC('month', cpc.purchase_at), 'YYYY-MM')::VARCHAR(10) AS "月份",
    CPK.name AS "組合包方案名稱",
    COUNT(CPK.name)::INTEGER AS "銷售數量",
    SUM(CPK.price)::NUMERIC(10,2) AS "銷售金額"
FROM "CREDIT_PURCHASE" AS CPC
LEFT JOIN "CREDIT_PACKAGE" AS CPK ON CPK.id = CPC.credit_package_id
WHERE cpc.purchase_at BETWEEN v_start_at AND v_end_at
GROUP BY 月份, CPK.name
ORDER BY 月份;
END;
$$ LANGUAGE plpgsql;
-- 建立以使用者預約課程狀態的function
CREATE OR REPLACE FUNCTION REPORT_USER_COURSE_BOOKING_STATUS_BY_TIMESTAMP(
    P_START_AT TIMESTAMP DEFAULT NULL,
    P_END_AT TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "月份" VARCHAR(10),
    "會員名稱" VARCHAR(50),
    "預約狀態" VARCHAR(20),
    "次數" INTEGER
) AS $$
DECLARE
    v_start_at TIMESTAMP;
    v_end_at TIMESTAMP;
BEGIN
-- 設定 v_start_at 和 v_end_at 的值
    v_start_at := COALESCE(P_START_AT, DATE_TRUNC('month', CURRENT_DATE));
    v_end_at := COALESCE(P_END_AT, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day');
RETURN QUERY
SELECT
    TO_CHAR(DATE_TRUNC('month', CB.created_at), 'YYYY-MM')::VARCHAR(10) AS "月份",
    U.name AS "會員名稱",
    CB.Status AS "預約狀態",
    COUNT(CB.Status)::INTEGER AS "次數"
FROM "COURSE_BOOKING" AS CB
LEFT JOIN "USER" AS U ON U.id = CB.user_id
LEFT JOIN GET_REMAINING_CREDITS_BY_USER_EMAIL() AS F ON F.user_id = U.id
WHERE CB.created_at BETWEEN v_start_at AND v_end_at
GROUP BY "月份", U.id, CB.Status, F.remaining_credit
ORDER BY "月份";
END;
$$ LANGUAGE plpgsql;