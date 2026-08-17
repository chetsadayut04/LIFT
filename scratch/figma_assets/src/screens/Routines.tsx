import { useState } from 'react'
import { ROUTINES } from '../data'
import type { Routine } from '../types'

export default function Routines() {
  const [routines, setRoutines] = useState<Routine[]>(ROUTINES)
  const [showQR, setShowQR] = useState<string | null>(null)
  const [showNew, setShowNew] = useState(false)
  const [newName, setNewName] = useState('')

  function deleteRoutine(id: string) {
    setRoutines((prev) => prev.filter((r) => r.id !== id))
  }

  function addRoutine() {
    if (!newName.trim()) return
    setRoutines((prev) => [
      ...prev,
      {
        id: `custom-${Date.now()}`,
        name: newName.trim(),
        gradient: 'linear-gradient(135deg,#374151 0%,#111827 100%)',
        exercises: [],
      },
    ])
    setNewName('')
    setShowNew(false)
  }

  const qrRoutine = routines.find((r) => r.id === showQR)

  return (
    <div style={{ height: '100%', background: '#0A0C0A', display: 'flex', flexDirection: 'column', paddingBottom: 72 }}>
      {/* Header */}
      <div style={{ padding: '52px 20px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
        <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 30, fontWeight: 800, color: '#F2F5EF', letterSpacing: '-0.5px' }}>ตารางของฉัน</div>
        <div style={{ display: 'flex', gap: 8 }}>
          {/* Import QR */}
          <button style={{ width: 38, height: 38, borderRadius: 10, background: '#1E211F', border: '1px solid rgba(255,255,255,0.08)', color: '#8E9A8E', fontSize: 16, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }} title="นำเข้าตาราง">
            📷
          </button>
          {/* New */}
          <button onClick={() => setShowNew(true)} style={{ width: 38, height: 38, borderRadius: 10, background: '#C6FF3D', border: 'none', color: '#0A0C0A', fontSize: 22, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700 }}>
            +
          </button>
        </div>
      </div>

      {/* List */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '16px 20px' }}>
        {routines.map((r) => (
          <div key={r.id} style={{ marginBottom: 14, background: '#1B1F1B', borderRadius: 16, overflow: 'hidden', border: '1px solid rgba(255,255,255,0.06)' }}>
            {/* Gradient strip */}
            <div style={{ height: 6, background: r.gradient }} />
            <div style={{ padding: '16px 16px 16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 22, fontWeight: 700, color: '#F2F5EF', marginBottom: 4 }}>{r.name}</div>
                  <div style={{ fontSize: 12, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif', marginBottom: 10 }}>{r.exercises.length} ท่าออกกำลังกาย</div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                    {r.exercises.slice(0, 4).map((ex) => (
                      <span key={ex.name} style={{ fontSize: 11, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif', background: 'rgba(255,255,255,0.04)', padding: '3px 8px', borderRadius: 6 }}>
                        {ex.nameTh}
                      </span>
                    ))}
                    {r.exercises.length > 4 && (
                      <span style={{ fontSize: 11, color: '#5A6A5A', fontFamily: 'Sarabun, sans-serif' }}>+{r.exercises.length - 4} อื่นๆ</span>
                    )}
                  </div>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginLeft: 12 }}>
                  {/* QR */}
                  <button onClick={() => setShowQR(r.id)} style={{ width: 34, height: 34, borderRadius: 8, background: '#1E211F', border: '1px solid rgba(255,255,255,0.08)', color: '#8E9A8E', fontSize: 14, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    ▦
                  </button>
                  {/* Delete */}
                  <button onClick={() => deleteRoutine(r.id)} style={{ width: 34, height: 34, borderRadius: 8, background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', color: '#f87171', fontSize: 14, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    🗑
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* QR Modal */}
      {showQR && qrRoutine && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(5,7,5,0.88)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24, zIndex: 200 }} onClick={() => setShowQR(null)}>
          <div className="animate-slide-up" style={{ background: 'rgba(23,27,23,0.92)', backdropFilter: 'blur(40px)', WebkitBackdropFilter: 'blur(40px)', borderRadius: 20, padding: 28, width: '100%', maxWidth: 340, border: '1px solid rgba(198,255,61,0.1)' }} onClick={(e) => e.stopPropagation()}>
            <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 22, fontWeight: 700, color: '#F2F5EF', marginBottom: 4 }}>แชร์ตาราง</div>
            <div style={{ fontSize: 13, color: '#7C8A7C', marginBottom: 20, fontFamily: 'Sarabun, sans-serif' }}>{qrRoutine.name} · {qrRoutine.exercises.length} ท่า</div>
            {/* QR placeholder */}
            <div style={{ background: '#fff', borderRadius: 12, padding: 16, display: 'grid', gridTemplateColumns: 'repeat(9,1fr)', gap: 3, marginBottom: 16 }}>
              {Array.from({ length: 81 }, (_, i) => {
                const corner = (r: number, c: number) => (r < 3 && c < 3) || (r < 3 && c > 5) || (r > 5 && c < 3)
                const row = Math.floor(i / 9), col = i % 9
                const isCorner = corner(row, col)
                const isDark = isCorner || Math.random() > 0.55
                return <div key={i} style={{ aspectRatio: '1', background: isDark ? '#000' : '#fff', borderRadius: 1 }} />
              })}
            </div>
            <div style={{ background: '#0A0C0A', borderRadius: 10, padding: '10px 14px', marginBottom: 16 }}>
              <div style={{ fontSize: 10, color: '#5A6A5A', fontFamily: 'JetBrains Mono, monospace', wordBreak: 'break-all' }}>
                {JSON.stringify({ id: qrRoutine.id, name: qrRoutine.name, ex: qrRoutine.exercises.length }).slice(0, 80)}...
              </div>
            </div>
            <button onClick={() => setShowQR(null)} style={{ width: '100%', padding: '13px', background: '#C6FF3D', border: 'none', borderRadius: 10, color: '#0A0C0A', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 17, fontWeight: 700, cursor: 'pointer' }}>ปิด</button>
          </div>
        </div>
      )}

      {/* New routine modal */}
      {showNew && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(5,7,5,0.88)', display: 'flex', alignItems: 'flex-end', zIndex: 200 }} onClick={() => setShowNew(false)}>
          <div className="animate-slide-up" style={{ width: '100%', background: 'rgba(16,20,16,0.94)', backdropFilter: 'blur(40px)', WebkitBackdropFilter: 'blur(40px)', borderRadius: '20px 20px 0 0', padding: '24px 20px 32px', border: '1px solid rgba(198,255,61,0.09)' }} onClick={(e) => e.stopPropagation()}>
            <div style={{ width: 36, height: 4, background: '#333', borderRadius: 2, margin: '0 auto 20px' }} />
            <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 24, fontWeight: 700, color: '#F2F5EF', marginBottom: 16 }}>สร้างตารางใหม่</div>
            <input
              autoFocus
              placeholder="ชื่อตารางฝึก เช่น Push Day"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && addRoutine()}
              style={{ width: '100%', padding: '14px 16px', background: '#1E211F', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, color: '#F2F5EF', fontSize: 15, fontFamily: 'Sarabun, sans-serif', outline: 'none', marginBottom: 12 }}
            />
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => setShowNew(false)} style={{ flex: 1, padding: '13px', background: '#1E211F', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 10, color: '#8E9A8E', fontFamily: 'Sarabun, sans-serif', fontSize: 14, cursor: 'pointer' }}>ยกเลิก</button>
              <button onClick={addRoutine} style={{ flex: 2, padding: '13px', background: '#C6FF3D', border: 'none', borderRadius: 10, color: '#0A0C0A', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 17, fontWeight: 700, cursor: 'pointer' }}>สร้างตาราง</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
