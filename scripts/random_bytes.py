import random

f = open("testbench/faketable1.mem", 'w')

# Fake table 1
for j in range(3):
    for i in range(64):
        f.write(str(hex(random.getrandbits(8)))[2:] + " ")

f.write("00 "*64)
f.close()

# Fake table 2
for j in range(2):
    for i in range(64):
        f.write(str(hex(random.getrandbits(8)))[2:] + " ")
f.write("\n")
f.close()
