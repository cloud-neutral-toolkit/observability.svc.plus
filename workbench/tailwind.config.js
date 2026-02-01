/**
 * Tailwind CSS 配置文件
 * 使用 ES Module 格式 - 统一现代标准
 * 
 * 参考: https://tailwindcss.com/docs/configuration
 */

import typography from '@tailwindcss/typography'

const tailwindConfig = {
  // 扫描的源文件路径
  content: [
    './src/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],

  // 主题扩展配置
  theme: {
    extend: {
      colors: {
        border: 'var(--color-surface-border)',
        input: 'var(--color-surface-border)',
        ring: 'var(--color-ring)',
        background: 'var(--color-background)',
        foreground: 'var(--color-text)',
        primary: {
          DEFAULT: 'var(--color-primary)',
          foreground: 'var(--color-primary-foreground)',
        },
        secondary: {
          DEFAULT: 'var(--color-surface-muted)',
          foreground: 'var(--color-text-muted)',
        },
        destructive: {
          DEFAULT: 'var(--color-danger)',
          foreground: 'var(--color-danger-foreground)',
        },
        muted: {
          DEFAULT: 'var(--color-surface-muted)',
          foreground: 'var(--color-text-muted)',
        },
        accent: {
          DEFAULT: 'var(--color-accent)',
          foreground: 'var(--color-accent-foreground)',
        },
        popover: {
          DEFAULT: 'var(--color-surface-elevated)',
          foreground: 'var(--color-text)',
        },
        card: {
          DEFAULT: 'var(--color-surface)',
          foreground: 'var(--color-text)',
        },
        brand: {
          DEFAULT: '#3366FF',      // 主色
          light: '#4D7AFF',        // 浅色
          dark: '#254EDB',         // 深色
          surface: '#F5F8FF',      // 表面色
          border: '#D6E0FF',       // 边框色
          navy: '#1E2E55',         // 海军蓝
          heading: '#2E3A59',      // 标题色
        },
        surface: {
          DEFAULT: 'var(--color-surface)',
          muted: 'var(--color-surface-muted)',
          border: 'var(--color-surface-border)',
          hover: 'var(--color-surface-hover)',
        },
        text: {
          DEFAULT: 'var(--color-text)',
          muted: 'var(--color-text-muted)',
          subtle: 'var(--color-text-subtle)',
        },
        heading: 'var(--color-heading)',
      },

      // 字体配置
      fontFamily: {
        sans: ['var(--font-geist-sans)', 'sans-serif'],
        mono: ['var(--font-geist-mono)', 'monospace'],
      },

      // 自定义阴影
      boxShadow: {
        soft: '0 35px 80px -45px rgba(37, 78, 219, 0.35), 0 25px 60px -40px rgba(15, 23, 42, 0.25)',
      },
    },
  },

  // 插件
  plugins: [
    typography,
  ],
}

export default tailwindConfig
