"use client";

import { useState, type FocusEvent } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { LogOut, Settings, UserRound, Zap } from "lucide-react";
import { ParityOverlay } from "@/components/parity/parity-overlay";
import { SettingsPanel } from "@/features/settings/components/settings-panel";
import { APP_ROUTES } from "@/lib/routes";
import { getNavItems } from "@/components/shell/nav-items";
import { useAuth } from "@/providers/auth-provider";
import { useShell } from "@/providers/shell-provider";

const pageTitles: Record<string, string> = {
  "/overview": "Overview",
  "/organizations": "Organizations",
  "/access": "Access",
  "/machine-config": "Machine Config",
  "/fleet": "Fleet",
  "/incidents": "Incidents",
  "/broadcasts": "Broadcasts",
};

export function AppShell({ children }: Readonly<{ children: React.ReactNode }>) {
  const pathname = usePathname();
  const router = useRouter();
  const [railExpanded, setRailExpanded] = useState(false);
  const { session, logout } = useAuth();
  const { settingsOpen, setSettingsOpen } = useShell();
  const navItems = getNavItems();
  const normalizedPath = pathname.endsWith("/") && pathname !== "/" ? pathname.slice(0, -1) : pathname;
  const pageTitle = pageTitles[normalizedPath] ?? "Admin Workspace";

  function handleRailBlur(event: FocusEvent<HTMLElement>) {
    const nextFocusTarget = event.relatedTarget;

    if (!(nextFocusTarget instanceof Node) || !event.currentTarget.contains(nextFocusTarget)) {
      setRailExpanded(false);
    }
  }

  return (
    <div className="shell-page">
      <div className="app-shell" data-rail-expanded={railExpanded}>
        <aside
          className="app-rail"
          onMouseEnter={() => setRailExpanded(true)}
          onMouseLeave={() => setRailExpanded(false)}
          onFocusCapture={() => setRailExpanded(true)}
          onBlurCapture={handleRailBlur}
        >
          <div className="app-rail__logo">
            <div className="app-rail__mark">
              <Zap size={18} strokeWidth={2.5} />
            </div>
            <span className="app-rail__wordmark">ADMIN CENTER</span>
          </div>

          <div className="app-rail__body">
            <nav className="app-nav">
              {navItems.map(({ href, icon: Icon, label }) => (
                <Link key={href} href={href} className="app-nav__item" data-active={normalizedPath === href}>
                  <Icon size={20} />
                  <span className="app-nav__label">{label}</span>
                </Link>
              ))}
            </nav>

            <div className="app-rail__footer">
              <button className="app-nav__item" type="button" onClick={() => setSettingsOpen(true)}>
                <Settings size={20} />
                <span className="app-nav__label">Settings</span>
              </button>
              <button
                className="app-nav__item"
                type="button"
                onClick={async () => {
                  await logout();
                  router.replace(APP_ROUTES.login);
                }}
              >
                <LogOut size={20} />
                <span className="app-nav__label">Sign Out</span>
              </button>
            </div>
          </div>
        </aside>

        <main className="app-main">
          <header className="app-header">
            <div className="app-header__title">{pageTitle}</div>

            <div className="app-header__user">
              <div className="app-header__meta">
                <div className="app-header__name">{session?.user.name}</div>
                <div className="app-header__subtext">{session?.user.clearance}</div>
              </div>
              <div className="app-header__avatar">
                <UserRound size={16} />
              </div>
            </div>
          </header>

          <div className="app-content">{children}</div>
        </main>
      </div>

      <nav className="mobile-nav">
        {navItems.map(({ href, icon: Icon, label }) => (
          <Link key={href} href={href} className="mobile-nav__item" data-active={normalizedPath === href}>
            <Icon size={18} />
            <span>{label}</span>
          </Link>
        ))}
        <button className="mobile-nav__item" type="button" onClick={() => setSettingsOpen(true)}>
          <Settings size={18} />
          <span>Settings</span>
        </button>
      </nav>

      {settingsOpen ? (
        <ParityOverlay onBackdropClick={() => setSettingsOpen(false)}>
          <SettingsPanel onClose={() => setSettingsOpen(false)} />
        </ParityOverlay>
      ) : null}
    </div>
  );
}
