CREATE TABLE dbo.sqlins_procs_param(
	proc_name VARCHAR(50),
	parameter VARCHAR(50),
	parameter_type VARCHAR(50),
	description VARCHAR(500)

	CONSTRAINT PK_sqlins_procs_param PRIMARY KEY (proc_name, parameter)
)