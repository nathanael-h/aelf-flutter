# Geolocation: the offline-region auto-detection workflow

Lets the app suggest the liturgical region/diocese (`offline_region`, used by
the offline liturgy only — the online API liturgy has its own, separate
`region` setting and ignores all of this) from the device's position,
instead of the user picking it by hand every time they move. Android and iOS
only: desktop and web have no reliable device position, so the whole feature
stays hidden and dormant there (see "Platform scope" below).

Code map:

| Piece | File | Role |
| --- | --- | --- |
| `GeolocalisationService` | `lib/utils/geolocalisation_service.dart` | OS permission state, position fetch, country/diocese resolution (possibly several candidates), the proposal dialogs, the revoked-access banner, the no-renag signature |
| `GeolocationSetting` | `lib/widgets/geolocation_setting.dart` | The settings screen's toggle row |
| `GeolocationAccessBanner` | `lib/widgets/geolocation_access_banner.dart` | App-wide `MaterialBanner` warning when access was revoked after being granted |
| `AelfHomePageState._maybeDetectGeolocation` | `lib/app_screens/aelf_home_page.dart` | The silent, throttled background check on launch/resume |
| `keyOfflineGeolocation` / `getOfflineGeolocation` / `setOfflineGeolocation` | `lib/utils/settings.dart` | The stored "detect automatically" preference (off by default) |
| `LocationService` | `lib/utils/location_service.dart` | Reads/writes the selected `offline_region`, looks up display names in the location tree |

## The two independent states to keep in mind

1. **The app's own preference** — `offlineGeolocationEnabled` (`FeatureFlagsState`,
   persisted via `keyOfflineGeolocation`). Only ever changed by the user
   flipping the settings switch. **Never flipped back by the app itself**,
   even when the OS revokes the permission — see "Revoked after being
   granted" below.
