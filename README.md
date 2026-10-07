# Student Attendance Tracking System

A full-stack Student Attendance Tracking System developed to manage and analyze student academic and attendance data.

## Project Overview

The system provides an interactive dashboard for managing and viewing student information, courses, enrollments, GPA, and attendance data stored in an Oracle Database.

The project consists of:

* Oracle Database for data storage
* Flask REST API for the backend
* React + Vite for the frontend

## Features

* View all students and their GPAs
* Search for students by first name
* View top-performing students
* View students and their enrolled courses
* View instructors associated with courses
* View students by major
* Calculate average GPA by enrollment year
* Calculate attendance percentage for each student
* Filter courses by department
* View courses based on credit hours
* Update student GPA
* Delete student enrollments

## Technologies Used

### Frontend

* React
* Vite
* JavaScript
* HTML
* CSS
* Node.js
* npm

### Backend

* Python
* Flask
* Flask-CORS
* cx_Oracle

### Database

* Oracle Database XE
* SQL
* Oracle SQL Developer

## Project Structure

```text
DB project/
├── frontend/
│   ├── public/
│   ├── src/
│   ├── dist/
│   ├── node_modules/
│   ├── package.json
│   ├── package-lock.json
│   └── vite.config.js
│
├── backend (1).py
├── start.bat
└── Student Attendance Tracking System.sql
```

## Database

The project uses Oracle Database XE.

The database includes tables for:

* Students
* Instructors
* Courses
* Enrollments
* Class Sessions
* Attendance Records

The database schema and sample data are provided in:

`Student Attendance Tracking System.sql`


## Backend API

The Flask backend runs on port `5001`.

Base URL:

```text
http://localhost:5001
```

### Student Endpoints

#### Get All Students

```http
GET /students
```

Returns all students with their GPA.

#### Get Top Students

```http
GET /top-students
```

Returns active students sorted by GPA.

#### Search Students

```http
GET /search?name=Ahmed
```

Searches for students by first name.

### Course Endpoints

#### Get Student Courses

```http
GET /student-courses
```

Returns students, their enrolled courses, and instructors.

#### Get Courses by Department

```http
GET /courses?department=CS
```

Returns courses for a selected department.

#### Get Courses by Credit Range

```http
GET /courses-range
```

Returns courses with credit hours between 3 and 4.

### Academic Statistics

#### Students per Major

```http
GET /students-per-major
```

Returns the number of students in each major.

#### GPA by Year

```http
GET /gpa-by-year
```

Returns the average GPA for each enrollment year.

#### Attendance

```http
GET /attendance
```

Returns the attendance percentage for each student.

### Data Modification

#### Update GPA

```http
POST /update-gpa
```

Example request:

```json
{
  "id": 1,
  "gpa": 3.75
}
```

#### Delete Enrollment

```http
POST /delete-enrollment
```

Example request:

```json
{
  "id": 1
}
```

## Running the Project

### 1. Start Oracle Database

Make sure Oracle Database XE is running.

The database should be available at:

```text
localhost:1521
```

Service name:

```text
XE
```

### 2. Run the Backend

Open a terminal in the project root directory and run:

```bash
python "backend (1).py"
```

The Flask backend will run on:

```text
http://localhost:5001
```

### 3. Run the Frontend

Open another terminal and navigate to the frontend directory:

```bash
cd frontend
```

Install the required packages:

```bash
npm install
```

Start the Vite development server:

```bash
npm run dev
```

The frontend will be available at:

```text
http://localhost:5173
```

## System Architecture

```text
┌─────────────────────────┐
│   React + Vite Frontend │
└────────────┬────────────┘
             │
             │ HTTP Requests
             ▼
┌─────────────────────────┐
│     Flask REST API      │
│        Port 5001        │
└────────────┬────────────┘
             │
             │ SQL Queries
             ▼
┌─────────────────────────┐
│    Oracle Database XE   │
│        Port 1521        │
└─────────────────────────┘
```

## API Response Format

The backend returns JSON responses containing a title, description, and data.

Example:

```json
{
  "title": "All Students",
  "description": "List of all students with GPA",
  "data": []
}
```

## CORS

Flask-CORS is used to allow communication between the React frontend and Flask backend running on different ports.

## Future Improvements

* User authentication and authorization
* Admin dashboard
* Add and edit students
* Add and manage courses
* Attendance recording interface
* Attendance charts and reports
* GPA visualization
* Export reports to PDF or Excel
* Pagination
* Input validation
* Role-based access control

## Conclusion

The Student Attendance Tracking System demonstrates the integration of an Oracle relational database with a Flask REST API and a React frontend.

The project demonstrates:

* Database design and management
* SQL queries
* REST API development
* Oracle database integration
* Frontend-backend communication
* Academic data analysis
* Attendance tracking

 ## Screenshots

### Dashboard

<p align="center">
  <img src="https://github.com/user-attachments/assets/e59cd3ed-471a-4621-9133-7c517fa66d1c" width="48%" />
  <img src="https://github.com/user-attachments/assets/c78a29b2-59de-4564-8335-6e0b55e3d277" width="48%" />
</p>

### Student & Academic Data

<p align="center">
  <img src="https://github.com/user-attachments/assets/35fb5433-ef5c-4b1f-bcd4-020cf78d43a8" width="48%" />
  <img src="https://github.com/user-attachments/assets/d3f8f960-e381-49b4-ace1-afc8f56e4e80" width="48%" />
</p>

### Attendance & Statistics

<p align="center">
  <img src="https://github.com/user-attachments/assets/e2f7e0e3-ccf0-4cda-ae5d-1dc1c942344a" width="60%" />
</p>
