
-- ████████  █████   █     █ 
--   █ █   ██    █  █     ██ 
--   █ █████ ███ ███       █ 
--   █ █   █    ██  █      █ 
--   █ █   █████ █   █     █ 
-- ===================== ====================
-- 1. 用戶資料，資料表為 USER
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
-- 1. 新增：新增六筆用戶資料，資料如下：
--     1. 用戶名稱為`李燕容`，Email 為`lee2000@hexschooltest.io`，Role為`USER`
--     2. 用戶名稱為`王小明`，Email 為`wXlTq@hexschooltest.io`，Role為`USER`
--     3. 用戶名稱為`肌肉棒子`，Email 為`muscle@hexschooltest.io`，Role為`USER`
--     4. 用戶名稱為`好野人`，Email 為`richman@hexschooltest.io`，Role為`USER`
--     5. 用戶名稱為`Q太郎`，Email 為`starplatinum@hexschooltest.io`，Role為`USER`
--     6. 用戶名稱為 透明人，Email 為 opacity0@hexschooltest.io，Role 為 USER
CALL ADD_USER_WITH_EMAIL_CHECK('李燕容', 'lee2000@hexschooltest.io', 'USER');
CALL ADD_USER_WITH_EMAIL_CHECK('王小明', 'wXlTq@hexschooltest.io', 'USER');
CALL ADD_USER_WITH_EMAIL_CHECK('肌肉棒子', 'muscle@hexschooltest.io', 'USER');
CALL ADD_USER_WITH_EMAIL_CHECK('好野人', 'richman@hexschooltest.io', 'USER');
CALL ADD_USER_WITH_EMAIL_CHECK('Q太郎', 'starplatinum@hexschooltest.io', 'USER');
CALL ADD_USER_WITH_EMAIL_CHECK('透明人', 'opacity0@hexschooltest.io', 'USER');

-- 1-2 修改：用 Email 找到 李燕容、肌肉棒子、Q太郎，如果他的 Role 為 USER 將他的 Role 改為 COACH
CALL UPDATE_USER_BY_EMAIL('lee2000@hexschooltest.io', null, 'COACH');
CALL UPDATE_USER_BY_EMAIL('muscle@hexschooltest.io', null, 'COACH');
CALL UPDATE_USER_BY_EMAIL('starplatinum@hexschooltest.io', null, 'COACH');

-- 1-3 刪除：刪除USER 資料表中，用 Email 找到透明人，並刪除該筆資料
CALL DELETE_USER_BY_EMAIL('opacity0@hexschooltest.io');
-- 1-4 查詢：取得USER 資料表目前所有用戶數量（提示：使用count函式）
SELECT COUNT(*) AS 用戶數量 FROM "USER";
-- 1-5 查詢：取得 USER 資料表所有用戶資料，並列出前 3 筆（提示：使用limit語法）
SELECT * FROM "USER"
LIMIT 3;

--  ████████  █████   █    ████  
--    █ █   ██    █  █         █ 
--    █ █████ ███ ███       ███  
--    █ █   █    ██  █     █     
--    █ █   █████ █   █    █████ 
-- ===================== ====================
-- 2. 組合包方案 CREDIT_PACKAGE、客戶購買課程堂數 CREDIT_PURCHASE
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
-- 2-1. 新增：在`CREDIT_PACKAGE` 資料表新增三筆資料，資料需求如下：
    -- 1. 名稱為 `7 堂組合包方案`，價格為`1,400` 元，堂數為`7`
    -- 2. 名稱為`14 堂組合包方案`，價格為`2,520` 元，堂數為`14`
    -- 3. 名稱為 `21 堂組合包方案`，價格為`4,800` 元，堂數為`21`
CALL ADD_CREDIT_PACKAGE('7 堂組合包方案',1400::numeric, 7);
CALL ADD_CREDIT_PACKAGE('14 堂組合包方案',2520::numeric, 14);
CALL ADD_CREDIT_PACKAGE('21 堂組合包方案',4800::numeric, 21);
-- 2-2. 新增：在 `CREDIT_PURCHASE` 資料表，新增三筆資料：（請使用 name 欄位做子查詢）
    -- 1. `王小明` 購買 `14 堂組合包方案`
    -- 2. `王小明` 購買 `21 堂組合包方案`
    -- 3. `好野人` 購買 `14 堂組合包方案`
CALL ADD_CREDIT_PURCHASE_PACKAGE_by_user_name('王小明','14 堂組合包方案', '2024-01-01'::TIMESTAMP);
CALL ADD_CREDIT_PURCHASE_PACKAGE_by_user_name('王小明','21 堂組合包方案', '2024-02-01'::TIMESTAMP);
CALL ADD_CREDIT_PURCHASE_PACKAGE_by_user_name('好野人','14 堂組合包方案', '2024-09-01'::TIMESTAMP);

