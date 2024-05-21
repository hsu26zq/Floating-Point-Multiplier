#############################################
## Final Project							#
## Generate Test Data						#
#############################################

## Number of Test Data ##
COUNT = 1000

## Output File ##
PATH = "pattern.dat"

## Switch Between Hex or Binary ##
USE_HEX =True;

import struct
import random
import sys

def float_2_ieee754(value):
	packed = struct.pack('>d', value)
	unpacked = struct.unpack('>Q', packed)[0]
	ieee754 = format(unpacked, '08X') if USE_HEX else format(unpacked, '064b')
	return ieee754

random.seed(1)
with open(PATH, 'w') as file:
	for i in range(COUNT):
		num1 = random.randint(0, 2**64 - 1)
		num2 = random.randint(0, 2**64 - 1)

		float1 = struct.unpack('>d', struct.pack('>Q', num1))[0]
		float2 = struct.unpack('>d', struct.pack('>Q', num2))[0]
		float3 = float1 * float2

		A = float_2_ieee754(float1)
		B = float_2_ieee754(float2)
		Z = float_2_ieee754(float3)

		file.write(str(A) + '\n'
				 + str(B) + '\n'
				 + str(Z) + '\n'
				 + '\n')
