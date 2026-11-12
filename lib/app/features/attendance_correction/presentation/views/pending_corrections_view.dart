import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../admin/presentation/widgets/assign_reviewer_button.dart';
import '../../domain/repositories/correction_repository.dart';
import '../manager/pending_corrections_cubit/pending_corrections_cubit.dart';
import '../widgets/pending_corrections_view_body.dart';

/// Admin only (the router sends everyone else home): the pending
/// correction requests to approve or reject.
class PendingCorrectionsView extends StatelessWidget {
  const PendingCorrectionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // For "Assign reviewer" on each card.
        RepositoryProvider<ReviewerDirectory?>(create: ReviewerDirectory.of),
        BlocProvider(
          create: (context) =>
              PendingCorrectionsCubit(context.read<CorrectionRepository>())
                ..load(),
        ),
      ],
      child: const Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
          child: PendingCorrectionsViewBody(),
        ),
      ),
    );
  }
}
