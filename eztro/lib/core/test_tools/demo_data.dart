class DemoData {
  const DemoData._();

  static const house = DemoHouseData(
    name: 'Nha tro Auto Test',
    addressDetail: '123 Duong Test',
    area: '180',
    floors: '4',
    latitude: 10.0385,
    longitude: 105.7876,
  );

  static const room = DemoRoomData(
    name: 'P.Auto 101',
    price: '2500000',
    area: '24',
    deposit: '2500000',
    maxTenants: '2',
  );

  static const service = DemoServiceData(
    typeName: 'Internet',
    price: '100000',
    unit: 'thang',
    chargeType: 'fixed',
  );

  static const member = DemoMemberData(
    name: 'Nguyen Van Test',
    phone: '0901234567',
    email: 'test.member@example.com',
    birthday: '1998-01-15',
    idCard: '012345678901',
    idCardDate: '2020-01-15',
    idCardPlace: 'Cuc Canh sat QLHC ve TTXH',
    address: '123 Duong Test, Phuong Test',
    gender: 'Nam',
  );

  static const receipt = DemoReceiptData(
    payerName: 'Nguyen Van Test',
    amount: '1500000',
    type: 'Thu tien phong',
    description: 'Du lieu auto fill phieu thu',
    paymentMethod: 'Tien mat',
  );

  static const expense = DemoExpenseData(
    receiverName: 'Tran Thi Test',
    amount: '350000',
    type: 'Sua chua',
    description: 'Du lieu auto fill phieu chi',
    paymentMethod: 'Tien mat',
  );

  static const deposit = DemoDepositData(
    customerName: 'Pham Van Coc Test',
    customerPhone: '0912345678',
    amount: '2000000',
    note: 'Du lieu auto fill phieu coc',
  );

  static const vehicle = DemoVehicleData(
    plate: '59-X1 12345',
    type: 'Honda Vision',
  );

  static const meter = DemoMeterData(electricDelta: 50, waterDelta: 5);

  static const incident = DemoIncidentData(
    title: 'Hong voi nuoc',
    description: 'Voi nuoc trong phong bi ri, can ho tro kiem tra.',
  );

  static const post = DemoPostData(ruleCount: 4);

  static const contract = DemoContractData(
    tenantName: 'Le Van Hop Dong Test',
    tenantPhone: '0923456789',
    tenantEmail: 'contract.test@example.com',
    birthday: '1997-02-20',
    idCard: '079123456789',
    idCardDate: '2021-03-10',
    idCardPlace: 'Cuc Canh sat QLHC ve TTXH',
    address: '45 Duong Test, Phuong Test',
    durationMonths: '6',
    paymentDay: '5',
    startElectric: '0',
    startWater: '0',
    gender: 'Nam',
  );

  static const invoice = DemoInvoiceData(electricDelta: 50, waterDelta: 5);
}

class DemoHouseData {
  final String name;
  final String addressDetail;
  final String area;
  final String floors;
  final double latitude;
  final double longitude;

  const DemoHouseData({
    required this.name,
    required this.addressDetail,
    required this.area,
    required this.floors,
    required this.latitude,
    required this.longitude,
  });
}

class DemoRoomData {
  final String name;
  final String price;
  final String area;
  final String deposit;
  final String maxTenants;

  const DemoRoomData({
    required this.name,
    required this.price,
    required this.area,
    required this.deposit,
    required this.maxTenants,
  });
}

class DemoServiceData {
  final String typeName;
  final String price;
  final String unit;
  final String chargeType;

  const DemoServiceData({
    required this.typeName,
    required this.price,
    required this.unit,
    required this.chargeType,
  });
}

class DemoMemberData {
  final String name;
  final String phone;
  final String email;
  final String birthday;
  final String idCard;
  final String idCardDate;
  final String idCardPlace;
  final String address;
  final String gender;

  const DemoMemberData({
    required this.name,
    required this.phone,
    required this.email,
    required this.birthday,
    required this.idCard,
    required this.idCardDate,
    required this.idCardPlace,
    required this.address,
    required this.gender,
  });
}

class DemoReceiptData {
  final String payerName;
  final String amount;
  final String type;
  final String description;
  final String paymentMethod;

  const DemoReceiptData({
    required this.payerName,
    required this.amount,
    required this.type,
    required this.description,
    required this.paymentMethod,
  });
}

class DemoExpenseData {
  final String receiverName;
  final String amount;
  final String type;
  final String description;
  final String paymentMethod;

  const DemoExpenseData({
    required this.receiverName,
    required this.amount,
    required this.type,
    required this.description,
    required this.paymentMethod,
  });
}

class DemoDepositData {
  final String customerName;
  final String customerPhone;
  final String amount;
  final String note;

  const DemoDepositData({
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.note,
  });
}

class DemoVehicleData {
  final String plate;
  final String type;

  const DemoVehicleData({required this.plate, required this.type});
}

class DemoMeterData {
  final int electricDelta;
  final int waterDelta;

  const DemoMeterData({required this.electricDelta, required this.waterDelta});
}

class DemoIncidentData {
  final String title;
  final String description;

  const DemoIncidentData({required this.title, required this.description});
}

class DemoPostData {
  final int ruleCount;

  const DemoPostData({required this.ruleCount});
}

class DemoContractData {
  final String tenantName;
  final String tenantPhone;
  final String tenantEmail;
  final String birthday;
  final String idCard;
  final String idCardDate;
  final String idCardPlace;
  final String address;
  final String durationMonths;
  final String paymentDay;
  final String startElectric;
  final String startWater;
  final String gender;

  const DemoContractData({
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.birthday,
    required this.idCard,
    required this.idCardDate,
    required this.idCardPlace,
    required this.address,
    required this.durationMonths,
    required this.paymentDay,
    required this.startElectric,
    required this.startWater,
    required this.gender,
  });
}

class DemoInvoiceData {
  final int electricDelta;
  final int waterDelta;

  const DemoInvoiceData({
    required this.electricDelta,
    required this.waterDelta,
  });
}
