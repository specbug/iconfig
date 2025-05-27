#!/usr/bin/env python3

import os
import sys
import argparse
import logging
from pathlib import Path

# Add the project root to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import project modules
from wizard.terminal_ui import WizardUI
from sync.git_sync import GitSync
from sync.background_syncer import BackgroundSyncer
from config.config_manager import ConfigManager

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.expanduser("~/.mac-sync-wizard/logs/mac-sync-wizard.log")),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger('mac-sync-wizard')

def setup_command(args):
    """Run the setup wizard"""
    logger.info("Starting setup wizard")
    wizard = WizardUI()
    wizard.run_setup_wizard()

def sync_command(args):
    """Run a manual sync operation"""
    logger.info("Starting manual sync")
    
    if args.daemon:
        logger.info("Running in daemon mode")
        syncer = BackgroundSyncer()
        syncer.start_daemon()
    else:
        syncer = BackgroundSyncer()
        success = syncer.sync_once()
        
        if success:
            logger.info("Sync completed successfully")
            print("✅ Sync completed successfully")
        else:
            logger.error("Sync failed")
            print("❌ Sync failed. Check logs for details.")

def config_command(args):
    """Run the configuration UI"""
    logger.info("Starting configuration UI")
    
    config_manager = ConfigManager()
    
    if args.frequency:
        logger.info(f"Setting sync frequency to {args.frequency} seconds")
        config_manager.set_sync_frequency(args.frequency)
        print(f"✅ Sync frequency set to {args.frequency} seconds")
    elif args.enable:
        logger.info(f"Enabling utility: {args.enable}")
        config_manager.enable_utility(args.enable, True)
        print(f"✅ Utility {args.enable} enabled")
    elif args.disable:
        logger.info(f"Disabling utility: {args.disable}")
        config_manager.enable_utility(args.disable, False)
        print(f"✅ Utility {args.disable} disabled")
    elif args.reset:
        logger.info("Resetting configuration to defaults")
        config_manager.reset_to_defaults()
        print("✅ Configuration reset to defaults")
    else:
        from wizard.config_ui import ConfigUI
        config_ui = ConfigUI()
        config_ui.main_menu()

def status_command(args):
    """Show sync status"""
    logger.info("Checking sync status")
    
    syncer = BackgroundSyncer()
    status = syncer.get_status()
    
    print("\n🔄 Mac Sync Wizard Status\n")
    print(f"Last sync: {status['last_sync']}")
    print(f"Next scheduled sync: {status['next_sync']}")
    print(f"Repository: {status['repository']}")
    print(f"Enabled utilities: {status['enabled_utilities_count']}/{status['total_utilities_count']}")
    
    if status['is_syncing']:
        print("\nSync is currently in progress")
    
    if args.verbose:
        print("\nEnabled utilities:")
        for utility in status['enabled_utilities']:
            print(f"  - {utility}")

def install_command(args):
    """Install or uninstall the background service"""
    logger.info(f"{'Installing' if args.install else 'Uninstalling'} background service")
    
    syncer = BackgroundSyncer()
    
    if args.install:
        success = syncer.install_launch_agent()
        if success:
            logger.info("Background service installed successfully")
            print("✅ Background service installed successfully")
        else:
            logger.error("Failed to install background service")
            print("❌ Failed to install background service")
    else:
        success = syncer.uninstall_launch_agent()
        if success:
            logger.info("Background service uninstalled successfully")
            print("✅ Background service uninstalled successfully")
        else:
            logger.error("Failed to uninstall background service")
            print("❌ Failed to uninstall background service")

def help_command(args):
    """Show help information"""
    print("\n🔄 Mac Sync Wizard Help\n")
    print("Mac Sync Wizard is a tool to synchronize your Mac utilities across multiple machines.")
    print("\nCommands:")
    print("  setup     - Run the setup wizard")
    print("  sync      - Perform a manual sync")
    print("  config    - Configure sync settings")
    print("  status    - Check sync status")
    print("  install   - Install or uninstall the background service")
    print("  help      - Show this help information")
    print("\nFor more information, see the README.md file or visit:")
    print("https://github.com/username/mac-sync-wizard")

def main():
    """Main entry point for the application"""
    # Create application directories if they don't exist
    app_dir = os.path.expanduser("~/.mac-sync-wizard")
    os.makedirs(os.path.join(app_dir, "logs"), exist_ok=True)
    os.makedirs(os.path.join(app_dir, "config"), exist_ok=True)
    
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Mac Sync Wizard")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Setup command
    setup_parser = subparsers.add_parser("setup", help="Run the setup wizard")
    
    # Sync command
    sync_parser = subparsers.add_parser("sync", help="Perform a manual sync")
    sync_parser.add_argument("--daemon", action="store_true", help="Run as daemon")
    
    # Config command
    config_parser = subparsers.add_parser("config", help="Configure sync settings")
    config_parser.add_argument("--frequency", type=int, help="Sync frequency in seconds")
    config_parser.add_argument("--enable", help="Enable a utility")
    config_parser.add_argument("--disable", help="Disable a utility")
    config_parser.add_argument("--reset", action="store_true", help="Reset to defaults")
    
    # Status command
    status_parser = subparsers.add_parser("status", help="Check sync status")
    status_parser.add_argument("--verbose", "-v", action="store_true", help="Show verbose output")
    
    # Install command
    install_parser = subparsers.add_parser("install", help="Install or uninstall the background service")
    install_parser.add_argument("--uninstall", action="store_false", dest="install", help="Uninstall the background service")
    
    # Help command
    help_parser = subparsers.add_parser("help", help="Show help information")
    
    args = parser.parse_args()
    
    # If no command is specified, show help
    if not args.command:
        parser.print_help()
        return
    
    # Run the specified command
    if args.command == "setup":
        setup_command(args)
    elif args.command == "sync":
        sync_command(args)
    elif args.command == "config":
        config_command(args)
    elif args.command == "status":
        status_command(args)
    elif args.command == "install":
        install_command(args)
    elif args.command == "help":
        help_command(args)

if __name__ == "__main__":
    main()
