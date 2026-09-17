import '../config/app_environment.dart';

String? resolveImageUrl(String? value, {String? apiBaseUrl}) {
  if (value == null || value.trim().isEmpty) return null;
  final api = Uri.tryParse(apiBaseUrl ?? AppConfig.apiBaseUrl);
  if (api == null || !api.hasAuthority) return null;
  final origin = api.replace(path: '/', query: null, fragment: null);
  final uri = origin.resolve(value.trim());
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
    return uri.replace(scheme: api.scheme, host: api.host, port: api.hasPort ? api.port : null).toString();
  }
  return uri.toString();
}
