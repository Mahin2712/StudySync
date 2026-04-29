import re

with open('C:/Users/SER/StudySync/lib/screens/room_detail_screen.dart', 'rb') as f:
    content = f.read().decode('utf-8', errors='ignore')

content = content.replace("import '../widgets/chat_bottom_sheet.dart';", "")
content = content.replace("        floatingActionButton: _buildChatFab(),\r\n", "")
content = content.replace("        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,\r\n", "")

# Remove _buildChatFab method
content = re.sub(r'  // Chat FAB \? opens Room Chat bottom sheet.*?Widget _buildChatFab\(\) \{.*?\n  \}\n\}', '}', content, flags=re.DOTALL)

with open('C:/Users/SER/StudySync/lib/screens/room_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
