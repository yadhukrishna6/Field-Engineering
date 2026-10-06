# Digital Drawing Markup Platform (Flutter + Quarkus)

A streamlined, digital markup tool designed for field engineers to overlay hand-drawn annotations and clean typed text labels in **one uniform bundled engineering font** onto technical drawings (PDF / PNG / JPG), isometric piping layouts, and P&IDs.

---

## 🏗️ Architecture & Technologies

- **Frontend**: Flutter (stable), Riverpod State Management, `InteractiveViewer` with hardware-accelerated Bezier canvas rendering, SQLite offline-first sync cache, PDF/PNG vector export engine (`pdf`, `printing`).
- **Backend**: Quarkus 3.8.3 (Java 17+), RESTEasy Reactive, Hibernate ORM with Panache, PostgreSQL / H2 in-memory test DB, Flyway migrations, SmallRye OpenAPI & Swagger UI.

---

## 🚀 Features (Phase 1 & Phase 2 Complete)

1. **Drawing Upload & Multi-Page Viewer**:
   - Accepts PDF, PNG, JPG files via file picker, photo library, or camera.
   - Per-page navigation (e.g. `Sheet 1 of 3`) with zoom, pan, and double-tap fit.
2. **Smooth Pen Tool**:
   - Catmull-Rom spline interpolation converted to cubic Beziers.
   - Ramer-Douglas-Peucker (RDP) decimation for low payload size and 60 FPS drawing.
   - 3 stroke widths (Thin 2px, Medium 4px, Thick 8px) and 4 preset colors (Safety Red, Field Green, P&ID Blue, Hazard Orange).
   - Stylus vs. Finger drawing toggle.
3. **Typed Text Label Tool**:
   - Tap canvas to place text label with single uniform engineering font (`AppTypography.engineeringFontFamily = 'EngineeringFont'`).
   - S/M/L preset sizes (11pt, 14pt, 18pt).
   - Opaque white background box with solid colored border to guarantee readability over technical drawing lines.
   - Tap to select, drag to reposition, and delete handle.
4. **Whole Item Eraser**:
   - Tap or swipe across any stroke or text label to delete the whole item cleanly.
5. **30-Step Undo / Redo Stack**:
   - Reverts and restores both vector strokes and text labels.
6. **Autosave & Persistence**:
   - Debounced 600ms autosave to local SQLite and Quarkus REST API.
   - Optimistic concurrency version check (`409 Conflict` on stale version).
7. **Client-Ready Multi-Page Vector PDF Export Engine**:
   - Burns vector paths, white-boxed engineering text labels, title blocks, and sheet numbers into flattened vector PDFs.

---

## 🔌 Quarkus REST API Endpoints & `curl` Examples

### 1. Upload a New Engineering Drawing
```bash
curl -X POST "http://localhost:8080/api/v1/drawings" \
  -F "file=@sample_pid.pdf;type=application/pdf" \
  -F "name=Unit 102 High-Pressure Steam P&ID"
```

### 2. List All Uploaded Drawings
```bash
curl -X GET "http://localhost:8080/api/v1/drawings" \
  -H "Accept: application/json"
```

### 3. Get Drawing Metadata by ID
```bash
curl -X GET "http://localhost:8080/api/v1/drawings/dwg-1790800000" \
  -H "Accept: application/json"
```

### 4. Download Drawing Binary File
```bash
curl -X GET "http://localhost:8080/api/v1/drawings/dwg-1790800000/file" \
  --output downloaded_drawing.pdf
```

### 5. Fetch Page Markup (Strokes + Labels)
```bash
curl -X GET "http://localhost:8080/api/v1/drawings/dwg-1790800000/pages/1/markup" \
  -H "Accept: application/json"
```

### 6. Save / Update Page Markup (with Optimistic Lock Version)
```bash
curl -X PUT "http://localhost:8080/api/v1/drawings/dwg-1790800000/pages/1/markup" \
  -H "Content-Type: application/json" \
  -d '{
    "version": 1,
    "payload": "{\"strokes\":[{\"points\":[{\"x\":0.12,\"y\":0.15},{\"x\":0.34,\"y\":0.38}],\"color\":4294918960,\"strokeWidth\":4.0}],\"labels\":[{\"id\":\"lbl-1\",\"text\":\"4\\\" TIE-IN SPOOL REVISED\",\"x\":0.35,\"y\":0.40,\"size\":\"M\",\"color\":4294918960}]}"
  }'
```

### 7. Delete Drawing
```bash
curl -X DELETE "http://localhost:8080/api/v1/drawings/dwg-1790800000"
```

---

## 🔤 How to Swap the Engineering Font

The digital markup module strictly enforces a single uniform technical drawing font across all field notes and typed labels.

To replace the bundled font with your organization's custom CAD font (e.g. `ISOCPEUR.ttf`, `DIN1451.ttf`, or `Romans.ttf`):

1. **Place your TTF font file** into the assets directory:
   ```
   Field-Engineering/assets/fonts/EngineeringFont.ttf
   ```

2. **Register the font in `pubspec.yaml`**:
   ```yaml
   flutter:
     fonts:
       - family: EngineeringFont
         fonts:
           - asset: assets/fonts/EngineeringFont.ttf
             weight: 600
   ```

3. **Verify the Constant in `lib/core/theme/app_typography.dart`**:
   ```dart
   class AppTypography {
     static const String engineeringFontFamily = 'EngineeringFont';
     // ...
   }
   ```
   All text labels on the canvas, bottom sheets, and PDF export engine will immediately use your custom engineering font without modifying any other code.

---

## 🧪 Running Tests

### Flutter Frontend:
```bash
cd Field-Engineering
flutter test
```

### Quarkus Backend:
```bash
cd field-engineering-backend
mvn test
```
