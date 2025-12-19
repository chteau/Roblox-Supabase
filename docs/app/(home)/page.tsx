"use client"

import Image from 'next/image';
import Link from 'next/link';
import Beams from "@/components/Beams";

export default function HomePage() {
  return (
    <>
        <div className="flex flex-col justify-center items-center text-center flex-1 z-10 w-1/2 mx-auto">
            <Image src="/logo.png" alt="Supabase" width={100} height={100} className="drop-shadow-xl" />
            <h1 className="text-2xl font-bold mb-4 mt-10">Roblox Supabase</h1>
            <p>
                A comprehensive, type-safe Supabase client for Roblox Luau, providing full access to PostgREST API,
                Storage, and Edge Functions. Built specifically for Roblox's server-side environment with Rojo workflow compatibility.
            </p>

            <Link href={"/docs"}>
                <button className="mt-10 bg-[#34b27b] pl-5 pr-5 pt-2 pb-2 cursor-pointer rounded-sm hover:opacity-80 transition-opacity">
                    See Docs
                </button>
            </Link>

        </div>

        <div style={{ width: '100%', height: '100%', position: 'absolute', top: '0', left: '0', zIndex: '-1' }}>
            <Beams
                beamWidth={3}
                beamHeight={30}
                beamNumber={20}
                lightColor="#34b27b"
                speed={2}
                noiseIntensity={1.75}
                scale={0.2}
                rotation={30}
            />

        </div>
    </>
  );
}
