export function StatusPill({ label, tone = "default" }: { label: string; tone?: "default" | "success" | "warning" }) {
  return (
    <span className="status-pill" data-tone={tone}>
      {label}
    </span>
  );
}