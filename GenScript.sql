--//SQL Database documentation script return JSON ver.
--//Author: Nitin Patel, Email: nitinpatel31@gmail.com
--//Date:18-Feb-2008
--//ModifiedBy: LionLai, Email: Lyc1983@gmail.com
--//ModifiedDate:10-May-2013
--//Description: T-SQL script to generate the database document for SQL server 2000/2005 Return JSON Format
Declare @i Int, @maxi Int
Declare @j Int, @maxj Int
Declare @sr int
Declare @Output nvarchar(4000)
--Declare @tmpOutput varchar(max)
Declare @SqlVersion nvarchar(5)
Declare @last nvarchar(155), @current nvarchar(255), @typ nvarchar(255), @description nvarchar(4000)

create Table #Tables  (id int identity(1, 1), Object_id int, Name nvarchar(155), Type nvarchar(20), [description] nvarchar(4000))
create Table #Columns (id int identity(1,1), Name nvarchar(155), Type nVarchar(155), Nullable nvarchar(2), [description] nvarchar(4000))
create Table #Fk(id int identity(1,1), Name nvarchar(155), col nVarchar(155), refObj nvarchar(155), refCol nvarchar(155))
create Table #Constraint(id int identity(1,1), Name nvarchar(155), col nVarchar(155), definition nvarchar(1000))
create Table #Indexes(id int identity(1,1), Name nvarchar(155), Type nVarchar(25), cols nvarchar(1000))

 If (substring(@@VERSION, 1, 25 ) = 'Microsoft SQL Server 2005')
	set @SqlVersion = '2005'
else if (substring(@@VERSION, 1, 26 ) = 'Microsoft SQL Server  2000')
	set @SqlVersion = '2000'
else 
	set @SqlVersion = '2005'

set nocount on
	if @SqlVersion = '2000' 
		begin
		insert into #Tables (Object_id, Name, Type, [description])
			--FOR 2000
			select object_id(table_name),  '[' + table_schema + '].[' + table_name + ']',  
			case when table_type = 'BASE TABLE'  then 'Table'   else 'View' end,
			cast(p.value as nvarchar(4000))
			from information_schema.tables t
			left outer join sysproperties p on p.id = object_id(t.table_name) and smallid = 0 and p.name = 'MS_Description' 
			order by table_type, table_schema, table_name
		end
	else if @SqlVersion = '2005' 
		begin
		insert into #Tables (Object_id, Name, Type, [description])
		--FOR 2005
		Select o.object_id,  '[' + s.name + '].[' + o.name + ']', 
				case when type = 'V' then 'View' when type = 'U' then 'Table' end,  
				cast(p.value as nvarchar(4000))
				from sys.objects o 
					left outer join sys.schemas s on s.schema_id = o.schema_id 
					left outer join sys.extended_properties p on p.major_id = o.object_id and minor_id = 0 and p.name = 'MS_Description' 
				where type in ('U', 'V') 
				order by type, s.name, o.name
		end
