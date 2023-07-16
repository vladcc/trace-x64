### trace-x64
see the instructions a process is executing

### What's this?
This is a suite of tools for x64 Linux which, taken together, allow you to see
exactly what a process is doing at the instruction level.

### How is it useful?
It's useful for debugging and profiling. You can record an execution path of a
binary with given arguments, examine what something like an emulator or an
interpreter is doing (see examples), or look at what a runaway thread is
executing. Filtering with the usual command line tools can reveal some basic
profiling stats, like function call counts and traces.

### How does it work?
There are three tools in the tool chain:

tx64-trace - this is the instruction tracer. Much like a debugger, it runs or
attaches to an already running process/thread and collects its instructions by
single stepping. The emphasis is on collecting the instructions in the least
intrusive way possible, so the debugee isn't slowed down too much. That is,
latency sensitive functions like clock_gettime() should still work. This means
that only raw binary is collected and examined later offline. tx64-trace outputs
three files: an .iblob file - the executed instructions blob, and two copies of
the debugee's /proc/<pid>/maps file - one taken at the start of the trace and
one at the end. Why two copies? Because it is possible new libraries were mapped
by the traced thread during the tracing. Those mappings will only show in the
second file. Further more, if you run a process from the beginning, the first
maps file will only show the binary and the loader mapped because at that time
no libraries have yet been linked.

sym-map.awk - this script takes a maps file and produces a symbol information
file which is used during disassembly. It runs 'file' and 'nm' in the background
to see which mappings are for ELF executables and to collect the text symbols
from each of them.

tx64-print - this is the disassembler/printer. It takes as input an .iblob file
and an optional symbol file as output by sym-map.awk. It disassembles the .iblob
into readable assembly and maps any symbols to it. If no symbol file is
available, no function names will be visible.

Generally, you'd run tx64-trace, then sym-map.awk, then tx64-print, then examine
the output, or filter further.

### Examples
The code for all of the below can be found in the example-tools folder.

#### Hello world
Ever wondered exactly what it takes at system level to hello world?
```
$ cat hello.c 
#include <stdio.h>

int main(void)
{
        puts("Hello world");
        return 0;
}

$ gcc hello.c -o hello.bin -Wall

$ ./hello.bin 
Hello world
```

```
$ ./tx64-trace -x ./hello.bin 
Hello world

$ ls hello.bin*
hello.bin  hello.bin.66694.tx64-trace.iblob  hello.bin.66694.tx64-trace.maps.end  hello.bin.66694.tx64-trace.maps.start

$ ./sym-map.awk hello.bin.66694.tx64-trace.maps.end

$ ls hello.bin*
hello.bin  hello.bin.66694.tx64-trace.iblob  hello.bin.66694.tx64-trace.maps.end  hello.bin.66694.tx64-trace.maps.end.sym  hello.bin.66694.tx64-trace.maps.start

$ ./tx64-print -s hello.bin.66694.tx64-trace.maps.end.sym -i hello.bin.66694.tx64-trace.iblob | head
0x7f72b5a162b0 <_dl_catch_error@@GLIBC_PRIVATE+11968> | 48 89 e7 | mov rdi, rsp
0x7f72b5a162b3 <_dl_catch_error@@GLIBC_PRIVATE+11971> | e8 98 0d 00 00 | call 0x7f72b5a17050 <_dl_catch_error@@GLIBC_PRIVATE+15456>
0x7f72b5a17050 <_dl_catch_error@@GLIBC_PRIVATE+15456> | f3 0f 1e fa | endbr64 
0x7f72b5a17054 <_dl_catch_error@@GLIBC_PRIVATE+15460> | 55 | push rbp
0x7f72b5a17055 <_dl_catch_error@@GLIBC_PRIVATE+15461> | 48 89 e5 | mov rbp, rsp
0x7f72b5a17058 <_dl_catch_error@@GLIBC_PRIVATE+15464> | 41 57 | push r15
0x7f72b5a1705a <_dl_catch_error@@GLIBC_PRIVATE+15466> | 41 56 | push r14
0x7f72b5a1705c <_dl_catch_error@@GLIBC_PRIVATE+15468> | 41 55 | push r13
0x7f72b5a1705e <_dl_catch_error@@GLIBC_PRIVATE+15470> | 41 54 | push r12
0x7f72b5a17060 <_dl_catch_error@@GLIBC_PRIVATE+15472> | 53 | push rbx

$ ./tx64-print -s hello.bin.66694.tx64-trace.maps.end.sym -i hello.bin.66694.tx64-trace.iblob | tail
0x7f72b564554b <putenv@@GLIBC_2.2.5+2283> | 89 ef | mov edi, ebp
0x7f72b564554d <putenv@@GLIBC_2.2.5+2285> | e8 1e 57 0a 00 | call 0x7f72b56eac70 <_exit@@GLIBC_2.2.5>
0x7f72b56eac70 <_exit@@GLIBC_2.2.5+0> | f3 0f 1e fa | endbr64 
0x7f72b56eac74 <_exit@@GLIBC_2.2.5+4> | 4c 8b 05 95 e1 12 00 | mov r8, qword ptr [rip + 0x12e195]
0x7f72b56eac7b <_exit@@GLIBC_2.2.5+11> | be e7 00 00 00 | mov esi, 0xe7
0x7f72b56eac80 <_exit@@GLIBC_2.2.5+16> | ba 3c 00 00 00 | mov edx, 0x3c
0x7f72b56eac85 <_exit@@GLIBC_2.2.5+21> | eb 16 | jmp 0x7f72b56eac9d <_exit@@GLIBC_2.2.5+45>
0x7f72b56eac9d <_exit@@GLIBC_2.2.5+45> | 89 f0 | mov eax, esi
0x7f72b56eac9f <_exit@@GLIBC_2.2.5+47> | 0f 05 | syscall 
0x7f72b56eaca1 <_exit@@GLIBC_2.2.5+49> | 48 3d 00 f0 ff ff | cmp rax, -0x1000

$ ./tx64-print -s hello.bin.66694.tx64-trace.maps.end.sym -i hello.bin.66694.tx64-trace.iblob | wc -l
133537
```

