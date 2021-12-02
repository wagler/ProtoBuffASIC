import random

print(str(hex(random.getrandbits(8)))[2:])
f = open("testbench/demo64.mem", 'w')
for i in range(64):
    f.write(str(hex(random.getrandbits(8)))[2:] + " ")
f.write("\n")
f.close()
