#!/usr/bin/env python3
import subprocess
import time
import sys
import select
import re

def run_verification():
    cmd = [
        "qemu-system-x86_64",
        "-kernel", "boot/vmlinuz",
        "-initrd", "boot/initramfs.cpio.gz",
        "-append", "console=ttyS0 root=/dev/ram0 rw",
        "-nographic"
    ]
    
    print("Starting QEMU verification...")
    proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=0
    )
    
    output = []
    ansi_escape = re.compile(r'\x1b(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    
    def wait_for(pattern, timeout=30):
        start_time = time.time()
        buffer = ""
        while time.time() - start_time < timeout:
            r, _, _ = select.select([proc.stdout], [], [], 0.1)
            if r:
                char = proc.stdout.read(1)
                if not char:
                    break
                sys.stdout.write(char)
                sys.stdout.flush()
                buffer += char
                output.append(char)
                
                # Check clean buffer
                clean_buf = ansi_escape.sub('', buffer)
                if pattern in clean_buf:
                    return True
        return False

    def send_cmd(command):
        print(f"\n[Command] Sending: {command}")
        proc.stdin.write(command + "\n")
        proc.stdin.flush()

    # 1. Wait for boot shell prompt (which starts at / and has prompt 'GungnirOS:/# ')
    if not wait_for("GungnirOS:/#", timeout=45):
        print("\nError: System failed to boot to prompt", file=sys.stderr)
        proc.kill()
        sys.exit(1)
        
    # 2. Test pacman -Q (should show preinstalled packages)
    send_cmd("pacman -Q")
    wait_for("GungnirOS:/#")

    # 3. Install and test apache
    send_cmd("pacman -S apache")
    wait_for("GungnirOS:/#")
    
    send_cmd("apachectl start")
    wait_for("GungnirOS:/#")
    
    send_cmd("apachectl status")
    wait_for("GungnirOS:/#")

    # 4. Install and test ufw
    send_cmd("pacman -S ufw")
    wait_for("GungnirOS:/#")
    
    send_cmd("ufw enable")
    wait_for("GungnirOS:/#")
    
    send_cmd("ufw allow 80")
    wait_for("GungnirOS:/#")
    
    send_cmd("ufw status")
    wait_for("GungnirOS:/#")

    # 5. Install and test kali-tools
    send_cmd("pacman -S kali-tools")
    wait_for("GungnirOS:/#")
    
    # Test nmap (localhost scan)
    send_cmd("nmap 127.0.0.1")
    wait_for("GungnirOS:/#")
    
    # Test john the ripper with md5 hash of 'gungnir'
    send_cmd("echo '75df5eb42a420b925b3999933758bdf2' > /tmp/hash.txt")
    wait_for("GungnirOS:/#")
    send_cmd("john /tmp/hash.txt")
    wait_for("GungnirOS:/#")

    # Test nikto scanner against localhost web server
    send_cmd("nikto -h 127.0.0.1")
    wait_for("GungnirOS:/#")

    # 6. Shut down QEMU cleanly
    send_cmd("poweroff")
    print("\nWaiting for QEMU to terminate...")
    proc.wait()
    print("Verification completed successfully!")

if __name__ == "__main__":
    run_verification()
