WITH 

res_categories AS (
    SELECT res_notify_key, array_agg(res_category_fkey) AS res_acc_res_fkeys,
        array_agg(res_category_title) AS res_acc_res_title_list
    FROM audit.feed09tocat
    INNER JOIN audit.feed09cat
    USING (res_category_fkey)
    WHERE res_field='res_accounting'
    GROUP BY res_notify_key, res_field)
    
SELECT company_fkey::integer AS cik, name, file_date,
    res_notify_key, res_begin_date, res_end_date, res_aud_letter, res_sec_invest,
    best_edgar_ticker, res_acc_res_fkeys
FROM audit.feed09filing AS a
LEFT JOIN res_categories
USING (res_notify_key)
INNER JOIN audit.namesauditnonreli
USING (file_date, company_fkey)
WHERE res_sec_invest 
--         AND company_fkey::integer IN 
--             (5272, 60086, 67472, 84129, 216275, 812011, 821130, 877890, 
--              896841, 921582, 1001082, 1067701, 1085734, 1105705, 1229206, 
--              1124887, 1037949, 912093, 807707, 28823)
--         AND file_date IN 
--             ('2005-05-01', '2005-05-03', '2006-08-02', '1999-10-11', '2004-02-18', 
--             '2007-06-08', '2005-11-10', '2005-03-07', '2013-03-19', '2007-10-05', 
--             '2004-03-11', '2005-03-14', '2006-03-09', '2002-10-23', '2005-02-11', 
--             '2004-01-18', '2002-07-28', '2001-09-19', '2003-03-14', '2007-08-09')

