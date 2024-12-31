CREATE PROCEDURE sp_backup_info 
AS SET NOCOUNT ON
SELECT
      d.database_id,
      d.name,
      d.state_desc,
      d.recovery_model_desc,
      data_size = CAST(SUM(CASE WHEN mf.[type] = 0 THEN mf.size END) * 8. / 1024 AS DECIMAL(18,2)), -- Data file size in MB
      log_size = CAST(SUM(CASE WHEN mf.[type] = 1 THEN mf.size END) * 8. / 1024 AS DECIMAL(18,2)), -- Log file size in MB
      bu.full_last_date,
      bu.full_size,
      bu.log_last_date,
      bu.log_size last_log_backup_size 
FROM sys.databases d
JOIN sys.master_files mf ON d.database_id = mf.database_id
LEFT JOIN (
    SELECT
          database_name,
          full_last_date = MAX(CASE WHEN [type] = 'D' THEN backup_finish_date END),
          full_size = MAX(CASE WHEN [type] = 'D' THEN backup_size END),
          log_last_date = MAX(CASE WHEN [type] = 'L' THEN backup_finish_date END),
          log_size = MAX(CASE WHEN [type] = 'L' THEN backup_size END)
    FROM msdb.dbo.backupset
    WHERE [type] IN ('D', 'L')
    GROUP BY database_name
) bu ON d.name = bu.database_name
GROUP BY
    d.database_id, d.name, d.state_desc, d.recovery_model_desc, bu.full_last_date, bu.full_size, bu.log_last_date, bu.log_size
ORDER BY data_size DESC
