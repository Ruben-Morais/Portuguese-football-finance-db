drop view if exists v_pivot;
CREATE VIEW v_pivot AS
SELECT
    c.club_name,
    f.season,
    MAX(CASE WHEN f.line_item = 'Matchday'                             THEN f.amount_eur_m END) AS matchday,
    MAX(CASE WHEN f.line_item = 'Commercial'                           THEN f.amount_eur_m END) AS commercial,
    MAX(CASE WHEN f.line_item = 'TV and media'                         THEN f.amount_eur_m END) AS tv_media,
    MAX(CASE WHEN f.line_item = 'Player trading'                       THEN f.amount_eur_m END) AS trading_revenue,
    MAX(CASE WHEN f.line_item = 'Player trading costs'                 THEN f.amount_eur_m END) AS trading_costs,
    MAX(CASE WHEN f.line_item = 'Wages'                                THEN f.amount_eur_m END) AS wages,
    MAX(CASE WHEN f.line_item = 'Player amortisation'                  THEN f.amount_eur_m END) AS amortisation,
    MAX(CASE WHEN f.line_item = 'Operating result excl. player rights' THEN f.amount_eur_m END) AS op_result_excl_players,
    MAX(CASE WHEN f.line_item = 'Operating result'                     THEN f.amount_eur_m END) AS op_result,
    MAX(CASE WHEN f.line_item = 'Net result'                           THEN f.amount_eur_m END) AS net_result,
    MAX(CASE WHEN f.line_item = 'Total debt'                           THEN f.amount_eur_m END) AS total_debt,
    MAX(CASE WHEN f.line_item = 'Cash'                                 THEN f.amount_eur_m END) AS cash,
    MAX(CASE WHEN f.line_item = 'Equity'                               THEN f.amount_eur_m END) AS equity,
    MAX(CASE WHEN f.line_item = 'Player registrations'                 THEN f.amount_eur_m END) AS player_registrations,
    MAX(CASE WHEN f.line_item = 'Current assets'                       THEN f.amount_eur_m END) AS current_assets,
    MAX(CASE WHEN f.line_item = 'Current liabilities'                  THEN f.amount_eur_m END) AS current_liabilities,
    MAX(CASE WHEN f.line_item = 'Current borrowings'                   THEN f.amount_eur_m END) AS current_borrowings,
    MAX(CASE WHEN f.line_item = 'Player-sale receivables'              THEN f.amount_eur_m END) AS player_receivables,
    MAX(CASE WHEN f.line_item = 'Payables to clubs'                    THEN f.amount_eur_m END) AS club_payables,
    MAX(CASE WHEN f.line_item = 'Operating cash flow'                  THEN f.amount_eur_m END) AS operating_cash_flow
FROM club_financials f
JOIN clubs c ON c.club_id = f.club_id
GROUP BY c.club_name, f.season;

select * from v_pivot vp

CREATE VIEW v_ratios AS
WITH base AS (
    SELECT
        *,
        matchday + commercial + tv_media               AS recurring_revenue,
        trading_revenue - trading_costs - amortisation AS player_rights_result,
        total_debt - cash                              AS net_debt
    FROM v_pivot
)
SELECT
    club_name,
    season,
    ROUND(recurring_revenue, 1)                                   AS recurring_revenue,
    ROUND(op_result_excl_players, 1)                              AS core_result,
    ROUND(player_rights_result, 1)                                AS player_rights_result,
    ROUND(net_result, 1)                                          AS net_result,
    ROUND(net_result - player_rights_result, 1)                   AS net_result_excl_player_rights,
    ROUND(100.0 * wages / recurring_revenue, 1)                   AS wages_pct,
    ROUND(100.0 * (wages + amortisation) / recurring_revenue, 1)  AS squad_cost_pct,
    ROUND(net_debt, 1)                                            AS net_debt,
    ROUND(net_debt / recurring_revenue, 2)                        AS net_debt_to_revenue,
    ROUND(cash / NULLIF(current_borrowings, 0), 2)                AS cash_to_current_debt,
    ROUND(current_assets / NULLIF(current_liabilities, 0), 2)     AS current_ratio,
    ROUND(operating_cash_flow, 1)                                 AS operating_cash_flow,
    ROUND(player_receivables - club_payables, 1)                  AS net_player_trade_balance
FROM base;

select * from v_ratios 

DROP VIEW IF EXISTS v_yoy;

CREATE VIEW v_yoy AS
SELECT
    club_name,
    season,

    -- revenue
    recurring_revenue,
    ROUND(recurring_revenue
          - LAG(recurring_revenue) OVER (PARTITION BY club_name ORDER BY season), 1)   AS revenue_change,
    ROUND(100.0 * (recurring_revenue
          - LAG(recurring_revenue) OVER (PARTITION BY club_name ORDER BY season))
          / LAG(recurring_revenue) OVER (PARTITION BY club_name ORDER BY season), 1)   AS revenue_change_pct,

    -- core result
    core_result,
    ROUND(core_result
          - LAG(core_result) OVER (PARTITION BY club_name ORDER BY season), 1)         AS core_result_change,

    -- player-rights result
    player_rights_result,
    ROUND(player_rights_result
          - LAG(player_rights_result) OVER (PARTITION BY club_name ORDER BY season), 1) AS player_rights_result_change,

    -- squad cost (percentage points)
    squad_cost_pct,
    ROUND(squad_cost_pct
          - LAG(squad_cost_pct) OVER (PARTITION BY club_name ORDER BY season), 1)      AS squad_cost_pct_change,

    -- net debt
    net_debt,
    ROUND(net_debt
          - LAG(net_debt) OVER (PARTITION BY club_name ORDER BY season), 1)            AS net_debt_change,

    -- net debt / revenue
    net_debt_to_revenue,
    ROUND(net_debt_to_revenue
          - LAG(net_debt_to_revenue) OVER (PARTITION BY club_name ORDER BY season), 2) AS net_debt_to_revenue_change,

    -- current ratio
    current_ratio,
    ROUND(current_ratio
          - LAG(current_ratio) OVER (PARTITION BY club_name ORDER BY season), 2)       AS current_ratio_change,

    -- operating cash flow
    operating_cash_flow,
    ROUND(operating_cash_flow
          - LAG(operating_cash_flow) OVER (PARTITION BY club_name ORDER BY season), 1) AS operating_cash_flow_change,

    -- net player trade balance
    net_player_trade_balance,
    ROUND(net_player_trade_balance
          - LAG(net_player_trade_balance) OVER (PARTITION BY club_name ORDER BY season), 1) AS net_player_trade_balance_change
FROM v_ratios;

select * from v_yoy
