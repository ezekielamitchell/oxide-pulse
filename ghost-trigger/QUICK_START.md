# ESP32 JTAG Debugging - Quick Start

## 🚀 Prerequisites Checklist

- [ ] ESP32 WROVER board connected via USB
- [ ] JTAG adapter (ESP-Prog or FTDI) connected to GPIO12-15
- [ ] VS Code with Cortex-Debug extension installed
- [ ] xtensa-esp32-elf-gdb installed (see below)

---

## ⚡ 5-Minute Setup

### 1. Install ESP32 GDB
```bash
# Option A: Homebrew (recommended)
brew tap espressif/homebrew-esp
brew install esp32-elf-gdb

# Option B: Manual install
wget https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v13.2_20240530/xtensa-esp-elf-gdb-13.2_20240530-aarch64-apple-darwin.tar.xz
tar -xf xtensa-esp-elf-gdb-*.tar.xz -C ~/.espressif/tools/
export PATH="$HOME/.espressif/tools/xtensa-esp-elf-gdb/bin:$PATH"

# Verify
xtensa-esp32-elf-gdb --version
```

### 2. Build Firmware
```bash
cd ghost-trigger
cargo build
```

### 3. Flash Firmware (First Time Only)
```bash
cargo run
# Wait for upload to complete, then Ctrl+C
```

### 4. Test JTAG Connection
```bash
openocd -f interface/ftdi/esp32_devkitj_v1.cfg -f target/esp32.cfg
```

Expected output:
```
Info : JTAG tap: esp32.cpu0 tap/device found
Info : starting gdb server for esp32.cpu0 on 3333
```

Press Ctrl+C if successful.

### 5. Start Debugging
1. Open `src/main.rs` in VS Code
2. Set breakpoint on line 21: `core::hint::black_box(&threat_detected);`
3. Press **F5**
4. Select "ESP32 JTAG Debug"

---

## 🎯 The Mission: Inject a Threat Signal

### What You'll Do
The code has a variable `threat_detected` that's always `false`. You'll use JTAG to change it to `true` while the program is running - simulating a threat injection attack.

### Steps

1. **Hit the Breakpoint**
   - Code will pause at line 21
   - You'll see `threat_detected = false` in the Variables panel

2. **Inject the Threat**
   - In Debug Console, type:
     ```gdb
     set threat_detected = true
     ```
   - Or use Watch panel to change the value

3. **Continue Execution**
   - Press F5 or click Continue
   - Watch the serial monitor

4. **Observe the Attack**
   - Serial output will show:
     ```
     ERROR - !! THREAT DETECTED !! [Cycle: X]
     WARN  - Engaging backup protocols...
     ```

✅ **Success!** You've manually injected a signal into processor memory via hardware debugging.

---

## 🔧 Troubleshooting

### "xtensa-esp32-elf-gdb not found"
Add to your shell profile (~/.zshrc or ~/.bashrc):
```bash
export PATH="$HOME/.espressif/tools/xtensa-esp-elf-gdb/bin:$PATH"
```
Then: `source ~/.zshrc`

### OpenOCD Connection Failed
1. Check JTAG wiring (GPIO12-15, GND)
2. Verify USB connection
3. Try different config:
   ```bash
   openocd -f interface/ftdi/esp-prog.cfg -f target/esp32.cfg
   ```

### Breakpoints Not Hitting
Rebuild with debug symbols:
```bash
cargo clean
cargo build  # NOT --release
```

---

## 📚 Learn More

See [JTAG_SETUP.md](./JTAG_SETUP.md) for:
- Complete hardware setup
- Advanced debugging techniques
- Memory inspection
- Watchpoints and register access
- Security implications
- Production hardening

---

## Hardware Pinout Reference

### ESP32 WROVER JTAG Pins
| Function | GPIO | Pin |
|----------|------|-----|
| TDI      | 12   | JTAG Data In |
| TDO      | 15   | JTAG Data Out |
| TCK      | 13   | JTAG Clock |
| TMS      | 14   | JTAG Mode Select |
| GND      | GND  | Ground |

Connect these to your JTAG adapter (ESP-Prog, FTDI, or J-Link).

---

**Ready for professional embedded debugging? Let's go!** 🚀
