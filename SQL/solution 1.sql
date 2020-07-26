
-----------------------------------------------------
/* Num Stu by Dep */
-----------------------------------------------------
select   DepartmentName
		,count  (studentid)  as Stu_Num
from Departments
		inner join Courses on (Departments.DepartmentId = Courses.DepartmentID)
		inner join Classrooms on Courses.CourseId = Classrooms.CourseId
group by DepartmentName 
order by Stu_Num desc
-----------------------------------------------------
/* Num Stu by Eng Courses */
-----------------------------------------------------
Select count (cast ( StudentId as int) ) as Eng_STU , 'SUM_Eng_STU' as Dep_Name
from Courses 
inner join classrooms on courses.courseId = classrooms.courseId
where DepartmentID = 1

Select courseName ,count (CAST ( StudentId as int)) as Eng_STU 
from Courses
 		inner join classrooms on courses.courseId = classrooms.courseId
		where DepartmentID = 1
Group by CourseName
order by Eng_STU Desc
-----------------------------------------------------
/* Num of big & small classes by Sience Courses*/
-----------------------------------------------------
SELECT dbo.courses.CourseName
	,CASE WHEN 
	count (StudentId) >= 22 
	THEN 'Big Class' 
	ELSE 'Small Class' 
	END As 'Size_C'

	into #Sience_class_Sizes
	from Courses
 		inner join classrooms on courses.courseId = classrooms.courseId
		where DepartmentID = 2
	Group by CourseName

    SELECT cast (Size_C as varchar)
	   ,COUNT (coursename) AS num_of_classes
    FROM #Sience_class_Sizes
GROUP BY Size_c
-----------------------------------------------------
/*סטודנטית שהיא פעילה פמיניסטית טוענת שהמכללה מעדיפה לקבל יותר גברים מאשר נשים. תבדקו האם הטענה מוצדקת (מבחינת כמותית, לא סטטיסטית).*/
-----------------------------------------------------
select 
	count( case 
			when gender = 'F' then 1 
			end) as FemaleCount,
	count( case 
			when gender = 'M' then 1 
			end) as MaleCount,
	count(*) as Total
from Students
-----------------------------------------------------
/* courses with 70% female/male*/
-----------------------------------------------------
select C.CourseName, C.Female, C.Male, C.Total from (
	select coursename,
		   count( case 
					when gender = 'F' then 1 
				  end) as Female,
		   count( case 
					when gender = 'M' then 1 
				  end) as Male,
		   count(*) as Total
	from Students
			join Classrooms on Classrooms.StudentId = Students.StudentId
			join Courses on Courses.courseId = classrooms.CourseId
	group by coursename ) as C
where  ( C.Male * 100 / C.Total >= 70) or ( ( C.Female * 100 / C.Total >= 70) );
-------------------------------------------------------------------------------------
/*בכל אחד מהיחידות (מחלקות), כמה סטודנטים (מספר ואחוזים) עברו עם ציון מעל 80?*/
-------------------------------------------------------------------------------------
select B.DepartmentName, 
		B.students_with_avg_above_80,
		B.students_with_avg_above_80 * 100 / B.total_students as precentage, 
		B.total_students 
from 
(
	select A.DepartmentName, count( case when A.Average_grade > 80 then 1 end) as students_with_avg_above_80, count(*) as total_students
	from
	(
		select  Departments.DepartmentName, Students.StudentId, AVG( Classrooms.degree ) as Average_grade
		from Classrooms 
				join Courses on Courses.courseId = classrooms.CourseId
				join Students on Classrooms.StudentId = Students.StudentId
				join Departments on Departments.DepartmentId = Courses.DepartmentID
		group by Departments.DepartmentName, Students.StudentId
	) as A
	group by A.DepartmentName
) B
-------------------------------------------------------------------------------------------
/*בכל אחד מהיחידות (מחלקות), כמה סטודנטים (מספר ואחוזים) לא עברו (ציון מתחת ל-60) ?*/
-------------------------------------------------------------------------------------------
select B.DepartmentName, 
		B.students_with_avg_below_60,
		B.students_with_avg_below_60 * 100 / B.total_students as precentage, 
		B.total_students 
from 
(
	select A.DepartmentName, count( case when A.Average_grade < 60 then 1 end) as students_with_avg_below_60, count(*) as total_students
	from
	(
		select  Departments.DepartmentName, Students.StudentId, AVG( Classrooms.degree ) as Average_grade
		from Classrooms 
				join Courses on Courses.courseId = classrooms.CourseId
				join Students on Classrooms.StudentId = Students.StudentId
				join Departments on Departments.DepartmentId = Courses.DepartmentID
		group by Departments.DepartmentName, Students.StudentId
	) as A
	group by A.DepartmentName
) B
--------------------------------------------------------------------
/*תדרגו את המורים לפי ממוצע הציון של הסטודנטים מהגבוהה לנמוך*/
--------------------------------------------------------------------
select  Teachers.FirstName, Teachers.LastName, AVG( Classrooms.degree ) as Average_grade
		from Classrooms 
				join Courses on Courses.courseId = classrooms.CourseId
				join Students on Classrooms.StudentId = Students.StudentId
				join Teachers on Teachers.TeacherId = Courses.TeacherId
		group by Teachers.FirstName, Teachers.LastName
		order by Average_grade desc


----------------------------------------------------------
 /*תייצרו VIEW המראה את הקורסים, היחידות (מחלקות) עליהם משויכים, המרצה בכל קורס ומספר התלמידים רשומים בקורס*/
 ---------------------------------------------------------
 view CollegeV as 
	   select D.DepartmentName,
			   C.CourseName,
			   Teachers.firstname,
			   Teachers.LastName,
			   sum(Classrooms.StudentId)
	   from Departments as D
				join Courses as C on Courses.departmentid = departments. departmentid
				join teachers as T on Teachers.TeacherId = courses.TeacherId
				join Classrooms as R on Classrooms.CourseId = Courses.CourseId
		group by Departments.DepartmentName,
			   Courses.CourseName,
			   Teachers.firstname,
			   Teachers.LastName

select * from 'Collegev';
---------------------------------------------------------
/*תייצרו VIEW המראה את התלמידים, מס' הקורסים שהם לוקחים, הממוצע של הציונים לפי יחידה (מחלקה) והממוצע הכוללת שלהם.*/
---------------------------------------------------------

create view StudentView as
	select 
		S.StudentID,
		S.FirstName,
		S.LastName,
		S.Student_Average,
		X.DepartmentName,
		count(X.CourseId) As Num_of_courses,
		avg(X.degree) as Department_Avg
	from  ( 
		select
			S.StudentId,
			S.FirstName,
			S.LastName,
			AVG(case when R.Degree is NULL then 0 else R.degree end) as Student_Average
			from Students as S
			left join Classrooms as R on S.StudentId = R.StudentId
			group by S.StudentId, S.FirstName, S.LastName 
		) as S
	left join (
			select Classrooms.StudentID, Classrooms.degree, Classrooms.CourseID, Courses.DepartmentID , Departments.DepartmentName
				from Classrooms
				join Courses on Classrooms.CourseId = Courses.CourseId
				join Departments on Departments.DepartmentId = Courses.DepartmentID 
			) as X on S.StudentId = X.StudentId
	group by  S.StudentId, S.FirstName, S.LastName, S.Student_Average, X.DepartmentName


