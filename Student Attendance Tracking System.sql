-- ============================================================
-- SECTION 1: CLEANUP (Drop existing objects if re-running)
-- ============================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_student_id';         EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_course_id';          EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_instructor_id';      EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_enrollment_id';      EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_session_id';         EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_attendance_id';      EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE attendance_records CASCADE CONSTRAINTS';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE class_sessions CASCADE CONSTRAINTS';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE enrollments CASCADE CONSTRAINTS';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE courses CASCADE CONSTRAINTS';             EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE instructors CASCADE CONSTRAINTS';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE students CASCADE CONSTRAINTS';            EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
-- ============================================================
-- SECTION 2: SEQUENCES (Auto-increment simulation for Oracle 11g)
-- ============================================================
CREATE SEQUENCE seq_student_id    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_course_id     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_instructor_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_enrollment_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_session_id    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_attendance_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
 
 
-- ============================================================
-- SECTION 3: TABLE DEFINITIONS
-- ============================================================
 
-- Table 1: STUDENTS
CREATE TABLE students (
    student_id     NUMBER          PRIMARY KEY,
    student_number VARCHAR2(15)    NOT NULL UNIQUE,
    first_name     VARCHAR2(50)    NOT NULL,
    last_name      VARCHAR2(50)    NOT NULL,
    email          VARCHAR2(100)   NOT NULL UNIQUE,
    phone          VARCHAR2(20),
    date_of_birth  DATE            NOT NULL,
    gender         CHAR(1)         NOT NULL CHECK (gender IN ('M','F','O')),
    major          VARCHAR2(100)   DEFAULT 'Undeclared',
    enrollment_year NUMBER(4)      NOT NULL CHECK (enrollment_year BETWEEN 2000 AND 2099),
    gpa            NUMBER(3,2)     CHECK (gpa BETWEEN 0.00 AND 4.00),
    is_active      CHAR(1)         DEFAULT 'Y' NOT NULL CHECK (is_active IN ('Y','N'))
);
 
-- Table 2: INSTRUCTORS
CREATE TABLE instructors (
    instructor_id  NUMBER          PRIMARY KEY,
    first_name     VARCHAR2(50)    NOT NULL,
    last_name      VARCHAR2(50)    NOT NULL,
    email          VARCHAR2(100)   NOT NULL UNIQUE,
    phone          VARCHAR2(20),
    department     VARCHAR2(100)   NOT NULL,
    hire_date      DATE            NOT NULL,
    title          VARCHAR2(50)    DEFAULT 'Lecturer' CHECK (title IN ('Lecturer','Assistant Professor','Associate Professor','Professor'))
);
 
-- Table 3: COURSES
CREATE TABLE courses (
    course_id      NUMBER          PRIMARY KEY,
    course_code    VARCHAR2(15)    NOT NULL UNIQUE,
    course_name    VARCHAR2(150)   NOT NULL,
    credits        NUMBER(1)       NOT NULL CHECK (credits BETWEEN 1 AND 6),
    department     VARCHAR2(100)   NOT NULL,
    instructor_id  NUMBER          NOT NULL,
    semester       VARCHAR2(20)    NOT NULL CHECK (semester IN ('Fall','Spring','Summer')),
    academic_year  NUMBER(4)       NOT NULL CHECK (academic_year BETWEEN 2000 AND 2099),
    room           VARCHAR2(20),
    max_capacity   NUMBER(3)       DEFAULT 30 CHECK (max_capacity BETWEEN 1 AND 500),
    CONSTRAINT fk_course_instructor FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id)
);
 
-- Table 4: ENROLLMENTS
CREATE TABLE enrollments (
    enrollment_id  NUMBER          PRIMARY KEY,
    student_id     NUMBER          NOT NULL,
    course_id      NUMBER          NOT NULL,
    enroll_date    DATE            DEFAULT SYSDATE NOT NULL,
    grade          CHAR(2)         CHECK (grade IN ('A+','A','A-','B+','B','B-','C+','C','C-','D','F','W','I')),
    status         VARCHAR2(15)    DEFAULT 'Active' CHECK (status IN ('Active','Dropped','Completed','Withdrawn')),
    CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_enroll_course  FOREIGN KEY (course_id)  REFERENCES courses(course_id),
    CONSTRAINT uq_enroll         UNIQUE (student_id, course_id)
);
 
