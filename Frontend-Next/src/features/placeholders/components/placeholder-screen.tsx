import { StatusPill } from "@/components/primitives/status-pill";

type PlaceholderScreenProps = {
  eyebrow: string;
  title: string;
  description: string;
  bullets: string[];
  managerOnly?: boolean;
};

export function PlaceholderScreen({ eyebrow, title, description, bullets, managerOnly = false }: PlaceholderScreenProps) {
  return (
    <div className="stack">
      <section className="hero-stat">
        <div className="eyebrow">{eyebrow}</div>
        <strong>{managerOnly ? "Manager-only shell" : "Placeholder shell"}</strong>
        <h3 style={{ marginBottom: 8 }}>{title}</h3>
        <p className="muted" style={{ margin: 0 }}>{description}</p>
      </section>

      <section className="grid-2">
        <article className="placeholder-card">
          <div className="row-between">
            <div>
              <div className="eyebrow">Phase 1 boundary</div>
              <h3>Intentional placeholder</h3>
            </div>
            <StatusPill label="Mock only" />
          </div>
          <p className="muted">This route exists so navigation, role rules, and layout are validated before deeper feature work starts.</p>
        </article>

        <article className="placeholder-card">
          <div className="eyebrow">Planned next</div>
          <div className="list">
            {bullets.map((bullet) => (
              <div className="list-item" key={bullet}>
                <span>{bullet}</span>
              </div>
            ))}
          </div>
        </article>
      </section>
    </div>
  );
}