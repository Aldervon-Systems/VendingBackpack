# PASS_01 - Extracted Product and Integration Details

## Extracted Details

- The app is at MVP stage with a single manager account in practical testing.
- The core release-critical workflow is machine registration through the admin experience.
- Newly registered machines are expected to appear immediately for the manager organization in dashboard views.
- Current behavior is inconsistent across surfaces:
  - Machines can appear in map/routes contexts.
  - The same machines do not appear in dashboard contexts.
- Session persistence is currently unstable from a user perspective: page reload should preserve login state but does not.
- Runtime/API reliability concerns are present due to observed HTTP 500 failures on critical flows:
  - Login-related path.
  - Machine-add path.
  - Route-related path.
- The issue is treated as a code/data-structure problem, not a ports or container wiring problem.

## Inferred Technical Focus Areas

- Data source consistency between map, routes, and dashboard read models.
- Write/read consistency after machine registration (creation path vs dashboard query path).
- Type and key consistency (`id` formats, machine identifiers, organization scoping).
- Session state durability across browser reload.
- Error handling quality and diagnostics for critical API calls.

## Summary

The release blocker is not feature absence, but integration inconsistency in core flows: machine creation, machine visibility, and session continuity. The highest-priority objective is to make machine registration produce a consistent, immediately visible state across all manager views while stabilizing auth persistence and eliminating opaque 500s on production-critical paths.
