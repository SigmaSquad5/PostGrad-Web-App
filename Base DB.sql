CREATE DATABASE PostGradOffice;
go
use PostGradOffice;
CREATE TABLE PostGradUser
(
	id int primary key identity(1,1),
	email varchar(50) not null unique,
	password varchar(30) not null
)
CREATE TABLE Admin
(
	id int primary key foreign key references PostGradUser on delete cascade
on update cascade
)
CREATE TABLE GucianStudent
(
	id int primary key foreign key references PostGradUser on delete cascade
on update cascade,
	firstName varchar(20),
	lastName varchar(20),
	type varchar(3),
	faculty varchar(30),
	address varchar(50),
	GPA decimal(3,2),
	undergradID int
)
CREATE TABLE NonGucianStudent
(
	id int primary key foreign key references PostGradUser on delete cascade
on update cascade,
	firstName varchar(20),
	lastName varchar(20),
	type varchar(3),
	faculty varchar(30),
	address varchar(50),
	GPA decimal(3,2),
)
CREATE TABLE GUCStudentPhoneNumber
(	id int,
	phone varchar(20),
	
	primary key(id, phone),
	foreign key(id) references GucianStudent on delete cascade
on update cascade
)
CREATE TABLE NonGUCStudentPhoneNumber
(	id int,
	phone varchar(20),
	
	primary key(id, phone),
	foreign key(id) references NonGucianStudent on delete
cascade on update cascade
)
CREATE TABLE Course
(
	id int primary key identity(1,1),
	fees int,
	creditHours int,
	code varchar(10)
)
CREATE TABLE Supervisor
(
	id int primary key foreign key references PostGradUser,
	name varchar(20),
	faculty varchar(30)
);
CREATE TABLE Examiner
(
	id int primary key foreign key references PostGradUser on delete cascade
on update cascade,
	name varchar(20),
	fieldOfWork varchar(100),
	isNational BIT
)
CREATE TABLE Payment
(
	id int primary key identity(1,1),
	amount decimal(7,2),
	noOfInstallments int,
	fundPercentage decimal(4,2)
)
CREATE TABLE Thesis
(
	serialNumber int primary key identity(1,1),
	field varchar(20),
	type varchar(3) not null,
	title varchar(100) not null,
	startDate date not null,
	endDate date not null,
	defenseDate date,
	years as (year(endDate)-year(startDate)),
	grade decimal(4,2),
	payment_id int foreign key references payment on delete cascade on update
cascade,
	noOfExtensions int
)
CREATE TABLE Publication
(
	id int primary key identity(1,1),
	title varchar(100) not null,
	dateOfPublication date,
	place varchar(100),
	accepted BIT,
	host varchar(100)
);
Create table Defense
(
	serialNumber int,
	date datetime,
	location varchar(15),
	grade decimal(4,2),
	primary key (serialNumber, date),
	foreign key (serialNumber) references Thesis on delete cascade on update
cascade
)
Create table GUCianProgressReport
(
	sid int foreign key references GUCianStudent on delete cascade on update
cascade
,
	no int
,
	date datetime
,
	eval int
,
	state int
,
	description varchar(200)
,
	thesisSerialNumber int foreign key references Thesis on delete cascade
on update cascade
,
	supid int foreign key references Supervisor
,
	primary key (sid, no)
)
Create table NonGUCianProgressReport
(
	sid int foreign key references
NonGUCianStudent on delete
cascade on update cascade,
	no int
,
	date datetime
,
	eval int
,
	state int
,
	description varchar(200)
,
	thesisSerialNumber int foreign key references Thesis on delete cascade
on update cascade
,
	supid int foreign key references Supervisor
,
	primary key (sid, no)
)
Create table Installment
(
	date datetime,
	paymentId int foreign key references Payment on delete cascade on update
cascade
,
	amount decimal(8,2)
,
	done bit
,
	primary key (date, paymentId)
)
Create table NonGucianStudentPayForCourse
(
	sid int foreign key references
NonGucianStudent on
delete cascade on update cascade,
	paymentNo int foreign key references Payment on delete cascade on update
cascade,
	cid int foreign key references Course on delete cascade on update cascade,
	primary key (sid, paymentNo, cid)
)
Create table NonGucianStudentTakeCourse
(
	sid int foreign key references
NonGUCianStudent on delete
cascade on update cascade
,
	cid int foreign key references Course on delete cascade on update
cascade
,
	grade decimal (4,2)
,
	primary key (sid, cid)
)
Create table GUCianStudentRegisterThesis
(
	sid int foreign key references
GUCianStudent on delete
cascade on update cascade,
	supid int foreign key references Supervisor
,
	serial_no int foreign key references Thesis on delete cascade on update
cascade
,
	primary key(sid, supid, serial_no)
)
Create table NonGUCianStudentRegisterThesis
(
	sid int foreign key
references NonGUCianStudent on
delete cascade on update cascade,
	supid int foreign key references Supervisor,
	serial_no int foreign key references Thesis on delete cascade on update
cascade ,
	primary key (sid, supid, serial_no)
)
Create table ExaminerEvaluateDefense
(
	date datetime,
	serialNo int,
	examinerId int foreign key references Examiner on delete cascade on update
cascade,
	comment varchar(300),
	primary key(date, serialNo, examinerId),
	foreign key (serialNo, date) references Defense (serialNumber, date) on
delete cascade on update
cascade
)
Create table ThesisHasPublication
(
	serialNo int foreign key references
Thesis on delete cascade on
update cascade,
	pubid int foreign key references Publication on delete cascade on update
cascade,
	primary key(serialNo,pubid)
)
go
create proc studentRegister
	@first_name varchar(20),
	@last_name varchar(20),
	@password varchar(20),
	@faculty varchar(20),
	@Gucian bit,
	@email varchar(50),
	@address varchar(50)
