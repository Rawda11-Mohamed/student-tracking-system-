import { useEffect, useMemo, useState } from 'react'
import EmptyState from '../components/EmptyState'
import LoadingSpinner from '../components/LoadingSpinner'
import { getStudentCourses, getStudents, searchStudents } from '../api/api'

function normalizeName(firstName, lastName) {
  return `${String(firstName || '').trim().toLowerCase()}::${String(
    lastName || '',
  )
    .trim()
    .toLowerCase()}`
}

function gpaClassName(gpa) {
  const value = Number(gpa || 0)
  if (value >= 3.5) {
    return 'gpa-good'
  }
  if (value >= 2.5) {
    return 'gpa-mid'
  }
  return 'gpa-low'
}

function Students() {
  const [query, setQuery] = useState('')
  const [students, setStudents] = useState([])
  const [courseMap, setCourseMap] = useState({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let isMounted = true
    const loadCourses = async () => {
      try {
        const response = await getStudentCourses()
        if (!isMounted) {
          return
        }

        const rows = response.data?.data || []
        const nextMap = {}
        rows.forEach((row) => {
          const key = normalizeName(row.first_name, row.last_name)
          if (!nextMap[key]) {
            nextMap[key] = []
          }
          const alreadyAdded = nextMap[key].some((c) => c.courseName === row.course_name)
          if (row.course_name && !alreadyAdded) {
            nextMap[key].push({
              courseName: row.course_name,
              instructor: row.instructor_name || '—',
            })
          }
        })
        setCourseMap(nextMap)
      } catch (err) {
        if (isMounted) {
          setError(err.message || 'Failed to load courses.')
        }
      }
    }

    loadCourses()
    return () => {
      isMounted = false
    }
  }, [])

  useEffect(() => {
    let isMounted = true
    const timeoutId = setTimeout(async () => {
      setLoading(true)
      setError('')
      try {
        const response = query.trim()
          ? await searchStudents(query.trim())
          : await getStudents()

        if (!isMounted) {
          return
        }

        setStudents(response.data?.data || [])
      } catch (err) {
        if (isMounted) {
          setError(err.message || 'Failed to load students.')
          setStudents([])
        }
      } finally {
        if (isMounted) {
          setLoading(false)
        }
      }
    }, 400)

    return () => {
      isMounted = false
      clearTimeout(timeoutId)
    }
  }, [query])

  const mappedStudents = useMemo(() => {
    return students.map((student) => {
      const key = normalizeName(student.first_name, student.last_name)
      return {
        ...student,
        courses: courseMap[key] || [],
      }
    })
  }, [students, courseMap])

  if (loading) {
    return (
      <div className="dashboard-centered">
        <LoadingSpinner />
      </div>
    )
  }

  if (error) {
    return <div className="error-alert">{error}</div>
  }

  return (
    <section className="students-page">
      <div className="students-toolbar">
        <div className="search-input-wrap">
          <span className="search-icon">🔍</span>
          <input
            type="text"
            className="students-search-input"
            placeholder="Search by first name..."
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>
      </div>

      {!mappedStudents.length ? (
        <div className="dashboard-centered">
          <EmptyState message="No data available" />
        </div>
      ) : (
        <>
          <div className="table-wrap">
            <table className="students-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Student ID</th>
                  <th>Full Name</th>
                  <th>GPA</th>
                  <th>Courses</th>
                  <th>Instructor(s)</th>
                </tr>
              </thead>
              <tbody>
                {mappedStudents.map((student, index) => {
                  const instructors = [
                    ...new Set(student.courses.map((c) => c.instructor).filter(Boolean)),
                  ]
                  return (
                    <tr key={student.student_id}>
                      <td>{index + 1}</td>
                      <td>{student.student_id}</td>
                      <td>{student.first_name} {student.last_name}</td>
                      <td className={gpaClassName(student.gpa)}>
                        {Number(student.gpa || 0).toFixed(2)}
                      </td>
                      <td>
                        {student.courses.length ? (
                          <div className="course-pills">
                            {student.courses.map((course) => (
                              <span key={`${student.student_id}-${course.courseName}`} className="course-pill">
                                {course.courseName}
                              </span>
                            ))}
                          </div>
                        ) : (
                          <span>—</span>
                        )}
                      </td>
                      <td>
                        {instructors.length ? (
                          <div className="course-pills">
                            {instructors.map((name) => (
                              <span key={`${student.student_id}-${name}`} className="course-pill instructor-pill">
                                {name}
                              </span>
                            ))}
                          </div>
                        ) : (
                          <span>—</span>
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
          <p className="students-summary">Showing {mappedStudents.length} students</p>
        </>
      )}
    </section>
  )
}

export default Students
