import 'dart:typed_data';
import 'owner_order_card.dart';
import '../../operations/data/operations_repository.dart';
import '../../operations/presentation/account_order_screens.dart';
import '../../operations/presentation/role_widgets.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/coordinate_fields.dart';
import '../../../core/config/map_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/image_url.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../customer/data/customer_repository.dart';
import '../data/owner_restaurant_repository.dart';

class ConnectedOwnerRestaurantScreen extends StatefulWidget {
  const ConnectedOwnerRestaurantScreen({super.key, required this.repository, this.dashboard = false, this.operations});
  final OwnerRestaurantRepository repository;
  final bool dashboard;
  final OperationsRepository? operations;
  @override
  State<ConnectedOwnerRestaurantScreen> createState() => _ConnectedOwnerRestaurantScreenState();
}

class _ConnectedOwnerRestaurantScreenState extends State<ConnectedOwnerRestaurantScreen> with WidgetsBindingObserver {
  late Future<Map<String, dynamic>> _data;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); widget.repository.addListener(_reload); _data = widget.repository.getDashboard(); }
  void _reload() { if (mounted) setState(() => _data = widget.repository.getDashboard()); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _reload(); }
  @override
  void dispose() { widget.repository.removeListener(_reload); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  Future<void> _edit() async {
    await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => RestaurantSetupScreen(repository: widget.repository)));
    _reload();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return RestaurantLoadError(error: snapshot.error, retry: _reload);
      final value = snapshot.data!;
      final restaurant = value['restaurant'] == null ? null : RestaurantData.fromJson(Map<String, dynamic>.from(value['restaurant'] as Map));
      final metrics = Map<String, dynamic>.from(value['metrics'] as Map);
      return RefreshIndicator(onRefresh: () async { _reload(); await _data; }, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          Text(widget.dashboard ? 'Restaurant dashboard' : 'My Restaurant', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (restaurant == null) ...[
            const AppCard(child: Padding(padding: EdgeInsets.all(20), child: Text('Welcome to Foodie! Create your restaurant to introduce your food to customers.'))),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _edit, icon: const Icon(Icons.add_business), label: const Text('Create Restaurant')),
          ] else ...[
            RestaurantOverview(restaurant: restaurant),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _edit, icon: const Icon(Icons.edit_outlined), label: const Text('Edit Restaurant')),
            if (widget.dashboard) ...[
              const SizedBox(height: 24),
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (final metric in {'todayOrders': "Today's orders", 'activeOrders': 'Active orders', 'completedOrders': 'Completed orders', 'todayRevenue': 'Revenue today', 'menuItems': 'Menu items'}.entries)
                  SizedBox(width: 150, child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(metric.value), const SizedBox(height: 8), Text('${metric.key == 'todayRevenue' ? 'Rs. ' : ''}${metrics[metric.key] ?? 0}', style: Theme.of(context).textTheme.titleLarge)]))),
              ]),
              const SizedBox(height: 20),
              Text('Recent orders', style: Theme.of(context).textTheme.titleLarge),
              for (final order in maps(value['recentOrders'])) OwnerOrderCard(order: order,
                onTap: widget.operations == null ? null : () => openPage(context, 'Order details', OperationsOrderDetail(repository: widget.operations!, id: order['_id'] as String))),
            ],
          ],
        ],
      ));
    },
  );
}

class RestaurantOverview extends StatelessWidget {
  const RestaurantOverview({super.key, required this.restaurant});
  final RestaurantData restaurant;
  @override
  Widget build(BuildContext context) => AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    RestaurantLogo(url: restaurant.imageUrl),
    const SizedBox(height: 16),
    Text(restaurant.name, style: Theme.of(context).textTheme.headlineSmall),
    Text(restaurant.category, style: const TextStyle(color: AppColors.primaryDark)),
    const SizedBox(height: 8),
    Text(restaurant.isOpen ? 'Open for orders' : 'Currently closed', style: TextStyle(fontWeight: FontWeight.w700, color: restaurant.isOpen ? AppColors.primaryDark : AppColors.error)),
    const SizedBox(height: 12), Text(restaurant.description),
    ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.phone_outlined), title: Text(restaurant.phone)),
    ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.location_on_outlined), title: Text(restaurant.address)),
    const Divider(), const Text('Operating hours', style: TextStyle(fontWeight: FontWeight.w700)),
    if (restaurant.operatingHours.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Not specified')),
    ...restaurant.operatingHours.entries.map((entry) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text(_dayLabel(entry.key))), Flexible(child: Text(entry.value.label))]))),
  ]));
}

