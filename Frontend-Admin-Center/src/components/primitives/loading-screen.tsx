export function LoadingScreen({ label }: { label: string }) {
  return (
    <div className="loading-screen">
      <div className="loading-card">
        <div className="spinner" />
        <div className="eyebrow">Workspace shell</div>
        <h1 className="title-lg">{label}</h1>
        <p className="muted">Restoring the local preview state and preparing the parity shell.</p>
      </div>
    </div>
  );
}
