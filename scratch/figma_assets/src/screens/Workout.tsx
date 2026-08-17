import { useState } from 'react'
import { INITIAL_WORKOUT, PLATE_COLORS } from '../data'
import type { WorkoutExercise, WorkoutSet } from '../types'

interface Props {
  seconds: number
  onFinish: () => void
}

function formatTime(s: number) {
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = s % 60
  return `${h > 0 ? h + ':' : ''}${m.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`
}

function calcPlates(targetKg: number) {
  const barWeight = 20
  const perSide = (targetKg - barWeight) / 2
  const sizes = [20, 15, 10, 5, 2.5, 1.25]
  const plates: number[] = []
  let remaining = perSide
  for (const size of sizes) {
    while (remaining >= size - 0.001) {
      plates.push(size)
      remaining -= size
    }
  }
  return plates
}

function PlateVisual({ weight, onClick }: { weight: number; onClick: () => void }) {
  const plates = weight > 20 ? calcPlates(weight) : []
  return (
    <button onClick={onClick} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 1, padding: '0 6px' }} title="เปิดเครื่องคิดเลข">
      {/* Bar center */}
      <div style={{ width: 3, height: 24, background: '#333', borderRadius: 1 }} />
      {plates.slice(0, 4).map((p, i) => (
        <div key={i} style={{ width: 5, height: 10 + p * 0.7, background: PLATE_COLORS[p] ?? '#888', borderRadius: 2, opacity: 0.85 }} />
      ))}
      {plates.length === 0 && <div style={{ fontSize: 9, color: '#333', fontFamily: 'JetBrains Mono, monospace' }}>BW</div>}
    </button>
  )
}

function PlateCalcModal({ onClose }: { onClose: () => void }) {
  const [target, setTarget] = useState(100)
  const barWeight = 20
  const plates = target > barWeight ? calcPlates(target) : []

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(5,7,5,0.88)', display: 'flex', alignItems: 'flex-end', zIndex: 200 }} onClick={onClose}>
      <div className="animate-slide-up" style={{ width: '100%', background: 'rgba(16,20,16,0.94)', backdropFilter: 'blur(40px)', WebkitBackdropFilter: 'blur(40px)', borderRadius: '20px 20px 0 0', padding: '24px 20px 32px', border: '1px solid rgba(198,255,61,0.09)' }} onClick={(e) => e.stopPropagation()}>
        <div style={{ width: 36, height: 4, background: '#333', borderRadius: 2, margin: '0 auto 20px' }} />
        <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 22, fontWeight: 700, color: '#F2F5EF', marginBottom: 6 }}>Barbell Plate Calculator</div>
        <div style={{ fontSize: 13, color: '#7C8A7C', marginBottom: 20, fontFamily: 'Sarabun, sans-serif' }}>แกนบาร์ 20 kg · คำนวณแผ่นน้ำหนักต่อด้าน</div>

        {/* Target input */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
          <button onClick={() => setTarget(Math.max(20, target - 2.5))} style={{ width: 40, height: 40, borderRadius: 10, background: '#1E211F', border: '1px solid rgba(255,255,255,0.08)', color: '#C6FF3D', fontSize: 20, cursor: 'pointer' }}>−</button>
          <div style={{ flex: 1, textAlign: 'center' }}>
            <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 36, fontWeight: 600, color: '#C6FF3D' }}>{target}</div>
            <div style={{ fontSize: 12, color: '#7C8A7C' }}>kg เป้าหมาย</div>
          </div>
          <button onClick={() => setTarget(target + 2.5)} style={{ width: 40, height: 40, borderRadius: 10, background: '#1E211F', border: '1px solid rgba(255,255,255,0.08)', color: '#C6FF3D', fontSize: 20, cursor: 'pointer' }}>+</button>
        </div>

        {/* Plate breakdown */}
        <div style={{ background: '#0A0C0A', borderRadius: 14, padding: '16px', marginBottom: 16 }}>
          <div style={{ fontSize: 11, color: '#5A6A5A', fontFamily: 'Barlow Condensed, sans-serif', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 12 }}>แผ่นน้ำหนักต่อด้าน</div>
          {plates.length === 0 ? (
            <div style={{ color: '#333', fontSize: 13, fontFamily: 'Sarabun, sans-serif', textAlign: 'center' }}>ใช้เพียงแกนบาร์</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {/* Plate visual bar */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 2, marginBottom: 8 }}>
                <div style={{ width: 4, height: 28, background: '#888', borderRadius: 1 }} />
                {plates.map((p, i) => (
                  <div key={i} style={{ width: 8, height: 12 + p * 1.2, background: PLATE_COLORS[p] ?? '#888', borderRadius: 3 }} />
                ))}
                <div style={{ width: 40, height: 6, background: '#555', borderRadius: 2 }} />
                {[...plates].reverse().map((p, i) => (
                  <div key={i} style={{ width: 8, height: 12 + p * 1.2, background: PLATE_COLORS[p] ?? '#888', borderRadius: 3 }} />
                ))}
                <div style={{ width: 4, height: 28, background: '#888', borderRadius: 1 }} />
              </div>
              {/* Plate list */}
              {Object.entries(
                plates.reduce<Record<number, number>>((acc, p) => ({ ...acc, [p]: (acc[p] ?? 0) + 1 }), {})
              ).map(([size, count]) => (
                <div key={size} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{ width: 16, height: 16, borderRadius: 3, background: PLATE_COLORS[Number(size)] ?? '#888' }} />
                  <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 14, color: '#CCC' }}>{size} kg</span>
                  <span style={{ marginLeft: 'auto', fontFamily: 'JetBrains Mono, monospace', fontSize: 14, color: '#C6FF3D' }}>× {count}</span>
                </div>
              ))}
            </div>
          )}
        </div>
        <div style={{ textAlign: 'center', fontSize: 12, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif' }}>
          แกนบาร์ 20 kg + แผ่น {(target - 20).toFixed(1)} kg (ด้านละ {((target - 20) / 2).toFixed(2)} kg)
        </div>
      </div>
    </div>
  )
}

