CREATE PROCEDURE sp_current_locks
AS SET NOCOUNT ON
SELECT 
    request_session_id AS session_id, 
    DB_NAME(resource_database_id) AS database_name,
    resource_associated_entity_id, 
    CASE WHEN resource_type = 'OBJECT' 
         THEN OBJECT_NAME(resource_associated_entity_id) 
         WHEN resource_associated_entity_id = 0 THEN 'N/A' 
         ELSE OBJECT_NAME(p.object_id) 
    END AS entity_name, 
    index_id, 
    resource_type AS resource, 
    resource_description AS description, 
    request_mode AS mode, 
    request_status AS status 
FROM sys.dm_tran_locks t 
LEFT JOIN sys.partitions p ON p.partition_id = t.resource_associated_entity_id 
WHERE resource_database_id = DB_ID() AND resource_type != 'DATABASE'
