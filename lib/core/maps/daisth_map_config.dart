/// Provider and camera configuration shared by Daisth map surfaces.
abstract final class DaisthMapConfig {
  static const lightStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const darkStyleUrl = 'https://tiles.openfreemap.org/styles/dark';

  static String styleUrlFor({required bool isDark}) =>
      isDark ? darkStyleUrl : lightStyleUrl;

  static const initialZoom = 12.5;
  static const selectedPlaceZoom = 15.0;
  static const styleLoadTimeout = Duration(seconds: 20);
}