-- ████████  █████   █    ████   
--   █ █   ██    █  █         ██ 
--   █ █████ ███ ███       ███   
--   █ █   █    ██  █         ██ 
--   █ █   █████ █   █    ████   
-- ===================== ====================
-- 3. 教練資料 ，資料表為 COACH ,SKILL,COACH_LINK_SKILL
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
-- 3-1 新增：在`COACH`資料表新增三筆教練資料，資料需求如下：
    -- 1. 將用戶`李燕容`新增為教練，並且年資設定為2年（提示：使用`李燕容`的email ，取得 `李燕容` 的 `id` ）
    -- 2. 將用戶`肌肉棒子`新增為教練，並且年資設定為2年
    -- 3. 將用戶`Q太郎`新增為教練，並且年資設定為2年
CALL UPDATE_COACH_BY_USER_EMAIL ('lee2000@hexschooltest.io', 2, NULL, NULL);
CALL UPDATE_COACH_BY_USER_EMAIL ('muscle@hexschooltest.io', 2, NULL, NULL);
CALL UPDATE_COACH_BY_USER_EMAIL ('starplatinum@hexschooltest.io', 2, NULL, NULL);
-- 3-2. 新增：承1，為三名教練新增專長資料至 `COACH_LINK_SKILL` ，資料需求如下：
    -- 1. 所有教練都有 `重訓` 專長
    -- 2. 教練`肌肉棒子` 需要有 `瑜伽` 專長
    -- 3. 教練`Q太郎` 需要有 `有氧運動` 與 `復健訓練` 專長
CALL UPDATE_COACH_SKILLS_BY_USER_EMAIL ('lee2000@hexschooltest.io', '重訓');
CALL UPDATE_COACH_SKILLS_BY_USER_EMAIL ('lee2000@hexschooltest.io', '瑜伽');

CALL UPDATE_COACH_SKILLS_BY_USER_EMAIL ('muscle@hexschooltest.io', '重訓');
CALL UPDATE_COACH_SKILLS_BY_USER_EMAIL ('muscle@hexschooltest.io', '瑜伽');

CALL UPDATE_COACH_SKILLS_BY_USER_EMAIL ('starplatinum@hexschooltest.io', '重訓');
CALL UPDATE_COACH_SKILLS_BY_USER_EMAIL ('starplatinum@hexschooltest.io', '有氧運動');
CALL UPDATE_COACH_SKILLS_BY_USER_EMAIL ('starplatinum@hexschooltest.io', '復健訓練');
-- 3-3 修改：更新教練的經驗年數，資料需求如下：
    -- 1. 教練`肌肉棒子` 的經驗年數為3年
    -- 2. 教練`Q太郎` 的經驗年數為5年
CALL UPDATE_COACH_BY_USER_EMAIL ('muscle@hexschooltest.io', 3, NULL, NULL);
CALL UPDATE_COACH_BY_USER_EMAIL ('starplatinum@hexschooltest.io', 5, NULL, NULL);

-- 3-4 刪除：新增一個專長 空中瑜伽 至 SKILL 資料表，之後刪除此專長。
CALL ADD_SKILL_BY_NAME ('空中瑜伽');
CALL DELETE_SKILL_BY_NAME ('空中瑜伽');

--  ████████  █████   █    █   █ 
--    █ █   ██    █  █     █   █ 
--    █ █████ ███ ███      █████ 
--    █ █   █    ██  █         █ 
--    █ █   █████ █   █        █ 
-- ===================== ==================== 
-- 4. 課程管理 COURSE 、組合包方案 CREDIT_PACKAGE
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
-- 4-1. 新增：在`COURSE` 新增一門課程，資料需求如下：
    -- 1. 教練設定為用戶`李燕容` 
    -- 2. 在課程專長 `skill_id` 上設定為「 `重訓` 」
    -- 3. 在課程名稱上，設定為「`重訓基礎課`」
    -- 4. 授課開始時間`start_at`設定為2024-11-25 14:00:00
    -- 5. 授課結束時間`end_at`設定為2024-11-25 16:00:00
    -- 6. 最大授課人數`max_participants` 設定為10
    -- 7. 授課連結設定`meeting_url`為 https://test-meeting.test.io
CALL ADD_COURSE_BY_COACH_EMAIL('lee2000@hexschooltest.io', '重訓', '重訓基礎課', NULL, '2024-11-25 14:00:00', '2024-11-25 16:00:00', 10, 'https://test-meeting.test.io', 30);
CALL ADD_COURSE_BY_COACH_EMAIL('lee2000@hexschooltest.io', '重訓', '重訓基礎課', NULL, '2024-11-26 14:00:00', '2024-11-26 16:00:00', 10, 'https://test-meeting.test.io', 30);

