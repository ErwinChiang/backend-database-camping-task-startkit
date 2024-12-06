-- Task1
-- 建立新增使用者的 SP
CREATE OR REPLACE PROCEDURE ADD_USER_WITH_EMAIL_CHECK(
    IN P_NAME VARCHAR(50),
    IN P_EMAIL VARCHAR(320),
    IN P_ROLE VARCHAR(20),
    IN P_CREATED_AT TIMESTAMP DEFAULT (CURRENT_TIMESTAMP),
    IN P_UPDATED_AT TIMESTAMP DEFAULT (CURRENT_TIMESTAMP)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 檢查 email 格式是否正確
    IF LOWER(P_EMAIL) !~ '^[a-zA-Z0-9.!#$%&''''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$' THEN
        RAISE EXCEPTION 'EMail 格式不正確: %', P_EMAIL;
    END IF;
    
    -- 檢查 email 是否已存在
    IF EXISTS (SELECT 1 FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL)) THEN
        RAISE NOTICE '使用者已存在: %', P_EMAIL;
    ELSE
        -- 插入新使用者資料
        INSERT INTO "USER" (name, email, role, created_at, updated_at)
        VALUES (P_NAME, P_EMAIL, P_ROLE, P_CREATED_AT, P_UPDATED_AT);
    END IF;
END;
$$;
-- 變更使用者資料的 SP - 以 email 判斷
CREATE OR REPLACE PROCEDURE UPDATE_USER_BY_EMAIL(
    IN P_EMAIL VARCHAR(320),
    IN P_NAME VARCHAR(50) DEFAULT NULL,
    IN P_ROLE VARCHAR(20) DEFAULT NULL,
    IN P_UPDATED_AT TIMESTAMP DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 檢查 email 格式是否正確
    IF LOWER(P_EMAIL) !~ '^[a-zA-Z0-9.!#$%&''''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$' THEN
        RAISE EXCEPTION 'EMail 格式不正確: %', P_EMAIL;
    END IF;
    
    -- 檢查 email 是否存在
    IF EXISTS (SELECT 1 FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL)) THEN
        -- 使用 CASE WHEN 語句來更新欄位
        UPDATE "USER"
        SET name = COALESCE(P_NAME, name),
            role = COALESCE(P_ROLE, role),
            updated_at = COALESCE(P_UPDATED_AT, CURRENT_TIMESTAMP)
        WHERE LOWER(email) = LOWER(P_EMAIL);
        
        RAISE NOTICE '已更新使用者 % 姓名:% 角色:%.', P_EMAIL, COALESCE(P_NAME, '未變更'), COALESCE(P_ROLE, '未變更');
    ELSE
        RAISE NOTICE '使用者 % 不存在.', P_EMAIL;
    END IF;
END;
$$;
-- 刪除使用者資料的 SP - 以 email 判斷
CREATE OR REPLACE PROCEDURE DELETE_USER_BY_EMAIL(
    IN P_EMAIL VARCHAR(320)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 檢查 email 是否存在
    IF EXISTS (SELECT 1 FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL)) THEN
        -- 使用 email 判斷是否有需要刪除的資料
        DELETE FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL);
        RAISE NOTICE '已刪除使用者 % ', P_EMAIL;
    ELSE
        RAISE NOTICE '使用者 % 不存在.', P_EMAIL;
    END IF;
END;
$$;

