import { useEffect, useMemo, useState } from 'react'
import { deleteEnrollment, getAttendance, updateGpa } from '../api/api'
import Badge from '../components/Badge'
import EmptyState from '../components/EmptyState'
import LoadingSpinner from '../components/LoadingSpinner'

function getStatus(attendance) {
  if (attendance >= 75) {
    return { text: 'Good', variant: 'good', barClass: 'attendance-fill-good' }
  }
  if (attendance >= 60) {
    return { text: 'At Risk', variant: 'risk', barClass: 'attendance-fill-risk' }
  }
  return { text: 'Critical', variant: 'critical', barClass: 'attendance-fill-critical' }
}

function Attendance() {
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [studentId, setStudentId] = useState('')
  const [gpa, setGpa] = useState('')
  const [enrollmentId, setEnrollmentId] = useState('')
  const [actionMessage, setActionMessage] = useState('')
  const [actionType, setActionType] = useState('success')

  useEffect(() => {
    const loadAttendance = async () => {
      setLoading(true)
      setError('')
      try {
        const response = await getAttendance()
        const data = Array.isArray(response.data?.data) ? response.data.data : []
        setRows(data)
      } catch (err) {
        setError(err.message || 'Failed to load attendance data.')
      } finally {
        setLoading(false)
      }
    }
    loadAttendance()
  }, [])

  const sortedRows = useMemo(
    () => [...rows].sort((a, b) => Number(a.attendance || 0) - Number(b.attendance || 0)),
    [rows],
  )

  const atRiskCount = useMemo(
    () => sortedRows.filter((row) => Number(row.attendance || 0) < 75).length,
    [sortedRows],
  )

  const showMessage = (message, type) => {
    setActionMessage(message)
    setActionType(type)
    window.setTimeout(() => {
      setActionMessage('')
    }, 2600)
  }

  const handleUpdateGpa = async () => {
    try {
      await updateGpa(Number(studentId), Number(gpa))
      showMessage('✅ GPA updated successfully', 'success')
      setStudentId('')
      setGpa('')
    } catch (err) {
      showMessage(err.message || 'Failed to update GPA.', 'error')
    }
  }

  const handleDeleteEnrollment = async () => {
    if (!window.confirm('Are you sure?')) {
      return
    }
    try {
      await deleteEnrollment(Number(enrollmentId))
      showMessage('✅ Enrollment removed', 'success')
      setEnrollmentId('')
    } catch (err) {
      showMessage(err.message || 'Failed to remove enrollment.', 'error')
    }
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

  if (!sortedRows.length) {
    return (
      <div className="dashboard-centered">
        <EmptyState message="No data available" />
      </div>
    )
  }

  return (
    <section className="attendance-page">
      {atRiskCount > 0 ? (
        <div className="attendance-banner">
          ⚠️ {atRiskCount} students are below the 75% attendance threshold
        </div>
      ) : null}

      {actionMessage ? (
        <div className={actionType === 'success' ? 'success-alert' : 'error-alert'}>
          {actionMessage}
        </div>
      ) : null}

      <section className="table-card">
        <h3>Attendance Overview</h3>
        <div className="table-wrap">
          <table className="attendance-table">
            <thead>
              <tr>
                <th>Student Name</th>
                <th>Attendance %</th>
                <th>Visual Bar</th>
                <th>Status Badge</th>
              </tr>
            </thead>
            <tbody>
              {sortedRows.map((row) => {
                const attendance = Number(row.attendance || 0)
                const status = getStatus(attendance)
                return (
                  <tr key={`${row.first_name}-${row.last_name}`}>
                    <td>{row.first_name} {row.last_name}</td>
                    <td>{attendance.toFixed(1)}%</td>
                    <td>
                      <div className="attendance-bar-bg">
                        <div
                          className={`attendance-bar-fill ${status.barClass}`}
                          style={{ width: `${Math.max(0, Math.min(100, attendance))}%` }}
                        />
                      </div>
                    </td>
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

      <section className="action-card">
        <h3>Update Student GPA</h3>
        <div className="action-row">
          <input
            type="number"
            placeholder="Student ID"
            value={studentId}
            onChange={(event) => setStudentId(event.target.value)}
          />
          <input
            type="number"
            placeholder="New GPA"
            step="0.01"
            min="0"
            max="4"
            value={gpa}
            onChange={(event) => setGpa(event.target.value)}
          />
          <button
            type="button"
            onClick={handleUpdateGpa}
            disabled={!studentId || gpa === ''}
          >
            Update GPA
          </button>
        </div>
      </section>

      <section className="action-card">
        <h3>Remove Enrollment</h3>
        <div className="action-row">
          <input
            type="number"
            placeholder="Enrollment ID"
            value={enrollmentId}
            onChange={(event) => setEnrollmentId(event.target.value)}
          />
          <button
            type="button"
            className="btn-danger"
            onClick={handleDeleteEnrollment}
            disabled={!enrollmentId}
          >
            Delete
          </button>
        </div>
      </section>
    </section>
  )
}

export default Attendance
