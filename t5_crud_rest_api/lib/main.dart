import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'APLIKASI MANAJEMEN USER',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6558C3),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F2FA),
      ),
      home: const UserPage(),
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserService _service = UserService();

  late Future<List<UserModel>> _usersFuture;
  List<UserModel> _users = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _usersFuture = _service.getUsers();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<Map<String, String>?> _showUserForm({
    UserModel? user,
  }) async {
    final formKey = GlobalKey<FormState>();

    final firstNameController = TextEditingController(
      text: user?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: user?.lastName ?? '',
    );
    final emailController = TextEditingController(
      text: user?.email ?? '',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            user == null ? 'Tambah User' : 'Edit User',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Depan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama depan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Belakang',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama belakang wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(value.trim())) {
                        return 'Masukkan email yang valid';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    {
                      'first_name':
                          firstNameController.text.trim(),
                      'last_name':
                          lastNameController.text.trim(),
                      'email': emailController.text.trim(),
                    },
                  );
                }
              },
              child: Text(user == null ? 'Simpan' : 'Update'),
            ),
          ],
        );
      },
    );


    return result;
  }

  Future<void> _createUser() async {
    final input = await _showUserForm();
    if (input == null || !mounted) return;

    setState(() => _loading = true);

    try {
      final created = await _service.createUser(
        firstName: input['first_name']!,
        lastName: input['last_name']!,
        email: input['email']!,
      );

      if (!mounted) return;

      // ReqRes adalah API latihan; perubahan ditampilkan lokal.
      setState(() {
        _users = [
          UserModel(
            id: created.id,
            email: input['email']!,
            firstName: input['first_name']!,
            lastName: input['last_name']!,
            avatar: created.avatar,
          ),
          ..._users,
        ];
        _usersFuture = Future.value(_users);
      });

      _showMessage('User berhasil ditambahkan!');
    } catch (e) {
      _showMessage('Gagal menambahkan user: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editUser(UserModel user) async {
    final input = await _showUserForm(user: user);
    if (input == null || !mounted) return;

    setState(() => _loading = true);

    try {
      await _service.updateUser(
        id: user.id,
        firstName: input['first_name']!,
        lastName: input['last_name']!,
        email: input['email']!,
      );

      if (!mounted) return;

      setState(() {
        _users = _users.map((item) {
          if (item.id != user.id) return item;

          return UserModel(
            id: user.id,
            email: input['email']!,
            firstName: input['first_name']!,
            lastName: input['last_name']!,
            avatar: user.avatar,
          );
        }).toList();

        _usersFuture = Future.value(_users);
      });

      _showMessage('Data user berhasil diperbarui!');
    } catch (e) {
      _showMessage('Gagal memperbarui user: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text(
          'Yakin ingin menghapus ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);

    try {
      await _service.deleteUser(user.id);

      if (!mounted) return;

      setState(() {
        _users.removeWhere((item) => item.id == user.id);
        _usersFuture = Future.value(_users);
      });

      _showMessage('User berhasil dihapus!');
    } catch (e) {
      _showMessage('Gagal menghapus user: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _loadUsers();
    });

    try {
      final result = await _usersFuture;
      if (!mounted) return;

      setState(() => _users = result);
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6558C3),
        foregroundColor: Colors.white,
        title: const Text(
          'CRUD REST API',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang data',
            onPressed: _loading ? null : _refreshUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _createUser,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah User'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E3FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen Pengguna',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF44358F),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Kelola data pengguna melalui REST API.',
                  style: TextStyle(color: Color(0xFF554B76)),
                ),
                SizedBox(height: 8),
                Text(
                  'GET  •  POST  •  PUT  •  DELETE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    _users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Memuat data pengguna...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError && _users.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 52,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Gagal memuat data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _refreshUsers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_users.isEmpty && snapshot.hasData) {
                  _users = snapshot.data!;
                }

                if (_users.isEmpty) {
                  return const Center(
                    child: Text('Belum ada data pengguna.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              radius: 27,
                              backgroundColor:
                                  const Color(0xFFE8E3FF),
                              backgroundImage: user.avatar.isNotEmpty
                                  ? NetworkImage(user.avatar)
                                  : null,
                              child: user.avatar.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Color(0xFF6558C3),
                                    )
                                  : null,
                            ),
                            title: Text(
                              user.fullName.isEmpty
                                  ? 'User ${user.id}'
                                  : user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                '${user.email}\nID: ${user.id}',
                              ),
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Aksi pengguna',
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editUser(user);
                                } else if (value == 'delete') {
                                  _deleteUser(user);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Hapus'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}