With this binary it takes 133537 instructions. Ok, let's try something more
meaningful.

#### Filtering
This example assumes fib(0) == 0, fib(1) == 1, and computes the Fibonacci number
with recursion, memoization, and iteratively in a loop. This makes for a nice
demonstration of what can be achieved by only manipulating the text from
tx64-print on the command line.
```
$ ./tx64-trace -x ./fib.bin 10
55
55
55

$ ./sym-map.awk fib.bin.66938.tx64-trace.maps.end

$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | wc -l
143109
```

The whole execution took 143109 instructions. Let's examine the function call
count. For this a 15 line awk script is enough.
```
$ wc -l ./call-count.awk 
15 ./call-count.awk

$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | ./call-count.awk | head
0x7f4aff7f0590 <_dl_x86_get_cpu_features@@GLIBC_PRIVATE+3488> | 3
0x7f4aff48e660 <_IO_enable_locks@@GLIBC_PRIVATE+64> | 1
0x7f4aff4a87a0 <__strerror_r@@GLIBC_2.2.5+256> | 2
0x7f4aff7e9230 <_dl_mcount@@GLIBC_2.2.5+14976> | 1
0x7f4aff7d8310 <_dl_debug_state@@GLIBC_PRIVATE+16> | 2
0x7f4aff4a4a10 <__default_morecore@GLIBC_2.2.5+9184> | 1
0x7f4aff7f5d30 <_dl_catch_error@@GLIBC_PRIVATE+14656> | 1
0x7f4aff48f5b0 <_IO_str_underflow@@GLIBC_2.2.5+0> | 1
0x7f4aff7f2440 <_dl_catch_error@@GLIBC_PRIVATE+80> | 1
0x7f4aff7f24a0 <_dl_catch_error@@GLIBC_PRIVATE+176> | 1

$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | ./call-count.awk | wc -l
222
```

Looks like 222 functions were called. For some there were symbols, for some
there were not and the closes symbol + offset was used. Let's focus only on the
functions called from the binary image's address space.
```
$ head -n1 fib.bin.66938.tx64-trace.maps.end
55b7c0ae9000-55b7c0aea000 r--p 00000000 103:06 2373673                   /home/vld/preproj/trace-x64/example-tools/fib.bin

$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | ./call-count.awk | grep '^0x55b7c0a'
0x55b7c0aea080 <_init+128> | 1
0x55b7c0aea33a <main+0> | 1
0x55b7c0aea2c4 <fib_loop+0> | 1
0x55b7c0aea110 <deregister_tm_clones+0> | 1
0x55b7c0aea0a0 <_init+160> | 3
0x55b7c0aea000 <_init+0> | 1
0x55b7c0aea0c0 <_init+192> | 1
0x55b7c0aea1c0 <frame_dummy+0> | 1
0x55b7c0aea4ac <_fini+0> | 1
0x55b7c0aea1c9 <fib_rec+0> | 177
0x55b7c0aea213 <fib_tbl+0> | 19
0x55b7c0aea180 <__do_global_dtors_aux+0> | 1
```

Now to make it prettier and focus on the internal calls only.
```
$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | ./call-count.awk | grep '^0x55b7c0a' | grep -v '<_' | sort -t'|' -nrk2,2 | column -s'|' -t
0x55b7c0aea1c9 <fib_rec+0>                 177
0x55b7c0aea213 <fib_tbl+0>                 19
0x55b7c0aea33a <main+0>                    1
0x55b7c0aea2c4 <fib_loop+0>                1
0x55b7c0aea1c0 <frame_dummy+0>             1
0x55b7c0aea110 <deregister_tm_clones+0>    1
```

