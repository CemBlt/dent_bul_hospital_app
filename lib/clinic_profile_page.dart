import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicProfilePage extends StatefulWidget {
  final String clinicId;
  const ClinicProfilePage({super.key, required this.clinicId});

  @override
  State<ClinicProfilePage> createState() => _ClinicProfilePageState();
}

class _ClinicProfilePageState extends State<ClinicProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Clinic data
  Map<String, dynamic>? _clinicData;
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _appointments = [];

  bool _isLoading = true;
  bool _isUpdating = false;

  final _clinicNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _doctorCountController = TextEditingController();
  final _languagesController = TextEditingController();

  // Form state
  bool _hasDisabledAccess = false;
  bool _is247 = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  // Bu metodu eklemeniz gerekiyor:
  Future<void> _saveProfile() async {
    try {
      await _supabase
          .from('clinics')
          .update({
            'clinic_name': _clinicNameController.text,
            'city': _cityController.text,
            'district': _districtController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'doctor_count': int.tryParse(_doctorCountController.text),
            'languages': _languagesController.text,
            'has_disabled_access': _hasDisabledAccess,
          })
          .eq('id', widget.clinicId);

      Navigator.pop(context);
      await _loadClinicData(); // Refresh data

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profil güncellendi')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Güncelleme hatası: $e')));
    }
  }

  Future<void> _loadClinicData() async {
    try {
      setState(() => _isLoading = true);

      // Load clinic data
      final clinicResponse = await _supabase
          .from('clinics')
          .select()
          .eq('id', widget.clinicId)
          .single();

      // Load doctors
      final doctorsResponse = await _supabase
          .from('clinic_doctors')
          .select()
          .eq('clinic_id', widget.clinicId);

      //Load appointments
      final appointmentsResponse = await _supabase
          .from('appointments')
          .select('''
      *,
      users(name,phone),
      clinic_doctors(name,specialty)
      ''')
          .eq('clinic_id', widget.clinicId)
          .order('appointment_date', ascending: true);

      setState(() {
        _clinicData = clinicResponse;
        _doctors = List<Map<String, dynamic>>.from(doctorsResponse);
        _appointments = List<Map<String, dynamic>>.from(appointmentsResponse);
        _isLoading = false; //
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Veri yüklenirken hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xff21254A),
        appBar: AppBar(
          title: Text('Klinik Profili'),
          backgroundColor: Color(0xff21254A),
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_clinicData == null) {
      return Scaffold(
        backgroundColor: Color(0xff21254A),
        appBar: AppBar(
          title: Text('Klinik Profili'),
          backgroundColor: Color(0xff21254A),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            'Klinik bulunamadı',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Color(0xff21254A),
      appBar: AppBar(
        title: Text('Klinik Profili'),
        backgroundColor: Color(0xff21254A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _showEditDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClinicInfo(),
            SizedBox(height: 20),
            _buildWorkingHours(),
            SizedBox(height: 20),
            _buildSpecialties(),
            SizedBox(height: 20),
            _buildDoctorsSection(),
            SizedBox(height: 20),
            _buildAppointmentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicInfo() {
    return _buildSection(
      title: 'Klinik Bilgileri',
      children: [
        _buildInfoRow(
          'Klinik Adı',
          _clinicData!['clinic_name'] ?? 'Belirtilmemiş',
        ),
        _buildInfoRow('Şehir', _clinicData!['city'] ?? 'Belirtilmemiş'),
        _buildInfoRow('İlçe', _clinicData!['district'] ?? 'Belirtilmemiş'),
        _buildInfoRow('Adres', _clinicData!['address'] ?? 'Belirtilmemiş'),
        _buildInfoRow('Telefon', _clinicData!['phone'] ?? 'Belirtilmemiş'),
        _buildInfoRow('E-posta', _clinicData!['email'] ?? 'Belirtilmemiş'),
        _buildInfoRow(
          'Doktor Sayısı',
          _clinicData!['doctor_count']?.toString() ?? 'Belirtilmemiş',
        ),
        _buildInfoRow(
          'Hizmet Dilleri',
          _clinicData!['languages'] ?? 'Belirtilmemiş',
        ),
        _buildInfoRow(
          'Engelli Erişimi',
          _clinicData!['has_disabled_access'] == true ? 'Var' : 'Yok',
        ),
        _buildInfoRow('Durum', _clinicData!['status'] ?? 'Belirtilmemiş'),
      ],
    );
  }

  Widget _buildWorkingHours() {
    return _buildSection(
      title: 'Çalışma Saatleri',
      children: [
        _buildInfoRow(
          '7/24 Hizmet',
          _clinicData!['is_247'] == true ? 'Evet' : 'Hayır',
        ),
        if (_clinicData!['is_247'] != true) ...[
          _buildInfoRow(
            'Başlangıç Saati',
            _clinicData!['start_time'] ?? 'Belirtilmemiş',
          ),
          _buildInfoRow(
            'Bitiş Saati',
            _clinicData!['end_time'] ?? 'Belirtilmemiş',
          ),
        ],
      ],
    );
  }

  Widget _buildSpecialties() {
    final specialties = _clinicData!['specialties'] as List<dynamic>? ?? [];
    return _buildSection(
      title: 'Uzmanlık Alanları',
      children: [
        if (specialties.isEmpty)
          Text(
            'Uzmanlık alanı belirtilmemiş',
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specialties
                .map(
                  (specialty) => Chip(
                    label: Text(specialty),
                    backgroundColor: Colors.pink[200],
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildDoctorsSection() {
    return _buildSection(
      title: 'Doktorlar',
      children: [
        if (_doctors.isEmpty)
          Text('Doktor bilgisi yok', style: TextStyle(color: Colors.grey))
        else
          ..._doctors
              .map(
                (doctor) => Card(
                  color: Color(0xff31274F),
                  child: ListTile(
                    title: Text(
                      doctor['name'] ?? 'İsimsiz',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${doctor['title'] ?? ''} ${doctor['specialty'] ?? ''}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDoctorDialog(doctor),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDoctor(doctor['id']),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _showAddDoctorDialog(),
          icon: Icon(Icons.add),
          label: Text('Doktor Ekle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink[200],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsSection() {
    return _buildSection(
      title: 'Randevular',
      children: [
        if (_appointments.isEmpty)
          Text('Randevu yok', style: TextStyle(color: Colors.grey))
        else
          ..._appointments
              .map(
                (appointment) => Card(
                  color: Color(0xff31274F),
                  child: ListTile(
                    title: Text(
                      '${appointment['users']['name']} - ${appointment['clinic_doctors']['name']}',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${appointment['appointment_date']} ${appointment['appointment_time']}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: _buildStatusChip(appointment['status']),
                  ),
                ),
              )
              .toList(),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xff31274F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color,
      labelStyle: TextStyle(color: Colors.white, fontSize: 10),
    );
  }

  void _showEditDialog() {
    // Mevcut verileri controller'lara yükle
    _loadFormData();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _clinicNameController,
                decoration: InputDecoration(labelText: 'Klinik Adı'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'Şehir'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _districtController,
                decoration: InputDecoration(labelText: 'İlçe'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Telefon'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-posta'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _doctorCountController,
                decoration: InputDecoration(labelText: 'Doktor Sayısı'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _languagesController,
                decoration: InputDecoration(labelText: 'Hizmet Dilleri'),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _hasDisabledAccess,
                    onChanged: (value) {
                      setState(() => _hasDisabledAccess = value ?? false);
                    },
                  ),
                  Text('Engelli Erişimi'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(onPressed: () => _saveProfile(), child: Text('Kaydet')),
        ],
      ),
    );
  }

  void _showAddDoctorDialog() {
    final _nameController = TextEditingController();
    String? _selectedSpecialty;
    String? _selectedTitle;
    String? _selectedGender;
    List<String> _selectedDays = [];
    TimeOfDay? _startTime;
    TimeOfDay? _endTime;

    final specialties = [
      'Ağız, Diş ve Çene Cerrahisi',
      'Ağız, Diş ve Çene Radyolojisi',
      'Endodonti',
      'Ortodonti',
      'Pedodonti (Çocuk Diş Hekimliği)',
      'Periodontoloji',
      'Protetik Diş Tedavisi',
      'Restoratif Diş Tedavisi',
      'Estetik Diş Hekimliği',
      'İmplantoloji',
      'Dijital Diş Hekimliği',
      'Gülüş Tasarımı',
      'Ağız Kokusu Tedavisi',
      'Diş Beyazlatma',
      'Diş Sıkma / Çene Eklemi Tedavisi',
    ];

    final titles = [
      'Prof. Dr.',
      'Doç. Dr.',
      'Dr. Öğr. Üyesi',
      'Uzm. Dr.',
      'Dr. Dt.',
      'Dt.',
    ];

    final genders = ['Erkek', 'Kadın', 'Diğer'];
    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Yeni Doktor Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Ad Soyad *'),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  decoration: InputDecoration(labelText: 'Uzmanlık Alanı'),
                  items: specialties
                      .map(
                        (specialty) => DropdownMenuItem(
                          value: specialty,
                          child: Text(specialty),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => _selectedSpecialty = value);
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedTitle,
                  decoration: InputDecoration(labelText: 'Unvan'),
                  items: titles
                      .map(
                        (title) =>
                            DropdownMenuItem(value: title, child: Text(title)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => _selectedTitle = value);
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(labelText: 'Cinsiyet'),
                  items: genders
                      .map(
                        (gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => _selectedGender = value);
                  },
                ),
                SizedBox(height: 10),
                Text(
                  'Çalışma Günleri:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  children: days
                      .map(
                        (day) => FilterChip(
                          label: Text(day),
                          selected: _selectedDays.contains(day),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => _startTime = time);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _startTime != null
                                ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                                : 'Başlangıç Saati',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _endTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => _endTime = time);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _endTime != null
                                ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                                : 'Bitiş Saati',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ad Soyad zorunludur')),
                  );
                  return;
                }

                try {
                  await _supabase.from('clinic_doctors').insert({
                    'clinic_id': widget.clinicId,
                    'name': _nameController.text,
                    'specialty': _selectedSpecialty,
                    'title': _selectedTitle,
                    'gender': _selectedGender,
                    'working_days': _selectedDays,
                    'start_time': _startTime != null
                        ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                        : null,
                    'end_time': _endTime != null
                        ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                        : null,
                  });

                  Navigator.pop(context);
                  await _loadClinicData(); // Refresh data

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Doktor eklendi')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Doktor eklenirken hata: $e')),
                  );
                }
              },
              child: Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDoctorDialog(Map<String, dynamic> doctor) {
    final _nameController = TextEditingController(text: doctor['name'] ?? '');
    String? _selectedSpecialty = doctor['specialty'];
    String? _selectedTitle = doctor['title'];
    String? _selectedGender = doctor['gender'];
    List<String> _selectedDays = List<String>.from(
      doctor['working_days'] ?? [],
    );
    TimeOfDay? _startTime;
    TimeOfDay? _endTime;

    // Parse time strings to TimeOfDay
    if (doctor['start_time'] != null) {
      final startParts = doctor['start_time'].split(':');
      _startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
    }
    if (doctor['end_time'] != null) {
      final endParts = doctor['end_time'].split(':');
      _endTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
    }

    final specialties = [
      'Ağız, Diş ve Çene Cerrahisi',
      'Ağız, Diş ve Çene Radyolojisi',
      'Endodonti',
      'Ortodonti',
      'Pedodonti (Çocuk Diş Hekimliği)',
      'Periodontoloji',
      'Protetik Diş Tedavisi',
      'Restoratif Diş Tedavisi',
      'Estetik Diş Hekimliği',
      'İmplantoloji',
      'Dijital Diş Hekimliği',
      'Gülüş Tasarımı',
      'Ağız Kokusu Tedavisi',
      'Diş Beyazlatma',
      'Diş Sıkma / Çene Eklemi Tedavisi',
    ];

    final titles = [
      'Prof. Dr.',
      'Doç. Dr.',
      'Dr. Öğr. Üyesi',
      'Uzm. Dr.',
      'Dr. Dt.',
      'Dt.',
    ];

    final genders = ['Erkek', 'Kadın', 'Diğer'];
    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Doktor Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Ad Soyad *'),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  decoration: InputDecoration(labelText: 'Uzmanlık Alanı'),
                  items: specialties
                      .map(
                        (specialty) => DropdownMenuItem(
                          value: specialty,
                          child: Text(specialty),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => _selectedSpecialty = value);
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedTitle,
                  decoration: InputDecoration(labelText: 'Unvan'),
                  items: titles
                      .map(
                        (title) =>
                            DropdownMenuItem(value: title, child: Text(title)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => _selectedTitle = value);
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(labelText: 'Cinsiyet'),
                  items: genders
                      .map(
                        (gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => _selectedGender = value);
                  },
                ),
                SizedBox(height: 10),
                Text(
                  'Çalışma Günleri:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  children: days
                      .map(
                        (day) => FilterChip(
                          label: Text(day),
                          selected: _selectedDays.contains(day),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => _startTime = time);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _startTime != null
                                ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                                : 'Başlangıç Saati',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _endTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => _endTime = time);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _endTime != null
                                ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                                : 'Bitiş Saati',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ad Soyad zorunludur')),
                  );
                  return;
                }

                try {
                  await _supabase
                      .from('clinic_doctors')
                      .update({
                        'name': _nameController.text,
                        'specialty': _selectedSpecialty,
                        'title': _selectedTitle,
                        'gender': _selectedGender,
                        'working_days': _selectedDays,
                        'start_time': _startTime != null
                            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                            : null,
                        'end_time': _endTime != null
                            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                            : null,
                      })
                      .eq('id', doctor['id']);

                  Navigator.pop(context);
                  await _loadClinicData(); // Refresh data

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Doktor güncellendi')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Doktor güncellenirken hata: $e')),
                  );
                }
              },
              child: Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDoctor(String doctorId) async {
    try {
      await _supabase.from('clinic_doctors').delete().eq('id', doctorId);

      await _loadClinicData(); // Refresh data

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Doktor silindi')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Doktor silinirken hata: $e')));
    }
  }

  void _loadFormData() {
    if (_clinicData != null) {
      _clinicNameController.text = _clinicData!['clinic_name'] ?? '';
      _cityController.text = _clinicData!['city'] ?? '';
      _districtController.text = _clinicData!['district'] ?? '';
      _phoneController.text = _clinicData!['phone'] ?? '';
      _emailController.text = _clinicData!['email'] ?? '';
      _doctorCountController.text =
          _clinicData!['doctor_count']?.toString() ?? '';
      _languagesController.text = _clinicData!['languages'] ?? '';
      _hasDisabledAccess = _clinicData!['has_disabled_access'] == true;
      _is247 = _clinicData!['is_247'] == true;
    }
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _doctorCountController.dispose();
    _languagesController.dispose();
    super.dispose();
  }
}
