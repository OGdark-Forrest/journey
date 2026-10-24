# Journey — Tech & Conventions

## Stack
- **Flutter / Dart**, Android-first (iOS later). Tested via Android Studio.
- **serious_python** embeds the Python runtime in the app; the Python algorithm runs as a
  **localhost HTTP server on the device**. Flutter talks to it over `http` to `127.0.0.1`.
  Contract: #[[file:.kiro/steering/api-contract.md]]
- UI state: Flutter built-ins (`ChangeNotifier` + `ListenableBuilder`, `setState` for
  local widget state). No third-party state management library.
- Navigation: not finalized (go_router proposed for the first-launch redirect).
- Font: **Nunito**, default weight **w600 (semibold)**.

## MVP data policy
- **Fully offline. No auth, no cloud in MVP.**
- Frontend data is **hardcoded / mocked for now** while the Python backend is built on a
  separate branch.
- Every hardcoded value, mock, or stub MUST carry a comment saying what replaces it:
  - `// TODO(backend): <what replaces this> — e.g. GET /entries/draft`
  - `// TODO(post-mvp): <deferred feature>` for auth, cloud, paywall, LLM insights.
- Hold off adding the `serious_python` dependency until the backend branch is ready.

## Architecture seams
- Screens read from controllers; controllers read from **repository interfaces**.
- `Mock*Repository` now -> `LocalApi*Repository` (HTTP to the Python server) later.
  Swapping must not require UI changes.
- The generation algorithm stays behind the repository: the frontend only asks for
  "today's draft entry" and sends back "my edits".

## Android integration checklist (when wiring serious_python)
- `minSdk = 23`.
- `INTERNET` permission in `android/app/src/main/AndroidManifest.xml` (debug manifest has it
  by default, release does not).
- Network security config allowing cleartext only to `127.0.0.1`.
- Splash waits on `GET /health`; re-check on app resume.

## Visual direction
- Earthy, soothing, low-vibrancy palette: light greens, browns, beige.
- Light + dark both supported.
- Rounded-rectangle cards, generous padding, large tap targets.
- Otter mascot; confetti on meaningful completions; streaks (no XP).