So fib_rec(10) was called 177 times, fib_tbl(10) 19, and fib_loop(10) only one.
Let's see how the execution of fib_loop(10) looked like.
```
$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | grep -E '<fib_loop\+' | sort | uniq -c | column -s'|' -t
      1 0x55b7c0aea2c4 <fib_loop+0>      f3 0f 1e fa                endbr64 
      1 0x55b7c0aea2c8 <fib_loop+4>      55                         push rbp
      1 0x55b7c0aea2c9 <fib_loop+5>      48 89 e5                   mov rbp, rsp
      1 0x55b7c0aea2cc <fib_loop+8>      48 89 7d d8                mov qword ptr [rbp - 0x28], rdi
      1 0x55b7c0aea2d0 <fib_loop+12>     48 83 7d d8 01             cmp qword ptr [rbp - 0x28], 1
      1 0x55b7c0aea2d5 <fib_loop+17>     77 06                      ja 0x55b7c0aea2dd <fib_loop+25>
      1 0x55b7c0aea2dd <fib_loop+25>     48 c7 45 f8 00 00 00 00    mov qword ptr [rbp - 8], 0
      1 0x55b7c0aea2e5 <fib_loop+33>     48 c7 45 e0 01 00 00 00    mov qword ptr [rbp - 0x20], 1
      1 0x55b7c0aea2ed <fib_loop+41>     48 8b 55 f8                mov rdx, qword ptr [rbp - 8]
      1 0x55b7c0aea2f1 <fib_loop+45>     48 8b 45 e0                mov rax, qword ptr [rbp - 0x20]
      1 0x55b7c0aea2f5 <fib_loop+49>     48 01 d0                   add rax, rdx
      1 0x55b7c0aea2f8 <fib_loop+52>     48 89 45 e8                mov qword ptr [rbp - 0x18], rax
      1 0x55b7c0aea2fc <fib_loop+56>     48 c7 45 f0 02 00 00 00    mov qword ptr [rbp - 0x10], 2
      1 0x55b7c0aea304 <fib_loop+64>     eb 24                      jmp 0x55b7c0aea32a <fib_loop+102>
      8 0x55b7c0aea306 <fib_loop+66>     48 8b 45 e0                mov rax, qword ptr [rbp - 0x20]
      8 0x55b7c0aea30a <fib_loop+70>     48 89 45 f8                mov qword ptr [rbp - 8], rax
      8 0x55b7c0aea30e <fib_loop+74>     48 8b 45 e8                mov rax, qword ptr [rbp - 0x18]
      8 0x55b7c0aea312 <fib_loop+78>     48 89 45 e0                mov qword ptr [rbp - 0x20], rax
      8 0x55b7c0aea316 <fib_loop+82>     48 8b 55 f8                mov rdx, qword ptr [rbp - 8]
      8 0x55b7c0aea31a <fib_loop+86>     48 8b 45 e0                mov rax, qword ptr [rbp - 0x20]
      8 0x55b7c0aea31e <fib_loop+90>     48 01 d0                   add rax, rdx
      8 0x55b7c0aea321 <fib_loop+93>     48 89 45 e8                mov qword ptr [rbp - 0x18], rax
      8 0x55b7c0aea325 <fib_loop+97>     48 83 45 f0 01             add qword ptr [rbp - 0x10], 1
      9 0x55b7c0aea32a <fib_loop+102>    48 8b 45 f0                mov rax, qword ptr [rbp - 0x10]
      9 0x55b7c0aea32e <fib_loop+106>    48 3b 45 d8                cmp rax, qword ptr [rbp - 0x28]
      9 0x55b7c0aea332 <fib_loop+110>    72 d2                      jb 0x55b7c0aea306 <fib_loop+66>
      1 0x55b7c0aea334 <fib_loop+112>    48 8b 45 e8                mov rax, qword ptr [rbp - 0x18]
      1 0x55b7c0aea338 <fib_loop+116>    5d                         pop rbp
      1 0x55b7c0aea339 <fib_loop+117>    c3                         ret
      
$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | grep -E '<fib_loop\+' | sort | uniq -c | column -s'|' -t | wc -l
29
```

The function is 29 instructions and 118 bytes long and the loop and how many
times it was taken is visible. Let's look at the call trace for main(). Again a
small awk script will do.
```
$ wc -l call-trace.awk 
16 call-trace.awk

$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | awk '/<main\+0/, /<main\+.* ret/' | ./call-trace.awk  | head -n15
0x55b7c0aea33a <main+0> | f3 0f 1e fa | endbr64 
0x55b7c0aea3b8 <main+126> | call 0x55b7c0aea0c0 <_init+192>
----0x55b7c0aea0c0 <_init+192> | endbr64 
----0x55b7c0aea0c4 <_init+196> | bnd jmp qword ptr [rip + 0x2efd]
----0x7f4aff4622d0 <__isoc99_sscanf@@GLIBC_2.7+0> | endbr64 
----0x7f4aff462380 <__isoc99_sscanf@@GLIBC_2.7+176> | call 0x7f4aff48e6d0 <_IO_enable_locks@@GLIBC_PRIVATE+176>
--------0x7f4aff48e6d0 <_IO_enable_locks@@GLIBC_PRIVATE+176> | endbr64 
--------0x7f4aff48e6ea <_IO_enable_locks@@GLIBC_PRIVATE+202> | call 0x7f4aff48e660 <_IO_enable_locks@@GLIBC_PRIVATE+64>
------------0x7f4aff48e660 <_IO_enable_locks@@GLIBC_PRIVATE+64> | endbr64 
------------0x7f4aff48e6c7 <_IO_enable_locks@@GLIBC_PRIVATE+167> | ret 
--------0x7f4aff48e6ef <_IO_enable_locks@@GLIBC_PRIVATE+207> | mov dword ptr [rbp + 0xc0], r12d
--------0x7f4aff48e73d <_IO_enable_locks@@GLIBC_PRIVATE+285> | ret 
----0x7f4aff462385 <__isoc99_sscanf@@GLIBC_2.7+181> | lea rax, [rip + 0x1b4334]
----0x7f4aff46239e <__isoc99_sscanf@@GLIBC_2.7+206> | call 0x7f4aff48fa30 <_IO_str_pbackfail@@GLIBC_2.2.5+96>
--------0x7f4aff48fa30 <_IO_str_pbackfail@@GLIBC_2.2.5+96> | endbr64
```