as
begin
	insert into PostGradUser
		(email,password)
	values(@email, @password)
	declare @id int
	SELECT @id=SCOPE_IDENTITY()
	if(@Gucian=1)
insert into GucianStudent
		(id,firstName,lastName,faculty,address)
	values(@id, @first_name, @last_name, @faculty, @address)
else
insert into NonGucianStudent
		(id,firstName,lastName,faculty,address)
	values(@id, @first_name, @last_name, @faculty, @address)
end
go
create proc supervisorRegister
	@first_name varchar(20),
	@last_name varchar(20),
	@password varchar(20),
	@faculty varchar(20),
	@email varchar(50)
as
begin
	insert into PostGradUser
		(email,password)
	values(@email, @password)
	declare @id int
	SELECT @id=SCOPE_IDENTITY()
	declare @name varchar(50)
	set @name = CONCAT(@first_name,@last_name)
	insert into Supervisor
		(id,name,faculty)
	values(@id, @name, @faculty)
end
go
Create proc userLogin
	@id int,
	@password varchar(20),
	@success bit output,
	@type int output
as
begin
	if exists(
select ID, password
	from PostGradUser
	where id=@id and password=@password)
begin
		set @success =1
		-- check user type 0-->Student,1-->Admin,2-->Supervisor ,3-->Examiner
		if exists(			select id
			from GucianStudent
			where id=@id
		union
			select id
			from
				NonGucianStudent
			where id=@id )
set @type=0
		if exists(select id
		from Admin
		where id=@id)
set @type=1
		if exists(select id
		from Supervisor
		where id=@id)
set @type=2
		if exists(select id
		from Examiner
		where id=@id)
set @type=3
	end
else
set @success=0
end
go
create proc addMobile
	@ID int,
	@mobile_number varchar(20)
as
begin
	if @ID is not null and @mobile_number is not null
begin
		--check Gucian student or not
		if(exists(select *
		from GucianStudent
		where id=@ID))
insert into GUCStudentPhoneNumber
		values(@ID, @mobile_number)
		if(exists(select *
		from NonGucianStudent
		where id=@ID))
insert into NonGUCStudentPhoneNumber
		values(@ID, @mobile_number)
	end
end
go
CREATE Proc AdminListSup
As
Select u.id, u.email, u.password, s.name, s.faculty
from PostGradUser u inner join Supervisor s on u.id = s.id
go
CREATE Proc AdminViewSupervisorProfile
	@supId int
As
Select u.id, u.email, u.password, s.name, s.faculty
from PostGradUser u inner join Supervisor s on u.id = s.id
WHERE @supId = s.id
go
CREATE Proc AdminViewAllTheses
As
Select
	serialNumber, field, type, title, startDate, endDate, defenseDate, years, grade, payment_id, noOfExtensions
From Thesis
go
CREATE Proc AdminViewOnGoingTheses
	@thesesCount int output
As
Select @thesesCount=Count(*)
From Thesis
where endDate > Convert(Date,CURRENT_TIMESTAMP)
go
CREATE Proc AdminViewStudentThesisBySupervisor
As
	Select s.name, t.title, gs.firstName
	From Thesis t inner join GUCianStudentRegisterThesis sr on
t.serialNumber=sr.serial_no
		inner join Supervisor s on s.id=sr.supid inner join GucianStudent gs on sr.sid=gs.id
	where t.endDate > Convert(Date,CURRENT_TIMESTAMP)
union
	Select s.name, t.title, gs.firstName
	From Thesis t inner join NonGUCianStudentRegisterThesis sr on
t.serialNumber=sr.serial_no
		inner join Supervisors on s.id=sr.supid inner join NonGucianStudent gs on
sr.sid=gs.id
	where t.endDate > Convert(Date,CURRENT_TIMESTAMP)
go
go
CREATE Proc AdminListNonGucianCourse
	@courseID int
As
if(exists(select *
from Course
where id=@courseID))
Select ng.firstName, ng.lastName, c.code, n.grade
From NonGucianStudentTakeCourse n inner join Course c on n.cid=c.id inner
	join NonGucianStudent ng
	on ng.id=n.sid
where n.cid=@courseID
go
CREATE Proc AdminUpdateExtension
	@ThesisSerialNo int
As
if(exists(select *
from Thesis
where serialNumber=@ThesisSerialNo))
begin
	declare @noOfExtensions int
	select @noOfExtensions=noOfExtensions
	from Thesis
	where
serialNumber=@ThesisSerialNo
	update Thesis
set noOfExtensions=@noOfExtensions+1
where serialNumber=@ThesisSerialNo
end
go
CREATE Proc AdminIssueThesisPayment
	@ThesisSerialNo int,
	@amount decimal(7,2),
	@noOfInstallments int,
	@fundPercentage decimal(4,2)
As
if(exists(select *
from Thesis
where serialNumber=@ThesisSerialNo))
begin
	insert into Payment
		(amount,noOfInstallments,fundPercentage)
	values(@amount, @noOfInstallments, @fundPercentage)
	declare @id int
	SELECT @id=SCOPE_IDENTITY()
	update Thesis
set payment_id=@id
where serialNumber=@ThesisSerialNo
end
go
CREATE Proc AdminViewStudentProfile
	@sid int
