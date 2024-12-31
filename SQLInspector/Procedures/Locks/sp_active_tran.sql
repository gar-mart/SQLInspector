CREATE PROCEDURE sp_active_tran
AS 
SET NOCOUNT ON
SELECT
    st.session_id,
    es.login_name,
    DB_NAME(dt.database_id) AS database_name, 
    dt.database_transaction_begin_time AS begin_time,
    dt.database_transaction_log_bytes_used AS log_bytes,
    dt.database_transaction_log_bytes_reserved AS log_bytes_reserved,
    est.text AS sql_text,
    qp.query_plan AS last_plan
FROM sys.dm_tran_database_transactions dt
INNER JOIN sys.dm_tran_session_transactions st
ON st.transaction_id = dt.transaction_id
INNER JOIN sys.dm_exec_sessions es
ON es.session_id = st.session_id
INNER JOIN sys.dm_exec_connections ec
ON ec.session_id = st.session_id
LEFT OUTER JOIN sys.dm_exec_requests er
ON er.session_id = st.session_id
CROSS APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) AS est
OUTER APPLY sys.dm_exec_query_plan(er.plan_handle) AS qp
ORDER BY begin_time
