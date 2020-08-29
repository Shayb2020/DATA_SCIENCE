library(dplyr)
library(odbc)
library(readr)
library(data.table)
library(tidyr)

# Q1. Count the number of students on each department
#colnames(df_departments)
names(df_departments)[names(df_departments) == "DepartmentId"] <- "DepartmentID"
#df_departments

df_merged <- merge(df_classrooms, df_courses, by="CourseId")
df_merged <- merge(df_students, df_merged, by="StudentId")
df_merged <- merge(df_departments, df_merged, by="DepartmentID")

ST_Dep <- setDT(df_Dep_stu)[, .(Num_of_Stu = uniqueN(paste(DepartmentID, StudentId))) , by = DepartmentName]
ST_Dep

## Q2. How many students have each course of the English department and the total number of students in the department?

Stu_by_Eng_C <- df_merged %>% 
                group_by (CourseId , CourseName) %>% 
                filter(DepartmentID == 1) %>%
                summarise(Stu_Num = n_distinct(StudentId))

Stu_by_Eng_T <- df_merged %>%
                group_by (DepartmentID) %>%
                filter(DepartmentID == 1) %>%
                summarise(Stu_Num = n_distinct(StudentId))

Eng_Dep_Stu <- Stu_by_Eng_T[,2, drop=FALSE]

Eng_Dep_Stu_T <- merge(Eng_Dep_Stu, Stu_by_Eng_C, by = 'Stu_Num', all=TRUE)

Eng_Dep_Stu_T[4,3] = "TOTAL"

Eng_Dep_Stu_T[4,2] = ""

Eng_Dep_Stu_T

##Q3. How many small (<22 students) and large (22+ students) classrooms are needed for the Science department?

Stu_by_Sci <- df_merged %>%
              group_by (CourseId) %>%
              filter(DepartmentID == 2) %>%
              summarise(Stu_Num = n_distinct(StudentId))

Stu_by_Sci <- Stu_by_Sci %>%
              mutate(C_Type = ifelse(is.na(Stu_Num)==TRUE, "No Age",
              ifelse(Stu_Num >=22, " Big", " Small")))

Sci_cla_T <-  Stu_by_Sci %>%
              filter(!is.na(CourseId)) %>%
              group_by(C_Type) %>%
              summarise(N_Class_Type = n_distinct(CourseId))
Sci_cla_T

##Q4. A feminist student claims that there are more male than female in the College. Justify if the argument is correct

Fem_VS_Mal <- df_merged %>% 
              filter(!is.na(StudentId)) %>%
              group_by (Gender) %>% 
              summarise(Stu_Num = n_distinct(StudentId))
Fem_VS_Mal

##Q5. For which courses the percentage of male/female students is over 70%?

Stu_gen_Course_T <- df_merged %>% 
                    group_by(CourseId) %>% 
                    summarise(T_Stu_Num = n())

Stu_gen_Course  <-  df_merged %>% 
                    group_by(CourseId,Gender) %>% 
                    summarise(Stu_Num = n_distinct(StudentId))

C_O_Se <- merge (Stu_gen_Course, Stu_gen_Course_T, by = 'CourseId', all = TRUE)                 

C_O_Se <- C_O_Se %>%
          mutate( Over_70 = C_O_Se$Stu_Num/C_O_Se$T_Stu_Num * 100)

R_O_70 <- C_O_Se %>% 
          filter (Over_70 > 70)

R_O_70 <- left_join(R_O_70, df_courses, by='CourseId')

select (R_O_70, CourseId, CourseName, Gender, Over_70)

##Q6. For each department, how many students passed with a grades over 80?

C_D <- left_join(df_courses, df_departments, by = 'DepartmentID')

C_D_C <- left_join(C_D, df_classrooms, by = 'CourseId')

Above_80P <- C_D_C %>% 
             filter ((degree>=80))

S_B_D <-     Above_80P %>% 
             group_by(DepartmentID, DepartmentName) %>% 
             summarise(Stu_Num = n_distinct(StudentId))