As
if(exists(select *
from GucianStudent
where id=@sid))
Select
	u.id, u.email, u.password, s.firstName, s.lastName, s.type, s.faculty, s.address,
	s.address, s.GPA
from PostGradUser u inner join GucianStudent s on u.id=s.id
WHERE @sid = s.id
else if(exists(select *
from NonGucianStudent
where id=@sid))
Select
	u.id, u.email, u.password, s.firstName, s.lastName, s.type, s.faculty, s.address,
	s.address, s.GPA
from PostGradUser u inner join NonGucianStudent s on u.id=s.id
WHERE @sid = s.id
go
CREATE Proc AdminIssueInstallPayment
	@paymentID int,
	@InstallStartDate date
As
if(exists(select *
from Payment
where id=@paymentID))
begin
	declare @numOfInst int

	select @numOfInst=noOfInstallments
	from Payment
	where id=@paymentID

	declare @payAmount int

	select @payAmount=amount
	from Payment
	where id=@paymentID

	DECLARE @Counter INT

	SET @Counter=1

	declare @instdate date

	set @instdate=@InstallStartDate

	declare @instAmount int

	set @instAmount=@payAmount/@numOfInst

	WHILE (@counter<=@numOfInst)
	BEGIN
		

		if(@counter=1)
			insert into
			Installment
				(date,paymentId,amount,done)
			values(@InstallStartDate, @paymentID
			, @instAmount, 0)
		else
			begin
				set @instdate=DATEADD(MM, 6, @instdate);
				insert into
				Installment
				(date,paymentId,amount,done)
				values(@instdate, @paymentID, @instAmount, 0)
			end
		SET @counter=@counter+1
	END
end
go
CREATE Proc AdminListAcceptPublication
As
select t.serialNumber, p.title
from ThesisHasPublication tp inner join Thesis t on
tp.serialNo=t.serialNumber
	inner join Publication p on p.id=tp.pubid
where p.accepted=1
go
CREATE Proc AddCourse
	@courseCode varchar(10),
	@creditHrs int,
	@fees decimal
As
insert into Course
values(@fees, @creditHrs, @courseCode)
go
CREATE Proc linkCourseStudent
	@courseID int,
	@studentID int
As
if(exists(select *
	from Course ) and exists(select *
	from NonGucianStudent
	where id=@studentID))
insert into
NonGucianStudentTakeCourse
	(sid,cid,grade)
values(@studentID, @courseID, null)
go
CREATE Proc addStudentCourseGrade
	@courseID int,
	@studentID int,
	@grade decimal
As
if(exists(select *
from NonGucianStudentTakeCourse
where sid=@studentID
	and cid=@courseID))
update NonGucianStudentTakeCourse
set grade =@grade
where cid=@courseID and sid=@studentID
go
CREATE Proc ViewExamSupDefense
	@defenseDate datetime
As
select s.serial_no, ee.date, e.name, sup.name
from ExaminerEvaluateDefense ee inner join examiner e on
ee.examinerId=e.id
	inner join GUCianStudentRegisterThesis s on ee.serialNo=s.serial_no
	inner join Supervisor sup on sup.id=s.supid
go
CREATE Proc EvaluateProgressReport
	@supervisorID int,
	@thesisSerialNo int,
	@progressReportNo int,
	@evaluation int
As
if(exists(select *
	from Thesis
	where serialNumber=@thesisSerialNo ) and
	@evaluation in(0,1,2,3) )
begin
	if(exists(select *
	from GUCianStudentRegisterThesis
	where
	serial_no=@thesisSerialNo))
begin
		if(exists(select *
		from GUCianProgressReport
		where
		thesisSerialNumber=@thesisSerialNo and no=@progressReportNo))
		BEGIN
			declare @gucSid int
			select @gucSid=sid
			from GUCianStudentRegisterThesis
			where serial_no=@thesisSerialNo
			update GUCianProgressReport
	set eval=@evaluation
	where sid=@gucSid and thesisSerialNumber=@thesisSerialNo and
				no=@progressReportNo
		END
		ELSE
		BEGIN
			RAISERROR('NO Progress Reports with this Progress Report Number!',11,1);
		END
	end
else if(exists(select *
	from NonGUCianStudentRegisterThesis
	where
serial_no=@thesisSerialNo))
	begin
		if(exists(select *
		from NonGUCianProgressReport
		where
		thesisSerialNumber=@thesisSerialNo and no=@progressReportNo))
		BEGIN
			declare @nonGucSid int
			select @nonGucSid=sid
			from NonGUCianStudentRegisterThesis
			where serial_no=@thesisSerialNo
			update NonGUCianProgressReport
			set eval=@evaluation
			where sid=@nonGucSid and thesisSerialNumber=@thesisSerialNo and no=@progressReportNo
		END
		ELSE
		BEGIN
			RAISERROR('NO Progress Reports with this Progress Report Number!',11,1);
		END
	end
end
ELSE
BEGIN
RAISERROR('There are NO Thesis with this Thesis Serial Number!',11,1);
END
go
CREATE Proc ViewSupStudentsYears
	@supervisorID int
As
if(exists(select *
from Supervisor
where id=@supervisorID))
begin
			select s.firstName, s.lastName, t.years
		from GUCianStudentRegisterThesis sr inner join GucianStudent s on
sr.sid=s.id
			inner join Thesis t on t.serialNumber=sr.serial_no
			where sr.supid=@supervisorID
	union
		select s.firstName, s.lastName, t.years
		from NonGUCianStudentRegisterThesis sr inner join NonGucianStudent s on
