import 'package:flutter/material.dart';
import 'package:chatting/allConstants/all_constants.dart';

final appTheme = ThemeData(
  primaryColor: AppColors.white,
  scaffoldBackgroundColor: AppColors.black,
  appBarTheme: const AppBarTheme(backgroundColor: AppColors.black),
  colorScheme: ColorScheme.fromSwatch().copyWith(secondary: AppColors.white),
);
