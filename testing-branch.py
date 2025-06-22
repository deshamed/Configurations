import pymem
import ctypes
import re
import time
from ctypes import wintypes

# Memory Constants
PAGE_READONLY = 0x02
PAGE_READWRITE = 0x04
PAGE_WRITECOPY = 0x08
PAGE_EXECUTE_READ = 0x20
MEM_COMMIT = 0x1000
MEM_PRIVATE = 0x20000
MEM_MAPPED = 0x40000

# Configuration - EDIT THESE
KEYWORDS = [
    "software", "upgrade", "authenticator", 
    "thunder", "mapper", "Assembly",
    "BitcoinMiner", "newuimatrix", ".py"
]
MIN_STRING_LENGTH = 4  # Minimum string length to check

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

def get_memory_regions(pm):
    """Retrieve all accessible memory regions"""
    VirtualQueryEx = ctypes.windll.kernel32.VirtualQueryEx
    mbi = MEMORY_BASIC_INFORMATION()
    address = 0
    regions = []

    while address < 0x7FFFFFFFFFFF:
        if not VirtualQueryEx(pm.process_handle, ctypes.c_void_p(address), 
                            ctypes.byref(mbi), ctypes.sizeof(mbi)):
            break
            
        if (mbi.State == MEM_COMMIT and 
            mbi.Protect in (PAGE_READONLY, PAGE_READWRITE, PAGE_WRITECOPY, PAGE_EXECUTE_READ) and 
            mbi.Type in (MEM_PRIVATE, MEM_MAPPED)):
            regions.append((mbi.BaseAddress, mbi.RegionSize))
        address += mbi.RegionSize

    return regions

def find_strings_with_keywords(data):
    """Find ALL strings containing keywords (case-insensitive)"""
    results = []
    patterns = [
        rb'[\x20-\x7E]{%d,}' % MIN_STRING_LENGTH,          # ASCII
        rb'(?:[\x20-\x7E]\x00){%d,}' % MIN_STRING_LENGTH   # Unicode
    ]

    # Create combined regex pattern for all keywords
    keyword_pattern = re.compile(
        b'|'.join(re.escape(k.lower().encode()) for k in KEYWORDS), 
        re.IGNORECASE
    )

    for pattern in patterns:
        for match in re.finditer(pattern, data):
            try:
                string_data = match.group()
                if keyword_pattern.search(string_data):
                    decoded = string_data.decode('utf-16le' if b'\x00' in string_data else 'ascii')
                    results.append((match.start(), decoded))
            except:
                continue
    return results

def clean_memory(pm, regions):
    """Precisely clean keyword strings with multiple write attempts"""
    cleaned = 0
    failed = 0
    chunk_size = 2 * 1024 * 1024  # 2MB chunks

    for base, size in regions:
        for offset in range(0, size, chunk_size):
            current_chunk = min(chunk_size, size - offset)
            try:
                data = pm.read_bytes(base + offset, current_chunk)
                for str_offset, string in find_strings_with_keywords(data):
                    absolute_addr = base + offset + str_offset
                    
                    # Try multiple write methods
                    for attempt in range(3):  # 3 attempts per string
                        try:
                            # Method 1: Write as string
                            pm.write_string(absolute_addr, '.' * len(string))
                            cleaned += 1
                            break
                        except:
                            try:
                                # Method 2: Write as raw bytes
                                if any(ord(c) > 127 for c in string):  # Unicode
                                    pm.write_bytes(absolute_addr, b'.\x00' * len(string))
                                else:  # ASCII
                                    pm.write_bytes(absolute_addr, b'.' * len(string))
                                cleaned += 1
                                break
                            except:
                                if attempt == 2:  # Final attempt failed
                                    failed += 1
                                continue

            except Exception as e:
                failed += 1
                continue

    return cleaned, failed

def main():
    process_name = "explorer.exe"
    print(f"[*] Starting PRECISION cleaning of {process_name}")
    print(f"[*] Targeting ALL strings containing: {', '.join(KEYWORDS)}")

    try:
        pm = pymem.Pymem(process_name)
        regions = get_memory_regions(pm)
        print(f"[+] Scanning {len(regions)} memory regions...")
        
        cleaned, failed = clean_memory(pm, regions)
        
        print(f"\n[+] Results:")
        print(f"    Cleaned keyword strings: {cleaned}")
        print(f"    Failed attempts: {failed}")
        print(f"    Success rate: {cleaned/(cleaned+failed)*100:.2f}%")
        
    except Exception as e:
        print(f"[!] Critical Error: {str(e)}")
    finally:
        if 'pm' in locals():
            pm.close_process()

if __name__ == "__main__":
    start_time = time.time()
    main()
    print(f"[*] Completed in {time.time()-start_time:.2f} seconds")