--Task2
-- 建立新增課程的 SP
CREATE OR REPLACE PROCEDURE ADD_CREDIT_PACKAGE(
    IN P_NAME VARCHAR(50),
    IN P_PRICE NUMERIC(10,2),
    IN P_CREDIT_AMOUNT INTEGER,
    IN P_CREATED_AT TIMESTAMP DEFAULT (CURRENT_TIMESTAMP)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 檢查課程是否已存在
    IF EXISTS (SELECT 1 FROM "CREDIT_PACKAGE" WHERE "name" = P_NAME) THEN
        RAISE NOTICE '課程已存在: %', P_NAME;
    ELSE
        -- 插入新的課程
        INSERT INTO "CREDIT_PACKAGE" (name, credit_amount, price, created_at)
        VALUES (P_NAME, P_CREDIT_AMOUNT, P_PRICE, P_CREATED_AT);
        RAISE NOTICE '建立課程: % 堂數: %, 價格: %', P_NAME, P_CREDIT_AMOUNT, P_PRICE;
    END IF;
END;
$$;
-- 建立購買課程的 SP
CREATE OR REPLACE PROCEDURE ADD_CREDIT_PURCHASE_PACKAGE_BY_USER_NAME(
    IN P_USER_NAME VARCHAR(50),
    IN P_CREDIT_PACKAGE_NAME VARCHAR(50),
    IN P_PURCHASE_AT TIMESTAMP DEFAULT (CURRENT_TIMESTAMP)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id uuid;
    v_credit_package_id INTEGER;
    v_purchased_credits INTEGER;
    v_price_paid INTEGER;
BEGIN
    -- 判斷課堂是否存在
    IF EXISTS(SELECT name, COUNT(*) FROM "CREDIT_PACKAGE" WHERE name = P_CREDIT_PACKAGE_NAME GROUP BY name HAVING COUNT(*) !=1) THEN
        RAISE NOTICE '不存在課堂，或存在多個相同課堂: %, 請使用課堂編號查詢', P_CREDIT_PACKAGE_NAME;
        RETURN;
    END IF;
    
    IF EXISTS(SELECT name, COUNT(*) FROM "USER" WHERE name = P_USER_NAME GROUP BY name HAVING COUNT(*) != 1) THEN
        RAISE NOTICE '使用者名稱不存在，或存在多位相同使用者: %, 請使用 email 查詢', P_USER_NAME;
        RETURN;
    ELSE
        SELECT id INTO v_user_id FROM "USER" WHERE name = P_USER_NAME;
    END IF;
    
    -- 獲取 credit_package_id, purchased_credits 和 price_paid
    SELECT id, credit_amount, price INTO v_credit_package_id, v_purchased_credits, v_price_paid
    FROM "CREDIT_PACKAGE" WHERE name = P_CREDIT_PACKAGE_NAME;
    
    -- 新增購買資料
    INSERT INTO "CREDIT_PURCHASE" (user_id, credit_package_id, purchased_credits, price_paid, purchase_at)
    VALUES (v_user_id, v_credit_package_id, v_purchased_credits, v_price_paid, P_PURCHASE_AT);
    
    -- 顯示購買資訊
    RAISE NOTICE '%(%) => 已購買課堂: %(%) 金額: % 堂數: %', P_USER_NAME, v_user_id, P_CREDIT_PACKAGE_NAME, v_credit_package_id, v_price_paid, v_purchased_credits;
END;
$$;

--Task3
-- 更新角色為 COACH 的 SP
CREATE
OR REPLACE PROCEDURE UPDATE_COACH_BY_USER_EMAIL (
    IN P_EMAIL VARCHAR(50),
    IN P_EXPERIENCE_YEARS INTEGER,
    IN P_DESCRIPTION TEXT,
    IN P_PROFILE_IMAGE_URL VARCHAR(2048)
) LANGUAGE PLPGSQL AS $$
DECLARE
    v_user_id uuid;
    v_user_name varchar(50);
BEGIN
    -- 檢查 email 是否存在
    IF EXISTS (SELECT 1 FROM "USER" WHERE LOWER(email) = LOWER(p_email)) THEN
        -- 取得user_id
        SELECT id,name INTO v_user_id, v_user_name FROM "USER" WHERE LOWER(email) = LOWER(p_email);
        
        -- 更新USER.role 為 COACH
        UPDATE "USER"
        SET role = 'COACH'
        WHERE LOWER(email) = LOWER(p_email);
        RAISE NOTICE '已更新使用者 %(%) 為COACH.', p_email, v_user_name;
    ELSE
        RAISE NOTICE '使用者 % 不存在.', p_email;
        RETURN;
    END IF;
    
    -- 增加COACH關聯紀錄
    IF EXISTS (SELECT 1 FROM "COACH" WHERE user_id = v_user_id) THEN
        RAISE NOTICE '已存在教練資料 %(% - %) .', v_user_id, p_email, v_user_id;
        UPDATE "COACH"
        SET experience_years = COALESCE(p_experience_years, 0),
            description = COALESCE(p_description, '這傢伙沒有什麼值得介紹的'),
            profile_image_url = COALESCE(p_profile_image_url, '這傢伙見不得人'),
            updated_at = (CURRENT_TIMESTAMP)
        WHERE user_id = v_user_id;
    ELSE
        INSERT INTO "COACH" (user_id, experience_years, description, profile_image_url)
        VALUES (v_user_id, COALESCE(p_experience_years, 0), COALESCE(p_description, '這傢伙沒有什麼值得介紹的'), COALESCE(p_profile_image_url, '這傢伙見不得人'));
    END IF;
    
    RAISE NOTICE '教練資料=> 姓名: %(%) 年資: % 介紹: % 頭像連結: %.', v_user_name, p_email, COALESCE(p_experience_years, 0), COALESCE(p_description, '這傢伙沒有什麼值得介紹的'), COALESCE(p_profile_image_url, '這傢伙見不得人');
END;
$$;

-- 更新 COACH 的技能
CREATE
OR REPLACE PROCEDURE UPDATE_COACH_SKILLS_BY_USER_EMAIL (
    IN P_EMAIL VARCHAR(50),
    IN P_SKILL_NAME VARCHAR(50)
) LANGUAGE PLPGSQL AS $$
DECLARE
    v_coach_id uuid;
    v_user_name varchar(50);
    v_skill_id uuid;
BEGIN
    -- 檢查 ROLE 為教練的email 是否存在
    IF EXISTS (SELECT 1 FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL) AND role = 'COACH') THEN
        -- 取得教練id 與 教練姓名
        SELECT
            "COACH".id AS COACH_ID,
            "USER".name AS USER_NAME
        INTO v_coach_id, v_user_name
        FROM "USER"
        LEFT JOIN "COACH" ON "COACH".user_id = "USER".id AND "USER".role = 'COACH'
        WHERE LOWER("USER".email) = LOWER(P_EMAIL);
        
        --RAISE NOTICE '教練: % (%)', v_user_name,P_EMAIL;
    ELSE
        RAISE NOTICE '教練: % 不存在.', P_EMAIL;
        RETURN;
    END IF;
    
    --檢查SKILL_NAME 是否存在
    IF EXISTS (SELECT 1 FROM "SKILL" WHERE LOWER(name) = LOWER(P_SKILL_NAME)) THEN
        SELECT "id" INTO v_skill_id FROM "SKILL" WHERE LOWER(name) = LOWER(P_SKILL_NAME);
    ELSE
        RAISE NOTICE '技能: % 不存在.', P_SKILL_NAME;
        RETURN;
    END IF;
    
    -- 檢查 該教練是否已擁有該技能
    IF EXISTS (SELECT 1 FROM "COACH_LINK_SKILL"
               LEFT JOIN "SKILL" ON "COACH_LINK_SKILL".skill_id = "SKILL".id
               WHERE "COACH_LINK_SKILL".coach_id = v_coach_id AND "SKILL".name = P_SKILL_NAME) THEN
        --該教練已擁有該技能
        RAISE NOTICE '教練: % (%) 已存在技能: %', v_user_name, P_EMAIL, P_SKILL_NAME;
        RETURN;
    ELSE
        --增加教練的技能
        INSERT INTO "COACH_LINK_SKILL" (coach_id, skill_id) VALUES (v_coach_id, v_skill_id);
        RAISE NOTICE '教練: % (%) 已新增技能: %', v_user_name, P_EMAIL, P_SKILL_NAME;
    END IF;
END;
$$;

-- 新增技能
CREATE
OR REPLACE PROCEDURE ADD_SKILL_BY_NAME (IN P_SKILL_NAME VARCHAR(50)) LANGUAGE PLPGSQL AS $$
BEGIN
    --檢查SKILL_NAME 是否存在
    IF EXISTS (SELECT 1 FROM "SKILL" WHERE LOWER(name) = LOWER(P_SKILL_NAME)) THEN
        RAISE NOTICE '技能: % 已存在', P_SKILL_NAME;
        RETURN;
    ELSE
        --技能不存在，新增技能
        INSERT INTO "SKILL" (name) VALUES (P_SKILL_NAME);
        RAISE NOTICE '已新增技能: %', P_SKILL_NAME;
    END IF;
END;
$$;

-- 刪除技能
CREATE
OR REPLACE PROCEDURE DELETE_SKILL_BY_NAME (IN P_SKILL_NAME VARCHAR(50)) LANGUAGE PLPGSQL AS $$
DECLARE
    v_skill_id uuid;
BEGIN
    --檢查SKILL_NAME 是否存在
    IF EXISTS (SELECT 1 FROM "SKILL" WHERE LOWER(name) = LOWER(P_SKILL_NAME)) THEN
        SELECT id INTO v_skill_id FROM "SKILL" WHERE LOWER(name) = LOWER(P_SKILL_NAME);
        RAISE NOTICE '將刪除技能: % (%)', P_SKILL_NAME, v_skill_id;
    ELSE
        RAISE NOTICE '不存在技能: %', P_SKILL_NAME;
        RETURN;
    END IF;
    
    --檢查技能是否存在關聯
    IF EXISTS (SELECT 1 FROM "COACH_LINK_SKILL" WHERE skill_id = v_skill_id) THEN
        DELETE FROM "COACH_LINK_SKILL" WHERE skill_id = v_skill_id;
        RAISE NOTICE '清除教練與技能關聯資料...';
    END IF;
    
    --刪除技能
    DELETE FROM "SKILL" WHERE LOWER(name) = LOWER(P_SKILL_NAME);
    RAISE NOTICE '已刪除技能: %', P_SKILL_NAME;
END;
$$;

--Task4
-- 增加課程的 SP
CREATE
OR REPLACE PROCEDURE ADD_COURSE_BY_COACH_EMAIL (
    IN P_EMAIL VARCHAR(50),
    IN P_SKILL_NAME VARCHAR(50),
    IN P_COURSE_NAME VARCHAR(100),
    IN P_COURSE_DESCRIPTION TEXT,
    IN P_START_AT TIMESTAMP,
    IN P_END_AT TIMESTAMP,
    IN P_MAX_PARTICIPANTS INTEGER,
    IN P_MEETING_URL VARCHAR(2048),
    IN P_INTERVAL_MINUTES INTEGER
) LANGUAGE PLPGSQL AS $$
DECLARE
    v_coach_id uuid;
    v_user_id uuid;
    v_coach_name varchar(50);
    v_skill_id uuid;
    v_interval interval;
BEGIN
    -- 將 P_INTERVAL_MINUTES 轉換為 INTERVAL 類型, 若為NULL 則為30
    v_interval := (COALESCE(P_INTERVAL_MINUTES,30) || ' minutes')::INTERVAL;
    
    -- 檢查 ROLE 為教練的email 是否存在
    IF EXISTS (SELECT 1 FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL) AND role = 'COACH') THEN
        -- 取得教練id 與 教練姓名
        SELECT
            "USER".id,
            "USER".name,
            "COACH".id
        INTO v_user_id, v_coach_name, v_coach_id
        FROM "USER"
        LEFT JOIN "COACH" ON "COACH".user_id = "USER".id AND "USER".role = 'COACH'
        WHERE LOWER("USER".email) = LOWER(P_EMAIL);
        RAISE NOTICE '教練: % (%)', v_coach_name,P_EMAIL;
    ELSE
        RAISE NOTICE '教練: % 不存在.', P_EMAIL;
        RETURN;
    END IF;
    
    --檢查SKILL_NAME 是否存在
    IF EXISTS (SELECT 1 FROM "SKILL" WHERE LOWER(name) = LOWER(P_SKILL_NAME)) THEN
        SELECT "id" INTO v_skill_id FROM "SKILL" WHERE LOWER(name) = LOWER(P_SKILL_NAME);
    ELSE
        RAISE NOTICE '技能: % 不存在.', P_SKILL_NAME;
        RETURN;
    END IF;
    
    -- 檢查教練是否擁有該技能
    IF EXISTS (SELECT 1 FROM "COACH_LINK_SKILL"
               LEFT JOIN "SKILL" ON "COACH_LINK_SKILL".skill_id = "SKILL".id
               WHERE "COACH_LINK_SKILL".coach_id = v_coach_id AND "SKILL".name = P_SKILL_NAME) THEN
        --該教練已擁有該技能
        RAISE NOTICE '教練: % (%) 已存在技能: %', v_coach_name, P_EMAIL, P_SKILL_NAME;
    ELSE
        --教練不會這個
        RAISE NOTICE '教練: % (%) 還沒學會: %，請教練取得相關技能', v_coach_name, P_EMAIL, P_SKILL_NAME;
        RETURN;
    END IF;
    
    -- 防止課程結束早於課程起始
    IF (P_START_AT + v_interval) > P_END_AT THEN
        RAISE NOTICE '開課時間不合理: 開始: % 結束: %', P_START_AT, P_END_AT;
        RETURN;
    END IF;
    
    -- 防血汗以及分身檢查, 同一教練在 START_AT 與 END_AT 的時間內是否有重疊的課程, 或間隔小於 P_INTERVAL_MINUTES 分鐘
    IF EXISTS (SELECT 1 FROM "COURSE"
               WHERE user_id = v_user_id
               AND ((P_START_AT BETWEEN start_at AND end_at + v_interval)
                    OR (P_END_AT BETWEEN start_at AND end_at + v_interval)
                    OR (start_at BETWEEN P_START_AT AND P_END_AT + v_interval)
                    OR (end_at BETWEEN P_START_AT AND P_END_AT + v_interval))) THEN
        RAISE NOTICE '太血汗了!!!! 教練: % (%)，該時段已安排課程或課程間距小於 % 分鐘', v_coach_name, P_EMAIL, COALESCE(P_INTERVAL_MINUTES,30);
        RETURN;
    END IF;
    
    -- 新增開課
    INSERT INTO "COURSE" (user_id, skill_id, name, description, start_at, end_at, max_participants, meeting_url)
    VALUES(v_user_id, v_skill_id, P_COURSE_NAME, P_COURSE_DESCRIPTION, P_START_AT, P_END_AT, P_MAX_PARTICIPANTS, P_MEETING_URL);
    RAISE NOTICE '新增課程: % (技能: %), 教練: %, 開始於: %, 結束於: %, 開班允許人數: %, 授課連結: %, 課程簡介: %', P_COURSE_NAME, P_SKILL_NAME, v_coach_name, P_START_AT, P_END_AT, P_MAX_PARTICIPANTS, P_MEETING_URL, P_COURSE_DESCRIPTION;
