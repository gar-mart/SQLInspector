CREATE TABLE dbo.sqlins_procs_output(
	proc_name VARCHAR(50),
	output_index TINYINT CONSTRAINT DF_sqlins_procs_output_output_index DEFAULT (1),
	[column] VARCHAR(50),
	description VARCHAR(500)

	CONSTRAINT PK_sqlins_procs_output PRIMARY KEY (proc_name, output_index, [column])
)