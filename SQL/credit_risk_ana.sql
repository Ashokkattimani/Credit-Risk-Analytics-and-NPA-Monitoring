/*create database credit_risk_analysis
use credit_risk_analysis
select * from loan_portfolio$

select count(*) from loan_portfolio$


USE Credit_Risk_Analytics;
GO
*/

-- Credit Risk Profiling & NPA Monitoring
-- SQL Dialect: Microsoft SQL Server 2022
-- Table: Loan_Portfolio


-- 1. PORTFOLIO KPIs

SELECT
    COUNT(*) AS total_loans,
    SUM(loan_amount) AS total_exposure,
    AVG(pd_estimate) AS avg_pd,
    AVG(CAST(npa_flag AS DECIMAL(10,4))) AS npa_ratio,
    AVG(CAST(default_flag AS DECIMAL(10,4))) AS default_rate
FROM loan_portfolio$;


-- 2. NPA RATIO BY REGION

SELECT
    region,
    COUNT(*) AS loans,
    SUM(loan_amount) AS exposure,
    ROUND(
        100.0 * AVG(CAST(npa_flag AS DECIMAL(10,4))), 2
    ) AS npa_ratio_pct
FROM Loan_Portfolio$
GROUP BY region
ORDER BY npa_ratio_pct DESC;


-- 3. NPA RATIO BY RISK BAND
SELECT
    risk_band,
    COUNT(*) AS loans,
    ROUND(
        100.0 * AVG(CAST(npa_flag AS DECIMAL(10,4))), 2
    ) AS npa_ratio_pct,
    ROUND(AVG(CAST(pd_estimate AS DECIMAL(10,4))), 4) AS avg_pd
FROM Loan_Portfolio$
GROUP BY risk_band
ORDER BY avg_pd DESC;


-- 4. HIGH-RISK EXPOSURE

SELECT
    risk_band,
    SUM(loan_amount) AS exposure,
    COUNT(*) AS accounts
FROM Loan_Portfolio$
WHERE risk_band IN ('High', 'Very High')
GROUP BY risk_band
ORDER BY exposure DESC;


-- 5. EARLY-WARNING LOANS: DPD 30-89

SELECT
    loan_id,
    risk_band,
    credit_score,
    dti_pct,
    ltv_pct,
    prior_delinquencies,
    days_past_due,
    loan_amount
FROM Loan_Portfolio$
WHERE days_past_due BETWEEN 30 AND 89
ORDER BY days_past_due DESC, pd_estimate DESC;


-- 6. SEVERE DELINQUENCY / NPA ACCOUNTS
SELECT
    loan_id,
    days_past_due,
    loan_amount,
    pd_estimate,
    risk_band,
    credit_score,
    dti_pct,
    ltv_pct
FROM loan_portfolio$
WHERE days_past_due >= 90
ORDER BY loan_amount DESC;


-- 7. CREDIT SCORE BUCKETS

WITH CreditScoreBuckets AS
(
    SELECT
        CASE
            WHEN credit_score < 600 THEN '<600'
            WHEN credit_score < 650 THEN '600-649'
            WHEN credit_score < 700 THEN '650-699'
            WHEN credit_score < 750 THEN '700-749'
            ELSE '750+'
        END AS score_bucket,
        npa_flag,
        pd_estimate
    FROM loan_portfolio$
)
SELECT
    score_bucket,
    COUNT(*) AS loans,
    ROUND(
        100.0 * AVG(CAST(npa_flag AS DECIMAL(10,4))), 2
    ) AS npa_ratio_pct,
    ROUND(AVG(CAST(pd_estimate AS DECIMAL(10,4))), 4) AS avg_pd
FROM CreditScoreBuckets
GROUP BY score_bucket
ORDER BY score_bucket;


-- 8. DTI RISK SEGMENTATION

WITH DTIBuckets AS
(
    SELECT
        CASE
            WHEN dti_pct < 25 THEN '<25%'
            WHEN dti_pct < 40 THEN '25-39%'
            WHEN dti_pct < 55 THEN '40-54%'
            ELSE '55%+'
        END AS dti_bucket,
        default_flag,
        npa_flag
    FROM loan_portfolio$
)
SELECT
    dti_bucket,
    COUNT(*) AS loans,
    ROUND(
        100.0 * AVG(CAST(default_flag AS DECIMAL(10,4))), 2
    ) AS default_rate_pct,
    ROUND(
        100.0 * AVG(CAST(npa_flag AS DECIMAL(10,4))), 2
    ) AS npa_ratio_pct
