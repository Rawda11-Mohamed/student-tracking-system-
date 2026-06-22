function StatCard({
  title = 'Stat',
  value = '-',
  icon = '•',
  color = 'blue',
  subtitle = '',
}) {
  return (
    <article className={`stat-card stat-card-${color}`}>
      <span className="stat-card-icon">{icon}</span>
      <p className="stat-card-title">{title}</p>
      <p className="stat-card-value">{value}</p>
      {subtitle ? <p className="stat-card-subtitle">{subtitle}</p> : null}
    </article>
  )
}

export default StatCard
