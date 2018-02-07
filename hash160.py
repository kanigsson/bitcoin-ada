import array
import binascii
import hashlib
import struct

def hash160(s):
    s = hashlib.sha256(s)
    print s.hexdigest()
    h = hashlib.new('ripemd160')
    h.update(s.digest())
    return h.digest()

input = "522102439c82485854aecdffee256d940450529a7a107b5246184e34ddc074e203ca152102eeddc0d7ac5e504c0dceb10d0d183e3823bbf454628775cda2cc1ddcd5a91a2c21021475443068b9fbbaff25b00df6d48f7fd08418245040167d796fa21631a1badc53ae"
print input
input_bin = binascii.unhexlify(input)
print len(input_bin)
print binascii.hexlify(input_bin[::-1])
h = hash160(input_bin)
print binascii.hexlify(h)
