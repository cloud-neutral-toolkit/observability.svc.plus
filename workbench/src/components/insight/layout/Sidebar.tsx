'use client'

import React from 'react'
import { QueryLanguage, TopologyMode } from '../store/urlState'
import { SidebarHeader, SidebarContent } from '@/components/layout/SidebarRoot'
import { InsightSidebarContent } from './InsightSidebarContent'

interface SidebarProps {
  topologyMode: TopologyMode
  activeLanguages: QueryLanguage[]
  onSelectSection: (section: string) => void
  onTopologyChange: (mode: TopologyMode) => void
  onToggleLanguage: (language: QueryLanguage) => void
  onToggleCollapse: () => void
  onHide: () => void
  activeSection: string
  collapsed: boolean
}

export function Sidebar(props: SidebarProps) {
  const { collapsed } = props

  return (
    <SidebarRoot
      className={`border-r border-slate-800 bg-slate-900/70 px-3 py-6 backdrop-blur ${collapsed ? 'w-20' : 'w-full lg:w-72 xl:w-80'
        }`}
    >
      <InsightSidebarContent {...props} />
    </SidebarRoot>
  )
}
