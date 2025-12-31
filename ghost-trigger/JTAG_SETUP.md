# ESP32 WROVER JTAG Debugging Setup Guide

## Overview
This document provides complete instructions for establishing a professional embedded development environment with JTAG debugging on ESP32 WROVER using VS Code, OpenOCD, and GDB.

## Purpose
This Proof of Concept validates the ability to:
- Pause the processor at any point during execution
- Manually inject "threat" signals directly into memory
- Simulate rigorous hardware-level testing required for defense and robotics applications
- Move beyond simple serial logging to professional embedded debugging

---

## Hardware Requirements

### ESP32 WROVER Board
- **Chip**: ESP32 (Xtensa dual-core)
- **Flash**: 4MB minimum
- **Features**: WiFi, BT, Dual Core, 240MHz
- **Revision**: v1.0 or later

### JTAG Interface
The ESP32 WROVER has dedicated JTAG pins:
- **TDI** (GPIO12)
- **TDO** (GPIO15)
- **TCK** (GPIO13)
- **TMS** (GPIO14)
- **GND**
- **VCC** (3.3V)

### JTAG Adapter Options
1. **ESP-Prog** (Recommended for ESP32)
   - Native Espressif JTAG adapter
   - Built-in UART for serial console
   - Direct USB connection

2. **FTDI FT2232H/FT4232H**
   - Generic JTAG/UART adapter
   - Widely available
   - Requires configuration

3. **J-Link** (EDU/Commercial)
   - Professional-grade debugger
   - Excellent performance
   - Higher cost

---

## Software Installation

### 1. Install ESP32-Specific GDB

The standard GDB doesn't support Xtensa architecture. You need the ESP32-specific version:

#### Option A: Via Homebrew (Easiest)
```bash
brew tap espressif/homebrew-esp
brew install esp32-elf-gdb
```

#### Option B: Manual Installation
```bash
# Download from Espressif releases
wget https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v13.2_20240530/xtensa-esp-elf-gdb-13.2_20240530-aarch64-apple-darwin.tar.xz

# Extract to a permanent location
tar -xf xtensa-esp-elf-gdb-*.tar.xz -C ~/.espressif/tools/

# Add to PATH in your shell profile (.zshrc or .bashrc)
export PATH="$HOME/.espressif/tools/xtensa-esp-elf-gdb/bin:$PATH"
```

#### Verify Installation
```bash
xtensa-esp32-elf-gdb --version
# Should output: GNU gdb (esp-gdb) 13.2 or later
```

### 2. Install OpenOCD

OpenOCD is already installed via Homebrew:
```bash
openocd --version
# Output: Open On-Chip Debugger 0.12.0
```

### 3. Install VS Code Extensions

Required extensions:
```bash
# Cortex-Debug (JTAG debugging interface)
code --install-extension marus25.cortex-debug

# Rust Analyzer (optional, for Rust development)
code --install-extension rust-lang.rust-analyzer
```

---

## Hardware Connection

### ESP-Prog to ESP32 WROVER

| ESP-Prog Pin | ESP32 WROVER Pin | Function |
|--------------|------------------|----------|
| TDI          | GPIO12           | Test Data In |
| TDO          | GPIO15           | Test Data Out |
| TCK          | GPIO13           | Test Clock |
| TMS          | GPIO14           | Test Mode Select |
| GND          | GND              | Ground |
| VCC          | 3.3V             | Power (optional) |

**CRITICAL**:
- Ensure all grounds are connected
- Use 3.3V logic levels (NOT 5V)
- GPIO12-15 are the default JTAG pins on ESP32

### Verify Hardware Connection
```bash
# List USB devices
system_profiler SPUSBDataType

# You should see the JTAG adapter listed
```

---

## Project Configuration

### 1. Cargo Configuration
The project is already configured in [.cargo/config.toml](ghost-trigger/.cargo/config.toml):
- Target: `xtensa-esp32-espidf`
- Linker: `ldproxy`
- Debug symbols enabled in dev profile

### 2. SDK Configuration
The [sdkconfig.defaults](ghost-trigger/sdkconfig.defaults) has been optimized for JTAG debugging:
- `CONFIG_ESP32_DEBUG_OCDAWARE=y` - JTAG awareness
- `CONFIG_ESP_TASK_WDT_EN=n` - Disable watchdog during breakpoints
- `CONFIG_COMPILER_OPTIMIZATION_DEBUG=y` - Optimal debug symbols
- `CONFIG_FREERTOS_USE_TRACE_FACILITY=y` - Thread visibility