2. **What the OS currently allows** — `GeolocalisationService.access()`,
   recomputed on demand (never cached across the two states above). One of:
   - `allowed` — may ask for the position right now.
   - `askable` — not granted, but the OS will still show its own prompt if
     asked (fresh install, or a soft revoke — see below).
   - `serviceDisabled` — location is off for the whole device.
   - `denied` — permanently refused (iOS "Never", Android "don't ask
     again"); only the system settings can change this now.

   A screen showing anything about geolocation always reads this fresh
   rather than trusting a flag, because it can change at any moment outside
   the app (system settings, a system dialog, the location toggle in quick
   settings).

## Fresh install

`offlineGeolocationEnabled` is `false` by default. Nothing happens
automatically: no permission prompt, no detection, no banner. The settings
row shows the switch off, no warning.

## Turning the toggle on (`GeolocationSetting._onChanged`)

1. `GeolocalisationService.requestAccess()` is called first.
   - Already `allowed` → skip straight to step 2.
   - `askable` → the **native OS permission dialog** appears.
     - Granted (while-in-use / always) → continue.
     - Refused → `access` is re-read; if it comes back `askable` the switch
       just stays off (the user can try again any time); if it comes back
       `denied` the row switches to the blocked state (see below).
   - `serviceDisabled` → no OS dialog at all (there is nothing to ask); the
     row shows "La localisation est désactivée sur l'appareil." plus (except
     on iOS, which has no such deep link) an "Ouvrir les réglages" button
     straight to the device's location settings.
   - `denied` already (hard-blocked from a previous session) → same
     treatment, with the steps specific to iOS/Android and a button to the
     app's own settings page.
2. Only once access is confirmed `allowed`: the preference is persisted
   (`setOfflineGeolocationEnabled(true)`), a **"Détection de la position en
   cours…" SnackBar** appears, and
   `GeolocalisationService.detectAndPropose(context, userInitiated: true)`
   runs with a generous 25 s budget for a cold GPS fix (last-known position
   is tried first; a background check only gets 10 s, since nothing is
   waiting on it — see below).
3. The "en cours" SnackBar is replaced by exactly one of:
   - **A single, different, known location was detected** → the "Position
     détectée" dialog: the name, and `Ignorer` / `Choisir manuellement`
     (opens the full location tree picker) / `Utiliser` (applies it
     immediately).
   - **More than one known location matches** → see "Ambiguous detection"
     below.
   - **A French diocese with no data yet** was detected → the same
     single-candidate dialog, without `Utiliser`, with an explanation that
     the diocese isn't registered and an invitation to contact the
     developers or turn detection off.
   - **Already on the detected location** (or on one of several candidates)
     → a plain SnackBar, "Vous êtes déjà sur la localisation détectée." No
     dialog.
   - **Detection failed** (no fix within the budget, no network for
     reverse geocoding, anything unexpected) → a SnackBar, "Position
     introuvable. Réessayez, ou choisissez votre localisation manuellement
     dans les réglages." This is the fix for the original gap: silence used
     to mean the same thing as "detected, already correct," and the user had
     no way to tell which one had happened.

## Turning the toggle off

Only clears the preference. No confirmation, no re-detection. The
background check and the revoked-access banner go dormant immediately
(both read the live preference).

## Ambiguous detection (more than one candidate)

Resolving a position to a location can yield more than one plausible
answer in two different ways:

1. **A diocese is always paired with its country.** A diocese and its
   national calendar can genuinely differ (local feasts, a diocese's own
   proper, etc.), so detecting **Lyon** never silently applies Lyon on its
   own — it is offered *alongside* **France**, and the user picks. This is
   the common case: almost every French diocese detection is at least a
   two-way choice.
2. **Two diocese polygons can both match.** France's 82 diocese boundaries
   (`assets/geo/france_dioceses.geojson`, OSM-derived,
   `GeolocalisationService._findInDioceses`) can overlap very slightly near
   a shared edge between two adjacent dioceses, so a point can genuinely
   fall inside more than one polygon at once — e.g. a point near the
   Drôme/Isère border matching both **Diocèse de Valence** and
   **Grenoble** (which then also both get paired with France, a three-way
   choice). The department-level fallback used when no polygon matches
   (`france_departments.geojson` + `france_diocese_mapping.json`) is a flat
   one-to-one mapping and can never be ambiguous on its own.

`detectAndPropose`:

1. Resolves every matching diocese/country candidate (`_resolveLocationIds`),
   then keeps only the ones already registered in the location tree — an
   unregistered diocese is never offered as a choice (see the "no data yet"
   flow above; if *every* candidate is unregistered, that flow is used with
   the first one). Call this set `known`.
2. If the **current** selection is already in `known`, does nothing
   (`unchanged`) — no point asking when the plausible, specific answer is
   already in effect. This check is against `known`, deliberately *before*
   France is added below: already being on generic France does **not** by
   itself suppress offering a more specific diocese that was just detected.
3. `GeolocalisationService.offeredCandidates(known)` adds France whenever
   `known` contains anything that isn't itself a stable country/continent
   id (i.e. a diocese) — this is where case 1 above happens, every time.
4. One candidate to offer → the single-answer "Position détectée" dialog
   (name + `Utiliser`). More than one → `showAmbiguousDetectionDialog`,
   also titled "Position détectée", asking "Quel calendrier liturgique
   souhaitez-vous utiliser ?" with one filled button per candidate (its display
   name — tapping it selects that location immediately), plus `Choisir
   manuellement` (the full picker) and `Ignorer`. The wording deliberately
   avoids "plusieurs localisations possibles": with case 1, the multi-
   candidate dialog is the *normal* French path, not an anomaly, and
   phrasing it as one would read like a data glitch to someone in Lyon.

### Not re-asking until the choices change

Every proposal — single, unknown-diocese, or ambiguous — is reduced to a
canonical string by `GeolocalisationService.proposalSignature` (the sorted
candidate ids, prefixed `known:` or `unknown:`) and compared against
`getGeoLastProposedSignature()` (persisted via `keyGeoLastProposedSignature`
in `lib/utils/settings.dart`). If the signature is unchanged from last
time, the **background** check returns `unchanged` and shows nothing: the
user already answered (or ignored) this exact question once.

**A user-initiated call always bypasses this** (`_alreadyProposed` returns
false for `userInitiated`). The dedup exists to stop the hourly check from
nagging, never to refuse an answer to someone who just turned the toggle
on and is waiting for one — and without the bypass, toggling off and on to
retry after dismissing a proposal would answer "Vous êtes déjà sur la
localisation détectée" while the user sat on a completely different
region, with the proposal suppressed for good.