sr.sid=s.id
			inner join Thesis t on t.serialNumber=sr.serial_no
			where sr.supid=@supervisorID
end
go
CREATE Proc SupViewProfile
	@supervisorID int
As
if(exists(select *
from Supervisor
where id=@supervisorID))
begin
	select u.id, u.email, u.password, s.name, s.faculty
	from PostGradUser u inner join Supervisor s on u.id=s.id
end
go
---------------------------------------
create proc UpdateSupProfile
	@supervisorID int,
	@name varchar(20),
	@faculty varchar(20)
as
update Supervisor
set name = @name, faculty = @faculty
where id = @supervisorID
go
create proc ViewAStudentPublications
	@StudentID int
as
	select P.*
	from GUCianStudentRegisterThesis GUC
		inner join Thesis T
		on GUC.serial_no = T.serialNumber
		inner join ThesisHasPublication TP
		on T.serialNumber = TP.serialNo
		inner join Publication P
		on P.id = TP.pubid
	where GUC.sid = @StudentID
union all
	select P.*
	from NonGUCianStudentRegisterThesis NON
		inner join Thesis T
		on NON.serial_no = T.serialNumber
		inner join ThesisHasPublication TP
		on T.serialNumber = TP.serialNo
		inner join Publication P
		on P.id = TP.pubid
	where NON.sid = @StudentID
go
create proc AddDefenseGucian
@ThesisSerialNo int , @DefenseDate Datetime , @DefenseLocation varchar(15)
as
insert into Defense
values(@ThesisSerialNo,@DefenseDate,@DefenseLocation,null)
UPDATE Thesis
	SET defenseDate = @DefenseDate
	WHERE THESIS.serialNumber = @ThesisSerialNo
go
create proc AddDefenseNonGucian
@ThesisSerialNo int , @DefenseDate Datetime , @DefenseLocation varchar(15)
as
declare @idOfStudent int
select @idOfStudent = sid
from NonGUCianStudentRegisterThesis
where serial_no = @ThesisSerialNo
if(not exists(select grade
from NonGucianStudentTakeCourse
where sid = @idOfStudent and grade < 50))
begin
insert into Defense
values(@ThesisSerialNo,@DefenseDate,@DefenseLocation,null)
UPDATE Thesis
	SET defenseDate = @DefenseDate
	WHERE THESIS.serialNumber = @ThesisSerialNo
end


go
create proc AddExaminer
	@ThesisSerialNo int ,
	@DefenseDate Datetime ,
	@ExaminerName
varchar(20),
	@Password varchar(30),
	@National bit,
	@fieldOfWork varchar(20)
as
IF (EXISTS(SELECT * FROM Defense WHERE Defense.date = @DefenseDate AND Defense.serialNumber = @ThesisSerialNo))
BEGIN
	insert into PostGradUser
	values(@ExaminerName, @Password)
	declare @id int
	set @id = SCOPE_IDENTITY()
	insert into Examiner
	values(@id, @ExaminerName, @fieldOfWork, @National)
	insert into ExaminerEvaluateDefense
	values(@DefenseDate, @ThesisSerialNo, @id, null)
END
ELSE
BEGIN
	RAISERROR('There is No Defense with this Thesis Serial Number and Defense Date. Please add the Defense Before adding the Examiner',11,1);
END


go
create proc CancelThesis
	@ThesisSerialNo int
as
if(exists(
select *
from GUCianStudentRegisterThesis
where serial_no = @ThesisSerialNo
))
begin
	if(exists(
	select *
	from GUCianProgressReport
	where thesisSerialNumber = @ThesisSerialNo
	))
	BEGIN
		declare @gucianEval int
		set @gucianEval = (
	select top 1
			eval
		from GUCianProgressReport
		where thesisSerialNumber = @ThesisSerialNo
		order by no desc
	)
		if(@gucianEval = 0)
		begin
			delete from Thesis where serialNumber = @ThesisSerialNo
		end
	END
	ELSE
	BEGIN
			RAISERROR('There are NO Progress Reports for Thesis. Thesis NOT Canceled!',11,1);
	END
end
else if(exists(
select *
from NonGUCianStudentRegisterThesis
where serial_no = @ThesisSerialNo
))
begin
	if(exists(
	select *
	from NonGUCianProgressReport
	where thesisSerialNumber = @ThesisSerialNo
	))
	BEGIN
		declare @nonGucianEval int
		set @nonGucianEval = (
	select top 1
			eval
		from NonGUCianProgressReport
		where thesisSerialNumber = @ThesisSerialNo
		order by no desc
	)
		if(@nonGucianEval = 0)
		begin
			delete from Thesis where serialNumber = @ThesisSerialNo
		end
	END
	ELSE
	BEGIN
		RAISERROR('There are NO Progress Reports for Thesis. Thesis NOT Canceled!',11,1);
	END
end
ELSE 
BEGIN 
	RAISERROR('Thesis Serial Number DOES NOT exist',11,1);
END
go
create proc AddGrade
	@ThesisSerialNo int
as
declare @grade decimal(4,2)
select @grade = grade
from Defense
where serialNumber = @ThesisSerialNo
update Thesis
set grade = @grade
where serialNumber = @ThesisSerialNo
go
create proc AddDefenseGrade
	@ThesisSerialNo int ,
	@DefenseDate Datetime ,
	@grade decimal(4,2)
as
update Defense
set grade = @grade
where serialNumber = @ThesisSerialNo and date = @DefenseDate
go
create proc AddCommentsGrade
	@ThesisSerialNo int ,
	@DefenseDate Datetime ,
	@comments varchar(300)