### 3. VS Code Launch Configuration
Two debug configurations are available in [.vscode/launch.json](ghost-trigger/.vscode/launch.json):

#### **ESP32 JTAG Debug** (Launch)
- Flashes firmware and starts debugging
- Halts at `app_main()`
- Full control from reset

#### **ESP32 Attach (Running)** (Attach)
- Attaches to running firmware
- Halts processor on attach
- Useful for debugging live systems

---

## Building the Firmware

### Clean Build (Recommended)
```bash
cd ghost-trigger
cargo clean
cargo build
```

The debug binary will be at:
```
ghost-trigger/target/xtensa-esp32-espidf/debug/ghost-trigger
```

### Verify Debug Symbols
```bash
xtensa-esp32-elf-objdump -h target/xtensa-esp32-espidf/debug/ghost-trigger | grep debug
```
You should see sections like `.debug_info`, `.debug_line`, etc.

---

## Debugging Workflow

### Step 1: Flash Firmware (First Time)
```bash
cd ghost-trigger
cargo run
```
This flashes the firmware via serial. You only need to do this once or when code changes.

### Step 2: Connect JTAG Adapter
- Connect ESP-Prog to ESP32 WROVER JTAG pins
- Connect USB cable to computer
- Power on the ESP32

### Step 3: Test OpenOCD Connection
```bash
openocd -f interface/ftdi/esp32_devkitj_v1.cfg -f target/esp32.cfg
```

**Expected output:**
```
Info : clock speed 20000 kHz
Info : JTAG tap: esp32.cpu0 tap/device found: 0x120034e5
Info : JTAG tap: esp32.cpu1 tap/device found: 0x120034e5
Info : [esp32.cpu0] Examination succeed
Info : [esp32.cpu1] Examination succeed
Info : starting gdb server for esp32.cpu0 on 3333
```

Press `Ctrl+C` to stop. If you see errors, check:
- JTAG connections
- USB device permissions
- Correct adapter configuration file

### Step 4: Start Debugging in VS Code

1. Open `ghost-trigger/src/main.rs`
2. Set a breakpoint on line 21 (the `black_box` call)
3. Press `F5` or click "Run > Start Debugging"
4. Select "ESP32 JTAG Debug"

**VS Code will:**
- Launch OpenOCD
- Connect GDB
- Reset and halt the processor
- Flash the firmware (if needed)
- Break at `app_main()`
- Continue to your breakpoint

---

## The Proof of Concept: Memory Injection Attack

### Test Code Analysis
The [main.rs](ghost-trigger/src/main.rs) contains a `threat_detected` variable that is always `false` in code. This simulates a sensor that never detects threats.

```rust
let mut threat_detected = false;  // Always false in code
```

### Objective
Use JTAG to manually change `threat_detected` from `false` to `true` while the processor is paused, simulating a threat injection attack.

### Procedure

#### 1. Start Debugging
- Set breakpoint at line 21: `core::hint::black_box(&threat_detected);`
- Start debugging (F5)
- Code will pause at the breakpoint

#### 2. Inspect Variable
In VS Code Debug Console or Watch panel:
```gdb
print threat_detected
# Output: $1 = false
```

Or find the memory address:
```gdb
print &threat_detected
# Output: $2 = (bool *) 0x3ffb1234
```

#### 3. Inject Threat Signal
Manually set the variable to `true`:
```gdb
set threat_detected = true
```

Or directly modify memory:
```gdb
set {bool}0x3ffb1234 = 1
```

#### 4. Verify Modification
```gdb
print threat_detected
# Output: $3 = true
```

#### 5. Continue Execution
Press `F5` or use:
```gdb
continue
```

#### 6. Observe Result
The serial monitor will show:
```
ERROR - !! THREAT DETECTED !! [Cycle: 42]
WARN  - Engaging backup protocols...
```

This proves you successfully injected a threat signal directly into processor memory via JTAG.

---

## Advanced Debugging Techniques

### Memory Inspection
```gdb
# Read memory region
x/16xb 0x3ffb0000

# Dump variable in different formats
print/x threat_detected   # Hexadecimal
print/d counter          # Decimal
print/t threat_detected   # Binary
```

### Watchpoints (Hardware Breakpoints)
```gdb
# Break when threat_detected is written to
watch threat_detected

# Break when threat_detected changes value
watch -l threat_detected

# Break when threat_detected is read
rwatch threat_detected
```

ESP32 has 2 hardware watchpoint registers.

### Register Access
```gdb
# View all CPU registers
info registers

# View specific register
print $pc     # Program counter
print $sp     # Stack pointer
print $a0     # Argument register 0
```

