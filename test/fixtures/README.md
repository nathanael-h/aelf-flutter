# API fixtures

**These are real, unmodified AELF API responses.** They were fetched with
`curl` on 2025-06-20 and committed verbatim apart from one transformation
described below. Do not hand-edit them: a hand-written fixture only tests the
schema someone imagined, which is exactly the kind of fiction these are meant
to prevent.

## Provenance

| Fixture | Endpoint |
| --- | --- |
| `mass_single.json` | `api.aelf.org/v1/messes/2025-06-10/france` — an ordinary Tuesday, one mass |
| `mass_multiple.json` | `api.aelf.org/v1/messes/2025-06-08/france` — Pentecost, vigil + day mass |
| `office_laudes.json` | `api.aelf.org/v1/laudes/2025-06-08/france` |
| `office_lectures.json` | `api.aelf.org/v1/lectures/2025-06-08/france` |
| `office_vepres.json` | `api.aelf.org/v1/vepres/2025-06-08/france` |
| `office_complies.json` | `api.aelf.org/v1/complies/2025-06-08/france` |
| `informations.json` | `api.app.epitre.co/82/office/informations/2025-06-08.json?region=france` |
| `informations_weekday.json` | `api.app.epitre.co/82/office/informations/2025-06-10.json?region=france` |

`office_error.json` is the one synthetic file, and deliberately so: the API
answers an unknown date with an **HTML** 404 page, not JSON.
`LiturgyState._getAELFLiturgyOnWeb` checks the status code before decoding and
synthesises `{"<type>": {"erreur_technique": …}}` itself, so that synthesised
shape — not the HTML — is what the parsers actually receive.

## The one transformation

`_getAELFLiturgyOnWeb` drops every key but the requested `type`:

```dart
obj.removeWhere((key, value) => key != type);
```

The raw `api.aelf.org` responses carry both `informations` and the office key,
so each fixture here has been reduced to its single top-level key. That is the
only change; the content below it is untouched.

## Refreshing them

The liturgy for a given date is fixed, so these do not go stale. If you need a
new one, fetch it and strip it the same way:

```sh
curl -s "https://api.aelf.org/v1/laudes/2025-06-08/france" \
  | python3 -c 'import json,sys;d=json.load(sys.stdin);json.dump({"laudes":d["laudes"]},sys.stdout,ensure_ascii=False,indent=2)' \
  > test/fixtures/office_laudes.json
```

`tool/describe_fixtures.dart` prints what the parsers make of every fixture,
which is the quickest way to see what an assertion should say.

## Why they exist

To freeze the **online** (API-backed) liturgy while the offline liturgy is
built behind `feature_offline_liturgy`. If a test reading one of these starts
failing, the online rendering changed — a regression unless it was deliberate.

Because they are real, they also pin down real-world oddities that invented
data would miss, and the tests below name them: a Pentecost vigil whose four
readings are *all* typed `lecture_1`, a psalm reference that renders as
`Ps  103` with a double space, titles carrying trailing whitespace, and a
solemnity with a null `psalter_week`.