as
update ExaminerEvaluateDefense
set comment = @comments
where serialNo = @ThesisSerialNo and date = @DefenseDate
go
create proc viewMyProfile
	@studentId int
as
if(exists(
select *
from GucianStudent
where id = @studentId
))
begin
	select G.*, P.email
	from GucianStudent G
		inner join PostGradUser P
		on G.id = P.id
	where G.id = @studentId
end
else
begin
	select N.*, P.email
	from NonGucianStudent N
		inner join PostGradUser P
		on N.id = P.id
	where N.id = @studentId
end
go
create proc editMyProfile
	@studentID int,
	@firstName varchar(20),
	@lastName varchar(20),
	@password
varchar(30),
	@email
varchar(50)
,
	@address varchar(50),
	@type varchar(3)
as
update GucianStudent
set firstName = @firstName, lastName = @lastName, address = @address, type
= @type
where id = @studentID
update NonGucianStudent
set firstName = @firstName, lastName = @lastName, address = @address, type
= @type
where id = @studentID
update PostGradUser
set email = @email, password = @password
where id = @studentID
go
create proc addUndergradID
	@studentID int,
	@undergradID varchar(10)
as
update GucianStudent
set undergradID = @undergradID
where id = @studentID
go
create proc ViewCoursesGrades
	@studentID int
as
select grade
from NonGucianStudentTakeCourse
where sid = @studentID
go
create proc ViewCoursePaymentsInstall
	@studentID int
as
select P.id as 'Payment Number', P.amount as 'Amount of
Payment', P.fundPercentage as 'Percentage of
fund for payment', P.noOfInstallments as 'Number of installments',
	I.amount as 'Installment Amount', I.date as 'Installment date', I.done as
'Installment done or not'
from NonGucianStudentPayForCourse NPC
	inner join Payment P
	on NPC.paymentNo = P.id and NPC.sid = @studentID
	inner join Installment I
	on I.paymentId = P.id
go
create proc ViewThesisPaymentsInstall
	@studentID int
as
	select P.id as 'Payment Number', P.amount as 'Amount of Payment',
		P.fundPercentage as
'Fund', P.noOfInstallments as 'Number of installments',
		I.amount as 'Installment amount', I.date as 'Installment date', I.done as
'Installment done or not'
	from GUCianStudentRegisterThesis G
		inner join Thesis T
		on G.serial_no = T.serialNumber and G.sid = @studentID
		inner join Payment P
		on T.payment_id = P.id
		inner join Installment I
		on I.paymentId = P.id
union
	select P.id as 'Payment Number', P.amount as 'Amount of Payment',
		P.fundPercentage as
'Fund', P.noOfInstallments as 'Number of installments',
		I.amount as 'Installment amount', I.date as 'Installment date', I.done as
'Installment done or not'
	from NonGUCianStudentRegisterThesis NG
		inner join Thesis T
		on NG.serial_no = T.serialNumber and NG.sid = @studentID
		inner join Payment P
		on T.payment_id = P.id
		inner join Installment I
		on I.paymentId = P.id
go
create proc ViewUpcomingInstallments
	@studentID int
as
	select I.date as 'Date of Installment' , I.amount as 'Amount'
	from Installment I
		inner join NonGucianStudentPayForCourse NPC
		on I.paymentId = NPC.paymentNo and NPC.sid = @studentID and I.date >
CURRENT_TIMESTAMP
union
	select I.date as 'Date of Installment' , I.amount as 'Amount'
	from Thesis T
		inner join Payment P
		on T.payment_id = P.id
		inner join Installment I
		on I.paymentId = P.id
		inner join GUCianStudentRegisterThesis G
		on G.serial_no = T.serialNumber and G.sid = @studentID
	where I.date > CURRENT_TIMESTAMP
union
	select I.date as 'Date of Installment' , I.amount as 'Amount'
	from Thesis T
		inner join Payment P
		on T.payment_id = P.id
		inner join Installment I
		on I.paymentId = P.id
		inner join NonGUCianStudentRegisterThesis G
		on G.serial_no = T.serialNumber and G.sid = @studentID
	where I.date > CURRENT_TIMESTAMP
go
create proc ViewMissedInstallments
	@studentID int
as
	select I.date as 'Date of Installment' , I.amount as 'Amount'
	from Installment I
		inner join NonGucianStudentPayForCourse NPC
		on I.paymentId = NPC.paymentNo and NPC.sid = @studentID and I.date <
CURRENT_TIMESTAMP and
			I.done = '0'
union
	select I.date as 'Date of Installment' , I.amount as 'Amount'
	from Thesis T
		inner join Payment P
		on T.payment_id = P.id
		inner join Installment I
		on I.paymentId = P.id
		inner join GUCianStudentRegisterThesis G
		on G.serial_no = T.serialNumber and G.sid = @studentID
	where I.date < CURRENT_TIMESTAMP and I.done = '0'
union
	select I.date as 'Date of Installment' , I.amount as 'Amount'
	from Thesis T
		inner join Payment P
		on T.payment_id = P.id
		inner join Installment I
		on I.paymentId = P.id
		inner join NonGUCianStudentRegisterThesis G
		on G.serial_no = T.serialNumber and G.sid = @studentID
	where I.date < CURRENT_TIMESTAMP and I.done = '0'
go
create proc AddProgressReport
	@thesisSerialNo int,
	@progressReportDate date,
	@studentID int,
	@progressReportNo int
as
declare @gucian int
if(exists(
select id
from GucianStudent
where id = @studentID
))
begin
	set @gucian = '1'
