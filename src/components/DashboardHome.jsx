import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabaseClient'
import './DashboardHome.css'

const DashboardHome = () => {
  const [citas, setCitas] = useState([])
  const [clientes, setClientes] = useState([])
  const [loading, setLoading] = useState(true)
  const [weeklyData, setWeeklyData] = useState({
    lunes: 0,
    martes: 0,
    miercoles: 0,
    jueves: 0,
    viernes: 0
  })
  const [upcomingAppointments, setUpcomingAppointments] = useState([])

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)

      // Cargar citas
      const { data: citasData, error: citasError } = await supabase
        .from('citas_medicas')
        .select('*')
        .order('appointment_at', { ascending: true })

      if (citasError) throw citasError

      // Cargar clientes
      const { data: clientesData, error: clientesError } = await supabase
        .from('clientes')
        .select('*')

      if (clientesError) throw clientesError

      setCitas(citasData || [])
      setClientes(clientesData || [])

      // Procesar datos para el gráfico semanal
      processWeeklyData(citasData || [])

      // Procesar próximas citas
      processUpcomingAppointments(citasData || [])

    } catch (error) {
      console.error('Error al cargar datos:', error)
    } finally {
      setLoading(false)
    }
  }

  const processWeeklyData = (citasData) => {
    // Obtener el lunes de esta semana
    const today = new Date()
    const dayOfWeek = today.getDay() // 0 = Domingo, 1 = Lunes, ..., 6 = Sábado
    const diff = dayOfWeek === 0 ? -6 : 1 - dayOfWeek // Ajustar para empezar en lunes
    const monday = new Date(today)
    monday.setDate(today.getDate() + diff)
    monday.setHours(0, 0, 0, 0)

    // Inicializar contadores
    const weekData = {
      lunes: 0,
      martes: 0,
      miercoles: 0,
      jueves: 0,
      viernes: 0
    }

    // Contar citas por día
    citasData.forEach(cita => {
      const citaDate = new Date(cita.appointment_at)
      const citaDayOfWeek = citaDate.getDay()

      // Solo contar si está en esta semana (Lunes a Viernes)
      const diffDays = Math.floor((citaDate - monday) / (1000 * 60 * 60 * 24))

      if (diffDays >= 0 && diffDays < 7) {
        switch (citaDayOfWeek) {
          case 1: weekData.lunes++; break
          case 2: weekData.martes++; break
          case 3: weekData.miercoles++; break
          case 4: weekData.jueves++; break
          case 5: weekData.viernes++; break
          default: break
        }
      }
    })

    setWeeklyData(weekData)
  }

  const processUpcomingAppointments = (citasData) => {
    const now = new Date()

    // Filtrar citas futuras
    const upcoming = citasData
      .filter(cita => new Date(cita.appointment_at) >= now)
      .slice(0, 5) // Mostrar solo las próximas 5
      .map(cita => ({
        ...cita,
        daysUntil: Math.ceil((new Date(cita.appointment_at) - now) / (1000 * 60 * 60 * 24))
      }))

    setUpcomingAppointments(upcoming)
  }

  const formatDateTime = (dateString) => {
    const date = new Date(dateString)
    const options = {
      weekday: 'short',
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }
    return date.toLocaleDateString('es-ES', options)
  }

  const getMaxValue = () => {
    const values = Object.values(weeklyData)
    const max = Math.max(...values)
    return max > 0 ? max : 5 // Mínimo 5 para que la escala se vea bien
  }

  const getBarHeight = (value) => {
    const max = getMaxValue()
    return `${(value / max) * 100}%`
  }

  const getUrgencyClass = (daysUntil) => {
    if (daysUntil === 0) return 'urgent-today'
    if (daysUntil === 1) return 'urgent-tomorrow'
    if (daysUntil <= 3) return 'urgent-soon'
    return 'urgent-later'
  }

  const getUrgencyText = (daysUntil) => {
    if (daysUntil === 0) return 'Hoy'
    if (daysUntil === 1) return 'Mañana'
    return `En ${daysUntil} días`
  }

  if (loading) {
    return (
      <div className="dashboard-home">
        <div className="text-center py-5">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Cargando...</span>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="dashboard-home">
      {/* Header */}
      <div className="dashboard-header">
        <h2>
          <i className="bi bi-speedometer2 me-2"></i>
          Panel de Control
        </h2>
        <p className="text-muted">Resumen de la clínica dental</p>
      </div>

      {/* Tarjetas de Estadísticas */}
      <div className="row mb-4">
        <div className="col-md-3 mb-3">
          <div className="stat-card stat-card-primary">
            <div className="stat-icon">
              <i className="bi bi-calendar-check"></i>
            </div>
            <div className="stat-content">
              <div className="stat-value">{citas.length}</div>
              <div className="stat-label">Total Citas</div>
            </div>
          </div>
        </div>

        <div className="col-md-3 mb-3">
          <div className="stat-card stat-card-success">
            <div className="stat-icon">
              <i className="bi bi-people"></i>
            </div>
            <div className="stat-content">
              <div className="stat-value">{clientes.length}</div>
              <div className="stat-label">Clientes Registrados</div>
            </div>
          </div>
        </div>

        <div className="col-md-3 mb-3">
          <div className="stat-card stat-card-info">
            <div className="stat-icon">
              <i className="bi bi-calendar-week"></i>
            </div>
            <div className="stat-content">
              <div className="stat-value">
                {Object.values(weeklyData).reduce((a, b) => a + b, 0)}
              </div>
              <div className="stat-label">Citas Esta Semana</div>
            </div>
          </div>
        </div>

        <div className="col-md-3 mb-3">
          <div className="stat-card stat-card-warning">
            <div className="stat-icon">
              <i className="bi bi-bell"></i>
            </div>
            <div className="stat-content">
              <div className="stat-value">{upcomingAppointments.length}</div>
              <div className="stat-label">Próximas Citas</div>
            </div>
          </div>
        </div>
      </div>

      {/* Gráfico de Barras y Notificaciones */}
      <div className="row">
        {/* Gráfico de Barras de Citas Semanales */}
        <div className="col-lg-8 mb-4">
          <div className="card chart-card">
            <div className="card-body">
              <h5 className="card-title mb-4">
                <i className="bi bi-bar-chart-fill me-2"></i>
                Citas por Día (Lunes - Viernes)
              </h5>

              <div className="bar-chart-container">
                <div className="bar-chart">
                  {Object.entries(weeklyData).map(([day, value]) => (
                    <div key={day} className="bar-wrapper">
                      <div className="bar-value">{value}</div>
                      <div className="bar" style={{ height: getBarHeight(value) }}>
                        <div className="bar-fill"></div>
                      </div>
                      <div className="bar-label">{day.charAt(0).toUpperCase() + day.slice(1, 3)}</div>
                    </div>
                  ))}
                </div>

                <div className="chart-info mt-3">
                  <small className="text-muted">
                    <i className="bi bi-info-circle me-1"></i>
                    Mostrando citas programadas de Lunes a Viernes de esta semana
                  </small>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Panel de Notificaciones */}
        <div className="col-lg-4 mb-4">
          <div className="card notifications-card">
            <div className="card-body">
              <h5 className="card-title mb-4">
                <i className="bi bi-bell-fill me-2"></i>
                Próximas Citas
              </h5>

              {upcomingAppointments.length === 0 ? (
                <div className="text-center py-4">
                  <i className="bi bi-calendar-x display-4 text-muted mb-3"></i>
                  <p className="text-muted">No hay citas próximas programadas</p>
                </div>
              ) : (
                <div className="notifications-list">
                  {upcomingAppointments.map((cita) => (
                    <div key={cita.id} className={`notification-item ${getUrgencyClass(cita.daysUntil)}`}>
                      <div className="notification-time">
                        <span className="badge">{getUrgencyText(cita.daysUntil)}</span>
                      </div>
                      <div className="notification-content">
                        <div className="notification-title">
                          <i className="bi bi-person-fill me-2"></i>
                          {cita.client_name}
                        </div>
                        <div className="notification-details">
                          <i className="bi bi-clock me-1"></i>
                          {formatDateTime(cita.appointment_at)}
                        </div>
                        <div className="notification-reason">
                          <i className="bi bi-file-text me-1"></i>
                          {cita.reason}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Recordatorios */}
          <div className="card reminders-card mt-4">
            <div className="card-body">
              <h5 className="card-title mb-3">
                <i className="bi bi-journal-check me-2"></i>
                Recordatorios
              </h5>

              <div className="reminders-list">
                <div className="reminder-item">
                  <i className="bi bi-check-circle-fill text-success"></i>
                  <span>Revisar inventario de materiales</span>
                </div>
                <div className="reminder-item">
                  <i className="bi bi-check-circle-fill text-warning"></i>
                  <span>Confirmar citas del día siguiente</span>
                </div>
                <div className="reminder-item">
                  <i className="bi bi-check-circle-fill text-info"></i>
                  <span>Actualizar historial de pacientes</span>
                </div>
                <div className="reminder-item">
                  <i className="bi bi-check-circle-fill text-primary"></i>
                  <span>Revisar pagos pendientes</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default DashboardHome