END;
$$;

--Task5
--增加預約課程的 SP
CREATE
OR REPLACE PROCEDURE ADD_COURSE_BOOKING_BY_USER_EMAIL (
    IN P_EMAIL VARCHAR(50),
    IN P_COACH_NAME VARCHAR(50),
    IN P_COURSE_NAME VARCHAR(100),
    IN P_COURSE_START_AT TIMESTAMP,
    IN P_BOOKING_AT TIMESTAMP
) LANGUAGE PLPGSQL AS $$
DECLARE
    v_user_id uuid;
    v_user_name varchar(50);
    v_course_id integer;
    v_course_name varchar(100);
BEGIN
    -- 檢查 該使用者EMAIL是否存在
    IF EXISTS (SELECT 1 FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL)) THEN
        -- 取得使用者id
        SELECT id, name INTO v_user_id, v_user_name FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL);
    ELSE
        RAISE NOTICE '不存在: %', P_EMAIL;
        RETURN;
    END IF;
    
    --檢查課程狀態
    IF (SELECT COUNT(1) FROM GET_COURSES_BY_COACH_NAME_AND_START_AT(P_COACH_NAME, P_COURSE_NAME, P_COURSE_START_AT)) > 1 THEN
        RAISE NOTICE '超過一門課，請增加條件。 教練: % 課程: % 預約時間: %', P_COACH_NAME, P_COURSE_NAME, P_BOOKING_AT;
        RETURN;
    END IF;
    
    --檢查是否存在開課
    IF EXISTS (SELECT 1 FROM GET_COURSES_BY_COACH_NAME_AND_START_AT(P_COACH_NAME, P_COURSE_NAME, P_COURSE_START_AT)) THEN
        SELECT course_id, course_name INTO v_course_id, v_course_name FROM GET_COURSES_BY_COACH_NAME_AND_START_AT(P_COACH_NAME, P_COURSE_NAME, P_COURSE_START_AT);
    ELSE
        RAISE NOTICE '無此課程, 教練: % 課程: % 預約時間: %', P_COACH_NAME, v_course_name, P_BOOKING_AT;
        RETURN;
    END IF;
    
    --檢查是否已預約
    IF EXISTS (SELECT 1 FROM "COURSE_BOOKING" WHERE user_id = v_user_id and course_id = v_course_id and booking_at IS NOT NULL and cancel_at IS NULL) THEN
        RAISE NOTICE '% => 該課程已預約, 教練: % 課程: % 課程時間: %', v_user_name, P_COACH_NAME, v_course_name, P_COURSE_START_AT;
        RETURN;
    END IF;
    
    -- 新增預約
    INSERT INTO "COURSE_BOOKING" (user_id, course_id, booking_at, status, join_at, leave_at, cancel_at, cancellation_reason)
    VALUES(v_user_id, v_course_id, P_BOOKING_AT, '即將授課', NULL, NULL, NULL, NULL);
    RAISE NOTICE '% => 預約課程成功: % 開始於: % 教練: % 預約成功時間: %',v_user_name, v_course_name, P_COURSE_START_AT, P_COACH_NAME, P_BOOKING_AT;
