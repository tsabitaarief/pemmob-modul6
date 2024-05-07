import 'dart:convert'; // fungsi import untuk mengonversi data JSON ke dalam Dart.
import 'package:flutter/material.dart'; // fungsi import untuk membangun interface pengguna.
import 'package:http/http.dart' as http; // fungsi import library http dari package http untuk melakukan permintaan HTTP.
import 'package:flutter_bloc/flutter_bloc.dart'; // fungsi import library flutter_bloc untuk menggunakan BLoC.

void main() {
  runApp(MyApp()); // menjalankan aplikasi Flutter.
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider( // BlocProvider dipakai untuk menyediakan UniversityCubit ke dalam widget tree.
      create: (context) => UniversityCubit(), // membuat instance dari UniversityCubit.
      child: MaterialApp(
        title: 'Daftar Universitas', 
        home: UniversityList(), // menampilkan UniversityList sebagai home screen.
      ),
    );
  }
}

class UniversityCubit extends Cubit<UniversityState> { // membuat class UniversityCubit extends Cubit dengan tipe state UniversityState.
  UniversityCubit() : super(UniversityInitial()); // menginisialisasi state awal.

  void fetchUniversities(String selectedCountry) async {
    emit(UniversityLoading()); // event UniversityLoading dikirimkan untuk menampilkan indikator loading.
    try {
      final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$selectedCountry'), // HTTP request dikirimkan untuk mendapatkan data universitas berdasarkan negara.
      );

      if (response.statusCode == 200) {
        final universities = json.decode(response.body); // mengambil data universitas dari response.
        emit(UniversityLoaded(universities)); // event UniversityLoaded dikirimkan dengan data universitas.
      } else {
        throw Exception('Gagal memuat universitas: ${response.reasonPhrase}'); // menampilkan exception apabila gagal memuat data universitas.
      }
    } catch (error) {
      emit(UniversityError('Error: $error')); // mengirimkan event UniversityError dengan pesan error.
    }
  }
}

// State untuk UniversityCubit
abstract class UniversityState {}

class UniversityInitial extends UniversityState {} // State awal untuk UniversityCubit.

class UniversityLoading extends UniversityState {} // State loading untuk UniversityCubit.

class UniversityLoaded extends UniversityState { // State loaded untuk UniversityCubit.
  final List universities; // daftar universitas.
  UniversityLoaded(this.universities); // Constructor dengan parameter universities.
}

class UniversityError extends UniversityState {
  final String errorMessage;
  UniversityError(this.errorMessage);
}

class UniversityList extends StatelessWidget {
  final List<String> _aseanCountries = ['Indonesia', 'Singapura', 'Malaysia', 'Thailand', 'Vietnam', 'Filipina']; // membuat daftar negara ASEAN.

  @override
  Widget build(BuildContext context) {
    final universityCubit = BlocProvider.of<UniversityCubit>(context); // mengambil instance UniversityCubit dari BlocProvider.

    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Universitas'), // membuat isi judul AppBar.
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0), // membuat padding untuk dropdown button.
            child: DropdownButton<String>(
              value: _aseanCountries[0], // mengatur nilai default pada dropdown.
              onChanged: (String? newValue) {
                if (newValue != null) {
                  universityCubit.fetchUniversities(newValue); // memanggil fetchUniversities saat dropdown berubah.
                }
              },
              items: _aseanCountries.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value), // mengatur tampilan teks pada dropdown.
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: BlocBuilder<UniversityCubit, UniversityState>( // widget yang sesuai dengan state UniversityCubit dibuat.
              builder: (context, state) {
                if (state is UniversityLoading) { // ketika state loading, maka akan menampilkan indikator loading.
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is UniversityError) { // ketika state error, maka akan menampilkan pesan error.
                  return Center(
                    child: Text(
                      state.errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                } else if (state is UniversityLoaded) { // ketika state loaded, maka akan menampilkan data universitas.
                  return ListView.builder(
                    itemCount: state.universities.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            state.universities[index]['name'],
                            style: TextStyle(fontSize: 18),
                          ),
                          subtitle: Text(
                            state.universities[index]['web_pages'][0],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Center(
                    child: Text('Pilih negara untuk melihat daftar universitas.'), // tampilan pesan default jika belum ada data yang dipilih.
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
