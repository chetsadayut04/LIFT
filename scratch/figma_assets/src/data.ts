import type { Routine, PRRecord, WorkoutExercise } from './types'

export const ROUTINES: Routine[] = [
  {
    id: 'push-a',
    name: 'Push A',
    gradient: 'linear-gradient(135deg,#b91c1c 0%,#7c2d12 100%)',
    exercises: [
      { name: 'Bench Press', nameTh: 'เบนช์เพรส', defaultSets: 4, defaultReps: '5-8', defaultWeight: 100 },
      { name: 'Overhead Press', nameTh: 'โอเวอร์เฮดเพรส', defaultSets: 3, defaultReps: '8-10', defaultWeight: 60 },
      { name: 'Incline DB Press', nameTh: 'อินไคลน์ดัมเบล', defaultSets: 3, defaultReps: '10-12', defaultWeight: 30 },
      { name: 'Tricep Pushdown', nameTh: 'ไตรเซ็ปพุชดาวน์', defaultSets: 3, defaultReps: '12-15', defaultWeight: 35 },
      { name: 'Lateral Raise', nameTh: 'ยกด้านข้าง', defaultSets: 4, defaultReps: '15-20', defaultWeight: 12 },
    ],
  },
  {
    id: 'pull-a',
    name: 'Pull A',
    gradient: 'linear-gradient(135deg,#1d4ed8 0%,#1e1b4b 100%)',
    exercises: [
      { name: 'Deadlift', nameTh: 'เดดลิฟท์', defaultSets: 3, defaultReps: '3-5', defaultWeight: 150 },
      { name: 'Barbell Row', nameTh: 'บาร์เบลโรว์', defaultSets: 4, defaultReps: '6-8', defaultWeight: 90 },
      { name: 'Pull-ups', nameTh: 'พูลอัพ', defaultSets: 3, defaultReps: '6-10', defaultWeight: 0 },
      { name: 'Face Pull', nameTh: 'เฟซพูล', defaultSets: 3, defaultReps: '15-20', defaultWeight: 20 },
      { name: 'Bicep Curl', nameTh: 'ไบเซ็ปเคิร์ล', defaultSets: 3, defaultReps: '10-12', defaultWeight: 15 },
    ],
  },
  {
    id: 'legs-a',
    name: 'Legs A',
    gradient: 'linear-gradient(135deg,#065f46 0%,#134e4a 100%)',
    exercises: [
      { name: 'Back Squat', nameTh: 'สควอท', defaultSets: 4, defaultReps: '4-6', defaultWeight: 120 },
      { name: 'Romanian DL', nameTh: 'โรมาเนียน DL', defaultSets: 3, defaultReps: '8-10', defaultWeight: 100 },
      { name: 'Leg Press', nameTh: 'เลกเพรส', defaultSets: 3, defaultReps: '10-12', defaultWeight: 200 },
      { name: 'Leg Curl', nameTh: 'เลกเคิร์ล', defaultSets: 3, defaultReps: '12-15', defaultWeight: 50 },
      { name: 'Calf Raise', nameTh: 'น่องยกส้นเท้า', defaultSets: 4, defaultReps: '15-20', defaultWeight: 80 },
    ],
  },
  {
    id: 'upper-b',
    name: 'Upper B',
    gradient: 'linear-gradient(135deg,#6d28d9 0%,#831843 100%)',
    exercises: [
      { name: 'DB Shoulder Press', nameTh: 'ดัมเบลช้อลเดอร์เพรส', defaultSets: 4, defaultReps: '8-10', defaultWeight: 28 },
      { name: 'Cable Row', nameTh: 'เคเบิลโรว์', defaultSets: 3, defaultReps: '10-12', defaultWeight: 60 },
      { name: 'Dips', nameTh: 'ดิปส์', defaultSets: 3, defaultReps: '8-12', defaultWeight: 0 },
      { name: 'Hammer Curl', nameTh: 'แฮมเมอร์เคิร์ล', defaultSets: 3, defaultReps: '10-12', defaultWeight: 18 },
    ],
  },
]

