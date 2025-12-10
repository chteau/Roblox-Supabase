import { source } from "@/lib/source";
import { DocsLayout } from "fumadocs-ui/layouts/docs";
import { SidebarProvider } from "fumadocs-ui/components/sidebar/base";
import { baseOptions } from "@/lib/layout.shared";

import { Braces, LibraryBig } from "lucide-react";
import { ReactNode } from "react";

export default function Layout({ children }: LayoutProps<"/docs">) {
    return (
        <SidebarProvider>
            <DocsLayout
                tree={source.pageTree}
                {...baseOptions()}
                sidebar={{
                    tabIndex: 0,
                    tabs: [
                        {
                            icon: <TabIcon icon={<LibraryBig />} />,
                            title: "Client Docs",
                            description:
                                "The Roblox Supabase Client documentation",
                            url: "/docs",
                        },
                        {
                            icon: <TabIcon icon={<Braces />} />,
                            title: "Contribution Guide",
                            description:
                                "The Roblox Supabase Contribution Guide",
                            url: "/docs/contribute",
                        }
                    ],
                }}
            >
                {children}
            </DocsLayout>
        </SidebarProvider>
    );
}

const TabIcon = ({ icon }: { icon: ReactNode }) => {
    return (
        <div className="size-full [&_svg]:size-full max-md:p-1.5 max-md:rounded-md max-md:border max-md:bg-fd-secondary">
            {icon}
        </div>
    );
};
