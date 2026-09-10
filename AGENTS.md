# Loupe

An iOS app that gives users a hands-on tour of the iOS fingerprinting surface. It reads real values from public iOS APIs—the same ones any third-party app can call—and displays them raw to show what the device exposes and why each reading makes the user identifiable.

Signals are organized into three tiers reflecting the cost of access: **Passive** (no user consent needed), **Needs Permission** (triggers an iOS prompt), and **Advanced** (clever side-channel uses of public APIs — e.g. URL-scheme probing via `canOpenURL`, canvas/WebGL extraction in a hidden `WKWebView`, Keychain persistence across reinstalls).

Nothing collected leaves the device unless the user explicitly exports it. The app deliberately shows raw values without aggregation or hashing.

## Build System

The project uses Xcode's **buildable folders** (folder references), so new Swift files are automatically included in the build. There is no need to manually add files to the Xcode project's build sources.

## SwiftUI — modal Done actions

For sheets and similar modal chrome, use `.confirmationAction` with a titled checkmark button rather than plain `.topBarTrailing`:

```swift
ToolbarItem(placement: .confirmationAction) {
    Button("Done", systemImage: "checkmark") {
        dismiss()
    }
}
```

Keep `.topBarTrailing` for actions that are not the primary dismiss control (for example export or refresh).

## Writing style — user-facing copy

Loupe explains a technical subject (device fingerprinting) to non-technical users. All user-facing strings — onboarding pages, summary sheets, narrative cards, basis captions, signal descriptions — should sound like one consistent, calm voice.

### Voice principles

- **Plain English.** No jargon. Prefer "tracker" over "ad-tech vendor", "settings" over "configuration", "your iPhone" over "the device".
- **Second person, present tense.** Talk to the user about what *their* `\(PlatformDevice.localizedModel)` reveals. Avoid passive constructions like "a device can be identified".
- **Quietly.** Apps "quietly read" or "quietly check" things — this single adverb captures the whole privacy thesis. Use it where it fits, but don't overuse.
- **Short, declarative sentences.** Two short sentences beat one long one. Trim subordinate clauses.
- **No marketing language.** No exclamation marks, no "powerful", no "amazing", no rhetorical hype. The values themselves are persuasive enough.
- **No emojis** in any user-facing string.
- **No em dashes** (—) in any user-facing string. Use a comma, a colon, or two separate sentences instead.
- **Match the device noun.** Use `PlatformDevice.localizedModel` (e.g. "iPhone") when referring to the user's own device, and `PlatformDevice.marketingName` (e.g. "iPhone 15 Pro") when contrasting it with other units of the same model.
- **Contractions are fine** ("don't", "isn't", "you've") — they read more conversational. Just be consistent within a paragraph.
- **Avoid repeated words within a sentence or short paragraph.** If you find yourself writing "permission … permission" or "track you … track you", rephrase one of them.

### Recurring phrases (use these)

- "Any app can quietly read / quietly check …"
- "Trackers don't need your name, email, or location to recognize you online."
- "Each one isn't necessarily unique on its own, but together …"
- "form a fingerprint that follows you online"
- "When the same combination … shows up again across apps and websites, it stands out."
- "Nothing is uploaded, synced, or shared unless you choose to export."
- For narrative-card `basis` strings, prefer the pattern **"Read from \<source\>."** (occasionally "Inferred from …" or "Comparing …" when literally appropriate).

### Examples

**Onboarding / explainer copy**

- DO: "Apps can quietly check which other apps you have installed. That mix hints at your work, travel, finances, hobbies, and habits."
- DON'T: "Did you know?! Apps are able to detect a comprehensive list of all applications installed on your device, which can subsequently be utilized to derive insights about your lifestyle."

- DO: "Some readings are passively visible to apps with no prompt at all, while others require your permission."
- DON'T: "Some readings are passively visible to apps without permission or a prompt, while others require your permission." *(repeats "permission")*

**Narrative card headlines**

- DO: "Your time zone hints that you might be visiting or traveling in Germany."
- DON'T: "Your timezone suggests you may be in or traveling to Germany." *(awkward "in or traveling to"; "timezone" should be "time zone")*

- DO: "You have accessibility settings turned on: larger text and bold text."
- DON'T: "Accessibility settings are active: larger text and bold text." *(passive, less direct)*

- DO: "Lockdown Mode is turned on for this iPhone."
- DON'T: "Lockdown Mode is enabled on this iPhone." *("turned on" is plainer than "enabled")*

**Narrative card `basis` lines**

- DO: "Read from your iPhone's region setting. A VPN does not change this."
- DON'T: "Taken from your iPhone's region setting. Using a VPN does not change this."