end
else
begin
	set @gucian = '0'
end
if(@gucian = '1')
begin
	if(exists(select * from GUCianStudentRegisterThesis where GUCianStudentRegisterThesis.sid = @studentID and GUCianStudentRegisterThesis.serial_no = @thesisSerialNo))
	begin
		if(exists(select * from GUCianProgressReport where GUCianProgressReport.sid = @studentID and GUCianProgressReport.no = @progressReportNo))
		begin
			RAISERROR('PROGRESS REPORT WITH THIS NUMBER ALREADY EXISTS!',11,1);
		end
		else
		begin
			declare @startDate date
			declare @endDate date
			select @startDate = Thesis.startDate from Thesis where Thesis.serialNumber = @thesisSerialNo
			select @endDate = Thesis.endDate from Thesis where Thesis.serialNumber = @thesisSerialNo

			if(@progressReportDate>@startDate and @progressReportDate<@endDate)
			begin
				insert into GUCianProgressReport values(@studentID, @progressReportNo, @progressReportDate, null, null, null, @thesisSerialNo, null)
			end
			else
			begin
				RAISERROR('PLEASE ENTER A VALID DATE WITHIN THE START AND END OF YOUR THESIS',11,1);
			end
			
		end
	end
	else
	begin
		RAISERROR('Thesis Serial Number DOES NOT exist!',11,1);
	end	
end
else
begin
	if(exists(select * from NonGUCianStudentRegisterThesis where NonGUCianStudentRegisterThesis.sid = @studentID and NonGUCianStudentRegisterThesis.serial_no = @thesisSerialNo))
	begin
		if(exists(select * from NonGUCianProgressReport where NonGUCianProgressReport.sid = @studentID and NonGUCianProgressReport.no = @progressReportNo))
		begin
			RAISERROR('PROGRESS REPORT WITH THIS NUMBER ALREADY EXISTS!',11,1);
		end
		else
		begin
			insert into NonGUCianProgressReport values(@studentID, @progressReportNo, @progressReportDate, null, null, null, @thesisSerialNo, null)
		end
	end
	else
	begin
		RAISERROR('Thesis Serial Number DOES NOT exist!',11,1);
	end	
end
go
create proc FillProgressReport
	@thesisSerialNo int,
	@progressReportNo int,
	@state int,
	@description varchar(200),
	@studentID int
as
declare @gucian bit
if(exists(
select *
from GucianStudent
where id = @studentID
))
begin
	set @gucian = '1'
end
else
begin
	set @gucian = '0'
end
if(@gucian = '1')
begin
	if(exists(select * from GUCianStudentRegisterThesis where GUCianStudentRegisterThesis.sid = @studentID and GUCianStudentRegisterThesis.serial_no = @thesisSerialNo))
	begin
		if(exists(select * from GUCianProgressReport where GUCianProgressReport.sid = @studentID and GUCianProgressReport.no = @progressReportNo))
		begin
			update GUCianProgressReport
			set state = @state, description = @description, date = CURRENT_TIMESTAMP
			where thesisSerialNumber = @thesisSerialNo and sid = @studentID and no = @progressReportNo
		end
		else
		begin
			RAISERROR('PROGRESS REPORT WITH THIS NUMBER DOES NOT EXISTS!',11,1);
		end
	end
	else
	begin
		RAISERROR('Thesis Serial Number DOES NOT exist!',11,1);
	end	
end
else
begin
	if(exists(select * from NonGUCianStudentRegisterThesis where NonGUCianStudentRegisterThesis.sid = @studentID and NonGUCianStudentRegisterThesis.serial_no = @thesisSerialNo))
	begin
		if(exists(select * from NonGUCianProgressReport where NonGUCianProgressReport.sid = @studentID and NonGUCianProgressReport.no = @progressReportNo))
		begin
			update NonGUCianProgressReport
			set state = @state, description = @description, date = CURRENT_TIMESTAMP
			where thesisSerialNumber = @thesisSerialNo and sid = @studentID and no = @progressReportNo
		end
		else
		begin
			RAISERROR('PROGRESS REPORT WITH THIS NUMBER DOES NOT EXISTS!',11,1);
		end
	end
	else
	begin
		RAISERROR('Thesis Serial Number DOES NOT exist!',11,1);
	end	
end
go
create proc ViewEvalProgressReport
	@thesisSerialNo int,
	@progressReportNo int,
	@studentID int
as
	select eval
	from GUCianProgressReport
	where sid = @studentID and thesisSerialNumber = @thesisSerialNo and no =
@progressReportNo
union
	select eval
	from NonGUCianProgressReport
	where sid = @studentID and thesisSerialNumber = @thesisSerialNo and no =
@progressReportNo
go
create proc addPublication
	@title varchar(50),
	@pubDate datetime,
	@host varchar(50),
	@place varchar(50),
	@accepted bit
as
insert into Publication
values(@title, @pubDate, @place, @accepted, @host)
go
create proc linkPubThesis
	@PubID int,
	@thesisSerialNo int
as
insert into ThesisHasPublication values(@thesisSerialNo, @PubID)
go
create trigger deleteSupervisor
on Supervisor
instead of delete
as
delete from GUCianProgressReport where supid in (select id
from deleted)
delete from NonGUCianProgressReport where supid in (select id
from
	deleted)
delete from GUCianStudentRegisterThesis where supid in (select id
from
	deleted)
delete from NonGUCianStudentRegisterThesis where supid in (select id
from
	deleted)
delete from Supervisor where id in (select id
from deleted)
delete from PostGradUser where id in (select id
from deleted)

