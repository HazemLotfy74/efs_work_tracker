import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../attendance_correction/domain/correction_rules.dart';
import '../../../attendance_session/domain/entities/attendance_event_entity.dart';
import '../../../attendance_session/presentation/widgets/location/location_map.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';

/// The photo, time and location recorded with one check-in or check-out.
/// Shows only what was saved with that event: never a live location, and
/// nothing made up when a part is missing.
class AttendanceEvidenceCard extends StatelessWidget {
  const AttendanceEvidenceCard({
    super.key,
    required this.title,
    required this.event,
    required this.timezone,
    required this.photoUrl,
    this.showMap = true,
  });

  final String title;

  /// `null` when no event was recorded (no check-out).
  final AttendanceEventEntity? event;
  final String? timezone;

  /// Signs the selfie's Storage path; called once, only when shown.
  final Future<String> Function(String path) photoUrl;

  /// Off in tests (map tiles come from the network).
  final bool showMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final event = this.event;
    String time(DateTime instant) =>
        CorrectionRules.wallClock(timezone, instant).formatTime(context);
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 16,
      verticalPadding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(title, style: context.textTheme.titleMedium),
          if (event == null)
            Text(
              l10n.adminNoCheckOut,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          else ...[
            _EvidencePhoto(path: event.selfiePath, photoUrl: photoUrl),
            if (event.time case final at?)
              InfoRow(label: l10n.adminRecordedAt, value: time(at)),
            _EvidenceLocation(event: event, time: time, showMap: showMap),
          ],
        ],
      ),
    );
  }
}

class _EvidencePhoto extends StatefulWidget {
  const _EvidencePhoto({required this.path, required this.photoUrl});

  final String? path;
  final Future<String> Function(String path) photoUrl;

  @override
  State<_EvidencePhoto> createState() => _EvidencePhotoState();
}

class _EvidencePhotoState extends State<_EvidencePhoto> {
  late final Future<String>? _url = switch (widget.path) {
    final path? => widget.photoUrl(path),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = _url;
    if (url == null) return _Placeholder(text: l10n.adminPhotoUnavailable);
    return FutureBuilder<String>(
      future: url,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Placeholder(text: l10n.adminPhotoLoadFailed);
        }
        final link = snapshot.data;
        if (link == null) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Semantics(
          button: true,
          label: l10n.adminOpenPhoto,
          child: GestureDetector(
            key: const Key('evidencePhoto'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => _FullScreenPhoto(url: link),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 220,
                width: double.infinity,
                color: context.colors.surfaceContainerLow,
                // contain: the whole photo, never cropped.
                child: Image.network(
                  link,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      _Placeholder(text: l10n.adminPhotoLoadFailed),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  const _FullScreenPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image.network(url, fit: BoxFit.contain)),
      ),
    );
  }
}

class _EvidenceLocation extends StatelessWidget {
  const _EvidenceLocation({
    required this.event,
    required this.time,
    required this.showMap,
  });

  final AttendanceEventEntity event;
  final String Function(DateTime) time;
  final bool showMap;

  static bool _valid(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final location = event.location;
    if (location == null ||
        !_valid(location.latitude, location.longitude)) {
      return _Placeholder(text: l10n.adminLocationUnavailable);
    }
    final coordinates =
        '${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (showMap)
          LocationMap(point: LatLng(location.latitude, location.longitude)),
        InfoRow(
          label: l10n.adminLatitude,
          value: location.latitude.toStringAsFixed(6),
        ),
        InfoRow(
          label: l10n.adminLongitude,
          value: location.longitude.toStringAsFixed(6),
        ),
        InfoRow(
          label: l10n.adminAccuracy,
          value: l10n.adminAccuracyMeters(location.accuracyMeters.round()),
        ),
        InfoRow(
          label: l10n.adminLocationCapturedAt,
          value: time(location.capturedAt),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: coordinates));
              showAppSnackBar(
                messenger,
                l10n.adminCopied,
                type: AppMessageType.success,
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l10n.adminCopyCoordinates),
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
