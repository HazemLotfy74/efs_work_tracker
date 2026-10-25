import 'dart:io';

import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/step_header.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../manager/attendance_flow_cubit/attendance_flow_cubit.dart';

class SelfiePageView extends StatefulWidget {
  const SelfiePageView({super.key});

  @override
  State<SelfiePageView> createState() => _SelfiePageViewState();
}

class _SelfiePageViewState extends State<SelfiePageView> {
  final _picker = ImagePicker();
  bool _isPicking = false;

  Future<void> _takeSelfie() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        // Enough for evidence, small enough to upload.
        maxWidth: 1080,
        imageQuality: 80,
      );
      // `null` when the user closes the camera without a photo.
      if (file != null && mounted) {
        context.read<AttendanceFlowCubit>().setSelfie(file.path);
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceFlowCubit, AttendanceFlowState>(
      buildWhen: (previous, current) =>
          previous.event.selfiePath != current.event.selfiePath,
      builder: (context, state) {
        final selfiePath = state.event.selfiePath;
        return Column(
          spacing: 20,
          children: [
            StepHeader(
              icon: Icons.camera_alt_outlined,
              title: context.l10n.takeQuickSelfie,
              subtitle: context.l10n.positionYourFace,
            ),
            // Tap again to retake.
            CustomContainer(
              onTap: _takeSelfie,
              horizontalPadding: 20,
              verticalPadding: 20,
              borderWidth: 1,
              child: _isPicking
                  ? CircularProgressIndicator(color: context.colors.primary)
                  : selfiePath != null
                  ? Image.file(
                      File(selfiePath),
                      fit: BoxFit.contain,
                      width: 200,
                      height: 200,
                    )
                  : Column(
                      spacing: 10,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 100,
                          color: context.colors.primary,
                        ),
                        Text(
                          context.l10n.clickHereToUpload,
                          style: context.textTheme.titleMedium,
                        ),
                      ],
                    ),
            ),
            const Spacer(),
            AppPrimaryButton(
              // Disabled until a selfie is stored in the event.
              onPressed: selfiePath == null
                  ? null
                  : context.read<AttendanceFlowCubit>().next,
              child: Text(context.l10n.continueTo),
            ),
          ],
        );
      },
    );
  }
}