-- Table 5: CLASS_SESSIONS
CREATE TABLE class_sessions (
    session_id     NUMBER          PRIMARY KEY,
    course_id      NUMBER          NOT NULL,
    session_date   DATE            NOT NULL,
    start_time     VARCHAR2(8)     NOT NULL,
    end_time       VARCHAR2(8)     NOT NULL,
    topic          VARCHAR2(200),
    session_type   VARCHAR2(20)    DEFAULT 'Lecture' CHECK (session_type IN ('Lecture','Lab','Tutorial','Exam','Workshop')),
    is_cancelled   CHAR(1)         DEFAULT 'N' CHECK (is_cancelled IN ('Y','N')),
    notes          VARCHAR2(500),
    CONSTRAINT fk_session_course FOREIGN KEY (course_id) REFERENCES courses(course_id),
    CONSTRAINT uq_session        UNIQUE (course_id, session_date, start_time)
);
 
-- Table 6: ATTENDANCE_RECORDS
CREATE TABLE attendance_records (
    attendance_id  NUMBER          PRIMARY KEY,
    session_id     NUMBER          NOT NULL,
    student_id     NUMBER          NOT NULL,
    status         VARCHAR2(15)    DEFAULT 'Present' NOT NULL CHECK (status IN ('Present','Absent','Late','Excused')),
    check_in_time  VARCHAR2(8),
    remarks        VARCHAR2(300),
    recorded_by    VARCHAR2(100),
    record_date    DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_attend_session FOREIGN KEY (session_id)  REFERENCES class_sessions(session_id),
    CONSTRAINT fk_attend_student FOREIGN KEY (student_id)  REFERENCES students(student_id),
    CONSTRAINT uq_attend         UNIQUE (session_id, student_id)
);
 
 
-- ============================================================
-- SECTION 3B: AUTO-INCREMENT TRIGGERS
-- (Oracle 11g does not support sequence DEFAULT in CREATE TABLE;
--  BEFORE INSERT triggers are the standard workaround.)
-- ============================================================
 
CREATE OR REPLACE TRIGGER trg_students_bi
BEFORE INSERT ON students
FOR EACH ROW
BEGIN
    IF :NEW.student_id IS NULL THEN
        SELECT seq_student_id.NEXTVAL INTO :NEW.student_id FROM DUAL;
    END IF;
END;
/
 
CREATE OR REPLACE TRIGGER trg_instructors_bi
BEFORE INSERT ON instructors
FOR EACH ROW
BEGIN
    IF :NEW.instructor_id IS NULL THEN
        SELECT seq_instructor_id.NEXTVAL INTO :NEW.instructor_id FROM DUAL;
    END IF;
END;
/
 
CREATE OR REPLACE TRIGGER trg_courses_bi
BEFORE INSERT ON courses
FOR EACH ROW
BEGIN
    IF :NEW.course_id IS NULL THEN
        SELECT seq_course_id.NEXTVAL INTO :NEW.course_id FROM DUAL;
    END IF;
END;
/
 
CREATE OR REPLACE TRIGGER trg_enrollments_bi
BEFORE INSERT ON enrollments
FOR EACH ROW
BEGIN
    IF :NEW.enrollment_id IS NULL THEN
        SELECT seq_enrollment_id.NEXTVAL INTO :NEW.enrollment_id FROM DUAL;
    END IF;
END;
/
 
CREATE OR REPLACE TRIGGER trg_sessions_bi
BEFORE INSERT ON class_sessions
FOR EACH ROW
BEGIN
    IF :NEW.session_id IS NULL THEN
        SELECT seq_session_id.NEXTVAL INTO :NEW.session_id FROM DUAL;
    END IF;
END;
/
 
CREATE OR REPLACE TRIGGER trg_attendance_bi
BEFORE INSERT ON attendance_records
FOR EACH ROW
BEGIN
    IF :NEW.attendance_id IS NULL THEN
        SELECT seq_attendance_id.NEXTVAL INTO :NEW.attendance_id FROM DUAL;
    END IF;
END;
/
 
-- ============================================================
-- SECTION 4: INDEXES
-- ============================================================
-- Index 1: Speed up attendance lookups by student
CREATE INDEX idx_attend_student ON attendance_records(student_id);
 
-- Index 2: Speed up session queries by course and date
CREATE INDEX idx_session_course_date ON class_sessions(course_id, session_date);
 