The call, target of the call, return, and target of the return are listed along
with the call depth level. Jumps through plt, or other tables, are also taken
into account. It's visible that main called sscanf() through an indirect call,
as usual, probably to scan the command line arguments. An indeed, the actual
source is:
```
        size_t num = 0;
        if (sscanf(argv[1], "%zu", &num) != 1)
        {
                fprintf(stderr, "error: '%s' not a valid number", argv[1]);
                return 2;
        }
```

Let's filer for only internal calls.
```
$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | awk '/<main\+0/, /<main\+.* ret/' | ./call-trace.awk  | grep '0x55b7c' | head -n20
0x55b7c0aea33a <main+0> | f3 0f 1e fa | endbr64 
0x55b7c0aea3b8 <main+126> | call 0x55b7c0aea0c0 <_init+192>
----0x55b7c0aea0c0 <_init+192> | endbr64 
----0x55b7c0aea0c4 <_init+196> | bnd jmp qword ptr [rip + 0x2efd]
0x55b7c0aea3bd <main+131> | cmp eax, 1
0x55b7c0aea42f <main+245> | call 0x55b7c0aea1c9 <fib_rec>
----0x55b7c0aea1c9 <fib_rec+0> | endbr64 
----0x55b7c0aea1ec <fib_rec+35> | call 0x55b7c0aea1c9 <fib_rec>
--------0x55b7c0aea1c9 <fib_rec+0> | endbr64 
--------0x55b7c0aea1ec <fib_rec+35> | call 0x55b7c0aea1c9 <fib_rec>
------------0x55b7c0aea1c9 <fib_rec+0> | endbr64 
------------0x55b7c0aea1ec <fib_rec+35> | call 0x55b7c0aea1c9 <fib_rec>
----------------0x55b7c0aea1c9 <fib_rec+0> | endbr64 
----------------0x55b7c0aea1ec <fib_rec+35> | call 0x55b7c0aea1c9 <fib_rec>
--------------------0x55b7c0aea1c9 <fib_rec+0> | endbr64 
--------------------0x55b7c0aea1ec <fib_rec+35> | call 0x55b7c0aea1c9 <fib_rec>
------------------------0x55b7c0aea1c9 <fib_rec+0> | endbr64 
------------------------0x55b7c0aea1ec <fib_rec+35> | call 0x55b7c0aea1c9 <fib_rec>
----------------------------0x55b7c0aea1c9 <fib_rec+0> | endbr64 
----------------------------0x55b7c0aea1ec <fib_rec+35> | call 0x55b7c0aea1c9 <fib_rec>
```

