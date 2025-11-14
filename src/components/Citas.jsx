import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabaseClient'
import './Citas.css'

const Citas = () => {
  const [citas, setCitas] = useState([])
  const [clientes, setClientes] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [editingId, setEditingId] = useState(null)
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0])
  const [viewMode, setViewMode] = useState('calendar') // 'calendar' o 'list'

  const [formData, setFormData] = useState({
    appointment_number: '',
    client_name: '',
    client_id_number: '',
    appointment_date: new Date().toISOString().split('T')[0],
    appointment_time: '09:00',
    reason: '',
    cost: '',
    attending_doctor: '',
    notes: ''
  })

  useEffect(() => {
    fetchCitas()
    fetchClientes()
  }, [])

  const fetchCitas = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('citas_medicas')
        .select('*')
        .order('appointment_at', { ascending: true })

      if (error) throw error
      console.log('=== CITAS CARGADAS DESDE SUPABASE ===')
      console.log('Total de citas:', data?.length || 0)
      data?.forEach((cita, index) => {
        console.log(`Cita ${index + 1}:`, {
          id: cita.id,
          appointment_number: cita.appointment_number,
          client_name: cita.client_name,
          appointment_at: cita.appointment_at,
          fecha: new Date(cita.appointment_at).toISOString().split('T')[0],
          hora: new Date(cita.appointment_at).toTimeString().substring(0, 5)
        })
      })
      setCitas(data || [])
    } catch (error) {
      console.error('Error al cargar citas:', error)
      setError('Error al cargar las citas')
    } finally {
      setLoading(false)
    }
  }

  const fetchClientes = async () => {
    try {
      const { data, error } = await supabase
        .from('clientes')
        .select('id_number, name')
        .order('name', { ascending: true })

      if (error) throw error
      setClientes(data || [])
    } catch (error) {
      console.error('Error al cargar clientes:', error)
    }
  }

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))

    // Auto-completar nombre del cliente al seleccionar cédula
    if (name === 'client_id_number') {
      const cliente = clientes.find(c => c.id_number === value)
      if (cliente) {
        setFormData(prev => ({
          ...prev,
          client_name: cliente.name
        }))
      }
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    setLoading(true)

    try {
      // Combinar fecha y hora en formato ISO local (sin zona horaria)
      // Supabase interpretará esto como hora local del servidor
      // Para evitar conversiones, enviamos como string con la hora exacta que queremos
      const appointmentDateTime = `${formData.appointment_date}T${formData.appointment_time}:00`

      console.log('=== GUARDANDO CITA ===')
      console.log('Fecha seleccionada:', formData.appointment_date)
      console.log('Hora seleccionada:', formData.appointment_time)
      console.log('DateTime string:', appointmentDateTime)

      const citaData = {
        client_name: formData.client_name,
        client_id_number: formData.client_id_number,
        appointment_at: appointmentDateTime,
        reason: formData.reason,
        cost: formData.cost ? parseInt(formData.cost) : null,
        attending_doctor: formData.attending_doctor || null,
        notes: formData.notes || null
      }

      console.log('Datos a enviar:', citaData)

      if (editingId) {
        // Actualizar cita existente
        const { error } = await supabase
          .from('citas_medicas')
          .update(citaData)
          .eq('id', editingId)

        if (error) throw error
        setSuccess('Cita actualizada exitosamente')
        setEditingId(null)
      } else {
        // Crear nueva cita
        const { error } = await supabase
          .from('citas_medicas')
          .insert([citaData])

        if (error) throw error
        setSuccess('Cita registrada exitosamente')
      }

      // Limpiar formulario
      setFormData({
        appointment_number: '',
        client_name: '',
        client_id_number: '',
        appointment_date: new Date().toISOString().split('T')[0],
        appointment_time: '09:00',
        reason: '',
        cost: '',
        attending_doctor: '',
        notes: ''
      })

      fetchCitas()
    } catch (error) {
      console.error('Error:', error)
      if (error.message.includes('Ya existe una cita')) {
        setError('Ya existe una cita programada para esta hora. Por favor seleccione otra hora.')
      } else if (error.code === '23503') {
        setError('El cliente con esta cédula no existe. Debe registrar el cliente primero.')
      } else {
        setError(error.message || 'Error al guardar la cita')
      }
    } finally {
      setLoading(false)
    }
  }

  const handleEdit = (cita) => {
    const appointmentDate = new Date(cita.appointment_at)
    const date = appointmentDate.toISOString().split('T')[0]
    const time = appointmentDate.toTimeString().substring(0, 5)

    setFormData({
      appointment_number: cita.appointment_number ? cita.appointment_number.toString().padStart(4, '0') : '',
      client_name: cita.client_name,
      client_id_number: cita.client_id_number,
      appointment_date: date,
      appointment_time: time,
      reason: cita.reason,
      cost: cita.cost || '',
      attending_doctor: cita.attending_doctor || '',
      notes: cita.notes || ''
    })
    setEditingId(cita.id)
    setError('')
    setSuccess('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const handleDelete = async (id) => {
    if (!window.confirm('¿Está seguro de eliminar esta cita?')) {
      return
    }

    try {
      setLoading(true)
      const { error } = await supabase
        .from('citas_medicas')
        .delete()
        .eq('id', id)

      if (error) throw error
      setSuccess('Cita eliminada exitosamente')
      fetchCitas()
    } catch (error) {
      console.error('Error:', error)
      setError('Error al eliminar la cita')
    } finally {
      setLoading(false)
    }
  }

  const handleCancelEdit = () => {
    setEditingId(null)
    setFormData({
      appointment_number: '',
      client_name: '',
      client_id_number: '',
      appointment_date: new Date().toISOString().split('T')[0],
      appointment_time: '09:00',
      reason: '',
      cost: '',
      attending_doctor: '',
      notes: ''
    })
    setError('')
    setSuccess('')
  }

  const formatDateTime = (dateString) => {
    const options = {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    }
    return new Date(dateString).toLocaleDateString('es-ES', options)
  }


  // Generar horarios disponibles (8:00 AM - 6:00 PM)
  const generateTimeSlots = () => {
    const slots = []
    for (let hour = 8; hour < 18; hour++) {
      slots.push(`${hour.toString().padStart(2, '0')}:00`)
    }
    return slots
  }

  // Obtener citas del día seleccionado
  const getAppointmentsByDate = (date) => {
    const citasDelDia = citas.filter(cita => {
      // Crear fecha local sin conversión de zona horaria
      const appointmentDate = new Date(cita.appointment_at)
      const year = appointmentDate.getFullYear()
      const month = String(appointmentDate.getMonth() + 1).padStart(2, '0')
      const day = String(appointmentDate.getDate()).padStart(2, '0')
      const citaDate = `${year}-${month}-${day}`

      console.log('Comparando:', citaDate, '===', date, '→', citaDate === date)
      return citaDate === date
    })

    console.log('Citas del día', date, ':', citasDelDia.length)
    return citasDelDia
  }

  // Vista de calendario
  const renderCalendarView = () => {
    const timeSlots = generateTimeSlots()
    const appointmentsToday = getAppointmentsByDate(selectedDate)

    return (
      <div className="calendar-view">
        <div className="calendar-header mb-3 d-flex justify-content-between align-items-center">
          <div>
            <label htmlFor="selectedDate" className="form-label me-2">Fecha:</label>
            <input
              type="date"
              id="selectedDate"
              className="form-control form-control-sm d-inline-block w-auto"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
            />
          </div>
          <div className="badge bg-info">
            {appointmentsToday.length} cita{appointmentsToday.length !== 1 ? 's' : ''} programada{appointmentsToday.length !== 1 ? 's' : ''}
          </div>
        </div>

        <div className="calendar-grid">
          {timeSlots.map(time => {
            const cita = appointmentsToday.find(c => {
              const appointmentDate = new Date(c.appointment_at)
              const hours = String(appointmentDate.getHours()).padStart(2, '0')
              const minutes = String(appointmentDate.getMinutes()).padStart(2, '0')
              const citaTime = `${hours}:${minutes}`

              console.log('Buscando cita a las', time, '- Cita en', citaTime, '→', citaTime === time)
              return citaTime === time
            })

            return (
              <div key={time} className={`time-slot ${cita ? 'occupied' : 'available'}`}>
                <div className="time-label">{time}</div>
                {cita ? (
                  <div className="appointment-info">
                    <strong>{cita.client_name}</strong>
                    <div className="small">{cita.reason}</div>
                    <div className="small">Doctor: {cita.attending_doctor || 'N/A'}</div>
                    <div className="small">Costo: ${cita.cost || '0'}</div>
                    <div className="appointment-actions mt-2">
                      <button
                        className="btn btn-sm btn-outline-primary me-1"
                        onClick={() => handleEdit(cita)}
                        disabled={loading}
                      >
                        <i className="bi bi-pencil"></i>
                      </button>
                      <button
                        className="btn btn-sm btn-outline-danger"
                        onClick={() => handleDelete(cita.id)}
                        disabled={loading}
                      >
                        <i className="bi bi-trash"></i>
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="no-appointment">
                    <i className="bi bi-plus-circle"></i> Disponible
                  </div>
                )}
              </div>
            )
          })}
        </div>
      </div>
    )
  }

  return (
    <div className="citas-container">
      <div className="citas-header">
        <h2>
          <i className="bi bi-calendar-check me-2"></i>
          Gestión de Citas
        </h2>
        <p className="text-muted">Programa y administra las citas de la clínica</p>
      </div>

      {/* Formulario de registro */}
      <div className="card mb-4">
        <div className="card-body">
          <h5 className="card-title mb-4">
            {editingId ? (
              <>
                <i className="bi bi-pencil-square me-2"></i>
                Editar Cita
              </>
            ) : (
              <>
                <i className="bi bi-plus-circle-fill me-2"></i>
                Nueva Cita
              </>
            )}
          </h5>

          {error && (
            <div className="alert alert-danger alert-dismissible fade show" role="alert">
              <i className="bi bi-exclamation-triangle-fill me-2"></i>
              {error}
              <button type="button" className="btn-close" onClick={() => setError('')}></button>
            </div>
          )}

          {success && (
            <div className="alert alert-success alert-dismissible fade show" role="alert">
              <i className="bi bi-check-circle-fill me-2"></i>
              {success}
              <button type="button" className="btn-close" onClick={() => setSuccess('')}></button>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="row">
              <div className="col-md-6 mb-3">
                <label htmlFor="appointment_number" className="form-label">
                  Número de Cita
                </label>
                <input
                  type="text"
                  className="form-control"
                  id="appointment_number"
                  name="appointment_number"
                  value={formData.appointment_number}
                  disabled
                  placeholder={editingId ? "" : "Se genera automáticamente"}
                  style={{ backgroundColor: '#e9ecef' }}
                />
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="client_id_number" className="form-label">
                  Cédula del Cliente <span className="text-danger">*</span>
                </label>
                <select
                  className="form-select"
                  id="client_id_number"
                  name="client_id_number"
                  value={formData.client_id_number}
                  onChange={handleInputChange}
                  required
                  disabled={loading}
                >
                  <option value="">Seleccione un cliente</option>
                  {clientes.map(cliente => (
                    <option key={cliente.id_number} value={cliente.id_number}>
                      {cliente.id_number} - {cliente.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="client_name" className="form-label">
                  Nombre del Cliente <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  className="form-control"
                  id="client_name"
                  name="client_name"
                  value={formData.client_name}
                  onChange={handleInputChange}
                  required
                  disabled={loading}
                  placeholder="Se completa automáticamente"
                  readOnly
                />
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="appointment_date" className="form-label">
                  Fecha de la Cita <span className="text-danger">*</span>
                </label>
                <input
                  type="date"
                  className="form-control"
                  id="appointment_date"
                  name="appointment_date"
                  value={formData.appointment_date}
                  onChange={handleInputChange}
                  required
                  disabled={loading}
                  min={new Date().toISOString().split('T')[0]}
                />
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="appointment_time" className="form-label">
                  Hora de la Cita <span className="text-danger">*</span>
                </label>
                <select
                  className="form-select"
                  id="appointment_time"
                  name="appointment_time"
                  value={formData.appointment_time}
                  onChange={handleInputChange}
                  required
                  disabled={loading}
                >
                  {generateTimeSlots().map(time => (
                    <option key={time} value={time}>{time}</option>
                  ))}
                </select>
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="reason" className="form-label">
                  Razón de la Cita <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  className="form-control"
                  id="reason"
                  name="reason"
                  value={formData.reason}
                  onChange={handleInputChange}
                  required
                  disabled={loading}
                  placeholder="Ej: Limpieza dental, Extracción, Consulta"
                />
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="cost" className="form-label">
                  Costo (USD)
                </label>
                <input
                  type="number"
                  step="1"
                  min="0"
                  className="form-control"
                  id="cost"
                  name="cost"
                  value={formData.cost}
                  onChange={handleInputChange}
                  disabled={loading}
                  placeholder="0"
                />
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="attending_doctor" className="form-label">
                  Doctor Encargado
                </label>
                <input
                  type="text"
                  className="form-control"
                  id="attending_doctor"
                  name="attending_doctor"
                  value={formData.attending_doctor}
                  onChange={handleInputChange}
                  disabled={loading}
                  placeholder="Nombre del doctor"
                />
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="notes" className="form-label">
                  Notas Adicionales
                </label>
                <textarea
                  className="form-control"
                  id="notes"
                  name="notes"
                  rows="2"
                  value={formData.notes}
                  onChange={handleInputChange}
                  disabled={loading}
                  placeholder="Observaciones o instrucciones especiales"
                ></textarea>
              </div>
            </div>

            <div className="d-flex gap-2">
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? (
                  <>
                    <span className="spinner-border spinner-border-sm me-2"></span>
                    Procesando...
                  </>
                ) : editingId ? (
                  <>
                    <i className="bi bi-save me-2"></i>
                    Actualizar Cita
                  </>
                ) : (
                  <>
                    <i className="bi bi-plus-circle me-2"></i>
                    Registrar Cita
                  </>
                )}
              </button>

              {editingId && (
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={handleCancelEdit}
                  disabled={loading}
                >
                  <i className="bi bi-x-circle me-2"></i>
                  Cancelar
                </button>
              )}
            </div>
          </form>
        </div>
      </div>

      {/* Vista de citas */}
      <div className="card">
        <div className="card-body">
          <div className="d-flex justify-content-between align-items-center mb-4">
            <h5 className="card-title mb-0">
              <i className="bi bi-list-ul me-2"></i>
              {viewMode === 'calendar' ? 'Calendario de Citas' : `Listado de Citas (${citas.length})`}
            </h5>
            <div className="btn-group" role="group">
              <button
                type="button"
                className={`btn btn-sm ${viewMode === 'calendar' ? 'btn-primary' : 'btn-outline-primary'}`}
                onClick={() => setViewMode('calendar')}
              >
                <i className="bi bi-calendar3 me-1"></i>
                Calendario
              </button>
              <button
                type="button"
                className={`btn btn-sm ${viewMode === 'list' ? 'btn-primary' : 'btn-outline-primary'}`}
                onClick={() => setViewMode('list')}
              >
                <i className="bi bi-list me-1"></i>
                Lista
              </button>
            </div>
          </div>

          {viewMode === 'calendar' ? (
            renderCalendarView()
          ) : (
            <div className="table-responsive">
              <table className="table table-hover table-striped">
                <thead className="table-primary">
                  <tr>
                    <th>N° Cita</th>
                    <th>Fecha y Hora</th>
                    <th>Cliente</th>
                    <th>Cédula</th>
                    <th>Razón</th>
                    <th>Doctor</th>
                    <th>Costo</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {loading && citas.length === 0 ? (
                    <tr>
                      <td colSpan="8" className="text-center py-4">
                        <div className="spinner-border text-primary" role="status">
                          <span className="visually-hidden">Cargando...</span>
                        </div>
                      </td>
                    </tr>
                  ) : citas.length === 0 ? (
                    <tr>
                      <td colSpan="8" className="text-center py-4 text-muted">
                        <i className="bi bi-inbox display-4 d-block mb-2"></i>
                        No hay citas registradas
                      </td>
                    </tr>
                  ) : (
                    citas.map((cita) => (
                      <tr key={cita.id}>
                        <td>{cita.appointment_number ? cita.appointment_number.toString().padStart(4, '0') : 'N/A'}</td>
                        <td>{formatDateTime(cita.appointment_at)}</td>
                        <td>{cita.client_name}</td>
                        <td>{cita.client_id_number}</td>
                        <td>{cita.reason}</td>
                        <td>{cita.attending_doctor || 'N/A'}</td>
                        <td>${cita.cost || '0'}</td>
                        <td>
                          <div className="btn-group" role="group">
                            <button
                              className="btn btn-sm btn-outline-primary"
                              onClick={() => handleEdit(cita)}
                              disabled={loading}
                              title="Editar"
                            >
                              <i className="bi bi-pencil"></i>
                            </button>
                            <button
                              className="btn btn-sm btn-outline-danger"
                              onClick={() => handleDelete(cita.id)}
                              disabled={loading}
                              title="Eliminar"
                            >
                              <i className="bi bi-trash"></i>
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default Citas
