import { useState } from 'react'

interface Props {
  onAuth: () => void
}

export default function Auth({ onAuth }: Props) {
  const [tab, setTab] = useState<'login' | 'signup'>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [error, setError] = useState('')
  const [showForgot, setShowForgot] = useState(false)
  const [forgotEmail, setForgotEmail] = useState('')
  const [forgotSent, setForgotSent] = useState(false)

  function handleSubmit() {
    setError('')
    if (!email.includes('@')) {
      setError('รูปแบบอีเมลไม่ถูกต้อง กรุณาตรวจสอบอีเมลอีกครั้ง')
      return
    }
    if (password.length < 6) {
      setError('รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร')
      return
    }
    if (tab === 'login' && password !== 'lift123') {
      setError('อีเมลหรือรหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง')
      return
    }
    onAuth()
  }

  function handleForgot() {
    if (!forgotEmail.includes('@')) return
    setForgotSent(true)
    setTimeout(() => {
      setShowForgot(false)
      setForgotSent(false)
      setForgotEmail('')
    }, 2500)
  }

  return (
    <div style={{ height: '100%', background: 'radial-gradient(ellipse 120% 60% at -10% 110%,rgba(198,255,61,0.07) 0%,transparent 60%), radial-gradient(ellipse 80% 40% at 110% -10%,rgba(198,255,61,0.04) 0%,transparent 60%), #0A0C0A', display: 'flex', flexDirection: 'column', padding: '0 28px', paddingTop: 64, position: 'relative', overflow: 'hidden' }}>

      {/* Logo */}
      <div style={{ marginBottom: 48 }}>
        <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 52, fontWeight: 800, color: '#C6FF3D', letterSpacing: '-1px', lineHeight: 1 }}>LIFT</div>
        <div style={{ fontSize: 14, color: '#7C8A7C', marginTop: 4 }}>ติดตามการฝึกซ้อม · วิเคราะห์สถิติ · เติบโตขึ้น</div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', background: 'rgba(27,31,27,0.55)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', borderRadius: 12, padding: 4, marginBottom: 32, border: '1px solid rgba(255,255,255,0.08)' }}>
        {(['login', 'signup'] as const).map((t) => (
          <button
            key={t}
            onClick={() => { setTab(t); setError('') }}
            style={{
              flex: 1, padding: '10px 0', borderRadius: 9, fontFamily: 'Sarabun, sans-serif', fontSize: 15, fontWeight: 600, border: 'none', cursor: 'pointer', transition: 'all 0.2s',
              background: tab === t ? '#C6FF3D' : 'transparent',
              color: tab === t ? '#0A0C0A' : '#555',
            }}
          >
            {t === 'login' ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก'}
          </button>
        ))}
      </div>

      {/* Fields */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* Email */}
        <div style={{ position: 'relative' }}>
          <span style={{ position: 'absolute', left: 16, top: '50%', transform: 'translateY(-50%)', fontSize: 16, color: '#5A6A5A' }}>✉</span>
          <input
            type="email"
            placeholder="อีเมล"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            style={{ width: '100%', padding: '15px 16px 15px 44px', background: 'rgba(27,31,27,0.6)', backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)', border: '1px solid rgba(255,255,255,0.09)', borderRadius: 12, color: '#F2F5EF', fontSize: 15, fontFamily: 'Sarabun, sans-serif', outline: 'none' }}
          />
        </div>
        {/* Password */}
        <div style={{ position: 'relative' }}>
          <span style={{ position: 'absolute', left: 16, top: '50%', transform: 'translateY(-50%)', fontSize: 16, color: '#5A6A5A' }}>🔒</span>
          <input
            type={showPass ? 'text' : 'password'}
            placeholder="รหัสผ่าน"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSubmit()}
            style={{ width: '100%', padding: '15px 48px 15px 44px', background: 'rgba(27,31,27,0.6)', backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)', border: '1px solid rgba(255,255,255,0.09)', borderRadius: 12, color: '#F2F5EF', fontSize: 15, fontFamily: 'Sarabun, sans-serif', outline: 'none' }}
          />
          <button onClick={() => setShowPass(!showPass)} style={{ position: 'absolute', right: 16, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: '#7C8A7C', cursor: 'pointer', fontSize: 16 }}>
            {showPass ? '🙈' : '👁'}
          </button>
        </div>

        {/* Forgot password */}
        {tab === 'login' && (
          <button onClick={() => setShowForgot(true)} style={{ alignSelf: 'flex-end', background: 'none', border: 'none', color: '#C6FF3D', fontSize: 13, fontFamily: 'Sarabun, sans-serif', cursor: 'pointer', padding: 0 }}>
            ลืมรหัสผ่าน?
          </button>
        )}

        {/* Error */}
        {error && (
          <div style={{ background: 'rgba(239,68,68,0.12)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 10, padding: '12px 14px', color: '#f87171', fontSize: 13, fontFamily: 'Sarabun, sans-serif' }}>
            {error}
          </div>
        )}

        {/* Submit */}
        <button
          onClick={handleSubmit}
          style={{ width: '100%', padding: '16px', background: '#C6FF3D', borderRadius: 14, border: 'none', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 20, fontWeight: 700, color: '#0A0C0A', cursor: 'pointer', letterSpacing: '0.05em', marginTop: 6 }}
        >
          {tab === 'login' ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก'}
        </button>

        {/* Divider */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '4px 0' }}>
          <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.07)' }} />
          <span style={{ color: '#5A6A5A', fontSize: 12, fontFamily: 'Sarabun, sans-serif' }}>หรือ</span>
          <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.07)' }} />
        </div>

        {/* Google */}
        <button
          onClick={onAuth}
          style={{ width: '100%', padding: '14px', background: '#1E211F', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 14, fontFamily: 'Sarabun, sans-serif', fontSize: 15, color: '#CCC', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}
        >
          <svg width="18" height="18" viewBox="0 0 18 18"><path d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844a4.14 4.14 0 0 1-1.796 2.716v2.259h2.908c1.702-1.567 2.684-3.875 2.684-6.615z" fill="#4285F4"/><path d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z" fill="#34A853"/><path d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z" fill="#FBBC05"/><path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z" fill="#EA4335"/></svg>
          เข้าสู่ระบบด้วย Google
        </button>

        {/* Demo hint */}
        <p style={{ textAlign: 'center', color: '#333', fontSize: 12, fontFamily: 'Sarabun, sans-serif', marginTop: 8 }}>
          Demo: อีเมลใดก็ได้ + รหัสผ่าน lift123
        </p>
      </div>

      {/* Forgot password dialog */}
      {showForgot && (
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(5,7,5,0.88)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 28, zIndex: 100 }}>
          <div className="animate-slide-up" style={{ background: 'rgba(23,27,23,0.92)', backdropFilter: 'blur(40px)', WebkitBackdropFilter: 'blur(40px)', borderRadius: 20, padding: 28, width: '100%', border: '1px solid rgba(198,255,61,0.1)' }}>
            <h3 style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 24, fontWeight: 700, color: '#F2F5EF', marginBottom: 8 }}>รีเซ็ตรหัสผ่าน</h3>
            <p style={{ color: '#7C8A7C', fontSize: 13, marginBottom: 20, fontFamily: 'Sarabun, sans-serif' }}>กรอกอีเมลของคุณเพื่อรับลิงก์รีเซ็ตรหัสผ่าน</p>
            {forgotSent ? (
              <div style={{ background: 'rgba(198,255,61,0.1)', border: '1px solid rgba(198,255,61,0.3)', borderRadius: 10, padding: '14px', color: '#C6FF3D', fontSize: 14, textAlign: 'center', fontFamily: 'Sarabun, sans-serif' }}>
                ✓ ส่งลิงก์ไปยัง {forgotEmail} แล้ว
              </div>
            ) : (
              <>
                <input
                  type="email"
                  placeholder="อีเมลของคุณ"
                  value={forgotEmail}
                  onChange={(e) => setForgotEmail(e.target.value)}
                  style={{ width: '100%', padding: '14px 16px', background: '#1E211F', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 10, color: '#F2F5EF', fontSize: 15, fontFamily: 'Sarabun, sans-serif', outline: 'none', marginBottom: 12 }}
                />
                <div style={{ display: 'flex', gap: 10 }}>
                  <button onClick={() => setShowForgot(false)} style={{ flex: 1, padding: '13px', background: '#1E211F', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 10, color: '#8E9A8E', fontFamily: 'Sarabun, sans-serif', fontSize: 14, cursor: 'pointer' }}>ยกเลิก</button>
                  <button onClick={handleForgot} style={{ flex: 1, padding: '13px', background: '#C6FF3D', border: 'none', borderRadius: 10, color: '#0A0C0A', fontFamily: 'Barlow Condensed, sans-serif', fontSize: 16, fontWeight: 700, cursor: 'pointer' }}>ส่ง</button>
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
