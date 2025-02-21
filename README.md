# LaunchCraft

LaunchCraft is a utility tool for Linux desktop environments that helps manage application icons (AppIcon) for AppImage files and website shortcuts.

## Features

- Create desktop entries (.desktop files) for AppImage applications
- Generate website shortcuts with custom icons
- Simple shell script based solution
- Multi-language support (English/Korean)

## Usage

1. Make the script executable:
```bash
chmod +x launchcraft.sh
```

2. Run the script with AppImage file or URL:
```bash
# For AppImage
./launchcraft.sh /path/to/your/application.AppImage

# For website shortcut
./launchcraft.sh https://example.com

# With Korean language option
./launchcraft.sh -l ko /path/to/your/application.AppImage
```

3. Follow the interactive prompts to:
   - Choose installation location (Dock/Desktop/Both)
   - Set custom icon (if needed)

## Upcoming Features

- GUI interface with drag-and-drop support
- File dialog for easier file selection
- Enhanced icon management capabilities

## System Requirements

- Debian-based Linux distributions (Ubuntu, Zorin OS, etc.)
- GNOME-based desktop environment
- Bash shell
- GTK-based desktop environment support
- Tested on:
  - Zorin OS (GNOME)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