### Thread/Task Debugging (FreeRTOS)
```gdb
# List all FreeRTOS tasks
info threads

# Switch to specific task
thread 2

# View task backtrace
backtrace
```

### Flash Breakpoints
OpenOCD can set unlimited software breakpoints in flash:
```gdb
break main.rs:23
break app_main
```

### Live Variable Modification
```gdb
# Change counter value mid-execution
set counter = 1000

# Change loop delay
set delay_ms = 100
```

---

## Troubleshooting

### GDB Not Found
**Error**: `xtensa-esp32-elf-gdb: command not found`

**Solution**:
```bash
# Verify installation
which xtensa-esp32-elf-gdb

# Add to PATH if not found
export PATH="$HOME/.espressif/tools/xtensa-esp-elf-gdb/bin:$PATH"
```

### OpenOCD Can't Connect
**Error**: `Error: JTAG scan chain interrogation failed`

**Solutions**:
1. Check JTAG wiring (especially TDI, TDO, TCK, TMS, GND)
2. Verify 3.3V power to ESP32
3. Check USB cable and adapter
4. Try different JTAG adapter configuration:
   ```bash
   openocd -f interface/ftdi/esp-prog.cfg -f target/esp32.cfg
   ```

### Watchdog Timeouts
**Error**: Task watchdog triggers during debugging

**Solution**: Already configured in `sdkconfig.defaults`:
```
CONFIG_ESP_TASK_WDT_EN=n
CONFIG_ESP_INT_WDT_EN=n
```

If still occurring, rebuild:
```bash
cargo clean
cargo build
```

### Breakpoints Not Hitting
**Issues**:
- Code is optimized out
- Debug symbols missing

**Solution**:
1. Verify debug build:
   ```bash
   cargo build  # NOT cargo build --release
   ```

2. Check optimization in Cargo.toml:
   ```toml
   [profile.dev]
   debug = true
   opt-level = "z"  # Still allows debugging
   ```

### Can't Modify Variables
**Error**: Variable is read-only or optimized out

**Solution**:
1. Use `black_box()` to prevent optimization:
   ```rust
   core::hint::black_box(&threat_detected);
   ```

2. Make variable `volatile`:
   ```rust
   use core::ptr::{read_volatile, write_volatile};
   ```

---

## Security Implications

### Attack Surface
This PoC demonstrates:
- **Memory injection attacks** via JTAG
- **Control flow hijacking** by modifying variables
- **Sensor spoofing** by bypassing normal input channels

### Defense Mechanisms
In production systems for defense/robotics:

1. **JTAG Security Fuses**
   ```c
   // Disable JTAG in production
   CONFIG_SECURE_DISABLE_JTAG=y
   ```

2. **Secure Boot**
   - Verify firmware signatures
   - Prevent unauthorized code execution

3. **Flash Encryption**
   - Encrypt firmware in flash
   - Protect against physical extraction

4. **Memory Protection**
   - Use MPU (Memory Protection Unit)
   - Isolate critical data

5. **Tamper Detection**
   - Monitor for JTAG connection attempts
   - Implement anti-debugging techniques

---

## Next Steps

### 1. Expand Test Scenarios
- Inject complex data structures
- Modify function pointers
- Manipulate peripheral registers

### 2. Automated Testing
Create GDB scripts for automated injection:
```gdb
# test_injection.gdb
break main.rs:21
commands
    set threat_detected = true
    continue
end
run
```

Run with:
```bash
xtensa-esp32-elf-gdb -x test_injection.gdb target/xtensa-esp32-espidf/debug/ghost-trigger
```

### 3. Integration with CI/CD
- Automated hardware-in-the-loop testing
- Regression testing with JTAG
- Fault injection testing

### 4. Real Sensor Integration
Replace mock variable with actual sensor:
```rust
let threat_detected = read_radar_sensor();
let threat_detected = check_motion_detector();
```

---

## References

- [ESP-IDF JTAG Debugging](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/jtag-debugging/)
- [OpenOCD User Guide](http://openocd.org/doc/html/index.html)
- [GDB Documentation](https://sourceware.org/gdb/current/onlinedocs/gdb/)
- [Cortex-Debug Extension](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug)
- [ESP32 Technical Reference](https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf)

---

## Summary

You now have a fully configured professional embedded development environment with:
- ✅ Hardware-level JTAG debugging
- ✅ Memory inspection and modification
- ✅ Breakpoint and watchpoint support
- ✅ FreeRTOS thread debugging
- ✅ Real-time variable injection

This establishes the foundation for rigorous hardware-level testing in defense and robotics applications, moving far beyond simple serial logging to true embedded systems validation.
