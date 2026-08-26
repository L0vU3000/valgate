# Bundled Font Licenses

The app's active typography is **Geist** only, registered as a real static
`.ttf` app font — matching the web app's active brand guide
(`apps/web/docs/valgate-brand-guide.md`), where Geist is the primary face for
all application UI. It is licensed under the SIL Open Font License 1.1. Its
license text is bundled alongside the fonts as an app resource
(`*-OFL.txt`) so redistribution carries the required notice, per the OFL's
own terms.

**Bricolage Grotesque** `.ttf` assets and its `*-OFL.txt` license file are
also present on disk under `Resources/Fonts/` from earlier work, but are
**inactive**: they are not listed in `UIAppFonts` (`Info.plist` /
`project.yml`), so iOS never registers them, and no code in
`DesignSystem/Typography.swift` references them. Per the web app's active
brand guide, Bricolage Grotesque is legacy and should not be introduced for
new work — these files are retained on disk (not deleted) but should not be
wired back up.

All files were pulled directly from each family's official upstream
repository — not from Google Fonts' variable-only distribution, and not from
any web/browser (`.woff`/`.woff2`) package — because iOS needs real static
`.ttf` instances registered by PostScript name, not a browser-oriented
variable font or web font format.

## Geist

- **Source:** https://github.com/vercel/geist-font (Vercel's official
  repository for the typeface)
- **Release used:** [`1.8.0`](https://github.com/vercel/geist-font/releases/tag/1.8.0)
  — `fonts/Geist/ttf/*.ttf`
- **License:** SIL Open Font License 1.1 — `Resources/Fonts/Geist-OFL.txt`
  (copied from the release's `OFL.txt`; trailing whitespace trimmed for
  `git diff --check`, text otherwise unchanged)
- **Files bundled** (PostScript names, as verified with `fontTools`):
  - `Geist-Regular.ttf` → `Geist-Regular`
  - `Geist-Medium.ttf` → `Geist-Medium`
  - `Geist-SemiBold.ttf` → `Geist-SemiBold`
  - `Geist-Bold.ttf` → `Geist-Bold`
- Only the four weights `ValgateFont.GeistWeight` actually uses are bundled
  (regular/medium/demiBold/bold map to those four files) — not the full
  17-weight family, to keep the app bundle lean.
- `ValgateFont.display()` also resolves to Geist (bold/demiBold), so all four
  files above cover every active text style — display, title, body, and
  label alike.

## Bricolage Grotesque (retained on disk, inactive)

**Not currently active.** These files are kept in the repository from
earlier work but are not registered as app fonts and not referenced by any
code — see the note at the top of this document.

- **Source:** https://github.com/ateliertriay/bricolage (the typeface
  designer's official repository; this is also the upstream Google Fonts
  packages from, per `google/fonts` `ofl/bricolagegrotesque/upstream_info.md`)
- **Commit used:** `84745e5b96261ae5f8c6c856e262fe78d1d6efdd` (the commit
  Google Fonts itself packaged) — `fonts/ttf/BricolageGrotesque-*.ttf`
- **License:** SIL Open Font License 1.1 —
  `Resources/Fonts/BricolageGrotesque-OFL.txt` (copied from the upstream
  repo's `OFL.txt`; trailing whitespace trimmed for `git diff --check`, text
  otherwise unchanged). License text is retained alongside the still-present
  `.ttf` files even though they are inactive, since the files themselves
  have not been deleted.
- **Files present but not bundled as app fonts** (PostScript names, as
  verified with `fontTools`):
  - `BricolageGrotesque-SemiBold.ttf` → `BricolageGrotesque-SemiBold`
  - `BricolageGrotesque-Bold.ttf` → `BricolageGrotesque-Bold`
- Neither `UIAppFonts` (`Info.plist` / `project.yml`) nor
  `DesignSystem/Typography.swift` references these two files or their
  PostScript names.

## Registration

Only Geist is wired up as an app font, the way the project already declares
any other app resource/config (`project.yml`, XcodeGen's source of truth for
the generated `.xcodeproj`):

- `project.yml` adds `Sources/ValgateiOS/Resources/Fonts` as a `buildPhase:
  resources` target source (so all files in that directory, including the
  inactive Bricolage `.ttf`/`OFL.txt` files, are copied into the app bundle
  as plain resources), but lists only the four Geist `.ttf` files under
  `targets.ValgateiOS.info.properties.UIAppFonts` — the array iOS actually
  reads to register fonts.
- `Sources/ValgateiOS/Info.plist` carries the same four-entry `UIAppFonts`
  array directly, since it's the tracked file XcodeGen's `info.path` points
  at.
- `DesignSystem/Typography.swift` (`ValgateFont.display`/`.sans`) references
  only the Geist PostScript names above via
  `Font.custom(_:size:relativeTo:)`, and checks `UIFont(name:size:) != nil`
  before using it — if a font somehow didn't register, text falls back to
  the equivalent system font/weight instead of silently rendering tofu.

**Known limitation:** this repository was authored in a Linux sandbox with no
Xcode/xcodegen toolchain available, so `xcodegen generate` could not be run
here to verify the four Geist files land in the generated `.xcodeproj`'s Copy
Bundle Resources phase and `UIAppFonts` resolves at runtime. Re-run `xcodegen
generate` on macOS (per `docs/MAC-STARTUP-CHECKLIST.md`) and confirm in a
simulator build before relying on the custom fonts rendering; if they don't,
`ValgateFont`'s fallback path keeps every text style legible on the
equivalent system font in the meantime.
