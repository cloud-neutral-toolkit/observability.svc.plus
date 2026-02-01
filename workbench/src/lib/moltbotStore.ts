import { create } from "zustand";
import { persist } from "zustand/middleware";

export type MoltbotLayoutMode = "overlay" | "left-sidebar" | "right-sidebar";

interface MoltbotState {
    isOpen: boolean;
    isMinimized: boolean;
    mode: MoltbotLayoutMode;
    width: number;
    setIsOpen: (open: boolean) => void;
    setMinimized: (minimized: boolean) => void;
    setMode: (mode: MoltbotLayoutMode) => void;
    toggleOpen: () => void;
    close: () => void;
}

export const useMoltbotStore = create<MoltbotState>()(
    persist(
        (set) => ({
            isOpen: false,
            isMinimized: false,
            mode: "overlay",
            width: 400,
            setIsOpen: (isOpen) => set({ isOpen }),
            setMinimized: (isMinimized) => set({ isMinimized }),
            setMode: (mode) => set({ mode }),
            toggleOpen: () => set((state) => ({ isOpen: !state.isOpen })),
            close: () => set({ isOpen: false, isMinimized: false }),
        }),
        {
            name: "moltbot-layout-storage",
        }
    )
);
