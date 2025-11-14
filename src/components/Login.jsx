import { useState } from 'react'
import { useAuth } from '../context/AuthContext'
import './Login.css'

const Login = () => {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [showResetPassword, setShowResetPassword] = useState(false)
  const [resetEmail, setResetEmail] = useState('')
  const [resetMessage, setResetMessage] = useState('')

  const { signIn, resetPassword } = useAuth()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await signIn(email, password)
    } catch (error) {
      setError(error.message || 'Error al iniciar sesión')
    } finally {
      setLoading(false)
    }
  }

  const handleResetPassword = async (e) => {
    e.preventDefault()
    setError('')
    setResetMessage('')
    setLoading(true)

    try {
      await resetPassword(resetEmail)
      setResetMessage('Se ha enviado un enlace de recuperación a tu correo electrónico')
      setResetEmail('')
      setTimeout(() => {
        setShowResetPassword(false)
        setResetMessage('')
      }, 3000)
    } catch (error) {
      setError(error.message || 'Error al enviar correo de recuperación')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-container">
      <div className="container">
        <div className="row justify-content-center">
          <div className="col-md-5 col-lg-4">
            <div className="login-card">
              <div className="text-center mb-4">
                <div className="clinic-logo mb-3">
                  <i className="bi bi-heart-pulse-fill"></i>
                </div>
                <h2 className="clinic-name">Clínica Dental Sonrisa</h2>
                <p className="text-muted">Sistema de Gestión Odontológica</p>
              </div>

              {!showResetPassword ? (
                <form onSubmit={handleSubmit}>
                  {error && (
                    <div className="alert alert-danger alert-dismissible fade show" role="alert">
                      {error}
                      <button
                        type="button"
                        className="btn-close"
                        onClick={() => setError('')}
                        aria-label="Close"
                      ></button>
                    </div>
                  )}

                  <div className="mb-3">
                    <label htmlFor="email" className="form-label">
                      Usuario o Email
                    </label>
                    <div className="input-group">
                      <span className="input-group-text">
                        <i className="bi bi-person"></i>
                      </span>
                      <input
                        type="email"
                        className="form-control"
                        id="email"
                        placeholder="correo@ejemplo.com"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        required
                        disabled={loading}
                      />
                    </div>
                  </div>

                  <div className="mb-3">
                    <label htmlFor="password" className="form-label">
                      Contraseña
                    </label>
                    <div className="input-group">
                      <span className="input-group-text">
                        <i className="bi bi-lock"></i>
                      </span>
                      <input
                        type="password"
                        className="form-control"
                        id="password"
                        placeholder="••••••••"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        required
                        disabled={loading}
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="btn btn-primary w-100 mb-3"
                    disabled={loading}
                  >
                    {loading ? (
                      <>
                        <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                        Iniciando sesión...
                      </>
                    ) : (
                      <>
                        <i className="bi bi-box-arrow-in-right me-2"></i>
                        Iniciar Sesión
                      </>
                    )}
                  </button>

                  <div className="text-center">
                    <button
                      type="button"
                      className="btn btn-link text-decoration-none"
                      onClick={() => setShowResetPassword(true)}
                      disabled={loading}
                    >
                      ¿Olvidaste tu contraseña?
                    </button>
                  </div>
                </form>
              ) : (
                <form onSubmit={handleResetPassword}>
                  <div className="mb-3">
                    <button
                      type="button"
                      className="btn btn-link text-decoration-none p-0 mb-3"
                      onClick={() => {
                        setShowResetPassword(false)
                        setError('')
                        setResetMessage('')
                      }}
                    >
                      <i className="bi bi-arrow-left me-2"></i>
                      Volver al inicio de sesión
                    </button>
                  </div>

                  <h4 className="mb-3">Recuperar Contraseña</h4>
                  <p className="text-muted mb-4">
                    Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.
                  </p>

                  {error && (
                    <div className="alert alert-danger alert-dismissible fade show" role="alert">
                      {error}
                      <button
                        type="button"
                        className="btn-close"
                        onClick={() => setError('')}
                        aria-label="Close"
                      ></button>
                    </div>
                  )}

                  {resetMessage && (
                    <div className="alert alert-success alert-dismissible fade show" role="alert">
                      {resetMessage}
                      <button
                        type="button"
                        className="btn-close"
                        onClick={() => setResetMessage('')}
                        aria-label="Close"
                      ></button>
                    </div>
                  )}

                  <div className="mb-3">
                    <label htmlFor="resetEmail" className="form-label">
                      Correo Electrónico
                    </label>
                    <div className="input-group">
                      <span className="input-group-text">
                        <i className="bi bi-envelope"></i>
                      </span>
                      <input
                        type="email"
                        className="form-control"
                        id="resetEmail"
                        placeholder="correo@ejemplo.com"
                        value={resetEmail}
                        onChange={(e) => setResetEmail(e.target.value)}
                        required
                        disabled={loading}
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="btn btn-primary w-100"
                    disabled={loading}
                  >
                    {loading ? (
                      <>
                        <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                        Enviando...
                      </>
                    ) : (
                      <>
                        <i className="bi bi-send me-2"></i>
                        Enviar Enlace de Recuperación
                      </>
                    )}
                  </button>
                </form>
              )}

              <div className="text-center mt-4">
                <small className="text-muted">
                  Sistema de Gestión Odontológica v1.0
                </small>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Login
