import struct
import serial
import sys
import zlib

# usage: python3 upload.py /dev/ttyUSB0 app.bin
port = sys.argv[1]
binfile = sys.argv[2]

data = open(binfile, "rb").read()
#print("len =", len(data))
#print("crc32(bin) = 0x%08X" % (zlib.crc32(data) & 0xFFFFFFFF))
#print("head[32] =", data[:32].hex())

ser = serial.Serial(port, 115200, timeout=2)
ser.reset_input_buffer()
ser.reset_output_buffer()

def u32(x): return struct.pack("<I", x)

def read_exact(n: int) -> bytes:
    buf = b""
    while len(buf) < n:
        chunk = ser.read(n - len(buf))
        if not chunk:
            raise RuntimeError(f"timeout leyendo {n} bytes (llevo {len(buf)})")
        buf += chunk
    return buf

def cmd_upload(payload: bytes):
    print("UPLOAD:", end=" ")
    ser.reset_input_buffer()
    ser.write(b"U" + u32(len(payload)) + payload)
    ser.flush()
    ack = read_exact(1)
    if ack != b'\x55': raise RuntimeError("upload no ack")

def cmd_read(off: int, n: int) -> bytes:
    ser.reset_input_buffer()
    ser.write(b'R' + u32(off) + u32(n)); ser.flush()
    ack = read_exact(1)
    if ack == b'\xEE': raise RuntimeError("read error")
    if ack != b'\xAA': raise RuntimeError(f"bad ack {ack.hex()}")
    return read_exact(n)

def cmd_jump():
    ser.reset_input_buffer()
    ser.write(b'J'); ser.flush()
    ack = ser.read(1)    
    if ack != b'\xCC': raise RuntimeError("jump error")

def main():
    # 1) Programar
    try:
        cmd_upload(data)
        print("OK")
    except:
        print("FAIL")
        return

    # 2) Verificar leyendo por bloques
    print("VERIFY:", end=" ")
    BLOCK = 512
    ok = True
    try:
        for off in range(0, len(data), BLOCK):
            chunk = data[off:off+BLOCK]
            rb = cmd_read(off, len(chunk))
            if rb != chunk:
                print("VERIFY FAIL at offset", off)
                print("bin :", chunk[:32].hex())
                print("mem :", rb[:32].hex())
                ok = False
                break
        print("OK")
    except:
        print("FAIL")

    # 3) Saltar a la app
    if ok:
        cmd_jump()

if __name__ == "__main__":
    main()