class RestaurantLogo extends StatelessWidget {
  const RestaurantLogo({super.key, this.url, this.bytes});
  final String? url;
  final Uint8List? bytes;
  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(url);
    Widget fallback() => const Center(child: Icon(Icons.storefront, size: 64, color: AppColors.primaryDark));
    return Container(width: double.infinity, height: 180, padding: const EdgeInsets.all(12), color: AppColors.primaryLight,
      child: bytes != null ? Image.memory(bytes!, fit: BoxFit.contain, errorBuilder: (_, _, _) => fallback()) : resolved == null ? fallback() : Image.network(resolved, fit: BoxFit.contain, errorBuilder: (_, _, _) => fallback()));
  }
}

class RestaurantSetupScreen extends StatefulWidget {
  const RestaurantSetupScreen({super.key, required this.repository});
  final OwnerRestaurantRepository repository;
  @override
  State<RestaurantSetupScreen> createState() => _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends State<RestaurantSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _latitude = '';
  String _longitude = '';
  RestaurantOptions? _options;
  RestaurantData? _restaurant;
  String? _category;
  String? _imageUrl;
  Uint8List? _bytes;
  String _filename = '';
  String _mime = '';
  Map<String, RestaurantDayHours> _hours = {};
  Map<String, String> _errors = {};
  bool _open = false;
  bool _loading = true;
  bool _busy = false;
  String? _loadError;
  String? _message;
  String? _success;
  String _stage = '';
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _name.dispose(); _description.dispose(); _phone.dispose(); _address.dispose(); super.dispose(); }
  void _fill(RestaurantData? restaurant) {
    _latitude = restaurant?.latitude?.toString() ?? ''; _longitude = restaurant?.longitude?.toString() ?? '';
    _restaurant = restaurant; _name.text = restaurant?.name ?? ''; _description.text = restaurant?.description ?? '';
    _phone.text = restaurant?.phone ?? ''; _address.text = restaurant?.address ?? ''; _category = restaurant?.category;
    _imageUrl = restaurant?.imageUrl; _open = restaurant?.isOpen ?? false; _hours = {...?restaurant?.operatingHours};
  }
  Future<void> _load() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final options = await widget.repository.getOptions();
      final restaurant = await widget.repository.getRestaurant();
      if (!mounted) return;
      setState(() { _options = options; _fill(restaurant); });
    } catch (error) { if (mounted) setState(() => _loadError = _errorMessage(error)); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _pickLogo() async {
    try {
      const group = XTypeGroup(label: 'Restaurant logo', extensions: ['jpg', 'jpeg', 'png', 'webp'], mimeTypes: ['image/jpeg', 'image/png', 'image/webp'], uniformTypeIdentifiers: ['public.jpeg', 'public.png', 'org.webmproject.webp']);
      final file = await openFile(acceptedTypeGroups: [group]);
      if (file == null || !mounted) return;
      final extension = file.name.split('.').last.toLowerCase();
      final mime = {'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png', 'webp': 'image/webp'}[extension];
      final size = await file.length();
      if (mime == null || !_options!.imageTypes.contains(mime)) throw const ApiException('Choose a JPG, PNG or WebP image.');
      if (size == 0 || size > _options!.maxImageBytes) throw ApiException('Choose an image up to ${_options!.maxImageBytes ~/ 1024 ~/ 1024} MB.');
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() { _bytes = bytes; _filename = file.name; _mime = mime; _errors.remove('imageUrl'); _success = null; });
    } catch (error) { if (mounted) setState(() => _errors['imageUrl'] = _errorMessage(error)); }
  }
  String? _required(String key, String? value, {int? max}) {
    if (_errors[key] != null) return _errors[key];
    if (value == null || value.trim().isEmpty) return 'Please complete this field.';
    if (max != null && value.trim().length > max) return 'Use $max characters or fewer.';
    return null;
  }
  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() { _errors.removeWhere((key, value) => key != 'imageUrl'); _message = null; _success = null; });
    final valid = _formKey.currentState!.validate();
    for (final entry in _hours.entries) {
      final h = entry.value;
      final time = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
      if (!h.closed && (!time.hasMatch(h.open) || !time.hasMatch(h.close) || h.open == h.close)) _errors['operatingHours.${entry.key}'] = 'Enter different opening and closing times.';
    }
    if (!valid || _errors.isNotEmpty) { setState(() => _message = 'Please check the highlighted fields.'); return; }
    setState(() { _busy = true; _stage = _bytes == null ? 'Saving?' : 'Uploading logo?'; });
    try {
      if (_bytes != null) {
        final url = await widget.repository.uploadLogo(_bytes!, _filename, _mime, (sent, total) { if (mounted && total > 0) setState(() => _stage = 'Uploading logo? ${(sent * 100 / total).round()}%'); });
        if (!mounted) return;
        setState(() { _imageUrl = url; _bytes = null; _stage = 'Saving?'; });
      }
      final location = coordinateInput(_latitude, _longitude);
      final saved = await widget.repository.saveRestaurant({...?location, 'name': _name.text.trim(), 'category': _category, 'description': _description.text.trim(), 'phone': _phone.text.trim(), 'address': _address.text.trim(), 'imageUrl': _imageUrl ?? '', 'isOpen': _open, 'operatingHours': _hours.map((day, hours) => MapEntry(day, hours.toJson()))});
      if (!mounted) return;
      setState(() { _fill(saved); _success = 'Restaurant saved. Customers see the same details after refreshing.'; });
    } catch (error) {
      if (mounted) { setState(() { _message = _errorMessage(error); if (error is ApiException) _errors = {...error.errors}; }); _formKey.currentState?.validate(); }
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _pickTime(String day, bool opening) async {
    final h = _hours[day]!;
    final raw = opening ? h.open : h.close;
    final parts = raw.split(':');
    final time = await showTimePicker(context: context, initialTime: parts.length == 2 ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0) : const TimeOfDay(hour: 9, minute: 0));
    if (time == null || !mounted) return;
    final text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    setState(() { _hours[day] = RestaurantDayHours(open: opening ? text : h.open, close: opening ? h.close : text); _errors.remove('operatingHours.$day'); });
  }
  Widget _field(String label, String key, TextEditingController controller, {int lines = 1, TextInputType? keyboard}) => Padding(padding: const EdgeInsets.only(bottom: 16), child: TextFormField(
    controller: controller, maxLines: lines, maxLength: _options!.limits[key], keyboardType: keyboard,
    decoration: InputDecoration(labelText: label, helperText: key == 'phone' ? 'Sri Lankan mobile or landline; +94 accepted.' : null),
    onChanged: (_) { _errors.remove(key); },
    validator: (value) {
      final error = _required(key, value, max: _options!.limits[key]);
      if (error != null) return error;
      if (key == 'phone' && !RegExp(_options!.phonePattern).hasMatch(value!.replaceAll(RegExp(r'[\s()-]'), ''))) return 'Use 0771234567 or +94771234567 format.';
      return null;
    },
  ));
  Widget _section(String title, List<Widget> children) => Padding(padding: const EdgeInsets.only(bottom: 20), child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 18), ...children])));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_restaurant == null ? 'Create Restaurant' : 'My Restaurant')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _loadError != null ? RestaurantLoadError(error: ApiException(_loadError!), retry: _load) : Form(key: _formKey, child: AbsorbPointer(absorbing: _busy, child: ListView(padding: const EdgeInsets.all(16), children: [
      if (_message != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_message!, style: const TextStyle(color: AppColors.error))),
      if (_success != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_success!, style: const TextStyle(color: AppColors.primaryDark))),
      _section('Restaurant identity', [
        _field('Restaurant name', 'name', _name),
        DropdownButtonFormField<String>(initialValue: _options!.categories.contains(_category) ? _category : null, isExpanded: true, decoration: const InputDecoration(labelText: 'Category'), hint: const Text('Choose a category'), items: _options!.categories.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) { _category = value; _errors.remove('category'); }, validator: (value) => _errors['category'] ?? (value == null || !_options!.categories.contains(value) ? 'Choose a category from the list.' : null)),
        const SizedBox(height: 16), _field('Description', 'description', _description, lines: 4),
        RestaurantLogo(url: _imageUrl, bytes: _bytes), const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _pickLogo, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Upload Restaurant Logo')),
        Text('JPG, PNG or WebP ? up to ${_options!.maxImageBytes ~/ 1024 ~/ 1024} MB', textAlign: TextAlign.center),
        if (_bytes != null) TextButton(onPressed: () => setState(() { _bytes = null; _errors.remove('imageUrl'); }), child: Text('Cancel selection: $_filename')),
        if (_errors['imageUrl'] != null) Text(_errors['imageUrl']!, style: const TextStyle(color: AppColors.error)),
      ]),
      _section('Contact & location', [_field('Phone', 'phone', _phone, keyboard: TextInputType.phone), _field('Address', 'address', _address, lines: 2), CoordinateFields(latitude:_latitude,longitude:_longitude,enabled:!_busy,onChanged:(lat,lng) { _latitude=lat; _longitude=lng; })]),
      _section('Business settings', [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Open for orders'), subtitle: const Text('Turn off to pause new orders.'), value: _open, onChanged: (value) => setState(() => _open = value)),
        const Divider(), const Text('Operating hours', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), const Text('Unspecified days stay unset. Closing before opening means the next day. The switch above controls order availability.'),
        ..._options!.days.map((day) {
          final h = _hours[day];
          return Padding(padding: const EdgeInsets.only(top: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(_dayLabel(day), style: const TextStyle(fontWeight: FontWeight.w600))), DropdownButton<String>(value: h == null ? 'unset' : h.closed ? 'closed' : 'open', items: const [DropdownMenuItem(value: 'unset', child: Text('Not specified')), DropdownMenuItem(value: 'open', child: Text('Set hours')), DropdownMenuItem(value: 'closed', child: Text('Closed'))], onChanged: (value) => setState(() { if (value == 'unset') { _hours.remove(day); } else { _hours[day] = RestaurantDayHours(open: h?.open ?? '', close: h?.close ?? '', closed: value == 'closed'); } _errors.remove('operatingHours.$day'); }))]),
            if (h != null && !h.closed) Wrap(spacing: 12, children: [OutlinedButton(onPressed: () => _pickTime(day, true), child: Text('Opens: ${h.open.isEmpty ? 'Choose' : h.open}')), OutlinedButton(onPressed: () => _pickTime(day, false), child: Text('Closes: ${h.close.isEmpty ? 'Choose' : h.close}'))]),
            if (_errors['operatingHours.$day'] != null) Text(_errors['operatingHours.$day']!, style: const TextStyle(color: AppColors.error)),
          ]));
        }),
      ]),
      FilledButton(onPressed: _busy ? null : _save, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(_busy ? _stage : _restaurant == null ? 'Create Restaurant' : 'Save Changes'))),
      const SizedBox(height: 30),
    ]))),
  );
}

class RestaurantLoadError extends StatelessWidget {
  const RestaurantLoadError({super.key, required this.error, required this.retry});
  final Object? error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_errorMessage(error)), const SizedBox(height: 12), FilledButton(onPressed: retry, child: const Text('Retry'))])));
}
String _errorMessage(Object? error) => error is ApiException ? error.message : 'Unable to complete this request. Please try again.';
String _dayLabel(String day) => day.isEmpty ? day : '${day[0].toUpperCase()}${day.substring(1)}';
