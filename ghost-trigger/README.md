# Ghost Trigger - ESP32 JTAG Debugging Proof of Concept

## Overview
Professional Rust-based embedded development environment for ESP32 WROVER with full JTAG debugging support. This project demonstrates hardware-level threat signal injection for rigorous embedded systems testing in defense and robotics applications.

## Mission Statement
Move beyond simple serial logging to establish a professional embedded toolchain with the ability to:
- Pause the processor mid-execution
- Inspect and modify memory in real-time
- Inject signals directly into running firmware
- Perform hardware-level validation and testing

---

## Quick Start

### 1. Install Dependencies
```bash
# Install GDB for ESP32
./install_gdb.sh

# Or manually
brew tap espressif/homebrew-esp
brew install esp32-elf-gdb
```

### 2. Build and Flash
```bash
cargo build
cargo run
```

### 3. Start Debugging
1. Connect JTAG adapter to ESP32 GPIO12-15
2. Open [src/main.rs](src/main.rs) in VS Code
3. Press **F5** → Select "ESP32 JTAG Debug"

See [QUICK_START.md](QUICK_START.md) for detailed walkthrough.

---

## Project Structure

```
ghost-trigger/
├── src/
│   └── main.rs                 # Main firmware with threat detection simulation
├── .vscode/
│   └── launch.json             # JTAG debugging configurations
├── .cargo/
│   └── config.toml             # Rust toolchain configuration
├── sdkconfig.defaults          # ESP-IDF configuration for JTAG
├── Cargo.toml                  # Project dependencies
├── QUICK_START.md              # 5-minute setup guide
├── JTAG_SETUP.md               # Complete hardware/software setup
├── GDB_COMMANDS.md             # GDB command reference
└── install_gdb.sh              # Automated GDB installation
```

---

## Features

### Hardware Debugging
- ✅ Full JTAG support via OpenOCD
- ✅ Hardware breakpoints and watchpoints
- ✅ Real-time memory inspection and modification
- ✅ FreeRTOS thread-aware debugging
- ✅ Register and peripheral access

### Firmware
- ✅ Rust-based ESP32 application
- ✅ ESP-IDF framework integration
- ✅ Optimized for debugging (symbols, no watchdog)
- ✅ Threat detection simulation
- ✅ Professional logging with esp-idf-svc

### Development Environment
- ✅ VS Code integration
- ✅ Cortex-Debug extension support
- ✅ Multiple debug configurations (launch/attach)
- ✅ Automated GDB setup
- ✅ Comprehensive documentation

---

## Documentation

| Document | Description |
|----------|-------------|
| [QUICK_START.md](QUICK_START.md) | 5-minute getting started guide |
| [JTAG_SETUP.md](JTAG_SETUP.md) | Complete setup, hardware, security implications |
| [GDB_COMMANDS.md](GDB_COMMANDS.md) | GDB command reference and examples |
| [install_gdb.sh](install_gdb.sh) | Automated GDB installation script |

---

## The Proof of Concept

### Scenario
The firmware contains a `threat_detected` variable that is permanently `false` in code:
```rust
let mut threat_detected = false;  // Always false
```

### Goal
Use JTAG to inject a "threat signal" by changing the variable to `true` while the processor is running.

### Procedure
1. Set breakpoint at the sensor check
2. Pause execution via JTAG
3. Modify `threat_detected` to `true` via GDB
4. Continue execution
5. Observe system response to injected threat

### Success Criteria
Serial output shows:
```
ERROR - !! THREAT DETECTED !! [Cycle: X]
WARN  - Engaging backup protocols...
```

This validates the ability to perform hardware-level fault injection and testing.

---

## Hardware Requirements

### ESP32 Board
- **Model**: ESP32 WROVER
- **Chip**: ESP32 (Xtensa dual-core)
- **Flash**: 4MB+
- **Revision**: v1.0 or later

### JTAG Adapter
One of:
- ESP-Prog (recommended)
- FTDI FT2232H/FT4232H
- J-Link (EDU or commercial)

### Connections
| ESP32 Pin | JTAG Signal |
|-----------|-------------|
| GPIO12    | TDI         |
| GPIO13    | TCK         |
| GPIO14    | TMS         |
| GPIO15    | TDO         |
| GND       | GND         |

---

## Software Requirements

### System
- macOS (Apple Silicon or Intel)
- Homebrew
- Rust toolchain with ESP32 support
- VS Code

### Tools
- `xtensa-esp32-elf-gdb` (ESP32-specific GDB)
- `openocd` (JTAG interface)
- `espflash` (firmware flashing)
- Cortex-Debug extension for VS Code

### Installation
See [QUICK_START.md](QUICK_START.md) or run:
```bash
./install_gdb.sh
```

---

## Debugging Workflow

### Build with Debug Symbols
```bash
cargo build  # Uses dev profile with debug = true
```

