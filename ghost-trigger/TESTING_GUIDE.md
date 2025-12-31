# Ghost Trigger - Testing Guide

Complete guide for testing the threat injection proof of concept on ESP32 WROVER.

---

## 🎯 What You're Testing

The firmware has a `threat_detected` variable that is **permanently `false`** in the code:
```rust
let mut threat_detected = false;  // Always false - line 10 in main.rs
```

You'll use JTAG to manually change it to `true` while the processor is running, proving hardware-level signal injection.

---

## Test Method 1: Serial Monitoring (Basic Test)

This verifies the firmware works correctly before attempting JTAG debugging.

### Step 1: Flash and Monitor
```bash
cd ghost-trigger
cargo run
```

### Step 2: Expected Serial Output
You should see continuous messages like:
```
INFO  - System altered!
INFO  - System secure. [Cycle: 1]
INFO  - System secure. [Cycle: 2]
INFO  - System secure. [Cycle: 3]
...
```

**Key Point**: You will NEVER see "THREAT DETECTED" because `threat_detected` is always `false` in code.

### Step 3: Stop Monitoring
Press **Ctrl+C** to exit.

✅ **Success Criteria**: Firmware runs, serial output shows "System secure" messages continuously.

---

## Test Method 2: JTAG Threat Injection (Advanced Test)

This is the **main proof of concept** - injecting a threat signal via JTAG.

### Prerequisites
1. ✅ ESP32 WROVER connected via USB
2. ✅ JTAG adapter connected to GPIO12-15
3. ✅ ESP32 GDB installed (`./install_gdb.sh`)
4. ✅ VS Code with Cortex-Debug extension

### Hardware Setup
Connect JTAG adapter to ESP32:

| ESP32 Pin | JTAG Signal | Wire Color (typical) |
|-----------|-------------|---------------------|
| GPIO12    | TDI         | Orange              |
| GPIO13    | TCK         | Yellow              |
| GPIO14    | TMS         | Brown               |
| GPIO15    | TDO         | Green               |
| GND       | GND         | Black               |

**CRITICAL**: Ensure GND is connected!

### Step-by-Step JTAG Test

#### 1. Verify JTAG Connection
```bash
cd ghost-trigger
openocd -f interface/ftdi/esp32_devkitj_v1.cfg -f target/esp32.cfg
```

**Expected output:**
```
Info : clock speed 20000 kHz
Info : JTAG tap: esp32.cpu0 tap/device found: 0x120034e5
Info : JTAG tap: esp32.cpu1 tap/device found: 0x120034e5
Info : starting gdb server for esp32.cpu0 on 3333
```

Press **Ctrl+C** if you see this. If not, check:
- JTAG wiring (especially GND)
- USB connection
- Adapter is powered

#### 2. Flash Firmware (If Not Already Flashed)
```bash
cargo run
# Wait for "Flashing has completed!"
# Press Ctrl+C
```

#### 3. Open VS Code
```bash
code .
```

Open [src/main.rs](src/main.rs)

#### 4. Set Breakpoint
Click in the left margin on **line 21** (the `black_box` call):
```rust
core::hint::black_box(&threat_detected);  // <-- Set breakpoint here
```

A red dot should appear.

#### 5. Start JTAG Debugging
- Press **F5** (or Run → Start Debugging)
- Select **"ESP32 JTAG Debug"** from the dropdown

**What happens:**
1. OpenOCD starts and connects to ESP32
2. GDB connects to OpenOCD
3. Processor resets and halts at `app_main()`
4. Firmware continues to your breakpoint
5. Execution pauses at line 21

#### 6. Inspect Variable
When paused at the breakpoint, look at the **Variables** panel (left sidebar).

You should see:
```
Local
  threat_detected: false
  counter: 1 (or some number)
```

Or use the **Debug Console** (bottom panel):
```gdb
print threat_detected
```
Output: `$1 = false`

#### 7. INJECT THE THREAT
This is the critical moment! In the **Debug Console**, type:
```gdb
set threat_detected = true
```

Then verify:
```gdb
print threat_detected
```
Output: `$2 = true` ✅

#### 8. Continue Execution
Press **F5** or click the **Continue** button (▶️).

#### 9. Observe Serial Monitor
Open a new terminal and monitor serial output:
```bash
espflash monitor
```