Set @maxi = @@rowcount
PRINT 'var dbData = ['
set @i = 1
While(@i <= @maxi)
BEGIN

	--table header
	IF @i <> 1
	BEGIN
		SELECT @Output = ', { TableName : "' + name + '", Description :"' + isnull(@description, '') + '"' from #Tables where id = @i
		print @Output  
	END 
	ELSE
	BEGIN
		SELECT @Output = '{ TableName : "' + name + '", Description :"' + isnull(@description, '') + '"' from #Tables where id = @i
		print @Output    
	END 
	
	--table columns
	truncate table #Columns 
	if @SqlVersion = '2000' 
		begin
		insert into #Columns  (Name, Type, Nullable, [description])
		--FOR 2000
		Select c.name, 
					type_name(xtype) + (
					case when (type_name(xtype) = 'varchar' or type_name(xtype) = 'nvarchar' or type_name(xtype) ='char' or type_name(xtype) ='nchar')
						then '(' + cast(length as varchar) + ')' 
					 when type_name(xtype) = 'decimal'  
							then '(' + cast(prec as varchar) + ',' + cast(scale as varchar)   + ')' 
					else ''
					end				
					), 
					case when isnullable = 1 then 'Y' else 'N'  end, 
					cast(p.value as nvarchar(8000))
				from syscolumns c
					inner join #Tables t on t.object_id = c.id
					left outer join sysproperties p on p.id = c.id and p.smallid = c.colid and p.name = 'MS_Description' 
				where t.id = @i
				order by c.colorder
		end
	else if @SqlVersion = '2005' 
		begin
		insert into #Columns  (Name, Type, Nullable, [description])
		--FOR 2005	
		Select c.name, 
					type_name(user_type_id) + (
					case when (type_name(user_type_id) = 'varchar' or type_name(user_type_id) = 'nvarchar' or type_name(user_type_id) ='char' or type_name(user_type_id) ='nchar')
						then '(' + cast(max_length as varchar) + ')' 
					 when type_name(user_type_id) = 'decimal'  
							then '(' + cast([precision] as varchar) + ',' + cast(scale as varchar)   + ')' 
					else ''
					end				
					), 
					case when is_nullable = 1 then 'Y' else 'N'  end,
					cast(p.value as nvarchar(4000))
		from sys.columns c
				inner join #Tables t on t.object_id = c.object_id
				left outer join sys.extended_properties p on p.major_id = c.object_id and p.minor_id  = c.column_id and p.name = 'MS_Description' AND p.class = 1
		where t.id = @i
		order by c.column_id
		end
	Set @maxj =   @@rowcount
	set @j = 1

	
	if (@maxj >0)
	BEGIN
		PRINT ', Coumns : ['    
		While(@j <= @maxj)
		BEGIN
		
			IF @j = 1
			BEGIN
				select @Output = '{ Name : "' + isnull(name,'')  + '", Datatype : "'  + upper(isnull(Type,'')) + '", Nullable : "' + isnull(Nullable,'N') + '", Description : "' + isnull([description],'') + '" }'
				from #Columns  where id = @j    
			END
			ELSE          
			BEGIN
				select @Output = ', { Name : "' + isnull(name,'')  + '", Datatype : "'  + upper(isnull(Type,'')) + '", Nullable : "' + isnull(Nullable,'N') + '", Description : "' + isnull([description],'') + '" }'
				from #Columns  where id = @j            
			END
		
			print 	@Output 	
			Set @j = @j + 1;
		END
		PRINT ']'  
	END

	--reference key
	truncate table #FK
	if @SqlVersion = '2000' 
		begin
		insert into #FK  (Name, col, refObj, refCol)
	--		FOR 2000
		select object_name(constid), s.name,  object_name(rkeyid) ,  s1.name  
				from sysforeignkeys f
					inner join sysobjects o on o.id = f.constid
					inner join syscolumns s on s.id = f.fkeyid and s.colorder = f.fkey
					inner join syscolumns s1 on s1.id = f.rkeyid and s1.colorder = f.rkey
					inner join #Tables t on t.object_id = f.fkeyid
				where t.id = @i
				order by 1
		end	
	else if @SqlVersion = '2005' 
		begin
		insert into #FK  (Name, col, refObj, refCol)
