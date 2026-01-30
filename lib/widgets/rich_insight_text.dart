import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RichInsightText extends StatelessWidget {
  final String text;

  const RichInsightText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseInsights(text, context),
    );
  }

  List<Widget> _parseInsights(String text, BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Check if line starts with emoji (insight title)
      if (line.contains('🎯') || line.contains('💰') || line.contains('💡') || 
          line.contains('📊') || line.contains('⚠️') || line.contains('✨') || 
          line.contains('📈') || line.contains('💪')) {
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                height: 1.3,
              ),
            ),
          ),
        );
      } else {
        // Regular content line
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ),
        );
      }
    }
    
    return widgets;
  }
}
