import 'flow_order.dart';

enum OrderStatus { transit, delivered, postponed, failed }

/// What the courier is standing in front of at each end of a route leg — the
/// branch they set out from, or the kind of address they are heading to. Drives
/// the Home hero's «from → to» leg, which reads branch → building on the first
/// order of a batch and building → villa on every one after it.
enum PlaceKind { branch, building, villa }

class Order {
  const Order({
    required this.num,
    required this.name,
    required this.addr,
    required this.area,
    required this.status,
    this.due,
    this.cod,
    this.prepaid = false,
    this.dist,
    this.returns,
    this.reason,
    this.postponedAt,
    this.items = const [],
    this.note,
    this.collected,
    this.phone,
    this.place = PlaceKind.building,
    this.addrDetail,
  });

  final String num;
  final String name;
  final String addr;
  final String area;
  final OrderStatus status;
  final String? due; // promised delivery time label, e.g. "2:45 م"
  final int? cod; // cash-on-delivery amount in EGP
  final bool prepaid;
  final String? dist; // distance label shown on the queue card, e.g. "4.2 كم"
  final String? returns; // postponed: when it returns to the active queue
  final String? reason; // postponed reason, or failure reason once returned
  final String? postponedAt; // postponed: when it was postponed

  /// The order's line items — shown on the detail screen and the source of the
  /// [pieces] count carried on the card. Kept on [Order] so a tapped card and
  /// its detail agree (number of items, COD vs prepaid, note).
  final List<FlowOrderItem> items;

  /// Customer note for the courier; `null` hides the notes card.
  final String? note;

  /// Cash actually collected on delivery (COD). Set when the order is marked
  /// delivered so the shift's "collected today" total is real.
  final int? collected;

  /// The kind of address this order is delivered to. Apartment blocks are the
  /// common case, so [PlaceKind.building] is the default; a standalone house
  /// gets [PlaceKind.villa]. Never [PlaceKind.branch] — that end of the leg is
  /// the branch itself, not an order.
  final PlaceKind place;

  /// The customer's phone, in dialable form. Powers the Order Detail call
  /// button and the Live Activity's "اتصال بالعميل" — null simply hides both.
  final String? phone;

  /// The last-metres part of the address — building, floor and apartment (or
  /// villa number and gate). The street gets the courier to the block; this
  /// gets them to the door, so the hero shows it as its own line.
  final String? addrDetail;

  /// Number of pieces = the sum of item quantities. Reflected on the card meta
  /// ("<area> · N قطعة") and on the detail.
  int get pieces => items.fold(0, (sum, it) => sum + it.qty);

  /// Full delivery address ("street - area") for the maps badge + search.
  String get fullAddress => '$addr - $area';

  /// The address with its door-level detail, for the order detail screen:
  /// "street، building · floor · apartment - area".
  String get detailedAddress =>
      addrDetail == null ? fullAddress : '$addr، $addrDetail - $area';

  /// The order's leg distance as a number (from the "4.2 كم" label), or null
  /// when there is none. Feeds the batch trip estimate.
  double? get distanceKm {
    final d = dist;
    if (d == null) return null;
    final match = RegExp(r'[\d.]+').firstMatch(d);
    return double.tryParse(match?.group(0) ?? '');
  }

  /// The same order as it leaves the branch: in transit, with no outcome yet.
  /// The sample day ships some orders already delivered / failed / postponed
  /// so the app opens mid-shift; a *fresh* day has to start them all at zero
  /// or "start a new day" would hand the courier a batch already half closed.
  Order asFresh() => Order(
    num: num,
    name: name,
    addr: addr,
    area: area,
    status: OrderStatus.transit,
    due: due,
    cod: cod,
    prepaid: prepaid,
    dist: dist,
    items: items,
    note: note,
    phone: phone,
    place: place,
    addrDetail: addrDetail,
    // reason / returns / postponedAt / collected are outcomes — dropped.
  );

  Order copyWith({OrderStatus? status, String? reason, int? collected}) {
    return Order(
      num: num,
      name: name,
      addr: addr,
      area: area,
      status: status ?? this.status,
      due: due,
      cod: cod,
      prepaid: prepaid,
      dist: dist,
      returns: returns,
      reason: reason ?? this.reason,
      postponedAt: postponedAt,
      items: items,
      note: note,
      collected: collected ?? this.collected,
      phone: phone,
      place: place,
      addrDetail: addrDetail,
    );
  }
}

