import { ROUTINES, WEEKLY_DATA, WEEKLY_DAYS, TRAINED_DAYS } from '../data'

interface Props {
  isWorkoutActive: boolean
  workoutSeconds: number
  onStartWorkout: (routineId?: string) => void
  onContinueWorkout: () => void
  onFinishWorkout: () => void
}

function ProgressRing({ value, max, size = 72 }: { value: number; max: number; size?: number }) {
  const r = (size - 8) / 2
  const circumference = 2 * Math.PI * r
  const filled = (value / max) * circumference
  return (
    <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(255,255,255,0.07)" strokeWidth={4} />
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#C6FF3D" strokeWidth={4} strokeLinecap="round" strokeDasharray={`${filled} ${circumference}`} />
    </svg>
  )
}

function MiniBarChart({ data }: { data: number[] }) {
  const max = Math.max(...data, 1)
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 3, height: 32 }}>
      {data.map((v, i) => (
        <div key={i} style={{ flex: 1, background: v > 0 ? '#C6FF3D' : 'rgba(255,255,255,0.08)', borderRadius: 2, height: `${Math.max((v / max) * 100, v > 0 ? 20 : 8)}%`, opacity: v > 0 ? 1 : 0.5 }} />
      ))}
    </div>
  )
}

function formatTime(s: number) {
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = s % 60
  if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`
  return `${m.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`
}

const today = new Date()
const todayName = today.toLocaleDateString('th-TH', { weekday: 'long', day: 'numeric', month: 'long' })
const todayIdx = (today.getDay() + 6) % 7 // Mon=0

export default function Home({ isWorkoutActive, workoutSeconds, onStartWorkout, onContinueWorkout, onFinishWorkout }: Props) {
  const weeklyTotal = WEEKLY_DATA.reduce((a, b) => a + b, 0)
  const prevTotal = 28400
  const pctChange = Math.round(((weeklyTotal - prevTotal) / prevTotal) * 100)

  if (isWorkoutActive) {
    return (
      <div style={{ height: '100%', background: 'radial-gradient(ellipse 80% 40% at 50% 0%,rgba(198,255,61,0.05) 0%,transparent 60%), #0A0C0A', display: 'flex', flexDirection: 'column', padding: '0 0 72px' }}>
        {/* Header */}
        <div style={{ padding: '56px 24px 20px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ color: '#7C8A7C', fontSize: 12, fontFamily: 'Sarabun, sans-serif', marginBottom: 4 }}>กำลังฝึกซ้อม</div>
              <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 28, fontWeight: 800, color: '#F2F5EF', letterSpacing: '-0.5px' }}>Push A</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ color: '#7C8A7C', fontSize: 11, marginBottom: 3, fontFamily: 'Sarabun, sans-serif' }}>เวลาที่ใช้</div>
              <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 28, fontWeight: 600, color: '#C6FF3D' }}>{formatTime(workoutSeconds)}</div>
            </div>
          </div>
          {/* Pulsing active bar */}
          <div style={{ marginTop: 16, height: 3, background: 'rgba(198,255,61,0.15)', borderRadius: 2, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: '60%', background: '#C6FF3D', borderRadius: 2, animation: 'pulse-ring 1.5s ease-in-out infinite' }} />
          </div>
        </div>

        {/* Exercise summary */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '20px 20px 0' }}>
          <div style={{ marginBottom: 12, color: '#5A6A5A', fontSize: 12, fontFamily: 'Barlow Condensed, sans-serif', letterSpacing: '0.1em', textTransform: 'uppercase' }}>ท่าที่บันทึกไว้</div>
          {[
            { name: 'เบนช์เพรส', sets: 4, done: 3, best: '105 kg × 4 🏆' },
            { name: 'โอเวอร์เฮดเพรส', sets: 3, done: 2, best: '60 kg × 8' },
            { name: 'อินไคลน์ดัมเบล', sets: 3, done: 0, best: '—' },
          ].map((ex) => (
            <div key={ex.name} style={{ background: 'rgba(27,31,27,0.65)', backdropFilter: 'blur(16px)', WebkitBackdropFilter: 'blur(16px)', borderRadius: 12, padding: '14px 16px', marginBottom: 10, border: '1px solid rgba(255,255,255,0.07)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: 15, fontWeight: 600, color: '#E0E0E0', fontFamily: 'Sarabun, sans-serif' }}>{ex.name}</div>
                <div style={{ fontSize: 12, color: '#7C8A7C', marginTop: 2, fontFamily: 'JetBrains Mono, monospace' }}>{ex.best}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 13, color: ex.done > 0 ? '#C6FF3D' : '#444' }}>{ex.done}/{ex.sets}</div>
                <div style={{ fontSize: 11, color: '#5A6A5A', marginTop: 2 }}>เซ็ต</div>
              </div>
            </div>
          ))}
        </div>

        {/* Actions */}
        <div style={{ padding: '16px 20px 0', display: 'flex', gap: 12 }}>
          <button onClick={onFinishWorkout} style={{ flex: 1, padding: '15px', background: 'rgba(198,255,61,0.08)', border: '1px solid rgba(198,255,61,0.3)', borderRadius: 14, color: '#C6FF3D', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 17, fontWeight: 700, cursor: 'pointer', letterSpacing: '0.05em' }}>
            เสร็จสิ้นการฝึก
          </button>
          <button onClick={onContinueWorkout} style={{ flex: 2, padding: '15px', background: '#C6FF3D', border: 'none', borderRadius: 14, color: '#0A0C0A', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 17, fontWeight: 700, cursor: 'pointer', letterSpacing: '0.05em' }}>
            บันทึกต่อ →
          </button>
        </div>
      </div>
    )
  }

  return (
    <div style={{ height: '100%', background: 'radial-gradient(ellipse 70% 35% at 50% -5%,rgba(198,255,61,0.06) 0%,transparent 65%), #0A0C0A', display: 'flex', flexDirection: 'column', overflowY: 'auto', paddingBottom: 72 }}>
      {/* Top bar */}
      <div style={{ padding: '52px 24px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 36, fontWeight: 800, color: '#C6FF3D', letterSpacing: '-1px' }}>LIFT</div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontSize: 12, color: '#5A6A5A', fontFamily: 'Sarabun, sans-serif' }}>{todayName}</div>
        </div>
      </div>

      {/* Weekly calendar */}
      <div style={{ padding: '0 20px 24px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          {WEEKLY_DAYS.map((day, i) => {
            const isTrained = TRAINED_DAYS.includes(i)
            const isToday = i === todayIdx
            return (
              <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                <div style={{ fontSize: 11, color: isToday ? '#C6FF3D' : '#444', fontFamily: 'Sarabun, sans-serif', fontWeight: isToday ? 700 : 400 }}>{day}</div>
                <div
                  style={{
                    width: 34, height: 34, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    background: isTrained ? '#C6FF3D' : isToday ? 'transparent' : 'rgba(255,255,255,0.04)',
                    border: isToday ? '2px solid #C6FF3D' : '2px solid transparent',
                    animation: isToday ? 'pulse-ring 2s ease-in-out infinite' : 'none',
                    fontSize: 14,
                  }}
                >
                  {isTrained ? <span style={{ color: '#0A0C0A', fontSize: 14 }}>✓</span> : <span style={{ color: '#333', fontSize: 11, fontFamily: 'JetBrains Mono, monospace' }}>{i + 1}</span>}
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Stat cards */}
      <div style={{ padding: '0 20px 24px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        {/* Weekly volume */}
        <div style={{ background: 'rgba(27,31,27,0.7)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderRadius: 16, padding: '16px 16px 14px', border: '1px solid rgba(255,255,255,0.07)' }}>
          <div style={{ fontSize: 10, color: '#7C8A7C', fontFamily: 'Barlow Condensed, sans-serif', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 8 }}>ปริมาณรายสัปดาห์</div>
          <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 22, fontWeight: 600, color: '#F2F5EF', lineHeight: 1.1 }}>
            {(weeklyTotal / 1000).toFixed(1)}<span style={{ fontSize: 12, color: '#7C8A7C', marginLeft: 2 }}>t</span>
          </div>
          <div style={{ fontSize: 11, color: pctChange >= 0 ? '#C6FF3D' : '#f87171', fontFamily: 'JetBrains Mono, monospace', marginTop: 4, marginBottom: 10 }}>
            {pctChange >= 0 ? '↑' : '↓'} {Math.abs(pctChange)}%
          </div>
          <MiniBarChart data={WEEKLY_DATA} />
        </div>

        {/* Monthly goal */}
        <div style={{ background: 'rgba(27,31,27,0.7)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderRadius: 16, padding: '16px', border: '1px solid rgba(255,255,255,0.07)', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ fontSize: 10, color: '#7C8A7C', fontFamily: 'Barlow Condensed, sans-serif', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 12 }}>เป้าหมายเดือนนี้</div>
          <div style={{ position: 'relative', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
            <ProgressRing value={12} max={20} size={76} />
            <div style={{ position: 'absolute', textAlign: 'center' }}>
              <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 16, fontWeight: 600, color: '#C6FF3D' }}>12</div>
              <div style={{ fontSize: 9, color: '#5A6A5A' }}>/ 20</div>
            </div>
          </div>
          <div style={{ fontSize: 11, color: '#7C8A7C', marginTop: 10, fontFamily: 'Sarabun, sans-serif' }}>วันที่ฝึกซ้อม</div>
        </div>
      </div>

      {/* My Routines */}
      <div style={{ paddingBottom: 24 }}>
        <div style={{ padding: '0 20px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 18, fontWeight: 700, color: '#8E9A8E', letterSpacing: '0.05em', textTransform: 'uppercase' }}>ตารางของฉัน</div>
        </div>
        <div style={{ display: 'flex', gap: 12, paddingLeft: 20, overflowX: 'auto', paddingRight: 20 }}>
          {ROUTINES.slice(0, 3).map((r) => (
            <div key={r.id} style={{ minWidth: 160, background: r.gradient, borderRadius: 16, padding: '18px 16px', position: 'relative', overflow: 'hidden', flexShrink: 0 }}>
              <div style={{ position: 'absolute', top: -20, right: -20, width: 80, height: 80, background: 'rgba(255,255,255,0.06)', borderRadius: '50%' }} />
              <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 22, fontWeight: 800, color: '#fff', letterSpacing: '-0.5px', marginBottom: 4 }}>{r.name}</div>
              <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.6)', fontFamily: 'Sarabun, sans-serif', marginBottom: 18 }}>{r.exercises.length} ท่า</div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 3, marginBottom: 16 }}>
                {r.exercises.slice(0, 2).map((ex) => (
                  <div key={ex.name} style={{ fontSize: 10, color: 'rgba(255,255,255,0.5)', fontFamily: 'Sarabun, sans-serif' }}>{ex.nameTh}</div>
                ))}
              </div>
              <button
                onClick={() => onStartWorkout(r.id)}
                style={{ width: 36, height: 36, borderRadius: '50%', background: 'rgba(255,255,255,0.9)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14 }}
              >
                ▶
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* AI Banner */}
      <div style={{ margin: '0 20px 24px', background: 'linear-gradient(135deg,rgba(198,255,61,0.08) 0%,rgba(198,255,61,0.02) 100%)', border: '1px solid rgba(198,255,61,0.15)', borderRadius: 14, padding: '14px 18px', display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer' }}>
        <div style={{ fontSize: 28 }}>🤖</div>
        <div>
          <div style={{ fontSize: 14, fontWeight: 600, color: '#C6FF3D', fontFamily: 'Sarabun, sans-serif' }}>AI Coach</div>
          <div style={{ fontSize: 12, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif' }}>ถามคำถามเรื่องการฝึกซ้อม</div>
        </div>
        <div style={{ marginLeft: 'auto', color: '#C6FF3D', fontSize: 18 }}>›</div>
      </div>

      {/* Bottom actions */}
      <div style={{ padding: '0 20px', display: 'flex', gap: 12 }}>
        <button onClick={() => onStartWorkout()} style={{ flex: 2, padding: '16px', background: '#C6FF3D', border: 'none', borderRadius: 14, color: '#0A0C0A', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 18, fontWeight: 700, cursor: 'pointer', letterSpacing: '0.05em' }}>
          ▶ เริ่มการฝึก
        </button>
        <button style={{ flex: 1, padding: '16px', background: 'transparent', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 14, color: '#8E9A8E', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 16, fontWeight: 600, cursor: 'pointer' }}>
          เลือกตาราง
        </button>
      </div>
    </div>
  )
}
