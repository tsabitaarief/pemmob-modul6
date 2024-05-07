import 'dart:convert'; // fungsi import untuk mengonversi data JSON ke dalam Dart.
import 'package:flutter/material.dart'; // fungsi import untuk membangun interface pengguna.
import 'package:http/http.dart' as http; // fungsi import library http dari package http untuk melakukan permintaan HTTP.
import 'package:provider/provider.dart'; // fungsi import package provider untuk manajemen state.

void main() {
  runApp(
    ChangeNotifierProvider( // class ChangeNotifierProvider dibuat untuk memberikan akses ke UniversityProvider ke seluruh aplikasi.
      create: (_) => UniversityProvider(), // pembuatan instance dari UniversityProvider.
      child: MyApp(), // aplikasi utama MyApp dijalankan sebagai child dari ChangeNotifierProvider.
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<String> _aseanCountries = ['Indonesia', 'Singapura', 'Malaysia', 'Thailand', 'Vietnam', 'Filipina']; // membuat list yang berisi negara asean.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Universitas', // isi judul aplikasi.
      home: Scaffold(
        appBar: AppBar(
          title: Text('Daftar Universitas'), // isi judul AppBar.
          centerTitle: true, // memposisikan judul AppBar agar berada di tengah.
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // membuat child widgets yang disusun secara horizontal di tengah.
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0), // menambahkan padding vertical 20.0.
              child: DropdownButton<String>(
                value: Provider.of<UniversityProvider>(context).selectedCountry, // menyatakan isi dropdown berasal dari selectedCountry pada UniversityProvider.
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    Provider.of<UniversityProvider>(context, listen: false).setSelectedCountry(newValue); // memperbarui isi selectedCountry saat dropdown dipilih.
                  }
                },
                items: _aseanCountries.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value), // mengisi teks pada dropdown menggunakan value yang berasal dari selectedCounrty.
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: UniversityList(), // tampilan UniversityList sebagai child widget yang dapat diperluas.
            ),
          ],
        ),
      ),
    );
  }
}

class UniversityProvider extends ChangeNotifier {
  List _universities = []; // membuat list yang menampung data universitas.
  bool _isLoading = false; // membuat status loading.
  String _errorMessage = ''; // membuat pesan kesalahan jika terjadi error.
  String _selectedCountry = 'Indonesia'; // setting default di combobox sebelum memilih negara.

  List get universities => _universities; // fungsi get untuk universities yang berisi daftar universitas.
  bool get isLoading => _isLoading; // fungsi get untuk isLoading.
  String get errorMessage => _errorMessage; // fungsi get untuk errorMessage.
  String get selectedCountry => _selectedCountry; // fungsi get untuk selectedCountry.

  void setSelectedCountry(String country) {
    _selectedCountry = country; // setting selectedCountry berdasarkan negara yang dipilih.
    _fetchUniversities(); // menampung daftar universitas berdasarkan negara yang dipilih.
    notifyListeners(); // notifikasi kepada listener bahwa state telah berubah.
  }

  Future<void> _fetchUniversities() async {
    _isLoading = true; // isLoading diubah menjadi true saat memuat data.
    _errorMessage = ''; // mengosongkan errorMessage sebelum melakukan permintaan HTTP.

    try {
      final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$_selectedCountry'), // Memuat data universitas berdasarkan negara.
      );

      if (response.statusCode == 200) {
        _universities = json.decode(response.body); // Mendecode data JSON dan menyimpannya ke dalam list _universities.
        _isLoading = false; // Mengubah isLoading menjadi false setelah data berhasil dimuat.
      } else {
        throw Exception('Gagal memuat universitas: ${response.reasonPhrase}'); // Melempar exception jika gagal memuat data universitas.
      }
    } catch (error) {
      _errorMessage = 'Error: $error'; // Mengatur errorMessage jika terjadi error.
      _isLoading = false; // Mengubah isLoading menjadi false setelah terjadi error.
    }

    notifyListeners(); // Memberitahukan kepada listener bahwa state telah berubah.
  }
}

class UniversityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var universityProvider = Provider.of<UniversityProvider>(context); // Mendapatkan instance UniversityProvider.

    if (universityProvider.isLoading) { // Jika isLoading true, tampilkan indicator loading.
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (universityProvider.errorMessage.isNotEmpty) { // Jika terdapat errorMessage, tampilkan pesan error.
      return Center(
        child: Text(
          universityProvider.errorMessage,
          style: TextStyle(color: Colors.red),
        ),
      );
    } else if (universityProvider.universities.isEmpty) { // Jika universities kosong, tampilkan pesan tidak ada data.
      return Center(
        child: Text('Tidak ada universitas yang ditemukan.'),
      );
    } else {
      return ListView.builder( // Jika ada data universitas, tampilkan dalam ListView.
        itemCount: universityProvider.universities.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(
                universityProvider.universities[index]['name'],
                style: TextStyle(fontSize: 18),
              ),
              subtitle: Text(
                universityProvider.universities[index]['web_pages'][0],
              ),
            ),
          );
        },
      );
    }
  }
}