/// Sample data mirroring the mockup's own `state.orders`. Names are Arabic (the
/// app is Arabic-first) and every order carries its items + note so a tapped
/// card and its detail agree.
/// One dispatch of orders from the branch. A courier's day is a sequence of
/// these, not a single hand-off: a batch can land while an earlier one is still
/// being delivered, so each keeps its own identity through the Pickup tab.
class OrderBatch {
  const OrderBatch({required this.id, required this.orders});

  /// The batch's identity as the branch prints it — «T #7877». Shown on the
  /// hero, the Orders tab and the settlement, so the courier and the cashier
  /// are always talking about the same thing.
  final String id;
  final List<Order> orders;

  /// The ride from the last door back to the branch, in km. There is no
  /// routing service yet, so one city figure stands in for it.
  static const double returnLegKm = 6;

  /// Average city speed the estimates assume (dense Cairo traffic on a bike).
  static const double cityKmPerHour = 22;

  int get count => orders.length;

  /// The whole trip: every leg to a stop, plus the ride back to the branch.
  /// A sum of the orders' own leg distances — an estimate, not a route.
  double get routeKm =>
      orders.fold<double>(0, (sum, o) => sum + (o.distanceKm ?? 0)) +
      returnLegKm;

  /// Total cash due across the batch, so the courier can size up what they are
  /// about to carry before accepting it.
  int get codTotal =>
      orders.fold(0, (sum, o) => sum + (o.prepaid ? 0 : (o.cod ?? 0)));
}

/// The second branch batch — dispatched to the courier *while the first one is
/// still being delivered*, which is the normal case in the field: a courier can
/// hold several batches in one day. Announced by the dispatch sheet and waits in
/// [ShiftController.pendingPickup] until it is carried from the branch.
/// The batch the day opens with — already in hand, partly delivered.
const String sampleBatchOneId = 'T #7877';
const String sampleBatchTwoId = 'T #7878';
const String sampleBatchThreeId = 'T #7879';

final List<Order> sampleBatchTwo = [
  const Order(
    num: '#89412',
    phone: '+201115540',
    name: 'سلمى فؤاد',
    addr: 'شارع مصدق',
    area: 'الدقي',
    addrDetail: 'عمارة 7 · الدور 3 · شقة 12',
    status: OrderStatus.transit,
    due: '5:20 م',
    cod: 640,
    dist: '6.8 كم',
  ),
  const Order(
    num: '#89417',
    phone: '+201227781',
    name: 'طارق الشناوي',
    addr: 'شارع التسعين الشمالي',
    area: 'التجمع الخامس',
    addrDetail: 'فيلا 18 · بوابة 2',
    status: OrderStatus.transit,
    place: PlaceKind.villa,
    due: '5:50 م',
    prepaid: true,
    dist: '11.3 كم',
  ),
  const Order(
    num: '#89423',
    phone: '+201004432',
    name: 'دينا سمير',
    addr: 'شارع جسر السويس',
    area: 'مصر الجديدة',
    addrDetail: 'عمارة 22 · الدور 1 · شقة 4',
    status: OrderStatus.transit,
    due: '6:15 م',
    cod: 980,
    dist: '8.1 كم',
  ),
];

