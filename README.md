# Field Engineering Platform (Phase 1 & Phase 2)
### Offline-First Industrial Tablet Application with Vector Drawing Viewer & Multi-Layer Markup Engine

![Offline Tablet](https://img.shields.io/badge/Platform-Flutter_Tablet-orange.svg)
![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture_%2B_Riverpod-blue.svg)
![Storage](https://img.shields.io/badge/Offline-SQLite_%2B_Native_Storage-green.svg)
![Phase 2](https://img.shields.io/badge/Phase_2-Markup_Engine_Complete-brightgreen.svg)

---

## 🏗️ Overview

**Field Engineering** is a mission-critical, offline-first Flutter tablet platform engineered specifically for field engineers operating in remote desert, offshore, and hazardous EPC construction sites.

The primary use case is:
> An engineer pre-loads project drawing packages (P&IDs, piping isometrics, electrical single-line diagrams, structural GAs) to their Android tablet at base camp, locks their secure field session, and travels into remote desert locations with **zero internet connectivity**. All drawing inspection, file imports, calculation tools, multi-layer vector annotations, and daily field inspection reporting operate 100% locally.

---

## 📐 Layered Drawing Architecture (Non-Destructive Annotation)

The original engineering PDF **always remains 100% untouched and pristine**. Annotations and site intelligence are rendered and saved as discrete vector layers:

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

### Sub-Pixel Page Normalized Coordinates
All annotations store geometric points in normalized page space `Point2D(x/pageWidth, y/pageHeight)` ($x \in [0, 1], y \in [0, 1]$):
- **Anchorage**: Redlines and revision clouds stay anchored to the exact valve nozzles, piping tags, and weld numbers regardless of zoom level (0.5x to 10.0x).
- **Orientation Independent**: Rotating tablet between Landscape and Portrait retains exact positions.
- **Persistence**: SQLite stores vector math in JSON geometry columns, allowing reopening and exporting without coordinate drift.

---

## 🎨 Professional Markup Tools Implemented

- ✏️ **Freehand Pen**: Smooth path interpolation with customizable stroke width.
- 🖌️ **Highlighter**: Semi-transparent wide stroke with blend mode.
- 📏 **Line & Arrow Leader**: Directional arrowheads for technical callouts.
- ⬜ **Rectangle & ⭕ Circle / Ellipse**: Box enclosures with optional fill color.
- 📐 **Polygon**: Multi-vertex enclosure.
- ☁️ **Revision Cloud**: Authentic CAD standard circular scallop curves along boundaries.
- 🔤 **Text Callout**: Scalable text box with background pill and font sizing.
- 📐 **Measurement Ruler**: Calibrated dimension line with dual perpendicular witness marks and real-time mm readout.
- ⚠️ **Punchlist Issue Pin**: Location pins for quality non-conformances with tag IDs (`PNC-01`).
- 📷 **Site Photo Pin**: Pinned camera callouts linked to local tablet storage.
- 🛡️ **QA/QC Certified Stamp**: `APPROVED FOR CONSTRUCTION`, `AS-BUILT`, `HOLD FOR CLARIFICATION`.
- 🧽 **Eraser**: Hit-test object eraser.
- ↩️ **Undo / ↪️ Redo Stack**: Multi-level state history.
- 📋 **Copy, Paste & Duplicate**: Fast annotation cloning across sheets.
- 💾 **Debounced SQLite Autosave**: Automatically persists markups locally on edit.

### Default Engineering Palette
- **Safety Red** (`#D32F2F`)
- **Field Green** (`#2E7D32`)
- **P&ID Blue** (`#1565C0`)
- **Warning Yellow** (`#FBC02D`)
- **Instrument Purple** (`#7B1FA2`)
- **Carbon Black** (`#212121`)
- **Hazard Orange** (`#FF6F00`)
- **Process Cyan** (`#00838F`)

---

## 🏛️ Project Directory Structure

```
lib/
├── main.dart                                # Application entry point & SQLite FFI initialization
├── core/
│   ├── database/
│   │   ├── app_database.dart                # Local SQLite singleton & table initialization
│   │   └── database_tables.dart             # Schema definitions (projects, drawings, markups, queue)
│   ├── storage/
│   │   ├── offline_storage_manager.dart     # Dedicated file manager for PDFs, thumbs, photos, reports
│   │   └── storage_models.dart              # Storage models, categories & byte formatters
│   ├── offline/
│   │   ├── network_status_state.dart        # ONLINE / OFFLINE / SYNC PENDING state model
│   │   └── offline_sync_manager.dart        # Mutation audit queue & sync notifier
│   ├── theme/
│   │   ├── app_theme.dart                   # Material 3 Industrial Dark & Desert Sunlight themes
│   │   └── color_palette.dart               # Engineering color palette
│   ├── routing/
│   │   └── app_router.dart                  # GoRouter shell & deep link navigation
│   ├── utils/
│   │   ├── drawing_generator.dart           # Offline vector PDF engine for A3 blueprints & title blocks
│   │   ├── sample_data_seeder.dart          # Seed demo EPC packages with initial markups
│   │   └── formatters.dart                  # Date & byte formatters
│   ├── errors/
│   │   ├── app_exceptions.dart              # Custom domain exceptions
│   │   └── failures.dart                    # Failure abstractions
│   └── providers/
│       └── core_providers.dart              # Riverpod dependency injection definitions
├── features/
│   ├── auth/                                # 1. Splash Screen & 2. 4-Digit PIN Lock Screen
│   ├── dashboard/                           # 3. Field Dashboard with KPIs & Desert Readiness Banner
│   ├── projects/                            # 4. Project List & 5. Project Details (Master-Detail)
│   ├── drawings/                            # 6. Drawing List & 7. Drawing Details & Markup Studio
│   │   ├── domain/models/                   # Drawing, DrawingType, Markup, DrawingLayer
│   │   ├── domain/repositories/             # DrawingsRepository, MarkupsRepository
│   │   ├── data/datasources/                # DrawingsLocalDataSource, MarkupsLocalDataSource
│   │   ├── data/repositories/               # DrawingsRepositoryImpl, MarkupsRepositoryImpl
│   │   └── presentation/
│   │       ├── controllers/                 # drawings_controller.dart, markup_controller.dart
│   │       ├── widgets/
│   │       │   ├── drawing_canvas_view.dart          # Interactive zoom/pan viewport
│   │       │   ├── drawing_markup_painter.dart       # CustomPainter for vector clouds & shapes
│   │       │   ├── markup_toolbar.dart               # Floating engineering toolbar
│   │       │   ├── layer_management_panel.dart       # Multi-layer visibility toggles
│   │       │   ├── thumbnail_navigation_drawer.dart  # Multi-sheet thumbnail selector
│   │       │   ├── drawing_card.dart                 # Tablet drawing card
│   │       │   └── drawing_import_modal.dart         # Device PDF importer
│   │       └── screens/
│   │           ├── drawing_list_screen.dart          # Drawing directory & discipline filters
│   │           └── drawing_details_screen.dart       # Fullscreen vector drawing workspace
│   ├── offline_manager/                     # 8. Download Manager & 9. Storage & Cache Inspector
│   ├── settings/                            # 10. Engineer Profile, PIN Security & Theme Configuration
│   ├── calculations/                        # ASME B31.3 Pipe Wall Thickness & Hydrotest Calculators
│   ├── reports/                             # Offline Daily Inspection Report Builder & PDF Exporter
│   ├── issues/                              # Phase 2 domain structure
│   ├── inspections/                         # Phase 2 domain structure
│   └── equipment/                           # Phase 2 domain structure
└── shared/
    └── widgets/                             # Tablet scaffold, badges, search fields, loading/error states
```

---

## 🚀 How to Run Locally

1. Open a terminal in the project directory:
   ```bash
   cd C:\Users\Yadhukrishna\.gemini\antigravity-ide\scratch\field_engineering
   ```
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Run on your desktop or connected tablet:
   ```bash
   flutter run -d windows    # Windows Desktop
   flutter run -d android    # Android Tablet
   ```

*Default PIN to unlock session:* **`1234`**
