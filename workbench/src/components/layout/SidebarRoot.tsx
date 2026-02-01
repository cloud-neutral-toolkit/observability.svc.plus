'use client'

import React from 'react'
import { cn } from '@/lib/utils'

interface SidebarRootProps {
    children: React.ReactNode
    className?: string
}

/**
 * SidebarRoot - The base skeleton for all sidebars.
 * Provides the container and common layout behavior.
 */
export function SidebarRoot({ children, className }: SidebarRootProps) {
    return (
        <aside
            className={cn(
                "flex h-full flex-col bg-background transition-colors duration-300",
                className
            )}
        >
            {children}
        </aside>
    )
}

/**
 * SidebarHeader - Top section of the sidebar (e.g., Branding, Logo).
 */
export function SidebarHeader({ children, className }: { children: React.ReactNode; className?: string }) {
    return <div className={cn("flex-shrink-0", className)}>{children}</div>
}

/**
 * SidebarContent - Middle scrollable section of the sidebar.
 */
export function SidebarContent({ children, className }: { children: React.ReactNode; className?: string }) {
    return <div className={cn("flex-1 overflow-y-auto min-h-0", className)}>{children}</div>
}

/**
 * SidebarFooter - Bottom fixed section of the sidebar (e.g., User, Settings, Call to Action).
 */
export function SidebarFooter({ children, className }: { children: React.ReactNode; className?: string }) {
    return <div className={cn("mt-auto flex-shrink-0", className)}>{children}</div>
}
