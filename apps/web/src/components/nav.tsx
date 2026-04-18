'use client'

import Link from 'next/link'
import { SignInButton, SignUpButton, UserButton, useAuth } from '@clerk/nextjs'

export function Nav() {
  const { isSignedIn } = useAuth()

  return (
    <header className="border-b border-stone-200 bg-white">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3">
        <Link href="/" className="text-xl font-bold tracking-tight text-emerald-700">
          Localmart
        </Link>
        <nav className="flex items-center gap-4 text-sm">
          {isSignedIn ? (
            <UserButton afterSignOutUrl="/" />
          ) : (
            <>
              <SignInButton mode="modal">
                <button className="text-stone-600 hover:text-stone-900">Sign in</button>
              </SignInButton>
              <SignUpButton mode="modal">
                <button className="rounded-md bg-emerald-600 px-3 py-1.5 text-white hover:bg-emerald-700">
                  Get started
                </button>
              </SignUpButton>
            </>
          )}
        </nav>
      </div>
    </header>
  )
}