-- Index 3: Enrollment lookups by course
CREATE INDEX idx_enroll_course ON enrollments(course_id);
 
-- Index 4: Student last name search
CREATE INDEX idx_student_lastname ON students(last_name);
 
 
-- ============================================================
-- SECTION 5: DATA POPULATION
-- ============================================================
 
-- ---- INSTRUCTORS (10 records) ----
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Ahmed',   'Hassan',    'a.hassan@university.edu',    '555-0101', 'Computer Science',    DATE '2010-09-01', 'Professor');
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Sara',    'El-Masry',  's.elmasry@university.edu',   '555-0102', 'Mathematics',         DATE '2015-02-15', 'Associate Professor');
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Mohamed', 'Khalil',    'm.khalil@university.edu',    '555-0103', 'Physics',             DATE '2012-08-20', 'Assistant Professor');
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Nadia',   'Fawzy',     'n.fawzy@university.edu',     '555-0104', 'English Literature',  DATE '2018-01-10', 'Lecturer');
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Omar',    'Ibrahim',   'o.ibrahim@university.edu',   '555-0105', 'Computer Science',    DATE '2011-04-05', 'Professor');
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Layla',   'Mansour',   'l.mansour@university.edu',   '555-0106', 'Chemistry',           DATE '2016-09-01', 'Associate Professor');
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Karim',   'Nasser',    'k.nasser@university.edu',    '555-0107', 'History',             DATE '2009-03-22', 'Professor');
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Hana',    'Saad',      'h.saad@university.edu',      '555-0108', 'Economics',           DATE '2020-08-15', 'Lecturer');
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Youssef', 'Adel',      'y.adel@university.edu',      '555-0109', 'Mathematics',         DATE '2014-01-30', 'Assistant Professor');
INSERT INTO instructors (first_name, last_name, email, phone, department, hire_date, title)
VALUES ('Rania',   'Gouda',     'r.gouda@university.edu',     '555-0110', 'Computer Science',    DATE '2019-07-01', 'Lecturer');
 
 
-- ---- STUDENTS (15 records) ----
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2021-001', 'Ali',       'Mahmoud',   'ali.mahmoud@student.edu',   '555-1001', DATE '2002-05-14', 'M', 'Computer Science',   2021, 3.75);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2021-002', 'Mona',      'Farouk',    'mona.farouk@student.edu',   '555-1002', DATE '2001-11-22', 'F', 'Mathematics',         2021, 3.90);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2022-001', 'Tamer',     'Samir',     'tamer.samir@student.edu',   '555-1003', DATE '2003-03-08', 'M', 'Physics',             2022, 3.20);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2022-002', 'Dina',      'Hassan',    'dina.hassan@student.edu',   '555-1004', DATE '2002-07-19', 'F', 'Computer Science',   2022, 2.85);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2022-003', 'Khaled',    'Ibrahim',   'khaled.ibrahim@student.edu','555-1005', DATE '2003-01-25', 'M', 'Economics',           2022, 3.50);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2023-001', 'Nour',      'Mostafa',   'nour.mostafa@student.edu',  '555-1006', DATE '2004-09-11', 'F', 'English Literature',  2023, 3.65);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2023-002', 'Sherif',    'Rashad',    'sherif.rashad@student.edu', '555-1007', DATE '2004-04-30', 'M', 'Chemistry',           2023, 2.70);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2023-003', 'Yasmine',   'Kamal',     'yasmine.kamal@student.edu', '555-1008', DATE '2003-12-05', 'F', 'Mathematics',         2023, 3.88);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2023-004', 'Hassan',    'Lotfy',     'hassan.lotfy@student.edu',  '555-1009', DATE '2004-06-17', 'M', 'Computer Science',   2023, 3.10);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2024-001', 'Reem',      'Talaat',    'reem.talaat@student.edu',   '555-1010', DATE '2005-02-28', 'F', 'History',             2024, 3.45);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2024-002', 'Amr',       'Galal',     'amr.galal@student.edu',     '555-1011', DATE '2005-08-03', 'M', 'Physics',             2024, 2.95);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2024-003', 'Salma',     'Wahid',     'salma.wahid@student.edu',   '555-1012', DATE '2004-10-21', 'F', 'Economics',           2024, 3.60);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2024-004', 'Ibrahim',   'Nazih',     'ibrahim.nazih@student.edu', '555-1013', DATE '2005-05-09', 'M', 'Computer Science',   2024, 3.30);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2024-005', 'Farida',    'Osman',     'farida.osman@student.edu',  '555-1014', DATE '2005-11-16', 'F', 'Mathematics',         2024, 3.80);
INSERT INTO students (student_number, first_name, last_name, email, phone, date_of_birth, gender, major, enrollment_year, gpa)
VALUES ('STU-2024-006', 'Ziad',      'Barakat',   'ziad.barakat@student.edu',  '555-1015', DATE '2006-01-07', 'M', 'History',             2024, 2.50);
 
 
-- ---- COURSES (10 records) ----
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('CS301',  'Data Structures and Algorithms',    3, 'Computer Science',   1, 'Spring', 2024, 'CS-Lab-1',  35);
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('MATH201','Calculus II',                       4, 'Mathematics',        2, 'Spring', 2024, 'B-201',     40);
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('PHY101', 'Introduction to Physics',           3, 'Physics',            3, 'Spring', 2024, 'B-105',     50);
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('ENG102', 'Academic Writing',                  3, 'English Literature', 4, 'Spring', 2024, 'C-302',     30);
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('CS401',  'Database Systems',                  3, 'Computer Science',   5, 'Spring', 2024, 'CS-Lab-2',  30);
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('CHEM101','General Chemistry',                 3, 'Chemistry',          6, 'Spring', 2024, 'A-101',     45);
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('HIST201','Modern World History',              3, 'History',            7, 'Spring', 2024, 'C-201',     35);
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('ECON201','Microeconomics',                    3, 'Economics',          8, 'Spring', 2024, 'B-305',     40);
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('MATH101','Pre-Calculus',                      3, 'Mathematics',        9, 'Spring', 2024, 'B-101',     50);
INSERT INTO courses (course_code, course_name, credits, department, instructor_id, semester, academic_year, room, max_capacity)
VALUES ('CS201',  'Programming Fundamentals',          3, 'Computer Science',  10, 'Spring', 2024, 'CS-Lab-3',  30);
 
 
-- ---- ENROLLMENTS (15 records) ----
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (1, 1, DATE '2024-01-15', 'A',  'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (1, 5, DATE '2024-01-15', 'B+', 'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (2, 2, DATE '2024-01-16', 'A+', 'Completed');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (3, 3, DATE '2024-01-16', 'B',  'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (4, 1, DATE '2024-01-17', 'C+', 'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (4,10, DATE '2024-01-17', NULL, 'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (5, 8, DATE '2024-01-17', 'B-', 'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (6, 4, DATE '2024-01-18', 'A',  'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (7, 6, DATE '2024-01-18', 'C',  'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (8, 2, DATE '2024-01-18', 'A-', 'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (9, 1, DATE '2024-01-19', 'B+', 'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (10, 7, DATE '2024-01-19', NULL, 'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (11, 3, DATE '2024-01-20', 'D',  'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (12, 8, DATE '2024-01-20', 'A',  'Active');
INSERT INTO enrollments (student_id, course_id, enroll_date, grade, status)
VALUES (13, 5, DATE '2024-01-20', NULL, 'Dropped');
 
 
-- ---- CLASS SESSIONS (12 records for courses 1 and 5) ----
-- Sessions for CS301 (course_id = 1)
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (1, DATE '2024-02-05', '09:00', '10:30', 'Introduction to Complexity (Big-O)', 'Lecture');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (1, DATE '2024-02-12', '09:00', '10:30', 'Arrays and Linked Lists', 'Lecture');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (1, DATE '2024-02-19', '09:00', '10:30', 'Stacks and Queues', 'Lecture');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (1, DATE '2024-02-26', '09:00', '10:30', 'Lab: Linked List Implementation', 'Lab');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (1, DATE '2024-03-04', '09:00', '10:30', 'Trees: Binary Search Trees', 'Lecture');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (1, DATE '2024-03-11', '09:00', '10:30', 'Midterm Examination', 'Exam');
 
-- Sessions for CS401 (course_id = 5)
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (5, DATE '2024-02-05', '11:00', '12:30', 'Introduction to Relational Databases', 'Lecture');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (5, DATE '2024-02-12', '11:00', '12:30', 'SQL Basics: DDL and DML', 'Lecture');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (5, DATE '2024-02-19', '11:00', '12:30', 'Advanced SQL: Joins and Subqueries', 'Lecture');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (5, DATE '2024-02-26', '11:00', '12:30', 'Lab: Oracle SQL Workshop', 'Lab');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (5, DATE '2024-03-04', '11:00', '12:30', 'Normalization and ER Diagrams', 'Lecture');
INSERT INTO class_sessions (course_id, session_date, start_time, end_time, topic, session_type)
VALUES (5, DATE '2024-03-11', '11:00', '12:30', 'PL/SQL Introduction', 'Lecture');
 
 
-- ---- ATTENDANCE RECORDS (20 records) ----
-- Students enrolled in CS301: student_ids 1, 4, 9  (enrollment_ids 1, 5, 11)
-- Sessions 1-6 are for course 1
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (1, 1, 'Present', '09:02', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (1, 4, 'Late',    '09:20', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (1, 9, 'Present', '08:58', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (2, 1, 'Present', '09:01', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (2, 4, 'Absent',  NULL,    'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (2, 9, 'Present', '09:00', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (3, 1, 'Present', '09:03', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (3, 4, 'Present', '09:05', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (3, 9, 'Excused', NULL,    'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, remarks, recorded_by)
VALUES (4, 1, 'Present', '09:00', 'Completed lab exercise', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (4, 4, 'Present', '09:10', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (4, 9, 'Present', '09:02', 'Prof. Hassan');
-- Students in CS401: student_ids 1, 13  (enrollments 2, 15)
-- Sessions 7-12 are for course 5
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (7, 1, 'Present', '11:00', 'Prof. Ibrahim');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (8, 1, 'Present', '10:58', 'Prof. Ibrahim');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (9, 1, 'Absent',  NULL,    'Prof. Ibrahim');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (10, 1, 'Present', '11:05', 'Prof. Ibrahim');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (5,  1, 'Late',    '09:18', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (5,  4, 'Present', '09:01', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (6,  1, 'Present', '09:00', 'Prof. Hassan');
INSERT INTO attendance_records (session_id, student_id, status, check_in_time, recorded_by)
VALUES (6,  9, 'Present', '08:55', 'Prof. Hassan');
 
COMMIT;
 
 
-- ============================================================
-- SECTION 6: ALTER TABLE DEMONSTRATIONS
-- ============================================================

-- Add a new column to students
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE students ADD (scholarship VARCHAR2(50) DEFAULT ''None'')';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE = -1430 THEN NULL; ELSE RAISE; END IF;
END;
/

-- Add column to enrollments
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE enrollments ADD (payment_status VARCHAR2(20) DEFAULT ''Paid'' CHECK (payment_status IN (''Paid'',''Pending'',''Waived'')))';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE = -1430 THEN NULL; ELSE RAISE; END IF;
END;
/

-- Modify a column (increase VARCHAR size) — safe to repeat
ALTER TABLE courses MODIFY (room VARCHAR2(40));

-- Add a named constraint after table creation
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE students ADD CONSTRAINT chk_gpa_positive CHECK (gpa >= 0)';
EXCEPTION WHEN OTHERS THEN
    IF SQLCODE = -2264 THEN NULL; ELSE RAISE; END IF;
END;
/
 
 
-- ============================================================
-- SECTION 7: UPDATE STATEMENTS
-- ============================================================
 
-- Update 1: Mark a student as inactive (dropped out)
UPDATE students
SET    is_active = 'N'
WHERE  student_id = 16;
 
-- Update 2: Assign final grades for completed enrollments
UPDATE enrollments
SET    grade  = 'A',
       status = 'Completed'
WHERE  student_id = 1
  AND  course_id  = 1;
 
-- Update 3: Cancel a class session
UPDATE class_sessions
SET    is_cancelled = 'Y',
       notes        = 'Instructor ill – session rescheduled'
WHERE  session_id = 6;
 
-- Update 4: Give a scholarship to all students with GPA >= 3.80
UPDATE students
SET    scholarship = 'Merit Scholarship'
WHERE  gpa >= 3.80;
 
-- Update 5: Subquery-based UPDATE – raise max_capacity for overloaded courses
--   (courses whose current enrollment > 80% of capacity)
UPDATE courses c
SET    max_capacity = max_capacity + 10
WHERE  (SELECT COUNT(*) FROM enrollments e
        WHERE  e.course_id = c.course_id
          AND  e.status    = 'Active') > (c.max_capacity * 0.8);
 
COMMIT;
 
 
-- ============================================================
-- SECTION 8: DELETE STATEMENTS
-- ============================================================
 
-- Delete 1: Remove a dropped enrollment
DELETE FROM enrollments
WHERE  status = 'Dropped';
 
-- Delete 2: Subquery-based DELETE – remove attendance records for cancelled sessions
DELETE FROM attendance_records
WHERE  session_id IN (SELECT session_id
                      FROM   class_sessions
                      WHERE  is_cancelled = 'Y');
 
COMMIT;
 
 
-- ============================================================
-- SECTION 9: SELECT QUERIES
-- ============================================================
 
-- 9A: Filtering + Sorting
-- Active students sorted by GPA descending
SELECT student_number, first_name, last_name, major, gpa
FROM   students
WHERE  is_active = 'Y'
ORDER  BY gpa DESC;
 
-- 9B: LIKE – Find students whose last name starts with 'M'
SELECT student_id, first_name, last_name, email
FROM   students
WHERE  last_name LIKE 'M%';
 
-- 9C: IN – Students enrolled in CS or Math departments
SELECT s.student_number, s.first_name, s.last_name, c.course_name
FROM   students    s
JOIN   enrollments e ON s.student_id = e.student_id
JOIN   courses     c ON e.course_id  = c.course_id
WHERE  c.department IN ('Computer Science','Mathematics');
 
-- 9D: BETWEEN – Courses with 3 to 4 credits
SELECT course_code, course_name, credits, department
FROM   courses
WHERE  credits BETWEEN 3 AND 4
ORDER  BY credits, course_name;
 
-- 9E: BETWEEN on dates – Students enrolled between Jan 15 and Jan 18 2024
SELECT e.enrollment_id, s.first_name || ' ' || s.last_name AS student_name,
       c.course_name, e.enroll_date
FROM   enrollments e
JOIN   students    s ON e.student_id = s.student_id
JOIN   courses     c ON e.course_id  = c.course_id
WHERE  e.enroll_date BETWEEN DATE '2024-01-15' AND DATE '2024-01-18'
ORDER  BY e.enroll_date;
 
 
-- ============================================================
-- SECTION 10: AGGREGATE FUNCTIONS, GROUP BY, HAVING
-- ============================================================
 
-- 10A: COUNT students per major
SELECT   major, COUNT(*) AS student_count
FROM     students
WHERE    is_active = 'Y'
GROUP BY major
ORDER BY student_count DESC;
 
-- 10B: AVG, MIN, MAX GPA per enrollment year
SELECT   enrollment_year,
         COUNT(*)          AS students,
         ROUND(AVG(gpa),2) AS avg_gpa,
         MIN(gpa)          AS min_gpa,
         MAX(gpa)          AS max_gpa
FROM     students
WHERE    gpa IS NOT NULL
GROUP BY enrollment_year
ORDER BY enrollment_year;
 
-- 10C: SUM credits per student (total credit hours enrolled)
SELECT   s.first_name || ' ' || s.last_name AS student_name,
         SUM(c.credits)                      AS total_credits,
         COUNT(e.enrollment_id)              AS courses_taken
FROM     students    s
JOIN     enrollments e ON s.student_id = e.student_id
JOIN     courses     c ON e.course_id  = c.course_id
GROUP BY s.student_id, s.first_name, s.last_name
ORDER BY total_credits DESC;
 
-- 10D: HAVING – Departments where the average instructor seniority > 5 years
SELECT   department,
         COUNT(*)                                  AS instructor_count,
         ROUND(AVG(MONTHS_BETWEEN(SYSDATE, hire_date)/12), 1) AS avg_years
FROM     instructors
GROUP BY department
HAVING   AVG(MONTHS_BETWEEN(SYSDATE, hire_date)/12) > 5
ORDER BY avg_years DESC;
 
-- 10E: Attendance summary per student per course (Present count)
SELECT   s.first_name || ' ' || s.last_name  AS student_name,
         c.course_code,
         COUNT(ar.attendance_id)             AS total_sessions,
         SUM(CASE WHEN ar.status = 'Present' THEN 1 ELSE 0 END) AS present_count,
         SUM(CASE WHEN ar.status = 'Absent'  THEN 1 ELSE 0 END) AS absent_count,
         ROUND(SUM(CASE WHEN ar.status = 'Present' THEN 1 ELSE 0 END) /
               NULLIF(COUNT(ar.attendance_id),0) * 100, 1)       AS attendance_pct
FROM     attendance_records ar
JOIN     students           s  ON ar.student_id = s.student_id
JOIN     class_sessions     cs ON ar.session_id = cs.session_id
JOIN     courses             c  ON cs.course_id  = c.course_id
GROUP BY s.student_id, s.first_name, s.last_name, c.course_id, c.course_code
HAVING   COUNT(ar.attendance_id) > 0
ORDER BY attendance_pct DESC;
 
 
-- ============================================================
-- SECTION 11: JOINS
-- ============================================================
 
-- 11A: INNER JOIN – Students and their enrolled course names
SELECT s.student_number,
       s.first_name || ' ' || s.last_name AS student_name,
       c.course_code,
       c.course_name,
       e.grade
FROM   students    s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses     c ON e.course_id  = c.course_id
ORDER  BY s.last_name, c.course_code;
 
-- 11B: LEFT JOIN – All students, including those with no enrollments
SELECT s.student_number,
       s.first_name || ' ' || s.last_name AS student_name,
       s.major,
       COUNT(e.enrollment_id)             AS enrollment_count
FROM   students    s
LEFT JOIN enrollments e ON s.student_id = e.student_id
GROUP  BY s.student_id, s.student_number, s.first_name, s.last_name, s.major
ORDER  BY enrollment_count DESC;
 
-- 11C: RIGHT JOIN – All courses and their enrolled student count (includes courses with 0 students)
SELECT c.course_code,
       c.course_name,
       c.max_capacity,
       COUNT(e.enrollment_id) AS enrolled_count
FROM   enrollments e
RIGHT JOIN courses c ON e.course_id = c.course_id
GROUP  BY c.course_id, c.course_code, c.course_name, c.max_capacity
ORDER  BY enrolled_count DESC;
 
-- 11D: FULL OUTER JOIN – All students and all courses (null where no match)
SELECT s.first_name || ' ' || s.last_name AS student_name,
       c.course_code,
       c.course_name
FROM   students    s
FULL OUTER JOIN enrollments e ON s.student_id = e.student_id
FULL OUTER JOIN courses     c ON e.course_id  = c.course_id
ORDER  BY student_name NULLS LAST, c.course_code NULLS LAST;
 
-- 11E: 3-TABLE JOIN – Attendance detail: student + session + course
SELECT s.student_number,
       s.first_name || ' ' || s.last_name AS student_name,
       c.course_code,
       c.course_name,
       cs.session_date,
       cs.topic,
       ar.status        AS attendance_status,
       ar.check_in_time
FROM   attendance_records ar
JOIN   students           s  ON ar.student_id = s.student_id
JOIN   class_sessions     cs ON ar.session_id = cs.session_id
JOIN   courses             c  ON cs.course_id  = c.course_id
ORDER  BY cs.session_date, s.last_name;
 
-- 11F: 4-TABLE JOIN – Full picture including instructor name
SELECT s.first_name || ' ' || s.last_name   AS student_name,
       c.course_code,
       i.first_name || ' ' || i.last_name   AS instructor_name,
       cs.session_date,
       ar.status
FROM   attendance_records ar
JOIN   students           s  ON ar.student_id  = s.student_id
JOIN   class_sessions     cs ON ar.session_id  = cs.session_id
JOIN   courses             c  ON cs.course_id   = c.course_id
JOIN   instructors         i  ON c.instructor_id = i.instructor_id
ORDER  BY c.course_code, cs.session_date, s.last_name;
 
 
-- ============================================================
-- SECTION 12: SUBQUERIES
-- ============================================================
 
-- 12A: Single-value subquery – Students with GPA above overall average
SELECT student_number, first_name, last_name, gpa
FROM   students
WHERE  gpa > (SELECT AVG(gpa) FROM students WHERE gpa IS NOT NULL)
ORDER  BY gpa DESC;
 
-- 12B: Multi-value subquery – Students enrolled in any Computer Science course
SELECT DISTINCT s.student_number,
                s.first_name || ' ' || s.last_name AS student_name
FROM   students s
WHERE  s.student_id IN (
    SELECT e.student_id
    FROM   enrollments e
    JOIN   courses     c ON e.course_id = c.course_id
    WHERE  c.department = 'Computer Science'
)
ORDER  BY student_name;
 
-- 12C: Correlated subquery – Students whose GPA is above average for their major
SELECT student_number, first_name, last_name, major, gpa
FROM   students s_outer
WHERE  gpa > (
    SELECT AVG(gpa)
    FROM   students s_inner
    WHERE  s_inner.major    = s_outer.major
      AND  s_inner.gpa IS NOT NULL
)
ORDER  BY major, gpa DESC;
 
-- 12D: Subquery in UPDATE – Update payment_status to 'Pending' for students with low GPA
UPDATE enrollments
SET    payment_status = 'Pending'
WHERE  student_id IN (
    SELECT student_id FROM students WHERE gpa < 3.00 AND is_active = 'Y'
);
 
-- 12E: Subquery in DELETE – Delete sessions for courses with no active enrollments
DELETE FROM class_sessions
WHERE  course_id NOT IN (
    SELECT DISTINCT course_id
    FROM   enrollments
    WHERE  status = 'Active'
);
 
COMMIT;
 
 
-- ============================================================
-- SECTION 13: SET OPERATIONS
-- ============================================================
 
-- 13A: UNION – All email addresses (students + instructors combined)
SELECT email, 'Student'    AS role FROM students
UNION
SELECT email, 'Instructor' AS role FROM instructors
ORDER  BY role, email;
 
-- 13B: UNION ALL – All attendance statuses logged (including duplicates)
SELECT status FROM attendance_records WHERE student_id = 1
UNION ALL
SELECT status FROM attendance_records WHERE student_id = 9
ORDER  BY status;
 
-- 13C: INTERSECT – Students who are enrolled AND have attendance records
SELECT student_id FROM enrollments
INTERSECT
SELECT student_id FROM attendance_records;
 
-- 13D: MINUS – Students enrolled but with NO attendance records at all
SELECT student_id FROM enrollments
MINUS
SELECT student_id FROM attendance_records;
 
-- 13E: UNION showing courses with either high enrollment or high capacity
SELECT course_code, course_name, 'High Enrollment' AS flag
FROM   courses
WHERE  course_id IN (SELECT course_id FROM enrollments
                     GROUP BY course_id HAVING COUNT(*) >= 3)
UNION
SELECT course_code, course_name, 'High Capacity'
FROM   courses
WHERE  max_capacity >= 40
ORDER  BY flag, course_code;
 
 
-- ============================================================
-- SECTION 14: USEFUL REPORTING QUERIES
-- ============================================================
 
-- Report 1: Full attendance report for CS301
SELECT s.student_number,
       s.first_name || ' ' || s.last_name              AS student_name,
       COUNT(ar.attendance_id)                          AS total_sessions,
       SUM(CASE WHEN ar.status = 'Present' THEN 1 END) AS present,
       SUM(CASE WHEN ar.status = 'Absent'  THEN 1 END) AS absent,
       SUM(CASE WHEN ar.status = 'Late'    THEN 1 END) AS late,
       SUM(CASE WHEN ar.status = 'Excused' THEN 1 END) AS excused,
       ROUND(SUM(CASE WHEN ar.status IN ('Present','Late') THEN 1 ELSE 0 END) /
             NULLIF(COUNT(ar.attendance_id),0) * 100, 1) AS attendance_pct
FROM   attendance_records ar
JOIN   students           s  ON ar.student_id = s.student_id
JOIN   class_sessions     cs ON ar.session_id = cs.session_id
WHERE  cs.course_id = 1
GROUP  BY s.student_id, s.student_number, s.first_name, s.last_name
ORDER  BY attendance_pct DESC;
 
-- Report 2: Students at risk (attendance below 75%)
SELECT student_name, course_code, attendance_pct
FROM (
    SELECT s.first_name || ' ' || s.last_name AS student_name,
           c.course_code,
           ROUND(SUM(CASE WHEN ar.status IN ('Present','Late') THEN 1 ELSE 0 END) /
                 NULLIF(COUNT(ar.attendance_id),0) * 100, 1) AS attendance_pct
    FROM   attendance_records ar
    JOIN   students           s  ON ar.student_id = s.student_id
    JOIN   class_sessions     cs ON ar.session_id = cs.session_id
    JOIN   courses             c  ON cs.course_id  = c.course_id
    GROUP  BY s.student_id, s.first_name, s.last_name, c.course_id, c.course_code
)
WHERE attendance_pct < 75
ORDER BY attendance_pct;
 
-- ============================================================
-- END OF SCRIPT
-- ============================================================