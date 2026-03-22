type ParitySectionHeaderProps = {
  title: string;
  subtitle: string;
  className?: string;
};

export function ParitySectionHeader({ title, subtitle, className = "" }: ParitySectionHeaderProps) {
  return (
    <div className={`parity-section-header ${className}`.trim()}>
      <div className="parity-section-header__title">{title}</div>
      <div className="parity-section-header__subtitle">{subtitle}</div>
    </div>
  );
}
