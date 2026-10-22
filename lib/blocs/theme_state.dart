import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  const ThemeState({this.isDark = true});

  final bool isDark;

  ThemeMode get mode => isDark ? ThemeMode.dark : ThemeMode.light;

  @override
  List<Object> get props => [isDark];
}