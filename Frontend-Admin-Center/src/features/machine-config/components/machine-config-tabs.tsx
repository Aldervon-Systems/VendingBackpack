"use client";

import type { MachineConfigTabId } from "@/features/machine-config/lib/types";

type TabOption = {
  id: MachineConfigTabId;
  label: string;
};

type MachineConfigTabsProps = {
  tabs: TabOption[];
  activeTab: MachineConfigTabId;
  onChange: (tabId: MachineConfigTabId) => void;
};

export function MachineConfigTabs({ tabs, activeTab, onChange }: MachineConfigTabsProps) {
  return (
    <div className="machine-config-tabs" role="tablist" aria-label="Machine configuration views">
      {tabs.map((tab) => (
        <button
          key={tab.id}
          className="machine-config-tabs__tab"
          type="button"
          data-active={tab.id === activeTab}
          onClick={() => onChange(tab.id)}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}
