-- Your answers here:
\c nerdery_challenge
-- 1
SELECT a.type, SUM(a.mount) 
FROM accounts a 
GROUP BY a.type;
-- 2
SELECT count(*) 
FROM(
    SELECT u.name, count(a.id) AS current_accounts 
    FROM users u 
    LEFT JOIN accounts a ON a.user_id = u.id AND a.type = 'CURRENT_ACCOUNT' 
    GROUP BY u.name 
    HAVING count(a.id) >= 2
    ) AS total_people;
-- 3
SELECT a.id, a.mount
FROM accounts a 
ORDER BY a.mount DESC 
LIMIT 5;
-- 4
SELECT
    u.name, 
    (
        sum(a.mount) +
        sum(
            CASE
                WHEN t.type = 'IN'  THEN  t.mount
                WHEN t.type = 'OUT' THEN (t.mount * -1)
                WHEN t.type = 'TRANSFER' AND t.account_FROM = a.id THEN (t.mount * -1)
                WHEN t.type = 'TRANSFER' AND t.account_to = a.id THEN t.mount
                else (t.mount * -1)
            END
        )
    ) AS total_amount
FROM users u 
LEFT JOIN accounts a ON a.user_id = u.id 
LEFT JOIN movements t ON t.account_FROM = a.id or t.account_to = a.id 
GROUP BY u.name
ORDER BY total_amount DESC
LIMIT 3;
-- 5
-- Function to calculate current amount FROM an account using only its ID
CREATE OR REPLACE FUNCTION get_current_balance(p_account_id UUID)
RETURNS FLOAT AS $$
DECLARE
    v_balance FLOAT;
BEGIN
        SELECT 
            (a.mount + 
                SUM(
                    case 
                        WHEN t.type = 'IN' or (t.type = 'TRANSFER' AND t.account_to = a.id) THEN t.mount
                        WHEN t.type = 'OUT' or (t.type = 'TRANSFER' AND t.account_FROM = a.id) THEN -t.mount
                        else 0
                    END
                )
            ) 
        INTO v_balance
        FROM accounts a 
        LEFT JOIN movements t ON a.id IN (t.account_FROM , t.account_to)
        WHERE a.id = p_account_id
        GROUP BY a.id , a.mount;
        IF v_balance IS NULL THEN
            SELECT mount INTO v_balance FROM accounts WHERE id = p_account_id;
        END IF;
        RETURN coalesce(v_balance, 0);
END;
$$ language plpgsql;

BEGIN;

DO $$
BEGIN
        IF get_current_balance('3b79e403-c788-495a-a8ca-86ad7643afaf') < 50.75 THEN
            RAISE EXCEPTION 'Insuf. current amount on account';
        END if;
        INSERT INTO movements(id , mount , account_FROM , account_to , type , created_at , updated_at)
        VALUES (gen_rANDom_uuid() , 50.75 , '3b79e403-c788-495a-a8ca-86ad7643afaf' , 'fd244313-36e5-4a17-a27c-f8265bc46590' , 'TRANSFER' , now() , now()); 
END $$;

DO $$
BEGIN
        IF get_current_balance('3b79e403-c788-495a-a8ca-86ad7643afaf') < 1823.56 THEN
            RAISE EXCEPTION 'Insuf. current amount on account';
        END IF;
        INSERT INTO movements(id , mount , account_FROM, type , created_at , updated_at)
        VALUES (gen_rANDom_uuid() , 1823.56, '3b79e403-c788-495a-a8ca-86ad7643afaf', 'OUT' , now() , now()); 
END $$;

COMMIT;
-- 6
SELECT m.*, u.name , u.last_name , u.email 
FROM movements m 
LEFT JOIN accounts a ON a.id in (m.account_FROM , m.account_to)
LEFT JOIN users u ON a.user_id = u.id
WHERE a.id = '3b79e403-c788-495a-a8ca-86ad7643afaf';
-- 7
SELECT u.name , u.email
FROM users u
LEFT JOIN accounts a ON a.user_id = u.id
GROUP BY u.id
ORDER BY sum(a.mount) DESC limit 1;
-- 8 
SELECT m.*, u.email, a.type , a.created_at 
FROM movements m 
INNER JOIN accounts a ON m.account_FROM = a.id or m.account_to = a.id 
INNER JOIN users u ON u.id = a.user_id 
WHERE u.email = 'Kaden.Gusikowski@gmail.com' 
ORDER BY a.type ASC, a.created_at DESC;