function SetRow({ set, idx, onToggle, onDelete }: { set: WorkoutSet; idx: number; onToggle: () => void; onDelete: () => void }) {
  const [swipe, setSwipe] = useState(false)
  return (
    <div
      style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 4px', borderRadius: 8, background: set.done ? 'rgba(198,255,61,0.04)' : 'transparent', position: 'relative', overflow: 'hidden', transition: 'background 0.2s' }}
      onMouseEnter={() => setSwipe(true)}
      onMouseLeave={() => setSwipe(false)}
    >
      {/* Set # */}
      <div style={{ width: 24, fontFamily: 'JetBrains Mono, monospace', fontSize: 12, color: set.isWarmup ? '#f97316' : '#555', textAlign: 'center', flexShrink: 0 }}>
        {set.isWarmup ? 'W' : idx + 1}
      </div>
      {/* Weight */}
      <div style={{ flex: 1, fontFamily: 'JetBrains Mono, monospace', fontSize: 15, color: set.done ? '#F2F5EF' : '#555', textAlign: 'center' }}>
        {set.weight > 0 ? set.weight : '—'}
      </div>
      <div style={{ width: 20, textAlign: 'center', color: '#333', fontFamily: 'JetBrains Mono, monospace', fontSize: 12 }}>kg</div>
      {/* Reps */}
      <div style={{ flex: 1, fontFamily: 'JetBrains Mono, monospace', fontSize: 15, color: set.done ? '#F2F5EF' : '#555', textAlign: 'center' }}>
        {set.reps > 0 ? set.reps : '—'}
      </div>
      {/* PR badge */}
      {set.isPR && <span title="Personal Record" style={{ fontSize: 14 }}>🏆</span>}
      {/* Checkmark */}
      <button onClick={onToggle} style={{ width: 28, height: 28, borderRadius: 8, background: set.done ? '#C6FF3D' : 'rgba(255,255,255,0.06)', border: set.done ? 'none' : '1px solid rgba(255,255,255,0.1)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, transition: 'all 0.15s' }}>
        {set.done && <span style={{ color: '#0A0C0A', fontSize: 14, fontWeight: 700 }}>✓</span>}
      </button>
      {/* Swipe delete */}
      {swipe && (
        <button onClick={onDelete} style={{ position: 'absolute', right: 0, top: 0, bottom: 0, width: 40, background: 'rgba(239,68,68,0.8)', border: 'none', color: '#fff', fontSize: 14, cursor: 'pointer', borderRadius: '0 8px 8px 0' }}>
          ✕
        </button>
      )}
    </div>
  )
}

export default function Workout({ seconds, onFinish }: Props) {
  const [exercises, setExercises] = useState<WorkoutExercise[]>(INITIAL_WORKOUT)
  const [showCalc, setShowCalc] = useState(false)
  const [sessionName, setSessionName] = useState('Push A')
  const [editingName, setEditingName] = useState(false)

  function toggleSet(exId: string, setId: string) {
    setExercises((prev) =>
      prev.map((ex) =>
        ex.id !== exId ? ex : { ...ex, sets: ex.sets.map((s) => s.id !== setId ? s : { ...s, done: !s.done }) }
      )
    )
  }

  function deleteSet(exId: string, setId: string) {
    setExercises((prev) =>
      prev.map((ex) =>
        ex.id !== exId ? ex : { ...ex, sets: ex.sets.filter((s) => s.id !== setId) }
      )
    )
  }

  const totalDone = exercises.flatMap((ex) => ex.sets).filter((s) => s.done).length
  const totalSets = exercises.flatMap((ex) => ex.sets).length

  return (
    <div style={{ height: '100%', background: '#0A0C0A', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{ padding: '52px 20px 14px', borderBottom: '1px solid rgba(255,255,255,0.06)', background: '#0A0C0A' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
          {editingName ? (
            <input
              autoFocus
              value={sessionName}
              onChange={(e) => setSessionName(e.target.value)}
              onBlur={() => setEditingName(false)}
              onKeyDown={(e) => e.key === 'Enter' && setEditingName(false)}
              style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 26, fontWeight: 800, color: '#F2F5EF', background: 'none', border: 'none', outline: 'none', borderBottom: '1px solid #C6FF3D', padding: '0 0 2px' }}
            />
          ) : (
            <button onClick={() => setEditingName(true)} style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 26, fontWeight: 800, color: '#F2F5EF', background: 'none', border: 'none', padding: 0, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8 }}>
              {sessionName} <span style={{ fontSize: 14, color: '#7C8A7C' }}>✎</span>
            </button>
          )}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 22, fontWeight: 600, color: '#C6FF3D' }}>{formatTime(seconds)}</div>
            <button onClick={onFinish} style={{ padding: '6px 14px', background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, color: '#f87171', fontFamily: 'Sarabun, sans-serif', fontSize: 13, cursor: 'pointer' }}>จบ</button>
          </div>
        </div>
        {/* Progress bar */}
        <div style={{ height: 3, background: 'rgba(255,255,255,0.05)', borderRadius: 2, overflow: 'hidden' }}>
          <div style={{ height: '100%', width: `${(totalDone / totalSets) * 100}%`, background: '#C6FF3D', borderRadius: 2, transition: 'width 0.4s ease' }} />
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
          <span style={{ fontSize: 11, color: '#5A6A5A', fontFamily: 'JetBrains Mono, monospace' }}>{totalDone}/{totalSets} เซ็ต</span>
          <button onClick={() => setShowCalc(true)} style={{ fontSize: 11, color: '#C6FF3D', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'Sarabun, sans-serif' }}>⚖ คำนวณแผ่น</button>
        </div>
      </div>

      {/* Exercise list */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '12px 20px 24px' }}>
        {exercises.map((ex) => (
          <div key={ex.id} style={{ marginBottom: 24 }}>
            {/* Exercise header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
              <div>
                <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 20, fontWeight: 700, color: '#E0E0E0', letterSpacing: '0.02em' }}>{ex.nameTh}</div>
                <div style={{ fontSize: 11, color: '#7C8A7C', fontFamily: 'JetBrains Mono, monospace' }}>{ex.name} · {ex.targetReps} reps</div>
              </div>
              <PlateVisual weight={ex.sets[0]?.weight ?? 0} onClick={() => setShowCalc(true)} />
            </div>

            {/* Table header */}
            <div style={{ display: 'flex', gap: 8, padding: '0 4px 6px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
              <div style={{ width: 24, fontSize: 10, color: '#5A6A5A', fontFamily: 'JetBrains Mono, monospace', textAlign: 'center' }}>#</div>
              <div style={{ flex: 1, fontSize: 10, color: '#5A6A5A', fontFamily: 'JetBrains Mono, monospace', textAlign: 'center' }}>kg</div>
              <div style={{ width: 20 }} />
              <div style={{ flex: 1, fontSize: 10, color: '#5A6A5A', fontFamily: 'JetBrains Mono, monospace', textAlign: 'center' }}>Reps</div>
              <div style={{ width: 14 }} />
              <div style={{ width: 28 }} />
            </div>

            {/* Sets */}
            {ex.sets.map((set, si) => (
              <SetRow key={set.id} set={set} idx={si} onToggle={() => toggleSet(ex.id, set.id)} onDelete={() => deleteSet(ex.id, set.id)} />
            ))}

            {/* Add set */}
            <button
              onClick={() => setExercises((prev) => prev.map((e) => e.id !== ex.id ? e : {
                ...e, sets: [...e.sets, { id: `${e.id}-${Date.now()}`, weight: e.sets[e.sets.length - 1]?.weight ?? 0, reps: 0, done: false, isWarmup: false }]
              }))}
              style={{ width: '100%', marginTop: 8, padding: '8px', background: 'rgba(255,255,255,0.03)', border: '1px dashed rgba(255,255,255,0.08)', borderRadius: 8, color: '#5A6A5A', fontFamily: 'Sarabun, sans-serif', fontSize: 13, cursor: 'pointer' }}
            >
              + เพิ่มเซ็ต
            </button>
          </div>
        ))}

        {/* Add exercise */}
        <button style={{ width: '100%', padding: '14px', background: 'rgba(198,255,61,0.04)', border: '1px dashed rgba(198,255,61,0.2)', borderRadius: 12, color: '#C6FF3D', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 16, fontWeight: 600, cursor: 'pointer', letterSpacing: '0.05em' }}>
          + เพิ่มท่าออกกำลังกาย
        </button>
      </div>

      {showCalc && <PlateCalcModal onClose={() => setShowCalc(false)} />}
    </div>
  )
}
