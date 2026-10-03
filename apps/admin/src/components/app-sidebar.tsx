"use client";

import {
  BadgePercent,
  ChevronsUpDown,
  GalleryHorizontalEnd,
  LayoutDashboard,
  LogOut,
  Moon,
  PackageSearch,
  Settings,
  ShieldCheck,
  Shirt,
  Sun,
  Truck,
  Users,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useTheme } from "next-themes";
import { BrandWordmark } from "@/components/brand";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
} from "@/components/ui/sidebar";
import { useAuth } from "@/lib/auth/auth-provider";
import { phone } from "@/lib/format";

interface NavItem {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  superAdminOnly?: boolean;
}

const NAV: { label: string; items: NavItem[] }[] = [
  {
    label: "Operations",
    items: [
      { href: "/", label: "Dashboard", icon: LayoutDashboard },
      { href: "/orders", label: "Orders", icon: PackageSearch },
      { href: "/customers", label: "Customers", icon: Users },
      { href: "/drivers", label: "Delivery partners", icon: Truck },
    ],
  },
  {
    label: "Storefront",
    items: [
      { href: "/catalog", label: "Services & prices", icon: Shirt },
      { href: "/promotions", label: "Promotions", icon: BadgePercent },
      { href: "/banners", label: "Banners", icon: GalleryHorizontalEnd },
    ],
  },
  {
    label: "Administration",
    items: [
      { href: "/staff", label: "Staff", icon: ShieldCheck, superAdminOnly: true },
      { href: "/settings", label: "Business settings", icon: Settings },
    ],
  },
];

function isActive(pathname: string, href: string): boolean {
  return href === "/" ? pathname === "/" : pathname === href || pathname.startsWith(`${href}/`);
}

export function AppSidebar() {
  const pathname = usePathname();
  const { user, isSuperAdmin, signOut } = useAuth();
  const { resolvedTheme, setTheme } = useTheme();

  return (
    <Sidebar collapsible="icon">
      <SidebarHeader className="px-3 py-4">
        <Link href="/" className="rounded-md outline-none focus-visible:ring-2 focus-visible:ring-sidebar-ring">
          <BrandWordmark subtitle="Admin" inverse className="text-sidebar-accent-foreground group-data-[collapsible=icon]:[&>span:last-child]:hidden" />
        </Link>
      </SidebarHeader>
      <SidebarContent>
        {NAV.map((group) => (
          <SidebarGroup key={group.label}>
            <SidebarGroupLabel className="text-sidebar-foreground/50">{group.label}</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {group.items
                  .filter((item) => !item.superAdminOnly || isSuperAdmin)
                  .map((item) => {
                    const active = isActive(pathname, item.href);
                    return (
                      <SidebarMenuItem key={item.href}>
                        <SidebarMenuButton
                          asChild
                          isActive={active}
                          tooltip={item.label}
                          className="data-[active=true]:bg-sidebar-accent data-[active=true]:text-sidebar-accent-foreground data-[active=true]:shadow-[inset_3px_0_0_var(--sidebar-primary)]"
                        >
                          <Link href={item.href}>
                            <item.icon className={active ? "text-sidebar-primary" : undefined} />
                            <span>{item.label}</span>
                          </Link>
                        </SidebarMenuButton>
                      </SidebarMenuItem>
                    );
                  })}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        ))}
      </SidebarContent>
      <SidebarFooter>
        <SidebarMenu>
          <SidebarMenuItem>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <SidebarMenuButton size="lg" className="data-[state=open]:bg-sidebar-accent">
                  <span className="flex size-8 shrink-0 items-center justify-center rounded-md bg-sidebar-accent text-xs font-semibold uppercase text-sidebar-accent-foreground">
                    {(user?.name ?? "A").slice(0, 2)}
                  </span>
                  <span className="grid flex-1 text-left text-sm leading-tight">
                    <span className="truncate font-medium text-sidebar-accent-foreground">{user?.name ?? "Admin"}</span>
                    <span className="truncate text-xs text-sidebar-foreground/60">
                      {isSuperAdmin ? "Super admin" : "Admin"}
                    </span>
                  </span>
                  <ChevronsUpDown className="ml-auto size-4 opacity-60" />
                </SidebarMenuButton>
              </DropdownMenuTrigger>
              <DropdownMenuContent side="top" align="start" className="w-60">
                <DropdownMenuLabel className="font-normal">
                  <div className="text-sm font-medium">{user?.name ?? "Admin"}</div>
                  <div className="text-xs text-muted-foreground">{user ? phone(user.phone) : ""}</div>
                </DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem onSelect={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}>
                  {resolvedTheme === "dark" ? <Sun /> : <Moon />}
                  {resolvedTheme === "dark" ? "Light theme" : "Dark theme"}
                </DropdownMenuItem>
                <DropdownMenuItem onSelect={() => void signOut()}>
                  <LogOut />
                  Sign out
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  );
}
