#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil
from pathlib import Path

class OSBuilder:
    def __init__(self):
        self.project_dir = Path(__file__).parent
        self.build_dir = self.project_dir / "build"
        self.source_files = {
            "boot": self.project_dir / "boot.asm",
            "loader": self.project_dir / "loader.asm", 
            "kernel": self.project_dir / "kernel.asm"
        }
        self.output_files = {
            "boot": self.build_dir / "boot.bin",
            "loader": self.build_dir / "loader.bin",
            "kernel": self.build_dir / "kernel.bin",
            "disk": self.build_dir / "disk.img"
        }
        
    def print_header(self):
        print("=" * 60)
        print("    Protected Mode OS - Full Edition Builder")
        print("=" * 60)
        print()
        
    def check_nasm(self):
        """检查NASM是否可用"""
        print("Checking for NASM...")
        try:
            result = subprocess.run(["nasm", "-v"], capture_output=True, text=True)
            if result.returncode == 0:
                print("✓ NASM found:", result.stdout.split('\n')[0])
                return True
            else:
                print("✗ NASM not found or not working")
                return False
        except FileNotFoundError:
            print("✗ NASM not found in PATH")
            print("Please install NASM from: https://www.nasm.us/")
            return False
    
    def create_build_dir(self):
        """创建构建目录"""
        try:
            self.build_dir.mkdir(exist_ok=True)
            print("✓ Build directory ready")
            return True
        except Exception as e:
            print(f"✗ Failed to create build directory: {e}")
            return False
    
    def clean_previous_build(self):
        """清理之前的构建文件"""
        print("Cleaning previous builds...")
        for file in self.output_files.values():
            if file.exists():
                try:
                    file.unlink()
                    print(f"  Deleted: {file.name}")
                except Exception as e:
                    print(f"  Warning: Could not delete {file.name}: {e}")
    
    def check_source_files(self):
        """检查源文件是否存在"""
        print("Checking source files...")
        missing_files = []
        for name, path in self.source_files.items():
            if path.exists():
                print(f"  ✓ {name}.asm found")
            else:
                print(f"  ✗ {name}.asm missing")
                missing_files.append(name)
        
        if missing_files:
            print(f"Missing files: {', '.join(missing_files)}")
            return False
        return True
    
    def compile_asm(self, source, output):
        """编译汇编文件"""
        try:
            cmd = ["nasm", "-f", "bin", "-o", str(output), str(source)]
            print(f"Compiling {source.name}...")
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                if output.exists():
                    size = output.stat().st_size
                    print(f"  ✓ Success: {size} bytes")
                    return True
                else:
                    print("  ✗ Output file not created")
                    return False
            else:
                print(f"  ✗ Compilation failed:")
                print(f"    Error: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"  ✗ Compilation error: {e}")
            return False
    
    def create_disk_image(self):
        """创建磁盘映像"""
        print("Creating disk image...")
        
        # 检查必要的文件
        required_files = [self.output_files["boot"], self.output_files["loader"], self.output_files["kernel"]]
        missing_files = [f.name for f in required_files if not f.exists()]
        
        if missing_files:
            print(f"  ✗ Missing required files: {', '.join(missing_files)}")
            return False
        
        try:
            # 读取boot.bin
            with open(self.output_files["boot"], 'rb') as f:
                boot_data = f.read()
            
            # 读取loader.bin
            with open(self.output_files["loader"], 'rb') as f:
                loader_data = f.read()
                
            # 读取kernel.bin
            with open(self.output_files["kernel"], 'rb') as f:
                kernel_data = f.read()
            
            # 创建磁盘映像
            with open(self.output_files["disk"], 'wb') as f:
                f.write(boot_data)
                f.write(loader_data)
                f.write(kernel_data)
                # 填充到1.44MB
                current_size = len(boot_data) + len(loader_data) + len(kernel_data)
                padding_size = 1474560 - current_size  # 1.44MB
                if padding_size > 0:
                    f.write(b'\x00' * padding_size)
            
            disk_size = self.output_files["disk"].stat().st_size
            print(f"  ✓ Disk image created: {disk_size} bytes")
            return True
            
        except Exception as e:
            print(f"  ✗ Failed to create disk image: {e}")
            return False
    
    def show_file_sizes(self):
        """显示文件大小信息"""
        print("\nFile sizes:")
        for name, path in self.output_files.items():
            if path.exists():
                size = path.stat().st_size
                print(f"  {path.name}: {size} bytes")
            else:
                print(f"  {name}: Not found")
    
    def show_system_info(self):
        """显示系统信息"""
        print("\nSystem features:")
        print("  - 32-bit Protected Mode")
        print("  - 4GB Memory Support") 
        print("  - Simple File System")
        print("  - Calculator Application")
        print("  - Text Editor with File I/O")
        print("  - File Manager with CRUD operations")
        print("  - System Information Display")
    
    def check_qemu(self):
        """检查QEMU是否可用"""
        print("\nChecking for QEMU...")
        qemu_versions = ["qemu-system-i386", "qemu-system-x86_64"]
        
        for qemu in qemu_versions:
            try:
                result = subprocess.run([qemu, "--version"], capture_output=True, text=True)
                if result.returncode == 0:
                    version_line = result.stdout.split('\n')[0]
                    print(f"✓ {qemu} found: {version_line}")
                    return qemu
            except FileNotFoundError:
                continue
        
        print("✗ QEMU not found")
        return None
    
    def run_qemu(self, qemu_cmd):
        """运行QEMU"""
        print(f"\nStarting {qemu_cmd}...")
        try:
            cmd = [qemu_cmd, "-fda", str(self.output_files["disk"]), "-m", "4G"]
            print(f"Command: {' '.join(cmd)}")
            subprocess.run(cmd)
        except Exception as e:
            print(f"Failed to start QEMU: {e}")
    
    def build(self):
        """主构建流程"""
        self.print_header()
        
        # 检查环境
        if not self.check_nasm():
            return False
        
        if not self.create_build_dir():
            return False
        
        if not self.check_source_files():
            return False
        
        # 清理和编译
        self.clean_previous_build()
        
        # 编译boot.asm
        if not self.compile_asm(self.source_files["boot"], self.output_files["boot"]):
            return False
        
        # 编译loader.asm
        if not self.compile_asm(self.source_files["loader"], self.output_files["loader"]):
            return False
        
        # 编译kernel.asm
        if not self.compile_asm(self.source_files["kernel"], self.output_files["kernel"]):
            return False
        
        # 创建磁盘映像
        if not self.create_disk_image():
            return False
        
        # 显示构建信息
        self.show_file_sizes()
        self.show_system_info()
        
        print("\n" + "=" * 60)
        print("    BUILD SUCCESSFUL!")
        print("=" * 60)
        
        # 检查并运行QEMU
        qemu_cmd = self.check_qemu()
        if qemu_cmd:
            response = input("\nRun in QEMU now? (y/n): ").lower().strip()
            if response in ['y', 'yes']:
                self.run_qemu(qemu_cmd)
        else:
            print("\nTo run manually:")
            print(f"  qemu-system-i386 -fda {self.output_files['disk']} -m 4G")
            print("Or use VMware/VirtualBox with the disk image")
        
        return True

def main():
    builder = OSBuilder()
    success = builder.build()
    
    if not success:
        print("\n" + "=" * 60)
        print("    BUILD FAILED!")
        print("=" * 60)
        print("\nPlease check the errors above and try again.")
        sys.exit(1)

if __name__ == "__main__":
    main()

os.system("pause")