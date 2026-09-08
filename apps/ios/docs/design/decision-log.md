# Design Decision Log

This log tracks the evolution of the Valgate iOS visual language. Every entry should link a design decision to a specific reference, goal, or user feedback.

## Decisions

### [2026-09-07] Transition to 'Energetic Sleek'
**Decision**: Pivot from standard iOS HIG (generic lists, gray hairlines) to a high-tension, branded visual language.
**Reasoning**: 
- **Analysis**: Figma audit of 'Proposed Design' revealed a 'spreadsheet' feel that lacked focal points.
- **Reference (Soar Flight)**: Luxury aviation websites use asymmetric compositions and deep, high-contrast palettes to create a sense of authority and exclusivity.
- **Reference (IG Reels)**: Social media pacing emphasizes 'visual hooks' and dramatic scale to capture attention instantly.
**Impact**: 
- Implementation of the **Power Scale** typography (11pt $\to$ 52pt).
- Replacement of hairlines with **Physical Glass** surfaces.
- Adoption of **Electric Cobalt (#245BFF)** as the primary energy accent.
- Introduction of the `VGHeroMetric` as a mandatory screen anchor.
