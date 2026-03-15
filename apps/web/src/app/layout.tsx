import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Localmart',
  description: 'The community-owned local retail marketplace',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
