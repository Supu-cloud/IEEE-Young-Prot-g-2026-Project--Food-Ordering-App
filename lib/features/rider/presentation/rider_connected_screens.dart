import '../../../core/widgets/order_status.dart';
import 'delivery_actions.dart';
import 'package:flutter/material.dart';
import 'rider_map_screen.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../operations/data/operations_repository.dart';
import '../../operations/presentation/account_order_screens.dart';
import '../../operations/presentation/role_widgets.dart';

Future<Map<String,dynamic>?> riderProfile(OperationsRepository repository) async {
  try { return await repository.object('/roles/rider/profile'); }
  on ApiException catch (error) { if (error.statusCode == 404) return null; rethrow; }
}
class RiderHomeConnected extends StatelessWidget {
  const RiderHomeConnected({super.key, required this.repository}); final OperationsRepository repository;
  @override Widget build(BuildContext context) => LiveResource<Map<String,dynamic>>(load: () async {
    final today = DateTime.now(); final start = DateTime(today.year,today.month,today.day).toUtc().toIso8601String();
    final values = await Future.wait<dynamic>([riderProfile(repository), repository.list('/deliveries/my'), repository.object('/deliveries/my/earnings'), repository.object('/deliveries/my/earnings', query: {'from': start})]);
    return {'profile':values[0], 'deliveries':values[1], 'earnings':values[2], 'today':values[3]};
  }, builder: (context, data, reload) {
    final profile = map(data['profile']); final deliveries = maps(data['deliveries']); final earnings = map(data['earnings']); final today = map(data['today']);
    return roleList([
      title(context, 'Rider dashboard'),
      if (profile.isEmpty) ...[const Text('Complete your vehicle profile before receiving assignments.'), TextButton(onPressed: () => openPage(context, 'Vehicle setup', RiderVehicleEditor(repository: repository)), child: const Text('Set up vehicle'))]
      else ...[
        ListTile(leading: Icon(profile['isAvailable'] == true ? Icons.wifi : Icons.wifi_off), title: Text(profile['isAvailable'] == true ? 'Online • available for assignment' : 'Offline / on a delivery'), subtitle: Text('${profile['vehicleType']} • ${profile['vehicleNumber']}')),
        RoleAction(title: profile['isAvailable'] == true ? 'Go offline' : 'Go online', action: () async { await repository.request('/roles/rider/availability', method:'PATCH', data:{'isAvailable': profile['isAvailable'] != true}); await reload(); }),
      ],
      metrics(context, {'Active deliveries':deliveries.where((d) => !['delivered','failed','rejected'].contains(d['status'])).length, 'Completed today':today['completedTrips'], 'Earnings today':money(today['totalEarnings']), 'Total earnings':money(earnings['totalEarnings'])}),
      const Padding(padding: EdgeInsets.symmetric(vertical:16), child: Text('Jobs are assigned by a restaurant owner or admin. There is no public job board. Earnings shown are the backend internal test ledger.')),
      title(context, 'Current Delivery'),
      for (final delivery in deliveries.where((d) => !['delivered','failed','rejected'].contains(d['status']))) DeliveryTile(delivery: delivery, onTap: () => openPage(context, 'Current delivery', RiderDeliveryDetail(repository:repository,id:delivery['_id'] as String))),
    ]);
  });
}
class RiderDeliveriesConnected extends StatelessWidget {
  const RiderDeliveriesConnected({super.key, required this.repository, required this.section}); final OperationsRepository repository; final String section;
  @override Widget build(BuildContext context) => LiveResource<List<Map<String,dynamic>>>(load: () => repository.list('/deliveries/my'), builder: (context, deliveries, reload) {
    final visible = deliveries.where((d) => section == 'All' ? true : section == 'Assigned' ? d['status'] == 'assigned' : section == 'History' ? ['delivered','failed','rejected'].contains(d['status']) : ['accepted','picked_up','out_for_delivery'].contains(d['status'])).toList();
    return roleList([title(context, section == 'All' ? 'Deliveries' : section), Text('${deliveries.where((d) => !['delivered','failed','rejected'].contains(d['status'])).length} active · ${deliveries.where((d) => ['delivered','failed','rejected'].contains(d['status'])).length} completed / ended'), if (visible.isEmpty) Text(section == 'Assigned' ? 'No new assignments. Go online to receive work from a restaurant owner or admin.' : 'No deliveries in this section.'), for (final delivery in visible) DeliveryTile(delivery: delivery, onTap: () => openPage(context, 'Delivery details', RiderDeliveryDetail(repository:repository,id:delivery['_id'] as String))), if (section == 'History') TextButton(onPressed: () => openPage(context, 'Earnings', RiderEarningsConnected(repository: repository)), child: const Text('View earnings and completed trips'))]);
  });
}
class DeliveryTile extends StatelessWidget {
  const DeliveryTile({super.key,required this.delivery,required this.onTap}); final Map<String,dynamic> delivery; final VoidCallback onTap;
  @override Widget build(BuildContext context) {
    final order = map(delivery['order']); final status = delivery['status'] as String;
    return OrderStatusSurface(status: deliveryVisualStatus(status), child: ListTile(contentPadding: EdgeInsets.zero,
      title: Text('Delivery #${order['_id']}'),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${person(order['restaurant'])}\n${order['deliveryAddress'] ?? ''}\n${money(delivery['payout'])}'), OrderStatusChip(deliveryVisualStatus(status), text: deliveryLabel(status))]),
      trailing: const Icon(Icons.chevron_right), onTap: onTap));
  }
}
class RiderDeliveryDetail extends StatelessWidget {
  const RiderDeliveryDetail({super.key,required this.repository,required this.id}); final OperationsRepository repository; final String id;
  @override Widget build(BuildContext context) => LiveResource<Map<String,dynamic>>(load: () async {
    final deliveries=await repository.list('/deliveries/my'); return deliveries.firstWhere((item)=>item['_id']==id, orElse:()=>throw const ApiException('This delivery is no longer assigned to your account.',statusCode:404));
  },builder:(context,delivery,reload) {
    final status = delivery['status'] as String;
    return roleList([
      OrderStatusSurface(key: ValueKey('delivery-$id-$status'), status: deliveryVisualStatus(status), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title(context,'Delivery #${map(delivery['order'])['_id']}'),
        OrderStatusChip(deliveryVisualStatus(status), text: deliveryLabel(status)),
        Text('Assigned: ${localTime(delivery['assignedAt'])}'), Text('Delivery earning: ${money(delivery['payout'])}'),
        if(delivery['deliveredAt']!=null) Text('Completed: ${localTime(delivery['deliveredAt'])}'),
        OrderInformation(order:map(delivery['order']), showStatus: false),
      ])),
      FilledButton.icon(onPressed:()=>openPage(context,'Rider Map',RiderMapScreen(repository:repository,deliveryId:id)),icon:const Icon(Icons.route),label:const Text('View Route')),
      DeliveryActions(delivery: delivery, repository: repository, onConfirmed: (updated) {
        LiveResource.commit<Map<String,dynamic>>(context, (current) => {...current, ...updated, 'order': {...map(current['order']), 'status': deliveryOrderStatus[updated['status']]}});
        reload();
      }),
    ]);
  });
}
class RiderEarningsConnected extends StatelessWidget {
  const RiderEarningsConnected({super.key,required this.repository});final OperationsRepository repository;
  @override Widget build(BuildContext context)=>LiveResource<Map<String,dynamic>>(load:()=>repository.object('/deliveries/my/earnings'),builder:(context,data,reload)=>roleList([
    metrics(context,{'Completed trips':data['completedTrips'],'Total earnings':money(data['totalEarnings'])}),Text('${data['description']??'Internal test ledger; no bank payout'}'),
    for(final trip in maps(data['trips'])) ListTile(title:Text('Order #${map(trip['order'])['_id']??trip['_id']}'),subtitle:Text('${localTime(trip['deliveredAt'])} • ${person(map(trip['order'])['restaurant'])}'),trailing:Text(money(trip['payout']))),
  ]));
}
class RiderProfileConnected extends StatelessWidget {
  const RiderProfileConnected({super.key,required this.dependencies});final AppDependencies dependencies;
  @override Widget build(BuildContext context)=>Column(children:[
    ListTile(leading:const Icon(Icons.person_outline),title:const Text('Account, theme & sign out'),trailing:const Icon(Icons.chevron_right),onTap:()=>openPage(context,'Profile',AccountScreen(dependencies:dependencies))),
    Expanded(child:LiveResource<Map<String,dynamic>>(load:()async=>await riderProfile(dependencies.operations)??{},builder:(context,profile,reload)=>roleList([
      title(context,'Vehicle details'),
      if(profile.isEmpty) const Text('Add your vehicle information to activate delivery tools.') else ...[Text('Vehicle: ${profile['vehicleType']}'),Text('Registration: ${profile['vehicleNumber']}'),Text('Licence: ${profile['licenseNumber']??'Not provided'}'),Text(profile['isAvailable']==true?'Available for assignment':'Unavailable')],
      FilledButton(onPressed:()=>openPage(context,'Vehicle details',RiderVehicleEditor(repository:dependencies.operations)),child:const Text('Edit vehicle details')),
    ]))),
  ]);
}
class RiderVehicleEditor extends StatefulWidget {
  const RiderVehicleEditor({super.key,required this.repository});final OperationsRepository repository;
  @override State<RiderVehicleEditor> createState()=>_RiderVehicleEditorState();
}
class _RiderVehicleEditorState extends State<RiderVehicleEditor>{
  final form=GlobalKey<FormState>();final values=<String,String>{};
  @override Widget build(BuildContext context)=>LiveResource<Map<String,dynamic>>(poll:false,load:()async=>await riderProfile(widget.repository)??{},builder:(context,profile,reload)=>Form(key:form,child:roleList([
    for(final entry in {'vehicleType':'Vehicle type','vehicleNumber':'Registration number','licenseNumber':'Licence number','verificationDocuments':'Verification document URLs (one per line)'}.entries)Padding(padding:const EdgeInsets.only(bottom:16),child:TextFormField(initialValue:entry.key=='verificationDocuments'?(profile[entry.key] as List? ?? []).join('\n'):profile[entry.key]?.toString()??'',decoration:InputDecoration(labelText:entry.value),maxLines:entry.key=='verificationDocuments'?3:1,validator:(value)=>['vehicleType','vehicleNumber'].contains(entry.key)&&(value?.trim().isEmpty??true)?'Required':null,onSaved:(value)=>values[entry.key]=value!.trim())),
    RoleAction(title:'Save vehicle details',action:()async{if(!form.currentState!.validate())return;form.currentState!.save();await widget.repository.request('/roles/rider/profile',method:'PUT',data:{...values,'verificationDocuments':values['verificationDocuments']!.split('\n').where((line)=>line.trim().isNotEmpty).toList()});if(context.mounted)Navigator.pop(context);}),
  ])));
}
