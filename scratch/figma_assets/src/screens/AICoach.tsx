import { useState, useRef, useEffect } from 'react'
import type { ChatMessage } from '../types'

const MOCK_RESPONSES: Record<string, string> = {
  default: 'ขอบคุณสำหรับคำถามครับ! เพื่อให้คำแนะนำที่ดีที่สุด กรุณาบอกรายละเอียดเพิ่มเติมได้เลยครับ เช่น ระดับประสบการณ์ เป้าหมาย และตารางการฝึกในปัจจุบัน',
  bench: 'สำหรับ Bench Press ที่ดีขึ้น ผมแนะนำ:\n\n1. **Linear Progression** — เพิ่ม 2.5kg ทุกครั้งที่ทำ 5×5 ได้\n2. **Arch & Leg Drive** — ฝึกการวางขาให้มั่นคง\n3. **Pause Rep** — หยุด 1-2 วินาทีที่หน้าอก ช่วยสร้าง Strength จุดอ่อน\n\nปัจจุบันยกได้เท่าไหร่ครับ?',
  squat: 'Squat เป็นท่าที่ต้องใช้ทั้งความแข็งแรงและเทคนิคครับ:\n\n• **Depth** — ต้นขาขนานกับพื้นหรือต่ำกว่า\n• **Knees out** — เข่าต้องออกทิศเดียวกับนิ้วเท้า\n• **Brace** — หายใจลึกแล้วล็อก core ก่อนลง\n\nถ้ามีปัญหาด้านใดเป็นพิเศษ บอกมาได้เลยครับ!',
  program: 'ผมแนะนำโปรแกรม **LIFT 4-Day Split** สำหรับระดับกลาง:\n\n📅 จันทร์ → Push A\n📅 อังคาร → Pull A\n📅 พฤหัส → Legs A\n📅 ศุกร์ → Upper B\n\nพักวันศุกร์ตาม และเน้น Progressive Overload ทุก Session ครับ!',
  diet: 'โภชนาการสำหรับการสร้างกล้ามเนื้อ:\n\n• **Protein**: 1.6-2.2g ต่อ kg น้ำหนักตัว\n• **Calories**: Surplus เล็กน้อย +200-300 kcal\n• **Timing**: กินโปรตีนภายใน 2 ชั่วโมงหลังฝึก\n\nทานอาหารอะไรเป็นหลักอยู่ครับ?',
}

function getResponse(input: string): string {
  const lower = input.toLowerCase()
  if (lower.includes('bench') || lower.includes('เบนช์')) return MOCK_RESPONSES.bench
  if (lower.includes('squat') || lower.includes('สควอท')) return MOCK_RESPONSES.squat
  if (lower.includes('โปรแกรม') || lower.includes('ตาราง') || lower.includes('program')) return MOCK_RESPONSES.program
  if (lower.includes('อาหาร') || lower.includes('โภชนาการ') || lower.includes('protein') || lower.includes('diet')) return MOCK_RESPONSES.diet
  return MOCK_RESPONSES.default
}

function formatMsg(text: string) {
  return text.split('\n').map((line, i) => {
    const parts = line.split(/\*\*(.*?)\*\*/g)
    return (
      <span key={i}>
        {parts.map((part, j) => j % 2 === 1 ? <strong key={j} style={{ color: '#C6FF3D', fontWeight: 700 }}>{part}</strong> : part)}
        {i < text.split('\n').length - 1 && <br />}
      </span>
    )
  })
}

const INITIAL_MESSAGES: ChatMessage[] = [
  {
    id: '0',
    role: 'ai',
    content: 'สวัสดีครับ! ผม LIFT AI Coach พร้อมช่วยคุณเรื่องการฝึกซ้อม 💪\n\nถามได้เลยครับ ไม่ว่าจะเป็นเรื่องโปรแกรม เทคนิคท่าฝึก หรือโภชนาการ',
  },
]

