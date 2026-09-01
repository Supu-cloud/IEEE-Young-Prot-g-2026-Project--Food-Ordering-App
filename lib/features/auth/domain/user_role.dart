enum UserRole {
  customer('customer', 'Customer'),
  restaurantOwner('restaurant_owner', 'Restaurant owner'),
  deliveryRider('delivery_rider', 'Delivery rider');

  const UserRole(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static UserRole fromApi(String value) => UserRole.values.firstWhere(
        (role) => role.apiValue == value,
        orElse: () => UserRole.customer,
      );
}
