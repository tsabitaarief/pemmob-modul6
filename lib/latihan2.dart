import 'package:flutter/material.dart'; // fungsi import untuk mengonversi data JSON ke dalam Dart.
import 'dart:convert'; // fungsi import untuk membangun interface pengguna.
import 'package:http/http.dart' as http; // fungsi import library http dari package http untuk melakukan permintaan HTTP.
import 'package:flutter_bloc/flutter_bloc.dart'; // fungsi import library flutter_bloc untuk menggunakan BLoC.

class University { // Model untuk menyimpan data universitas
  final String name;
  final List<String> webPages;

  University({
    required this.name,
    required this.webPages,
  });

  factory University.fromJson(Map<String, dynamic> json) { // Factory method untuk membuat instance University dari JSON
    return University(
      name: json['name'],
      webPages: List<String>.from(json['web_pages']),
    );
  }
}

// Events
abstract class UniversityEvent {}

class FetchUniversitiesEvent extends UniversityEvent {
  final String country;
  FetchUniversitiesEvent(this.country);
}

// Bloc
class UniversityBloc extends Bloc<UniversityEvent, List<University>> {
  UniversityBloc() : super([]) { // Mengatur handler untuk event FetchUniversitiesEvent
    on<FetchUniversitiesEvent>(_fetchUniversities);
  }

// Fungsi async untuk melakukan fetch data universitas dari API
  Future<void> _fetchUniversities(
    FetchUniversitiesEvent event,
    Emitter<List<University>> emit,
  ) async {
    try {
      final universities = await _fetchUniversitiesFromApi(event.country);
      emit(universities);
    } catch (e) {
      print('Error: $e');
      emit([]);
    }
  }

// Fungsi async untuk mengambil data universitas dari API
  Future<List<University>> _fetchUniversitiesFromApi(String country) async {
    final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$country'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
       // Mapping data JSON menjadi list University
      return data.map((json) => University.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat universitas');
    }
  }
}

void main() {
  runApp(MyApp());  // menjalankan aplikasi Flutter.
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        // Membuat provider Bloc untuk UniversityBloc
        create: (context) => UniversityBloc(),
        // Menetapkan UniversitiesPage sebagai child dari BlocProvider
        child: UniversitiesPage(),
      ),
    );
  }
}

class UniversitiesPage extends StatefulWidget {
  @override
  _UniversitiesPageState createState() => _UniversitiesPageState();
}

class _UniversitiesPageState extends State<UniversitiesPage> {
  final List<String> _aseanCountries = ['Indonesia', 'Singapura', 'Malaysia', 'Thailand', 'Vietnam', 'Filipina']; // membuat daftar negara ASEAN.

  String _selectedCountry = 'Indonesia'; //mengatur pilihan default menjadi indonesia

  @override
  void initState() {
    super.initState(); 
    // Memanggil event FetchUniversitiesEvent pada initState
    context.read<UniversityBloc>().add(FetchUniversitiesEvent(_selectedCountry));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Universitas'), // membuat isi judul AppBar.
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // membuat padding untuk dropdown button.
            child: DropdownButton<String>(
              value: _selectedCountry,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCountry = newValue!;
                  context
                      .read<UniversityBloc>()
                      .add(FetchUniversitiesEvent(newValue)); // memanggil fetchUniversities saat dropdown berubah.
                });
              },
              items: _aseanCountries.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value), // mengatur tampilan teks pada dropdown.
                );
              }).toList(),
            ),
          ),
          BlocBuilder<UniversityBloc, List<University>>(
            builder: (context, universities) {
              if (universities.isEmpty) { 
                return CircularProgressIndicator(); //menampilkan CircularProgressIndicator jika tidak ada data.
              }
              return Expanded(
                child: ListView.builder( //membuat listview yang berisi daftar universitas
                  itemCount: universities.length,
                  itemBuilder: (context, index) {
                    final university = universities[index];
                    return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            university.name,
                            style: TextStyle(fontSize: 18),
                          ),
                          subtitle: Text(
                            university.webPages.isNotEmpty ? university.webPages[0] : '',
                          ),
                        ),
                      );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}