The calls to fib_rec(10) become visible. Let's filter for only the first call
level.
```
$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | awk '/<main\+0/, /<main\+.* ret/' | ./call-trace.awk  | grep '0x55b7c' | grep -E '^-{0,4}0x'
0x55b7c0aea33a <main+0> | f3 0f 1e fa | endbr64 
0x55b7c0aea3b8 <main+126> | call 0x55b7c0aea0c0 <_init+192>
----0x55b7c0aea0c0 <_init+192> | endbr64 
----0x55b7c0aea0c4 <_init+196> | bnd jmp qword ptr [rip + 0x2efd]
0x55b7c0aea3bd <main+131> | cmp eax, 1
0x55b7c0aea42f <main+245> | call 0x55b7c0aea1c9 <fib_rec>
----0x55b7c0aea1c9 <fib_rec+0> | endbr64 
----0x55b7c0aea1ec <fib_rec+35> | call 0x55b7c0aea1c9 <fib_rec>
----0x55b7c0aea1f1 <fib_rec+40> | mov rbx, rax
----0x55b7c0aea1ff <fib_rec+54> | call 0x55b7c0aea1c9 <fib_rec>
----0x55b7c0aea204 <fib_rec+59> | add rax, rbx
----0x55b7c0aea212 <fib_rec+73> | ret 
0x55b7c0aea434 <main+250> | mov rsi, rax
0x55b7c0aea446 <main+268> | call 0x55b7c0aea0a0 <_init+160>
----0x55b7c0aea0a0 <_init+160> | endbr64 
----0x55b7c0aea0a4 <_init+164> | bnd jmp qword ptr [rip + 0x2f0d]
0x55b7c0aea44b <main+273> | mov rax, qword ptr [rbp - 0x10]
0x55b7c0aea452 <main+280> | call 0x55b7c0aea213 <fib_tbl>
----0x55b7c0aea213 <fib_tbl+0> | endbr64 
----0x55b7c0aea274 <fib_tbl+97> | call 0x55b7c0aea213 <fib_tbl>
----0x55b7c0aea279 <fib_tbl+102> | mov rbx, rax
----0x55b7c0aea287 <fib_tbl+116> | call 0x55b7c0aea213 <fib_tbl>
----0x55b7c0aea28c <fib_tbl+121> | lea rcx, [rbx + rax]
----0x55b7c0aea2c3 <fib_tbl+176> | ret 
0x55b7c0aea457 <main+285> | mov rsi, rax
0x55b7c0aea469 <main+303> | call 0x55b7c0aea0a0 <_init+160>
----0x55b7c0aea0a0 <_init+160> | endbr64 
----0x55b7c0aea0a4 <_init+164> | bnd jmp qword ptr [rip + 0x2f0d]
0x55b7c0aea46e <main+308> | mov rax, qword ptr [rbp - 0x10]
0x55b7c0aea475 <main+315> | call 0x55b7c0aea2c4 <fib_loop>
----0x55b7c0aea2c4 <fib_loop+0> | endbr64 
----0x55b7c0aea339 <fib_loop+117> | ret 
0x55b7c0aea47a <main+320> | mov rsi, rax
0x55b7c0aea48c <main+338> | call 0x55b7c0aea0a0 <_init+160>
----0x55b7c0aea0a0 <_init+160> | endbr64 
----0x55b7c0aea0a4 <_init+164> | bnd jmp qword ptr [rip + 0x2f0d]
0x55b7c0aea491 <main+343> | mov eax, 0
0x55b7c0aea4ab <main+369> | ret
```