FROM DTIBuckets
GROUP BY dti_bucket
ORDER BY
    CASE dti_bucket
        WHEN '<25%' THEN 1
        WHEN '25-39%' THEN 2
        WHEN '40-54%' THEN 3
        WHEN '55%+' THEN 4
    END;


-- 9. LTV RISK SEGMENTATION

WITH LTVBuckets AS
(
    SELECT
        CASE
            WHEN ltv_pct < 60 THEN '<60%'
            WHEN ltv_pct < 75 THEN '60-74%'
            WHEN ltv_pct < 90 THEN '75-89%'
            ELSE '90%+'
        END AS ltv_bucket,
        ltv_pct,
        npa_flag
    FROM Loan_Portfolio$
)
SELECT
    ltv_bucket,
    COUNT(*) AS loans,
    ROUND(AVG(CAST(ltv_pct AS DECIMAL(10,2))), 2) AS avg_ltv,
    ROUND(
        100.0 * AVG(CAST(npa_flag AS DECIMAL(10,4))), 2
    ) AS npa_ratio_pct
FROM LTVBuckets
GROUP BY ltv_bucket
ORDER BY
    CASE ltv_bucket
        WHEN '<60%' THEN 1
        WHEN '60-74%' THEN 2
        WHEN '75-89%' THEN 3
        WHEN '90%+' THEN 4
    END;


-- 10. PRODUCT / PURPOSE PERFORMANCE

SELECT
    purpose,
    COUNT(*) AS loans,
    SUM(loan_amount) AS exposure,
    ROUND(
        100.0 * AVG(CAST(npa_flag AS DECIMAL(10,4))), 2
    ) AS npa_ratio_pct,
    ROUND(AVG(CAST(pd_estimate AS DECIMAL(10,4))), 4) AS avg_pd
FROM Loan_Portfolio
GROUP BY purpose
ORDER BY npa_ratio_pct DESC;


-- 11. EMPLOYMENT TYPE PERFORMANCE

SELECT
    employment_type,
    COUNT(*) AS loans,
    ROUND(
        100.0 * AVG(CAST(default_flag AS DECIMAL(10,4))), 2
    ) AS default_rate_pct,
    ROUND(
        100.0 * AVG(CAST(npa_flag AS DECIMAL(10,4))), 2
    ) AS npa_ratio_pct
FROM Loan_Portfolio$
GROUP BY employment_type
ORDER BY default_rate_pct DESC;


-- 12. MONTHLY NPA TREND

SELECT
    DATEFROMPARTS(
        YEAR(application_date),
        MONTH(application_date),
        1
    ) AS month,
    COUNT(*) AS loans,
    SUM(loan_amount) AS exposure,
    ROUND(
        100.0 * AVG(CAST(npa_flag AS DECIMAL(10,4))), 2
    ) AS npa_ratio_pct
FROM Loan_Portfolio$
GROUP BY
    YEAR(application_date),
    MONTH(application_date)
ORDER BY
    YEAR(application_date),
    MONTH(application_date);


-- 13. TOP 25 EXPOSURE ACCOUNTS WITH RISK SIGNALS

SELECT TOP 25
    loan_id,
    loan_amount,
    risk_band,
    pd_estimate,
    credit_score,
    dti_pct,
    ltv_pct,
    prior_delinquencies,
    days_past_due
FROM loan_portfolio$
ORDER BY loan_amount DESC;


-- 14. APPLICANTS WITH MULTIPLE WARNING SIGNALS

SELECT
    loan_id,
    risk_band,
    pd_estimate,
    credit_score,
    dti_pct,
    ltv_pct,
    prior_delinquencies,
    days_past_due
FROM loan_portfolio$
WHERE
    CASE WHEN credit_score < 650 THEN 1 ELSE 0 END
    +
    CASE WHEN dti_pct >= 50 THEN 1 ELSE 0 END
    +
    CASE WHEN ltv_pct >= 85 THEN 1 ELSE 0 END
    +
    CASE WHEN prior_delinquencies >= 2 THEN 1 ELSE 0 END
    +
    CASE WHEN days_past_due >= 30 THEN 1 ELSE 0 END
    >= 3
ORDER BY pd_estimate DESC;


-- 15. EXPECTED LOSS ESTIMATE
-- EL = PD * LGD * EAD
-- Assumed LGD = 45%

SELECT
    SUM(pd_estimate * 0.45 * loan_amount) AS expected_loss,
    SUM(loan_amount) AS exposure,
    ROUND(
        100.0 * SUM(pd_estimate * 0.45 * loan_amount)
        / NULLIF(SUM(loan_amount), 0),
        2
    ) AS expected_loss_rate_pct
FROM Loan_Portfolio$;


GO







