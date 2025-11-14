import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabaseClient'
import './Clientes.css'

const Clientes = () => {
  const [clientes, setClientes] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [editingId, setEditingId] = useState(null)

  const [formData, setFormData] = useState({
    name: '',
    id_number: '',
    phone: '',
    email: '',
    direccion: ''
  })

  // Cargar clientes al montar el componente
  useEffect(() => {
    fetchClientes()
  }, [])

  const fetchClientes = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('clientes')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      setClientes(data || [])
    } catch (error) {
      console.error('Error al cargar clientes:', error)
      setError('Error al cargar la lista de clientes')
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    setLoading(true)

    try {
      if (editingId) {
        // Actualizar cliente existente
        const { error } = await supabase
          .from('clientes')
          .update({
            name: formData.name,
            id_number: formData.id_number,
            phone: formData.phone,
            email: formData.email,
            direccion: formData.direccion
          })
          .eq('id_cliente', editingId)

        if (error) throw error
        setSuccess('Cliente actualizado exitosamente')
        setEditingId(null)
      } else {
        // Crear nuevo cliente
        const { error } = await supabase
          .from('clientes')
          .insert([{
            name: formData.name,
            id_number: formData.id_number,
            phone: formData.phone,
            email: formData.email,
            direccion: formData.direccion
          }])

        if (error) throw error
        setSuccess('Cliente registrado exitosamente')
      }

      // Limpiar formulario
      setFormData({
        name: '',
        id_number: '',
        phone: '',
        email: '',
        direccion: ''
      })

      // Recargar lista
      fetchClientes()
    } catch (error) {
      console.error('Error:', error)
      if (error.code === '23505') {
        setError('Ya existe un cliente con ese número de cédula')
      } else {
        setError(error.message || 'Error al guardar el cliente')
      }
    } finally {
      setLoading(false)
    }
  }

  const handleEdit = (cliente) => {
    setFormData({
      name: cliente.name,
      id_number: cliente.id_number,
      phone: cliente.phone || '',
      email: cliente.email || '',
      direccion: cliente.direccion || ''
    })
    setEditingId(cliente.id_cliente)
    setError('')
    setSuccess('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const handleDelete = async (id) => {
    if (!window.confirm('¿Está seguro de eliminar este cliente?')) {
      return
    }

    try {
      setLoading(true)
      const { error } = await supabase
        .from('clientes')
        .delete()
        .eq('id_cliente', id)

      if (error) throw error
      setSuccess('Cliente eliminado exitosamente')
      fetchClientes()
    } catch (error) {
      console.error('Error:', error)
      setError('Error al eliminar el cliente')
    } finally {
      setLoading(false)
    }
  }

  const handleCancelEdit = () => {
    setEditingId(null)
    setFormData({
      name: '',
      id_number: '',
      phone: '',
      email: '',
      direccion: ''
    })
    setError('')
    setSuccess('')
  }

  const formatDate = (dateString) => {
    const options = { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }
    return new Date(dateString).toLocaleDateString('es-ES', options)
  }

  return (
    <div className="clientes-container">
      <div className="clientes-header">
        <h2>
          <i className="bi bi-people-fill me-2"></i>
          Gestión de Clientes
        </h2>
        <p className="text-muted">Registra y administra los clientes de la clínica</p>
      </div>

      {/* Formulario de registro */}
      <div className="card mb-4">
        <div className="card-body">
          <h5 className="card-title mb-4">
            {editingId ? (
              <>
                <i className="bi bi-pencil-square me-2"></i>
                Editar Cliente
              </>
            ) : (
              <>
                <i className="bi bi-person-plus-fill me-2"></i>
                Nuevo Cliente
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
                <label htmlFor="name" className="form-label">
                  Nombres y Apellidos <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  className="form-control"
                  id="name"
                  name="name"
                  value={formData.name}
                  onChange={handleInputChange}
                  required
                  disabled={loading}
                  placeholder="Juan Pérez García"
                />
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="id_number" className="form-label">
                  Número de Cédula <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  className="form-control"
                  id="id_number"
                  name="id_number"
                  value={formData.id_number}
                  onChange={handleInputChange}
                  required
                  disabled={loading || editingId}
                  placeholder="1234567890"
                />
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="phone" className="form-label">
                  Número de Teléfono
                </label>
                <input
                  type="tel"
                  className="form-control"
                  id="phone"
                  name="phone"
                  value={formData.phone}
                  onChange={handleInputChange}
                  disabled={loading}
                  placeholder="0991234567"
                />
              </div>

              <div className="col-md-6 mb-3">
                <label htmlFor="email" className="form-label">
                  Email
                </label>
                <input
                  type="email"
                  className="form-control"
                  id="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  disabled={loading}
                  placeholder="correo@ejemplo.com"
                />
              </div>

              <div className="col-12 mb-3">
                <label htmlFor="direccion" className="form-label">
                  Dirección
                </label>
                <textarea
                  className="form-control"
                  id="direccion"
                  name="direccion"
                  rows="2"
                  value={formData.direccion}
                  onChange={handleInputChange}
                  disabled={loading}
                  placeholder="Calle principal, ciudad, provincia"
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
                    Actualizar Cliente
                  </>
                ) : (
                  <>
                    <i className="bi bi-plus-circle me-2"></i>
                    Registrar Cliente
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

      {/* Tabla de clientes */}
      <div className="card">
        <div className="card-body">
          <h5 className="card-title mb-4">
            <i className="bi bi-list-ul me-2"></i>
            Lista de Clientes ({clientes.length})
          </h5>

          <div className="table-responsive">
            <table className="table table-hover table-striped">
              <thead className="table-primary">
                <tr>
                  <th>Nombre</th>
                  <th>Cédula</th>
                  <th>Teléfono</th>
                  <th>Email</th>
                  <th>Dirección</th>
                  <th>Fecha Registro</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {loading && clientes.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="text-center py-4">
                      <div className="spinner-border text-primary" role="status">
                        <span className="visually-hidden">Cargando...</span>
                      </div>
                    </td>
                  </tr>
                ) : clientes.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="text-center py-4 text-muted">
                      <i className="bi bi-inbox display-4 d-block mb-2"></i>
                      No hay clientes registrados
                    </td>
                  </tr>
                ) : (
                  clientes.map((cliente) => (
                    <tr key={cliente.id_cliente}>
                      <td>{cliente.name}</td>
                      <td>{cliente.id_number}</td>
                      <td>{cliente.phone || '-'}</td>
                      <td>{cliente.email || '-'}</td>
                      <td>{cliente.direccion || '-'}</td>
                      <td>{formatDate(cliente.created_at)}</td>
                      <td>
                        <div className="btn-group" role="group">
                          <button
                            className="btn btn-sm btn-outline-primary"
                            onClick={() => handleEdit(cliente)}
                            disabled={loading}
                            title="Editar"
                          >
                            <i className="bi bi-pencil"></i>
                          </button>
                          <button
                            className="btn btn-sm btn-outline-danger"
                            onClick={() => handleDelete(cliente.id_cliente)}
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
        </div>
      </div>
    </div>
  )
}

export default Clientes
