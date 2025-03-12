import pymem
import os
import customtkinter
import tkinter
from tkinter import messagebox
from ctypes import windll, byref, c_ulong, c_size_t, c_void_p

PAGE_READWRITE = 0x04

customtkinter.set_appearance_mode('dark')
app = customtkinter.CTk()
app.geometry('700x300')
app.title('HORRIBLE SOURCE + NO PROTECTION .gg/AHK')

label = customtkinter.CTkLabel(app, text='.gg/AHK', text_color='#FF0000')
label.place(relx=0.5, rely=0.1, anchor=tkinter.CENTER)

entry = customtkinter.CTkEntry(app, placeholder_text='process name', width=120, height=25, border_width=2, corner_radius=10)
entry.place(relx=0.5, rely=0.2, anchor=tkinter.CENTER)

def change_memory_permissions(handle, address, size, permissions):
    old_protect = c_ulong(0)
    windll.kernel32.VirtualProtectEx(handle, c_void_p(address), c_size_t(size), permissions, byref(old_protect))
    return old_protect.value

def is_valid_memory_address(pm, address, length):
    try:
        # Attempt to read the memory region to check if it's valid
        pm.read_bytes(address, length)
        return True
    except pymem.exception.MemoryReadError:
        return False

def replace_string_with_periods(procname, address, length):
    try:
        pm = pymem.Pymem(procname)
        
        # Check if the memory address is valid
        if not is_valid_memory_address(pm, address, length):
            print(f"Skipping Invalid Address: {hex(address)}")
            return False

        value = '.' * length
        old_protect = change_memory_permissions(pm.process_handle, address, length, PAGE_READWRITE)
        pm.write_string(address, value)
        change_memory_permissions(pm.process_handle, address, length, old_protect)
        print(f"Success: Replaced String at {hex(address)} (length: {length})")
        return True
    except pymem.exception.ProcessNotFound:
        messagebox.showerror("Error", f"Process '{procname}' not found.")
    except pymem.exception.MemoryWriteError:
        print(f"Failed to write to memory address: {hex(address)}")
    except Exception as e:
        messagebox.showerror("Error", f"An error occurred: {str(e)}")
    return False

def button_event():
    procname = entry.get()
    if not procname:
        messagebox.showwarning("Warning", "Please enter a process name.")
        return
    
    if not os.path.exists("strings.txt"):
        messagebox.showerror("Error", "strings.txt file not found.")
        return
    
    success_count = 0
    error_count = 0
    
    try:
        with open("strings.txt", "r") as file:
            lines = file.readlines()
        
        for line in lines:
            if "): " in line:
                try:
                    address_part, rest = line.split("): ")
                    address = int(address_part.split(" (")[0], 0)
                    length = int(address_part.split(" (")[1])
                    if replace_string_with_periods(procname, address, length):
                        success_count += 1
                    else:
                        error_count += 1
                except (ValueError, IndexError):
                    print(f"Skipping Invalid Line: {line.strip()}")
                    error_count += 1
    except Exception as e:
        messagebox.showerror("Error", f"Failed to read strings.txt: {str(e)}")
    
    print(f"Finished processing. Success: {success_count}, Errors: {error_count}")

button = customtkinter.CTkButton(
    app, width=120, height=32, border_width=0, corner_radius=8,
    fg_color='#FF0000', hover_color='#6A6767', text='remove string',
    command=button_event
)
button.place(relx=0.5, rely=0.8, anchor=tkinter.CENTER)

app.mainloop()