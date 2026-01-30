#!/usr/bin/env python3
import os
import requests
import time
from pathlib import Path

class IconDownloader:
    def __init__(self):
        self.base_url = "https://api.iconify.design"
        self.icons_dir = Path("../assets/icons/categories")
        
        # Financial category icons
        self.category_icons = {
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
            'subscriptions': [
                'simple-icons:netflix',
                'simple-icons:spotify',
                'simple-icons:youtube',
                'simple-icons:amazon',
                'simple-icons:apple',
                'simple-icons:microsoft',
                'simple-icons:adobe',
                'simple-icons:disney',
                'simple-icons:hulu',
                'simple-icons:hbo',
                'simple-icons:twitch',
                'simple-icons:dropbox',
                'simple-icons:googledrive',
                'simple-icons:icloud',
                'simple-icons:github',
                'simple-icons:linkedin',
                'simple-icons:canva',
                'simple-icons:figma',
                'simple-icons:notion',
                'simple-icons:slack',
                'simple-icons:zoom',
                'simple-icons:whatsapp',
                'simple-icons:telegram',
                'simple-icons:discord',
                'mdi:newspaper',
                'mdi:dumbbell',
                'mdi:car-rental',
                'mdi:shield-check',
            ]
        }

    def download_all_icons(self):
        # Create directories
        self.icons_dir.mkdir(parents=True, exist_ok=True)
        (self.icons_dir / 'expense').mkdir(exist_ok=True)
        (self.icons_dir / 'income').mkdir(exist_ok=True)
        (self.icons_dir / 'subscriptions').mkdir(exist_ok=True)
        
        print("📥 Starting icon download...")
        
        for category, icons in self.category_icons.items():
            print(f"\n📂 Downloading {category} icons...")
            
            for icon_name in icons:
                self.download_icon(icon_name, category)
                time.sleep(0.1)  # Rate limiting
        
        print("\n✅ All icons downloaded successfully!")
        print(f"📍 Icons saved to: {self.icons_dir}")

    def download_icon(self, icon_name, category):
        try:
            url = f"{self.base_url}/{icon_name}.svg?color=%23000000&width=24&height=24"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                file_name = icon_name.replace(':', '_') + '.svg'
                file_path = self.icons_dir / category / file_name
                
                with open(file_path, 'w') as f:
                    f.write(response.text)
                
                print(f"  ✓ {icon_name}")
            else:
                print(f"  ✗ Failed to download {icon_name} ({response.status_code})")
                
        except Exception as e:
            print(f"  ✗ Error downloading {icon_name}: {e}")

if __name__ == "__main__":
    downloader = IconDownloader()
    downloader.download_all_icons()
