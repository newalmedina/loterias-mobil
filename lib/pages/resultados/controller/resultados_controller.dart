import 'package:flutter/material.dart';
import 'package:loterymobile/model/loteria_model.dart';
import 'package:loterymobile/model/loteriaresult_model.dart';
import 'package:loterymobile/services/loteries_service.dart';
import 'package:intl/intl.dart';

class ResultadosController extends ChangeNotifier {
  final TextEditingController dateController = TextEditingController();
  DateTime? selectedDate = DateTime.now();
  List<Loteria> loteries = [];
  Map<int, bool> filters = {};
  List<LoteriaResult> results = [];
  bool isLoading = false;

  ResultadosController() {
    dateController.text = DateFormat('dd-MM-yyyy').format(selectedDate!);
  }

  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  Future<void> loadLoteries() async {
    final lots = await LoteriesService.getLoteries();
    loteries = lots;
    filters = {for (var l in lots) l.id: false};
    notifyListeners();
    await searchResults(reload: true);
  }

  Future<void> searchResults({bool reload = false}) async {
    isLoading = true;
    notifyListeners();

    final selectedIds =
        filters.entries.where((e) => e.value).map((e) => e.key).toList();

    results = await LoteriesService.getResults(
      startDate: selectedDate!,
      loteriesIds: selectedIds,
      reload: reload,
    );

    isLoading = false;
    notifyListeners();
  }

  void pickDate(DateTime picked) {
    selectedDate = picked;
    dateController.text = DateFormat('dd-MM-yyyy').format(picked);
    notifyListeners();
  }

  void setFilter(int id, bool value) {
    filters[id] = value;
    notifyListeners();
  }

  void toggleSelectAll(List<Loteria> filtered) {
    final allSelected = filtered.every((lot) => filters[lot.id] == true);
    for (var lot in filtered) {
      filters[lot.id] = !allSelected;
    }
    notifyListeners();
  }

  String get selectedFiltersLabel {
    final selected = loteries.where((l) => filters[l.id] == true);
    if (selected.isEmpty) return '';
    return 'Seleccionadas: ${selected.map((l) => l.shortName).join(', ')}';
  }
}