final List<Order> sampleOrders = [
  const Order(
    num: '#89289',
    phone: '+201092890',
    name: 'محمد حمدي',
    addr: 'شارع بن عبدالعزيز',
    area: 'زهراء مدينة نصر',
    addrDetail: 'عمارة 4290 · الدور 5 · شقة 52',
    status: OrderStatus.transit,
    due: '2:45 م',
    cod: 1200,
    dist: '4.2 كم',
    items: [
      FlowOrderItem(
        name: 'فادج شوكولاتة بالبندق',
        variant: 'متوسطة – 20 سم',
        weight: '600 جم',
        qty: 2,
      ),
      FlowOrderItem(
        name: 'كوكيز الشوفان بالعسل',
        variant: 'علبة – 12 قطعة',
        weight: '350 جم',
        qty: 2,
      ),
    ],
    note:
        'برجاء الاتصال قبل التوصيل بساعة على الأقل. العميل في الدور الخامس والمصعد معطّل، فيُرجى الصعود على السلّم.',
  ),
  const Order(
    num: '#89304',
    phone: '+201093040',
    name: 'سارة علي',
    addr: 'شارع 10',
    area: 'زهراء مدينة نصر',
    addrDetail: 'عمارة 15 · الدور 2 · شقة 8',
    dist: '2.1 كم',
    status: OrderStatus.postponed,
    returns: '4:30 م',
    reason: 'العميل طلب التوصيل بعد ساعتين',
    postponedAt: '2:30 م',
    cod: 640,
    items: [
      FlowOrderItem(
        name: 'تشيز كيك بالفراولة',
        variant: 'صغيرة – 14 سم',
        weight: '450 جم',
      ),
    ],
  ),
  const Order(
    num: '#89322',
    phone: '+201093220',
    name: 'نور عادل',
    addr: 'شارع 26',
    area: 'زهراء مدينة نصر',
    addrDetail: 'عمارة 33 · الدور الأرضي · شقة 1',
    dist: '1.8 كم',
    status: OrderStatus.delivered,
    cod: 350,
    collected: 350,
    items: [
      FlowOrderItem(
        name: 'مافن فانيليا',
        variant: 'علبة – 6 قطع',
        weight: '300 جم',
      ),
    ],
  ),
  const Order(
    num: '#89293',
    phone: '+201092930',
    name: 'يوسف كمال',
    addr: 'شارع النصر',
    area: 'مصر الجديدة',
    addrDetail: 'فيلا 42 · شارع فرعي 3',
    status: OrderStatus.transit,
    place: PlaceKind.villa,
    due: '3:15 م',
    prepaid: true,
    dist: '6.8 كم',
    items: [
      FlowOrderItem(
        name: 'كيك ريد فيلفيت',
        variant: 'كبيرة – 24 سم',
        weight: '900 جم',
      ),
    ],
    note:
        'الرجاء الاتصال قبل الوصول بـ 10 دقائق. البواب يستلم الطلب لو العميل غير موجود.',
  ),
  const Order(
    num: '#89298',
    phone: '+201092980',
    name: 'هناء مصطفى',
    addr: 'شارع التسعين',
    area: 'المعادي',
    addrDetail: 'عمارة 14 · الدور 2 · شقة 7',
    status: OrderStatus.transit,
    due: '3:40 م',
    cod: 640,
    dist: '11.5 كم',
    items: [
      FlowOrderItem(
        name: 'تورتة شوكولاتة',
        variant: 'وسط – 18 سم',
        weight: '700 جم',
      ),
      FlowOrderItem(
        name: 'بسكويت زبدة',
        variant: 'علبة – 20 قطعة',
        weight: '400 جم',
      ),
    ],
  ),
  const Order(
    num: '#89311',
    phone: '+201093110',
    name: 'عمر شريف',
    addr: 'شارع 9',
    area: 'المقطم',
    addrDetail: 'عمارة 9 · الدور 4 · شقة 16',
    dist: '2.4 كم',
    status: OrderStatus.postponed,
    returns: '6:00 م',
    reason: 'العميل مش في البيت قبل 6 م',
    postponedAt: '1:05 م',
    prepaid: true,
    items: [
      FlowOrderItem(
        name: 'كب كيك متنوع',
        variant: 'علبة – 6 قطع',
        weight: '450 جم',
        qty: 3,
      ),
    ],
  ),
  const Order(
    num: '#89340',
    phone: '+201093400',
    name: 'كريم عادل',
    addr: 'شارع الثورة',
    area: 'مدينة نصر',
    addrDetail: 'فيلا 6 · بوابة 1',
    status: OrderStatus.transit,
    place: PlaceKind.villa,
    due: '4:00 م',
    cod: 450,
    dist: '7.3 كم',
    items: [
      FlowOrderItem(
        name: 'تشيز كيك أوريو',
        variant: 'كبيرة – 22 سم',
        weight: '850 جم',
      ),
    ],
  ),
  const Order(
    num: '#89355',
    phone: '+201093550',
    name: 'ليلى فتحي',
    addr: 'شارع الحرية',
    area: 'مدينة نصر',
    addrDetail: 'عمارة 21 · الدور 6 · شقة 24',
    dist: '3.2 كم',
    status: OrderStatus.failed,
    reason: 'تعذّر التواصل مع العميل',
    items: [
      FlowOrderItem(
        name: 'تورتة عيد ميلاد',
        variant: 'كبيرة – 26 سم',
        weight: '1200 جم',
      ),
    ],
  ),
  const Order(
    num: '#89361',
    phone: '+201093610',
    name: 'خالد سمير',
    addr: 'شارع 9',
    area: 'المعادي',
    addrDetail: 'عمارة 5 · الدور 1 · شقة 3',
    dist: '2.6 كم',
    status: OrderStatus.failed,
    reason: 'العميل رفض استلام الطلب',
    items: [
      FlowOrderItem(
        name: 'دونات متنوع',
        variant: 'علبة – 12 قطعة',
        weight: '600 جم',
        qty: 2,
      ),
    ],
  ),
  const Order(
    num: '#89372',
    phone: '+201093720',
    name: 'منى سعيد',
    addr: 'شارع الميرغني',
    area: 'مصر الجديدة',
    addrDetail: 'عمارة 12 · الدور 3 · شقة 9',
    dist: '1.9 كم',
    status: OrderStatus.failed,
    reason: 'عدم تطابق المنتج',
    items: [
      FlowOrderItem(
        name: 'تشيز كيك مانجو',
        variant: 'وسط – 18 سم',
        weight: '650 جم',
        qty: 2,
      ),
    ],
  ),
];

