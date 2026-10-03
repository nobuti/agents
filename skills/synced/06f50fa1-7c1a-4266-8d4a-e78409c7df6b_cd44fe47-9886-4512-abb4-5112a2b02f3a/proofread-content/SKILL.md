---
name: proofread-content
description: >
  Proofread and copyedit Technosylva content: US English, house style, product names, consistency,
  figure and table numbering, and cross-reference checks.
  TRIGGER: invoke this skill automatically whenever the user asks to proofread, copyedit, review,
  or check any document or passage of text — even without naming this skill explicitly.
  Trigger phrases include: "proofread", "copyedit", "review this document", "check my writing",
  "review for errors", "give me an issue list", "editorial review".
  Do NOT answer proofread requests from base behavior — always load this skill first.
license: Proprietary
compatibility: requires mcp__claude_ai_Notion
metadata:
  version: 1.1.0
  author: Fern Braun
---

# Proofread Content

## Purpose

Use this skill to proofread or copyedit Technosylva content: help center articles, release notes, whitepapers, internal communications, and formal technical reports such as validation, verification, and qualification reports. This is a light-touch editorial pass, not a technical fact-check or a full rewrite.

Invoke whenever the user asks to proofread, copyedit, review, edit, or check a document or passage — including implicit requests like "check my writing" or "give me an issue list." Do not answer these requests from base behavior.

## When to invoke

Invoke this skill (via the Skill tool with `skill: "proofread-content"`) whenever:
- The user asks to proofread, copyedit, review, edit, or check a document or passage.
- The user asks for an issue list, editorial review, or grammar check.
- The user shares a document and asks what needs to be fixed.

Do not answer these requests from base behavior. Always load this skill first.

## Prerequisites

- Skill `pdf` — required when the source document is a PDF file.
- Skill `docx` — required when the source document is a Word (.docx) file.

## Context

### House rules

#### Voice and grammar
- Prefer active voice and present tense. Use the imperative for instructions ("Select Run," not "the Run button should be selected").
- Use one term for one concept. Flag synonym variation for a defined term.
- Keep list items and parallel headings grammatically parallel.

#### Capitalization
- Use title case for headings, and for figure and table titles. Flag headings in sentence case or in inconsistent case.
- Capitalize product names, UI labels, and metric names as branded. Do not capitalize generic nouns (map, layer, report) for emphasis.

#### US English
- Use US English: color, organize, center, catalog, behavior, analyze, modeling, labeled.
- Exception: keep the official spelling of proper nouns, including organizations, places, and products, even when it is not US spelling. Example: European Centre for Medium-Range Weather Forecasts (ECMWF) keeps "Centre." Do not "correct" these.
- Agency names take their official styling: CAL FIRE (all caps) and BCWS (British Columbia Wildfire Service). Flag variants such as Cal Fire or CalFire.

#### Punctuation
- Em dashes: do not use them. Replace with a colon, comma, or period, or rework the sentence. Flag every em dash. The character may be an en dash rather than a true em dash, so check for both.
- Do not use emojis, including check marks or similar symbols.
- Serial (Oxford) comma: use it in lists of three or more items.
- Hyphenation: hyphenate compound modifiers before a noun (real-time conditions, high-resolution model, decision-making support). Keep established hyphenated terms consistent.
- Use a single space after periods.
- Ignore a period at the end of a heading unless there is a space between the text and the period.
- Quotation marks: place commas and periods inside the quotation marks (US style). Use one quote style, curly or straight, consistently; do not mix.
- Prefer "for example" and "that is" over "e.g." and "i.e." in body text. Write "and," not "&." Do not use "/" to mean "or"; write the word.

#### Dates, numbers, and time
- Dates: US format, month name then day and year: February 17, 2026. Flag any other format. Avoid all-numeric dates in prose.
- Numbers: spell out zero through nine in prose; use numerals for 10 and above. Use numerals with units, percentages, and measurements, and in tables. Spell out a number that begins a sentence, or reword. Use numerals for both values in a range (for example, 5 to 12).
- Use a comma as the thousands separator in numbers of four or more digits: 1,000; 10,500.
- Use a leading zero before a decimal point: 0.5, not .5.
- Time: use 24-hour format and always include the time zone (for example, 14:00 PST). Flag 12-hour times (2:00 PM) and times missing a time zone.