### Flash Firmware
```bash
cargo run  # Flash via serial
```

### Launch Debugger
1. In VS Code, press **F5**
2. Select "ESP32 JTAG Debug"
3. Debugger halts at `app_main()`
4. Set breakpoints and continue

### Attach to Running Firmware
1. In VS Code, press **F5**
2. Select "ESP32 Attach (Running)"
3. Processor halts immediately
4. Inspect state without reflashing

---

## Advanced Features

### Memory Inspection
```gdb
x/16xb 0x3ffb0000  # Examine 16 bytes in hex
print &threat_detected  # Get variable address
```

### Watchpoints
```gdb
watch threat_detected  # Break when written
rwatch threat_detected  # Break when read
```

### Thread Debugging
```gdb
info threads  # List FreeRTOS tasks
thread 2      # Switch to task #2
```

See [GDB_COMMANDS.md](GDB_COMMANDS.md) for complete reference.

---

## Configuration Files

### [sdkconfig.defaults](sdkconfig.defaults)
ESP-IDF configuration optimized for JTAG:
- `CONFIG_ESP32_DEBUG_OCDAWARE=y` - JTAG awareness
- `CONFIG_ESP_TASK_WDT_EN=n` - Disable watchdog
- `CONFIG_COMPILER_OPTIMIZATION_DEBUG=y` - Debug symbols
- `CONFIG_FREERTOS_USE_TRACE_FACILITY=y` - Thread visibility

### [.vscode/launch.json](.vscode/launch.json)
Two debug configurations:
1. **ESP32 JTAG Debug** - Flash and debug from reset
2. **ESP32 Attach (Running)** - Attach to running firmware

### [.cargo/config.toml](.cargo/config.toml)
Rust toolchain configuration:
- Target: `xtensa-esp32-espidf`
- Debug symbols enabled in dev profile
- ESP-IDF v5.3.3

---

## Security Implications

This PoC demonstrates:
- **Memory injection attacks** via JTAG
- **Control flow hijacking** by modifying variables
- **Sensor spoofing** bypassing normal inputs

### Production Hardening
For deployed systems:
1. Disable JTAG via security fuses
2. Enable secure boot
3. Enable flash encryption
4. Use memory protection (MPU)
5. Implement tamper detection

See [JTAG_SETUP.md](JTAG_SETUP.md) for detailed security discussion.

---

## Troubleshooting

### GDB Not Found
```bash
# Verify installation
which xtensa-esp32-elf-gdb

# Install if missing
./install_gdb.sh
```

### OpenOCD Connection Failed
- Check JTAG wiring (GPIO12-15, GND)
- Verify USB connection
- Try different adapter config

### Breakpoints Not Hitting
```bash
# Rebuild with debug symbols
cargo clean
cargo build
```

See [JTAG_SETUP.md](JTAG_SETUP.md) troubleshooting section.

---

## Next Steps

### Expand Testing
- Inject complex data structures
- Modify function pointers
- Manipulate peripheral registers

### Real Sensor Integration
Replace mock variable with actual sensors:
```rust
let threat_detected = read_radar_sensor();
let threat_detected = check_motion_detector();
```

### Automated Testing
Create GDB scripts for automated injection:
```bash
xtensa-esp32-elf-gdb -x inject_threat.gdb
```

See [JTAG_SETUP.md](JTAG_SETUP.md) for detailed next steps.

---

## Technical Details

### Target Platform
- **MCU**: ESP32 (Xtensa LX6 dual-core @ 240MHz)
- **RAM**: 520KB SRAM
- **Flash**: 4MB
- **Features**: WiFi, Bluetooth, FreeRTOS

### Toolchain
- **Rust**: 1.77+ with ESP32 support
- **ESP-IDF**: v5.3.3
- **GDB**: esp-gdb v13.2
- **OpenOCD**: 0.12.0

### Debug Protocol
- **Interface**: JTAG (IEEE 1149.1)
- **Transport**: USB
- **Server**: OpenOCD
- **Client**: GDB with MI2 interface

---

## References

- [ESP-IDF JTAG Debugging Guide](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/jtag-debugging/)
- [OpenOCD Documentation](http://openocd.org/doc/html/index.html)
- [GDB Manual](https://sourceware.org/gdb/current/onlinedocs/gdb/)
- [ESP32 Technical Reference](https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf)
- [Cortex-Debug Extension](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug)

---

## License

This is a Proof of Concept for educational and professional development purposes.

## Author

Ezekiel A. Mitchell <Ezekielam@icloud.com>

---

## Summary

This project establishes a complete professional embedded development environment with hardware-level debugging capabilities, moving beyond simple serial logging to rigorous validation suitable for defense and robotics applications. The threat injection PoC demonstrates the ability to pause execution and manipulate processor state directly via JTAG for comprehensive embedded systems testing.

**Ready to debug at the hardware level.** 🚀
