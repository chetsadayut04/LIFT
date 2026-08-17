import { useState } from 'react'
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import { PR_RECORDS, PROGRESSION_DATA } from '../data'

const PERIODS = ['1M', '3M', '6M', 'ALL'] as const
type Period = (typeof PERIODS)[number]

const EXERCISES = ['Bench Press', 'Back Squat', 'Deadlift', 'Overhead Press']

function CustomTooltip({ active, payload }: { active?: boolean; payload?: Array<{ value: number }> }) {
  if (!active || !payload?.length) return null
  return (
    <div style={{ background: '#1E211F', border: '1px solid rgba(198,255,61,0.3)', borderRadius: 8, padding: '8px 12px' }}>
      <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 14, color: '#C6FF3D', fontWeight: 600 }}>{payload[0].value} kg</div>
    </div>
  )
}

export default function Stats() {
  const [period, setPeriod] = useState<Period>('3M')
  const [selectedEx, setSelectedEx] = useState('Bench Press')

  const sliceData = {
    '1M': PROGRESSION_DATA.slice(-4),
    '3M': PROGRESSION_DATA.slice(-7),
    '6M': PROGRESSION_DATA,
    'ALL': PROGRESSION_DATA,
  }[period]

  return (
    <div style={{ height: '100%', background: '#0A0C0A', display: 'flex', flexDirection: 'column', paddingBottom: 72 }}>
      {/* Header */}
      <div style={{ padding: '52px 20px 16px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
        <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 30, fontWeight: 800, color: '#F2F5EF', letterSpacing: '-0.5px', marginBottom: 14 }}>สถิติ & วิเคราะห์</div>
        {/* Period filter */}
        <div style={{ display: 'flex', gap: 8 }}>
          {PERIODS.map((p) => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              style={{ flex: 1, padding: '8px 0', borderRadius: 8, background: period === p ? '#C6FF3D' : '#1E211F', border: period === p ? 'none' : '1px solid rgba(255,255,255,0.08)', color: period === p ? '#0A0C0A' : '#666', fontFamily: 'JetBrains Mono, monospace', fontSize: 13, fontWeight: 700, cursor: 'pointer', transition: 'all 0.2s' }}
            >
              {p}
            </button>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '20px 20px' }}>
        {/* Exercise selector */}
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 11, color: '#5A6A5A', fontFamily: 'Barlow Condensed, sans-serif', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 10 }}>ท่าออกกำลังกาย</div>
          <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4 }}>
            {EXERCISES.map((ex) => (
              <button
                key={ex}
                onClick={() => setSelectedEx(ex)}
                style={{ flexShrink: 0, padding: '7px 14px', borderRadius: 20, background: selectedEx === ex ? 'rgba(198,255,61,0.12)' : '#1E211F', border: selectedEx === ex ? '1px solid rgba(198,255,61,0.4)' : '1px solid rgba(255,255,255,0.06)', color: selectedEx === ex ? '#C6FF3D' : '#666', fontFamily: 'Sarabun, sans-serif', fontSize: 13, cursor: 'pointer', transition: 'all 0.2s', whiteSpace: 'nowrap' }}
              >
                {ex}
              </button>
            ))}
          </div>
        </div>

        {/* Chart */}
        <div style={{ background: 'rgba(27,31,27,0.65)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderRadius: 16, padding: '20px 8px 12px', marginBottom: 24, border: '1px solid rgba(255,255,255,0.07)' }}>
          <div style={{ padding: '0 12px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 16, fontWeight: 700, color: '#8E9A8E', letterSpacing: '0.05em', textTransform: 'uppercase' }}>PR Trend</div>
              <div style={{ fontSize: 13, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif' }}>{selectedEx}</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 24, fontWeight: 600, color: '#C6FF3D' }}>110</div>
              <div style={{ fontSize: 11, color: '#7C8A7C' }}>สูงสุด (kg)</div>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={160}>
            <LineChart data={sliceData} margin={{ left: -10, right: 8 }}>
              <CartesianGrid stroke="rgba(255,255,255,0.04)" strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="date" tick={{ fill: '#444', fontSize: 10, fontFamily: 'Sarabun, sans-serif' }} axisLine={false} tickLine={false} />
              <YAxis domain={['auto', 'auto']} tick={{ fill: '#444', fontSize: 10, fontFamily: 'JetBrains Mono, monospace' }} axisLine={false} tickLine={false} width={36} />
              <Tooltip content={<CustomTooltip />} />
              <Line type="monotone" dataKey="weight" stroke="#C6FF3D" strokeWidth={2} dot={{ fill: '#C6FF3D', r: 3, strokeWidth: 0 }} activeDot={{ fill: '#C6FF3D', r: 5, strokeWidth: 0 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* PR Table */}
        <div style={{ marginBottom: 12 }}>
          <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 18, fontWeight: 700, color: '#8E9A8E', letterSpacing: '0.05em', textTransform: 'uppercase', marginBottom: 12 }}>สถิติส่วนตัว (PR)</div>
          {PR_RECORDS.map((pr, i) => (
            <div key={pr.exercise} style={{ background: 'rgba(27,31,27,0.6)', backdropFilter: 'blur(16px)', WebkitBackdropFilter: 'blur(16px)', borderRadius: 14, padding: '14px 16px', marginBottom: 10, border: '1px solid rgba(255,255,255,0.07)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2 }}>
                    <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 11, color: '#5A6A5A' }}>#{i + 1}</span>
                    <span style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 18, fontWeight: 700, color: '#E0E0E0' }}>{pr.exerciseTh}</span>
                  </div>
                  <div style={{ fontSize: 11, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif' }}>{pr.totalSets} เซ็ตทั้งหมด</div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 16, fontWeight: 600, color: '#C6FF3D' }}>{pr.bestWeight}<span style={{ fontSize: 11, color: '#7C8A7C' }}> kg</span></div>
                  <div style={{ fontSize: 11, color: '#7C8A7C', fontFamily: 'JetBrains Mono, monospace' }}>× {pr.bestReps} reps</div>
                </div>
              </div>
              {/* Progress bar */}
              <div style={{ height: 4, background: 'rgba(255,255,255,0.05)', borderRadius: 2, overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${pr.pct}%`, background: `linear-gradient(90deg,#9ECC2E,#C6FF3D)`, borderRadius: 2, transition: 'width 0.6s ease' }} />
              </div>
              <div style={{ textAlign: 'right', marginTop: 4, fontSize: 10, color: '#5A6A5A', fontFamily: 'JetBrains Mono, monospace' }}>{pr.pct.toFixed(0)}%</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
