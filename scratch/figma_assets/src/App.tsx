import { useState, useEffect } from 'react'
import type { NavTab } from './types'
import BottomNav from './components/BottomNav'
import Auth from './screens/Auth'
import Home from './screens/Home'
import Workout from './screens/Workout'
import Routines from './screens/Routines'
import Stats from './screens/Stats'
import AICoach from './screens/AICoach'
import Profile from './screens/Profile'

export default function App() {
  const [authed, setAuthed] = useState(false)
  const [tab, setTab] = useState<NavTab>('home')
  const [isWorkoutActive, setIsWorkoutActive] = useState(false)
  const [showWorkout, setShowWorkout] = useState(false)
  const [workoutSeconds, setWorkoutSeconds] = useState(0)

  useEffect(() => {
    if (!isWorkoutActive) return
    const id = setInterval(() => setWorkoutSeconds((s) => s + 1), 1000)
    return () => clearInterval(id)
  }, [isWorkoutActive])

  function startWorkout(_routineId?: string) {
    setIsWorkoutActive(true)
    setWorkoutSeconds(0)
    setShowWorkout(true)
    setTab('home')
  }

  function finishWorkout() {
    setIsWorkoutActive(false)
    setShowWorkout(false)
    setWorkoutSeconds(0)
  }

  if (!authed) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'flex-start', height: '100dvh', background: '#050505' }}>
        <div style={{ width: '100%', maxWidth: 430, height: '100dvh', position: 'relative', overflow: 'hidden' }}>
          <Auth onAuth={() => setAuthed(true)} />
        </div>
      </div>
    )
  }

  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'flex-start', height: '100dvh', background: '#050505' }}>
      <div style={{ width: '100%', maxWidth: 430, height: '100dvh', position: 'relative', overflow: 'hidden', background: '#0A0C0A' }}>

        {/* Full-screen workout overlay */}
        {showWorkout && (
          <div style={{ position: 'absolute', inset: 0, zIndex: 40, background: '#0A0C0A' }}>
            <Workout seconds={workoutSeconds} onFinish={finishWorkout} />
          </div>
        )}

        {/* Main tab screens */}
        {!showWorkout && (
          <>
            {tab === 'home' && (
              <Home
                isWorkoutActive={isWorkoutActive}
                workoutSeconds={workoutSeconds}
                onStartWorkout={startWorkout}
                onContinueWorkout={() => setShowWorkout(true)}
                onFinishWorkout={finishWorkout}
              />
            )}
            {tab === 'routines' && <Routines />}
            {tab === 'stats' && <Stats />}
            {tab === 'ai' && <AICoach />}
            {tab === 'profile' && <Profile onLogout={() => { setAuthed(false); setIsWorkoutActive(false); setShowWorkout(false) }} />}
          </>
        )}

        {/* Bottom nav — hidden during workout */}
        {!showWorkout && <BottomNav active={tab} onChange={setTab} />}

        {/* Active workout floating indicator */}
        {isWorkoutActive && !showWorkout && (
          <button
            onClick={() => setShowWorkout(true)}
            style={{
              position: 'absolute', bottom: 84, right: 20, zIndex: 45,
              background: '#C6FF3D', border: 'none', borderRadius: 14, cursor: 'pointer',
              padding: '10px 16px', display: 'flex', alignItems: 'center', gap: 8,
              boxShadow: '0 4px 24px rgba(198,255,61,0.3)',
            }}
          >
            <span style={{ fontSize: 14 }}>▶</span>
            <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 13, fontWeight: 600, color: '#0A0C0A' }}>
              {String(Math.floor(workoutSeconds / 3600)).padStart(2, '0')}:
              {String(Math.floor((workoutSeconds % 3600) / 60)).padStart(2, '0')}:
              {String(workoutSeconds % 60).padStart(2, '0')}
            </span>
          </button>
        )}
      </div>
    </div>
  )
}
