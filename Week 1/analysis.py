p1 = 3.893

def peff(n, perf):
    return perf / p1 / n

log_text = """1 | 1 |    3.893    | 1.00000
1 | 2 |    7.827    | 1.00527
1 | 4 |    15.385   | 0.98799
1 | 8 |    30.324   | 0.97364
1 | 16 |   59.837   | 0.96064
1 | 32 |   119.551  | 0.95963
1 | 56 |   195.629  | 0.89735
1 | 56 |   198.963  | 0.91873
2 | 112 |  400.619  | 0.91873
4 | 224 |  755.937  | 0.86687
8 | 448 |  1296.481 | 0.74338
16 | 896 | 2392.513 | 0.68589"""

log_lines = log_text.split("\n")
data = []
for x in log_lines:
    parts = x.split("|")
    partsClean = [float(x) for x in parts]
    data.append(partsClean)

parallel_eff=[peff(x[1],x[2]) for x in data]

perf_gain_on_mpi = []
prev = data[0][2]
for x in range(0,7):
    cur = data[x][2]
    perf_gain_on_mpi.append(100*(cur - prev) / prev)
    prev = cur

perf_gain_on_nodes = []
prev = data[7][2]
for x in range(7, 12):
    cur = data[x][2]
    perf_gain_on_nodes.append(100*(cur-prev)/prev)
    prev = cur

def print_by_line(pre,arr):
    for l in arr:
        print(pre,l)

print("parallel efficiency: ")
print_by_line("",parallel_eff)

print("Performace gained by adding MPI tasks:")
print_by_line("+%",perf_gain_on_mpi)

print("Performace gained by adding nodes:")
print_by_line("+%",perf_gain_on_nodes)