END;
$$;
-- 增加取消預約課程的 SP
CREATE
OR REPLACE PROCEDURE CANCEL_COURSE_BOOKING_BY_USER_EMAIL (
    IN P_EMAIL VARCHAR(50),
    IN P_COACH_NAME VARCHAR(50),
    IN P_COURSE_NAME VARCHAR(100),
    IN P_COURSE_START_AT TIMESTAMP,
    IN P_CANCEL_AT TIMESTAMP,
    IN P_CANCELLATION_REASON VARCHAR(255)
) LANGUAGE PLPGSQL AS $$
DECLARE
    v_user_id uuid;
    v_user_name varchar(50);
    v_course_id integer;
    v_course_name varchar(100);
BEGIN
    -- 檢查 該使用者EMAIL是否存在
    IF EXISTS (SELECT 1 FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL)) THEN
        -- 取得使用者id
        SELECT id, name INTO v_user_id, v_user_name FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL);
    ELSE
        RAISE NOTICE '不存在: %', P_EMAIL;
        RETURN;
    END IF;
    
    --檢查課程狀態
    IF (SELECT COUNT(1) FROM GET_COURSES_BY_COACH_NAME_AND_START_AT(P_COACH_NAME, P_COURSE_NAME, P_COURSE_START_AT)) > 1 THEN
        RAISE NOTICE '超過一門課，請增加條件。 教練: % 課程: % 預約時間: %', P_COACH_NAME, P_COURSE_NAME, P_BOOKING_AT;
        RETURN;
    END IF;
    
    --檢查是否存在開課
    IF EXISTS (SELECT 1 FROM GET_COURSES_BY_COACH_NAME_AND_START_AT(P_COACH_NAME, P_COURSE_NAME, P_COURSE_START_AT)) THEN
        SELECT course_id, course_name INTO v_course_id, v_course_name FROM GET_COURSES_BY_COACH_NAME_AND_START_AT(P_COACH_NAME, P_COURSE_NAME, P_COURSE_START_AT);
    ELSE
        RAISE NOTICE '無此課程, 教練: % 課程: % 預約時間: %', P_COACH_NAME, v_course_name, P_BOOKING_AT;
        RETURN;
    END IF;
    
    --檢查是否已預約
    IF NOT EXISTS (SELECT 1 FROM "COURSE_BOOKING" WHERE user_id = v_user_id and course_id = v_course_id and booking_at IS NOT NULL and cancel_at IS NULL) THEN
        RAISE NOTICE '% => 尚未預約課程, 教練: % 課程: % 課程時間: %', v_user_name, P_COACH_NAME, v_course_name, P_COURSE_START_AT;
        RETURN;
    END IF;
    
    -- 取消預約
    IF NOT EXISTS (SELECT 1 FROM "COURSE_BOOKING" WHERE user_id = v_user_id and course_id = v_course_id and booking_at IS NOT NULL AND status IN ('即將授課')) THEN
        RAISE NOTICE '沒有可以取消預約的課程';
        RETURN;
    END IF;
    
    UPDATE "COURSE_BOOKING"
    SET status = '課程已取消',
        cancel_at = P_CANCEL_AT,
        cancellation_reason = P_CANCELLATION_REASON
    WHERE user_id = v_user_id and course_id = v_course_id and booking_at IS NOT NULL AND status IN ('即將授課');
    RAISE NOTICE '% => 已取消預約: % 開始於: % 教練: % 取消時間: % 取消原因: %',v_user_name, v_course_name, P_COURSE_START_AT, P_COACH_NAME, P_CANCEL_AT, P_CANCELLATION_REASON;
