# Journey — Project Structure

Feature-first layout under `lib/`. Shared/cross-cutting code lives in `core/` and
`shared/`. Each feature owns its screens, widgets, and controllers.

```
lib/
  main.dart                 # app bootstrap, MaterialApp.router
  app/
    router.dart             # route names/paths, first-launch redirect
    theme.dart              # earthy palette, Nunito text theme, light + dark
  core/
    models/                 # plain data models (LogEntry, EntryChip, Assessment, UserPrefs...)
    repositories/           # repository INTERFACES + Mock* implementations (swappable)
    python/                 # serious_python startup, health check, localhost API client (later)
  shared/
    widgets/                # reusable UI: RoundedCard, PrimaryButton, Mascot, ChipField...
    theme/                  # colors, spacing, radii constants
  features/
    splash/                 # starts Python + waits on /health (mocked for now)
    assessment/             # initial in-depth onboarding (first launch only)
    dashboard/              # home: streak, scrollable log history, add-log + settings buttons
    log_entry/              # core screen: prewritten entry with editable chips (normal/blitz)
    settings/               # small user prefs (no account in MVP)
    insights/               # suggestions/reflections (post-MVP, stubbed)
```

## Notes
- First-launch flow: Splash -> Assessment -> Dashboard. Afterward: Splash -> Dashboard.
  "Has completed assessment" is mocked for now (TODO(backend): `GET /assessment/status`).
- Log history lives inside the dashboard, not as its own screen.
- No auth feature folder in MVP; add it post-MVP alongside the paywall.
- Keep mock data in the Mock*Repository files, not scattered in widgets.
- API shapes: see #[[file:.kiro/steering/api-contract.md]]
