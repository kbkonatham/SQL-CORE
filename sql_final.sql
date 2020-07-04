declare @date1 datetime='2018-07-31 09:59:32.853'
declare @date2 datetime='2018-07-31 10:01:35.767'
select DATEDIFF(hh,@date1,@date2)


========== initial-firstname-middle name--last name======
create table #t(Name varchar(20))
insert into #t values('Krishna.k'),('Vamsi Mukkanti'),('siva kesav Reddy'),('naveen'),('rajesh D')

select  case when len(parsename(REPLACE(name,' ','.'),1))=1 then parsename(REPLACE(name,' ','.'),1) end initial ,
        case when parsename(REPLACE(name,' ','.'),3) is not null then parsename(REPLACE(name,' ','.'),3) 
		else coalesce(parsename(REPLACE(name,' ','.'),2),parsename(REPLACE(name,' ','.'),1) )
		end first_name,
				case when parsename(REPLACE(name,' ','.'),3) is not null then parsename(REPLACE(name,' ','.'),2) end as middlename,
				case when len(parsename(REPLACE(name,' ','.'),1))>1 and  parsename(REPLACE(name,' ','.'),2) is not null then parsename(REPLACE(name,' ','.'),1) end as Last_name   
from #t


------------------------indexing------
CREATE TABLE SalesOrderHeader
( OrderKey INT NOT NULL
, OrderDate DATETIME2(3) NOT NULL
, CustomerID INT)
GO
--Next I add a clustered index.

CREATE CLUSTERED INDEX SalesOrderHeaderCX_OrderDate
ON dbo.SalesOrderHeader (OrderDate);
GO
---Now I add a PK.

ALTER TABLE dbo.SalesOrderHeader
ADD CONSTRAINT SalesOrderHeaderPK
    PRIMARY KEY (OrderKey);
 go

 ALTER TABLE dbo.SalesOrderHeader
ADD CONSTRAINT SalesOrderHeaderUK
    unique  (CustomerID);


 ---------------------------------------------------------