--		FOR 2005
		select f.name, COL_NAME (fc.parent_object_id, fc.parent_column_id) , object_name(fc.referenced_object_id) , COL_NAME (fc.referenced_object_id, fc.referenced_column_id)     
		from sys.foreign_keys f
			inner  join  sys.foreign_key_columns  fc  on f.object_id = fc.constraint_object_id	
			inner join #Tables t on t.object_id = f.parent_object_id
		where t.id = @i
		order by f.name
		end
	
	Set @maxj =   @@rowcount
	set @j = 1
	if (@maxj >0)
	begin

	    PRINT ', FKs : ['
		While(@j <= @maxj)
		begin
			IF @j = 1
			BEGIN
				select @Output = '{ Name : "' + isnull(name,'')  + '", Column : "' + isnull(col,'') + '", ReferenceTo : "[' + isnull(refObj,'N') + '].[' +  isnull(refCol,'N') + ']" }' 
				from #FK  where id = @j        
			END
			ELSE          
			BEGIN
				select @Output = ', { Name : "' + isnull(name,'')  + '", Column : "' + isnull(col,'') + '", ReferenceTo : "[' + isnull(refObj,'N') + '].[' +  isnull(refCol,'N') + ']" }' 
				from #FK  where id = @j          
			END          
			

			print @Output
			Set @j = @j + 1;
		end
		print ']'
	end

	--Default Constraints 
	truncate table #Constraint
	if @SqlVersion = '2000' 
		begin
		insert into #Constraint  (Name, col, definition)
		select object_name(c.constid), col_name(c.id, c.colid), s.text
				from sysconstraints c
					inner join #Tables t on t.object_id = c.id
					left outer join syscomments s on s.id = c.constid
				where t.id = @i 
				and 
				convert(varchar,+ (c.status & 1)/1)
				+ convert(varchar,(c.status & 2)/2)
				+ convert(varchar,(c.status & 4)/4)
				+ convert(varchar,(c.status & 8)/8)
				+ convert(varchar,(c.status & 16)/16)
				+ convert(varchar,(c.status & 32)/32)
				+ convert(varchar,(c.status & 64)/64)
				+ convert(varchar,(c.status & 128)/128) = '10101000'
		end
	else if @SqlVersion = '2005' 
		begin
		insert into #Constraint  (Name, col, definition)
		select c.name,  col_name(parent_object_id, parent_column_id), c.definition 
		from sys.default_constraints c
			inner join #Tables t on t.object_id = c.parent_object_id
		where t.id = @i
		order by c.name
		end
	Set @maxj =   @@rowcount
	set @j = 1
	if (@maxj >0)
	begin

		PRINT ', DefaultConstraints : ['
		While(@j <= @maxj)
		BEGIN
			IF @j = 1
			BEGIN
				select @Output = '{ Name : "' + isnull(name,'')  + '", Column : "' + isnull(col,'') + '", Value : "' + isnull(definition,'') + '" }' 
				from #Constraint  where id = @j          
			END
			ELSE
			BEGIN
				select @Output = ', { Name : "' + isnull(name,'')  + '", Column : "' + isnull(col,'') + '", Value : "' + isnull(definition,'') + '" }' 
				from #Constraint  where id = @j          
			END
			      
			

			print @Output
			Set @j = @j + 1;
		end

		print ']'
	end


	--Check  Constraints
	truncate table #Constraint
	if @SqlVersion = '2000' 
		begin
		insert into #Constraint  (Name, col, definition)
			select object_name(c.constid), col_name(c.id, c.colid), s.text
				from sysconstraints c
					inner join #Tables t on t.object_id = c.id
					left outer join syscomments s on s.id = c.constid
				where t.id = @i 
				and ( convert(varchar,+ (c.status & 1)/1)
					+ convert(varchar,(c.status & 2)/2)
					+ convert(varchar,(c.status & 4)/4)
					+ convert(varchar,(c.status & 8)/8)
					+ convert(varchar,(c.status & 16)/16)
					+ convert(varchar,(c.status & 32)/32)
					+ convert(varchar,(c.status & 64)/64)
					+ convert(varchar,(c.status & 128)/128) = '00101000' 
				or convert(varchar,+ (c.status & 1)/1)
					+ convert(varchar,(c.status & 2)/2)
					+ convert(varchar,(c.status & 4)/4)
					+ convert(varchar,(c.status & 8)/8)
					+ convert(varchar,(c.status & 16)/16)
					+ convert(varchar,(c.status & 32)/32)
					+ convert(varchar,(c.status & 64)/64)
					+ convert(varchar,(c.status & 128)/128) = '00100100')

		end
	else if @SqlVersion = '2005' 
		begin
		insert into #Constraint  (Name, col, definition)
			select c.name,  col_name(parent_object_id, parent_column_id), definition 
			from sys.check_constraints c
				inner join #Tables t on t.object_id = c.parent_object_id
			where t.id = @i
			order by c.name
		end
	Set @maxj =   @@rowcount
	
	set @j = 1
	if (@maxj >0)
	begin

		PRINT ', CheckConstraints : ['
		While(@j <= @maxj)
		BEGIN
			IF @j = 1
			BEGIN
				select @Output = '{ Name : "' + isnull(name,'')  + '", Column : "' + isnull(col,'') + '", Definition : "' + isnull(definition,'') + '" },' 
				from #Constraint  where id = @j    
			END
			ELSE
			BEGIN
				select @Output = ', { Name : "' + isnull(name,'')  + '", Column : "' + isnull(col,'') + '", Definition : "' + isnull(definition,'') + '" }' 
				from #Constraint  where id = @j
			END      
			print @Output 
			Set @j = @j + 1;
		end

		print ']'
	end


	--Triggers 
	truncate table #Constraint
	if @SqlVersion = '2000' 
		begin
		insert into #Constraint  (Name)
			select tr.name
			FROM sysobjects tr
				inner join #Tables t on t.object_id = tr.parent_obj
			where t.id = @i and tr.type = 'TR'
			order by tr.name
		end
	else if @SqlVersion = '2005' 
		begin
		insert into #Constraint  (Name)
			SELECT tr.name
			FROM sys.triggers tr
				inner join #Tables t on t.object_id = tr.parent_id
			where t.id = @i
			order by tr.name
		end
	Set @maxj =   @@rowcount
	
	set @j = 1
	if (@maxj >0)
	begin

		PRINT ', Triggers : ['
		While(@j <= @maxj)
		BEGIN
			IF @j = 1
			BEGIN
				select @Output = '{ Name : "' + isnull(name,'')  + '", Description : "" }'       
				from #Constraint  where id = @j
			END
			ELSE
			BEGIN
				select @Output = ', { Name : "' + isnull(name,'')  + '", Description : "" }'       
				from #Constraint  where id = @j
			END         

			print @Output 
			Set @j = @j + 1;
		end

		print ']'
	end

	--Indexes 
	truncate table #Indexes
	if @SqlVersion = '2000' 
		begin
		insert into #Indexes  (Name, type, cols)
			select i.name, case when i.indid = 0 then 'Heap' when i.indid = 1 then 'Clustered' else 'Nonclustered' end , c.name 
			from sysindexes i
				inner join sysindexkeys k  on k.indid = i.indid  and k.id = i.id
				inner join syscolumns c on c.id = k.id and c.colorder = k.colid
				inner join #Tables t on t.object_id = i.id
			where t.id = @i and i.name not like '_WA%'
			order by i.name, i.keycnt
		end
	else if @SqlVersion = '2005' 
		begin
		insert into #Indexes  (Name, type, cols)
			select i.name, case when i.type = 0 then 'Heap' when i.type = 1 then 'Clustered' else 'Nonclustered' end,  col_name(i.object_id, c.column_id)
				from sys.indexes i 
					inner join sys.index_columns c on i.index_id = c.index_id and c.object_id = i.object_id 
					inner join #Tables t on t.object_id = i.object_id
				where t.id = @i
				order by i.name, c.column_id
		end

	Set @maxj =   @@rowcount
	
	set @j = 1
	set @sr = 1
	if (@maxj >0)
	begin

		DECLARE @isPrint BIT
		SET @isPrint = 0
		PRINT ', Indexes : ['
		set @Output = ''
		set @last = ''
		set @current = ''
		While(@j <= @maxj)
		begin
			select @current = isnull(name,'') from #Indexes  where id = @j
					 
			if @last <> @current  and @last <> ''
				BEGIN
					IF @isPrint = 0
					BEGIN
						print '{ Name : "' + @last  + '", Type : "' + @typ + '", Columns : [' + @Output + '] }' 
						SET @isPrint = 1
					END
					ELSE
					BEGIN
						print ', { Name : "' + @last  + '", Type : "' + @typ + '", Columns : [' + @Output + '] }' 
					END              
					
					set @Output  = ''
					set @sr = @sr + 1
				END
                
			IF @Output = ''
			BEGIN
				IF (SELECT cols from #Indexes  where id = @j) <> ''
				BEGIN
					select @Output = @Output + '"' + cols + '"' , @typ = type
					from #Indexes  where id = @j
				END           
			END 
			ELSE
			BEGIN          
				IF (SELECT cols from #Indexes  where id = @j) <> ''
				BEGIN
					select @Output = @Output + ', "' + cols + '"' , @typ = type
					from #Indexes  where id = @j    
				END 
			END 

			
        
			set @last = @current 	
			Set @j = @j + 1;
		end
		if @Output <> ''
		begin	
			IF @isPrint = 1
			BEGIN
				print ',{ Name : "' + @last  + '", Type : "' + @typ + '", Columns : [' + @Output + '] }'       
			END 
			ELSE
			BEGIN          
				print '{ Name : "' + @last  + '", Type : "' + @typ + '", Columns : [' + @Output + '] }'  
				SET @isPrint = 1     
			END 
		END
		print ']'
	end
    Set @i = @i + 1;
	Print '}' 
end


PRINT ']'

drop table #Tables
drop table #Columns
drop table #FK
drop table #Constraint
drop table #Indexes 
set nocount off



