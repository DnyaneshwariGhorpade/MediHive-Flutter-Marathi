class OpdFormData {
  String patientId;
  String name;
  String dob;
  String age;
  String gender;
  String mobile;
  String address;
  String bloodGroup;
  String diagnosis;
  String symptoms;
  String opdType;
  String chargeType;
  String medicines;
  String clinicalNotes;
  String panchakarmaNotes;
  String nextVisit;
  String consultationFee;
  String medicineFee;
  String panchakarmaFee;
  String discount;
  String discountType;
  String paymentMode;
  String previousVisitDate;
  String followUpReason;
  String weight;

  OpdFormData({
    this.patientId = '',
    this.name = '',
    this.dob = '',
    this.age = '',
    this.gender = 'Male',
    this.mobile = '',
    this.address = '',
    this.bloodGroup = 'O+',
    this.diagnosis = '',
    this.symptoms = '',
    this.opdType = 'Consultation',
    this.chargeType = 'Cash',
    this.medicines = '',
    this.clinicalNotes = '',
    this.panchakarmaNotes = '',
    this.nextVisit = '',
    this.consultationFee = '500',
    this.medicineFee = '0',
    this.panchakarmaFee = '0',
    this.discount = '0',
    this.discountType = 'None',
    this.paymentMode = 'Cash',
    this.previousVisitDate = '',
    this.followUpReason = '',
    this.weight = '',
  });

  double get subtotal =>
      (double.tryParse(consultationFee) ?? 0) +
      (double.tryParse(medicineFee) ?? 0) +
      (double.tryParse(panchakarmaFee) ?? 0);

  double get totalFee {
    final sub = subtotal;
    final discVal = double.tryParse(discount) ?? 0;
    if (discountType == '₹') return sub - discVal < 0 ? 0 : sub - discVal;
    if (discountType == '%') {
      final discAmt = sub * discVal / 100;
      return sub - discAmt < 0 ? 0 : sub - discAmt;
    }
    return sub;
  }

  void reset() {
    patientId = '';
    name = '';
    dob = '';
    age = '';
    gender = 'Male';
    mobile = '';
    address = '';
    bloodGroup = 'O+';
    diagnosis = '';
    symptoms = '';
    opdType = 'Consultation';
    chargeType = 'Cash';
    medicines = '';
    clinicalNotes = '';
    panchakarmaNotes = '';
    nextVisit = '';
    consultationFee = '500';
    medicineFee = '0';
    panchakarmaFee = '0';
    discount = '0';
    discountType = 'None';
    paymentMode = 'Cash';
    previousVisitDate = '';
    followUpReason = '';
    weight = '';
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'name': name,
      'dob': dob,
      'age': age,
      'gender': gender,
      'mobile': mobile,
      'address': address,
      'bloodGroup': bloodGroup,
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'opdType': opdType,
      'chargeType': chargeType,
      'medicines': medicines,
      'clinicalNotes': clinicalNotes,
      'panchakarmaNotes': panchakarmaNotes,
      'nextVisit': nextVisit,
      'consultationFee': consultationFee,
      'medicineFee': medicineFee,
      'panchakarmaFee': panchakarmaFee,
      'discount': discount,
      'discountType': discountType,
      'paymentMode': paymentMode,
      'previousVisitDate': previousVisitDate,
      'followUpReason': followUpReason,
      'weight': weight,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    patientId = json['patientId'] ?? '';
    name = json['name'] ?? '';
    dob = json['dob'] ?? '';
    age = json['age'] ?? '';
    gender = json['gender'] ?? 'Male';
    mobile = json['mobile'] ?? '';
    address = json['address'] ?? '';
    bloodGroup = json['bloodGroup'] ?? 'O+';
    diagnosis = json['diagnosis'] ?? '';
    symptoms = json['symptoms'] ?? '';
    opdType = json['opdType'] ?? 'Consultation';
    chargeType = json['chargeType'] ?? 'Cash';
    medicines = json['medicines'] ?? '';
    clinicalNotes = json['clinicalNotes'] ?? '';
    panchakarmaNotes = json['panchakarmaNotes'] ?? '';
    nextVisit = json['nextVisit'] ?? '';
    consultationFee = json['consultationFee'] ?? '500';
    medicineFee = json['medicineFee'] ?? '0';
    panchakarmaFee = json['panchakarmaFee'] ?? '0';
    discount = json['discount'] ?? '0';
    discountType = json['discountType'] ?? 'None';
    paymentMode = json['paymentMode'] ?? 'Cash';
    previousVisitDate = json['previousVisitDate'] ?? '';
    followUpReason = json['followUpReason'] ?? '';
    weight = json['weight']?.toString() ?? '';
  }
}
