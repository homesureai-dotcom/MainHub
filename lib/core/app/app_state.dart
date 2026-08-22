import '../../features/property/state/property_state.dart';
import '../../state/assessment_state.dart';

class AppState {
  AppState._();

  static final AppState instance = AppState._();

  final PropertyState property = PropertyState.instance;

  final AssessmentState assessment = AssessmentState.instance;
}