import { NavLink } from 'react-router-dom'
import logo from '../assets/Images/LOGO1.png'

const links = [
  { to: '/', label: 'Dashboard', end: true },
  { to: '/students', label: 'Students' },
  { to: '/courses', label: 'Courses' },
  { to: '/attendance', label: 'Attendance' },
  { to: '/reports', label: 'Reports' },
]

function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <img className="sidebar-logo" src={logo} alt="AttendFlow logo" />
        <h2 className="sidebar-title">AttendFlow</h2>
      </div>
      <nav className="sidebar-nav">
        {links.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            end={link.end}
            className={({ isActive }) =>
              `sidebar-link ${isActive ? 'sidebar-link-active' : ''}`
            }
          >
            {link.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  )
}

export default Sidebar