export default function AICoach() {
  const [messages, setMessages] = useState<ChatMessage[]>(INITIAL_MESSAGES)
  const [input, setInput] = useState('')
  const [isTyping, setIsTyping] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isTyping])

  function send() {
    const text = input.trim()
    if (!text) return
    setInput('')
    const userMsg: ChatMessage = { id: Date.now().toString(), role: 'user', content: text }
    setMessages((prev) => [...prev, userMsg])
    setIsTyping(true)
    setTimeout(() => {
      const aiMsg: ChatMessage = { id: (Date.now() + 1).toString(), role: 'ai', content: getResponse(text) }
      setMessages((prev) => [...prev, aiMsg])
      setIsTyping(false)
    }, 1200 + Math.random() * 800)
  }

  const suggestions = ['แนะนำโปรแกรม 4 วัน', 'เทคนิค Bench Press', 'อาหารสร้างกล้าม']

  return (
    <div style={{ height: '100%', background: '#0A0C0A', display: 'flex', flexDirection: 'column', paddingBottom: 72 }}>
      {/* Header */}
      <div style={{ padding: '52px 20px 16px', borderBottom: '1px solid rgba(255,255,255,0.06)', display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{ width: 44, height: 44, borderRadius: 14, background: 'linear-gradient(135deg,rgba(198,255,61,0.15),rgba(198,255,61,0.05))', border: '1px solid rgba(198,255,61,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22 }}>🤖</div>
        <div>
          <div style={{ fontFamily: 'Barlow Condensed, sans-serif', fontSize: 22, fontWeight: 800, color: '#F2F5EF' }}>LIFT AI Coach</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#C6FF3D', animation: 'pulse-ring 2s ease-in-out infinite' }} />
            <span style={{ fontSize: 12, color: '#C6FF3D', fontFamily: 'Sarabun, sans-serif' }}>ออนไลน์</span>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {messages.map((msg) => (
          <div key={msg.id} className="animate-fade-in" style={{ display: 'flex', justifyContent: msg.role === 'user' ? 'flex-end' : 'flex-start' }}>
            {msg.role === 'ai' && (
              <div style={{ width: 28, height: 28, borderRadius: 8, background: 'rgba(198,255,61,0.1)', border: '1px solid rgba(198,255,61,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, marginRight: 8, flexShrink: 0, marginTop: 4 }}>🤖</div>
            )}
            <div
              style={{
                maxWidth: '78%', padding: '12px 16px', borderRadius: msg.role === 'user' ? '18px 18px 4px 18px' : '18px 18px 18px 4px',
                background: msg.role === 'user' ? '#C6FF3D' : '#1E211F',
                color: msg.role === 'user' ? '#0A0C0A' : '#E0E0E0',
                fontFamily: 'Sarabun, sans-serif', fontSize: 14, lineHeight: 1.6,
                border: msg.role === 'ai' ? '1px solid rgba(255,255,255,0.06)' : 'none',
              }}
            >
              {msg.role === 'user' ? msg.content : formatMsg(msg.content)}
            </div>
          </div>
        ))}

        {/* Typing indicator */}
        {isTyping && (
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
            <div style={{ width: 28, height: 28, borderRadius: 8, background: 'rgba(198,255,61,0.1)', border: '1px solid rgba(198,255,61,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, flexShrink: 0 }}>🤖</div>
            <div style={{ padding: '12px 16px', background: '#1E211F', borderRadius: '18px 18px 18px 4px', border: '1px solid rgba(255,255,255,0.06)', display: 'flex', gap: 5, alignItems: 'center' }}>
              {[0, 1, 2].map((i) => (
                <div key={i} className="typing-dot" style={{ width: 7, height: 7, borderRadius: '50%', background: '#C6FF3D' }} />
              ))}
            </div>
          </div>
        )}

        {/* Suggestions */}
        {messages.length === 1 && !isTyping && (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 4 }}>
            {suggestions.map((s) => (
              <button key={s} onClick={() => { setInput(s); setTimeout(() => send(), 50) }} style={{ padding: '8px 14px', background: 'rgba(198,255,61,0.06)', border: '1px solid rgba(198,255,61,0.2)', borderRadius: 20, color: '#C6FF3D', fontFamily: 'Sarabun, sans-serif', fontSize: 13, cursor: 'pointer' }}>
                {s}
              </button>
            ))}
          </div>
        )}

        <div ref={bottomRef} />
      </div>

      {/* Input */}
      <div style={{ padding: '12px 20px', borderTop: '1px solid rgba(255,255,255,0.06)', display: 'flex', gap: 10, background: 'rgba(8,8,8,0.98)' }}>
        <input
          ref={inputRef}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && send()}
          placeholder="ถามเรื่องการฝึกซ้อม..."
          style={{ flex: 1, padding: '12px 16px', background: '#1E211F', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 14, color: '#F2F5EF', fontFamily: 'Sarabun, sans-serif', fontSize: 14, outline: 'none' }}
        />
        <button
          onClick={send}
          disabled={!input.trim() || isTyping}
          style={{ width: 46, height: 46, borderRadius: 14, background: input.trim() ? '#C6FF3D' : '#1E211F', border: 'none', cursor: input.trim() ? 'pointer' : 'default', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, flexShrink: 0, transition: 'background 0.2s' }}
        >
          {isTyping ? '⏳' : '↑'}
        </button>
      </div>
    </div>
  )
}
