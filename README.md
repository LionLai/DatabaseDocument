Database-Document
=================

Description: T-SQL script to generate the database document for SQL server 2000/2005 Return JSON Format

output format 
like below
[{
  TableName: [dbo].[TopicMessage],
	Description: "",
	Coumns: [{
		Name: Id,
		Datatype: BIGINT,
		Nullable: N,
		Description: ""
	}, {
		Name: TopicId,
		Datatype: BIGINT,
		Nullable: N,
		Description: ""
	}, {
		Name: UserId,
		Datatype: BIGINT,
		Nullable: N,
		Description: ""
	}, {
		Name: Message,
		Datatype: VARCHAR(-1),
		Nullable: N,
		Description: ""
	}, {
		Name: ReplyingId,
		Datatype: BIGINT,
		Nullable: Y,
		Description: ""
	}, {
		Name: CreateOn,
		Datatype: DATETIME,
		Nullable: N,
		Description: ""
	}, ...],
	FKs: [{
		Name: FK_xxx_yyy,
		Column: yyyId,
		Reference To: "[yyy].[Id]"
	}, ...],
	DefaultConstraints: [{
		Name: DF_xxx_CreateOn,
		Column: CreateOn,
		Value: (getdate())
	}, ...],
	Indexes: [{
		Name: PK_xxx,
		Type: Clustered,
		Columns: ["Id"]
	}, ...]
}, ...]
