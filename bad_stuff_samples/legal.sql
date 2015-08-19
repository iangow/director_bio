WITH auditlegal AS (
    SELECT *
    FROM audit.feed14case
    INNER JOIN audit.feed14party
    USING (legal_case_key)
    WHERE legal_case_key IN (192, 315, 358, 395, 474, 4394, 4381, 4259, 2227, 2143)
    AND legal_party_key IN (1511, 2351, 2712, 2982, 3515, 29546, 29421, 28366, 13074, 12796)
    AND company_fkey IS NOT NULL)
SELECT legal_case_key, company_fkey AS cik, legal_party_key, name_text, -- title, 
    case_start_date, case_end_date, exp_start_date, exp_end_date
FROM auditlegal
ORDER BY legal_case_key;
