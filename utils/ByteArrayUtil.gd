###################################################
# Part of Bosca Ceoil Blue                        #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ByteArrayUtil extends Object


static func write_string(array: PackedByteArray, value: String) -> void:
	array.append_array(value.to_utf8_buffer())


static func write_int32(array: PackedByteArray, value: int, big_endian: bool = false) -> void:
	if big_endian: # PackedByteArray encodes in Little Endian with no setting to change that.
		var temp := PackedByteArray()
		temp.resize(4)
		temp.encode_s32(0, value)
		temp.reverse() # So we encode it using a temp array which we then reverse.
		
		array.append_array(temp)
		return
	
	var offset := array.size()
	array.resize(offset + 4)
	array.encode_s32(offset, value)


static func write_int16(array: PackedByteArray, value: int, big_endian: bool = false) -> void:
	if big_endian: # PackedByteArray encodes in Little Endian with no setting to change that.
		var temp := PackedByteArray()
		temp.resize(2)
		temp.encode_s16(0, value)
		temp.reverse() # So we encode it using a temp array which we then reverse.
		
		array.append_array(temp)
		return
	
	var offset := array.size()
	array.resize(offset + 2)
	array.encode_s16(offset, value)


static func write_vlen(array: PackedByteArray, value: int) -> void:
	# Variable-length values are used by MIDI to compactly store unsigned integers up to the 32-bit
	# limit. Numbers are represented by a sequence of bytes. Each byte uses its 7 low-order bits to
	# store a chunk of the value itself. The remaining high order bit is used as a flag. If the bit
	# is set, then the value continues into the next byte. If it is unset, then this is the last
	# byte in the sequence.
	# Value bits are ordered with most significant bits first (i.e. Big Endian).
	
	# First, encode the value into a sequence of bytes with a flag.
	# The order of bytes in the buffer is Little Endian.
	var buffer := value & 0x7F
	var remainder := value >> 7
	while remainder > 0:
		buffer <<= 8
		buffer |= 0x80
		buffer += remainder & 0x7F
		remainder = remainder >> 7
	
	# Then, append bytes from the end to the packed array, restoring Big Endian order in process.
	# This depends on PackedByteArray.append() only reading the lowest order byte of our multi-byte
	# value. While I don't expect this behavior to change, this is something to be aware of.
	while true:
		array.append(buffer)
		if buffer & 0x80:
			buffer >>= 8
			continue
		break