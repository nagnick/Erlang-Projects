# Overview
Repository for projects and assignments for Distributed Operating System Principles (COP5615).

# Team
Nicolas Garcia
Anurag Shenoy

# Project 1: Bitcoin Mining 
Finding hashes with a given number of leading Zeros.

Gatorlink ID used: `nicolasgarcia`.

## How to run
1. Install Erlang: <https://www.erlang.org/downloads>.
2. Clone repository or copy `main.erl` file.
3. Open an Erlang terminal with `name` and `setcookie` parameters. Example: `erl -name s@10.20.242.14 -setcookie xyz`. Replace IP with your private (local network) IP address.
4. Compile `main.erl` using `c(main).` within the erlang terminal.
5. Run `main:superVisorActor(10000000, 5, 4).`. The first argument is the number of strings to check. Second arg is number of Zeros you want to find in the hash. Third arg is the number of actor processes you want to spin up.
6. Optional: You can add machines whenever you want by opening an erlang terminal in the new machine using:
    1. Run **Step 3** using new machine's private IP and a different unique name. Example: `erl -name v@10.20.242.15 -setcookie xyz`
    2. Run **Step 4** to compile the code.
    3. Execute the command `main:remoteClient('s@10.20.242.14')`. Note: The IP must be the IP of the server.

## Questions:
### 1. Size of Work
Size of the work unit that you determined results in the best performance for your implementation and an explanation
 of how you determined it. The size of the work unit refers to the number of sub-problems that a worker gets in a
 single request from the boss.

Table 1 which shows the units of work and wall and cpu times:
| Total Work    |	Number of Actors    | Unit of Work per Actor    | Total Wall Time Taken (ms)    | Total CPU Time Taken (ms) |
| ------------- | --------------------- | ------------------------- | ----------------------------- | ------------------------- |
| 2000000       | 2	                    | 1000000	                | 3238                          | 6456                      | 
| 2000000       | 4	                    | 500000	                | 1884                          | 7487                      | 
| 2000000       | 6	                    | 333333	                | 1661                          | 9887                      | 
| 2000000       | 8                 	| 250000	                | 1464                          | 11491                     | 
| 2000000       | 10	                | 200000	                | 1545                          | 13109                     | 
| 2000000       | 12                	| 166666	                | 1487                          | 15431                     | 
| 2000000       | 14	                | 142857	                | 1473                          | 18009                     | 
| 2000000       | 16	                | 125000	                | 1494                          | 19918                     | 
| 2000000       | 18	                | 111111	                | 1476                          | 23294                     | 
| 2000000       | 20	                | 100000	                | 1471                          | 25487                     |  

Table 2 which shows relation between amount of work given to each Erlang actor for a fixed number of actors:
| Total Work | 	Number of Actors    | Unit of Work per Actor    | Wall Time Taken (ms)  |
| ---------- | -------------------- | ------------------------- | --------------------- |
| 100000	 | 8	                | 12500	                    | 101                   | 
| 1000000	 | 8	                | 125000	                | 754                   | 
| 10000000	 | 8	                | 1250000	                | 7175                  | 

From the above, we can see that when we have 8 workers, the wall time reduces to the lowest level and doesn't improve when we increase the number of workers.

We ran the code on M1 Macbook Air machines, which have 8 CPU cores, and so it makes sense that each M1 Macbook Air would work best when all the eight physical CPU cores are being put to full use.

### 2. Input 4
The result of running your program for input 4 i.e. for finding coins with 4 Zeros and 8 Actors.

```log
(w@127.0.0.1)2> main:superVisorActor(1000000, 4, 8).      
nicolasgarcia"%*O       0000d6548116a73f02acbb67982e9e8ff6d95cba3137761280043b0f1e96df4f
nicolasgarciaX2E        0000b38242ec3c476186511eb2af20d952a7bdd9ecac2cb04a49b2c74aa72923
nicolasgarcia~Bb        0000d98ab518a2d56b9f26caa0715c8dbfd9876f6cb52c480c0fa1ba5d1e3e62
nicolasgarcia".+2       0000306c5bfc3bc2d259d3f7095b57d13e436c12a0a608425b2e045418b5136f
nicolasgarcia"-G@       000083538474921ee492b183515e2fc2437944f0923a5cf25e776ad8f8429ecd
nicolasgarcia"-2K       00007d3b774742a38a0f957ad56c3d368b7907ecf7edda2d6c2838ac95f0f4c4
nicolasgarcia"+\&       00006c171b7ce341b9f52795cdf6cf8802a06bc0a0b40622b362de6190f7fcef
nicolasgarcia5up        0000f6dbc49838e90947d4e906a7a045914b386d843391418b2bac8fdeb2d04b
nicolasgarcia1mr        000027f6268d80d8f41761c71596cdb013fe4b2e97e20a8e6cbab3b8be6b3aa5
REAL TIME OF PROGRAM in milliseconds:938
RUN TIME OF ALL ACTORS in milliseconds is:6960
ok
```

### 3. Running Time & Ratio
The running time for the above is reported by time for the above and report the time.  The ratio of CPU time to REAL
TIME tells you how many cores were effectively used in the computation.  If you are close to 1 you have almost no
parallelism (points will be subtracted).

From Table 1, we can see that the ratio of CPU to Real Time is increasing by the same factor as the number of actors used.
This indicates that almost perfect parallelism is achieved.

| Number of Workers | Ratio of CPU time to Wall time    |
| ----------------- | --------------------------------- |
| 2	                | 1.993823348                       |
| 4	                | 3.973991507                       |
| 6	                | 5.95243829                        |
| 8	                | 7.849043716                       |
| 10                | 8.484789644                       |
| 12                | 10.37726967                       |
| 14                | 12.22606925                       |
| 16                | 13.33199465                       |
| 18                | 15.78184282                       |
| 20                | 17.32630863                       |

We can also see that the parallelism is almost perfect till 8 cores, and deteriorates thereafter as there are only 8 physical cores and the processes have to be rotated by the CPU onto the physical cores. The overhead faced by the CPU due to assignment of more than 8 processes to cores.

### 4. Coin with most Zeros
The coin with the most 0s you managed to find.

Trials:

7 Zeros:

nicolasgarcia)QKy##     0000000184f9a6f1e0b5875fc0592bfe196dd89fa8aa89e20ce6d1780b3a6bd1
nicolasgarcia,w[Ws9     000000041b7d5959327c9cf38c9e92296b784e7c1e0735dbe3b948a9e9536104
nicolasgarcia"by7by     00000004579b04563a04896a903380a4dab040673b54e89c53014f73960e6524

6 Zeros:

nicolasgarcia/Aw=   000000593a39c3c25a95742633361ed5f1a162d1825fd509421692db1221b7c0

### 5. Largest number of working machines
The largest number of working machines you were able to run your code with.

We were able to run the code with 2 machines but as long as the supervisor actor is running the only limit to the amount of machines that can join is what is allowed by erlang.

