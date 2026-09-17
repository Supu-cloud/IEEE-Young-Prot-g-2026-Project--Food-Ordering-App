class OwnerOrderMock {
  const OwnerOrderMock(
    this.id,
    this.customer,
    this.total,
    this.status,
    this.items,
    this.time,
  );
  final String id, customer, status, time;
  final int total, items;
}

class OwnerMenuMock {
  const OwnerMenuMock(this.name, this.category, this.price, this.available);
  final String name, category;
  final int price;
  final bool available;
}

const ownerOrdersMock = [
  OwnerOrderMock('FD-1048', 'Maya Perera', 3280, 'Pending', 3, '5 min ago'),
  OwnerOrderMock('FD-1047', 'Nimal Silva', 2460, 'Confirmed', 3, '12 min ago'),
  OwnerOrderMock(
    'FD-1046',
    'Aisha Fernando',
    1850,
    'Preparing',
    1,
    '21 min ago',
  ),
  OwnerOrderMock(
    'FD-1045',
    'Dinuka Jayasinghe',
    2960,
    'Out for Delivery',
    2,
    '38 min ago',
  ),
  OwnerOrderMock('FD-1044', 'Emma Wilson', 1380, 'Delivered', 2, '11:20 AM'),
];

const ownerMenuMock = [
  OwnerMenuMock('Cheese Chicken Kottu', 'Kottu', 1450, true),
  OwnerMenuMock('Egg Hopper Breakfast', 'Breakfast', 980, true),
  OwnerMenuMock('Chicken Lamprais', 'Rice', 1480, true),
  OwnerMenuMock('Watalappan', 'Dessert', 500, false),
];
