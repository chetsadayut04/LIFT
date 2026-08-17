import type { NavTab } from '../types'

interface Props {
  active: NavTab
  onChange: (tab: NavTab) => void
}

const tabs: { id: NavTab; label: string; icon: string }[] = [
  { id: 'home', label: 'หน้าหลัก', icon: '⊞' },
  { id: 'routines', label: 'ตาราง', icon: '≡' },
  { id: 'stats', label: 'สถิติ', icon: '↗' },
  { id: 'ai', label: 'AI Coach', icon: '◈' },
  { id: 'profile', label: 'ฉัน', icon: '○' },
]

export default function BottomNav({ active, onChange }: Props) {
  return (
    <nav
      style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        height: 72,
        background: 'rgba(10,12,10,0.78)',
        borderTop: '1px solid rgba(198,255,61,0.08)',
        backdropFilter: 'blur(32px)',
        WebkitBackdropFilter: 'blur(32px)',
        display: 'flex',
        alignItems: 'center',
        zIndex: 50,
      }}
    >
      {tabs.map((tab) => {
        const isActive = tab.id === active
        return (
          <button
            key={tab.id}
            onClick={() => onChange(tab.id)}
            style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, padding: '8px 0', background: 'none', border: 'none', cursor: 'pointer' }}
          >
            <span
              style={{
                fontFamily: 'Barlow Condensed, sans-serif',
                fontSize: 22,
                lineHeight: 1,
                color: isActive ? '#C6FF3D' : '#555',
                transition: 'color 0.2s',
              }}
            >
              {tab.icon}
            </span>
            <span
              style={{
                fontFamily: 'Sarabun, sans-serif',
                fontSize: 10,
                color: isActive ? '#C6FF3D' : '#444',
                transition: 'color 0.2s',
                letterSpacing: '0.02em',
              }}
            >
              {tab.label}
            </span>
            {isActive && (
              <span
                style={{
                  position: 'absolute',
                  bottom: 0,
                  width: 24,
                  height: 2,
                  background: '#C6FF3D',
                  borderRadius: 1,
                }}
              />
            )}
          </button>
        )
      })}
    </nav>
  )
}
