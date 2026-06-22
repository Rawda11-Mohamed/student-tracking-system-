import { useEffect, useMemo, useState } from 'react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import EmptyState from '../components/EmptyState'
import LoadingSpinner from '../components/LoadingSpinner'
import StatCard from '../components/StatCard'
import Badge from '../components/Badge'
import {
  getAttendance,
  getGpaByYear,
  getStudents,
  getStudentsPerMajor,
  getTopStudents,
} from '../api/api'

function getAttendanceStatus(attendance) {
  if (attendance >= 75) {
    return { text: 'Good', variant: 'good' }
  }
  if (attendance >= 60) {
    return { text: 'At Risk', variant: 'risk' }
  }
  return { text: 'Critical', variant: 'critical' }
}

function getSafeArray(payload, fallbackMessage) {
  if (Array.isArray(payload?.data)) {
    return payload.data
  }
  if (payload?.data?.error) {
    throw new Error(payload.data.error)
  }
  if (payload?.error) {
    throw new Error(payload.error)
  }
  throw new Error(fallbackMessage)
}

function Dashboard() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [students, setStudents] = useState([])
  const [topStudents, setTopStudents] = useState([])
  const [attendanceRows, setAttendanceRows] = useState([])
  const [studentsPerMajor, setStudentsPerMajor] = useState([])
  const [gpaByYear, setGpaByYear] = useState([])

  useEffect(() => {
    const loadDashboardData = async () => {
      setLoading(true)
      setError('')
      try {
        const [
          studentsResponse,
          topStudentsResponse,
          attendanceResponse,
          studentsPerMajorResponse,
          gpaByYearResponse,
        ] = await Promise.all([
          getStudents(),
          getTopStudents(),
          getAttendance(),
          getStudentsPerMajor(),
          getGpaByYear(),
        ])

        setStudents(getSafeArray(studentsResponse.data, 'Invalid students response'))
        setTopStudents(
          getSafeArray(topStudentsResponse.data, 'Invalid top students response'),
        )
        setAttendanceRows(
          getSafeArray(attendanceResponse.data, 'Invalid attendance response'),
        )
        setStudentsPerMajor(
          getSafeArray(
            studentsPerMajorResponse.data,
            'Invalid students per major response',
          ),
        )
        setGpaByYear(getSafeArray(gpaByYearResponse.data, 'Invalid GPA response'))
      } catch (err) {
        setError(err.message || 'Failed to fetch dashboard data.')
      } finally {
        setLoading(false)
      }
    }

    loadDashboardData()
  }, [])

  const averageAttendance = useMemo(() => {
    if (!attendanceRows.length) {
      return 0
    }
    const total = attendanceRows.reduce(
      (sum, row) => sum + Number(row.attendance || 0),
      0,
    )
    return total / attendanceRows.length
  }, [attendanceRows])

  const atRiskCount = useMemo(
    () => attendanceRows.filter((row) => Number(row.attendance || 0) < 75).length,
    [attendanceRows],
  )

  const attendanceColor = useMemo(() => {
    if (averageAttendance >= 75) {
      return 'green'
    }
    if (averageAttendance >= 60) {
      return 'amber'
    }
    return 'red'
  }, [averageAttendance])

  const topStudentName = useMemo(() => {
    if (!topStudents.length) {
      return 'N/A'
    }
    const topStudent = topStudents[0]
    return `${topStudent.first_name} ${topStudent.last_name}`
  }, [topStudents])

  const sortedAttendanceRows = useMemo(() => {
    return [...attendanceRows].sort(
      (a, b) => Number(a.attendance || 0) - Number(b.attendance || 0),
    )
  }, [attendanceRows])

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

  if (!attendanceRows.length) {
    return (
      <div className="dashboard-centered">
        <EmptyState message="No data available" />
      </div>
    )
  }

  return (
    <section className="dashboard">
      <div className="stats-grid">
        <StatCard
          title="Total Students"
          value={students.length}
          icon="👥"
          color="blue"
          subtitle="Registered students"
        />
        <StatCard
          title="Top GPA Student"
          value={topStudentName}
          icon="🏆"
          color="green"
          subtitle="Highest GPA among active students"
        />
        <StatCard
          title="Attendance Rate"
          value={`${averageAttendance.toFixed(1)}%`}
          icon="✅"
          color={attendanceColor}
          subtitle="Average attendance"
        />
        <StatCard
          title="At-Risk Students"
          value={atRiskCount}
          icon="⚠️"
          color="red"
          subtitle="Attendance below 75%"
        />
      </div>

      <div className="charts-grid">
        <article className="chart-card">
          <h3>Students per Major</h3>
          {studentsPerMajor.length ? (
            <div className="chart-wrap">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={studentsPerMajor}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="major" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="count" fill="#3B82F6" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <EmptyState message="No data available" />
          )}
        </article>

        <article className="chart-card">
          <h3>Avg GPA by Enrollment Year</h3>
          {gpaByYear.length ? (
            <div className="chart-wrap">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={gpaByYear}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="enrollment_year" />
                  <YAxis domain={[0, 4]} />
                  <Tooltip />
                  <Line
                    type="monotone"
                    dataKey="avg_gpa"
                    stroke="#1D4ED8"
                    strokeWidth={3}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <EmptyState message="No data available" />
          )}
        </article>
      </div>

      <section className="table-card">
        <h3>Attendance Overview</h3>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Student Name</th>
                <th>Attendance %</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {sortedAttendanceRows.map((row) => {
                const attendance = Number(row.attendance || 0)
                const status = getAttendanceStatus(attendance)
                return (
                  <tr key={`${row.first_name}-${row.last_name}`}>
                    <td>{row.first_name} {row.last_name}</td>
                    <td>{attendance.toFixed(1)}%</td>
                    <td>
                      <Badge variant={status.variant}>{status.text}</Badge>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </section>
    </section>
  )
}

export default Dashboard