**Expected output:**
```
ERROR - !! THREAT DETECTED !! [Cycle: 42]
WARN  - Engaging backup protocols...
```

🎉 **SUCCESS!** You've injected a threat signal directly into processor memory via JTAG!

#### 10. Continue Testing
The program will reset `threat_detected` back to `false` and continue. To inject again:
- Wait for breakpoint to hit
- Repeat steps 7-9

---

## Test Method 3: Automated GDB Script

For repeatable testing, create an automated injection script.

### Create Test Script
```bash
cat > inject_threat.gdb << 'EOF'
# Connect to OpenOCD
target remote :3333

# Load symbols
file target/xtensa-esp32-espidf/debug/ghost-trigger

# Reset and halt
monitor reset halt

# Set breakpoint
break main.rs:21

# Auto-inject on 10th cycle
commands
    silent
    print counter
    if counter == 10
        printf "\n=== AUTO-INJECTING THREAT ===\n"
        set threat_detected = true
        printf "threat_detected = %d\n", threat_detected
    end
    continue
end

# Start execution
continue
EOF
```

### Run Automated Test
In one terminal, start OpenOCD:
```bash
openocd -f interface/ftdi/esp32_devkitj_v1.cfg -f target/esp32.cfg
```

In another terminal, run the script:
```bash
xtensa-esp32-elf-gdb -x inject_threat.gdb
```

In a third terminal, monitor serial:
```bash
espflash monitor
```

**Expected**: On cycle 10, threat is auto-injected and you see "THREAT DETECTED" message.

---

## Verification Checklist

### Basic Functionality Test
- [ ] Firmware compiles without errors
- [ ] Firmware flashes successfully to ESP32
- [ ] Serial monitor shows "System secure" messages
- [ ] Messages increment counter each cycle
- [ ] No "THREAT DETECTED" messages (expected)

### JTAG Connection Test
- [ ] OpenOCD detects ESP32 via JTAG
- [ ] Both CPU cores detected (cpu0, cpu1)
- [ ] GDB server starts on port 3333
- [ ] No JTAG scan errors

### JTAG Debugging Test
- [ ] VS Code debugger launches successfully
- [ ] Processor halts at `app_main()`
- [ ] Breakpoint hits at line 21
- [ ] Variables visible in debug panel
- [ ] `threat_detected` shows as `false`

### Threat Injection Test
- [ ] Can modify `threat_detected` via GDB command
- [ ] Variable shows `true` after injection
- [ ] Continue execution works
- [ ] Serial shows "THREAT DETECTED" message
- [ ] Serial shows "Engaging backup protocols"
- [ ] System resets `threat_detected` to `false`
- [ ] Can inject multiple times

---

## Troubleshooting Test Failures

### Serial Monitor Shows Nothing
**Problem**: No output after flashing.

**Solutions**:
```bash
# Check USB port
ls /dev/cu.usbserial*

# Monitor with explicit port
espflash monitor --port /dev/cu.usbserial-0001

# Reset ESP32
# Press physical RESET button or use:
espflash reset
```

### JTAG Connection Failed
**Error**: `Error: JTAG scan chain interrogation failed`

**Solutions**:
1. Check wiring with multimeter
2. Verify 3.3V power to ESP32
3. Try different JTAG config:
   ```bash
   openocd -f interface/ftdi/esp-prog.cfg -f target/esp32.cfg
   ```
4. Check USB cable (use data cable, not charge-only)

### Breakpoint Not Hitting
**Problem**: Debugger doesn't pause at line 21.

**Solutions**:
1. Verify debug symbols:
   ```bash
   xtensa-esp32-elf-objdump -h target/xtensa-esp32-espidf/debug/ghost-trigger | grep debug
   ```
2. Rebuild with clean:
   ```bash
   cargo clean
   cargo build
   ```
3. Check optimization level in [Cargo.toml](Cargo.toml:16-18)

### Variable Shows "Optimized Out"
**Problem**: Can't see `threat_detected` in debugger.

**Solution**: The `black_box` on line 21 prevents this. If it still happens:
```rust
// Add volatile operations
use core::ptr::{read_volatile, write_volatile};

unsafe {
    let ptr = &mut threat_detected as *mut bool;
    let val = read_volatile(ptr);
    core::hint::black_box(val);
}
```

### Can't Modify Variable
**Error**: "Cannot access memory at address 0x..."

