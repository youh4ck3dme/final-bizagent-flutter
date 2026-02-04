# Ikona 512×512 px – špecifikácia a orez

## Výstup

- **Súbor:** `icon_512x512.png`
- **Rozmer:** **512 × 512 px** (presne)
- **Formát:** PNG
- **Zdroj:** splash 2048×2732 px (center crop)

## Presný orez

| Krok | Rozmer | Popis |
|------|--------|--------|
| Zdroj | 2048 × 2732 px | Splash (portrait) |
| Center crop | 2048 × 2048 px | Štvorec zo stredu: offset X=0, Y=342 px |
| Resize | **512 × 512 px** | Finálna ikona (LANCZOS ekvivalent pri sips) |

**Vzorec offsetu Y (center):**  
`Y = (2732 - 2048) / 2 = 342 px`

## Farby (z audit rámca)

- `#0B4EA2` (slovakBlue) – primárna modrá
- `#4A90E2` (blueLight) – svetlejšia modrá
- `#FFFFFF` – biela
- Červená len ako akcent (slovenská vlajka v „B“)

## Použitie

- Google Play: nahrať ako **High-resolution icon** (512×512 px).
- Android: použiť ako zdroj pre adaptívnu ikonu (pozadie + foreground).

## Poznámka

Ikona je orezaná zo splash obrazovky (geometrické „B“ + slovenská vlajka v ňom). Ak budeš potrebovať variant **iba symbol „B“ bez textu „BizAgent“**, treba zdroj pripraviť s menším vertikálnym orezom okolo loga alebo použiť samostatný asset loga.
