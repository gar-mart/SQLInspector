CREATE PROCEDURE sp_job_info
    @start_date  DATE = NULL,
    @job_owner NVARCHAR(128) = NULL,
    @run_status INT = NULL,
    @step_name NVARCHAR(128) = NULL
AS 
SET NOCOUNT ON

-- Jobs sorted by execution start time
SELECT j.name AS job_name, j.description, ja.start_execution_date
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobactivity ja ON j.job_id = ja.job_id
WHERE (@start_date  IS NULL OR ja.start_execution_date > @start_date )
AND j.enabled = 1
ORDER BY ja.start_execution_date

-- Jobs with their owners
SELECT a.name AS job_name, b.name AS job_owner
FROM msdb.dbo.sysjobs_view a
LEFT JOIN master.dbo.syslogins b ON a.owner_sid = b.sid
WHERE (@job_owner IS NULL OR b.name = @job_owner)

-- Failed agent jobs
SELECT j.name AS job_name, js.step_name, jh.sql_severity, jh.message, jh.run_date, jh.run_time
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobsteps AS js ON js.job_id = j.job_id
INNER JOIN msdb.dbo.sysjobhistory AS jh ON jh.job_id = j.job_id 
WHERE (@run_status IS NULL OR jh.run_status = @run_status)

-- Jobs with specific step name
SELECT j.name AS job_name, js.step_name, jh.sql_severity, jh.message, jh.run_date, jh.run_time
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobsteps AS js ON js.job_id = j.job_id
INNER JOIN msdb.dbo.sysjobhistory AS jh ON jh.job_id = j.job_id 
WHERE (@step_name IS NULL OR js.step_name = @step_name)
