import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutterx/flutterx.dart';
import 'package:intl/intl.dart';
import 'package:mis_portal/src/admin/widget/svg_icon.dart';
import 'package:mis_portal/src/ingrid/constant/color.dart';
import 'package:mis_portal/src/ingrid/constant/icons.dart';
import 'package:mis_portal/src/ingrid/constant/theme.dart';
import 'package:mis_portal/src/ingrid/models/report_logs.dart';
import 'package:mis_portal/src/ingrid/models/users.dart';
import 'package:mis_portal/src/ingrid/mysql/report_logs_db.dart';
import 'package:mis_portal/src/ingrid/mysql/reports_db.dart';
import 'package:mis_portal/src/ingrid/mysql/users_db.dart';
import 'package:mis_portal/src/ingrid/shared_preferences/user_shared_pref.dart';
import 'package:mis_portal/src/ingrid/utils/extension.dart';
import 'package:mis_portal/src/ingrid/view/reports/details.dart';
import 'package:mis_portal/src/ingrid/widget/button.dart';
import 'package:mis_portal/src/ingrid/widget/common_widget.dart';
import 'package:mis_portal/src/ingrid/widget/datatable.dart';
import 'package:mis_portal/src/ingrid/widget/title.dart';
import 'package:mis_portal/src/ingrid/models/reportss.dart';

