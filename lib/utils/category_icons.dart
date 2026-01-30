import 'package:flutter/material.dart';
import 'package:monixx/widgets/safe_svg.dart';

class CategoryIcons {
  static const Map<String, String> _expenseIcons = {
    'Food': 'assets/icons/categories/expense/mdi_food.svg',
    'Transport': 'assets/icons/categories/expense/mdi_car.svg',
    'Shopping': 'assets/icons/categories/expense/mdi_shopping.svg',
    'Bills': 'assets/icons/categories/expense/mdi_file-document.svg',
    'Health': 'assets/icons/categories/expense/mdi_hospital-building.svg',
    'Entertainment': 'assets/icons/categories/expense/mdi_gamepad-variant.svg',
    'Education': 'assets/icons/categories/expense/mdi_school.svg',
    'Home': 'assets/icons/categories/expense/mdi_home.svg',
    'Fuel': 'assets/icons/categories/expense/mdi_gas-station.svg',
    'Coffee': 'assets/icons/categories/expense/mdi_coffee.svg',
    'Clothing': 'assets/icons/categories/expense/mdi_tshirt-crew.svg',
    'Fitness': 'assets/icons/categories/expense/mdi_dumbbell.svg',
    'Gifts': 'assets/icons/categories/expense/mdi_gift.svg',
    'Travel': 'assets/icons/categories/expense/mdi_airplane.svg',
    'Phone': 'assets/icons/categories/expense/mdi_phone.svg',
    'Internet': 'assets/icons/categories/expense/mdi_wifi.svg',
    'Water': 'assets/icons/categories/expense/mdi_water.svg',
    'Electricity': 'assets/icons/categories/expense/mdi_flash.svg',
    'Waste': 'assets/icons/categories/expense/mdi_trash-can.svg',
    'Baby': 'assets/icons/categories/expense/mdi_baby-carriage.svg',
  };

  static const Map<String, String> _incomeIcons = {
    'Salary': 'assets/icons/categories/income/mdi_cash.svg',
    'Freelance': 'assets/icons/categories/income/mdi_briefcase.svg',
    'Investment': 'assets/icons/categories/income/mdi_chart-line.svg',
    'Gift': 'assets/icons/categories/income/mdi_gift-outline.svg',
    'Rental': 'assets/icons/categories/income/mdi_home-variant.svg',
    'Business': 'assets/icons/categories/income/mdi_bank.svg',
    'Bonus': 'assets/icons/categories/income/mdi_account-cash.svg',
    'Savings': 'assets/icons/categories/income/mdi_piggy-bank.svg',
  };

  static const Map<String, String> _subscriptionIcons = {
    'Netflix': 'assets/icons/categories/subscriptions/simple-icons_netflix.svg',
    'Spotify': 'assets/icons/categories/subscriptions/simple-icons_spotify.svg',
    'YouTube': 'assets/icons/categories/subscriptions/simple-icons_youtube.svg',
    'Amazon Prime':
        'assets/icons/categories/subscriptions/simple-icons_amazon.svg',
    'Apple': 'assets/icons/categories/subscriptions/simple-icons_apple.svg',
    'Microsoft':
        'assets/icons/categories/subscriptions/simple-icons_microsoft.svg',
    'Adobe': 'assets/icons/categories/subscriptions/simple-icons_adobe.svg',
    'Hulu': 'assets/icons/categories/subscriptions/simple-icons_hulu.svg',
    'HBO': 'assets/icons/categories/subscriptions/simple-icons_hbo.svg',
    'Twitch': 'assets/icons/categories/subscriptions/simple-icons_twitch.svg',
    'Dropbox': 'assets/icons/categories/subscriptions/simple-icons_dropbox.svg',
    'Google Drive':
        'assets/icons/categories/subscriptions/simple-icons_googledrive.svg',
    'iCloud': 'assets/icons/categories/subscriptions/simple-icons_icloud.svg',
    'GitHub': 'assets/icons/categories/subscriptions/simple-icons_github.svg',
    'LinkedIn':
        'assets/icons/categories/subscriptions/simple-icons_linkedin.svg',
    'Canva': 'assets/icons/categories/subscriptions/simple-icons_canva.svg',
    'Figma': 'assets/icons/categories/subscriptions/simple-icons_figma.svg',
    'Notion': 'assets/icons/categories/subscriptions/simple-icons_notion.svg',
    'Slack': 'assets/icons/categories/subscriptions/simple-icons_slack.svg',
    'Zoom': 'assets/icons/categories/subscriptions/simple-icons_zoom.svg',
    'WhatsApp':
        'assets/icons/categories/subscriptions/simple-icons_whatsapp.svg',
    'Telegram':
        'assets/icons/categories/subscriptions/simple-icons_telegram.svg',
    'Discord': 'assets/icons/categories/subscriptions/simple-icons_discord.svg',
    'News': 'assets/icons/categories/subscriptions/mdi_newspaper.svg',
    'Gym': 'assets/icons/categories/subscriptions/mdi_dumbbell.svg',
    'Car Rental': 'assets/icons/categories/subscriptions/mdi_car-rental.svg',
    'Insurance': 'assets/icons/categories/subscriptions/mdi_shield-check.svg',
  };

  /// Get SVG icon widget for a category
  static Widget getIcon(
    String categoryName, {
    double size = 24,
    Color? color,
    String type = 'expense',
  }) {
    final iconPath = getIconPath(categoryName, type: type);

    if (iconPath != null) {
      return SafeSvg(
        asset: iconPath,
        size: size,
        color: type == 'subscription' ? null : color,
        fallbackEmoji: getEmojiIcon(categoryName, type: type),
      );
    }

    return Text(
      getEmojiIcon(categoryName, type: type),
      style: TextStyle(fontSize: size),
    );
  }

