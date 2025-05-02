import pymem
import ctypes
import re
from ctypes import wintypes

# Memory constants
PAGE_READONLY = 0x02
PAGE_READWRITE = 0x04
PAGE_WRITECOPY = 0x08
PAGE_EXECUTE_READ = 0x20
MEM_COMMIT = 0x1000
MEM_PRIVATE = 0x20000
MEM_MAPPED = 0x40000

class MEMORY_BASIC_INFORMATION(ctypes.Structure):
    _fields_ = [
        ('BaseAddress', ctypes.c_void_p),
        ('AllocationBase', ctypes.c_void_p),
        ('AllocationProtect', wintypes.DWORD),
        ('RegionSize', ctypes.c_size_t),
        ('State', wintypes.DWORD),
        ('Protect', wintypes.DWORD),
        ('Type', wintypes.DWORD),
    ]

def is_readable(protect):
    return protect in [PAGE_READONLY, PAGE_READWRITE, PAGE_WRITECOPY, PAGE_EXECUTE_READ]

def get_memory_regions(pm):
    VirtualQueryEx = ctypes.windll.kernel32.VirtualQueryEx
    mbi = MEMORY_BASIC_INFORMATION()
    address = 0
    regions = []

    while address < 0x7FFFFFFFFFFF:
        if not VirtualQueryEx(pm.process_handle, ctypes.c_void_p(address), ctypes.byref(mbi), ctypes.sizeof(mbi)):
            break
        # Only scan PRIVATE and MAPPED
        if mbi.State == MEM_COMMIT and is_readable(mbi.Protect) and mbi.Type in (MEM_PRIVATE, MEM_MAPPED):
            regions.append((mbi.BaseAddress, mbi.RegionSize))
        address += mbi.RegionSize
    return regions

def find_strings(data, min_len=6):
    results = []
    for m in re.finditer(rb'[\x20-\x7E]{%d,}' % min_len, data):
        decoded = m.group().decode('ascii', errors='ignore')
        if decoded.strip('.') == '' or decoded.count('.') > len(decoded) // 2:
            continue
        results.append((m.start(), decoded))
    for m in re.finditer(rb'(?:[\x20-\x7E]\x00){%d,}' % min_len, data):
        try:
            decoded = m.group().decode('utf-16le', errors='ignore')
            if decoded.strip('.') == '' or decoded.count('.') > len(decoded) // 2:
                continue
            results.append((m.start(), decoded))
        except:
            continue
    return results

def auto_clean():
    process_name = "explorer.exe"
    keywords = [
        "matrix", "thunder", "celex", "severe", "authenticator", "isabelle", "swift", "xeno", "ui", "wavebootstrapper", "injector", "builder", "loader", ".dll", ".exe", "photon", "yerba"
    ]

    print(f"[*] Scanning process: {process_name}")
    try:
        pm = pymem.Pymem(process_name)
        print(f"[+] Attached to {process_name}")
        cleaned = 0

        for base, size in get_memory_regions(pm):
            try:
                data = pm.read_bytes(base, size)
            except:
                continue

            for offset, string in find_strings(data):
                if any(k in string.lower() for k in keywords):
                    try:
                        pm.write_string(base + offset, '.' * len(string))
                        print(f"[✓] {hex(base + offset)} | {string}")
                        cleaned += 1
                    except:
                        pass

        print(f"\n[✓] Done. Cleaned {cleaned} matching string(s).")

    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    auto_clean()
