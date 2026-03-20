export default function HomePage() {
  return (
    <main className="admin-center-home">
      <section className="admin-center-home__card">
        <header className="admin-center-home__header">
          <div className="admin-center-home__eyebrow">Admin Center</div>
          <h1 className="admin-center-home__title">Super Admin bootstrap surface</h1>
          <p className="admin-center-home__copy">
            This standalone Next.js app is prepared for static export, nginx serving, and local Docker validation without
            changing the current web app, backend contracts, fixtures, or Portainer stack.
          </p>
        </header>

        <div className="admin-center-home__body">
          <div className="admin-center-home__grid">
            <div className="admin-center-home__panel">
              <strong>Runtime</strong>
              <span>Static export built by Next.js and served by nginx.</span>
            </div>
            <div className="admin-center-home__panel">
              <strong>Future Host</strong>
              <span>`admin.aldervon.com` once infrastructure wiring is ready.</span>
            </div>
            <div className="admin-center-home__panel">
              <strong>Local Target</strong>
              <span>`http://localhost:9200` when the container is published on that port.</span>
            </div>
          </div>

          <div className="admin-center-home__panel">
            <strong>Bootstrap Boundaries</strong>
            <ul className="admin-center-home__list">
              <li>No backend API changes</li>
              <li>No fixture or schema changes</li>
              <li>No current app or Portainer modifications</li>
              <li>Ready for shell and tab implementation in a later pass</li>
            </ul>
          </div>
        </div>
      </section>
    </main>
  );
}
