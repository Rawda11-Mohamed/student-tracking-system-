import os

from flask import Flask, jsonify, request
from flask_cors import CORS

import cx_Oracle

app = Flask(__name__)
CORS(app)

# Oracle connection config
DB_USER = os.getenv("DB_USER", "system")
DB_PASS = os.getenv("DB_PASS", "12345")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "1521"))
DB_SERVICE = os.getenv("DB_SERVICE", "XE")

# cx_Oracle uses the Oracle XE client from system PATH automatically


def get_connection():
    dsn = cx_Oracle.makedsn(DB_HOST, DB_PORT, service_name=DB_SERVICE)
    return cx_Oracle.connect(user=DB_USER, password=DB_PASS, dsn=dsn)


def execute_query(query, params=None):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(query, params or {})
        columns = [c[0].lower() for c in cur.description] if cur.description else []
        data = [dict(zip(columns, row)) for row in cur.fetchall()] if columns else []
        return data
    finally:
        cur.close()
        conn.close()


def payload(title, description, data):
    return jsonify({"title": title, "description": description, "data": data})


@app.route("/students", methods=["GET"])
def get_students():
    try:
        data = execute_query(
            """
            SELECT student_id, first_name, last_name, gpa
            FROM students
            """,
        )
        return payload("All Students", "List of all students with GPA", data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/top-students", methods=["GET"])
def top_students():
    try:
        data = execute_query(
            """
            SELECT first_name, last_name, gpa
            FROM students
            WHERE is_active = 'Y'
            ORDER BY gpa DESC
            """,
        )
        return payload("Top Students", "Active students sorted by GPA", data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/search", methods=["GET"])
def search_students():
    name = request.args.get("name", "").strip().lower()
    try:
        data = execute_query(
            """
            SELECT first_name, last_name, gpa
            FROM students
            WHERE LOWER(first_name) LIKE :name
            """,
            {"name": f"%{name}%"},
        )
        return payload("Search Students", "Search students by first name", data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/student-courses", methods=["GET"])
def student_courses():
    try:
        data = execute_query(
            """
            SELECT s.first_name, s.last_name, c.course_name,
                   i.first_name || ' ' || i.last_name AS instructor_name
            FROM students s
            JOIN enrollments e ON s.student_id = e.student_id
            JOIN courses c ON e.course_id = c.course_id
            JOIN instructors i ON c.instructor_id = i.instructor_id
            """,
        )
        return payload("Student Courses", "Students with their enrolled courses and instructors", data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/students-per-major", methods=["GET"])
def students_per_major():
    try:
        data = execute_query(
            """
            SELECT major, COUNT(*) AS count
            FROM students
            GROUP BY major
            """,
        )
        return payload("Students per Major", "Number of students in each major", data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/gpa-by-year", methods=["GET"])
def gpa_by_year():
    try:
        data = execute_query(
            """
            SELECT enrollment_year, ROUND(AVG(gpa), 2) AS avg_gpa
            FROM students
            GROUP BY enrollment_year
            ORDER BY enrollment_year
            """,
        )
        return payload("GPA by Year", "Average GPA per enrollment year", data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/attendance", methods=["GET"])
def attendance():
    try:
        data = execute_query(
            """
            SELECT s.first_name, s.last_name,
                   ROUND(SUM(CASE WHEN ar.status='Present' THEN 1 ELSE 0 END)/COUNT(*)*100, 1) AS attendance
            FROM attendance_records ar
            JOIN students s ON ar.student_id = s.student_id
            GROUP BY s.first_name, s.last_name
            """,
        )
        return payload("Attendance Percentage", "Attendance percentage per student", data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/courses", methods=["GET"])
def courses_by_dept():
    dept = request.args.get("department", "").strip().upper()
    try:
        data = execute_query(
            """
            SELECT course_name, credits
            FROM courses
            WHERE department = :dept
            """,
            {"dept": dept},
        )
        return payload("Courses by Department", "Get courses for selected department", data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/courses-range", methods=["GET"])
def courses_range():
    try:
        data = execute_query(
            """
            SELECT course_name, credits
            FROM courses
            WHERE credits BETWEEN 3 AND 4
            """,
        )
        return payload("Courses by Credit Range", "Courses with credits between 3 and 4", data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/update-gpa", methods=["POST"])
def update_gpa():
    body = request.get_json(silent=True) or {}
    student_id = body.get("id")
    gpa = body.get("gpa")
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE students
            SET gpa = :gpa
            WHERE student_id = :id
            """,
            {"gpa": gpa, "id": student_id},
        )
        conn.commit()
        return jsonify({"message": "GPA updated successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        try:
            cur.close()
            conn.close()
        except Exception:
            pass


@app.route("/delete-enrollment", methods=["POST"])
def delete_enrollment():
    body = request.get_json(silent=True) or {}
    enrollment_id = body.get("id")
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute(
            """
            DELETE FROM enrollments
            WHERE enrollment_id = :id
            """,
            {"id": enrollment_id},
        )
        conn.commit()
        return jsonify({"message": "Deleted successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        try:
            cur.close()
            conn.close()
        except Exception:
            pass


if __name__ == "__main__":
    app.run(debug=True, use_reloader=False, port=5001)
