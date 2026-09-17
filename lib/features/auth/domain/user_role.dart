enum UserRole {
  customer('customer', 'Customer'),
  restaurantOwner('restaurant_owner', 'Restaurant owner'),
  deliveryRider('delivery_rider', 'Delivery rider'),
  admin('admin', 'Administrator');

  const UserRole(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static UserRole fromApi(String value) => UserRole.values.firstWhere(
    (role) => role.apiValue == value,
    orElse: () => throw const FormatException('Unsupported account role. Please contact support.'),
  );
}
