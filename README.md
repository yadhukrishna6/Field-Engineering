# Field Engineering Platform (Phases 1, 2, 3 & 4)
### Complete Offline-First Industrial Field Engineering Tablet Application

![Offline Tablet](https://img.shields.io/badge/Platform-Flutter_Tablet-orange.svg)
![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture_%2B_Riverpod-blue.svg)
![Storage](https://img.shields.io/badge/Offline-SQLite_%2B_Native_Storage-green.svg)
![Phase 4](https://img.shields.io/badge/Phase_4-Complete_Field_Tool_Complete-brightgreen.svg)
![Tests](https://img.shields.io/badge/Tests-42_Passing-success.svg)

---

## 🏗️ Overview

**Field Engineering** is a mission-critical, offline-first Flutter tablet platform engineered specifically for EPC construction, piping, QA/QC inspection, rotating equipment, and plant commissioning engineers operating in remote desert, offshore, and hazardous site locations with **zero internet connectivity**.

An engineer pre-loads project drawing packages (P&IDs, piping isometrics, electrical single-line diagrams, structural GAs) to their Android tablet at base camp, locks their secure field session, and travels into remote desert locations. All drawing inspections, calibrated measurements, punch lists, photo attachments, voice memos, GPS fixes, inspection checklists, and equipment registries operate 100% locally.

---

## ⚡ Phase 4: Complete Field Engineering Capabilities

### PART 1 & PART 6 — FIELD ISSUES & PUNCH LIST ENGINE
- **Drawing Pinning**: Tap any location on a drawing sheet to create and anchor an issue pin in sub-pixel normalized coordinates.
- **Comprehensive Fields**:
  - `id`, `projectId`, `drawingId`, `pageNumber`, `position (X, Y)`
  - `title`, `description`, `assignedTo`, `createdBy`, `dueDate`
  - **8 Categories**: `Piping`, `Mechanical`, `Electrical`, `Civil`, `Structural`, `Instrumentation`, `Safety`, `Other`
  - **4 Priorities**: `Low`, `Medium`, `High`, `Critical`
  - **Lifecycle Statuses**: `Open` ➔ `In Progress` ➔ `Resolved` ➔ `Verified` ➔ `Closed`
- **PDF Punch List Log**: Offline export of official engineering punch list tables with status counters and GPS coordinates.

### PART 2 — PHOTOS & MEDIA ATTACHMENTS
- Take site photos or select from device gallery.
- Attach photos to:
  - Issues and punch pins
  - Drawing locations (photo pins)
  - Field inspection checklists
  - Equipment master records
- Full-screen high-resolution viewer with zoom, GPS telemetry overlay, and file size metrics.
- 100% offline file storage.

### PART 3 — OFFLINE FIELD GPS ENGINE
- Capture high-precision field GPS telemetry: `latitude`, `longitude`, `accuracy`, and `timestamp`.
- Coordinate Formatting:
  - Decimal Degrees (e.g. `25.432100° N, 49.314200° E`)
  - Degrees Minutes Seconds (DMS)
  - Universal Transverse Mercator (UTM Zone & Easting/Northing)
- Preset oilfield & refinery coordinates (Ghawar Field, Jubail Industrial, Permian Basin, Ras Laffan LNG).
- Optional and non-intrusive for drawing markups.

### PART 4 — VOICE NOTES ENGINE
- Hands-free audio recording for field engineers wearing PPE.
- Visual audio waveform and live duration timer.
- Offline audio playback tile with progress bar, duration counter, and deletion.
- Attach audio memos directly to issues, drawing pins, and inspection audits.

### PART 5 — CONFIGURABLE INSPECTION CHECKLISTS
- Configurable checklist templates:
  - **Piping Inspection (10 Standard Items)**:
    1. Pipe installed according to drawing
    2. Correct diameter
    3. Correct material
    4. Flange installed
    5. Valve installed
    6. Support installed
    7. Welding completed
    8. Insulation completed
    9. Painting completed
    10. Hydro test completed
  - **Mechanical / Rotary Equipment QC (9 Items)**
  - **Electrical & Power Quality Audit (7 Items)**
  - **Civil & Structural QC (7 Items)**
  - **HSE & Field Safety Inspection (7 Items)**
- Per-item evaluation: **`PASS`**, **`FAIL`**, **`N/A`**, **`PENDING`**.
- Per-item field comments and photo attachments.
- **1-Tap Fail-to-Punchlist Conversion**: Automatically spawn high-priority punch items from failed checklist steps.
- **Dual Digital Signatures**: Stylus/finger signature pads for **QC Inspector** and **Client / Owner Representative**.
- **Official Field Inspection Certificate**: Instant offline PDF certificate generation with metadata, checklist table, and embedded digital signatures.

### PART 7 — EQUIPMENT MASTER REGISTRY
- Comprehensive equipment asset records:
  - `Equipment Number` (e.g., `EQ-1004`)
  - `Tag Number` (e.g., `P-101A`, `V-204`, `E-301`)
  - `Equipment Name` (e.g., Crude Feed Centrifugal Pump)
  - `Equipment Type` (Pump, Vessel, Exchanger, Compressor, Tank, Valve, Transformer, Turbine)
  - `Site Location / Plot Area`
  - `Linked P&ID / Drawing Sheet`
  - `Engineering Notes & Specifications`
  - `Operating Status` (Operational, Under Maintenance, Standby, Decommissioned)
  - `Photos & GPS Fix`
- Search and filter by tag number, type, and location.

---

## 📐 Non-Destructive Multi-Layer Drawing Architecture

The original engineering blueprint PDF is **never modified**. The viewer uses a 7-layer composited canvas:

```
┌────────────────────────────────────────────────────────┐
│  Layer 7: QA/QC Inspection Layer (Certified Stamps)    │
├────────────────────────────────────────────────────────┤
│  Layer 6: Photo Layer (Pinned Field Camera Callouts)   │
├────────────────────────────────────────────────────────┤
│  Layer 5: Issue Layer (Punchlist Action Pins)          │
├────────────────────────────────────────────────────────┤
│  Layer 4: Measurement Layer (ASME Dimension Rulers)    │
├────────────────────────────────────────────────────────┤
│  Layer 3: Markup Layer (Clouds, Redlines, Text, Pens)  │
├────────────────────────────────────────────────────────┤
│  Layer 2: Previous Revision Comparison Overlay         │
├────────────────────────────────────────────────────────┤
│  Layer 1: Original Engineering Blueprint (Vector PDF)  │
└────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Architecture (SQLite Schema Version 3)

| Table | Description |
|---|---|
| `projects` | Master project packages, client names, site locations, status |
| `drawings` | Vector PDF blueprints, sheet revisions, page count, local paths |
| `markups` | Layered vector annotations (pens, clouds, arrows, text, stamps) |
| `calibrations` | 2-point scale calibrations with real engineering units (mm, cm, m, inch, ft) |
| `measurements` | 8 measurement types (distance, polyline, area, angle, radius, diameter, count, perimeter) |
| `takeoff_items` | Material Takeoff & Bill of Materials (MTO / BOM) entries |
| `saved_calculations` | Engineering calculation sheets (ASME B31.3 wall thickness, hydrotest, torque) |
| `issues` | Field issues, punch pins, categories, priorities, lifecycle states |
| `photos` | Offline photo attachments with GPS telemetry and foreign keys |
| `voice_notes` | Offline audio memos with duration and drawing attachments |
| `inspections` | Inspection header, template type, status, dual signature paths |
| `inspection_items` | Checklist items with PASS/FAIL/NA/PENDING, comments, photo links |
| `equipment` | Equipment master registry with tag numbers and P&ID links |

---

## 🧪 Testing & Verification

Run the complete test suite:

```bash
flutter test
```

### Test Coverage (42 Tests):
- **Part 1 & 6**: Issue creation, categories, priorities, punch list lifecycle transitions, SQLite CRUD.
- **Part 2 & 3**: Photo attachments, offline GPS capture, DMS formatting, UTM zone conversion.
- **Part 4**: Voice recording duration formatting, offline audio metadata, drawing pin links.
- **Part 5**: 10-item standard Piping inspection checklist, PASS/FAIL/NA/PENDING evaluation, failure-to-punchlist conversion, signature capture, completion percentage.
- **Part 7**: Equipment master registry creation, tag lookup, drawing links.
- **Part 8**: **100% Offline Field Verification** — complete end-to-end field inspection and punch pin workflow verified without network access.

---

## 🚀 Running Locally

```bash
flutter pub get
flutter run -d windows # or android tablet
```
