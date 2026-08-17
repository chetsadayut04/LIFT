export interface WorkoutSet {
  id: string
  weight: number
  reps: number
  done: boolean
  isWarmup: boolean
  isPR?: boolean
}

export interface WorkoutExercise {
  id: string
  name: string
  nameTh: string
  targetReps: string
  sets: WorkoutSet[]
}

export interface RoutineExercise {
  name: string
  nameTh: string
  defaultSets: number
  defaultReps: string
  defaultWeight: number
}

export interface Routine {
  id: string
  name: string
  gradient: string
  exercises: RoutineExercise[]
}

export interface PRRecord {
  exercise: string
  exerciseTh: string
  bestWeight: number
  bestReps: number
  totalSets: number
  pct: number
}

export interface ChatMessage {
  id: string
  role: 'user' | 'ai'
  content: string
}

export type Screen = 'auth' | 'home' | 'workout' | 'routines' | 'stats' | 'ai' | 'profile'
export type NavTab = 'home' | 'routines' | 'stats' | 'ai' | 'profile'
