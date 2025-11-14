import { useState } from 'react'
import { useAuth } from '../context/AuthContext'
import Clientes from './Clientes'
import Citas from './Citas'
import DashboardHome from './DashboardHome'
import './Dashboard.css'

const Dashboard = () => {
  const { user, signOut } = useAuth()
  const [currentView, setCurrentView] = useState('home')

  const handleSignOut = async () => {
    try {
      await signOut()
    } catch (error) {
      console.error('Error al cerrar sesión:', error)
    }
  }

  const renderContent = () => {
    switch (currentView) {
      case 'clientes':
        return <Clientes />
      case 'citas':
        return <Citas />
      case 'home':
      default:
        return <DashboardHome />
    }
  }

  return (
    <div className="dashboard-container">
      <nav className="navbar navbar-expand-lg navbar-dark bg-primary">
        <div className="container-fluid">
          <span className="navbar-brand" style={{ cursor: 'pointer' }} onClick={() => setCurrentView('home')}>
            <i className="bi bi-heart-pulse-fill me-2"></i>
            Clínica Dental Sonrisa
          </span>

          <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span className="navbar-toggler-icon"></span>
          </button>

          <div className="collapse navbar-collapse" id="navbarNav">
            <ul className="navbar-nav me-auto">
              <li className="nav-item">
                <a
                  className={`nav-link ${currentView === 'home' ? 'active' : ''}`}
                  onClick={() => setCurrentView('home')}
                  style={{ cursor: 'pointer' }}
                >
                  <i className="bi bi-house-door me-1"></i>
                  Inicio
                </a>
              </li>
              <li className="nav-item">
                <a
                  className={`nav-link ${currentView === 'clientes' ? 'active' : ''}`}
                  onClick={() => setCurrentView('clientes')}
                  style={{ cursor: 'pointer' }}
                >
                  <i className="bi bi-people me-1"></i>
                  Clientes
                </a>
              </li>
              <li className="nav-item">
                <a
                  className={`nav-link ${currentView === 'citas' ? 'active' : ''}`}
                  onClick={() => setCurrentView('citas')}
                  style={{ cursor: 'pointer' }}
                >
                  <i className="bi bi-calendar-check me-1"></i>
                  Citas
                </a>
              </li>
              <li className="nav-item">
                <a
                  className={`nav-link ${currentView === 'pagos' ? 'active' : ''}`}
                  onClick={() => setCurrentView('pagos')}
                  style={{ cursor: 'pointer' }}
                >
                  <i className="bi bi-cash-coin me-1"></i>
                  Pagos
                </a>
              </li>
            </ul>

            <div className="d-flex align-items-center">
              <span className="text-white me-3">
                <i className="bi bi-person-circle me-2"></i>
                {user?.email}
              </span>
              <button className="btn btn-outline-light btn-sm" onClick={handleSignOut}>
                <i className="bi bi-box-arrow-right me-2"></i>
                Cerrar Sesión
              </button>
            </div>
          </div>
        </div>
      </nav>

      {renderContent()}
    </div>
  )
}

export default Dashboard
