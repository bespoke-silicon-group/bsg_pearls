import sys
import os

sys.path.append(os.environ.get("BSG_DESIGNS_TARGET_DIR")+"/testing/py")
from bsg_tag_trace_gen import *

#  Client ID Mapping
# ===================
#  0 = async_reset
#  1 = osc
#  2 = osc trigger
#  3 = ds
#  4 = sel
#  5 = monitor_reset

if len(sys.argv) != 4:
  print("USAGE:")
  command = "python bsg_tag_boot.py {num_clients_p} {max_payload_width_p} {offset_p}"
  print(command)
  sys.exit("Error: tag trace generation failed")

num_masters_p       = 1
num_clients_p       = int(sys.argv[1])
max_payload_width_p = int(sys.argv[2])
offset_p            = int(sys.argv[3])

# instantiate tag trace gen
tg = TagTraceGen(num_masters_p, num_clients_p, max_payload_width_p)

# reset all bsg_tag master
tg.send(masters=0, client_id=offset_p+0, data_not_reset=0, length=0, data=0)
tg.wait(32)

# reset each bsg_tag client
tg.send(masters=0, client_id=offset_p+0, data_not_reset=0, length=1, data=0b1)       # async_reset
tg.send(masters=0, client_id=offset_p+1, data_not_reset=0, length=5, data=0b11111)   # osc
tg.send(masters=0, client_id=offset_p+2, data_not_reset=0, length=1, data=0b1)       # osc trigger
tg.send(masters=0, client_id=offset_p+3, data_not_reset=0, length=7, data=0b1111111) # ds
tg.send(masters=0, client_id=offset_p+4, data_not_reset=0, length=2, data=0b11)      # sel
tg.send(masters=0, client_id=offset_p+5, data_not_reset=0, length=1, data=0b1)       # monitor_reset

# select zero output clk
tg.send(masters=0, client_id=offset_p+4, data_not_reset=1, length=2, data=0b11)

# reset oscillator and trigger flops
tg.send(masters=0, client_id=offset_p+0, data_not_reset=1, length=1, data=0b1)

# init trigger to low, init oscillator to zero
# OSC INIT VALUE MUST BE ZERO TO AVOID X IN SIMULATION
tg.send(masters=0, client_id=offset_p+2, data_not_reset=1, length=1, data=0b0)
tg.send(masters=0, client_id=offset_p+1, data_not_reset=1, length=5, data=0b00000)

# take oscillator and trigger flops out of reset
tg.send(masters=0, client_id=offset_p+0, data_not_reset=1, length=1, data=0b0)

# trigger oscillator value
tg.send(masters=0, client_id=offset_p+2, data_not_reset=1, length=1, data=0b1)
tg.send(masters=0, client_id=offset_p+2, data_not_reset=1, length=1, data=0b0)

# reset ds, then set ds value
tg.send(masters=0, client_id=offset_p+3, data_not_reset=1, length=7, data=0b0000001)
tg.send(masters=0, client_id=offset_p+3, data_not_reset=1, length=7, data=0b0000000)

# select ds output clk
tg.send(masters=0, client_id=offset_p+4, data_not_reset=1, length=2, data=0b01)

# sweep oscillator values
for tap in range(32):
  # set osc value
  tg.send(masters=0, client_id=offset_p+1, data_not_reset=1, length=5, data=tap)
  # trigger osc value
  tg.send(masters=0, client_id=offset_p+2, data_not_reset=1, length=1, data=0b1)
  tg.send(masters=0, client_id=offset_p+2, data_not_reset=1, length=1, data=0b0)
  # reset monitor
  tg.send(masters=0, client_id=offset_p+5, data_not_reset=1, length=1, data=0b1)
  tg.send(masters=0, client_id=offset_p+5, data_not_reset=1, length=1, data=0b0)
  # wait
  tg.wait(64)

# all done
tg.done()

