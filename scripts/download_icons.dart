import 'dart:io';
import 'dart:convert';

void main() async {
  final iconDownloader = IconDownloader();
  await iconDownloader.downloadAllIcons();
}

class IconDownloader {
  final String baseUrl = 'https://api.iconify.design';
  final String iconsDir = '../assets/icons/categories';
  
  final Map<String, List<String>> categoryIcons = {
    'expense': [
      'mdi:food',
      'mdi:car',
      'mdi:shopping',
      'mdi:file-document',
      'mdi:hospital-building',
      'mdi:gamepad-variant',
      'mdi:school',
      'mdi:home',
      'mdi:gas-station',
      'mdi:coffee',
      'mdi:tshirt-crew',
      'mdi:dumbbell',
      'mdi:gift',
      'mdi:airplane',
      'mdi:phone',
      'mdi:wifi',
      'mdi:water',
      'mdi:flash',
      'mdi:trash-can',
      'mdi:baby-carriage',
    ],
    'income': [
      'mdi:cash',
      'mdi:briefcase',
      'mdi:chart-line',
      'mdi:gift-outline',
      'mdi:home-variant',
      'mdi:bank',
      'mdi:account-cash',
      'mdi:piggy-bank',
    ],
  };

  Future<void> downloadAllIcons() async {
    // Create directories
    await Directory(iconsDir).create(recursive: true);
    await Directory('$iconsDir/expense').create(recursive: true);
    await Directory('$iconsDir/income').create(recursive: true);

    print('📥 Starting icon download...');

    for (final category in categoryIcons.keys) {
      print('\n📂 Downloading $category icons...');
      
      for (final iconName in categoryIcons[category]!) {
        await downloadIcon(iconName, category);
        await Future.delayed(const Duration(milliseconds: 100)); // Rate limiting
      }
    }

    print('\n✅ All icons downloaded successfully!');
    print('📍 Icons saved to: $iconsDir');
  }

  Future<void> downloadIcon(String iconName, String category) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl/$iconName.svg?color=%23000000&width=24&height=24');
      
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final fileName = iconName.replaceAll(':', '_');
        final file = File('$iconsDir/$category/$fileName.svg');
        
        await response.pipe(file.openWrite());
        print('  ✓ $iconName');
      } else {
        print('  ✗ Failed to download $iconName (${response.statusCode})');
      }
      
      client.close();
    } catch (e) {
      print('  ✗ Error downloading $iconName: $e');
    }
  }
}