----------------------------------------------------------------------------	Extra Procedures	---------------------------------------------------------------------------- 



GO

create proc examinerRegister
	@ExaminerName VARCHAR (20),
	@fieldOfWork VARCHAR (100),
	@National BIT,
	@password varchar(20),
	@email varchar(50)
as
begin
	insert into PostGradUser
		(email,password)
	values(@email, @password);
	declare @id int;
	SELECT @id=SCOPE_IDENTITY();
	insert into Examiner
		(id, fieldOfWork, isNational, name)
	values
		(@id, @fieldOfWork, @National, @ExaminerName);
end

Go

create proc getIDFromMail
	@email varchar(50),
	@Id int output
as
begin
	select @Id = PostGradUser.id
	from PostGradUser
	where PostGradUser.email = @email
end	

go
create proc userLoginSimple
	@email varchar(50),
	@password varchar(20),
	@success bit output,
	@type int output,
	@id int output
as
begin
	exec getIDFromMail @email, @id output;
	exec userLogin @id, @password, @success output, @type output;
end

go
create proc ExaminerEditPassword
	@id int,
	@newPassword varchar(20)
as
begin
	update PostGradUser
	SET password = @newPassword
	where id=@id;
end
go

go
create proc ExaminerEditEmail
	@id int,
	@newEmail varchar(50)
as
begin
	update PostGradUser
	SET email = @newEmail
	where id=@id;
end
go

go
create proc ExaminerEditName
	@id int,
	@newName varchar(20)
as
begin
	update Examiner
	SET name = @newName
	where id=@id;
end
go

go
create proc ExaminerEditFieldOfWork
	@id int,
	@newFieldOfWork varchar(100)
as
begin
	update Examiner
	Set fieldOfWork=@newFieldOfWork
	where id=@id;
end
go

go
create proc ExaminerEditNational
	@id int,
	@newIsNational bit
as
begin
	update Examiner
	Set isNational = @newIsNational
	where id=@id;
end
go

go
create proc ExaminerViewGucian
	@id int
as
begin
	select T.title as 'Thesis Title', S.name as 'Supervisor Name', GS.firstName as 'Student F.Name', GS.lastName as 'Student L.Name'
	from ExaminerEvaluateDefense E inner join Thesis T on E.serialNo = T.serialNumber and E.examinerId = @id
		inner join GUCianStudentRegisterThesis G on G.serial_no = T.serialNumber
		inner join GucianStudent GS on GS.id = G.sid
		inner join Supervisor S on S.id = G.supid;
end
go

go
create proc ExaminerViewNonGucian
	@id int
as
begin
	select T.title as 'Thesis Title', S.name as 'Supervisor Name', GS.firstName as 'Student F.Name', GS.lastName as 'Student L.Name'
	from ExaminerEvaluateDefense E inner join Thesis T on E.serialNo = T.serialNumber and E.examinerId = @id
		inner join NonGUCianStudentRegisterThesis G on G.serial_no = T.serialNumber
		inner join NonGucianStudent GS on GS.id = G.sid
		inner join Supervisor S on S.id = G.supid;
end
go
GO
CREATE PROC ExaminerAddCommentsGrade
	@ThesisSerialNo INT,
	@DefenseDate DATETIME,
	@examinerId INT,
	@comments VARCHAR(300)
AS
UPDATE ExaminerEvaluateDefense
	SET comment = @comments
	WHERE ExaminerEvaluateDefense.serialNo = @ThesisSerialNo AND ExaminerEvaluateDefense.date = @DefenseDate AND ExaminerEvaluateDefense.examinerId = @examinerId
RETURN

GO
CREATE PROC ExaminerSearch
	@word varchar(100)
as
begin
	select *
	from Thesis T
	where T.title like '%' + @word + '%';
end
go

GO
CREATE PROC AdminIssueInstallPaymentMine
@paymentID INT, @InstallStartDate DATE
AS
if(exists(select * from Installment where paymentId = @paymentID))
begin
RAISERROR('Installments for this payment were already issued',11,1);
end
else if(not exists(select *
from Payment
where id=@paymentID))
begin
RAISERROR('This Payment does not exist',11,1);
end
else
begin
	DECLARE @i INT = 0;

	DECLARE @InstallmentDate DATE = @InstallStartDate;

	DECLARE @no_installments INT = 
		(SELECT Payment.noOfInstallments
		FROM Payment
		WHERE Payment.id = @paymentID);

	DECLARE @Installment_Amount DECIMAL(8,2) = (SELECT Payment.amount
		FROM Payment
		WHERE Payment.id = @paymentID) / @no_installments;

	WHILE @i < @no_installments
	BEGIN
		INSERT INTO Installment(date, paymentId, amount, done)
		VALUES (@InstallmentDate, @paymentID, @Installment_Amount, 0);
		SET @InstallmentDate = DATEADD(month, 6, @InstallmentDate);
		SET @i = @i + 1;
	END
	end
RETURN
go

CREATE PROC ExaminerViewProfile
	@id int
as 
begin 
select E.*,P.email,P.password from Examiner E inner join PostGradUser P on E.id = P.id
where E.id = @id
end
go

go 
create proc ExaminerSearchDefense
	@serialNo int,
	@date date,
	@success bit output
as
begin
if(Exists(Select * from Defense where serialNumber = @serialNo AND date = @date))

set @success = 1;
else 
set @success =0;
end
go

--gets whether student is gucian or no
CREATE PROC StudentUni
	@ID INT,
	@gucian BIT OUTPUT
