import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';
import { Inter } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
});

export const metadata = {
    title: {
        "default": "Roblox Supabase",
        "template": "%s | Roblox Supabase",
    },
    description: "A comprehensive, type-safe Supabase client for Roblox Luau, providing full access to PostgREST API, Storage, and Edge Functions. Built specifically for Roblox's server-side environment with Rojo workflow compatibility.",
    keywords: [
        "Roblox",
        "Luau",
        "Supabase",
    ],
    authors: [
        {
            name: "Cheeteau",
            url: "https://github.com/chteau"
        }
    ],
    creator: "Cheeteau",
    publisher: "Cheeteau",

    // Favicon
    icons: {
        icon: "/logo.png",
        shortcut: "/logo.png",
    },

}

export default function Layout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="en" className={inter.className} suppressHydrationWarning>
      <body className="flex flex-col min-h-screen">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
