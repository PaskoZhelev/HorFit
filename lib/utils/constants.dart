
import 'package:flutter/material.dart';
import 'package:hor_fit/utils/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

const DB_NAME = 'hor_fit.db';

const CALS_COLOR = Colors.redAccent;
const FAT_COLOR = Colors.orange;
const PROTEIN_COLOR = Colors.green;
const CARBS_COLOR = Colors.blue;

var RAILEWAY_FONT = GoogleFonts.ralewayTextTheme();
var UBUNTU_FONT = GoogleFonts.ubuntuTextTheme();
var KANIT_FONT = GoogleFonts.kanitTextTheme();
var MULISH_FONT = GoogleFonts.mulishTextTheme();
var JOSEFIN_FONT = GoogleFonts.josefinSansTextTheme();
var JOST_FONT = GoogleFonts.jostTextTheme();
var CABIN_FONT = GoogleFonts.cabinTextTheme();

var MAIN_TEXT_THEME = CABIN_FONT;

var darkTheme = ThemeData.dark().copyWith(
      primaryColor: mainColor1,
      scaffoldBackgroundColor: const Color(0xFF101010),
      textTheme: TextThemeColor.nullFontColor(MAIN_TEXT_THEME),
      primaryTextTheme: TextThemeColor.nullFontColor(MAIN_TEXT_THEME),
  colorScheme: ThemeData.dark().colorScheme.copyWith(
    primary: mainColor1,
  ),
    );

var TEAL_COLOR = Colors.teal;
var DARK_COLOR = const Color(0xFF282828);

var mainColor1 = TEAL_COLOR;