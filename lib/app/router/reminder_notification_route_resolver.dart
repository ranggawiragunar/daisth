import '../../features/reminders/data/mappers/reminder_mapper.dart';
import 'route_paths.dart';

class ReminderNotificationRouteResolver {
  ReminderNotificationRouteResolver(this.mapper);

  final ReminderMapper mapper;

  String resolve(String? payload) =>
      mapper.routeForPayload(payload) ?? RoutePaths.today;
}
