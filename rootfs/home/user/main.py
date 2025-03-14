#!/usr/bin/env python3

"""
CoreARM Build - Sample Python Application
This script runs automatically on system startup.
Replace this with your own application.
"""

import os
import sys
import time
import platform
import subprocess
from datetime import datetime

# Set display environment variable if not already set
if not os.environ.get('DISPLAY'):
    os.environ['DISPLAY'] = ':0'

def run_gui_app():
    """Run GUI application if display is available"""
    try:
        # First try importing Tkinter
        import tkinter as tk
        from tkinter import ttk, messagebox

        # Create main window
        root = tk.Tk()
        root.title("CoreARM - Sample Application")
        root.geometry("600x400")
        
        # Configure style
        style = ttk.Style()
        style.theme_use('clam')  # Use a simple theme that works well on minimal systems
        
        # Create header
        header = ttk.Frame(root)
        header.pack(fill='x', padx=20, pady=10)
        
        title = ttk.Label(header, text="Welcome to CoreARM", font=("TkDefaultFont", 18, "bold"))
        title.pack(side='left')
        
        # Create content area
        content = ttk.Frame(root)
        content.pack(fill='both', expand=True, padx=20, pady=(0, 20))
        
        # System info section
        info_frame = ttk.LabelFrame(content, text="System Information")
        info_frame.pack(fill='both', expand=True, padx=5, pady=5)
        
        info_text = tk.Text(info_frame, height=10, width=70, bg='#f0f0f0')
        info_text.pack(padx=10, pady=10, fill='both', expand=True)
        
        def get_system_info():
            """Gather system information"""
            info = []
            info.append(f"Python Version: {platform.python_version()}")
            info.append(f"System: {platform.system()} {platform.release()}")
            info.append(f"Architecture: {platform.machine()}")
            info.append(f"Processor: ARM Cortex-A53 (64-bit)")
            info.append(f"Memory: {get_memory_info()}")
            info.append(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            info.append(f"Hostname: {platform.node()}")
            info.append(f"Username: {os.getenv('USER', 'user')}")
            return "\n".join(info)
        
        def get_memory_info():
            """Get memory information"""
            try:
                with open('/proc/meminfo', 'r') as f:
                    meminfo = f.read()
                
                total = 0
                free = 0
                for line in meminfo.split('\n'):
                    if 'MemTotal' in line:
                        total = int(line.split()[1]) // 1024
                    elif 'MemFree' in line:
                        free = int(line.split()[1]) // 1024
                
                return f"{free}MB free / {total}MB total"
            except:
                return "Unknown"
        
        def update_info():
            """Update system information"""
            info_text.delete(1.0, tk.END)
            info_text.insert(tk.END, get_system_info())
            root.after(1000, update_info)  # Update every second
        
        # Control section
        control_frame = ttk.LabelFrame(content, text="Controls")
        control_frame.pack(fill='x', padx=5, pady=5)
        
        def run_command(cmd):
            """Run a shell command and display the output"""
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            messagebox.showinfo("Command Output", result.stdout if result.stdout else "Command executed successfully.")
        
        # Create buttons
        btn_frame = ttk.Frame(control_frame)
        btn_frame.pack(padx=10, pady=10, fill='x')
        
        uptime_btn = ttk.Button(btn_frame, text="Show Uptime", 
                                command=lambda: run_command("uptime"))
        uptime_btn.pack(side="left", padx=5)
        
        ps_btn = ttk.Button(btn_frame, text="Process List", 
                           command=lambda: run_command("ps -ef"))
        ps_btn.pack(side="left", padx=5)
        
        disk_btn = ttk.Button(btn_frame, text="Disk Usage", 
                             command=lambda: run_command("df -h"))
        disk_btn.pack(side="left", padx=5)
        
        net_btn = ttk.Button(btn_frame, text="Network", 
                            command=lambda: run_command("ifconfig"))
        net_btn.pack(side="left", padx=5)
        
        exit_btn = ttk.Button(btn_frame, text="Exit", 
                             command=root.quit)
        exit_btn.pack(side="right", padx=5)
        
        # Start the update loop
        update_info()
        
        # Center the window
        root.update_idletasks()
        width = root.winfo_width()
        height = root.winfo_height()
        x = (root.winfo_screenwidth() // 2) - (width // 2)
        y = (root.winfo_screenheight() // 2) - (height // 2)
        root.geometry(f'{width}x{height}+{x}+{y}')
        
        # Start the main loop
        root.mainloop()
        return True
        
    except ImportError:
        try:
            # Try PyQt as a fallback
            from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QVBoxLayout, QPushButton
            from PyQt5.QtCore import Qt
            
            app = QApplication(sys.argv)
            window = QWidget()
            window.setWindowTitle("Boundless OS - Sample Application")
            window.resize(600, 400)
            
            layout = QVBoxLayout()
            
            title = QLabel("Welcome to Boundless OS")
            title.setAlignment(Qt.AlignCenter)
            font = title.font()
            font.setPointSize(18)
            font.setBold(True)
            title.setFont(font)
            
            info = QLabel(f"System: {platform.system()} {platform.release()}\n"
                         f"Python: {platform.python_version()}\n"
                         f"Architecture: {platform.machine()}")
            info.setAlignment(Qt.AlignCenter)
            
            exit_btn = QPushButton("Exit")
            exit_btn.clicked.connect(app.quit)
            
            layout.addWidget(title)
            layout.addWidget(info)
            layout.addWidget(exit_btn)
            
            window.setLayout(layout)
            window.show()
            
            sys.exit(app.exec_())
            return True
            
        except ImportError:
            return False

def run_console_app():
    """Run console-based application for systems without GUI support"""
    print("=" * 50)
    print(f"Boundless OS - Console Mode")
    print("=" * 50)
    print(f"Python Version: {platform.python_version()}")
    print(f"System: {platform.system()} {platform.release()}")
    print(f"Architecture: {platform.machine()}")
    print(f"Date/Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50)
    print("Press Ctrl+C to exit")
    
    try:
        while True:
            # Keep running until interrupted
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nExiting application")

if __name__ == "__main__":
    # Try to run the GUI version first, fall back to console if it fails
    if not run_gui_app():
        run_console_app() 