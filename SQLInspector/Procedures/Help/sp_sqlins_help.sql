CREATE OR ALTER PROCEDURE sp_sqlins_help (
	@proc_name VARCHAR(50) = NULL
)
AS
SET NOCOUNT ON

IF @proc_name IS NULL
BEGIN
	SELECT name [Procedure], description Description 
	FROM sqlins_procs_desc 
END

ELSE
BEGIN
	SELECT name [Procedure], description Description 
	FROM sqlins_procs_desc 
	WHERE name = @proc_name
	
	SELECT parameter Parameter,
		   parameter_type Type,
		   description Description
	FROM sqlins_procs_param WHERE proc_name = @proc_name
	
	DECLARE @max_output INT 
	
	SET @max_output = (
		SELECT DISTINCT COUNT(DISTINCT output_index)
		FROM sqlins_procs_output
		WHERE proc_name = @proc_name
	)
	
	IF @max_output > 1 
	BEGIN
		DECLARE @i INT = 1
		
		WHILE (@i <= @max_output)
		BEGIN
			SELECT output_index [Output Index],
				   [column] [Output Column],
				   description Description
			FROM sqlins_procs_output  A
			WHERE proc_name = @proc_name
				  AND output_index = @i
		
			SET @i += 1
		END
	END
	
	ELSE 
	BEGIN
		SELECT [column] [Output Column], description Description 
		FROM sqlins_procs_output 
		WHERE proc_name = @proc_name
	END
END