**Solutions**:
1. Ensure processor is paused (hit breakpoint)
2. Use correct syntax:
   ```gdb
   set threat_detected = true   # Not "= 1"
   ```
3. Or set via memory address:
   ```gdb
   print &threat_detected       # Get address
   set {bool}0x3ffb1234 = 1     # Use address
   ```

### Watchdog Resets
**Problem**: ESP32 resets during debugging.

**Solution**: Watchdogs are disabled in [sdkconfig.defaults](sdkconfig.defaults:18-19). If still happening:
```bash
cargo clean
cargo build
# Re-flash
cargo run
```

---

## Advanced Testing Scenarios

### 1. Memory Dump Test
Verify you can read raw memory:
```gdb
# At breakpoint
print &threat_detected
# Note address (e.g., 0x3ffb1234)

# Dump surrounding memory
x/16xb 0x3ffb1234
```

### 2. Watchpoint Test
Break when variable is written:
```gdb
watch threat_detected
continue
# Should break when variable is reset to false
```

### 3. Multi-Injection Test
Inject threat multiple times in one session:
```gdb
# First injection
set threat_detected = true
continue
# Wait for breakpoint to hit again

# Second injection
set threat_detected = true
continue
# Repeat
```

### 4. Persistent Injection Test
Keep threat active (prevent reset):
```gdb
# Set conditional breakpoint on reset
break main.rs:28 if threat_detected == false
commands
    set threat_detected = true
    printf "Prevented threat reset!\n"
    continue
end
```

### 5. Thread-Aware Test
View all FreeRTOS tasks:
```gdb
info threads
thread 2              # Switch to IDLE task
backtrace            # View call stack
thread 1             # Back to main
```

---

## Performance Metrics

Expected behavior:
- **Cycle time**: ~1 second per iteration (1000ms delay)
- **Breakpoint hit**: Every cycle while debugging
- **Injection effect**: Immediate (next iteration shows THREAT)
- **Reset time**: ~2 seconds (2000ms delay after threat)

---

## Success Definition

**Proof of Concept is SUCCESSFUL when:**

1. ✅ Firmware runs normally, showing "System secure" continuously
2. ✅ JTAG debugger can pause execution mid-loop
3. ✅ Variable `threat_detected` is visible and shows `false`
4. ✅ GDB command changes `threat_detected` to `true`
5. ✅ Continued execution triggers threat response
6. ✅ Serial output shows "THREAT DETECTED" message
7. ✅ This can be repeated multiple times

**This proves**: You can pause the processor and manually inject arbitrary signals into memory, validating hardware-level testing capabilities for embedded systems.

---

## Next Steps After Successful Test

### 1. Document Your Results
Create a test report:
```bash
cat > test_results.md << 'EOF'
# Ghost Trigger Test Results

Date: $(date)
Hardware: ESP32 WROVER v1.0
JTAG Adapter: [Your adapter]

## Test 1: Serial Monitor
- Status: PASS/FAIL
- Notes: ...

## Test 2: JTAG Connection
- Status: PASS/FAIL
- Notes: ...

## Test 3: Threat Injection
- Status: PASS/FAIL
- Injection cycle: 42
- Response time: Immediate
- Notes: ...
EOF
```

### 2. Expand Testing
- Inject different values (not just true/false)
- Modify `counter` to skip iterations
- Change delay times dynamically
- Test with real sensor inputs

### 3. Production Hardening
See [JTAG_SETUP.md](JTAG_SETUP.md) security section for:
- Disabling JTAG in production
- Implementing secure boot
- Flash encryption
- Tamper detection

---

## Quick Reference Commands

### Flash Firmware
```bash
cargo run
```

### Test JTAG
```bash
openocd -f interface/ftdi/esp32_devkitj_v1.cfg -f target/esp32.cfg
```

### Monitor Serial
```bash
espflash monitor
```

### Debug in VS Code
```
F5 → ESP32 JTAG Debug
```

### Inject Threat (at breakpoint)
```gdb
set threat_detected = true
```

### Check Variable
```gdb
print threat_detected
```

### Continue
```
F5 or type: continue
```

---

**Ready to test? Start with Method 1 (Serial Monitor) to verify basic functionality, then move to Method 2 (JTAG Injection) for the full proof of concept!** 🚀
