import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const maxTab = 3;

class HomeProvider extends ChangeNotifier {
  static HomeProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<HomeProvider>(context, listen: listen);
  }

  static HomeProvider _instance = HomeProvider._();
  factory HomeProvider() => _instance;
  HomeProvider._();
  int _tab = 0;

  set tab(int tab) {
    if (tab == null || tab < 0) tab = 0;
    tab = tab > maxTab ? maxTab : tab;
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }

  get tab {
    if (_tab == null || _tab < 0) return 0;
    return _tab > maxTab ? maxTab : _tab;
  }
}
