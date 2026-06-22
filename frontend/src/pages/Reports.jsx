import { useEffect, useMemo, useState } from 'react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { getAttendance, getGpaByYear, getStudentCourses } from '../api/api'
import EmptyState from '../components/EmptyState'
import LoadingSpinner from '../components/LoadingSpinner'

function Reports() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [gpaByYear, setGpaByYear] = useState([])
  const [attendance, setAttendance] = useState([])
  const [studentCourses, setStudentCourses] = useState([])
  const [search, setSearch] = useState('')

  useEffect(() => {
    const loadData = async () => {
      setLoading(true)
      setError('')
      try {
        const [gpaResponse, attendanceResponse, coursesResponse] = await Promise.all([
          getGpaByYear(),
          getAttendance(),
          getStudentCourses(),
        ])

        setGpaByYear(Array.isArray(gpaResponse.data?.data) ? gpaResponse.data.data : [])
        setAttendance(
          Array.isArray(attendanceResponse.data?.data) ? attendanceResponse.data.data : [],
        )
        setStudentCourses(
          Array.isArray(coursesResponse.data?.data) ? coursesResponse.data.data : [],
        )
      } catch (err) {
        setError(err.message || 'Failed to load reports data.')
      } finally {
        setLoading(false)
      }
    }
    loadData()
  }, [])

  const attendanceDistribution = useMemo(() => {
    const good = attendance.filter((item) => Number(item.attendance || 0) >= 75).length
    const risk = attendance.filter((item) => {
      const value = Number(item.attendance || 0)
      return value >= 60 && value < 75
    }).length
    const critical = attendance.filter((item) => Number(item.attendance || 0) < 60).length
    return [
      { name: 'Good', value: good, color: '#10B981' },
      { name: 'At Risk', value: risk, color: '#F59E0B' },
      { name: 'Critical', value: critical, color: '#EF4444' },
    ]
  }, [attendance])

  const filteredRows = useMemo(() => {
    const query = search.trim().toLowerCase()
    return studentCourses.filter((row) =>
      `${row.first_name} ${row.last_name}`.toLowerCase().includes(query),
    )
  }, [studentCourses, search])

  const exportCsv = () => {
    const header = 'Student Name,Course Name\n'
    const lines = filteredRows
      .map((row) => `"${row.first_name} ${row.last_name}","${row.course_name}"`)
      .join('\n')
    const csvContent = header + lines
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = 'student_courses_report.csv'
    link.click()
    URL.revokeObjectURL(url)
  }

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

  if (!gpaByYear.length && !attendance.length && !studentCourses.length) {
    return (
      <div className="dashboard-centered">
        <EmptyState message="No data available" />
      </div>
    )
  }

  return (
    <section className="reports-page">
      <div className="charts-grid">
        <article className="chart-card">
          <h3>GPA Distribution by Year</h3>
          {!gpaByYear.length ? (
            <EmptyState message="No data available" />
          ) : (
            <div className="chart-wrap chart-wrap-lg">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={gpaByYear}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="enrollment_year" />
                  <YAxis domain={[0, 4]} />
                  <Tooltip />
                  <ReferenceLine y={3.0} stroke="#1D4ED8" strokeDasharray="4 4" label="Good Standing" />
                  <Bar dataKey="avg_gpa" fill="#3B82F6" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </article>

        <article className="chart-card">
          <h3>Attendance Distribution</h3>
          {!attendance.length ? (
            <EmptyState message="No data available" />
          ) : (
            <div className="chart-wrap chart-wrap-lg">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={attendanceDistribution}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="42%"
                    outerRadius={100}
                    label
                  >
                    {attendanceDistribution.map((entry) => (
                      <Cell key={entry.name} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend verticalAlign="bottom" />
                </PieChart>
              </ResponsiveContainer>
            </div>
          )}
        </article>
      </div>

      <section className="table-card">
        <div className="reports-table-header">
          <input
            type="text"
            placeholder="Filter by student name..."
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
          <button type="button" onClick={exportCsv}>
            ⬇️ Export CSV
          </button>
        </div>
        {!filteredRows.length ? (
          <EmptyState message="No enrollments found" />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Student Name</th>
                  <th>Course Name</th>
                </tr>
              </thead>
              <tbody>
                {filteredRows.map((row, idx) => (
                  <tr key={`${row.first_name}-${row.last_name}-${row.course_name}-${idx}`}>
                    <td>{row.first_name} {row.last_name}</td>
                    <td>{row.course_name}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <p className="students-summary">{filteredRows.length} enrollments found</p>
      </section>
    </section>
  )
}

export default Reports
