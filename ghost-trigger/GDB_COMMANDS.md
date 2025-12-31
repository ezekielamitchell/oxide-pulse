# GDB Command Reference for ESP32 JTAG Debugging

Quick reference for common GDB commands when debugging ESP32 firmware via JTAG.

---

## 🎯 Basic Commands

### Execution Control
```gdb
run                    # Start program execution
continue (c)           # Continue execution after breakpoint
next (n)               # Step over (next line, don't enter functions)
step (s)               # Step into (enter functions)
finish                 # Run until current function returns
until 25               # Run until line 25
kill                   # Stop program execution
quit                   # Exit GDB
```

### Breakpoints
```gdb
break main             # Break at function 'main'
break main.rs:21       # Break at line 21 in main.rs
break *0x40080000      # Break at specific address
info breakpoints       # List all breakpoints
delete 1               # Delete breakpoint #1
delete                 # Delete all breakpoints
disable 2              # Disable breakpoint #2
enable 2               # Enable breakpoint #2
clear main.rs:21       # Remove breakpoint at line 21
```

### Watchpoints (Hardware)
ESP32 has **2 hardware watchpoints**.
```gdb
watch threat_detected      # Break when variable is written
rwatch threat_detected     # Break when variable is read
awatch threat_detected     # Break when variable is accessed (read/write)
info watchpoints           # List all watchpoints
delete 3                   # Delete watchpoint #3
```

---

## 🔍 Inspection Commands

### Variables
```gdb
print threat_detected          # Print variable value
print counter                  # Print counter
print/x threat_detected        # Print in hexadecimal
print/t threat_detected        # Print in binary
print/d counter                # Print in decimal
print &threat_detected         # Print variable address
print sizeof(threat_detected)  # Print variable size

# Pretty printing
set print pretty on            # Enable pretty printing
```

### Memory
```gdb
x/16xb 0x3ffb0000         # Examine 16 bytes in hex
x/8xw 0x3ffb0000          # Examine 8 words (32-bit) in hex
x/16xh 0x3ffb0000         # Examine 16 half-words (16-bit)
x/s 0x3ffb0000            # Examine as string
x/i 0x40080000            # Examine as instruction

# Format: x/[count][format][size] address
# count: number of units
# format: x(hex) d(decimal) t(binary) s(string) i(instruction)
# size: b(byte) h(half) w(word) g(giant, 64-bit)
```

### Registers
```gdb
info registers             # Show all registers
info registers a0 a1       # Show specific registers (a0, a1)
print $pc                  # Print program counter
print $sp                  # Print stack pointer
print $a0                  # Print argument register 0

# Xtensa-specific registers
print $sar                 # Shift amount register
print $windowbase          # Register window base
print $windowstart         # Register window start
```

### Backtrace (Call Stack)
```gdb
backtrace (bt)             # Full backtrace
backtrace 5                # Show only 5 frames
frame 2                    # Switch to frame #2
up                         # Move up call stack
down                       # Move down call stack
info frame                 # Info about current frame
info args                  # Show function arguments
info locals                # Show local variables
```

---

## 🛠️ Modification Commands

### Change Variables
```gdb
set threat_detected = true     # Set boolean to true
set counter = 1000             # Set integer to 1000
set threat_detected = 1        # Set to 1 (true)

# Set via memory address
set {bool}0x3ffb1234 = 1
set {int}0x3ffb5678 = 42
set {char}0x3ffb0000 = 'A'
```

### Modify Memory
```gdb
# Write single value
set *((int*)0x3ffb0000) = 0xdeadbeef

# Write multiple bytes
set {unsigned char[4]}0x3ffb0000 = {0xde, 0xad, 0xbe, 0xef}

# Write string
set {char[6]}0x3ffb0000 = "HELLO"
```

### Modify Registers
```gdb
set $pc = 0x40080000          # Jump to address
set $sp = $sp + 16            # Adjust stack pointer
set $a0 = 42                  # Set argument register
```

---

## 🧵 Thread/Task Debugging (FreeRTOS)

ESP32 runs FreeRTOS with multiple tasks.

```gdb
info threads               # List all FreeRTOS tasks
thread 2                   # Switch to thread/task #2
thread apply all bt        # Show backtrace for all threads
thread apply 1 2 bt        # Show backtrace for threads 1 and 2

# Example output:
# * 1    Thread 1 "main" 0x40080abc in main ()
#   2    Thread 2 "IDLE0" 0x40081234 in prvIdleTask ()
#   3    Thread 3 "IDLE1" 0x40081234 in prvIdleTask ()
```

---

## 🔧 ESP32-Specific Commands