And now for the full first level with library calls not excluded.
```
$ ./tx64-print -s fib.bin.66938.tx64-trace.maps.end.sym -i fib.bin.66938.tx64-trace.iblob | awk '/<main\+0/, /<main\+.* ret/' | ./call-trace.awk  | grep -E '^-{0,4}0x' 
0x55b7c0aea33a <main+0> | f3 0f 1e fa | endbr64 
0x55b7c0aea3b8 <main+126> | call 0x55b7c0aea0c0 <_init+192>
----0x55b7c0aea0c0 <_init+192> | endbr64 
----0x55b7c0aea0c4 <_init+196> | bnd jmp qword ptr [rip + 0x2efd]
----0x7f4aff4622d0 <__isoc99_sscanf@@GLIBC_2.7+0> | endbr64 
----0x7f4aff462380 <__isoc99_sscanf@@GLIBC_2.7+176> | call 0x7f4aff48e6d0 <_IO_enable_locks@@GLIBC_PRIVATE+176>
----0x7f4aff462385 <__isoc99_sscanf@@GLIBC_2.7+181> | lea rax, [rip + 0x1b4334]
----0x7f4aff46239e <__isoc99_sscanf@@GLIBC_2.7+206> | call 0x7f4aff48fa30 <_IO_str_pbackfail@@GLIBC_2.2.5+96>
----0x7f4aff4623a3 <__isoc99_sscanf@@GLIBC_2.7+211> | lea rdx, [rsp + 8]
----0x7f4aff4623dd <__isoc99_sscanf@@GLIBC_2.7+269> | call 0x7f4aff462a60 <psiginfo@@GLIBC_2.10+1440>
----0x7f4aff4623e2 <__isoc99_sscanf@@GLIBC_2.7+274> | mov rdx, qword ptr [rsp + 0x118]
----0x7f4aff462401 <__isoc99_sscanf@@GLIBC_2.7+305> | ret 
0x55b7c0aea3bd <main+131> | cmp eax, 1
0x55b7c0aea42f <main+245> | call 0x55b7c0aea1c9 <fib_rec>
----0x55b7c0aea1c9 <fib_rec+0> | endbr64 
----0x55b7c0aea1ec <fib_rec+35> | call 0x55b7c0aea1c9 <fib_rec>
----0x55b7c0aea1f1 <fib_rec+40> | mov rbx, rax
----0x55b7c0aea1ff <fib_rec+54> | call 0x55b7c0aea1c9 <fib_rec>
----0x55b7c0aea204 <fib_rec+59> | add rax, rbx
----0x55b7c0aea212 <fib_rec+73> | ret 
0x55b7c0aea434 <main+250> | mov rsi, rax
0x55b7c0aea446 <main+268> | call 0x55b7c0aea0a0 <_init+160>
----0x55b7c0aea0a0 <_init+160> | endbr64 
----0x55b7c0aea0a4 <_init+164> | bnd jmp qword ptr [rip + 0x2f0d]
----0x7f4aff460770 <printf@@GLIBC_2.2.5+0> | endbr64 
----0x7f4aff46081a <printf@@GLIBC_2.2.5+170> | call 0x7f4aff4750b0 <psiginfo@@GLIBC_2.10+76784>
----0x7f4aff46081f <printf@@GLIBC_2.2.5+175> | mov rdx, qword ptr [rsp + 0x18]
----0x7f4aff460836 <printf@@GLIBC_2.2.5+198> | ret 
0x55b7c0aea44b <main+273> | mov rax, qword ptr [rbp - 0x10]
0x55b7c0aea452 <main+280> | call 0x55b7c0aea213 <fib_tbl>
----0x55b7c0aea213 <fib_tbl+0> | endbr64 
----0x55b7c0aea274 <fib_tbl+97> | call 0x55b7c0aea213 <fib_tbl>
----0x55b7c0aea279 <fib_tbl+102> | mov rbx, rax
----0x55b7c0aea287 <fib_tbl+116> | call 0x55b7c0aea213 <fib_tbl>
----0x55b7c0aea28c <fib_tbl+121> | lea rcx, [rbx + rax]
----0x55b7c0aea2c3 <fib_tbl+176> | ret 
0x55b7c0aea457 <main+285> | mov rsi, rax
0x55b7c0aea469 <main+303> | call 0x55b7c0aea0a0 <_init+160>
----0x55b7c0aea0a0 <_init+160> | endbr64 
----0x55b7c0aea0a4 <_init+164> | bnd jmp qword ptr [rip + 0x2f0d]
----0x7f4aff460770 <printf@@GLIBC_2.2.5+0> | endbr64 
----0x7f4aff46081a <printf@@GLIBC_2.2.5+170> | call 0x7f4aff4750b0 <psiginfo@@GLIBC_2.10+76784>
----0x7f4aff46081f <printf@@GLIBC_2.2.5+175> | mov rdx, qword ptr [rsp + 0x18]
----0x7f4aff460836 <printf@@GLIBC_2.2.5+198> | ret 
0x55b7c0aea46e <main+308> | mov rax, qword ptr [rbp - 0x10]
0x55b7c0aea475 <main+315> | call 0x55b7c0aea2c4 <fib_loop>
----0x55b7c0aea2c4 <fib_loop+0> | endbr64 
----0x55b7c0aea339 <fib_loop+117> | ret 
0x55b7c0aea47a <main+320> | mov rsi, rax
0x55b7c0aea48c <main+338> | call 0x55b7c0aea0a0 <_init+160>
----0x55b7c0aea0a0 <_init+160> | endbr64 
----0x55b7c0aea0a4 <_init+164> | bnd jmp qword ptr [rip + 0x2f0d]
----0x7f4aff460770 <printf@@GLIBC_2.2.5+0> | endbr64 
----0x7f4aff46081a <printf@@GLIBC_2.2.5+170> | call 0x7f4aff4750b0 <psiginfo@@GLIBC_2.10+76784>
----0x7f4aff46081f <printf@@GLIBC_2.2.5+175> | mov rdx, qword ptr [rsp + 0x18]
----0x7f4aff460836 <printf@@GLIBC_2.2.5+198> | ret 
0x55b7c0aea491 <main+343> | mov eax, 0
0x55b7c0aea4ab <main+369> | ret
```

It becomes easy to see what the program was doing just by glancing at the symbol
names.

