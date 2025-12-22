import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/TractorService/tractor_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/slide_route.dart';
import '../../../widgets/no_data_widget.dart';
import '../add_entities/add_close_payment.dart';
import '../add_entities/add_return.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ClientDetailsPage extends StatefulWidget {
  final int clientId;
  final String clientName;
  final String phone;

  const ClientDetailsPage({
    Key? key,
    required this.clientId,
    required this.clientName,
    required this.phone,
  }) : super(key: key);

  @override
  State<ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<ClientDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final tractorService = TractorService();

  bool isLoading = true;
  bool isExpanded = false;

  double totalBalance = 0;
  double totalEarned = 0;
  double totalAcres = 0;
  double totalReceived = 0;

  List<Map<String, dynamic>> active = [];
  List<Map<String, dynamic>> partial = [];
  List<Map<String, dynamic>> completed = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final data = await tractorService.getClientActivities(widget.clientId);
      setState(() {
        totalEarned = (data["totalAmountToBeReceived"] ?? 0).toDouble();
        totalReceived = (data["totalEarned"] ?? 0).toDouble();
        totalBalance = (data["totalAmountRemaining"] ?? 0).toDouble();
        totalAcres = (data["totalAcres"] ?? 0).toDouble();

        final status = data["statusWise"] ?? {};

        active = List<Map<String, dynamic>>.from(status["PENDING"] ?? []);
        partial = List<Map<String, dynamic>>.from(status["PARTIALLY_PAID"] ?? []);
        completed = List<Map<String, dynamic>>.from(status["PAID"] ?? []);

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _callClient() async {
    final Uri uri = Uri(scheme: 'tel', path: widget.phone);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // REQUIRED
      );

      if (!launched) throw Exception("Launch failed");

    } catch (e) {
      log("Call error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to make call"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendSMS() async {
    final Uri uri = Uri(
      scheme: 'sms',
      path: widget.phone,
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) throw Exception("SMS launch failed");
    } catch (e) {
      log("SMS error: $e");
      _showError();
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.phone;
    final message = Uri.encodeComponent("Hello ${widget.clientName},");
    final url = Uri.parse("https://wa.me/$phone?text=$message");

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception("Failed");
    } catch (e) {
      log("WhatsApp error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open WhatsApp"), backgroundColor: Colors.red),
      );
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Unable to open app"),
        backgroundColor: Colors.red,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = AppColors.fromTheme(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.clientName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.text),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchActivities();
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.green),
      )
          : Column(
        children: [
          const SizedBox(height: 10),

          // ---------- TOP STATS ----------
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCard("Total", "₹${totalEarned.toStringAsFixed(0)}", Colors.orange.shade700, colors),
                _buildInfoCard("Earned", "₹${totalReceived.toStringAsFixed(0)}", Colors.green.shade700, colors),
                _buildInfoCard("Balance", "₹${totalBalance.toStringAsFixed(0)}", Colors.red.shade700, colors),
                _buildInfoCard("Acres", "${totalAcres.toStringAsFixed(1)}", Colors.blue.shade700, colors),
              ],
            ),
          ),

          // ---------- Tabs ----------
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.green.shade700,
            labelColor: Colors.green.shade700,
            unselectedLabelColor: colors.text.withOpacity(0.6),
            tabs: const [
              Tab(text: "Active"),
              Tab(text: "Partially Paid"),
              Tab(text: "Completed"),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  color: Colors.green.shade600,
                  backgroundColor: colors.background,   // background circle color
                  onRefresh: _fetchActivities,
                  child: _buildPaymentList(active, colors , isDark),
                ),
                RefreshIndicator(
                  color:Colors.green.shade600,
                  backgroundColor: colors.background,   // background circle color
                  onRefresh: _fetchActivities,
                  child: _buildPaymentList(partial, colors ,isDark),
                ),
                RefreshIndicator(
                  color: Colors.green.shade600,
                  backgroundColor: colors.background,   // background circle color
                  onRefresh: _fetchActivities,
                  child: _buildPaymentList(completed, colors , isDark),
                ),
              ],
            ),
          ),
        ],
      ),

      // ------------------ TWO FLOATING BUTTONS ------------------
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // --- EXPANDED ACTIONS ---
          if (isExpanded) ...[
            // WhatsApp
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                heroTag: "whatsappBtn",
                mini: true,
                backgroundColor: Colors.green.shade800,
                onPressed: _openWhatsApp,
                child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
              ),
            ),

            // Call
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                heroTag: "callBtn",
                mini: true,
                backgroundColor: Colors.green.shade700,
                onPressed: _callClient,
                child: const Icon(Icons.call, color: Colors.white),
              ),
            ),

            // SMS
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                heroTag: "smsBtn",
                mini: true,
                backgroundColor: Colors.blue.shade700,
                onPressed: _sendSMS,
                child: const Icon(Icons.message, color: Colors.white),
              ),
            ),
          ],

          FloatingActionButton(
            heroTag: "expandBtn",
            backgroundColor: Colors.green.shade900,
            onPressed: () {
              setState(() => isExpanded = !isExpanded);
            },
            child: Icon(
              isExpanded ? Icons.close : Icons.perm_phone_msg, // main icon
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          FloatingActionButton(
            heroTag: "addBtn",
            backgroundColor: Colors.green,
            onPressed: () {
              Navigator.of(context).push(
                SlideFromRightRoute(
                  page: AddReturnPage(
                    clientId: widget.clientId,
                    clientName: widget.clientName,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),

    );
  }

  // -------------------- Payment List --------------------
  Widget _buildPaymentList(List<Map<String, dynamic>> list, AppColors colors , bool isDark) {
    if (list.isEmpty) {
      return NoDataWidget(
        message: "No Records found",
        isDark: isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = list[index];
        final statusData = _getStatusIcon(item["paymentStatus"] ?? "");

        return InkWell(
          onTap: () async {
            final updated = await Navigator.of(context).push(
              SlideFromRightRoute(
                page: PaymentDetailsPage(
                  activityId: item["id"],
                  title: item["notes"] ?? "Work",
                  totalAmount: (item["amountEarned"] ?? 0).toDouble(),
                  amountReceived: (item["amountPaid"] ?? 0).toDouble(),
                  date: item["activityDate"] ?? "",
                  acres: (item["acresWorked"] ?? 0).toDouble(),
                ),
              ),
            );

            if (updated == true) {
              setState(() => isLoading = true);
              _fetchActivities();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // ✓ Dynamic icon + color
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusData["bg"],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusData["icon"], color: statusData["color"]),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["notes"] ?? "Work",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${item["activityDate"]} • ${item["acresWorked"]} acres",
                        style: TextStyle(
                          color: colors.text.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${item["amountEarned"]}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusData["color"],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   item["paymentStatus"] ?? "",
                    //   style: TextStyle(
                    //     color: statusData["color"],
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 13,
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // -------------------- Info Card --------------------
  Widget _buildInfoCard(String title, String value, Color color, AppColors colors) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  color: colors.text.withOpacity(0.6),
                  fontSize: 13,
                )),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _getStatusIcon(String status) {
  switch (status) {
    case "PENDING":
      return {
        "icon": Icons.timelapse,
        "color": Colors.orange.shade700,
        "bg": Colors.orange.withOpacity(0.15),
      };
    case "PARTIALLY_PAID":
      return {
        "icon": Icons.payments,
        "color": Colors.blue.shade700,
        "bg": Colors.blue.withOpacity(0.15),
      };
    case "PAID":
      return {
        "icon": Icons.check_circle,
        "color": Colors.green.shade700,
        "bg": Colors.green.withOpacity(0.15),
      };
    default:
      return {
        "icon": Icons.work,
        "color": Colors.grey.shade700,
        "bg": Colors.grey.withOpacity(0.15),
      };
  }
}
