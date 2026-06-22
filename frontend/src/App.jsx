import { Navigate, Route, Routes } from 'react-router-dom'
import Sidebar from './components/Sidebar'
import TopBar from './components/TopBar'
import Attendance from './pages/Attendance'
import Courses from './pages/Courses'
import Dashboard from './pages/Dashboard'
import Reports from './pages/Reports'
import Students from './pages/Students'

function PageContainer({ title, children }) {
  return (
    <section className="page-container">
      <TopBar title={title} />
      <div className="page-content">{children}</div>
    </section>
  )
}

function App() {
  return (
    <div className="app-layout">
      <Sidebar />
      <main className="content-area">
        <Routes>
          <Route
            path="/"
            element={
              <PageContainer title="Dashboard">
                <Dashboard />
              </PageContainer>
            }
          />
          <Route
            path="/students"
            element={
              <PageContainer title="Students">
                <Students />
              </PageContainer>
            }
          />
          <Route
            path="/courses"
            element={
              <PageContainer title="Courses">
                <Courses />
              </PageContainer>
            }
          />
          <Route
            path="/attendance"
            element={
              <PageContainer title="Attendance">
                <Attendance />
              </PageContainer>
            }
          />
          <Route
            path="/reports"
            element={
              <PageContainer title="Reports">
                <Reports />
              </PageContainer>
            }
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  )
}

export default App
