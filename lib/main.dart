import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/app.dart';

void main() {
  runApp(const ProviderScope(child: PorestDeskApp()));
}