- DO: "Read from the clipboard's change counter, a shared number any app can read."
- DON'T: "Read from the clipboard change counter, a shared counter accessible to all apps." *(repeats "counter")*

**Summary / closing copy**

- DO: "None of these readings are a name or an account. But together, they can be distinctive enough to recognize your iPhone again."
- DON'T: "None of these readings constitute personally identifiable information. However, in aggregate they may be sufficient to re-identify the device." *(legalistic, passive)*

- DO: "Loupe reads all of this on your iPhone and keeps it here. Nothing is uploaded, synced, or shared unless you choose to export."
- DON'T: "Loupe does not transmit any data off-device. All values remain local unless explicitly exported."

### When in doubt

Read [`OnboardingPage.swift`](code/Loupe/Views/Onboarding/OnboardingPage.swift) and the headlines in [`FingerprintNarrative.swift`](code/Loupe/Support/FingerprintNarrative.swift) — those are the canonical voice. Match their cadence before introducing a new one.

## Localization

Loupe ships in 17 locales: `en` (source) plus `ar`, `de`, `es`, `fr`, `it`, `ja`, `ko`, `pl`, `pt-BR`, `pt-PT`, `ru`, `tr`, `uk`, `vi`, `zh-Hans`, `zh-Hant`. English is the development region; users on an unsupported language fall back to English.

### The three layers (keep them in lockstep)

1. **`code/Loupe/Localizable.xcstrings`** — all user-facing strings, extracted from `String(localized: "…", comment: "…")` calls in Swift. Always populate the `comment:` so translators know where the string appears.
2. **`code/Loupe/InfoPlist.xcstrings`** — the localized `NSXxxUsageDescription` permission prompts (plus Xcode-managed `CFBundleDisplayName`/`CFBundleName`, leave those alone). These are NOT extracted from Swift; edit the catalog directly. `code/Loupe/Info.plist` holds the **full English usage descriptions** as the development-language source and runtime fallback; the catalog supplies the translations. Keep each key's English text identical in both files. Adding or removing a permission key means updating both files together.
3. **`code/Loupe.xcodeproj/project.pbxproj`** — every shipped locale must appear in `knownRegions` (alphabetical after `en, Base`). Don't re-add `INFOPLIST_KEY_NS*UsageDescription` build settings; they were deliberately removed because build settings can't be localized.

A locale ships in **both** catalogs or not at all — partial coverage feels half-done to users.

### Editing `.xcstrings` files

**Prefer Xcode's MCP string catalog tools over hand-editing the JSON or writing Python scripts.** They understand the format, plurals, substitutions, `shouldTranslate`, and typography, and they keep the diff minimal. The relevant tools (all on the `user-xcode-tools` MCP server) are:

- `XcodeListWindows` — get the `tabIdentifier` for the open workspace (most tools require it).
- `StringCatalogRead` — list keys grouped by translation state (`new`, `needs_review`, `translated`, …) for a locale. Use this to **audit** what is missing or stale before translating. Requires activating the `xcode-integration:translation-coordinator` skill first.
- `StringCatalogContext` — for a given key + target locale, returns the source value, `shouldTranslate` (respect `false` — do not translate), `relevantPluralCases`, usage locations, and `similarStrings` for terminology consistency. Read this **before** translating a key. Requires activating the `xcode-integration:translation` skill first.
- `StringCatalogEdit` — insert a translation for one key + locale, including `templateTranslation`/`variationTranslation` for plurals and substitutions. Requires the `xcode-integration:translation` skill.

A typical loop: `StringCatalogRead` to find untranslated/stale keys → `StringCatalogContext` per key → `StringCatalogEdit` to write each locale. `StringCatalogEdit` writes entries as `"state": "machine_translated"` — leave that as is; don't rewrite it to `"translated"`.

The `(none)` key is a real user-visible string, not a placeholder — translate it literally.