Dep_T_S <-   C_D_C %>% 
             group_by (DepartmentID) %>% 
             summarise(Stu_Num = n_distinct(StudentId))

S_T     <-   Dep_T_S[,2, drop=FALSE]

S_B_D   <-   merge (S_B_D, Dep_T_S, by = 'DepartmentID', all = TRUE)

S_B_D   <-   S_B_D %>%
             mutate (ratio = S_B_D$Stu_Num.x/Dep_T_S$Stu_Num * 100)

select (S_B_D, DepartmentID, DepartmentName, Stu_Num.x, Stu_Num.y,ratio)

## Q7. For each department, how many students passed with a grades under 60?

Bellow60P <- C_D_C %>% 
             filter ((degree<60))

S_B_D     <- Bellow60P %>% 
             group_by(DepartmentID, DepartmentName) %>% 
             summarise(Stu_Num = n_distinct(StudentId))

Dep_T_S   <- C_D_C %>% 
             group_by (DepartmentID) %>% 
             summarise(Stu_Num = n_distinct(StudentId))

S_T       <- Dep_T_S[,2, drop=FALSE]

S_B_D     <- merge (S_B_D, Dep_T_S, by = 'DepartmentID', all = TRUE)

S_B_D     <- S_B_D %>%
             mutate (ratio = S_B_D$Stu_Num.x/Dep_T_S$Stu_Num * 100)

select (S_B_D, DepartmentID, DepartmentName, Stu_Num.x, Stu_Num.y,ratio)

## Q8. Rate the teachers by their average student's grades (in descending order).

df_merged <- left_join (df_teachers,df_merged, by = 'TeacherId')

teacher_s_average <- df_merged %>%
                     group_by ( FirstName , LastName) %>% 
                     summarise(avg=mean(degree, na.rm=FALSE))%>% 
                     arrange(desc(avg))

teacher_s_average

## Q9. Create a dataframe showing the courses, departments they are associated with, the teacher in each course, and the number of students enrolled in the course (for each course, department and teacher show the names).
course_list <- df_merged %>%
               group_by ( CourseId, CourseName, DepartmentName ,FirstName.x, LastName.x ) %>% 
               summarise(student_count = n_distinct(StudentId)) 

course_list  

## Q10. Create a dataframe showing the students, the number of courses they take, 
##the average of the grades per class, and their overall average (for each student show the student name).

student_courses <- df_merged %>%
                   group_by ( StudentId, FirstName, LastName, degree) %>% 
                   summarise(courses = n_distinct(CourseId))

student_courses[4] <- sapply(student_courses[4],as.numeric)

student_courses <- S_CL_C_D %>%
                   group_by(StudentId) %>%
                   mutate(avg = mean(degree))

Dep_Avg_degree  <- S_CL_C_D %>%
                   pivot_wider(names_from = DepartmentName,
                   values_from = degree,
                   values_fn = list( degree = mean))

Dep_Avg_degree  <- select(Dep_Avg_degree, StudentId,  Cou_courses.x)

Courses_Count   <- S_CL_C_D %>%
                   group_by ( StudentId, FirstName,LastName) %>%
                   summarise ( Cou_courses = n_distinct(CourseId))

Stu_Dep_Avg     <- merge ( Courses_Count, Dep_Avg_degree, by = "StudentId", all = FALSE )

Stu_Dep_Avg_n   <- inner_join ( Stu_Dep_Avg, student_courses, by = "StudentId", all = TRUE )

Best_Stu        <- select ( Stu_Dep_Avg_n, StudentId, FirstName, LastName,Cou_courses,DepartmentName,degree, avg)

Best_Stu_n      <- Best_Stu %>%
                   pivot_wider(names_from = DepartmentName,
                   values_from = degree,
                   values_fn = list( degree = mean))

Best_Stu_n      <- Best_Stu_n[order(Best_Stu_n$avg, decreasing = TRUE),]

Best_Stu_n