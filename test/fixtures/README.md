# API fixtures

These files are trimmed but structurally faithful captures of what the online
AELF API returns, shaped exactly as they reach the parsers.

`LiturgyState._getAELFLiturgyOnWeb` strips every key but the requested `type`
(`obj.removeWhere((key, value) => key != type)`), so a fixture has a single
top-level key — `messes`, `laudes`, `complies`, `informations`, … — mirroring
what `LiturgyParserService.parse` actually receives.

They exist to freeze the **online** (API-backed) liturgy behaviour while the
offline liturgy is developed behind the `feature_offline_liturgy` flag. If a
test that reads one of these starts failing, the online rendering changed —
that is a regression unless it was deliberate.

Sources:
- `v1/messes/{date}/{region}` → `mass_*.json`
- `v1/{office}/{date}/{region}` → `office_*.json`
- `82/office/informations/{date}.json` (api.app.epitre.co) → `informations_*.json`