/// A third batch, dispatched later in the day so two batches can be open at
/// once — the normal case in the field.
final List<Order> sampleBatchThree = [
  const Order(
    num: '#89431',
    phone: '+201118820',
    name: 'أحمد فؤاد',
    addr: 'شارع عباس العقاد',
    area: 'مدينة نصر',
    addrDetail: 'عمارة 60 · الدور 7 · شقة 28',
    status: OrderStatus.transit,
    due: '7:30 م',
    cod: 450,
    dist: '3.4 كم',
  ),
  const Order(
    num: '#89436',
    phone: '+201005531',
    name: 'ياسمين عادل',
    addr: 'شارع الخليفة المأمون',
    area: 'مصر الجديدة',
    addrDetail: 'عمارة 3 · الدور 2 · شقة 5',
    status: OrderStatus.transit,
    due: '8:00 م',
    cod: 620,
    dist: '5.5 كم',
  ),
];

/// The three batches a simulated day dispatches, in order. The branch sends
/// them one at a time — the next only after the courier has carried the last
/// out of the door — so this is a plan, not a schedule.
List<OrderBatch> get demoDayBatches => [
  OrderBatch(
    id: sampleBatchOneId,
    orders: [for (final o in sampleOrders.take(5)) o.asFresh()],
  ),
  OrderBatch(id: sampleBatchTwoId, orders: sampleBatchTwo),
  OrderBatch(id: sampleBatchThreeId, orders: sampleBatchThree),
];

/// Builds the rich per-order [FlowOrder] the order-flow screens expect straight
/// from a queue [Order]. Items, note, COD/prepaid and piece count all carry
/// across, so a tapped card and its detail always agree. Shared by the queue
/// (card taps) and the app shell (Home's next-stop hero).
FlowOrder orderToFlow(Order o) {
  return FlowOrder(
    num: o.num,
    name: o.name,
    meta: o.pieces > 0 ? '${o.area} · ${o.pieces} قطعة' : o.area,
    state: switch (o.status) {
      OrderStatus.transit || OrderStatus.postponed => FlowOrderState.active,
      OrderStatus.delivered => FlowOrderState.done,
      OrderStatus.failed => FlowOrderState.failed,
    },
    cod: o.cod != null && !o.prepaid,
    amount: o.cod != null ? formatThousands(o.cod!) : null,
    address: o.detailedAddress,
    items: o.items,
    note: o.note,
    assignedTime: o.due ?? '',
    pickedTime: '',
    dateLabel: '',
  );
}

String formatThousands(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Every number in the app is written in English (Western) digits — the
/// design call, ending the Eastern/Western mix. This is the one funnel counts
/// pass through on their way into Arabic copy: it stringifies, and straightens
/// out any stray Eastern-Arabic digits that ride in on data.
String englishDigits(Object value) {
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var s = value.toString();
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(eastern[i], '$i');
  }
  return s;
}

/// A wall-clock label in the app's Arabic 12-hour form — "5:40 م".
String formatClockArabic(DateTime t) {
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final mm = t.minute.toString().padLeft(2, '0');
  final suffix = t.hour < 12 ? 'ص' : 'م';
  return '$h12:$mm $suffix';
}

/// A km figure for Arabic copy — "34 كم" (rounded, English digits).
String formatKmArabic(double km) => '${km.round()} كم';

const List<String> _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];
const List<String> _arabicWeekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

/// "13 سبتمبر" — day and month, Eastern digits.
String formatDateArabic(DateTime d) =>
    '${englishDigits(d.day)} ${_arabicMonths[d.month - 1]}';

/// "الخميس" for a date.
String weekdayArabic(DateTime d) => _arabicWeekdays[d.weekday - 1];