AS
IF(EXISTS(SELECT * FROM GucianStudent WHERE id = @ID))
SET @gucian = 1
ELSE
SET @gucian = 0
RETURN

GO

create proc ViewCoursesAndGrades
	@studentID int
as
select code as 'course code' , grade
from NonGucianStudentTakeCourse inner join Course on NonGucianStudentTakeCourse.cid = Course.id
where sid = @studentID

GO

CREATE PROC ViewAllTheses
	@studentID int
AS
select Thesis.*
from GUCianStudentRegisterThesis inner join Thesis on GUCianStudentRegisterThesis.serial_no = Thesis.serialNumber
where GUCianStudentRegisterThesis.sid = @studentID

union

select Thesis.*
from NonGUCianStudentRegisterThesis inner join Thesis on NonGUCianStudentRegisterThesis.serial_no = Thesis.serialNumber
where NonGUCianStudentRegisterThesis.sid = @studentID

GO

GO
CREATE PROC CheckGucianForThesis
	@thesisSerialNumber INT,
	@defenseDate DateTime,
	@defenseLocation VarChar(15)
AS
DECLARE @gucian INT
IF (EXISTS(SELECT serial_no
		   FROM GUCianStudentRegisterThesis
		   WHERE serial_no = @thesisSerialNumber))
BEGIN
	IF (EXISTS(SELECT * FROM Defense WHERE Defense.date = @defenseDate AND Defense.serialNumber = @thesisSerialNumber))
	BEGIN
		RAISERROR('Defense for this Thesis with this Defense Date is Already Added!',11,1);
	END
	Else
	BEGIN
		EXEC AddDefenseGucian @thesisSerialNumber, @defenseDate, @defenseLocation;
	END
END
ELSE IF (EXISTS(SELECT serial_no
		   FROM NonGUCianStudentRegisterThesis
		   WHERE serial_no = @thesisSerialNumber))
BEGIN
	IF (EXISTS(SELECT * FROM Defense WHERE Defense.date = @defenseDate AND Defense.serialNumber = @thesisSerialNumber))
	BEGIN
		RAISERROR('Defense for this Thesis with this Defense Date is Already Added!',11,1);
	END
	ELSE
	BEGIN
		EXEC AddDefenseNonGucian @thesisSerialNumber, @defenseDate, @defenseLocation;
	END
END
ELSE
BEGIN
	RAISERROR('There is no Thesis with Thesis Serial Number!',11,1);
END


GO
CREATE PROC AddExistingExaminer
	@defenseDate DATETIME,
	@thesisSerialNumber INT,
	@examinerId INT
AS
IF (EXISTS(SELECT * FROM Defense WHERE Defense.date = @defenseDate AND Defense.serialNumber = @thesisSerialNumber))
BEGIN
	IF(not exists(SELECT * FROM ExaminerEvaluateDefense WHERE ExaminerEvaluateDefense.date = @defenseDate AND ExaminerEvaluateDefense.serialNo = @thesisSerialNumber AND ExaminerEvaluateDefense.examinerId =@examinerId))
	BEGIN
		IF (EXISTS(SELECT * FROM Examiner WHERE Examiner.id =@examinerId))
		BEGIN
			INSERT INTO ExaminerEvaluateDefense VALUES(@defenseDate, @thesisSerialNumber, @examinerId, null)
		END
		ELSE
		BEGIN
			RAISERROR('There is NO Examiner with this ID',11,1);
		END
	END
	ELSE
	BEGIN
		RAISERROR('This Examiner is ALREADY added to this Defense',11,1);
	END
END
ELSE
BEGIN
	RAISERROR('There is No Defense with this Thesis Serial Number and Defense Date. Please add the Defense Before adding the Examiner',11,1);
END

GO
CREATE PROC CheckStudentId
@studentId INT
AS
	IF (NOT EXISTS(SELECT id FROM GucianStudent WHERE GucianStudent.id = @StudentId UNION SELECT id FROM NonGucianStudent WHERE NonGucianStudent.id = @StudentId))
	BEGIN
		RAISERROR('There is NO Student with this ID',11,1);
	END

go
	Create proc postGradUserType
	@id int,
	@type int output
as
begin
		-- check user type 0-->Student,1-->Admin,2-->Supervisor ,3-->Examiner
		if exists(			select id
			from GucianStudent
			where id=@id
		union
			select id
			from
				NonGucianStudent
			where id=@id )
set @type=0
		if exists(select id
		from Admin
		where id=@id)
set @type=1
		if exists(select id
		from Supervisor
		where id=@id)
set @type=2
		if exists(select id
		from Examiner
		where id=@id)
set @type=3
	end
go
GO


create proc addLinkPub
	@title varchar(50),
	@pubDate datetime,
	@host varchar(50),
	@place varchar(50),
	@accepted bit,
	@studentID int,
	@thesisSerialNo int
as
if(exists(select * from NonGUCianStudentRegisterThesis where NonGUCianStudentRegisterThesis.sid = @studentID and NonGUCianStudentRegisterThesis.serial_no = @thesisSerialNo) or exists(select * from GUCianStudentRegisterThesis where GUCianStudentRegisterThesis.sid = @studentID and GUCianStudentRegisterThesis.serial_no = @thesisSerialNo))
begin
	exec addPublication @title , @pubdate , @host , @place , @accepted;
	declare @id int
	SELECT @id=ident_current('Publication')
	exec linkPubThesis @id , @thesisSerialNo;
end
else
begin
	RAISERROR('THIS THESIS EITHER DOES NOT EXIST OR DOES NOT BELONG TO YOU!',11,1);
end