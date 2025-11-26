enum DistanceUnit { miles, km }
enum RouteType { loop, finishLine }
enum RouteMode { local, explorer }

String distanceUnitToString(DistanceUnit unit) => unit.toString().split('.').last;
String routeTypeToString(RouteType type) => type == RouteType.finishLine ? 'finish-line' : 'loop';
String routeModeToString(RouteMode mode) => mode.toString().split('.').last;

DistanceUnit parseDistanceUnit(String s) => DistanceUnit.values.firstWhere((e) => distanceUnitToString(e) == s, orElse: () => DistanceUnit.miles);
RouteType parseRouteType(String s) => s == 'finish-line' ? RouteType.finishLine : RouteType.loop;
RouteMode parseRouteMode(String s) => RouteMode.values.firstWhere((e) => routeModeToString(e) == s, orElse: () => RouteMode.local);