  /// Get icon path for a category
  static String? getIconPath(String categoryName, {String type = 'expense'}) {
    switch (type) {
      case 'expense':
        return _expenseIcons[categoryName];
      case 'income':
        return _incomeIcons[categoryName];
      case 'subscription':
        return _subscriptionIcons[categoryName];
      default:
        return _expenseIcons[categoryName];
    }
  }

  /// Get emoji fallback for categories
  static String getEmojiIcon(String categoryName, {String type = 'expense'}) {
    if (type == 'expense') {
      switch (categoryName) {
        case 'Food':
          return '🍔';
        case 'Transport':
          return '🚗';
        case 'Shopping':
          return '🛍️';
        case 'Bills':
          return '📄';
        case 'Health':
          return '🏥';
        case 'Entertainment':
          return '🎮';
        case 'Education':
          return '🎓';
        case 'Home':
          return '🏠';
        case 'Fuel':
          return '⛽';
        case 'Coffee':
          return '☕';
        case 'Clothing':
          return '👕';
        case 'Fitness':
          return '💪';
        case 'Gifts':
          return '🎁';
        case 'Travel':
          return '✈️';
        case 'Phone':
          return '📱';
        case 'Internet':
          return '📶';
        case 'Water':
          return '💧';
        case 'Electricity':
          return '⚡';
        case 'Waste':
          return '🗑️';
        case 'Baby':
          return '👶';
        default:
          return '💰';
      }
    } else {
      switch (categoryName) {
        case 'Salary':
          return '💵';
        case 'Freelance':
          return '💼';
        case 'Investment':
          return '📈';
        case 'Gift':
          return '🎁';
        case 'Rental':
          return '🏠';
        case 'Business':
          return '🏦';
        case 'Bonus':
          return '💰';
        case 'Savings':
          return '🐷';
        default:
          return '💰';
      }
    }
  }

  /// Get all available category names for a type
  static List<String> getCategoryNames({String type = 'expense'}) {
    switch (type) {
      case 'expense':
        return _expenseIcons.keys.toList();
      case 'income':
        return _incomeIcons.keys.toList();
      case 'subscription':
        return _subscriptionIcons.keys.toList();
      default:
        return _expenseIcons.keys.toList();
    }
  }

  /// Check if category has SVG icon
  static bool hasSvgIcon(String categoryName, {String type = 'expense'}) {
    return getIconPath(categoryName, type: type) != null;
  }

  /// Get brand color for subscription services
  static Color? getBrandColor(String categoryName) {
    switch (categoryName) {
      case 'Netflix':
        return const Color(0xFFE50914);
      case 'Spotify':
        return const Color(0xFF1DB954);
      case 'YouTube':
        return const Color(0xFFFF0000);
      case 'Amazon Prime':
        return const Color(0xFFFF9900);
      case 'Apple':
        return const Color(0xFF000000);
      case 'Microsoft':
        return const Color(0xFF00A4EF);
      case 'Adobe':
        return const Color(0xFFFF0000);
      case 'Hulu':
        return const Color(0xFF1CE783);
      case 'HBO':
        return const Color(0xFF7F3F98);
      case 'Twitch':
        return const Color(0xFF9146FF);
      case 'Dropbox':
        return const Color(0xFF0061FF);
      case 'Google Drive':
        return const Color(0xFF4285F4);
      case 'iCloud':
        return const Color(0xFF3693F3);
      case 'GitHub':
        return const Color(0xFF181717);
      case 'LinkedIn':
        return const Color(0xFF0A66C2);
      case 'Canva':
        return const Color(0xFF00C4CC);
      case 'Figma':
        return const Color(0xFFF24E1E);
      case 'Notion':
        return const Color(0xFF000000);
      case 'Slack':
        return const Color(0xFF4A154B);
      case 'Zoom':
        return const Color(0xFF2D8CFF);
      case 'WhatsApp':
        return const Color(0xFF25D366);
      case 'Telegram':
        return const Color(0xFF26A5E4);
      case 'Discord':
        return const Color(0xFF5865F2);
      // Expense categories
      case 'Food':
        return const Color(0xFFFF6B6B);
      case 'Transport':
        return const Color(0xFF4ECDC4);
      case 'Shopping':
        return const Color(0xFFFFE66D);
      case 'Bills':
        return const Color(0xFF95E1D3);
      case 'Health':
        return const Color(0xFFFF6B9D);
      case 'Entertainment':
        return const Color(0xFFC44569);
      case 'Education':
        return const Color(0xFF786FA6);
      case 'Home':
        return const Color(0xFFF8B500);
      case 'Fuel':
        return const Color(0xFFEA8685);
      case 'Coffee':
        return const Color(0xFF6F4E37);
      case 'Clothing':
        return const Color(0xFFE056FD);
      case 'Fitness':
        return const Color(0xFF26DE81);
      case 'Gifts':
        return const Color(0xFFFC5C65);
      case 'Travel':
        return const Color(0xFF45AAF2);
      case 'Phone':
        return const Color(0xFF5F27CD);
      case 'Internet':
        return const Color(0xFF00D2D3);
      // Income categories
      case 'Salary':
        return const Color(0xFF26DE81);
      case 'Freelance':
        return const Color(0xFF45AAF2);
      case 'Investment':
        return const Color(0xFFFEA47F);
      case 'Gift':
        return const Color(0xFFFC5C65);
      case 'Rental':
        return const Color(0xFFF8B500);
      case 'Business':
        return const Color(0xFF786FA6);
      case 'Bonus':
        return const Color(0xFF26DE81);
      case 'Savings':
        return const Color(0xFF4ECDC4);
      default:
        return null;
    }
  }
}