-- ████████  █████   █    █████ 
--   █ █   ██    █  █     █     
--   █ █████ ███ ███      ████  
--   █ █   █    ██  █         █ 
--   █ █   █████ █   █    ████  
-- ===================== ====================

-- 5. 客戶預約與授課 COURSE_BOOKING
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
    IF EXISTS (SELECT 1 FROM "COURSE_BOOKING" WHERE user_id = v_user_id and course_id = v_course_id and booking_at IS NOT NULL and cancelled_at IS NULL) THEN
        RAISE NOTICE '% => 該課程已預約, 教練: % 課程: % 課程時間: %', v_user_name, P_COACH_NAME, v_course_name, P_COURSE_START_AT;
        RETURN;
    END IF;
    
    -- 新增預約
    INSERT INTO "COURSE_BOOKING" (user_id, course_id, booking_at, status, join_at, leave_at, cancelled_at, cancellation_reason)
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
    IN P_cancelled_at TIMESTAMP,
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
    IF NOT EXISTS (SELECT 1 FROM "COURSE_BOOKING" WHERE user_id = v_user_id and course_id = v_course_id and booking_at IS NOT NULL and cancelled_at IS NULL) THEN
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
        cancelled_at = P_cancelled_at,
        cancellation_reason = P_CANCELLATION_REASON
    WHERE user_id = v_user_id and course_id = v_course_id and booking_at IS NOT NULL AND status IN ('即將授課');
    RAISE NOTICE '% => 已取消預約: % 開始於: % 教練: % 取消時間: % 取消原因: %',v_user_name, v_course_name, P_COURSE_START_AT, P_COACH_NAME, P_cancelled_at, P_CANCELLATION_REASON;
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
    IF NOT EXISTS (SELECT 1 FROM "COURSE_BOOKING" WHERE user_id = v_user_id and course_id = v_course_id and booking_at IS NOT NULL and cancelled_at IS NULL) THEN
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
      and cancelled_at IS NULL
      and join_at IS NULL;
    RAISE NOTICE '% => 上課中: % 開始於: % 教練: %',v_user_name, P_JOIN_AT, P_COURSE_START_AT, P_COACH_NAME;
END;
$$;
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
    cancelled_at TIMESTAMP,
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
    "COURSE_BOOKING".cancelled_at,
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
AND "COURSE_BOOKING".cancelled_at IS NULL
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
-- 5-1. 新增：請在 `COURSE_BOOKING` 新增兩筆資料：
    -- 1. 第一筆：`王小明`預約 `李燕容` 的課程
        -- 1. 預約人設為`王小明`
        -- 2. 預約時間`booking_at` 設為2024-11-24 16:00:00
        -- 3. 狀態`status` 設定為即將授課
    -- 2. 新增： `好野人` 預約 `李燕容` 的課程
        -- 1. 預約人設為 `好野人`
        -- 2. 預約時間`booking_at` 設為2024-11-24 16:00:00
        -- 3. 狀態`status` 設定為即將授課
--王小明 booking
CALL ADD_COURSE_BOOKING_BY_USER_EMAIL('wXlTq@hexschooltest.io', '李燕容', '重訓基礎課', '2024-11-25 14:00:00'::timestamp, '2024-11-24 16:00:00'::timestamp);
--好野人
CALL ADD_COURSE_BOOKING_BY_USER_EMAIL('richman@hexschooltest.io', '李燕容', '重訓基礎課', '2024-11-25 14:00:00'::timestamp, '2024-11-24 16:00:00'::timestamp);
-- 5-2. 修改：`王小明`取消預約 `李燕容` 的課程，請在`COURSE_BOOKING`更新該筆預約資料：
    -- 1. 取消預約時間`cancelled_at` 設為2024-11-24 17:00:00
    -- 2. 狀態`status` 設定為課程已取消
--王小明很皮，明天肚子痛，取消預約
CALL CANCEL_COURSE_BOOKING_BY_USER_EMAIL('wXlTq@hexschooltest.io', '李燕容', '重訓基礎課', '2024-11-25 14:00:00'::timestamp, '2024-11-24 17:00:00'::timestamp,'王小明很皮，明天會肚子痛');

-- 5-3. 新增：`王小明`再次預約 `李燕容`   的課程，請在`COURSE_BOOKING`新增一筆資料：
    -- 1. 預約人設為`王小明`
    -- 2. 預約時間`booking_at` 設為2024-11-24 17:10:25
    -- 3. 狀態`status` 設定為即將授課
--王小明很皮，忽然明天又不會肚子痛了
CALL ADD_COURSE_BOOKING_BY_USER_EMAIL('wXlTq@hexschooltest.io', '李燕容', '重訓基礎課', '2024-11-25 14:00:00'::timestamp, '2024-11-24 17:10:25'::timestamp);

