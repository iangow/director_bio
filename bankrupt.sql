SELECT company_fkey::integer AS cik, name, bank_key, bankruptcy_type, bank_begin_date, 
    bank_end_date, a.file_date, a.best_edgar_ticker
FROM audit.bankrupt AS a
LEFT JOIN audit.namesbankrupt AS b
    USING (company_fkey, bank_begin_date)
WHERE bank_key IN (1500, 971, 1146, 7, 86, 228, 794, 961, 505, 1083)
