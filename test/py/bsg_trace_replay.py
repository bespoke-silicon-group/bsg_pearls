class BsgTraceField:
	def __init__(self, name, width):
		self.name = name
		self.width = width
		self.value = 0

	# Assumed to be unsigned
	def set(self, value):
		if value < 2**self.width:
			self.value = value
		else:
			print("Error: value exceeds length of bitfield")

	def get(self):
		return self.value

	def get_bits(self):
		return f"{self.value:0{self.width}b}"

	def __repr__(self):
		return f"logic [{self.width-1}:0] {self.name};"


class BsgTraceStruct:
	def __init__(self, name, width):
		self.name = name
		self.width = width
		self.fields = []

		self.add_field("padding", width)

	def __setattr__(self, name, value):
		if hasattr(self, "fields") and hasattr(self, name):
			getattr(self, name).set(value)
		else:
			super(BsgTraceStruct, self).__setattr__(name, value)
		return self

	def adjust_padding(self):
		total = 0
		for field in self.fields:
			field = getattr(self, field)
			if field.name != "padding":
				total += field.width

		if total >= self.width:
			raise Exception("Padding must be non-negative width")

		self.padding.width = self.width - total
		self.padding.value = 0

	def add_field(self, name, width):
		setattr(self, name, BsgTraceField(name, width))
		self.fields.append(name)
		self.adjust_padding()

		return self

	def print_struct(self):
		print("typedef {")
		for field in self.fields:
			getattr(self, field).print_def()
		print("}} {name};".format(name=self.name))

	def get_bits(self):
		bs = ""
		for field in self.fields:
			bs += getattr(self, field).get_bits()

		return bs

	def get_int(self):
		bs = ""
		for field in self.fields:
			bs += getattr(self, field).get_bits()

		return int(bs, 2)

	def __str__(self):
		s = f"{self.name}"
		for field in self.fields:
			field = getattr(self, field)
			s += f" | {field.name}: {hex(field.value)}"

		return s


class BsgTraceReplayGen:
	OPCODE_SIZE = 4
	OPCODE_NOOP = "0000"
	OPCODE_SEND = "0001"
	OPCODE_RECV = "0010"
	OPCODE_DONE = "0011"
	OPCODE_FINI = "0100"
	OPCODE_DECR = "0101"
	OPCODE_INIT = "0110"

	# constructor
	def __init__(self, payload_width):
		self.payload_width = payload_width
		self.data_width = self.payload_width + self.__class__.OPCODE_SIZE
		self.fstr = "0" + str(self.payload_width) + "b"

	# get payload for a trace (helper)
	def get_payload(self, val):
		return format(val, f"{self.fstr}")

	# get trace (helper)
	def get_trace(self, opcode, val, comment=""):
		return comment + f"{opcode}_{self.get_payload(val)}\n"

	# nop
	def nop(self, comment=""):
		comment += f"// nop\n"
		return self.get_trace(self.__class__.OPCODE_NOOP, 0, comment)

	# send
	def send(self, val, comment=""):
		comment += f"// send {hex(val)}\n"
		return self.get_trace(self.__class__.OPCODE_SEND, val, comment)

	# recv packet
	def recv(self, data, comment=""):
		comment += f"// recv {hex(val)}\n"
		return self.get_trace(self.__class__.OPCODE_RECV, val, comment)

	# done
	def done(self, comment=""):
		comment += f"// done\n"
		return self.get_trace(self.__class__.OPCODE_DONE, 0, comment)

	# finish
	def finish(self, comment=""):
		comment += f"// finish\n"
		return self.get_trace(self.__class__.OPCODE_FINI, 0, comment)

	# wait
	def wait(self, val, comment=""):
		comment += f"// wait for {val} cycle(s)\n"
		return self.get_trace(
			self.__class__.OPCODE_INIT, val, comment
		) + self.get_trace(self.__class__.OPCODE_DECR, 0)