-- 5-4. 查詢：取得王小明所有的預約紀錄，包含取消預約的紀錄
SELECT * FROM GET_COURSES_BOOKING_BY_USER_EMAIL('wXlTq@hexschooltest.io');

-- 5-5. 修改：`王小明` 現在已經加入直播室了，請在`COURSE_BOOKING`更新該筆預約資料（請注意，不要更新到已經取消的紀錄）：
    -- 1. 請在該筆預約記錄他的加入直播室時間 `join_at` 設為2024-11-25 14:01:59
    -- 2. 狀態`status` 設定為上課中
CALL JOIN_COURSE_BOOKING_BY_USER_EMAIL('wXlTq@hexschooltest.io', '李燕容', '重訓基礎課', '2024-11-25 14:00:00'::timestamp, '2024-11-25 14:01:59'::timestamp);

-- 5-6. 查詢：計算用戶王小明的購買堂數，顯示須包含以下欄位： user_id , total。 (需使用到 SUM 函式與 Group By)
SELECT * FROM GET_PURCHASED_CREDITS_BY_USER_EMAIL('wXlTq@hexschooltest.io');

-- 5-7. 查詢：計算用戶王小明的已使用堂數，顯示須包含以下欄位： user_id , total。 (需使用到 Count 函式與 Group By)
SELECT * FROM GET_USED_CREDITS_BY_USER_EMAIL('wXlTq@hexschooltest.io');

-- 5-8. [挑戰題] 查詢：請在一次查詢中，計算用戶王小明的剩餘可用堂數，顯示須包含以下欄位： user_id , remaining_credit
    -- 提示：
    -- select ("CREDIT_PURCHASE".total_credit - "COURSE_BOOKING".used_credit) as remaining_credit, ...
    -- from ( 用戶王小明的購買堂數 ) as "CREDIT_PURCHASE"
    -- inner join ( 用戶王小明的已使用堂數) as "COURSE_BOOKING"
    -- on "COURSE_BOOKING".user_id = "CREDIT_PURCHASE".user_id;
SELECT * FROM GET_REMAINING_CREDITS_BY_USER_EMAIL('wXlTq@hexschooltest.io');

-- ████████  █████   █     ███  
--   █ █   ██    █  █     █     
--   █ █████ ███ ███      ████  
--   █ █   █    ██  █     █   █ 
--   █ █   █████ █   █     ███  
-- ===================== ====================
-- 6. 後台報表
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
-- 6-1 查詢：查詢專長為重訓的教練，並按經驗年數排序，由資深到資淺（需使用 inner join 與 order by 語法)
-- 顯示須包含以下欄位： 教練名稱 , 經驗年數, 專長名稱
SELECT * FROM GET_COACH_ORDER_BY_EXPERIENCE_YEARS();
-- 6-2 查詢：查詢每種專長的教練數量，並只列出教練數量最多的專長（需使用 group by, inner join 與 order by 與 limit 語法）
-- 顯示須包含以下欄位： 專長名稱, coach_total
SELECT * FROM GET_COACH_ORDER_BY_EXPERIENCE_YEARS()
ORDER By "技能數量" DESC
LIMIT 1;
-- 6-3. 查詢：計算 11 月份組合包方案的銷售數量
-- 顯示須包含以下欄位： 組合包方案名稱, 銷售數量

--前面的購買日期已經是12月了, 乾脆拉了全年度
SELECT * FROM REPORT_CREDIT_PACKAGE_PURCHASE_BY_TIMESTAMP('2024-01-01', '2024-12-31');
-- 6-4. 查詢：計算 11 月份總營收（使用 purchase_at 欄位統計）
-- 顯示須包含以下欄位： 總營收
SELECT
	"月份",
	SUM("銷售數量") AS "總銷售數量",
	SUM("銷售金額") AS "總營收"
FROM REPORT_CREDIT_PACKAGE_PURCHASE_BY_TIMESTAMP('2024-01-01', '2024-12-31')
GROUP BY 月份
ORDER BY 月份;

-- 6-5. 查詢：計算 11 月份有預約課程的會員人數（需使用 Distinct，並用 created_at 和 status 欄位統計）
-- 顯示須包含以下欄位： 預約會員人數
SELECT
	COUNT(DISTINCT "會員名稱")::INTEGER AS "預約會員人數"
FROM REPORT_USER_COURSE_BOOKING_STATUS_BY_TIMESTAMP('2024-11-01','2024-12-31');

-- 查詢全年度的課程預約狀況
SELECT * FROM REPORT_USER_COURSE_BOOKING_STATUS_BY_TIMESTAMP('2024-01-01','2024-12-31');

-- 查詢當月的課程預約狀況
SELECT * FROM REPORT_USER_COURSE_BOOKING_STATUS_BY_TIMESTAMP();