END;
$$;
-- 增加進入課程的 SP
CREATE
OR REPLACE PROCEDURE JOIN_COURSE_BOOKING_BY_USER_EMAIL (
    IN P_EMAIL VARCHAR(50),
    IN P_COACH_NAME VARCHAR(50),
    IN P_COURSE_NAME VARCHAR(100),
    IN P_COURSE_START_AT TIMESTAMP,
    IN P_JOIN_AT TIMESTAMP
) LANGUAGE PLPGSQL AS $$
DECLARE
    v_user_id uuid;
    v_user_name varchar(50);
    v_course_id integer;
    v_course_name varchar(100);
    v_course_start_at timestamp;
    v_course_end_at timestamp;
BEGIN
    -- 檢查 該使用者EMAIL是否存在
    IF EXISTS (SELECT 1 FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL)) THEN
        -- 取得使用者id
        SELECT id, name INTO v_user_id, v_user_name FROM "USER" WHERE LOWER(email) = LOWER(P_EMAIL);
    ELSE
        RAISE NOTICE '不存在: %', P_EMAIL;
        RETURN;
    END IF;
    
    --檢查課程狀態
    IF (SELECT COUNT(1) FROM GET_COURSES_BY_COACH_NAME_AND_START_AT(P_COACH_NAME, P_COURSE_NAME, P_COURSE_START_AT)) > 1 THEN
        RAISE NOTICE '超過一門課，請增加條件。 教練: % 課程: % 預約時間: %', P_COACH_NAME, P_COURSE_NAME, P_BOOKING_AT;
        RETURN;
    END IF;
    
    --檢查是否存在開課
    IF EXISTS (SELECT 1 FROM GET_COURSES_BY_COACH_NAME_AND_START_AT(P_COACH_NAME, P_COURSE_NAME, P_COURSE_START_AT)) THEN
        SELECT course_id, course_name, start_at, end_at
        INTO v_course_id, v_course_name, v_course_start_at, v_course_end_at
        FROM GET_COURSES_BY_COACH_NAME_AND_START_AT(P_COACH_NAME, P_COURSE_NAME, P_COURSE_START_AT);
    ELSE
        RAISE NOTICE '無此課程, 教練: % 課程: % 預約時間: %', P_COACH_NAME, v_course_name, P_BOOKING_AT;
        RETURN;
    END IF;
    
    --檢查是否已預約
    IF NOT EXISTS (SELECT 1 FROM "COURSE_BOOKING" WHERE user_id = v_user_id and course_id = v_course_id and booking_at IS NOT NULL and cancel_at IS NULL) THEN
        RAISE NOTICE '尚未預約課程, 教練: % 課程: % 課程時間: %', P_COACH_NAME, v_course_name, P_COURSE_START_AT;
        RETURN;
    END IF;
    
    -- 開課時間檢查
    IF NOT (P_JOIN_AT BETWEEN v_course_start_at AND v_course_end_at) THEN
        RAISE NOTICE '不是上課時間!!';
        RETURN;
    END IF;
    
    -- 遲到檢查
    IF ((P_JOIN_AT - P_COURSE_START_AT) > '30 minutes'::INTERVAL) THEN
        RAISE NOTICE '遲到 30 分鐘還想進來!??';
        RETURN;
    END IF;
    
    -- 加入課程
    UPDATE "COURSE_BOOKING"
    SET status = '上課中',
        join_at = P_JOIN_AT
    WHERE user_id = v_user_id and course_id = v_course_id
      and booking_at IS NOT NULL
      and cancel_at IS NULL
      and join_at IS NULL;
    RAISE NOTICE '% => 上課中: % 開始於: % 教練: %',v_user_name, P_JOIN_AT, P_COURSE_START_AT, P_COACH_NAME;
END;
$$;