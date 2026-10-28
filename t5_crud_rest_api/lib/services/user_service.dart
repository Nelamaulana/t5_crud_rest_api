import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user_model.dart';

class UserService {
  static const String _baseUrl = 'https://reqres.in/api/users';

  // API key untuk akses gratis ReqRes.
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'x-api-key': 'reqres-free-v1',
  };

  // READ: mengambil daftar user (GET)
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl?page=1'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            jsonDecode(response.body) as Map<String, dynamic>;

        final List<dynamic> data = jsonData['data'] as List<dynamic>;

        return data
            .map(
              (item) => UserModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }

      throw Exception(
        'Gagal mengambil data. HTTP ${response.statusCode}: '
        '${response.body}',
      );
    } on SocketException {
      throw Exception(
        'Tidak ada koneksi internet. Periksa jaringan kamu.',
      );
    } on http.ClientException {
      throw Exception(
        'Tidak dapat terhubung ke server API.',
      );
    } on FormatException {
      throw Exception('Format data dari server tidak valid.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // CREATE: menambahkan user (POST)
  Future<UserModel> createUser({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers,
            body: jsonEncode({
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 201) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        return UserModel.fromJson(data);
      }

      throw Exception(
        'Gagal menambahkan user. HTTP ${response.statusCode}: '
        '${response.body}',
      );
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server API.');
    } on FormatException {
      throw Exception('Format respons server tidak valid.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // UPDATE: mengubah data user (PUT)
  Future<UserModel> updateUser({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/$id'),
            headers: _headers,
            body: jsonEncode({
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        data['id'] ??= id;

        return UserModel.fromJson(data);
      }

      throw Exception(
        'Gagal mengubah user. HTTP ${response.statusCode}: '
        '${response.body}',
      );
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server API.');
    } on FormatException {
      throw Exception('Format respons server tidak valid.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // DELETE: menghapus user
  Future<void> deleteUser(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 20));

      // HTTP 204 adalah respons sukses standar untuk DELETE.
      if (response.statusCode == 204 ||
          response.statusCode == 200) {
        return;
      }

      throw Exception(
        'Gagal menghapus user. HTTP ${response.statusCode}: '
        '${response.body}',
      );
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server API.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}