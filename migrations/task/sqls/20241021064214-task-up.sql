
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
-- 3-1 新增：在`COACH`資料表新增三筆教練資料，資料需求如下：
    -- 1. 將用戶`李燕容`新增為教練，並且年資設定為2年（提示：使用`李燕容`的email ，取得 `李燕容` 的 `id` ）
    -- 2. 將用戶`肌肉棒子`新增為教練，並且年資設定為2年
    -- 3. 將用戶`Q太郎`新增為教練，並且年資設定為2年

-- 3-2. 新增：承1，為三名教練新增專長資料至 `COACH_LINK_SKILL` ，資料需求如下：
    -- 1. 所有教練都有 `重訓` 專長
    -- 2. 教練`肌肉棒子` 需要有 `瑜伽` 專長
    -- 3. 教練`Q太郎` 需要有 `有氧運動` 與 `復健訓練` 專長

-- 3-3 修改：更新教練的經驗年數，資料需求如下：
    -- 1. 教練`肌肉棒子` 的經驗年數為3年
    -- 2. 教練`Q太郎` 的經驗年數為5年

-- 3-4 刪除：新增一個專長 空中瑜伽 至 SKILL 資料表，之後刪除此專長。


--  ████████  █████   █    █   █ 
--    █ █   ██    █  █     █   █ 
--    █ █████ ███ ███      █████ 
--    █ █   █    ██  █         █ 
--    █ █   █████ █   █        █ 
-- ===================== ==================== 
-- 4. 課程管理 COURSE 、組合包方案 CREDIT_PACKAGE

-- 4-1. 新增：在`COURSE` 新增一門課程，資料需求如下：
    -- 1. 教練設定為用戶`李燕容` 
    -- 2. 在課程專長 `skill_id` 上設定為「 `重訓` 」
    -- 3. 在課程名稱上，設定為「`重訓基礎課`」
    -- 4. 授課開始時間`start_at`設定為2024-11-25 14:00:00
    -- 5. 授課結束時間`end_at`設定為2024-11-25 16:00:00
    -- 6. 最大授課人數`max_participants` 設定為10
    -- 7. 授課連結設定`meeting_url`為 https://test-meeting.test.io


-- ████████  █████   █    █████ 
--   █ █   ██    █  █     █     
--   █ █████ ███ ███      ████  
--   █ █   █    ██  █         █ 
--   █ █   █████ █   █    ████  
-- ===================== ====================

-- 5. 客戶預約與授課 COURSE_BOOKING
-- 5-1. 新增：請在 `COURSE_BOOKING` 新增兩筆資料：
    -- 1. 第一筆：`王小明`預約 `李燕容` 的課程
        -- 1. 預約人設為`王小明`
        -- 2. 預約時間`booking_at` 設為2024-11-24 16:00:00
        -- 3. 狀態`status` 設定為即將授課
    -- 2. 新增： `好野人` 預約 `李燕容` 的課程
        -- 1. 預約人設為 `好野人`
        -- 2. 預約時間`booking_at` 設為2024-11-24 16:00:00
        -- 3. 狀態`status` 設定為即將授課

-- 5-2. 修改：`王小明`取消預約 `李燕容` 的課程，請在`COURSE_BOOKING`更新該筆預約資料：
    -- 1. 取消預約時間`cancelled_at` 設為2024-11-24 17:00:00
    -- 2. 狀態`status` 設定為課程已取消

-- 5-3. 新增：`王小明`再次預約 `李燕容`   的課程，請在`COURSE_BOOKING`新增一筆資料：
    -- 1. 預約人設為`王小明`
    -- 2. 預約時間`booking_at` 設為2024-11-24 17:10:25
    -- 3. 狀態`status` 設定為即將授課

-- 5-4. 查詢：取得王小明所有的預約紀錄，包含取消預約的紀錄

-- 5-5. 修改：`王小明` 現在已經加入直播室了，請在`COURSE_BOOKING`更新該筆預約資料（請注意，不要更新到已經取消的紀錄）：
    -- 1. 請在該筆預約記錄他的加入直播室時間 `join_at` 設為2024-11-25 14:01:59
    -- 2. 狀態`status` 設定為上課中

-- 5-6. 查詢：計算用戶王小明的購買堂數，顯示須包含以下欄位： user_id , total。 (需使用到 SUM 函式與 Group By)

-- 5-7. 查詢：計算用戶王小明的已使用堂數，顯示須包含以下欄位： user_id , total。 (需使用到 Count 函式與 Group By)

-- 5-8. [挑戰題] 查詢：請在一次查詢中，計算用戶王小明的剩餘可用堂數，顯示須包含以下欄位： user_id , remaining_credit
    -- 提示：
    -- select ("CREDIT_PURCHASE".total_credit - "COURSE_BOOKING".used_credit) as remaining_credit, ...
    -- from ( 用戶王小明的購買堂數 ) as "CREDIT_PURCHASE"
    -- inner join ( 用戶王小明的已使用堂數) as "COURSE_BOOKING"
    -- on "COURSE_BOOKING".user_id = "CREDIT_PURCHASE".user_id;


-- ████████  █████   █     ███  
--   █ █   ██    █  █     █     
--   █ █████ ███ ███      ████  
--   █ █   █    ██  █     █   █ 
--   █ █   █████ █   █     ███  
-- ===================== ====================
-- 6. 後台報表
-- 6-1 查詢：查詢專長為重訓的教練，並按經驗年數排序，由資深到資淺（需使用 inner join 與 order by 語法)
-- 顯示須包含以下欄位： 教練名稱 , 經驗年數, 專長名稱

-- 6-2 查詢：查詢每種專長的教練數量，並只列出教練數量最多的專長（需使用 group by, inner join 與 order by 與 limit 語法）
-- 顯示須包含以下欄位： 專長名稱, coach_total

-- 6-3. 查詢：計算 11 月份組合包方案的銷售數量
-- 顯示須包含以下欄位： 組合包方案名稱, 銷售數量

-- 6-4. 查詢：計算 11 月份總營收（使用 purchase_at 欄位統計）
-- 顯示須包含以下欄位： 總營收

-- 6-5. 查詢：計算 11 月份有預約課程的會員人數（需使用 Distinct，並用 created_at 和 status 欄位統計）
-- 顯示須包含以下欄位： 預約會員人數