#### Units
- Place a space between the value and the unit: 20 mph, 30 km, 12 m/s. Flag a missing space. Exceptions: no space before a percent sign (20%) or before a degree symbol for temperature (45°F).
- Use metric or US customary units according to the customer or region. Keep the unit system consistent within a single deliverable.
- Unit symbols are case-sensitive: km, kW, m, s, ha, and L for liter. Flag miscasing such as "Km" or "KW."
- Use a non-breaking space between a value and its unit, and between "Figure" or "Table" and its number, so they do not split across lines.

#### Acronyms
- Spell out each acronym in full on first use in a document, with the acronym in parentheses: Rate of Spread (ROS). Use the acronym alone after that.
- Flag the first appearance of any acronym that was not spelled out.
- Do not re-expand an acronym after its first use. This rule applies in all languages, including Spanish-language documents. Flag any instance where a previously expanded acronym is spelled out in full again — even in a different paragraph or sentence.
- Use the canonical full forms in the Acronym reference below. The Glossary of Terms and Metrics (https://helpcenter.technosylva.com/metrics) is the source of truth.
- Preserve intentional mixed-case acronyms exactly: dBLF (lowercase "d") and OpCo.
- TL is used for two terms: Transmission Line (Utilities) and timber litter (Scott and Burgan fuel model set). Rely on the spell-out-on-first-use rule to disambiguate. If a single document legitimately uses TL for both meanings, expand each meaning in full on its own first use — that is two distinct first uses, not a re-expansion of the same acronym, so do not flag either one.

#### Product names
Write product names exactly as branded. Do not normalize the capitalization. Flag every deviation.
- Wildfire Planning (FireSight): Wildfire Planning is the primary name. Put FireSight in parentheses on first use, then use Wildfire Planning alone.
- Use a product name directly, without an article or an "application" suffix: "in Wildfire Planning," not "in the Wildfire Planning application."
- Wildfire Analyst (WFA), WFA Desktop, WFA Mobile, WFA FireCast, WFA FireRisk — "Wildfire Analyst" alone is correct; only flag when the variant name is wrong, e.g. "Wildfire Analyst desktop" (lowercase d + word "desktop") should be "WFA Desktop"
- FireSim
- fiResponse (lowercase "fi," capital "R") — flag "Firesponse", "FiResponse", "firesponse", "FireResponse"
- Tactical Analyst (TA), TA Mobile (Tactical Analyst Mobile) — flag "Tactical analyst mobile" (wrong casing)
- Data Manager, Colorado Forest Atlas, Wildfire Operations
- Activity Tracker: branded Cal MAPPER for CAL FIRE customers. Use Cal MAPPER for those customers and Activity Tracker otherwise. — flag "Cal mapper", "Cal Mapper", "CAL MAPPER" (only correct for the all-caps agency, not the product)
- Tool and model names keep internal capitals: WindNinja — do not flag WindNinja.

#### Terminology
- Keep the distinction between fire danger and fire risk. Fire danger is the potential for ignition, spread, and control difficulty from conditions. Fire risk incorporates the consequences to people, structures, and values. They are not interchangeable.

### Accessibility
- Use descriptive link text that makes sense out of context. Flag "click here," "read more," and bare URLs used as link text.
- Every figure or image needs alternative text. Flag missing alt text.

### Non-native English patterns
Many drafts are written by native Spanish speakers. Watch for and flag:
- Missing or misused articles (a, an, the).
- Preposition errors ("assist to the meeting" → "attend the meeting").
- Subject-verb agreement slips.
- False cognates — English words used with their Spanish meaning. Only flag when the word is clearly misused; do not flag correct English usage:
  - "actual" meaning "current" or "present-day" (Spanish: actual). Correct English: "actual" = real/genuine. Tell: "actual" immediately before a noun that is then anchored to a specific moment — "as mapped," "as of [time]," "as reported," "as observed" — signals the Spanish sense. Flag: "The actual fire perimeter as mapped by the infrared flight covers..." (→ "The current fire perimeter..."). Do NOT flag: "the actual cause of the ignition" (no time-anchoring phrase follows).
  - "assist to [event]" meaning "attend [event]" (Spanish: asistir a). Flag: "will assist to the meeting." Do NOT flag: "will assist the crew."
  - "realize [a task/run/simulation]" meaning "carry out" or "conduct" (Spanish: realizar). Flag: "will realize a simulation run." Do NOT flag: "we realize the importance of."
  - "control" meaning "check" or "monitor" (Spanish: controlar). Flag only when context makes the Spanish sense clear.
- Sentence structures calqued from Spanish (overly long embedded clauses, passive-heavy constructions).

### Style
- Enforce documentation style: clear, concise, and non-repetitive.
- Flag passages that make the same point more than once.
- Flag phrasing that reads as AI-generated, such as "Why This Matters" headers and "it is not just X, it is Y" constructions.

### Structure, figures, and references
Applies mainly to technical reports and any document with figures, tables, or numbered references.

- Figure and table numbering: confirm figures and tables are each numbered sequentially. Flag missing numbers, duplicated numbers, and gaps.
- Cross-references: flag stale, broken, or mismatched references to figures, tables, sections, or page numbers.
- Captions: flag duplicated captions and captions that do not match the figure or table they label.
- Late-edit artifacts: flag placeholder text, broken layout, orphaned headings, and content that no longer matches surrounding references. These signal a rushed final edit.
- Valid-word typos: flag correctly spelled words used in the wrong place (for example, "form" for "from," "mange" for "manage") that a spell checker will not catch.

### Acronym reference

Canonical full forms. Verify against the glossary when terms are added or changed.

Fire Danger

| Acronym | Full term |
|---|---|
| BI | Burning Index |
| EAA | Extended Attack Assessment Index |
| ERC | Energy Release Component |
| FBI | Fire Behavior Index |
| FL | Flame Length |
| FLI | Fireline Intensity |
| FPI | Fire Potential Index |
| FPIC | Fire Potential Index Composite |
| FPWI | Fire Potential Wind Index |
| HFI | Head Fire Intensity |
| IAA | Initial Attack Assessment |
| NFDRS16 | National Fire Danger Rating System, Version 2016 |
| POF | Probability of Failure |
| POI | Probability of Ignition |
| ROS | Rate of Spread |
| SC | Spread Component |
| SFDI | Severe Fire Danger Index |
| TDI | Terrain Difficulty Index |

Fire Risk

| Acronym | Full term |
|---|---|
| BLF | Building Loss Factor Index |
| dBLF | Dynamic Building Loss Factor |
| UC | Urban Conflagration |

Fuels

| Acronym | Full term |
|---|---|
| DFMC | Dead Fuel Moisture Content |
| LFMC | Live Fuel Moisture Content |
| WUI | Wildland-Urban Interface |

Utilities

| Acronym | Full term |
|---|---|
| DL | Distribution Line |
| EPSS | Enhanced Powerline Safety Settings |
| OpCo | Operating Company |
| PSPS | Public Safety Power Shutoff |
| TF | Transformers |
| TL | Transmission Line |
| ZOP | Zone of Protection |

Canadian

| Acronym | Full term |
|---|---|
| BUI | Buildup Index |
| CFFDRS | Canadian Forest Fire Danger Rating System |
| DC | Drought Code |
| DMC | Duff Moisture Code |
| FBP | Fire Behavior Prediction |
| FFMC | Fine Fuel Moisture Code |
| FMC | Foliar Moisture Content |
| FWI | Fire Weather Index |
| HFFMC | Hourly Fine Fuel Moisture Code |
| ISI | Initial Spread Index |

Weather

| Acronym | Full term |
|---|---|
| ASOS | Automated Surface Observation Station |
| ECMWF | European Centre for Medium-Range Weather Forecasts |
| EDDI | Evaporative Demand Drought Index |
| GFS | Global Forecast System |
| HRRR | High-Resolution Rapid Refresh |
| KBDI | Keetch-Byram Drought Index |
| NWS | National Weather Service |
| RH | Relative Humidity |
| WRF | Weather Research and Forecasting |

Reference

| Acronym | Full term |
|---|---|
| MODIS | Moderate Resolution Imaging Spectroradiometer |
| VIIRS | Visible Infrared Imaging Radiometer Suite |

## Steps

1. Confirm which output the user wants if it is not clear (see Output section).
2. If the document is a file (PDF, DOCX, or similar) and its content is not already in context, read it in full first, using the `pdf` or `docx` skill as appropriate. Do not skim; cover pages, headers, footers, captions, and back matter matter.
3. First pass: read for overall structure, including section order, heading hierarchy, figure and table numbering, and the terminology used for key entities (company names, product names, abbreviations).
4. Second pass: read section by section, capturing issues as you go against all house rules in Context.
5. Give high-visibility sections extra scrutiny: cover and title pages, executive summaries, section headings, captions, conclusions, and headers and footers.
6. Run global consistency checks across the whole document, not line by line. Group findings by pattern so each is resolved once:
   - Capitalization: the same term, heading, or UI label capitalized inconsistently.
   - Hyphenation: the same compound written hyphenated, open, and closed in different places.
   - Spacing and punctuation: inconsistent spacing, double spaces, and inconsistent punctuation patterns.
   - Dates: flag any date not in US month-day-year format (e.g. February 17, 2026). Flag all-numeric dates such as 17/02/2026 or 2026-02-17.
   - Numbers and units: flag any missing space between a value and its unit (e.g. "28Km/h" → "28 km/h"). Flag incorrect unit symbol casing (Km → km, KW → kW). Flag missing leading zero before a decimal point (.8% → 0.8%).
   - Time format: flag any 12-hour time (e.g. "2:00 PM") — use 24-hour format (14:00). Flag times missing a timezone.
   - Unit system: metric and US customary units mixed within a single deliverable.
   - Quotation style: straight and curly quotes mixed within the document.
   - Terminology: the same concept referred to by more than one term.
   - False cognates: scan every sentence for the specific patterns listed in Non-native English patterns. Check each use of "actual," "assist to," and "realize" against the definitions above.
7. Do not change technical meaning. Leave product names, UI labels, code, command syntax, and defined terms as written. When a correction could alter meaning, flag it rather than apply it.

## Output

Choose the output mode based on what the user requests:

1. **Corrected text**: return the full document with corrections applied.
2. **Issue list**: return a list of issues and suggested fixes, leaving the original text unchanged.
3. **Both**: the corrected text followed by a summary of what changed.

Default to an issue list for short documents and corrected text when the user asks for a clean version.

When returning an issue list, group findings by category and separate definite errors from optional style suggestions. Label each finding as **Error**, **Likely issue**, or **Style suggestion**. For each issue, give:
- Location (including page number when the source has pages)
- Original text
- Suggested correction using the lightest-touch fix
- Brief reason

List a recurring pattern once with all of its locations rather than repeating the same note. Lead with the top-priority fixes: high-visibility and definite errors first.

## Guardrails

### Editorial scope
- Preserve the document's existing style, tone, voice, and level of formality. Do not rewrite acceptable text to make it sound more polished or more concise.
- Prefer minimal corrections that improve correctness, clarity, consistency, or readability.
- Do not do a full rewrite, and do not raise technical correctness unless it is a clear internal inconsistency.
- Prefer a short list of strong findings over a long list of weak nitpicks. Do not pad the review.
- This is a light-touch editorial pass only, not a technical fact-check.

### Security and confidentiality
- Do not process documents containing credentials, API keys, or tokens. Stop and ask the user to redact them first.
- Do not publish, share, or send corrected output to any external system. Return it only to the user in this session.

## Evals

Automated test suite using `claude plugin eval`. See `evals/README.md` for the full
strategy write-up (grader types, why some cases use `regex` instead of `llm`, and how
to maintain the suite). Run from the skill root directory.

```bash
# Full suite (12 cases)
claude plugin eval .

# Fast model for iteration
claude plugin eval --ablation none --model claude-haiku-4-5-20251001

# Smoke only (quick validation)
claude plugin eval . --tag smoke

# Skill auto-invocation tests only
claude plugin eval . --tag skill-invocation

# Ablation: with skill vs. without (useful for invocation tests)
claude plugin eval . --tag skill-invocation --ablation with-without

# CI
claude plugin eval . --trust-plugin --json results.json --threshold 0.85 --max-cost-usd 5.00
```

### Cases

| Case | Tags | Lang | Verifies | Graders |
|---|---|---|---|---|
| `01-em-dash` | smoke, punctuation | EN | Detects em dashes and en dashes | llm |
| `01-em-dash-es` | smoke, punctuation, spanish | ES | Same rule applies in a Spanish document | llm |
| `02-product-names` | smoke, product-names | EN | Detects 5 product name casing errors | regex (w2) + llm (w1) |
| `02-product-names-es` | smoke, product-names, spanish | ES | Same rules apply in a Spanish document | regex (w2) + llm (w1) |
| `03-acronyms` | smoke, acronyms | EN | Detects unexpanded acronyms + re-expansion | llm |
| `03-acronyms-es` | smoke, acronyms, spanish | ES | Same rules apply in a Spanish document | llm |
| `04-numbers-units` | smoke, numbers | EN | Detects unit, date, and time formatting errors | regex (w2) + llm (w1) |
| `05-false-cognates` | smoke, false-cognates | EN | Detects false cognates from Spanish | llm |
| `06-clean` | smoke, regression | EN | No false positives on a correct document | regex only |
| `07-fires-on-explicit-request` | smoke, skill-invocation | EN | Skill fires on an explicit proofread request | tool_used + llm |
| `08-fires-on-implicit-request` | skill-invocation, regression | EN | Skill fires on an implicit writing-check request | tool_used + llm |
| `09-does-not-fire-on-unrelated` | skill-invocation, regression | EN | Skill does NOT fire on unrelated questions | tool_used |

Run only Spanish cases: `claude plugin eval . --tag spanish`

### Pass criteria

- Cases 01, 03, 05: LLM judge confirms all injected errors were detected (context-dependent judgment; no reliable string signal).
- Cases 02, 04: a `regex` grader checks the response literally contains the corrected forms (weight 2, dominant, zero LLM cost signal); the `llm` grader (weight 1) is a secondary check for completeness and false positives.
- Case 06: `regex` grader with `match: not_contains` checks the response does not use the skill's own `**Error**`/`**Likely issue**` labels — fully replaces the LLM judge since the skill's Output section enforces this labeling convention.
- Cases 07–08: `tool_used` grader confirms `proofread-content` was invoked; LLM judge confirms domain-specific errors were caught.
- Case 09: `tool_used` grader confirms the skill was NOT invoked; response answers the question correctly.

Note: `claude plugin eval` runs all graders for a case independently and averages their (weighted) scores — there is no short-circuiting, so a passing regex grader does not skip the LLM grader. The `weight` field only shifts how much each grader's pass/fail counts toward the case score, not execution order or cost.

## Knowledge Base

| Resource | MCP | ID or How to Find | Description |
|---|---|---|---|
| Technosylva Technical Writing Style Guide | mcp__claude_ai_Notion | `3ddc71b58aed8036b4dee0097d144f9e` | Source of truth for house style, product names, and acronyms |
| Glossary of Terms and Metrics | ask | `https://helpcenter.technosylva.com/metrics` | Canonical acronym full forms |
