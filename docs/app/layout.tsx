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
        "PostgreSQL",
        "Database",
        "Game Development",
        "Roblox Studio",
        "PostgREST",
        "Edge Functions"
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

    // Additional Metadata
    robots: {
        index: true,
        follow: true,
        googleBot: {
            index: true,
            follow: true,
            'max-video-preview': -1,
            'max-image-preview': 'large',
            'max-snippet': -1,
        },
    },

    // Open Graph / Social Media Metadata
    openGraph: {
        type: "website",
        url: "https://roblox-supabase.vercel.app",
        title: "Roblox Supabase",
        description: "A comprehensive, type-safe Supabase client for Roblox Luau, providing full access to PostgREST API, Storage, and Edge Functions. Built specifically for Roblox's server-side environment with Rojo workflow compatibility.",
        siteName: "Roblox Supabase",
        images: [
            {
                url: "/banner.png",
                width: 1200,
                height: 630,
                alt: "Roblox Supabase - Full Supabase Integration for Roblox Games",
            },
        ],
        locale: "en_US",
    },

    // Twitter Card Metadata
    twitter: {
        card: "summary_large_image",
        title: "Roblox Supabase",
        description: "A comprehensive, type-safe Supabase client for Roblox Luau, providing full access to PostgREST API, Storage, and Edge Functions.",
        images: ["/banner.png"],
        creator: "@Cheeteau_",
        site: "@Cheeteau_",
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
