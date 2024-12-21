
import argparse
import sys, os, glob, re

import matplotlib
import matplotlib.pyplot as plt

def gen(logpath):
  data = {}

  filelist = glob.glob(os.path.join(logpath, '*.log'))
  filelist.sort()
  for file in filelist:
    corner = os.path.basename(file).replace('.log', '')
    print(corner+',', end='')
    data[corner] = {"pos": [], "neg": []}
    f = open(file, "r")
    lines = f.readlines()
    # Trim last edge which will be glitchy
    lines = lines[:-1]
    pos_list = []
    neg_list = []
    pos_line_num = 0
    neg_line_num = 0
    for line in lines[:-1]:
      pos_pattern = re.compile(r".*POSEDGE.*[0-9]+\s+ps")
      neg_pattern = re.compile(r".*NEGEDGE.*[0-9]+\s+ps")
      if neg_pattern.match(line):
        line_num = int(line.split(':')[0])
        # remove previous number if two lines are close to each other
        # usually caused by smooth transition of osc
        if line_num <= neg_line_num + 2:
          neg_list.pop(-1)
        neg_list.append(line.split()[-2])
        neg_line_num = line_num
      if pos_pattern.match(line):
        line_num = int(line.split(':')[0])
        if line_num <= pos_line_num + 2:
          pos_list.pop(-1)
        pos_list.append(line.split()[-2])
        pos_line_num = line_num
    # Print results
    print('\nNEG,', end='')
    for num in neg_list:
      print(num+',', end='')
      data[corner]["pos"].append(int(num))
    print('\nPOS,', end='')
    for num in pos_list:
      print(num+',', end='')
      data[corner]["neg"].append(int(num))
    print('')

    return data

def plot(data, logpath):
  for k,v in data.items():
    data[k]['per'] = []
    for p,n in zip(v['pos'], v['neg']):
      data[k]['per'].append(p + n)
    data[k]['duty'] = []
    for p,n in zip(v['pos'], v['per']):
      data[k]['duty'].append(p / n)

  fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6), constrained_layout=True)
  ax1.title.set_text("DUTY CYCLE")
  for k,v in data.items():
    vals = v['duty']
    x_labels = [i for i in range(len(vals))]
    ax1.plot(x_labels, vals, label=k)
  ax2.title.set_text("PERIOD")
  for k,v in data.items():
    vals = v['per']
    x_labels = [i for i in range(len(vals))]
    ax2.plot(x_labels, vals, label=k)
  fig.savefig(os.path.join(logpath, "graph.png"))
  #plt.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generates a csv of clk generator transitions')
    parser.add_argument('--logpath', help='Path to the POSEDGE/NEGEDGE summarized logs', required=True)
    args = parser.parse_args()

    logpath = args.logpath

    data = gen(logpath)
    plot(data, logpath)