**Only if the MCP tools are unavailable** (e.g. Xcode isn't open) fall back to editing the JSON directly. The format is fussy: 2-space indent, **a space before every colon**, locales sorted alphabetically, and **no trailing newline**. The catalog's top-level keys use a Finder-style (`localizedStandardCompare`) order that Python's `sort_keys=True` does **not** reproduce, so re-sorting reformats the whole file. To keep the diff minimal, load with `json.load` (which preserves key order), mutate in place, and dump **without** `sort_keys`: `f.write(json.dumps(data, ensure_ascii=False, indent=2, separators=(",", " : ")))` — no trailing newline. Verify the result round-trips byte-for-byte against an unchanged dump before trusting it (it does, for both catalogs).

**Adding a whole new locale is the one case where you should NOT use per-key `StringCatalogEdit`.** `Localizable.xcstrings` has ~642 keys (plus 13 in `InfoPlist.xcstrings`), so one edit call per key is impractical. Instead, translate in bulk and merge with the round-trip JSON recipe above. What you need to know about the structure:

- Most keys (~619) are **implicit**: there is no `en` localization entry and the key text *is* the English source. ~19 are "simple" (their `en` `stringUnit.value` differs from the key because it uses numbered specifiers like `%1$@`, `%2$@` — multi-argument strings are always this type), and 4 are plural.
- Build a flat `{key: translation}` map and synthesize each locale node: `stringUnit` for normal keys, and `variations.plural` for plurals. Emit **only the CLDR plural categories that locale declares** (see the Plurals section): `it` needs `one, other`; `pl` needs `one, few, many, other`; `vi`/`ja`/`ko`/`zh` need just `other`. For multi-argument strings copy the **`en` value's** specifier numbering, not the key's.
- Insert the new locale **right after its alphabetical predecessor** in each `localizations` dict (e.g. `ko` goes after `ja`, `it` after `fr`, `pl` after `ko`, `vi` after `uk`); the dicts are kept alphabetical.
- A handful of keys have an `en` value that differs from the key (e.g. the two "Loupe reads… unless you choose to export." cards expand to a longer sentence) and the source has a couple of `en` units left in `"state": "new"`. That staleness is pre-existing in the source — translate the `en` *value*, and don't try to "fix" the source state.
- **Translating ~642 strings is too much for one agent to do well in a single pass — fan the work out to subagents.** Extract the English source values once (dump `{key, en}` or `{key, plural_en}` to a scratch JSON), split the keys into 6 chunks of ~107, and spawn a `Task` subagent per chunk. Give each subagent the full target-language voice guide (address form, the "quietly" word, Apple feature names, calendar-vs-language note, typography, and the locale's plural categories) and have it write its own `{key: translation}` output file for its chunk only — normal keys map to a string, plural keys to `{"plural": {<category>: …}}` — not edit the catalog directly. The parent then concatenates the maps and runs a single merge so there's one writer and one diff. Launch the chunk subagents in parallel (multiple `Task` calls in one message). Note subagents sometimes **undercount** in their summaries; trust the merge script's exact missing/extra-key validation, not the reported counts. The same pattern applies to refreshing many stale keys after a source change.
- After merging, use `StringCatalogRead` per locale to confirm `new: 0, needs_review: 0` and the expected `translated` count. `StringCatalogRead`/`StringCatalogContext`/`StringCatalogEdit` work without a separate skill-activation step in this setup; `StringCatalogRead` is the fastest way to audit and verify coverage.

**Korean (`ko`) specifics:** polite 해요체 with dropped subject pronouns; "your `iPhone`" → `내 %@`, "this `iPhone`" → `이 %@`; "quietly" → `몰래`; "tracker" → `추적기`; "fingerprint" → `지문` (`디지털 지문` in onboarding, to avoid Touch ID's `지문 인식`). Apple feature names: Lockdown Mode `잠금 모드`, Accessibility `손쉬운 사용`, Guided Access `손쉬운 사용 제어기`, Reduce Motion `동작 줄이기`, Low Power Mode `저전력 모드`, Reminders `미리 알림`, Photos `사진`, Settings `설정`, Privacy & Security `개인정보 보호 및 보안`. The calendar-name keys (`Gregorian`, `Chinese`, `Japanese`, `Buddhist`, …) are **calendar systems**, not languages — render them as `그레고리력`, `중국력`, `일본력`, `불교력`, etc. Korean translations are currently machine/AI-produced but flagged `translated`; a native review pass is still advisable.

**Polish (`pl`) specifics:** plurals need **all four** categories (`one, few, many, other`). Informal 2nd person ("ty"); "your `iPhone`" → `Twój %@`, "this `iPhone`" → `ten %@`; "quietly" → `po cichu`; "tracker" → `trackery`; "fingerprint" → `cyfrowy odcisk palca`. Apple feature names: Lockdown Mode `Tryb blokady`, Accessibility `Dostępność`, Guided Access `Dostęp nadzorowany`, Reduce Motion `Ogranicz ruch`, Low Power Mode `Tryb niskiego zużycia energii`, Reminders `Przypomnienia`, Photos `Zdjęcia`, Settings `Ustawienia`, Privacy & Security `Prywatność i ochrona`. Typography: Polish quotes are `„…"` (lower-open `U+201E`, upper-close `U+201D`). Calendar-name keys are calendar systems (`kalendarz gregoriański`, `kalendarz chiński`, …).

**Italian (`it`) specifics:** plurals need `one, other`. Informal 2nd person ("tu"); "your `iPhone`" → `il tuo %@`, "this `iPhone`" → `questo %@`; "quietly" → `silenziosamente`; "tracker" → `tracker` (invariant: `i tracker`); "fingerprint" → `impronta digitale` (`impronta digitale del dispositivo` in onboarding, to distinguish from the Touch ID biometric). Apple feature names: Lockdown Mode `Modalità di isolamento`, Accessibility `Accessibilità`, Guided Access `Accesso Guidato`, Reduce Motion `Riduci movimento`, Low Power Mode `Risparmio energetico`, Reminders `Promemoria`, Photos `Foto`, Settings `Impostazioni`, Privacy & Security `Privacy e sicurezza`. Typography: Italian guillemets `«…»` (caporali) for quoted terms. Calendar-name keys are calendar systems (`calendario gregoriano`, `calendario cinese`, …).

**Vietnamese (`vi`) specifics:** plurals need **only `other`** (no number distinction). Address the user as `bạn`; "your `iPhone`" → `%@ của bạn`, "this `iPhone`" → `%@ này`; "quietly" → `âm thầm`; "tracker" → `trình theo dõi`; "fingerprint" → `dấu vân tay kỹ thuật số` (full form in onboarding, to distinguish from the Touch ID biometric). Apple feature names: Lockdown Mode `Chế độ Khóa`, Accessibility `Trợ năng`, Guided Access `Truy cập được Hướng dẫn`, Reduce Motion `Giảm chuyển động`, Low Power Mode `Chế độ Nguồn điện Thấp`, Reminders `Nhắc nhở`, Photos `Ảnh`, Settings `Cài đặt`, Privacy & Security `Quyền riêng tư & Bảo mật`. Weekdays: `Thứ Hai` … `Chủ Nhật`. Typography: curly `"…"` quotes, no space before punctuation. Calendar-name keys are calendar systems (`lịch Gregory`, `lịch Trung Quốc`, …).

Polish, Italian, and Vietnamese translations are currently machine/AI-produced but flagged `translated`; a native review pass is still advisable.

### Translation rules

- **Preserve format specifiers exactly** (`%@`, `%lld`, …). If grammar requires reordering arguments, switch to numbered specifiers (`%1$@`, `%2$@`).
- **Never translate** code identifiers in backticks (`canOpenURL`, `WKWebView`), units (`Hz`, `µT`), or file format names (`PNG`, `HEIC`).
- **Use Apple's official localized feature names** for that locale (Lockdown Mode, Focus, Accessibility, App Tracking Transparency, Settings, Photos, Reminders, …) — verify against iOS in the target language, don't guess. Example: Lockdown Mode is 封闭模式 in zh-Hans, not 封锁模式.
- **Match Apple's address form** for each locale: informal where Apple is informal (de "du", es "tú", it "tu", pl "ty", ru «ты», uk «ти», vi "bạn"), formal where Apple is formal (fr "vous"), polite です/ます with dropped subject pronouns for ja, polite 해요체 with dropped subject pronouns for ko, masculine-singular neutral for ar.
- **"Quietly" is the thesis word** and has one canonical rendering per locale (de "unbemerkt", fr "discrètement", es "discretamente", it "silenziosamente", pl "po cichu", ru «незаметно», uk «непомітно», vi "âm thầm", ja 「ひそかに」, ko 「몰래」, ar «بصمت»). Keep it consistent.
- **Respect locale typography**: French narrow spaces before `?!:;`, full-width Japanese punctuation with no spaces around Latin tokens (「お使いのiPhoneは」), Spanish `¿…?`, Italian guillemets `«…»`, Polish `„…"`.
- Short system words may legitimately differ from a literal translation — e.g. "Done" is "OK" in French and Spanish, matching Apple. Don't "fix" these.

### Plurals

- Never write `count == 1 ? "time" : "times"` in Swift — that only works for English. Interpolate the `Int` directly (`\(count)`, which emits `%lld`) and let the catalog handle plural forms via `variations.plural` (or `substitutions` when the string has other arguments).
- Each locale declares only its CLDR plural categories: `en/de/es/fr/it/pt` use `one, other`; `pl/ru/uk` use `one, few, many, other`; `ar` uses all six; `ja/ko/vi/zh` use `other` only.
- When converting a key to plural variations, **English needs an explicit `en` localization too** — otherwise the source key serves as the only form and you get "1 signals collected".

### Keeping translations fresh

When you change or add an English source string, every other locale's entry becomes stale (`needs_review`) or missing (`new`). Use `StringCatalogRead` per locale to find these, then re-translate them and flag the change in your summary. When adding a new locale, write a per-language voice guide first (address form, the "quietly" word, Apple's localized feature names, recurring phrases, typography) derived from the voice principles above, and cover all of `Localizable.xcstrings`, `InfoPlist.xcstrings`, and `knownRegions`.