@RoutePage()
class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  // logined user
  final int? userIdLogin = UserSharedPref.getUserId();
  final int? departmentIdLogin = UserSharedPref.getUserDept();
  final int? sectionIdLogin = UserSharedPref.getUserSect();

  late Future<List<Reportss>> yourReports;
  late Future<List<Reportss>> reportsForYou;
  late Future<List<ReportLogs>> thread;

  late Reportss reportsDetails;

  late String? toAssignedId = "0";

  bool showReportDetails = false;

  @override
  void initState() {
    yourReports = ReportsDb().getByDepartmentFrom(departmentIdLogin);
    reportsForYou = ReportsDb().getByDepartmentTo(departmentIdLogin);
    //_getYourReport();
    //_getReportForYou();
    super.initState();
  }

  _getYourReport() async {
    setState(() {
      yourReports = ReportsDb().getByDepartmentFrom(departmentIdLogin);
    });
  }

  _getReportForYou() async {
    setState(() {
      reportsForYou = ReportsDb().getByDepartmentTo(departmentIdLogin);
    });
  }

  Future<String> getAssignedToName(String assignedToId) async {
    try {
      final user = await UsersDb().get(assignedToId);
      return user.first.fullName;
    } catch (error) {
      //print('Error fetching assigned user: $error');
      return '$error'; // Handle errors gracefully, e.g., display an error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FxBox.h24,
            if (!showReportDetails) ...[
              const RouteTitle(),
              FxBox.h24,
              _yourReports(),
              FxBox.h24,
              _reportsForYou(),
            ],
            if (showReportDetails) _reportDetails(),
            FxBox.h28
          ],
        ),
      ),
    );
  }

  Container _yourReports() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: context.theme.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 24.0, bottom: 4.0),
            child: Text(
              "Your Reports",
              style: ConstTheme.title(context),
            ),
          ),
          FxBox.h4,
          SizedBox(
            child: FutureBuilder<List<Reportss>>(
                future: yourReports,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                        child: Text("Error fetchting data on Your Reports"));
                  } else {
                    final List<Reportss> reports = snapshot.data!;

                    return SizedBox(
                      height: 64.0 * (reports.length + 1),
                      child: DataTable3(
                        minWidth: 744,
                        dividerThickness: 0.5,
                        showCheckboxColumn: true,
                        dataRowHeight: 64.0,
                        headingRowHeight: 64.0,
                        columnSpacing: 8.0,
                        columns: [
                          DataColumn2(
                            label: Text('ID', style: ConstTheme.hintText),
                            size: ColumnSize.S,
                          ),
                          DataColumn2(
                            label: Text('To Department',
                                style: ConstTheme.hintText),
                            size: ColumnSize.L,
                          ),
                          DataColumn2(
                            label: Text('Issue Category',
                                style: ConstTheme.hintText),
                            size: ColumnSize.M,
                          ),
                          DataColumn2(
                            label: Text('Status', style: ConstTheme.hintText),
                            size: ColumnSize.M,
                          ),
                          DataColumn2(
                            label: Text("Date", style: ConstTheme.hintText),
                            size: ColumnSize.L,
                          ),
                          DataColumn2(
                            label: Text(' ', style: ConstTheme.hintText),
                            size: ColumnSize.S,
                          ),
                        ],
                        rows: reports.map((row) {
                          DateTime dateTime =
                              DateTime.parse(row.createdAt.toString());

                          String formattedDate =
                              DateFormat('MMM d, y').format(dateTime);

                          Color colorsStatus =
                              CommonWidget().statusColor(row.status);

                          return DataRow2(
                            cells: [
                              DataCell(
                                Text(
                                  '${row.id}',
                                  style: ConstTheme.hintText.copyWith(
                                    color: context.isDarkMode
                                        ? Colors.white
                                        : const Color(0xff333333),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text('${row.departmentTo} - ${row.sectionTo}',
                                    style: ConstTheme.hintText),
                              ),
                              DataCell(
                                Text('${row.issueName} - ${row.issueSubName}',
                                    style: ConstTheme.hintText),
                              ),
                              DataCell(
                                StatusButton(
                                  text: '${row.status?.toUpperCase()}',
                                  color: colorsStatus,
                                ),
                              ),
                              DataCell(
                                Text(formattedDate, style: ConstTheme.hintText),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const SvgIcon(
                                    icon: ConstIcons.menu,
                                    color: ConstColor.hintColor,
                                  ),
                                  onPressed: () async {
                                    final List<Reportss> d =
                                        await ReportsDb().get(row.id);

                                    setState(() {
                                      reportsDetails = d[0];
                                      showReportDetails = true;
                                      thread = ReportLogsDb()
                                          .getByReport(reportsDetails.id);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  }
                }),
          ),
        ],
      ),
    );
  }

  Container _reportsForYou() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: context.theme.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 24.0, bottom: 4.0),
            child: Text(
              "Reports For You",
              style: ConstTheme.title(context),
            ),
          ),
          FxBox.h4,
          SizedBox(
            child: FutureBuilder<List<Reportss>>(
                future: reportsForYou,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                        child: Text("Error fetchting data on Your Reports"));
                  } else {
                    final List<Reportss> reports = snapshot.data!;

                    return SizedBox(
                      height: 64.0 * (reports.length + 1),
                      child: DataTable3(
                        minWidth: 744,
                        dividerThickness: 0.5,
                        showCheckboxColumn: true,
                        dataRowHeight: 64.0,
                        headingRowHeight: 64.0,
                        columnSpacing: 8.0,
                        columns: [
                          DataColumn2(
                            label: Text('ID', style: ConstTheme.hintText),
                            size: ColumnSize.S,
                          ),
                          DataColumn2(
                            label: Text('From Department',
                                style: ConstTheme.hintText),
                            size: ColumnSize.L,
                          ),
                          DataColumn2(
                            label: Text('Issue Category',
                                style: ConstTheme.hintText),
                            size: ColumnSize.M,
                          ),
                          DataColumn2(
                            label:
                                Text('Assigned To', style: ConstTheme.hintText),
                            size: ColumnSize.M,
                          ),
                          DataColumn2(
                            label: Text('Status', style: ConstTheme.hintText),
                            size: ColumnSize.M,
                          ),
                          DataColumn2(
                            label: Text("Date", style: ConstTheme.hintText),
                            size: ColumnSize.L,
                          ),
                          DataColumn2(
                            label: Text(' ', style: ConstTheme.hintText),
                            size: ColumnSize.S,
                          ),
                        ],
                        rows: reports.map((row) {
                          DateTime dateTime =
                              DateTime.parse(row.createdAt.toString());

                          String formattedDate =
                              DateFormat('MMM d, y h:mm a').format(dateTime);

                          Color colorsStatus = Colors.yellow;

                          switch (row.status) {
                            case "new":
                              colorsStatus = Colors.blueAccent;
                            case "assigned":
                              colorsStatus = Colors.greenAccent;
                            case "in progress":
                              colorsStatus = Colors.yellow;
                            case "resolved":
                              colorsStatus = Colors.green;
                            case "closed":
                              colorsStatus = Colors.grey;
                            default:
                              colorsStatus = Colors.black87;
                          }

                          Widget assignedCell;

                          if (row.status == 'new') {
                            assignedCell = Center(
                              child: IconButton(
                                onPressed: () {
                                  _assignedToDialog(
                                      context, row.id, 'onReportsList');
                                },
                                icon: const Icon(Icons.person_add),
                              ),
                            );
                          } else {
                            assignedCell = FutureBuilder(
                              future:
                                  getAssignedToName(row.assignedTo.toString()),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(snapshot.data!,
                                      style: ConstTheme.hintText);
                                } else if (snapshot.hasError) {
                                  return Text(' ',
                                      style: ConstTheme.hintText
                                          .copyWith(color: Colors.red));
                                } else {
                                  return Text(' ',
                                      style: ConstTheme.hintText
                                          .copyWith(color: Colors.grey));
                                }
                              },
                            );
                          }

                          return DataRow2(
                            cells: [
                              DataCell(
                                Text(
                                  '${row.id}',
                                  style: ConstTheme.hintText.copyWith(
                                    color: context.isDarkMode
                                        ? Colors.white
                                        : const Color(0xff333333),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                    '${row.departmentFrom} - ${row.sectionFrom}',
                                    style: ConstTheme.hintText),
                              ),
                              DataCell(
                                Text('${row.issueName} - ${row.issueSubName}',
                                    style: ConstTheme.hintText),
                              ),
                              DataCell(
                                assignedCell,
                              ),
                              DataCell(
                                StatusButton(
                                  text: '${row.status?.toUpperCase()}',
                                  color: colorsStatus,
                                ),
                              ),
                              DataCell(
                                Text(formattedDate, style: ConstTheme.hintText),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const SvgIcon(
                                    icon: ConstIcons.menu,
                                    color: ConstColor.hintColor,
                                  ),
                                  onPressed: () async {
                                    final List<Reportss> d =
                                        await ReportsDb().get(row.id);

                                    setState(() {
                                      reportsDetails = d[0];
                                      showReportDetails = true;
                                      thread = ReportLogsDb()
                                          .getByReport(reportsDetails.id);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  }
                }),
          ),
        ],
      ),
    );
  }

  _assignedToDialog(
      BuildContext contxt, String? reportId, String? toLoad) async {
    final Future<List<Users>> users =
        UsersDb().getByDepartment(departmentIdLogin);

    setState(() {
      toAssignedId = "0";
    });

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            width: 200.0,
            height: 10.0,
            child: AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.person_add),
                  FxBox.w10,
                  const Text("Assignt To:")
                ],
              ),
              content: FutureBuilder<List<Users>>(
                future: users,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                        child: Text("Error fetchining data on Users"));
                  } else {
                    final List<Users> users = snapshot.data!;

                    return DropdownButtonFormField(
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        filled: true,
                        fillColor: context.isDarkMode
                            ? ConstColor.darkFillColor
                            : ConstColor.lightFillColor,
                        contentPadding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Select person'),
                        ),
                        ...users.map((user) {
                          return DropdownMenuItem(
                            value: user,
                            child: Text(
                              user.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: ConstTheme.text(context)
                                  .copyWith(fontSize: 16.0),
                            ),
                          );
                        }).toList(),
                      ],
                      value: null,
                      style: ConstTheme.text(context).copyWith(fontSize: 18.0),
                      onChanged: (value) {
                        setState(() {
                          toAssignedId = value!.id;
                        });
                      },
                    );
                  }
                },
              ),
              actions: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  label: const Text('Cancel',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      )),
                  style: ButtonStyle(
                    backgroundColor:
                        const MaterialStatePropertyAll(ConstColor.redAccent),
                    elevation: const MaterialStatePropertyAll(0.0),
                    shape: MaterialStatePropertyAll(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.person_add_alt,
                    color: Colors.white,
                  ),
                  onPressed: () => _assignedToPerson(context, reportId, toLoad),
                  label: const Text('Assign',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      )),
                  style: ButtonStyle(
                    backgroundColor:
                        const MaterialStatePropertyAll(ConstColor.primary),
                    elevation: const MaterialStatePropertyAll(0.0),
                    shape: MaterialStatePropertyAll(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  _assignedToPerson(
      BuildContext context, String? reportId, String? toLoad) async {
    if (toAssignedId == '0') {
      CommonWidget().showSuccessDialog(
          context, 'Please select a person to assign report!', false);
    } else {
      var updateAssign =
          await ReportsDb().updateAssigned(reportId, toAssignedId, userIdLogin);

      if (updateAssign == 'success') {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);

        if (toLoad == 'onReportsList') {
          setState(() {
            reportsForYou = ReportsDb().getByDepartmentTo(departmentIdLogin);
          });
        } else {
          final List<Reportss> d = await ReportsDb().get(reportId);

          setState(() {
            reportsDetails = d[0];
          });
        }

        // ignore: use_build_context_synchronously
        CommonWidget()
            .showSuccessDialog(context, "Report successfully updated!", true);

        final assignToUser = await UsersDb().get(toAssignedId);
        final assignByUser = await UsersDb().get(userIdLogin);

        //print(assignToUser.first.fullName);

        final ReportLogs log = ReportLogs(
          reportId: reportId.toString(),
          userId: toAssignedId.toString(),
          status: "assigned",
          message:
              'Report was assigned to: ${assignToUser.first.fullName} by: ${assignByUser.first.fullName}',
        );
        await ReportLogsDb().save(log);

        final ReportLogs logInprogress = ReportLogs(
          reportId: reportId.toString(),
          userId: toAssignedId.toString(),
          status: "in progress",
          message:
              '${assignToUser.first.fullName} is now resolving the reported issue',
        );
        await ReportLogsDb().save(logInprogress);
      } else {
        // ignore: use_build_context_synchronously
        CommonWidget().showSuccessDialog(context, updateAssign, false);
      }
    }
  }

  _reportDetails() {
    return SizedBox(
      //padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Title
          Row(
            children: [
              Text(
                "Report: # ${reportsDetails.id} from: ${reportsDetails.departmentFrom} - ${reportsDetails.sectionFrom}",
                style: TextStyle(
                  fontSize: 24.0,
                  color: context.isDarkMode
                      ? Colors.white
                      : ConstColor.lightTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FxBox.w10,
              TextButton.icon(
                label: const Text("Return to List"),
                icon: const SvgIcon(
                  icon: ConstIcons.returnToReport,
                  color: ConstColor.primary,
                ),
                onPressed: () {
                  setState(() {
                    showReportDetails = false;
                  });
                },
              ),
            ],
          ),
          FxBox.h24,
          // test for report details
          Details(
              reportId: reportsDetails.id.toString(),
              assignTo: reportsDetails.assignedTo),
          // Report Details
        ],
      ),
    );
  }
}
