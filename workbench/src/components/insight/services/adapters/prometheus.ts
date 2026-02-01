import { createOpenObserveClient } from './openobserve'

interface SeriesPoint {
  timestamp: number
  value: number
}

export interface PrometheusResponse {
  metric: string
  points: SeriesPoint[]
}

const mockSeries: PrometheusResponse[] = [
  {
    metric: 'latency_p95',
    points: Array.from({ length: 20 }).map((_, idx) => ({
      timestamp: Date.now() - (19 - idx) * 60000,
      value: 120 + Math.sin(idx / 2) * 30
    }))
  },
  {
    metric: 'error_rate',
    points: Array.from({ length: 20 }).map((_, idx) => ({
      timestamp: Date.now() - (19 - idx) * 60000,
      value: 0.5 + Math.cos(idx / 1.5) * 0.1
    }))
  }
]

export async function fetchPromQL(query: string) {
  const adapter = createPrometheusAdapter()
  return adapter.queryRange(query)
}

export function createPrometheusAdapter(baseUrl?: string, token?: string) {
  const client = createOpenObserveClient({ baseUrl, token })
  return {
    async queryRange(query: string, params?: Record<string, string>) {
      void params
      return await client.request<PrometheusResponse[]>(`/prometheus/api/v1/query`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({ query }).toString()
      })
    }
  }
}