The signature is persisted **after** the dialog is actually built (inside
`_showDialog`'s post-frame callback), not when the decision to show it is
taken: persisting up front would permanently burn a proposal on any frame
where the context goes away before the dialog appears.

This replaced the previous, narrower rule that only ever re-asked for an
unregistered diocese (every single hourly check) while silently relying on
"already matches the current selection" everywhere else — which still nagged
once per hour for an ignored proposal, as long as the user hadn't accepted
or manually changed it.

## The silent background check (`_maybeDetectGeolocation`)

Runs once on `initState` and again on every `AppLifecycleState.resumed`,
throttled to **at most once per hour** (`_lastGeoCheck`). Skips entirely,
with no OS prompt and no feedback, unless *all* of:

- the platform is supported (Android/iOS);
- the offline liturgy feature flag is on (the row that would let the user
  see or turn this off is hidden otherwise — see "Offline liturgy off"
  below);
- `offlineGeolocationEnabled` is true;
- access is already `allowed`.

If access is only `askable` (see "Revoked after being granted"), **this
check does not call `Geolocator.requestPermission()` any more** — it used
to, which meant the native permission dialog could pop up out of nowhere,
with no explanation, just from opening or resuming the app. Only an
explicit tap on the settings switch may trigger that OS dialog now.

When access is `allowed`, the check runs `detectAndPropose` exactly as
above, except silently: no "en cours" SnackBar, no failure/unchanged
message — only the proposal dialog appears, and only if the location
actually changed. This is deliberate: a passive, once-an-hour check must
not nag the user when there is nothing to tell them.

## Revoked after being granted

This is the case that prompted this document: the toggle was on, the app
was used successfully, then the OS permission changed *outside* the app
(system settings, or a prompt from another app/OS flow). What happens
depends on which of the three non-`allowed` states it drops to:

| New `access()` | Can the switch itself fix it? | Settings row | Home-screen banner |
| --- | --- | --- | --- |
| `askable` (Android soft revoke, e.g. "Allow only while using" → "Ask every time") | **Yes** — tapping it re-triggers `requestAccess()` | Switch shown **off** (not a lying "on"), not greyed, inline note: "AELF n'a plus l'autorisation d'accéder à votre position. Réactivez le réglage pour la redemander." | "AELF n'a plus l'autorisation... la détection automatique de votre région est en pause." + `Ouvrir les réglages` / `Fermer` |
| `denied` (iOS "Never", Android "don't ask again") | No — only the system settings can | Switch greyed off, same wording as a fresh hard-deny, with the OS-specific steps and `Ouvrir les réglages` → app's settings page | Same message as `askable` + `Ouvrir les réglages` → app's settings page |
| `serviceDisabled` (location off device-wide) | No | Switch greyed off, "La localisation est désactivée sur l'appareil.", steps, `Ouvrir les réglages` → device location settings (hidden on iOS, which has no such deep link) | "La localisation a été désactivée sur l'appareil..." + `Ouvrir les réglages` (same iOS exception) / `Fermer` |

Both surfaces (the settings row and the banner) re-check `access()`
independently, on every `AppLifecycleState.resumed` — so returning from the
system settings, or just backgrounding and foregrounding the app, refreshes
both without needing to reopen the settings screen (checking `access()` is
a local, instant call — no GPS, no network — so unlike the detection it
needs no throttle).

The banner itself is shown **once per distinct reason**, tracked by
`_warnedAccess`: re-checking while the same `access()` state still holds
leaves the current banner (which the user may have dismissed) alone, and
only a change of reason — or the problem being fixed — clears it and
possibly puts a new one up. This matters because
`ScaffoldMessenger.showMaterialBanner` *queues*: showing one per resume
would stack identical banners, and "Fermer" would then have to be tapped
once per resume, each tap revealing the next copy. Clearing uses
`clearMaterialBanners()` (safe on an empty queue) rather than
`hideCurrentMaterialBanner()`, which would only pop the head.

The stored preference is **never** flipped off by any of this — if access
is later restored, everything just quietly resumes (see below).

### "Don't ask again" specifically

`deniedForever` (iOS "Never"; Android's "Don't ask again" + Deny) always
maps to `GeolocationAccess.denied` — the hard-block row in the table above
— whichever of the two ways it is reached:

- **Chosen on the very first prompt** (fresh install, or after having been
  off): `_onChanged(true)` never gets to persist the preference (it returns
  before `setOfflineGeolocationEnabled`), so the toggle simply stays off,
  greyed, with the warning and the way to the app's settings. No banner
  either, since the preference was never turned on.
- **Chosen on a *re*-prompt**, after a previous soft revoke (`askable`) had
  already turned the switch "lapsed" (off, but tappable): tapping it calls
  `requestAccess()` again, which this time comes back `denied`. The
  preference, already `true` from when it first worked, is **left alone** —
  `_onChanged` only ever writes it on a successful grant — so the row
  immediately switches from "lapsed" to the full hard-block state (greyed,
  warning, steps, settings button). This same `_onChanged` call pings
  `GeolocalisationService.accessChanged`, which `GeolocationAccessBanner`
  listens to, so the banner updates immediately too — it does not wait for
  the next app backgrounding/resume to notice the new, stronger denial.

Either way, from that point on only the system settings can undo it — the
in-app switch has nothing left to offer beyond "Ouvrir les réglages", and
stays greyed until `access()` reports something other than `denied` again.

## Access restored afterward

Nothing dedicated: the settings row's and the banner's own
`didChangeAppLifecycleState(resumed)` handlers re-read `access()` and clear
the blocked/lapsed state as soon as it comes back `allowed`. The background
check also runs its own on-resume pass and, once the hourly throttle allows
it, will silently detect-and-propose exactly as if the toggle had just been
turned on — except, being the silent path, it stays quiet if the location
turns out to already be correct, and simply does nothing if detection fails
once again.

## Offline liturgy feature flag off

The settings screen only shows the "Localisation" section (region picker +
the geolocation toggle) while `offlineLiturgyEnabled` is true, because
`offline_region` has no effect on the online API liturgy. Consistently, the
background check and the banner both go dormant the moment the flag is off,
regardless of what `offlineGeolocationEnabled` or the OS permission say —
otherwise the app could keep asking for and acting on a position for a
setting the user has no way to even see, let alone turn off. Turning the
offline liturgy back on resumes exactly where things were left (nothing is
reset).

## Platform scope

`GeolocalisationService.isSupportedPlatform` is `true` only on Android and
iOS (`!kIsWeb && (Platform.isAndroid || Platform.isIOS)`). The settings row,
the background check and the banner are all gated on it:

- on Linux/macOS/Windows/web, the "Détecter ma position automatiquement" row
  does not appear at all (the region picker above it still does — manual
  selection always works everywhere);
- the background check returns immediately;
- the banner widget is not even mounted.

This matches the product decision that desktop/web have no reliable
position worth acting on, rather than showing a toggle that would mostly
fail silently or throw through an unimplemented platform channel.

## Known limitations (by design, not bugs)

- The settings row and the banner both only re-check `access()` on
  `initState` and on `AppLifecycleState.resumed`. Disabling location from a
  quick-settings panel *without* backgrounding the app (rare, but possible
  on some Android launchers) is not caught until the next resume.
- The background detection's one-hour throttle is per app process
  (`_lastGeoCheck` is an in-memory field): force-quitting and reopening the
  app resets it, so a fresh cold start always re-checks regardless of how
  recently the app ran before.
- The proposal dialog and the banner's wording are French-only, like the
  rest of the app's UI strings.
- The diocese-polygon lookup itself (`_findInDioceses`, `_findDepartment`,
  `_pointInPolygon`) is not under test: it is private, asset-driven
  (real GeoJSON + an isolate `compute()`), and nothing in this feature was
  under test before this pass either. What *is* tested is everything built
  on top of its output: the dedup signature, and both dialogs.

## Tests

- `test/widgets/geolocation_setting_test.dart` — the settings row: every
  `access()` state, the iOS-specific wording, turning the toggle on/off, the
  lapsed ("askable" after being granted) display and re-request, detection
  outcomes.
- `test/widgets/geolocation_access_banner_test.dart` — the banner: shown/
  hidden by state, by the offline-liturgy flag, dismiss, resume-triggered
  refresh.
- `test/widgets/detection_dialog_test.dart` — the single-candidate proposal
  dialog's day/night contrast.
- `test/widgets/ambiguous_detection_dialog_test.dart` — the multi-candidate
  dialog: one button per candidate, each selecting and closing, `Ignorer`
  choosing nothing.
- `test/utils/geolocalisation_service_test.dart` — `offeredCandidates`: a
  diocese (alone, or two overlapping) always paired with France, a stable
  country/continent id offered alone; `proposalSignature`:
  order-independence, distinctness, known vs. unknown never colliding.
- `test/utils/settings_test.dart` — the last-proposed-signature preference
  round-trips and is unset on a fresh install.
