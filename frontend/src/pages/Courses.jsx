import { useEffect, useState } from 'react'
import { getCoursesByDept, getCoursesRange } from '../api/api'
import EmptyState from '../components/EmptyState'
import LoadingSpinner from '../components/LoadingSpinner'

const departments = [
  'Computer Science',
  'Mathematics',
  'Physics',
  'English Literature',
  'Chemistry',
  'History',
  'Economics',
]

const deptCodeMap = {
  'Computer Science': 'CS',
  Mathematics: 'MATH',
  Physics: 'PHY',
  'English Literature': 'ENG',
  Chemistry: 'CHEM',
  History: 'HIST',
  Economics: 'ECON',
}

function Courses() {
  const [selectedDept, setSelectedDept] = useState('Computer Science')
  const [filteredCourses, setFilteredCourses] = useState([])
  const [rangeCourses, setRangeCourses] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const loadRange = async () => {
      try {
        const response = await getCoursesRange()
        setRangeCourses(Array.isArray(response.data?.data) ? response.data.data : [])
      } catch (err) {
        setError(err.message || 'Failed to load courses range.')
      }
    }
    loadRange()
  }, [])

  useEffect(() => {
    const loadDepartmentCourses = async () => {
      setLoading(true)
      setError('')
      try {
        const deptCode = deptCodeMap[selectedDept] || selectedDept
        const response = await getCoursesByDept(deptCode)
        setFilteredCourses(Array.isArray(response.data?.data) ? response.data.data : [])
      } catch (err) {
        setError(err.message || 'Failed to load department courses.')
      } finally {
        setLoading(false)
      }
    }
    loadDepartmentCourses()
  }, [selectedDept])

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
    <section className="courses-page">
      <div className="courses-filter-bar">
        <label htmlFor="departmentSelect">Department</label>
        <select
          id="departmentSelect"
          value={selectedDept}
          onChange={(event) => setSelectedDept(event.target.value)}
        >
          {departments.map((dept) => (
            <option key={dept} value={dept}>
              {dept}
            </option>
          ))}
        </select>
      </div>

      <div className="courses-grid">
        <section className="table-card">
          <h3>Filtered Courses</h3>
          {!filteredCourses.length ? (
            <EmptyState message="No courses found for selected department" />
          ) : (
            <div className="table-wrap">
              <table className="courses-table">
                <thead>
                  <tr>
                    <th>Course Name</th>
                    <th>Credits</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredCourses.map((course, idx) => (
                    <tr key={`${course.course_name}-${idx}`}>
                      <td>{course.course_name}</td>
                      <td>
                        <span className="credit-pill">{course.credits}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>

        <section className="table-card">
          <h3>📘 Courses (3–4 Credits)</h3>
          {!rangeCourses.length ? (
            <EmptyState message="No data available" />
          ) : (
            <ul className="range-list">
              {rangeCourses.map((course, idx) => (
                <li key={`${course.course_name}-range-${idx}`}>
                  <span>{course.course_name}</span>
                  <span className="credit-pill">{course.credits}</span>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>
    </section>
  )
}

export default Courses