----whatapp query-- multipul cte-----
DROP TABLE #temp_len
create table #temp_len(sno int , code int ,name varchar(10))
insert into #temp_len(sno,code,name)values(1,123,'ABC') ,(2,123,'ABCD'),(3,111,'TEMP'),(4,112,'WXY'),(5,112,'WXYZ')
SELECT * FROM #temp_len
go
WITH
CTE_MAX
AS
(select * from (
select *,len(name) len_max from #temp_len) d where len_max= (select max(len(name)) max_len from #temp_len ))
,cte_min
as
(select * from (
select *,len(name) len_max from #temp_len) d where len_max= (select min(len(name)) max_len from #temp_len ))
select n.sno,n.code,x.sno from CTE_MAX X join cte_min N on n.code=x.code
------------min lenth ---max length------
select * from (
select *,len(ename) len_max from karvy1) d where len_max= (select max(len(ename)) max_len from karvy1 )
select * from (
select *,len(ename) len_max from karvy1) d where len_max= (select min(len(ename)) max_len from karvy1 )

go



------Cross Apply max and min value---------
create table #max_pivot (c1 int,c2 int,c3 int,c4 int)
insert into #max_pivot values(2,4,5,6),(8,9,10,13),(12,14,15,17)

Select max(value) from #max_pivot cross apply (values(c1),(c2),(c3),(c4)) as b (value)

Select min(value) from #max_pivot outer apply (values(c1),(c2),(c3),(c4)) as b (value)

-------------------
select * from #max_pivot
select max(maxs) max_from_all from (
select * from (select max(c1) c1,max(c2) c2,max(c3) c3,max(c4) c4 from #max_pivot)qw
unpivot( maxs for max_p in (c1,c2,c3,c4))r)z 


----------------------------------------------

EXEC sp_MSForEachTable ' ptint 

'

-------table count in data base-------------
CREATE TABLE #counts(table_name varchar(255),row_count int)
EXEC sp_MSForEachTable @command1='INSERT #counts (table_name, row_count) SELECT ''?'', COUNT(*) FROM ?'
SELECT table_name, row_count FROM #counts ORDER BY table_name, row_count DESC

-----whatup table------

source table data: 
CREATE TABLE [dbo].[parent](
	[parentsupplierid] [int] NULL,
	[supplierid] [int] NULL,
	[suppliername] [varchar](50) NULL
) ON [PRIMARY]
GO
INSERT [dbo].[parent] ([parentsupplierid], [supplierid], [suppliername]) VALUES (123, 321, N'AAA')
GO
INSERT [dbo].[parent] ([parentsupplierid], [supplierid], [suppliername]) VALUES (123, 231, N'BBB')
GO
INSERT [dbo].[parent] ([parentsupplierid], [supplierid], [suppliername]) VALUES (NULL, 123, N'ABC')
GO
INSERT [dbo].[parent] ([parentsupplierid], [supplierid], [suppliername]) VALUES (456, 654, N'DDD')
GO
INSERT [dbo].[parent] ([parentsupplierid], [supplierid], [suppliername]) VALUES (NULL, 546, N'EEE')
GO
INSERT [dbo].[parent] ([parentsupplierid], [supplierid], [suppliername]) VALUES (NULL, 456, N'DEF')
GO
INSERT [dbo].[parent] ([parentsupplierid], [supplierid], [suppliername]) VALUES (789, 987, N'GGG')
GO
INSERT [dbo].[parent] ([parentsupplierid], [supplierid], [suppliername]) VALUES (NULL, 879, N'HHH')
GO
INSERT [dbo].[parent] ([parentsupplierid], [supplierid], [suppliername]) VALUES (NULL, 789, N'GHI')
GO

select * from parent

step 1: create one temp table to create rownumber as per  source table records:
temp table : parenttest
CREATE TABLE [dbo].[parenttest ](
	[parentsupplierid] [int] NULL,
	[supplierid] [int] NULL,
	[suppliername] [varchar](50) NULL,
	[rn] [int] NULL
) 
truncate table [parenttest]
insert into [parenttest]
select * from ( 
SELECT  [parentsupplierid]
      ,[supplierid]
      ,[suppliername], row_number ()over(order by [supplierid] )as rn
  FROM [parent]
)a 
go
select * from [parenttest]
step: 2 
---------now main logic is started 
SELECT   
    ISNULL( a.[parentsupplierid],b.[supplierid]) [parentsupplierid],
   
    A.[supplierid],
    A.[suppliername],
    B.[suppliername] AS [PARENTsuppliername]
FROM   
    [parenttest] A  --- Table for base records
LEFT JOIN [parenttest] M  -- Join for missing parent
    ON M.rn = (A.rn -1)
    AND M.[parentsupplierid] IS NULL
    AND A.[parentsupplierid] IS NULL
INNER JOIN [parenttest] B
    ON ISNULL(A.parentsupplierid, M.supplierId) = B.supplierid option( hash join)

---OPTION  (HASH GROUP)  OPTION(order group)----
 select sum(sal),DEPTNO from karvy1 group by DEPTNO  OPTION  (HASH GROUP );

  select count(*) from karvy1
    
-----whatsapp example--------
----Pivot using case ststement---
--create table--
create table #case_with_pivot (name varchar(10), no int)

--insert data---
insert into #case_with_pivot values('A',1),('A',2),('A',3)
insert into #case_with_pivot values('B',1),('B',2),('B',3)

---select query----
select name, max(case when no=1 then 1 end) col2,max(case when no=2 then 2 end) col3, max(case when no=3 then 3 end) col2,
CONCAT( name,  max(case when no=1 then 1 end),max(case when no=2 then 2 end), max(case when no=3 then 3 end))
from #case_with_pivot group by name

---- multible CTE whatup example------ 
---aggregate the aggregates----
   with cte_one
   as
(   select  max(i.sal) max_sal,
   (case
    when DATENAME(mm,hiredate)='january' then 1      when DATENAME(mm,hiredate)='February' then 1   when DATENAME(mm,hiredate)='march' then 1 
	when DATENAME(mm,hiredate)='April' then 2        when DATENAME(mm,hiredate)='may' then 2        when DATENAME(mm,hiredate)='june' then 2 
	when DATENAME(mm,hiredate)='july' then 3         when DATENAME(mm,hiredate)='august' then 3     when DATENAME(mm,hiredate)='September' then 3 
    when DATENAME(mm,hiredate)='october' then 4 	 when DATENAME(mm,hiredate)='november' then 4 	when DATENAME(mm,hiredate)='december' then 4 
   end) as QQ
    from karvy1 i
    group by case
    when DATENAME(mm,hiredate)='january' then 1     when DATENAME(mm,hiredate)='February' then 1     when DATENAME(mm,hiredate)='march' then 1 
	when DATENAME(mm,hiredate)='April' then 2       when DATENAME(mm,hiredate)='may' then 2          when DATENAME(mm,hiredate)='june' then 2 
	when DATENAME(mm,hiredate)='july' then 3        when DATENAME(mm,hiredate)='august' then 3       when DATENAME(mm,hiredate)='September' then 3 
	when DATENAME(mm,hiredate)='october' then 4	    when DATENAME(mm,hiredate)='november' then 4 	 when DATENAME(mm,hiredate)='december' then 4 
   end) ,
 
   cte_two 
   AS
  ( SELECT * , (case
    when DATENAME(mm,hiredate)='january' then 1     when DATENAME(mm,hiredate)='February' then 1     when DATENAME(mm,hiredate)='march' then 1 
	when DATENAME(mm,hiredate)='April' then 2       when DATENAME(mm,hiredate)='may' then 2          when DATENAME(mm,hiredate)='june' then 2 
	when DATENAME(mm,hiredate)='july' then 3        when DATENAME(mm,hiredate)='august' then 3       when DATENAME(mm,hiredate)='September' then 3 
	when DATENAME(mm,hiredate)='october' then 4	    when DATENAME(mm,hiredate)='november' then 4 	 when DATENAME(mm,hiredate)='december' then 4 
   end) qq  from karvy1
   )
   select cte_two.EMPNO,cte_two.ENAME,cte_two.SAL,cte_one.QQ ,cte_one.max_sal from cte_one  join cte_two on cte_one.QQ=cte_two.qq
go
  

----------row count after load the daata to the table------------
declare @rowcount int
select * from karvy1
set @rowcount=@@ROWCOUNT
select @rowcount
-----lead ---lag-------
select EMPNO,LAG(EMPNO,3,0)over(order by EMPNO) from karvy1---,lead (EMPNO,3,0)over(order by EMPNO) 
-----merge output into audit table----
  select * from emp_temp
  select * from [dbo].[emp_new]
   select * from   emp_Audit
   go
   merge [emp_new] d
   using emp_temp s 
   on d.empno=s.empno
   when matched then 
   update set ename=s.ename, job=s.job
   when not matched then 
   insert  (ename,job,mgr) values(s.ename,s.job,s.mgr)
   when not matched by source then delete
   output inserted.*,$action,deleted.*,getdate() into emp_Audit;
   go
   select * from emp_Audit
   go 
 -------------------------------------------------
 --[6:40 PM, 10/11/2017] +91 70138 56858: 

create table one(no int ,aname varchar(10))
create table two(no int ,bname varchar(10))
create table three(no int ,cname varchar(10))

go
insert into one values(1,'cat'),(2,'dog'),(3,'Bird')
go
insert into two values(1,'aaa'),(1,'bbb'),(2,'ccc'),(2,'ddd')
go
insert into three values(1,'xxx'),(1,'yyy'),(1,'zzz'),(2,'www')

;with b1 as(
select b.*,ROW_NUMBER() over(partition by no order by bname) as RN
from two b
)

,
c1 as (
select c.*,ROW_NUMBER() over(partition by no order by cname) as RN
from three c
)
select a.*,t.bname,t.cname
from one a
left join
(
select coalesce(b1.no,c1.no) as no,
b1.bname as bname,
c1.cname as cname
from b1
full join c1 on b1.no=c1.no and b1.rn=c1.rn
)t  on a.no=t.no;

[6:40 PM, 10/11/2017] +91 70138 56858: output
[6:40 PM, 10/11/2017] +91 70138 56858: 

1	cat	aaa	xxx
1	cat	bbb	yyy
1	cat	NULL	zzz
2	dog	ccc	www
2	dog	ddd	NULL
3	Bird	NULL	NULL

 go
 ---Msg 35338, Level 15, State 1, Line 1
Clustered columnstore index is not supported.
GO
 ---output class in Dml operation-------LIKE TRIGGERS----
 declare @out table(nos int,ename varchar(100),job varchar(100))
insert into karvy (empno,ename,job)
output inserted.empno,inserted.ename,inserted.job
values(103,'balaji','konatham')
select * from @out
 ---options in set operator----
 select * from TEST
union all
select * from test
union all
 select * from TEST
union all
select * from test
OPTION (merge union)
go
select * from TEST
union 
select * from test 
OPTION (concat union)
--OPTION (CONCAT  union)
go
 
 
 -------dynamic sql -------------
 declare @sql nvarchar(100)
 set @sql='select * from karvy1'
 exec sp_executesql @sql
 go
 -------------sequence object------------
CREATE SEQUENCE seq_person
MINVALUE 1
START WITH 1
INCREMENT BY 1
CACHE 10;

-----Any month any  year date between [01-09]%------103,104,106,113,105
select *,HIREDATE hire_date_time ,convert (varchar(25),HIREDATE,104) deriver  from karvy1 
where convert (varchar(25),HIREDATE,104) like '[01-09]%' 
order by HIREDATE 


-----all date conversions-----
select  convert(varchar,getdate(),101) '101',
       convert(varchar,getdate(),102) '102',
	   convert(varchar,getdate(),103) '103',
       convert(varchar,getdate(),104) '104',
									  
       convert(varchar,getdate(),106) '106',
	   convert(varchar,getdate(),107) '107',
       convert(varchar,getdate(),108) '108',
	   convert(varchar,getdate(),109) '109',
	   convert(varchar,getdate(),110) '110',
       convert(varchar,getdate(),111) '111',
	   --convert(varchar,HIREDATE,112)  iso from karvy1
	   convert(varchar,getdate(),113) '113',
	   convert(varchar,getdate(),114) 'time_114',
	   getdate() get_date,
	   convert(varchar,getdate(),105) as '105',
	   convert(varchar,getdate(),120)as sarath_120,
	   convert(varchar,getdate(),121) as '121',
	   convert(varchar,getdate(),126) '126' ,
	   convert(varchar,getdate(),127) '127',
	   convert(varchar,getdate(),130) '130'
	   go
	   select HIREDATE,getdate() as get_date,
	   go
	  select convert(varchar(19), select convert(datetime,getdate(),121),121) as get_date from karvy1


--------all constraints in one table---
CREATE TABLE constraints (
    Iden_tity int identity(1,1) ,
    Notnull_Name varchar(2) NOT NULL,
    UniQue_Name varchar(25) unique,
    pk_name  int primary key,
	check_name int CHECK (check_name>=18),
	default_name varchar(10) DEFAULT 'balaji',

    
);
select * from constraints

----DML USING JOINS --------
go
---UPDATE---
update karvy set job=s.JOB,sal=s.SAL

from karvy d join karvy1 s on 
  d.EMPNO=s.EMPNO
  where s.DEPTNO=10

  go
  --DELETE---
  delete karvy
  from karvy d join karvy1 s on 
  d.EMPNO=s.EMPNO
  where s.DEPTNO=10
  ----insert using joins-------
  insert into karvy  select s.*,1 from  karvy d right outer join  karvy1 s on d.EMPNO=s.EMPNO where d.EMPNO is null
  go

  select s.EMPNO,d.EMPNO  from karvy d  left outer join karvy1 s on 
  d.EMPNO=s.EMPNO
  where s.EMPNO is null
  go
  select s.* from  karvy d right outer join  karvy1 s on d.EMPNO=s.EMPNO where d.EMPNO is null



---------exists ---
--if exists also we can use---
 if OBJECT_ID('karvy') is  null
 begin
select  'table is note there'
 end
 else
 begin
 select 'tabel is already exists'
 end
 --cube-- rollup  --    grouping 	sets-------
 ---drilldown like report
    select	job,DEPTNO ,sum(sal) from karvy1 group by rollup (job,DEPTNO)
	-- drill through---
	select job,DEPTNO ,sum(sal) from karvy1 group by cube    (job,DEPTNO)

   select job,DEPTNO ,sum(sal) from karvy1 group by 
    grouping 
	sets(	job,DEPTNO,
			job,
			DEPTNO,
			()
		)

--sub query---
select * from karvy1 where DEPTNO in (select DEPTNO from dept where loc='CHICAGO')-- in('CHICAGO','BOSTON') )
--- left semi join error mark---
select * from karvy1 k where not  exists (select DEPTNO from dept where  DEPTNO =k.DEPTNO)--- in ('CHICAGO','BOSTON') )
go
---- inline----
select *,(select loc from DEPT where DEPTNO=e.DEPTNO) from karvy e

---derived table=----
select  DEPTNO,SAL from (select * from karvy1)a where DEPTNO=10


----WHATUP TWO TABLES IN TO ONE TABLE----
create table #pop(year varchar(10),country varchar(10),pop int)
create table #gdp(year varchar(10),country varchar(10),gdp int)
go
select * from #pop
select * from #gdp
go
insert into #pop values('2014','us',1000),('2015','us',2000)
insert into #gdp values('2014','us',500),('2015','uk',600)

go



select  a.year,a.country,p.pop ,g.gdp
 from (select year,country  from #pop 
union 
select year,country from    #gdp  
) a
left join #pop p
on a.country=p.country and a.year=p.year
left join #gdp g
on a.country=g.country and a.year=g.year
order by a.year,a.country

---------print like table ----
drop table #test
create table #test(Id int, date varchar(10), d varchar(10))
insert into #test values(100,'2018-01-01', 'a,b,c')
insert into #test values(100,'2018-01-01', 'd,e,f')
insert into #test values(100,'2018-01-01', 'g,h,i,j,k')

go
select id, date,
	convert(varchar(100), left(d, charindex(',', d + ',') - 1)),
	convert(varchar(100), stuff(d, 1, charindex(',', d + ','), ''))
	from #test


go
with tmp(id, date, dataitem, d)
as
(
	select id, date,
	convert(varchar(100), left(d, charindex(',', d + ',') - 1)),
	convert(varchar(100), stuff(d, 1, charindex(',', d + ','), ''))
	from #test
	union all
	select id, DATE,
	convert(varchar(100), left(d, charindex(',', d + ',') - 1)),
	convert(varchar(100), stuff(d, 1, charindex(',', d + ','), ''))
	from tmp
	where
	d > '')
	select
	id, date, dataitem from tmp order by id


---- error handeling in ssis----
create table  #b(no int , error varchar(100))
go
begin
begin try
select   1/0--* rom karvy1
end try
begin catch
select ERROR_LINE() as line ,
ERROR_MESSAGE() message,
ERROR_NUMBER() err_num,
 ERROR_PROCEDURE() err_pro,
  @@ERROR,
   ERROR_SEVERITY() seve,
   ERROR_STATE() err_state
end catch
end
--go insert into #b select ERROR_LINE() as line ,ERROR_MESSAGE() message
--end catch
--end
select* from #b
go
go

declare
@date varchar(8)=replace(CONVERT(varchar,getdate(),102),'.',''),
@time varchar(6)=replace(CONVERT(varchar,getdate(),108),':',''),
@backuppath varchar(50);

select @backuppath=CONCAT('E:\bala_',@date,'_',@time,'.bak')
print @backuppath
backup database AdventureWorks2012
to disk= @backuppath
go

create function fn_inline()
returns table 
as
return select * from karvy1

go
----- DML ON @FUNCTION----
select * from fn_inline()
update fn_inline() set job=left(job,4) 
delete fn_inline() where DEPTNO=10
insert into fn_inline() (EMPNO,ENAME ) values(100,'balaji')
select * from fn_inline()
go



alter function fn_multi_lint(@dept int)
returns @tal table(no int primary key ,name varchar(20), job varchar(20))
as
begin
insert into @tal 
select distinct EMPNO,ENAME,JOB from karvy1 where DEPTNO=@dept
return
end
go


----- @TABLE VALIED FUNCTION----
create function fn_delect()
returns table 
as
return select * from dept  
go
select * from fn_delect()
go
-------- MULTI VALIED FUNCTION-----
create function fn_multi()
returns @table table (no int,name varchar(10))
as
begin
insert into @table
select EMPNO,ENAME from karvy1
return
end 
go
----VIEWS-----
select * from fn_multi()
insert into fn_multi() (no,name) values(101,'bala')
go
create view vw_select 
as
select * from karvy1


go
-----DML ON VIEWS-------
select * from vw_select

insert into vw_select (EMPNO,ENAME) values(200,'ba_view')

update vw_select set JOB='BAD' where EMPNO=200
delete vw_select where EMPNO=100
go



GO
select FLOOR(0.03),CEILING(0.03)
select floor(rand()*100)
declare @count int
set @count=1
while (@count<=10)
begin
print floor (rand()*100)
set @count=@count+1
end

go
Msg 8622, Level 16, State 1, Line 1
Query processor could not produce a query plan because of the hints defined in this query. 
Resubmit the query without specifying any hints and without using SET FORCEPLAN.
go
-----incremental loading ---- full loading----full scan
---- source -- left outer -- filter--select
insert into look_up  select s.* from karvy1 s left join  look_up d on s.EMPNO=d.EMPNO  where    d.EMPNO is null

-----delete from another table ---
--delete look_up from karvy1 s left join  look_up d on s.EMPNO=d.EMPNO 
       delete look_up 
        from karvy1 s  join  look_up d 
        on s.EMPNO=d.EMPNO 

---update  from another table ------
update look_up set EMPNO=s.EMPNO ,ENAME=s.ENAME 
               from karvy1 s  join  look_up d 
               on s.EMPNO=d.EMPNO 

------requercy query-------
select * from look_up
go
--alter table look_up drop column increment_sal---
go
;with cte_order (empno,ename ,mgr,position ) 
as
(select empno,ename ,mgr,1  from karvy1 where MGR is null
union all
select karvy1.empno,karvy1.ename ,karvy1.mgr,cte_order.position+1  from karvy1 join cte_order on karvy1.MGR=cte_order.empno
)
select emp.empno,emp.ename ,emp.mgr  mgrs,isnull(mgr.ename, 'superboss') boss,emp.position  from cte_order emp left join cte_order mgr on emp.mgr=mgr.empno 
go

 create  table ha
 
 (no int ,
 name varchar(10),
 sal money,
 doj date,
 dat time,
 total datetime,
 dept int
 )
 
 insert into ha(no, name, sal, doj, dat, total, dept) values(1,'balaji',200,getdate(),getdate(),getdate(),10)
 select no, name, sal, doj, dat, total, dept from ha

 go
 alter table ha alter column no varchar(15)not null
 go
 alter table ha alter column name varchar(20) not null
 go
 alter table ha alter column name varchar(12) null

 go
 select * from ha
 alter table ha drop column balji  
 go
 alter table ha add no int constraint  bala_uk unique

 truncate table ha 

 go
 alter table ha add constraint no_pk primary key (no)

 select * from EMP
 go
alter table ha drop column name

go


select ceiling(100*rand())
select pi()
select rand()
select round(12023654.25621,1,0)

select sign(100)
select SQRT(81)

select SQUARE(9)

select NCHAR(301)
select CHARINDEX('@','balaji@k@onatham.com',8)
go
select * from karvy1 where CHARINDEX('M',ENAME)>0

select LEFT('hello',3)
select SUBSTRING('balajikoantham',2,8)

select len('balajikojj')
select upper('balajikojj')
select REPLACE('balaji','a','A')
select REPLICATE('balaji ',2)
select DIFFERENCE('smith','smith')
select 'helo'+SPACE(12)+'konatham'

select STUFF('balaji',3,3,'yy')
select REPLACE('balaji','a','A')
select SUBSTRING('balaji',2,2)
go

select getdate()
select day(getdate())

select MONTH(getdate())
select YEAR(getdate())
select EOMONTH(getdate(),-2)
select datepart(MM,getdate())
select DATENAME(MM,getdate())

select datepart(WEEKDAY,getdate())+5
select DATENAME(WEEKDAY,getdate())+cast(5 as varchar)

select convert(varchar(100),getdate(),1)
select convert(varchar(100),getdate(),2)
select convert(varchar(100),getdate(),3)
select convert(varchar(100),getdate(),4)
select convert(varchar(100),getdate(),5)
select convert(varchar(100),getdate(),6)
select convert(varchar(100),getdate(),7)
go

select ISNUMERIC(1)
select isdate(getdate())
select ISNULL(null,200)
select DATALENGTH('nn')
go
select HOST_NAME()
select HOST_ID()

go
select IDENT_CURRENT('emp')

select NEWID()
select nullif(100,10)
select nullif(10,10)
go
select  coalesce(null,100,44)
select  coalesce(null,null,null,100)
go
--- case ststement --simple --serch case statement-------
select EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM,  DEPTNO ,case 

when DEPTNO=10 then 'one'
when DEPTNO=20 then 'two'
when DEPTNO=30 then 'three'
end as DEPTNO,
case DEPTNO
when 10 then 'one'
when 20 then 'two'
when 30 then 'three'
end as DEPT_NO_2
 from [dbo].[karvy1]

go
select * from karvy1
go
update   karvy1  set sal=case
                           when DEPTNO=10 then sal+sal*0.02 
						    when DEPTNO=20 then sal+sal*0.3 
							 when DEPTNO=30 then sal+sal*0.5
							 else sal+sal*1 
						    end 
							go
							select count (*) from karvy1
								select COUNT_BIG(*) from karvy1

								select sum(sal) from karvy1
								select min(sal) ,deptno from karvy1 group by deptno

								select distinct DEPTNO from karvy1

								select  DEPTNO from karvy1
								group by DEPTNO 
								go
							    select  DEPTNO ,count(1)from karvy1
								group by DEPTNO ,JOB
								order by 1
								go

								select EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM,SAL+ isnull(COMM,0) as app, DEPTNO from karvy1

									select  DEPTNO ,count(1)from karvy1
								group by DEPTNO ,JOB
								having count(1) >=2


select * from emp_new
union
select * from karvy1
option (hash union)
go
select * from emp_new
union all
select * from karvy1
go
select * from emp_new
intersect
select * from karvy1

go
select * from emp_new
except
select * from karvy1


go
select * from karvy1 where sal=( select max(sal) from karvy1 where sal< (select max(sal) from emp_new1))
go


--deptwise hiest salery

select  a.* from karvy1 a where sal in (select max(sal) from karvy1 group by DEPTNO) order by DEPTNO--------

go
select *,RANK() over(partition by deptno order by sal ) ranks, DENSE_RANK() over(partition by deptno order by sal ) D_ranks from karvy1

go
---Dept wise second hiest sal
 with ctr_dept
as
(select *, DENSE_RANK() over(partition by deptno order by sal ) D_ranks from karvy1
)
select * from ctr_dept where D_ranks>=2  ---D_ranks=2
go
----who have sub-ordines in showes left semi join
 select * from karvy1 where EMPNO   in  (select distinct MGR from karvy1)
select * from karvy1 where ENAME like 'a%'

go
use bala
select   max(sal),sum(sal) from karvy1 group by DEPTNO
select max(sal) from karvy1 group by DEPTNO
select sum(sal) from karvy1 group by DEPTNO

go
select * from karvy1 e where exists  (select  * from karvy1 f where e.EMPNO=f.MGR)

select * from karvy1

select deptno, Min(sal) from karvy1 where exists (select deptno, max(sal) from karvy1 group by deptno) group by deptno

select deptno from karvy1 group by deptno

select deptno, min(sal) from karvy1 group by deptno


go
with SalCTE 
AS 
(SELECT Dense_RANK() over(PARTITION BY DEPTNO ORDER BY SAL desc) AS rnk,deptno,sal from karvy1)
select sal from SalCTE where rnk=2

go

select deptno,sal, cast(deptno+max(sal) as money) from karvy1   group by deptno,sal
go
select * into Duplicate from karvy1

insert into Duplicate select * from karvy1
select * from Duplicate 
go
with DUPCTE AS (SELECT *,ROW_NUMBER()OVER(PARTITION BY EMPNO ORDER BY DEPTNO) AS R from Duplicate)
--delete DUPCTE  WHERE R>1


SELECT * FROM DUPCTE WHERE R>1
go









go
declare @name1 varchar(100) 
declare @name2 varchar(100)

set @name1='abc'
set @name2='xyz'
 select @name1 => @name2
go
select * into #test from karvy1

select  EMPNO, ENAME , JOB , MGR, HIREDATE, SAL, COMM, DEPTNO  from karvy1
select * from #test
update #test set ENAME=JOB,JOB=ENAME 
go


select * from karvy1 k where  exists(
select distinct mgr  from karvy1 m where k.EMPNO=m.MGR) 
go

select * into bal from karvy1
insert into bal select * from karvy1
go

create nonclustered index ix_name_non on karvy1(deptno) 
create clustered index ix_name on karvy1(deptno) 
go

declare @week int
set @week= 10 --DATEPART(DW,getdate())
print @week
if @week=1
print 'sunday'
else if @week=2
print 'monday'
else if @week=3
print 'thuesday'
else if @week=4
print 'wednesday'
else if @week=5
print 'thursday'
else if @week=6
print 'friday'
else if @week=7
print 'saterday'
else print ' last else'


go
declare @week int
set @week= 6 --DATEPART(DW,getdate())
print @week
if @week=1
print 'sunday'
else print 'last else'
 if @week=2
print 'monday'
else print 'last else'
if @week=3
print 'thuesday'
else print 'last else'
if @week=42
print 'wednesday'
else print 'last else'
if @week=5
print 'thursday'
else print 'last else'
 if @week=6
print 'friday'
else print 'last else'
 if @week=7
print 'saterday'
else print 'last else'
go

declare @week int
set @week= 44--datepart(dw,getdate())
print @week
select 
case @week
 when 1 then 'sunday'
 when 2 then 'mon'
 when 3 then 'thu'
 when 4 then 'wed'
 when 5 then 'thu'
 when 6 then 'fri'
 when 7 then 'sat'
 when 8 then 'sunday'
 else 'meee'
end
go
select * into karavy1_new from karvy1
go
select EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM, DEPTNO  from karavy1_new

update karavy1_new set sal=case DEPTNO
                                when 10 then sal+sal*0.1
								when 20 then sal+sal*0.2
								when 30 then sal+sal*0.3
								else  sal+SAL
								end
	go
select k.DEPTNO,k.SAL,n.SAL from karavy1_new n join karvy1 k on n.EMPNO=k.EMPNO order by k.DEPTNO
go
select DEPTNO,sum(sal) before,sum(case DEPTNO
                                when 10 then sal+sal*0.1
								when 20 then sal+sal*0.2
								when 30 then sal+sal*0.3
								else  sal+SAL
								end ) after_cost from karvy1
								group by DEPTNO


								order by DEPTNO

								go

declare cur_case cursor for select EMPNO,DEPTNO,SAL from karvy1
declare @EMPNO int,@DEPTNO int,@SAL money
open cur_case
fetch next from cur_case into @EMPNO ,@DEPTNO ,@SAL
while (@@FETCH_STATUS=0)
begin

     select @DEPTNO Deptno,@SAL before,(case @DEPTNO
                                when 10 then @SAL+@SAL*0.1
								when 20 then @SAL+@SAL*0.2
								when 30 then @SAL+@SAL*0.3
								else  @SAL+@SAL
								end) as After_Increment 
								--group by @DEPTNO


								--order by @DEPTNO

print cast(@DEPTNO as varchar) +' sal is '+cast(@SAL as varchar)
fetch next from cur_case into @EMPNO ,@DEPTNO ,@SAL
end
close cur_case
deallocate cur_case


--Msg 164, Level 15, State 1, Line 14
--Each GROUP BY expression must contain at least one column that is not an outer reference.
--Msg 1008, Level 16, State 1, Line 17
--The SELECT item identified by the ORDER BY number 1 contains a variable as part of the expression identifying a column position.
-- Variables are only allowed when ordering by an expression referencing a column name.




go
select * from EMP
alter table EMP drop column number
alter table emp add  number int null
update  emp  set number=(select  row_number() over(  order by ename))
select * from EMP

go



declare @i int
declare @j int
declare @str varchar(100)
set @str=''
set @i=6
while(@i>=1)
begin
   set @j=8
   while(@j>=@i)
   begin
  -- set @str=@str+cast(@j as varchar(100))
   set @str= CONCAT(@str,@i)
   set @j=@j-1
   end
   print @str
   set @str=''
   set @i=@i-1
end
go



declare cur_update cursor for select sal,COMM from emp
declare @sal int ,@comm int 
open cur_update
fetch next from cur_update into @sal,@comm
 declare @i int =1
while(@@FETCH_STATUS=0)
begin
 update emp set sal=@sal+100+@i,comm=@comm+600+@i
 select Salary=sal,Commission=comm from emp;
 set @i=@i+2
 fetch next from cur_update into @sal,@comm
end
close cur_update
deallocate cur_update

go
select * from emp

go
create trigger bala_trigger on emp

after insert ,update,delete
as
begin
declare @dt int
set @dt=DATEpart(HH,getdate())
print @dt
end

go
create table Orders1 (EmpName varchar(25),Salary int,[Date] date,DisplayOrder int)

insert into Orders1 values('Sudheer',5000,'2/05/2014',null),
('Anil',6000,'2/06/2014',null),('Usha',3000,'3/05/2014',null),
('Rajesh',4000,'2/08/2014',null),('Arun',2000,'4/05/2014',null),
('Neelam',1500,'2/09/2014',null)
select * from orders1
select * from orders

select *,Dense_Rank()over(partition by Date order by Salary desc) as DO from orders1
go

declare Ord_Cur cursor for select Salary from orders1 order by Salary desc
declare @Salary int,@DisplayOrder int;
set @DisplayOrder=1;
open Ord_Cur;
fetch next from Ord_Cur into @Salary;
while(@@FETCH_STATUS=0)
begin
update Orders1 set DisplayOrder=@DisplayOrder where Salary=@Salary;
fetch next from Ord_Cur into @Salary;
set @DisplayOrder=@DisplayOrder+1;
end;
select * from Orders1;
close Ord_Cur;
deallocate Ord_Cur;

go
select EmpName,Salary,Date,DisplayOrder=((update orders1 set DisplayOrder=(select Row_Number()over(order by Salary desc) from Orders1))) from orders1 order by salary desc
select Row_Number()over(order by Salary desc) from Orders1
go
update Orders1 set DisplayOrder=(select ROW_NUMBER()over(order by Salary desc) from Orders1)
go

create table Area (SNo int,[Length] decimal(10,2),Width  decimal(10,2),Height decimal(10,2),Area decimal(10,2))
go
insert into Area(SNo,[Length],Width,Height) values(1,10,20,4),(2,15,12,7.5),(3,12,12,5),(4,10.2,5.1,4),(5,6,9,3)
go

select * from Area
go
declare Area_Cur cursor for select SNo,[Length],Width,Height from Area;
declare @SNo int,@Length decimal(10,2),@Width  decimal(10,2),@Height decimal(10,2);
open Area_Cur;
fetch next from Area_Cur into @SNo,@Length,@Width,@Height;
while(@@FETCH_STATUS=0)
begin
update Area set Area=2*@Height*(@Length+@Width) where SNo=@SNo;
fetch next from Area_Cur into @SNo,@Length,@Width,@Height;
end
select * from Area
close Area_Cur;
deallocate Area_Cur;
go


create table jj (no int, sale varchar(100))
go
alter table jj alter column sale int  null

select * from Rao
go
--sp_rename 'jj','Rao' 
--sp_rename 'table.jj','Rao' 
go
select GETDATE()
select * from bal
alter table bal drop column  empcode
alter table bal add empcode varchar(100)
create nonclustered index ix_cursor on bal(empno)
drop index bal.ix_cursor
go
ALTER INDEX IX_Employee_OrganizationalLevel_OrganizationalNode 
  ON HumanResources.Employee  
REORGANIZE ;
go
ALTER INDEX ALL ON HumanResources.Employee  
REORGANIZE 
go
CREATE STATISTICS NamePurchase  
    ON AdventureWorks2012.Person.Person (BusinessEntityID, EmailPromotion)  
    WITH FULLSCAN, NORECOMPUTE;
go


go
ALTER INDEX ALL ON Production.Product
REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON,
              STATISTICS_NORECOMPUTE = ON)
go
select  left(ENAME,2)+'-'+ cast( datepart(YYYY,hiredate)as varchar(10))+ '-'+cast(EMPNO as varchar(10)) from bal
go
declare cur_dynamic cursor for select EMPNO,ENAME,HIREDATE from bal
declare @EMPNO int,@ENAME varchar(100),@HIREDATE datetime
open cur_dynamic
fetch next from cur_dynamic into @EMPNO,@ENAME,@HIREDATE
while (@@FETCH_STATUS=0)
begin
update  bal set empcode=left(ENAME,2)+'-'+ cast( datepart(YYYY,hiredate)as varchar(10))+ '-'+cast(EMPNO as varchar(10))  where EMPNO=@EMPNO
fetch next from cur_dynamic into @EMPNO,@ENAME,@HIREDATE
end
close cur_dynamic
deallocate cur_dynamic
go



/****** Object:  DdlTrigger [tr]    Script Date: 08-Feb-18 12:07:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE trigger [tr]
on all server
for create_table ,alter_table, drop_table
as
begin
declare @eventdata xml
select @eventdata= EVENTDATA()
insert into bala.dbo.auduting_Trigger (SPID ,ServerName,LoginName  ) values 
            (     @eventdata.value('(/EVENT_INSTANCE/SPID)[1]','varchar(250)'),
                   @eventdata.value('(/EVENT_INSTANCE/ServerName)[1]','varchar(250)'),
				   @eventdata.value('(/EVENT_INSTANCE/LoginName)[1]','varchar(250)') 
)
end

GO
select * from auduting_Trigger
go
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

ENABLE TRIGGER [tr] ON ALL SERVER
GO

SELECT 
  COUNT( ENAME) 
FROM bal 
go
select  * from pivots  order by 3
select no from pivots group by no  
-- pivot
select no,name ,ind,uk,rss from pivots
pivot(sum(sales_amount) for country in(ind,uk,rss) )yy where no=1 --option (hash  aggregate)
go
-- select * from unpivots
select no,name ,country,sales_amount from unpivots
unpivot( sales_amount for country in( ind,uk,rss))qq --option (merge join) Msg 8622, Level 16, State 1, Line 1
--Query processor could not produce a query plan because of the hints defined in this query. 
--Resubmit the query without specifying any hints and without using SET FORCEPLAN.
go
----dept dont have no employees
select * from dept where DEPTNO not in(select distinct DEPTNO from karvy1 )
go
--- pivot on derived table
select * from (
select count(k.deptno) counts ,d.LOC 
from karvy1 k join DEPT d 
on  k.DEPTNO=d.DEPTNO
group by d.deptno,d.LOC) trr
pivot (sum(counts) for loc in(CHICAGO,DALLAS,[NEW YORK])  )q
go

--pivot on cte
with  k2  as
(select count(k.DEPTNO) counts,dd.DNAME from DEPT dd  join karvy1 k on dd.DEPTNO=k.DEPTNO 
group by dd.DNAME)
 select * from  k2
pivot(sum(counts) for dname in(ACCOUNTING,RESEARCH,SALES ) ) p
go
select * from pivots
select * from unpivots
go
----- serch case statement on date (experence)
select *,convert(date,hiredate)  date,
convert(time,hiredate) time,
datediff(yy,HIREDATE,getdate()) experence,sal,
(case  
when datediff(yy,HIREDATE,getdate()) >=38 then sal+sal*0.4  
when datediff(yy,HIREDATE,getdate()) between 36 and 37  then sal+sal*0.3
when datediff(yy,HIREDATE,getdate()) <=35 then sal+sal*0.2 
else sal+sal
end )cas
from karvy1

go
----- simple case statement on date (experence)
select *,convert(date,hiredate)  date,
convert(time,hiredate) time,
datediff(yy,HIREDATE,getdate()) experence,sal,
(case  datediff(yy,HIREDATE,getdate())
when  38 then sal+sal*0.4  
when  36   then sal+sal*0.3
when  35 then sal+sal*0.2 
else sal+sal
end )cas
from karvy1
go
----concatenate function

select CONCAT('bajl',' ','kris.',7,4)
go

---deleting duplicates records--

select c1,c2

---03-03-2018--
data_type varchar(10),
pk int
,checks int
,for_eign int

)

go
create table log2(no int,name varchar(10))


select * from logs
select * from log2

alter table log2 alter column no int not null
alter table log2 add  constraint pk_log2 primary key  (no)
alter table logs alter column [data_type] int  
alter table logs add constraint pk_logs primary key  (pk)

alter table logs add constraint ck_log check (checks<100)
go
alter table logs
 add constraint fk_log foreign key (for_eign) 
   references log2(no)
 go
 insert into logs(no, nulla, data_type, pk, checks, for_eign) values(1,null,'va',1,101,12)  --- 1 identity error
insert into logs( nulla, data_type, pk, checks, for_eign) values(null,'va',1,101,12)  --- 2 null r not allowed in not null column
insert into logs( nulla, data_type, pk, checks, for_eign) values('null','va',1,101,12) ----3 Conversion failed 

insert into logs( nulla, data_type, pk, checks, for_eign) values('null','va',1,101,12) ---4 INSTED OF TRIGGER
insert into logs( nulla, data_type, pk, checks, for_eign) values('null','1',NULL,75,12)---5 column does not allow nulls IN PK KEY
insert into logs( nulla, data_type, pk, checks, for_eign) values('null','1',1,101,12)---6 conflicted with the CHECK constraint
insert into logs( nulla, data_type, pk, checks, for_eign) values('null','1',1,75,12)-----7 conflicted with the FOREIGN KEY constraint
insert into logs( nulla, data_type, pk, checks, for_eign) values('null','1',1,75,10)--- 8 DML EXECUTION + UPDATE T-LOG OK WORKING
insert into logs( nulla, data_type, pk, checks, for_eign) values('null','va',1,101,12) --- 9 AFTER TRIGGERS

insert into logs( nulla, data_type, pk, checks, for_eign) values('null','va',1,101,12) ---10 COMMIT TRANSACTION
insert into logs( nulla, data_type, pk, checks, for_eign) values('null','va',1,101,12) --- 11 DATA FILE  WRITTING
  go
 insert into log2  VALUES(10,'HR')


 go
 create table constraints(
 p_k int,
 f_k int,
 u_k int,
 n_null int,
 de_frult int,
 chk int
 )
 go
 alter table constraints alter column p_k  int not null
 alter table constraints add constraint pk_constraints primary key (p_k)
 alter table constraints add constraint uk_constraints unique (u_k)
 alter table constraints alter column n_null int not null
 go
 alter table constraints  
 add constraint def_con default 1 for [de_frult]

 ---insert bla default values
 -- is not working
 ----add constraint   def_con set  default de_frult 111
 go
 alter table constraints add constraint checks check (chk <100)
 go 

 WITH myTally(n)
AS
(SELECT n = ROW_NUMBER() OVER (ORDER BY (SELECT null))

)

SELECT *
FROM myTally 

FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) a(n)
	
	FROM a(n) (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10))
	The error is that I can't use a VALUES clause as a table'

	go
	WITH myvalues
AS
(
SELECT n
FROM
(
    VALUES
        (123) ,
        (80138) ,
        (2910)
)  a (n)
)
SELECT TOP 10
       FORMAT(myvalues.n, ?)
FROM myvalues; 


go

create table zemp(eno int  primary key,name varchar(100) , deptno int)
create table zdept(deptno int  primary key,name varchar(100) )



 -- add primary key
alter table zemp add constraint pk12345 primary key(eno)
go
alter table zdept add constraint pk1234 primary key (deptno)

go
---adding foreign key
alter table zemp  
add constraint fk_dept foreign key (deptno) 
references zdept(deptno)

go
--- drop the foregin key
alter table zemp drop   [fk_dept]
go

insert into [zemp] (eno, name, deptno) values (16,'balg',20)

insert into  zdept (deptno, name) values(30,'forty')



go
select * from zemp
select * from zdept

delete from zdept where deptno=20
delete from zemp where deptno=20
select * from zemp
select * from zdept

alter table zemp drop constraint [fk_dept]

go
select getdate()

go

create table pk_fk(clue_ix  int,pk_key int ,uniq_ix int ,uniq_key int ,non_clu_ix int)

select * from pk_fk

create clustered index ix_clus on pk_fk(clue_ix)

alter table pk_fk alter column pk_key int not null 
alter table pk_fk add constraint pk_key primary key (pk_key)

create unique nonclustered index ix_unique on pk_fk(uniq_ix)


alter table pk_fk add constraint uk_key unique (uniq_key)

create nonclustered index ix_noncluster on pk_fk(non_clu_ix)
go

truncate table pk_fk

insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(1,1,1,1,1)  --1 inserted sucessfully --cluster index inserted
--2 
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(1,1,1,1,1) --2 Violation of PRIMARY KEY constraint
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(1,2,1,1,1) ---3 Cannot insert duplicate in unique index
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(1,2,2,1,1) ---4  Violation of UNIQUE KEY constraint
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(1,2,2,2,1) ---- ok 
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(1,3,3,3,1) -----ok
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(null,5,5,5,1)  -----cluster index allow nulls
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(2,9,9,9,null)

insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(22,null,9,9,null)--not allowed  nulls in pk
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(22,10,null,9,null)----not allowed 
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(22,10,null,null,null)---- ok allowed one 
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(22,21,null,null,null) --- The duplicate key value is (<NULL>)
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(22,21,21,null,null)  ----Violation of UNIQUE KEY constraint The duplicate key value is (<NULL>)

insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(22,21,21,21,null) --- ok allowed
insert into pk_fk (clue_ix, pk_key, uniq_ix, uniq_key, non_clu_ix) values(20,22,21,21,null)

select * from pk_fk
go
create table oe (n int , nn int)

create  clustered index ix_oe on oe(n)

alter table oe add constraint pkone primary key (nn)
insert into oe(n,nn) values(81,8)
select * from oe
alter table oe alter column nn int  not null
truncate table oe 



go
--5-03-2018
--- we can not perform dml operation on column stored index is cteate on a table .



INSERT INTO [DB_A].[dbo.a_test] (a,b,c, d)

go
 select *   from c
 select * from b
 go
insert into c values (1,'a'),(2,'b'),(3,'c'),(4,'d'),(5,'e'),(6,'f')
insert into b values(2,'b'),(3,'c')
go
truncate table b
go
insert into b
select c.id,c.name,* from c left join b on c.id=b.id where b.id is null
go

 select *   from c
 select * from b
 go
 update b 
 set id=c.id, name=c.name from b join c on b.id=c.id 

 select *   from c
 select * from b
go
 delete b  from b join c on b.id=c.id
 select *   from c
 select * from b
 go


 insert into b
select c.id,c.name from c left join b on c.id=b.id where b.id is null

 update b 
 set id=c.id, name=c.name from b join c on b.id=c.id 

 delete b  from b join c on b.id=c.id
go



CREATE PROCEDURE [dbo].[Fact]
(
@Number Integer,
@RetVal Integer OUTPUT
)
AS
DECLARE @In Integer
DECLARE @Out Integer
	IF @Number != 1
			BEGIN
			SELECT @In = @Number-1
			EXEC Fact @In, @Out OUTPUT -- Same stored procedure has been called again(Recursively)
			SELECT @RetVal = @Number * @Out
			END
	ELSE
			BEGIN
			SELECT @RetVal = 1
			END
		RETURN
GO
DECLARE @Out Integer
exec [Fact] 5, @Out  output
print @out

select * from sys.server_principals 

select * from  sys.sql_logins
select NEWID()

-----06-03-2018-----

select * from bal

--pivot on cte
with  kk  as
(select count(k.DEPTNO) counts,d.DNAME from DEPT d  join karvy1 k on d.DEPTNO=k.DEPTNO 
group by d.DNAME)
 select * from  kk
pivot(sum(counts) for dname in(ACCOUNTING,RESEARCH,SALES ) ) p

---17-3-2018---
go
declare  @i int,@j int,@k int,@str varchar(100)
set @str=''
set @i=1
while(@i<=5)
begin
 set @k=4
	 while(@k>=@i)
	 begin
	 set @str=@str+' '
	 set @k=@k-1
	 end
	 set @j=1
 while(@j<=@i)
 begin
 set @str=@str+'*'
 set @j=@j+1
 end
 print @str;
set @i=@i+1
set @str='';
end
go


declare  @i int,@j int,@k int,@l int=5,@str varchar(100)
set @str=''
set @i=5
while(@i>=1)
begin
 set @k=4
 while(@k>=@i)
 begin
 set @str=@str+' '
 set @k=@k-1
 end
 set @j=1
 while(@j<=@i)
 begin
 set @str=@str+'*'
 set @j=@j+1
  end
 print @str;
set @i=@i-1
--set @l=@l-1;
set @str='';
end
go
go
--------palfiebonic series---------
begin
declare @x int=1,@y int=2,@z int,@i int=1, @str varchar(100)='';
set @str=cast(@x as varchar)+' '+cast(@y as varchar)
while(@i<=10)
begin
set @z=@x+@y;
set @str=@str+' '+cast(@z as varchar)
set @x=@y;
set @y=@z;
set @i=@i+1;
end
print @str;
end
go

-----revers the number--- Phalindrome ---
begin
declare @no bigint=7995370636,@r int,@revno bigint=0,@i int=1,@j int;
set @j=LEN(@no);
while(@i<=@j)
begin
set @r=@no%10;
set @revno=(@revno*10)+@r;
set @no=@no/10;
set @i=@i+1
end
print @revno
--if(@revno=@t)
--Print 'Given no. is Phalindrome.'
--else
--Print 'Given no. is not Phalindrome.'
end
go


--- select * from Department
        declare @deptno int
        declare @deptname  varchar(30)
        declare @location varchar(30)
        set @deptno=1
        while( @deptno<=100)
        begin
			set @deptname='DeptName_'+CONVERT(varchar,@deptno);
			 --  begin
					if @deptno in(50,90)
						begin  
						  set @location= null;
						  insert into Department(Deptno,DeptName,LocationID) values(@deptno,@deptname,@location )
						end  
					else
						begin
						  set @location= @deptno%10;
							     if(@location=0)
									begin
									 set @location=10;
									 end
							insert into Department(DeptNo,DeptName,LocationID) values(@deptno,@deptname,@location )
						end
					set @deptno=@deptno+1
				end
			-- end  

	go
 select * from  Employee

	  Declare @f_Empno int 
	  Declare  @f_Name varchar(20)
	  Declare @f_Dateofjoin date
	  Declare  @f_Sal money
	  Declare @f_Deptno int 
	  
	  set @f_Empno=475083
	   while @f_Empno <= 1000000
	   
	   begin
		   set @f_Deptno= @f_Empno%100+1;
		   set @f_Sal=(1000+@f_Empno)*@f_Deptno;
		   set @f_Dateofjoin=DATEADD(MI,-(@f_Empno/2),getdate());
		   set @f_Name='Empname_'+CONVERT(varchar,@f_Empno);

		   insert into Employee(Empno,Name,Dateof_Join,Sal,Deptno) values(@f_Empno,@f_Name,@f_Dateofjoin,@f_Sal,@f_Deptno);
		   set @f_Empno=@f_Empno+1;
	   end

	   go
	   	  Declare @f_Dateofjoin date
	    set @f_Dateofjoin=DATEADD(MI,-(5/2),getdate());
		print @f_Dateofjoin

		go
		select 5/2
		-------------------------
		go
		------19-3-2018-----------
		go
merge merge_pivote m
using merge_cte s
on m.no=s.no
---inner join--
when matched then 
update set country=s.country
--left outer join-----
when not matched then 
insert values(s.no,s.country,s.name,s.sales_amount)
----left anti semi join----
when not matched by source then
delete
OUTPUT
    $action,
    DELETED.no dele ,
    INSERTED.no ins ,
    DELETED.no del;
--    INSERTED.Title;
  --  DELETED.Quantity,
  --  INSERTED.Quantity;
  --INTO @MergeOutput;
go

select ROW_NUMBER() over( order by [no]) row_num, DENSE_RANK()over( order by [no]) DENSE_RAN, RANK()over( order by [no]) ranks, sum(sales_amount)over( order by no desc) sums  from  merge_cte 

select ROW_NUMBER() over(  order by [no]) row_num , DENSE_RANK()over( order by [no]) densranks,RANK()over( order by [no]) ranks   from  merge_cte 
select  DENSE_RANK()over( order by [no]) densranks from  merge_cte 
select  RANK()over( order by [no]) ranks from  merge_cte
select *,sum(sales_amount)over( partition by name order by no desc) from  merge_cte
select * from merge_cte order by 1 desc

create clustered index ix_cluster_no on merge_cte(no) 
go

--------29--march--2018--- with date functions------

Create table BEmployee(Empid int identity(1,1) constraint Emp_PK primary key,FirstName varchar(50),LastName varchar(50),Salary money,JoinDate date,Department varchar(50) )

create table Incentive(EmpId int identity(1,1),HikeDate date,Hike money)

insert into BEmployee values('John','Abraham',1000000,'01-JAN-13','Development'),('Michael','Clark',800000,'01-JAN-13','Testing')
,('Roy','Thomas',700000,'01-FEB-13','Sales'),('Tom','Jose',600000,'01-FEB-13','Testing'),('Jerry','Pinto',650000,'01-FEB-13','Sales')
,('Philip','Mathew',750000,'01-JAN-13','Development')

insert into Incentive values('01-FEB-13',5000),('01-FEB-13',3000),('01-June-13',4000),('01-June-13',4500),('01-June-13',3500)

Select * from BEmployee

Create View EmployeeSalary as(select E.Salary from BEmployee E join Incentive I on E.Empid=I.EmpId)

select * from EmployeeSalary

select * from BEmployee E where  exists(select S.Salary from EmployeeSalary S where E.Salary=S.Salary)

Select E.FirstName+' '+E.LastName, E.Salary from BEmployee E join BEmployee B on E.Empid=B.Empid where E.Salary>=700000 and E.Salary<=1000000
go
-----9---- 

with cte_table
as
(select *,ROW_NUMBER()over(partition by empno order by empno) as row_id from [emp_new] 
)
select * from cte_table where row_id>1

---10----remove duplicates
with cte_table
as
(select *,ROW_NUMBER()over(partition by empno order by empno) as row_id from [emp_new] 
)
delete from cte_table where row_id>1

go---2------
select *,DATEPART(yy,hiredate) as yea,DATEPART(MM,hiredate) as mon,DATEPART(dd,hiredate) as dat from [emp_new]

go

-------5-------
with cte_count
as
(
select *,DATEPART(yy,hiredate) as yea,DATEPART(MM,hiredate) as mon,DATEPART(dd,hiredate) as dat from [emp_new]
)
select mon,count(*) as no_count from cte_count group by mon
go