#### Real life example
Still somewhat contrived, but let's examine how two different implementations of
awk execute an endless loop.
```
# Terminal 1
$ gawk 'BEGIN {while (1);}'

# Terminal 2
$ ./tx64-trace -s 2 -p $(pgrep gawk)

# Terminal 1
$ mawk 'BEGIN {while (1);}'

# Terminal 2
$ ./tx64-trace -s 2 -p $(pgrep mawk)
```
##### gawk
```
$ ./sym-map.awk gawk.68330.tx64-trace.maps.end

$ ./tx64-print -s gawk.68330.tx64-trace.maps.end.sym -i gawk.68330.tx64-trace.iblob | sort | uniq -c | wc -l
62

$ ./tx64-print -s gawk.68330.tx64-trace.maps.end.sym -i gawk.68330.tx64-trace.iblob | sort | uniq -c | column -s'|' -t
  11236 0x555f9243748b <???+93868964148363>    0f bf 45 20             movsx eax, word ptr [rbp + 0x20]
  11235 0x555f9243748f <???+93868964148367>    66 85 c0                test ax, ax
  11235 0x555f92437492 <???+93868964148370>    7e 06                   jle 0x555f9243749a <???+93868964148378>
   3745 0x555f92437494 <???+93868964148372>    89 05 76 96 06 00       mov dword ptr [rip + 0x69676], eax
  11235 0x555f9243749a <???+93868964148378>    41 83 ff 77             cmp r15d, 0x77
  11235 0x555f9243749e <???+93868964148382>    0f 87 dc 01 00 00       ja 0x555f92437680 <???+93868964148864>
  11235 0x555f924374a4 <???+93868964148388>    44 89 f8                mov eax, r15d
  11235 0x555f924374a7 <???+93868964148391>    49 63 04 84             movsxd rax, dword ptr [r12 + rax*4]
  11236 0x555f924374ab <???+93868964148395>    4c 01 e0                add rax, r12
  11236 0x555f924374ae <???+93868964148398>    3e ff e0                notrack jmp rax
   3745 0x555f92437610 <???+93868964148752>    48 8b 6d 08             mov rbp, qword ptr [rbp + 8]
   3745 0x555f92437614 <???+93868964148756>    44 8b 7d 24             mov r15d, dword ptr [rbp + 0x24]
   3745 0x555f92437618 <???+93868964148760>    e9 6e fe ff ff          jmp 0x555f9243748b <???+93868964148363>
   3745 0x555f9243930b <???+93868964156171>    48 8b 05 86 78 06 00    mov rax, qword ptr [rip + 0x67886]
   3745 0x555f92439312 <???+93868964156178>    48 8d 50 f8             lea rdx, [rax - 8]
   3745 0x555f92439316 <???+93868964156182>    48 89 15 7b 78 06 00    mov qword ptr [rip + 0x6787b], rdx
   3745 0x555f9243931d <???+93868964156189>    4c 8b 28                mov r13, qword ptr [rax]
   3745 0x555f92439320 <???+93868964156192>    41 83 7d 68 05          cmp dword ptr [r13 + 0x68], 5
   3745 0x555f92439325 <???+93868964156197>    0f 84 a2 28 00 00       je 0x555f9243bbcd <???+93868964166605>
   3745 0x555f9243932b <???+93868964156203>    4c 39 2d fe aa 06 00    cmp qword ptr [rip + 0x6aafe], r13
   3745 0x555f92439332 <???+93868964156210>    0f 84 a2 ec ff ff       je 0x555f92437fda <???+93868964151258>
   3745 0x555f92439338 <???+93868964156216>    4c 39 2d f9 aa 06 00    cmp qword ptr [rip + 0x6aaf9], r13
   3745 0x555f9243933f <???+93868964156223>    0f 84 82 1e 00 00       je 0x555f9243b1c7 <???+93868964164039>
   3745 0x555f92439345 <???+93868964156229>    41 8b 45 6c             mov eax, dword ptr [r13 + 0x6c]
   3745 0x555f92439349 <???+93868964156233>    89 c2                   mov edx, eax
   3745 0x555f9243934b <???+93868964156235>    83 e2 28                and edx, 0x28
   3745 0x555f9243934e <???+93868964156238>    83 fa 20                cmp edx, 0x20
   3745 0x555f92439351 <???+93868964156241>    0f 84 df 3a 00 00       je 0x555f9243ce36 <???+93868964171318>
   3745 0x555f92439357 <???+93868964156247>    f6 c4 01                test ah, 1
   3745 0x555f9243935a <???+93868964156250>    0f 85 42 31 00 00       jne 0x555f9243c4a2 <???+93868964168866>
   3745 0x555f92439360 <???+93868964156256>    a8 10                   test al, 0x10
   3745 0x555f92439362 <???+93868964156258>    0f 85 a3 2e 00 00       jne 0x555f9243c20b <???+93868964168203>
   3745 0x555f92439371 <???+93868964156273>    49 83 6d 38 01          sub qword ptr [r13 + 0x38], 1
   3745 0x555f92439376 <???+93868964156278>    0f 84 03 34 00 00       je 0x555f9243c77f <???+93868964169599>
   3745 0x555f9243937c <???+93868964156284>    45 84 f6                test r14b, r14b
   3745 0x555f9243937f <???+93868964156287>    0f 84 8b e2 ff ff       je 0x555f92437610 <???+93868964148752>
   3745 0x555f92439385 <???+93868964156293>    48 8b 6d 00             mov rbp, qword ptr [rbp]
   3745 0x555f92439389 <???+93868964156297>    44 8b 7d 24             mov r15d, dword ptr [rbp + 0x24]
   3745 0x555f9243938d <???+93868964156301>    e9 f9 e0 ff ff          jmp 0x555f9243748b <???+93868964148363>
   3746 0x555f9243989c <???+93868964157596>    4c 8b 6d 08             mov r13, qword ptr [rbp + 8]
   3746 0x555f924398a0 <???+93868964157600>    f6 05 95 72 06 00 10    test byte ptr [rip + 0x67295], 0x10
   3746 0x555f924398a7 <???+93868964157607>    0f 84 5c 05 00 00       je 0x555f92439e09 <???+93868964158985>
   3746 0x555f924398ad <???+93868964157613>    49 83 45 38 01          add qword ptr [r13 + 0x38], 1
   3746 0x555f924398b2 <???+93868964157618>    48 8b 05 df 72 06 00    mov rax, qword ptr [rip + 0x672df]
   3746 0x555f924398b9 <???+93868964157625>    48 3b 05 98 72 06 00    cmp rax, qword ptr [rip + 0x67298]
   3746 0x555f924398c0 <???+93868964157632>    0f 83 81 16 00 00       jae 0x555f9243af47 <???+93868964163399>
   3746 0x555f924398c6 <???+93868964157638>    48 83 c0 08             add rax, 8
   3746 0x555f924398ca <???+93868964157642>    48 89 05 c7 72 06 00    mov qword ptr [rip + 0x672c7], rax
   3746 0x555f924398d1 <???+93868964157649>    48 8b 6d 00             mov rbp, qword ptr [rbp]
   3746 0x555f924398d5 <???+93868964157653>    4c 89 28                mov qword ptr [rax], r13
   3746 0x555f924398d8 <???+93868964157656>    44 8b 7d 24             mov r15d, dword ptr [rbp + 0x24]
   3746 0x555f924398dc <???+93868964157660>    e9 aa db ff ff          jmp 0x555f9243748b <???+93868964148363>
   3746 0x555f92439e09 <???+93868964158985>    41 f6 45 6c 40          test byte ptr [r13 + 0x6c], 0x40
   3746 0x555f92439e0e <???+93868964158990>    0f 84 99 fa ff ff       je 0x555f924398ad <???+93868964157613>
   3745 0x555f9243c20b <???+93868964168203>    f6 c4 0c                test ah, 0xc
   3745 0x555f9243c20e <???+93868964168206>    0f 85 cd 09 00 00       jne 0x555f9243cbe1 <???+93868964170721>
   3745 0x555f9243c214 <???+93868964168212>    66 0f ef c0             pxor xmm0, xmm0
   3745 0x555f9243c218 <???+93868964168216>    66 41 0f 2e 45 00       ucomisd xmm0, qword ptr [r13]
   3745 0x555f9243c21e <???+93868964168222>    b8 01 00 00 00          mov eax, 1
   3745 0x555f9243c223 <???+93868964168227>    41 0f 9a c6             setp r14b
   3745 0x555f9243c227 <???+93868964168231>    44 0f 45 f0             cmovne r14d, eax
   3745 0x555f9243c22b <???+93868964168235>    e9 41 d1 ff ff          jmp 0x555f92439371 <???+93868964156273>
```

