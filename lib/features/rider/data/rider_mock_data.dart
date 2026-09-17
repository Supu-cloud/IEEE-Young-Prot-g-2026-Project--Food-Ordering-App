class RiderDeliveryMock {
  const RiderDeliveryMock(
    this.id,
    this.restaurant,
    this.customer,
    this.pickup,
    this.dropoff,
    this.distance,
    this.eta,
    this.earning,
    this.status,
  );
  final String id, restaurant, customer, pickup, dropoff, distance, eta, status;
  final int earning;
}

const riderDeliveriesMock = [
  RiderDeliveryMock(
    'FD-1048',
    'Ceylon Kitchen',
    'Maya Perera',
    '128 Galle Road, Colombo 03',
    '18 Flower Road, Colombo 07',
    '3.2 km',
    '18 min',
    420,
    'Assigned',
  ),
  RiderDeliveryMock(
    'FD-1045',
    'Hopper House',
    'Dinuka Jayasinghe',
    '24 Ward Place, Colombo 07',
    '91 Temple Road, Kotte',
    '5.8 km',
    '27 min',
    610,
    'Out for Delivery',
  ),
  RiderDeliveryMock(
    'FD-1039',
    'Island Spice',
    'Aisha Fernando',
    '65 High Level Road, Nugegoda',
    '6 Park Lane, Rajagiriya',
    '4.1 km',
    '22 min',
    520,
    'Delivered',
  ),
];