export const WEEKLY_DATA = [3200, 0, 8750, 9120, 0, 10200, 0]
export const WEEKLY_DAYS = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา']
export const TRAINED_DAYS = [0, 2, 3, 5] // Mon, Wed, Thu, Sat (indices)

export const PR_RECORDS: PRRecord[] = [
  { exercise: 'Deadlift', exerciseTh: 'เดดลิฟท์', bestWeight: 160, bestReps: 3, totalSets: 124, pct: 100 },
  { exercise: 'Back Squat', exerciseTh: 'สควอท', bestWeight: 140, bestReps: 5, totalSets: 218, pct: 87.5 },
  { exercise: 'Bench Press', exerciseTh: 'เบนช์เพรส', bestWeight: 110, bestReps: 3, totalSets: 302, pct: 68.75 },
  { exercise: 'Barbell Row', exerciseTh: 'บาร์เบลโรว์', bestWeight: 100, bestReps: 5, totalSets: 187, pct: 62.5 },
  { exercise: 'Overhead Press', exerciseTh: 'โอเวอร์เฮดเพรส', bestWeight: 80, bestReps: 5, totalSets: 165, pct: 50 },
  { exercise: 'Leg Press', exerciseTh: 'เลกเพรส', bestWeight: 240, bestReps: 8, totalSets: 143, pct: 78 },
]

export const PROGRESSION_DATA = [
  { date: '9 เม.ย.', weight: 90 },
  { date: '16 เม.ย.', weight: 92.5 },
  { date: '23 เม.ย.', weight: 95 },
  { date: '30 เม.ย.', weight: 97.5 },
  { date: '7 พ.ค.', weight: 100 },
  { date: '14 พ.ค.', weight: 100 },
  { date: '21 พ.ค.', weight: 102.5 },
  { date: '28 พ.ค.', weight: 105 },
  { date: '4 มิ.ย.', weight: 105 },
  { date: '11 มิ.ย.', weight: 107.5 },
  { date: '18 มิ.ย.', weight: 110 },
]

export const INITIAL_WORKOUT: WorkoutExercise[] = [
  {
    id: 'ex1',
    name: 'Bench Press',
    nameTh: 'เบนช์เพรส',
    targetReps: '5-8',
    sets: [
      { id: 's1', weight: 60, reps: 10, done: true, isWarmup: true },
      { id: 's2', weight: 100, reps: 5, done: true, isWarmup: false },
      { id: 's3', weight: 100, reps: 5, done: true, isWarmup: false },
      { id: 's4', weight: 105, reps: 4, done: true, isWarmup: false, isPR: true },
      { id: 's5', weight: 100, reps: 0, done: false, isWarmup: false },
    ],
  },
  {
    id: 'ex2',
    name: 'Overhead Press',
    nameTh: 'โอเวอร์เฮดเพรส',
    targetReps: '8-10',
    sets: [
      { id: 's6', weight: 60, reps: 8, done: true, isWarmup: false },
      { id: 's7', weight: 60, reps: 7, done: true, isWarmup: false },
      { id: 's8', weight: 62.5, reps: 0, done: false, isWarmup: false },
    ],
  },
  {
    id: 'ex3',
    name: 'Incline DB Press',
    nameTh: 'อินไคลน์ดัมเบล',
    targetReps: '10-12',
    sets: [
      { id: 's9', weight: 30, reps: 0, done: false, isWarmup: false },
      { id: 's10', weight: 30, reps: 0, done: false, isWarmup: false },
      { id: 's11', weight: 30, reps: 0, done: false, isWarmup: false },
    ],
  },
]

export const PLATE_COLORS: Record<number, string> = {
  25: '#ef4444',
  20: '#3b82f6',
  15: '#eab308',
  10: '#22c55e',
  5: '#9ca3af',
  2.5: '#f97316',
  1.25: '#e5e7eb',
}