Looks like in 2 seconds gawk executed the entire loop about 3746 times and an
internal loop 11235 times. The whole execution path is 61 instructions long. No
internal function names are available because the gawk binary is stripped.

##### mawk
```
$ ./sym-map.awk mawk.68333.tx64-trace.maps.end

$ ./tx64-print -s mawk.68333.tx64-trace.maps.end.sym -i mawk.68333.tx64-trace.iblob | sort | uniq -c | wc -l
10

$ ./tx64-print -s mawk.68333.tx64-trace.maps.end.sym -i mawk.68333.tx64-trace.iblob | sort | uniq -c | column -s'|' -t
  29328 0x55bae0567550 <???+94261116040528>    83 3b 5a             cmp dword ptr [rbx], 0x5a
  29328 0x55bae0567553 <???+94261116040531>    48 8d 6b 08          lea rbp, [rbx + 8]
  29328 0x55bae0567557 <???+94261116040535>    0f 87 fc 21 00 00    ja 0x55bae0569759 <???+94261116049241>
  29328 0x55bae056755d <???+94261116040541>    8b 03                mov eax, dword ptr [rbx]
  29328 0x55bae056755f <???+94261116040543>    49 63 04 86          movsxd rax, dword ptr [r14 + rax*4]
  29329 0x55bae0567563 <???+94261116040547>    4c 01 f0             add rax, r14
  29329 0x55bae0567566 <???+94261116040550>    3e ff e0             notrack jmp rax
  29329 0x55bae0567fd0 <???+94261116043216>    48 63 43 08          movsxd rax, dword ptr [rbx + 8]
  29328 0x55bae0567fd4 <???+94261116043220>    48 8d 5c c5 00       lea rbx, [rbp + rax*8]
  29328 0x55bae0567fd9 <???+94261116043225>    e9 72 f5 ff ff       jmp 0x55bae0567550 <???+94261116040528>
```

In contrast, mawk's execution loop is only 10 instructions long and managed to
execute about 29329 times. This is not an attack on gawk, however. Both
implementations have their pros and cons. Faster execution is one of mawk's
pros.

### How to build
```
$ make
make rel     - release build + test
make test    - all + run tests
make testv   - all + run verbose tests
make all     - trace + print + sym
make trace   - compile tracer
make print   - compile printer
make sym     - compile sym-map.awk
make clean   - clean up
make help    - this screen
```

### Hack
```
$ tree -d trace-x64/
trace-x64/
├── err            # <-- error handling code
├── example-tools  # <-- the tools and programs used in the examples
├── obj            # <-- *.o go here
├── parse-opts     # <-- command line arguments parsing library
├── print          # <-- tx64-print
│   └── capstone   # <-- capstone is used for disassembly
│       └── include
│           ├── capstone
│           └── windowsce
├── sym-map        # <-- sym-map.awk
├── tests          # <-- tests directory
└── trace          # <-- tx64-trace

12 directories
```