### OpenOCD Monitor Commands
Use `monitor` prefix to send commands to OpenOCD:

```gdb
monitor reset halt         # Reset CPU and halt
monitor reset run          # Reset CPU and run
monitor halt               # Halt CPU
monitor resume             # Resume CPU

# Flash operations
monitor flash erase_sector 0 0 10    # Erase sectors 0-10
monitor flash write_image erase firmware.bin 0x10000

# ESP32-specific
monitor esp32 appimage_offset 0x10000   # Set app offset
monitor esp32 apptrace start file://trace.log 0 -1 5
```

### CPU-Specific
```gdb
# ESP32 is dual-core, switch between cores
monitor esp32 smp_break 1    # Break both cores together
monitor esp32 smp_break 0    # Break cores independently

# View core state
monitor targets              # Show all targets (cpu0, cpu1)
```

---

## 📊 Advanced Debugging

### Conditional Breakpoints
```gdb
break main.rs:21 if counter > 100     # Break only if counter > 100
break app_main if threat_detected    # Break if threat_detected is true

# Set condition on existing breakpoint
condition 1 counter == 50             # Breakpoint 1 triggers when counter == 50
```

### Commands on Breakpoint
```gdb
# Execute commands automatically when breakpoint hits
break main.rs:21
commands
    print counter
    print threat_detected
    continue
end

# More complex example
break main.rs:21
commands
    silent                          # Don't print breakpoint message
    printf "Counter: %d\n", counter
    if threat_detected
        printf "THREAT DETECTED!\n"
        set threat_detected = false
    end
    continue
end
```

### Scripting
```gdb
# Define custom commands
define print_state
    print counter
    print threat_detected
end

# Use it
print_state

# Save to file: threat_injection.gdb
# Run with: gdb -x threat_injection.gdb
```

---

## 🎬 Example: Automated Threat Injection

Create file: `inject_threat.gdb`
```gdb
# Connect to OpenOCD
target remote :3333

# Load symbols
file target/xtensa-esp32-espidf/debug/ghost-trigger

# Reset and halt
monitor reset halt

# Set breakpoint at the check point
break main.rs:21

# Define injection command
commands
    silent
    print counter
    if counter == 10
        print "=== INJECTING THREAT ==="
        set threat_detected = true
    end
    continue
end

# Start execution
continue
```

Run with:
```bash
xtensa-esp32-elf-gdb -x inject_threat.gdb
```

---

## 🐛 Debugging Common Issues

### Variable Optimized Out
```gdb
# Force variable to stay in memory
# Add to Rust code:
core::hint::black_box(&threat_detected);

# Or use volatile read/write:
use core::ptr::{read_volatile, write_volatile};
```

### Cannot Access Memory
```gdb
# Try different memory region
info mem                  # Show memory regions

# ESP32 memory map:
# 0x3FF00000 - 0x3FF7FFFF: Internal SRAM0
# 0x3FF80000 - 0x3FFFFFFF: Internal SRAM1
# 0x3FFAE000 - 0x3FFDFFFF: DMA-capable SRAM
# 0x40000000 - 0x400C1FFF: Instruction RAM
# 0x40080000 - 0x400BFFFF: Instruction cache
```

### Watchpoint Not Working
```gdb
# ESP32 has only 2 hardware watchpoints
# Delete unused ones:
info watchpoints
delete 1
delete 2
```

---

## 📋 Cheat Sheet

| Task | Command |
|------|---------|
| Run program | `run` |
| Continue | `c` |
| Step over | `n` |
| Step into | `s` |
| Print variable | `print var` |
| Set variable | `set var = value` |
| Set breakpoint | `break file:line` |
| Set watchpoint | `watch var` |
| Show backtrace | `bt` |
| List threads | `info threads` |
| Show registers | `info registers` |
| Examine memory | `x/16xb addr` |
| Reset CPU | `monitor reset halt` |

---

## 🔗 GDB Resources

- [GDB Manual](https://sourceware.org/gdb/current/onlinedocs/gdb/)
- [ESP32 Memory Map](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/general-notes.html#memory-layout)
- [OpenOCD Commands](http://openocd.org/doc/html/General-Commands.html)
- [FreeRTOS Thread Aware Debugging](https://www.freertos.org/FreeRTOS-Plus/FreeRTOS_Plus_Trace/RTOS_Trace_Instructions_GDB.html)

---

**Pro Tip**: Create a `.gdbinit` file in your project directory for automatic startup commands:
```gdb
# .gdbinit
set pagination off
set print pretty on
target remote :3333
monitor reset halt
load
thb app_main
continue
```
