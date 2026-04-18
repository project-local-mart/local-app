import type { Metadata } from 'next'
import { ClerkProvider } from '@clerk/nextjs'
import { Nav } from '@/components/nav'
import './globals.css'

export const metadata: Metadata = {
  title: 'Localmart',
  description: 'The community-owned local retail marketplace',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className="min-h-screen bg-stone-50 text-stone-900">
          <Nav />
          <main className="mx-auto max-w-6xl px-4 py-8">{children}</main>
        </body>
      </html>
    </ClerkProvider>
  )
}
