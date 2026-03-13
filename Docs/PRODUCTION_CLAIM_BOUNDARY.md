# Production Claim Boundary

Current production consistency claim:

Production claim is limited to warehouse, machine inventory, items, machines, shipments, employees, routes, and stops, and explicitly excludes vend-history/transactions unless `/api/transactions` is proven irrelevant to the live vend flow.

This narrowed claim remains the default until runtime proof is collected.

## Repo-grounded evidence

- The active Flutter frontend has no observed `/api/transactions` call sites.
- The backend still exposes `/api/transactions` through a legacy controller.
- That controller remains fixture-backed for both transactions and item mutation.

## Evidence rule

- Repo search is useful evidence.
- Runtime logs and traces are stronger evidence.
- Operator or test-flow confirmation is stronger evidence.
- Stale docs mentioning `/api/transactions` do not count as evidence of runtime usage.

## Required runtime verification before widening the claim

- Inspect deployment/runtime logs for `/api/transactions`.
- Confirm whether any vend, test, or ops flow posts to `/api/transactions`.
- If proof is missing, keep the production claim narrowed.
- If `/api/transactions` is proven live, open a separate vend-history hardening pass before making a broader consistency claim.
