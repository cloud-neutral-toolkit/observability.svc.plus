import { createOpenObserveClient } from './openobserve'

export interface TraceSpan {
  id: string
  parentId?: string
  name: string
  service: string
  durationMs: number
  startTime: number
}

const mockTrace: TraceSpan[] = [
  {
    id: 'root',
    name: 'GET /checkout',
    service: 'gateway',
    durationMs: 250,
    startTime: Date.now() - 250
  },
  {
    id: 'auth',
    parentId: 'root',
    name: 'AuthService.verify',
    service: 'auth',
    durationMs: 45,
    startTime: Date.now() - 240
  },
  {
    id: 'payments',
    parentId: 'root',
    name: 'PaymentService.charge',
    service: 'payments',
    durationMs: 110,
    startTime: Date.now() - 200
  },
  {
    id: 'db',
    parentId: 'payments',
    name: 'DB.query',
    service: 'postgres',
    durationMs: 80,
    startTime: Date.now() - 180
  }
]

export async function fetchTraces(query: string) {
  const adapter = createTracesAdapter()
  return adapter.queryTraces(query)
}

export function createTracesAdapter(baseUrl?: string, token?: string) {
  const client = createOpenObserveClient({ baseUrl, token })
  return {
    async queryTraces(query: string, params?: Record<string, string>) {
      void params
      return await client.request<TraceSpan[]>(`/traces/query`, {
        method: 'POST',
        body: JSON.stringify({ query })
      })
    }
  }
}
