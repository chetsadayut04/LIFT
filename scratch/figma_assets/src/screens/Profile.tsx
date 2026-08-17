import { useState } from 'react'

interface Props {
  onLogout: () => void
}

export default function Profile({ onLogout }: Props) {
  const [lang, setLang] = useState<'th' | 'en'>('th')
  const [unit, setUnit] = useState<'kg' | 'lbs'>('kg')
  const [feedback, setFeedback] = useState('')
  const [feedbackSent, setFeedbackSent] = useState(false)
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false)

  function sendFeedback() {
    if (!feedback.trim()) return
    setFeedbackSent(true)
    setTimeout(() => { setFeedbackSent(false); setFeedback('') }, 2500)
  }

  return (
    <div style={{ height: '100%', background: '#0A0C0A', display: 'flex', flexDirection: 'column', overflowY: 'auto', paddingBottom: 72 }}>
      {/* Header / Profile */}
      <div style={{ padding: '52px 20px 28px', borderBottom: '1px solid rgba(255,255,255,0.06)', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
        {/* Avatar */}
        <div style={{ width: 80, height: 80, borderRadius: '50%', background: 'linear-gradient(135deg,#C6FF3D,#9ECC2E)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 32, fontWeight: 700, color: '#0A0C0A', fontFamily: 'Barlow Condensed, sans-serif', border: '3px solid rgba(198,255,61,0.3)' }}>
          ส
        </div>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 24, fontWeight: 700, color: '#F2F5EF' }}>สมชาย วีระกุล</div>
          <div style={{ fontSize: 13, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif', marginTop: 2 }}>somchai@email.com</div>
          <div style={{ marginTop: 8, display: 'inline-flex', alignItems: 'center', gap: 6, background: '#1E211F', borderRadius: 20, padding: '4px 12px', border: '1px solid rgba(255,255,255,0.06)' }}>
            <svg width="14" height="14" viewBox="0 0 18 18"><path d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844a4.14 4.14 0 0 1-1.796 2.716v2.259h2.908c1.702-1.567 2.684-3.875 2.684-6.615z" fill="#4285F4"/><path d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z" fill="#34A853"/><path d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z" fill="#FBBC05"/><path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z" fill="#EA4335"/></svg>
            <span style={{ fontSize: 11, color: '#777', fontFamily: 'Sarabun, sans-serif' }}>เชื่อมต่อผ่าน Google</span>
          </div>
        </div>

        {/* Stats row */}
        <div style={{ display: 'flex', gap: 0, width: '100%', marginTop: 8, background: '#1B1F1B', borderRadius: 14, overflow: 'hidden', border: '1px solid rgba(255,255,255,0.06)' }}>
          {[
            { label: 'เซสชัน', value: '87' },
            { label: 'สัปดาห์นี้', value: '4' },
            { label: 'วันต่อเนื่อง', value: '12' },
          ].map((s, i) => (
            <div key={i} style={{ flex: 1, padding: '14px 8px', textAlign: 'center', borderRight: i < 2 ? '1px solid rgba(255,255,255,0.04)' : 'none' }}>
              <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 20, fontWeight: 600, color: '#C6FF3D' }}>{s.value}</div>
              <div style={{ fontSize: 11, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif', marginTop: 2 }}>{s.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Settings */}
      <div style={{ padding: '20px 20px' }}>
        {/* Language */}
        <div style={{ marginBottom: 20 }}>
          <div style={{ fontSize: 11, color: '#5A6A5A', fontFamily: 'Barlow Condensed, sans-serif', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 10 }}>ภาษา</div>
          <div style={{ display: 'flex', background: '#1B1F1B', borderRadius: 12, padding: 4, border: '1px solid rgba(255,255,255,0.06)' }}>
            {([['th', '🇹🇭 ภาษาไทย'], ['en', '🇬🇧 English']] as const).map(([l, label]) => (
              <button key={l} onClick={() => setLang(l)} style={{ flex: 1, padding: '10px 0', borderRadius: 9, background: lang === l ? '#C6FF3D' : 'transparent', color: lang === l ? '#0A0C0A' : '#555', fontFamily: 'Sarabun, sans-serif', fontSize: 14, fontWeight: 600, border: 'none', cursor: 'pointer', transition: 'all 0.2s' }}>
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Weight unit */}
        <div style={{ marginBottom: 20 }}>
          <div style={{ fontSize: 11, color: '#5A6A5A', fontFamily: 'Barlow Condensed, sans-serif', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 10 }}>หน่วยน้ำหนัก</div>
          <div style={{ display: 'flex', background: '#1B1F1B', borderRadius: 12, padding: 4, border: '1px solid rgba(255,255,255,0.06)' }}>
            {([['kg', 'กิโลกรัม (kg)'], ['lbs', 'ปอนด์ (lbs)']] as const).map(([u, label]) => (
              <button key={u} onClick={() => setUnit(u)} style={{ flex: 1, padding: '10px 0', borderRadius: 9, background: unit === u ? '#C6FF3D' : 'transparent', color: unit === u ? '#0A0C0A' : '#555', fontFamily: 'Sarabun, sans-serif', fontSize: 14, fontWeight: 600, border: 'none', cursor: 'pointer', transition: 'all 0.2s' }}>
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Feedback */}
        <div style={{ marginBottom: 20 }}>
          <div style={{ fontSize: 11, color: '#5A6A5A', fontFamily: 'Barlow Condensed, sans-serif', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 10 }}>ส่งความคิดเห็น</div>
          <div style={{ background: '#1B1F1B', borderRadius: 14, padding: '4px', border: '1px solid rgba(255,255,255,0.06)' }}>
            <textarea
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              placeholder="แจ้งปัญหา หรือแนะนำฟีเจอร์ใหม่..."
              rows={4}
              style={{ width: '100%', padding: '12px 14px', background: 'transparent', border: 'none', color: '#E0E0E0', fontFamily: 'Sarabun, sans-serif', fontSize: 14, outline: 'none', resize: 'none', lineHeight: 1.6 }}
            />
            {feedbackSent ? (
              <div style={{ margin: '0 8px 8px', padding: '10px 14px', background: 'rgba(198,255,61,0.1)', border: '1px solid rgba(198,255,61,0.2)', borderRadius: 10, color: '#C6FF3D', fontSize: 13, fontFamily: 'Sarabun, sans-serif', textAlign: 'center' }}>
                ✓ ขอบคุณสำหรับความคิดเห็นครับ!
              </div>
            ) : (
              <button onClick={sendFeedback} style={{ margin: '0 8px 8px', width: 'calc(100% - 16px)', padding: '11px', background: feedback.trim() ? 'rgba(198,255,61,0.12)' : '#1E211F', border: `1px solid ${feedback.trim() ? 'rgba(198,255,61,0.3)' : 'rgba(255,255,255,0.06)'}`, borderRadius: 10, color: feedback.trim() ? '#C6FF3D' : '#444', fontFamily: 'Sarabun, sans-serif', fontSize: 14, cursor: 'pointer', transition: 'all 0.2s' }}>
                ส่งความคิดเห็น
              </button>
            )}
          </div>
        </div>

        {/* App info */}
        <div style={{ background: '#1B1F1B', borderRadius: 14, padding: '14px 16px', marginBottom: 20, border: '1px solid rgba(255,255,255,0.06)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 10 }}>
            <span style={{ fontSize: 13, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif' }}>เวอร์ชัน</span>
            <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 13, color: '#5A6A5A' }}>1.0.0-beta</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ fontSize: 13, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif' }}>สมาชิกตั้งแต่</span>
            <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 13, color: '#5A6A5A' }}>ม.ค. 2025</span>
          </div>
        </div>

        {/* Logout */}
        <button onClick={() => setShowLogoutConfirm(true)} style={{ width: '100%', padding: '15px', background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: 14, color: '#f87171', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 18, fontWeight: 700, cursor: 'pointer', letterSpacing: '0.05em' }}>
          ออกจากระบบ
        </button>
      </div>

      {/* Logout confirm */}
      {showLogoutConfirm && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(5,7,5,0.88)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 28, zIndex: 200 }}>
          <div className="animate-slide-up" style={{ background: '#1B1F1B', borderRadius: 20, padding: 28, width: '100%', border: '1px solid rgba(255,255,255,0.08)', textAlign: 'center' }}>
            <div style={{ fontSize: 40, marginBottom: 16 }}>👋</div>
            <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 22, fontWeight: 700, color: '#F2F5EF', marginBottom: 8 }}>ออกจากระบบ?</div>
            <div style={{ fontSize: 14, color: '#7C8A7C', fontFamily: 'Sarabun, sans-serif', marginBottom: 24 }}>คุณต้องการออกจากระบบใช่หรือไม่</div>
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => setShowLogoutConfirm(false)} style={{ flex: 1, padding: '13px', background: '#1E211F', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 10, color: '#8E9A8E', fontFamily: 'Sarabun, sans-serif', fontSize: 14, cursor: 'pointer' }}>ยกเลิก</button>
              <button onClick={onLogout} style={{ flex: 1, padding: '13px', background: 'rgba(239,68,68,0.15)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 10, color: '#f87171', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 16, fontWeight: 700, cursor: 'pointer' }}>ออกจากระบบ</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
