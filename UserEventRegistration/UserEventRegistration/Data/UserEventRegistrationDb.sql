IF OBJECT_ID(N'dbo.SuperHeroes', N'U') IS NOT NULL drop table dbo.SuperHeroes; 

create table dbo.SuperHeroes(
	Id int identity(1,1), 
	Name varchar(500),
	FirstName varchar(500),
	LastName varchar(500),
	Place varchar(500)
)

insert into dbo.SuperHeroes values ('Super Man', 'Peter', 'Parker', 'Marvel');
insert into dbo.SuperHeroes values ('Super Man2', 'Peter2', 'Parker', 'Marvel2');
insert into dbo.SuperHeroes values ('Super Man3', 'Peter3', 'Parker', 'Marvel3');


select * from dbo.SuperHeroes;

