function TopBar({ title }) {
  const today = new Date().toLocaleDateString(undefined, {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })

  return (
    <header className="topbar">
      <h1 className="topbar-title">{title}</h1>
      <p className="topbar-date">{today}</p>
    </header>
  )
}

export default TopBar
