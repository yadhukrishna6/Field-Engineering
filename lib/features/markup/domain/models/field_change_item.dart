import 'annotation_item.dart';
import 'markup_layer.dart';

class FieldChangeItem {
  final int itemNumber;
  final String id;
  final String changeType; // 'DELETE' | 'ADD' | 'REPLACE' | 'RELOCATE' | 'VERIFY' | 'NOTE' | 'STAMP' | 'PHOTO' | 'DIMENSION' | 'MARKUP'
  final String? attachedTag;
  final String description;
  final String author;
  final DateTime timestamp;
  final GpsCoord? gps;
  final String status;
  final int pageNumber;
  final double x;
  final double y;
  final MarkupLayer layer;

  const FieldChangeItem({
    required this.itemNumber,
    required this.id,
    required this.changeType,
    this.attachedTag,
    required this.description,
    required this.author,
    required this.timestamp,
    this.gps,
    this.status = 'PENDING_REVIEW',
    this.pageNumber = 1,
    required this.x,
    required this.y,
    this.layer = MarkupLayer.markups,
  });

  factory FieldChangeItem.fromAnnotation(int itemNumber, AnnotationItem ann, {int pageNumber = 1}) {
    String derivedType = 'MARKUP';
    if (ann.changeType != null && ann.changeType!.isNotEmpty) {
      derivedType = ann.changeType!.toUpperCase();
    } else {
      switch (ann.type) {
        case AnnotationType.strikeOut:
          derivedType = 'DELETE';
          break;
        case AnnotationType.noteBox:
          derivedType = 'NOTE';
          break;
        case AnnotationType.stamp:
          derivedType = 'STAMP';
          break;
        case AnnotationType.photoPin:
          derivedType = 'PHOTO';
          break;
        case AnnotationType.dimension:
          derivedType = 'DIMENSION';
          break;
        case AnnotationType.callout:
          derivedType = 'CALLOUT';
          break;
        default:
          derivedType = ann.type.code.toUpperCase();
      }
    }

    String desc = ann.text ?? '';
    if (desc.isEmpty) {
      if (ann.metadata?['caption'] != null) {
        desc = ann.metadata!['caption'].toString();
      } else if (derivedType == 'DELETE') {
        desc = 'Delete / Strike-out marked spool component';
      } else if (derivedType == 'PHOTO') {
        desc = 'Field Photo Inspection';
      } else if (ann.type == AnnotationType.line || ann.type == AnnotationType.stroke) {
        desc = 'Vector redline markup';
      } else {
        desc = '${ann.type.name} markup';
      }
    }

    final originX = ann.points.isNotEmpty ? ann.points.first.x : 0.5;
    final originY = ann.points.isNotEmpty ? ann.points.first.y : 0.5;

    return FieldChangeItem(
      itemNumber: itemNumber,
      id: ann.id,
      changeType: derivedType,
      attachedTag: ann.attachedTag?.text,
      description: desc,
      author: ann.author ?? 'Field Engineer',
      timestamp: ann.createdAt,
      gps: ann.gps,
      status: ann.status ?? 'PENDING_REVIEW',
      pageNumber: pageNumber,
      x: originX,
      y: originY,
      layer: ann.layer,
    );
  }

  static List<FieldChangeItem> extractChanges(List<AnnotationItem> annotations, {int pageNumber = 1}) {
    final result = <FieldChangeItem>[];
    int count = 1;

    for (final ann in annotations) {
      if (ann.isConflictCopy) continue;
      // Filter out raw simple pen strokes from the formal change table unless tagged or strike-out
      if (ann.type == AnnotationType.stroke && ann.attachedTag == null && ann.changeType == null) {
        continue;
      }
      result.add(FieldChangeItem.fromAnnotation(count++, ann, pageNumber: pageNumber));
    }

    return result;
  }
}
