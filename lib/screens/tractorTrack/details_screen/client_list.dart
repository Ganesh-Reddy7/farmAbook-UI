import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../widgets/no_data_widget.dart';
import '../add_entities/add_client.dart';
import 'client_details.dart';
import '../../../services/TractorService/tractor_service.dart';

class ViewClientsPage extends StatefulWidget {
  const ViewClientsPage({Key? key}) : super(key: key);

  @override
  State<ViewClientsPage> createState() => _ViewClientsPageState();
}

class _ViewClientsPageState extends State<ViewClientsPage> {
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> filteredClients = [];

  bool isSearching = false;
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();
  final tractorService = TractorService();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  // -------------------- Load Clients --------------------
  Future<void> _loadClients() async {
    try {
      final data = await tractorService.getClients();
      log("Clients Loaded: $data");

      setState(() {
        clients = data.map((c) {
          return {
            "id": c["id"],
            "name": c["name"],
            "amount": c["pendingAmount"],
            "area": c["totalAcresWorked"],
            "phone": c["phone"],
          };
        }).toList();

        filteredClients = List.from(clients);
      });
    } catch (e) {
      debugPrint("Error loading clients: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // -------------------- Search Logic --------------------
  void _searchClient(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredClients = List.from(clients);
      } else {
        filteredClients = clients
            .where((client) =>
            (client['name'] as String)
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness != Brightness.dark;
    final colors = _AppColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(colors),
      body: isLoading
          ? Center(
            child: CircularProgressIndicator(color: Colors.green.shade600),
      )
          : _buildClientList(colors , isDark),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          "Add Client",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClientPage()),
          );

          if (added == true) {
            setState(() => isLoading = true);
            await _loadClients();
          }
        },
      ),
    );
  }
  // -------------------- APPBAR --------------------
  AppBar _buildAppBar(_AppColors colors) {
    return AppBar(
      elevation: 0,
      backgroundColor: colors.background,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.text),
        onPressed: () => Navigator.pop(context),
      ),
      title: isSearching
          ? TextField(
        controller: searchController,
        autofocus: true,
        onChanged: _searchClient,
        style: TextStyle(color: colors.text),
        cursorColor: Colors.green,
        decoration: InputDecoration(
          hintText: "Search clients...",
          hintStyle: TextStyle(color: colors.text.withOpacity(0.6)),
          border: InputBorder.none,
        ),
      )
          : Text(
        "Clients",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.text,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isSearching ? Icons.close : Icons.search,
            color: colors.text.withOpacity(0.8),
          ),
          onPressed: () {
            setState(() {
              if (isSearching) {
                searchController.clear();
                filteredClients = List.from(clients);
              }
              isSearching = !isSearching;
            });
          },
        ),
      ],
    );
  }

  // -------------------- CLIENT LIST WITH REFRESH --------------------
  Widget _buildClientList(_AppColors colors , bool isDark) {
    if (filteredClients.isEmpty) {
      return NoDataWidget(
        message: "No Client Data found",
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      color: Colors.green.shade700,
      backgroundColor: colors.background.withOpacity(0.9),
      onRefresh: () async {
        await _loadClients();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filteredClients.length,
        separatorBuilder: (_, __) => Divider(
          height: 0,
          color: colors.text.withOpacity(0.08),
          indent: 64,
        ),
        itemBuilder: (context, index) {
          final client = filteredClients[index];

          return InkWell(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientDetailsPage(
                    clientId: client["id"],
                    clientName: client["name"],
                    phone: client["phone"],
                  ),
                ),
              );

              if (updated == true) {
                await _loadClients();
              }
            },
            child: _buildClientTile(client, colors),
          );
        },
      ),
    );
  }

  // -------------------- CLIENT TILE --------------------
  Widget _buildClientTile(Map<String, dynamic> client, _AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              client["name"][0].toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client["name"],
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "₹${client["amount"]} • ${client["area"]} acres",
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.text.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          Icon(Icons.chevron_right, color: colors.text.withOpacity(0.4))
        ],
      ),
    );
  }
}

// -------------------- THEME HELPERS --------------------
class _AppColors {
  final Color background;
  final Color text;

  _AppColors(bool isDark)
      : background = isDark ? const Color(0xFF081712) : const Color(0xFFF5F5F5),
        text = isDark ? Colors.white : const Color(0xFF1A1A1A);
}
