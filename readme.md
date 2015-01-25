Goals
=====

Performance does not always come from writing code,
sometimes it is about the way you make use of existing
code and programs. The philosophy of the unix shell is
to create many small programs with orthogonal functionality,
then to combine them in many ways to provide different
high-level functionality. This philosophy also often
allows large amounts of parallelism, which can allow
surprisingly good scaling over multiple processors.

The overall goals of this coursework are:

1. Get experience in using the command line and shell-script,
   for those who are used to GUI-based programming.

2. Some (minimal) experience in automating setup.

3. Understand process pipelines, and how they can improve
   efficiency and enable parallelism.

4. Explore the built-in parallelism available in the shell.

5. Look at makefiles as a way of creating dependency graphs.

6. Use the built-in parallelism of make, and explore it's
   advantages and limitations.

The goal is not to produce ultra-optimised C code (though if
you do, and it works, then that is nice too). Also, I make no apologies
for making you go through some slightly circuitous steps on the
way to the streaming and parallelism bits later on in the
exercise.

For some of you it will make you do things you already
know how to do, or conflict with the ways that you've done
things in personal projects or industry. However, I think
most people will learn something useful (?), and it is
important to be able to work in this kind of environment
because:

- We need it to access the hardware used later on
  in the course.

- Linux is generally the environment of choice if you
  are trying to get a lot of compute done.

- There is often no GUI in production HPC contexts
  (whether embedded or super-computer).
  
- Code often needs to be deployable without any
  user input, as it needs to start up on 100
  linux boxes and sort itself out.
  
Environment Setup
-----------------

_People with experience in posix environments will
be able to get through this section very fast._

This coursework should be performed in a posix-like
environment, so that could be Linux, OS-X, or Cygwin.
Particular things it relies on are:

- **Bash**: There are many shells (the program that
  proves the interactive command line), and there are
  some differences in input syntax. This coursework
  explicitly targets the Bash shell, as it is installed
  in most systems (even when it isn't the default).

- **Make**: While traditionally used just for building
  programs, "make" can also be used for the general
  co-ordination of many programs working together. We
  will specifically use GNU make.
  
- **C++ toolchain**: Some of the audio processing
  will be done with programs compiled by you, so you need
  a command line toolchain setup. It doesn't really
  matter if it is gcc, clang, or icc, though if you
  don't have any strong preference, stick with the
  gcc.
  
First start a command line terminal -- the exact
mechanism depends on your OS. You should now be
looking at a command line shell, with some sort
of blinking text prompt. The first thing to check
is that you are in bash, rather than some other
shell. Type the command:

    echo $SHELL

This displays the name of the current shell, which
should look something like `/bin/bash`. If it says
something different, you'll need to type:

    bash

which should then drop you into a bash shell (the prompt
may change slightly). If it complains that bash can't
be found, then you'll need to use your system's package
manager to install it.

You should now be in bash, so next make sure that you
have `make` installed:

    make -v

If it complains that make can't be found, then you'll need
to install it using your package manager. If make is listed
as anything other than "GNU Make", then you may need to
install the GNU version -- however, try following the
coursework first, and it may just work ok.

Change to a directory you want to do your work in, then
clone the coursework repository:

    git clone https://github.com/HPCE/hpce-2014-cw2

Again, if `git` isn't found, get it through your package
manager.

For this courswork, you must keep things within git,
as it forms part of your submission.

Part A : Build automation
=========================

The point of this section is to set up a framework
for later work in audio processing, and to do that
we're going to use two tools:

- [Sox](http://sox.sourceforge.net) A tool for streaming/playing audio

- [Lame](http://lame.sourceforge.net) An mp3 codec

The aim here is to create a single makefile which
is able to download and build both packages, creating
a known environment no matter what software is
currently installed. This may seem a slightly pointless
task, but being able to replicate an environment by
typing `make` and then going away and getting
a coffee can often be useful.

Building sox
------------

Before automating, you need to build it manually. For lots
of open source packages, there are some standard steps for
doing this:

1. Download the tarball.

2. Extract the sources from the tarball.

3. Run the "./configure" script, which allows the package
   to look at your environment and see what is currently installed,
   and allows the user to specify where the new package will be
   installed.
   
4. Execute "make" to build all the sources and produce
   the executable.
   
5. Do "make install" to install the binaries and documentation.

The process is not completely standardised, but for many packages
it looks the same.

### Download the tarball

We'll use a version of sox that I downloaded from their [website](http://sox.sourceforge.net),
but which will be hosted locally to avoid us hammering their
website. We'll use `curl` to download the source package:

    curl http://cas.ee.ic.ac.uk/people/dt10/teaching/2013/hpce/cw2/sox-14.4.1.tar.gz -o packages/sox-14.4.1.tar.gz

`curl` should be installed on most managed installation,
but if you are using your own cygwin you might need to
installed it. The first argument to is the URL we
want to read from, and `-o` is the location it should
be saved to. As with most unix programs, you can use
`--help` to find out the arguments it takes (for example
`curl --help`), or `man` or `info` to get more detailed
documentation (`man curl`, or `info curl`). If they
exist, the info pages are usually more detailed and better structured
(and the man page may just be a [stub](http://xkcd.com/912/), though
some tools only have man pages.

_Note: if you have problems getting the tar-ball, have a look at Issue [#1](https://github.com/HPCE/hpce-2014-cw2/issues/1). Thanks to @farrell236._

Here we are specifying that the file should be downloaded to
the `packages` directory. Once curl finishes, do `ls packages`
to check that you can see the download file there.

Note that this as a distinct step in the build process:

1. we depended on nothing,
2. executed the curl command,
3. and the output of that command was the tarball.

Unpack the sources
------------------

We now need to extract the contents of the tarball.
To keep things clean, we'll extract the contents to
the directory called `build` This will keep things
separated, so that if necessary (e.g. to save space), we can
delete the contents of `build` without losing anything.

You should still be at the base directory, but that is not
where we want to extract. Do `cd build` to get into the
build directory. The general [command to extract things](href{http://xkcd.com/1168/)
is `tar -xzf some-file`, where `some-file` is the path to a
tarball you want to extract. The `-xzf` option specifies
what you want to do:
- `x` means eXtract;
- `z` means the tarball is compressed with gzip;
-  `f` means that we are specifying the input tarball using a File path.

The tarball is still in the packages directory, so we'll need to
specify a relative path. You may wish to do:

    ls ..
    ls ../packages
    ls ../packages/sox-14.4.1.tar.gz
    
just to check you know where you are pointing. Knowing
that the relative path from the `build` directory is `../packages/sox-14.4.1.tar.gz`,
we can now extract the files using:

    tar -xzf ../packages/sox-14.4.1.tar.gz

This will extract a number of files and directories in
the current (i.e. `build`) directory. Change directory
into the new `sox-14.4.1`, and have a look around.
In particular, note that there is a file called `configure`
which will be what we use next.

This step is now complete, and again we can summarise the step
in terms of inputs, commands, and outputs:

1. the input is the tarball;
2. the command is tar;
3. and the output is the extracted files, and a specific output
   is the file called `configure`.

Configure the package
---------------------

The source files for sox are designed to work on multiple unix-like
platforms, but to achieve this they have to enable and disable
certain features, or specify different `#define`s at
compile time. A commonly used approach is to use
[GNU Autotools](http://en.wikipedia.org/wiki/GNU_build_system),
which attempts to make this "easy", and is reasonably portable

(Although nobody really thinks that autotools are good - they
just mostly work and everything else is worse. They are the
democracy of build systems. See for example Poul-Henning Kamp's
[commentary](http://queue.acm.org/detail.cfm?id=2349257).)

The `configure` file produced by the previous stage is actually
a program that we need to run. Make sure that you are in
the `build/sox-14.4.1`
directory, and do:

    ./configure --help

This will show you all the options that you can pass when configuring
the package, so there are lots of options affecting what gets included
or excluded, and multiple flags that can be passed in.

The only flag that we need to worry about is `--prefix`, which
tells `configure` where it should install the binaries. By default
it will install it in a system-wide location, often `/bin` or `/local/bin`.
However, we are trying to create a local environment that we
control, rather than modifying the entire systems. On many systems
you also won't be allowed to write to the system-wide directories
(certainly in college, and often in an industrial context), so
it is critical that you make sure it installs it in a place you control.

We're going to specify the installation directory as `local`
in your base directory. From where you are you should be
able to do:

    ls ../../local

to check the relative path from where you are, and can then do:

    ./configure --prefix=../../local

Well, except... it won't (at least on systems I tried). The error
message should tell you what the problem is, and to solve it
you can use the following:

1. The `pwd` command prints the current directory.
2. Enclosing a command `cmd` in `$(cmd)` captures the output
   of that variable.
3. You can concatenate strings in the shell.
   
So for example:   
   
    X=`pwd`;
    echo $X

captures the output of `pwd` into the shell
variable X, then prints the value of X using echo.
Combining that with string concatenation, you can do:

    X=`pwd`;
    echo "$X/../../local"

which should now print your current directory followed
by the relative path to local. However, because it starts
with `/`, this is now an absolute path, despite
the `..` components later on.

Collapsing the two steps, you can do:

    echo "$(pwd)/../../local"
    
to combine the two.

This leads us to a (rather hacky, but portable) solution:

    ./configure --prefix="$(pwd)/../../local"

You should now see huge amounts of configuration messages
go past as it works out what your system looks like.

(It is _possible_ that it may find some errors, for example
a missing library. Some of those can be fixed easily with
your package manager, but if you find uncorrectable errors,
switch to a controlled environment like Cygwin. Building
the environment should not involve any debugging or
difficulty, so don't get caught up trying to debug problems.
If you come across any problems, raise an [issue](https://github.com/HPCE/hpce-2014-cw2/issues),
and either I or someone else might be able to help. Don't forget to
include actionable information though.
)

Once configuration has finished, a new file called `Makefile`
will have appeared, which is the input to the next stage.
Again, notice the pattern:

1. the required input is the configure file;
2. the action is to run that configure file;
3. the output is the Makefile.

Building the code
-----------------

We now have a makefile, which contains the list of all files
which must be built, as well as the order in which they have
to be built. So for example, an object file must be built
before a library containing it can be linked. However, for
now we can just run the file:

    make

You'll now (hopefully) see a mass of compilation messages
going past. To start with, there will be lots of individual
C files being compiled, then you'll start to see some linking
of libraries and executables. Once this process is finished,
the whole thing should be compiled. If you do:

    ls -la src/sox

then you should be able to see the sox executable, and if
you want you can run it with:

    src/sox

but, it is not yet in the location where we want it installed.

(Again, there should not be any compilation errors once make
starts -- if anything strange happens at this stage, you may wish
to switch to a clean cygwin install.)

Laboring the pedagogical point, in this stage:
1. the input file was the Makefile;
2. the process was calling make;
3. and the output is the executable.

At this point we can start to exploit the parallelism of
make. Do:

    make clean

This is the convention for getting a makefile to remove
everything it has built, but _only_ the things it has
build - all source files will be untouched. You'll see
that all the object files have disappeared (what a waste!).

Now do:

    make -j 4

You should see a similar set of compilation messages go past,
but you'll see them go by faster, and if you look at a process
monitor, you'll see multiple compilation tasks happening at
once. If you have 4 or less CPU cores, you'll see most of the
cores active most of the time, while if you have more than 4
cores then the cores will all be active but not running at 100\%.

This type of process-level parallelism is extremely useful because:

- The parallelism is declarative rather than explicit: internally the makefile
  does not describe what should execute in parallel, instead it
  specifies a whole bunch of tasks to perform, and any dependencies between those tasks.
  
- It is very safe: there is usually no chance of deadlocks or
  race conditions.

- It allows you to take existing sequential programs with no
  support for multi-core and scale them over multiple CPUS, without
  needing to rewrite them.

There are limitations to this approach, but if a `make`-like solution
to describing parallelism can be used, it is usually very efficient
in terms of programmer time, and fairly efficient at exploiting
multiple cores (I have met people who do what would normally be
called super-computing using `make`, executing peta-flops with
one make command).

Installing
----------

The final step here is to install the binary to its target
location, in our case the `local` directory. To install,
just do:

    make install

You'll see various things being copied, and a few other commands
being run. _If you see errors about not being able to write to
a directory, check that you specified the `--prefix` flag to
`configure` earlier on._

The installation directory is `local`, so if you do:

    ls ../../local/

You'll see that you have a shiny new `local/bin`, `local/include', and
so on created, and hopefully if you do:

    ls ../../local/bin

You'll see the `sox` binary there.

So, for this process:

1. the input is the `sox` binary in the `build` dir;
2. the process is `make install`;
3. and the output is the `sox` binary in the `local/bin` dir.

If you return to the base folder, you can now run sox
as `local/bin/sox`.

Building lame
-------------

Sox is able to play audio, but by default is not able to handle
things like mp3s. We'll use [lame](http://lame.sourceforge.net/)
for these purposes, so we'll also need to follow the same steps.

The version of lame we'll use is lame-3.99.5, and it is available
at:

    http://cas.ee.ic.ac.uk/people/dt10/teaching/2013/hpce/cw2/lame-3.99.5.tar.gz

The steps you should follow will be exactly the same as for `sox`, but
you'll need to change the various names from `sox` to `lame` as you
go through.

Checking it works
-----------------

Congratulations! You should now have both lame and sox installed
in `local/bin`, so whenever anyone says you are not allowed to
install things, you can point out that if you have a
compiler, you can do anything you want. We'll now do some
(not very impressive) parallel processing.

From your base directory, execute this (it is all one command, you can copy
and paste it in):

    curl http://cas.ee.ic.ac.uk/people/dt10/teaching/2013/hpce/cw2/bn9th_m4.mp3 \
        | local/bin/lame -  --mp3input --decode  - \
        | local/bin/sox  - -d

The [source mp3](https://archive.org/details/beethoven9) is Creative Commons, I believe.

Be careful about the ends of lines in these commands, as it is easy to accidentally
send binary files to the terminal. If that happens, you'll get a screen
of weird characters, and your terminal might lockup. If that happens,
just kill the terminal and open another one.

**Note:** _On some platforms sox will build happily, but then refuse
to play to the audio device due to the system setup. If you are using
cygwin (32 or 64 bit), and on many linuxes, everything be fine. If you are
using your own linux, then you can install `libasound2-dev`
to get audio support. If you can't get it to play live audio at
all, then don't worry. As long as `sox` builds it is fine.

The three commands correspond to three stages in a parallel processing pipeline:

1. Curl is downloading a file over http, and sending it to stdout.

2. Lame is reading data from its stdin (`-`), treating that input data
	as mp3 (`--mp3input`) and decoding it to wav (`--decode`), then
	sending it to stdout (second `-`).

3. Sox is reading a wav over its stdin (`-`), and sending it to
   the audio output device (`-d`).
   
If you look at a process monitor while it is playing (e.g. taskmgr in windows,
or `top`/`htop` in unix), then you'll see that all three processes are active
at the same time. However, the processing requirements are very small.

If you instead try:

    curl http://cas.ee.ic.ac.uk/people/dt10/teaching/2013/hpce/cw2/bn9th_m4.mp3 \
        | local/bin/lame -  --mp3input --decode  - \
        | local/bin/lame -  - \
        > tmp/dump.mp3

then here we are decoding, then re-encoding (i.e. transcoding). Because
we are writing to a file (`> tmp/dump.mp3`), there are no limits on
playback speeds, so all processes run as fast as they can. In this
case you'll find either that the curl process is the limit (if you
have slow internet), or more likely that the second lame process
starts taking up 100\% of CPU. The first lame process will probably
take a much smaller, but still noticeable amount of CPU time.

To emphasise this effect, do the following:

    curl http://cas.ee.ic.ac.uk/people/dt10/teaching/2013/hpce/cw2/bn9th_m4.mp3 \
        | local/bin/lame --mp3input --decode - - \
        | local/bin/lame - - \
        | local/bin/lame --mp3input --decode - - \
        | local/bin/lame - - \
        > tmp/dump.mp3

This is now completely pointless, but if you run it, you will
probably see that two of the lame processes are now taking
up an entire CPU each. So by connecting streaming
processes in this way, we are enabling multiple cores to
work together on the same problem.

Automating the build
--------------------

You've now built two tools, but there were quite a few steps
involved. If you now wanted to do the same experiment on a
different machine, you'd have to go through each of the
manual processes again. Here we're going to build a makefile
which will automate this process.

**Note:** This automation and the makefile is part of the
submission - my tests will initially get your submission
to build its environment, before running your code.

We're going to do this by creating a makefile, similar to the
makefile you used to build sox and lame, but much simpler. Note
that there is a lot of documentation available for make, either
on the [GNU website](http://www.gnu.org/software/make),
or by typing `info make`.

Makefiles primarily consist of rules, with each rule describing
how to create some target file. For example, we want our build
system to eventually create the target executable `local/bin/sox`.
Each rule consists of three parts:

- **target**: The name of the target file (or files) that the rule can build.

- **dependencies** Zero or more files which must already exist
	before the rule can execute.

- **commands* Zero or more shell commands to execute in order to build the target.

The general format of a rule is:

    target : dependencies
        command(s)

Be aware that the space before the command must be a single
tab, not multiple spaces. The makefile will contain multiple
rules, each of which describes one step in the process.

In the case of building sox, we used the following rules:


| Stage     | target                     | dependencies               | command              | directory        |
|-----------|----------------------------|----------------------------|----------------------|------------------|
| Download  | packages/sox-14.4.1.tar.gz |                            | curl _url_ -o _dest_ |                  |
| Unpack    | build/sox-14.4.1/configure | packages/sox-14.4.1.tar.gz | tar                  | build            |
| Configure | build/sox-14.4.1/Makefile  | build/sox-14.4.1/configure | configure            | build/sox-14.4.1 |
| Build     | build/sox-14.4.1/src/sox   | build/sox-14.4.1/Makefile  | make                 | build/sox-14.4.1 |
| Install   | local/bin/sox              | build/sox-14.4.1/src/sox   | make install         | build/sox-14.4.1 |

So each of these corresponds to each of the stages you performed manually (you'll
notice I deliberately pointed out the target, commands, and dependencies at the
end of each stage). I've also included the directory we were in when the command
was executed, as we were occasionally using relative paths.

Clean the environment
---------------------

Your makefile is going to replicate the steps you performed to
install sox and lame, so first you need to delete everything you
did manually. So delete:

- The tarballs from `packages`.
- The two build directories from `build`.
- All the directories from `local`.

You should now be back to just what came out of the original
coursework tarball.

Create the makefile
-------------------

In the base directory of your project, create a text file called `makefile`.
This should have no extension: windows may secretly add a `.txt` on the
end, and lord knows what MacOS does, but you need it to have no extension.
You can check it by doing `ls` to see what the real filename is.
If some sort of extension has been added, just rename it, .e.g:

    mv makefile.txt makefile

Open the text file in a text editor, and add the variable and rule:

    SRC_URL = http://cas.ee.ic.ac.uk/people/dt10/teaching/2013/hpce/cw2

    packages/sox-14.4.1.tar.gz :
        curl $(SRC_URL)/sox-14.4.1.tar.gz -o packages/sox-14.4.1.tar.gz

This first defines a convenience variable called `SRC_URL`, which
describes the web address, and then defines the actual rule:
- the target is `packages/sox-14.4.1.tar.gz`;
- there are no dependencies (as it comes from the network);
- and the command just executes curl.
Where the variable `SRC_URL` is referenced using `$(SRC_URL)` it will expand into the full path.

**Note-1**: the white-space before `curl` is a tab character. Do not use
four spaces, or it won't work.

**Note-2**: if you are in windows (cygwin), you need to make sure you
use unix [line-endings](http://en.wikipedia.org/wiki/Newline)
in your makefile. If necessary, force your text editor to use that
mode.

If you go back to your command line (with the same directory as the makefile), and execute:

    make packages/sox-14.4.1.tar.gz

it should execute the rule, and download the package. The argument to `make` specifies the
target you want to build, and it will execute any rules necessary in order to build that
target.

Start adding rules
------------------

So now the makefile can download, and we need to unpack the file. Add this
rule to the end of the makefile:

    build/sox-14.4.1/configure : packages/sox-14.4.1.tar.gz
        cd build && tar -xzf ../packages/sox-14.4.1.tar.gz

Make sure there is an empty line between this rule, and the previous rule.

This tells make how to build the configure target, so you can now do:

    make build/sox-14.4.1/configure

Note that `make` does not re-execute the download rule, it only executes
the tar rule. This is because if a file already exists, then
it won't bother to re-execute the rule that produced it.

For the rule's command, we used:

    cd build && tar -xzf ../packages/sox-14.4.1.tar.gz

Originally we performed the command from within the `build`
directory, so to use the same tar command we first enter the
correct directory and then ('&&') execute the tar command.
Changing directories within a command only affects that
particular command - any further commands will execute
from the original working directory.

Fill in the rest of the stages
------------------------------

You can now follow the same process for the rest of the
stages, adding a rule to the makefile for each.

Two of the stages involve calling another makefile from
within make - this is perfectly valid, but in order
to allow things like parallel make to work well, we need
to use the convention for [recursive make](https://www.gnu.org/software/make/manual/html_node/Recursion.html#Recursion).
So where you would naturally write the command as:

    build/sox-14.4.1/src/sox : build/sox-14.4.1/Makefile
        cd build/sox-14.4.1 && make

instead write it as:

    build/sox-14.4.1/src/sox : build/sox-14.4.1/Makefile
        cd build/sox-14.4.1 && $(MAKE)

Once you have added all the rules, doing:

    make local/bin/sox

should result in all the sox build and install stages running.
However, they will only run if necessary -- if you run the
same command again, nothing will happen, because the target
already exists.

Add support for lame
--------------------

The same steps can be followed to add the commands to
build lame to the same makefile -- simply add the equivalent
rules after the rules for sox. You should mostly be able
to copy and paste the rules, then modify where necessary
to work with lame (There are ways to templatise
things like this, but we won't go into them here.)

Create a dummy target
---------------------

We'd also like an easy way to tell make to build all the
tools we need, so the final thing we'll do is create
a dummy target called ''tools''. Add the following
line to the end of your makefile:

    tools : local/bin/sox local/bin/lame

This is a dummy rule, because it has no commands, so the
`tools` target is considered to exist as long as both
sox and lame have been built. You can then type:

    make tools

and it will check that both tools have been built, and
if necessary perform the steps to build them.

Conclusion
----------

We now have an automated build system for getting and
downloading the tools. As a final test, clean the environment
as before (making sure not to delete your makefile), then do:

    make -j 4 tools

This should download and build all the tools, and as a bonus
you should see the compilation of both lame and sox proceeding
in parallel. Some of the output will be messed up, because
concurrent tasks are writing to the terminal, but the resulting
files will be ok.

**Note-1**: _The test tools for submissions will `make tools`
as the first step, so do make sure it works from a clean start._

**Note-2**: _These makefiles will look essentially identical, so
don't worry about us thinking you have plagiarised._

Once you are satisfied that this part works, `commit`
your work to your local git repository. This consists
of [two stages](http://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository):

- Staging: use the `git add` command to tell git that
  your want to add, or "stage", a file for the next commit.
  
- Committing: use the `git commit` command to tell
  git that you want to record all the currently staged
  changes.
  
I reccomend using a GUI (see the other notes about git),
which will make the process easier, and allows you to
combine the two steps.

So in this case, you need to `add` your `makefile` and
then `commit` it. It is generally a good idea to commit
whenever you get something working, but I particularly
want you to commit here.

The final thing I want you to do is to
[tag](http://git-scm.com/book/en/v2/Git-Basics-Tagging)
the repository with the tag "done_A". This is to
capture the state of the repository at this point,
so that you can always get back here.

On the command line you can use `git tag -a done_A`,
or again, the GUIs make it much easier.

Part B : Processing with pipes
========================================================

This section will play around with the concept of pipeline parallelism and
streaming, all in the context of streaming audio.

We'll be working in the directory `audio`, and will rely
on the two tools built in the previous section having already
been built. We will be using C rather than C++, but feel free
to use [C99](http://en.wikipedia.org/wiki/C99) constructs.

Some helper functions
---------------------

First we'll define some helper scripts to reduce typing. In
the audio directory, create a text file called `mp3_url_src.sh`
and enter the following text:

    #!/bin/bash
    curl $1 | ../local/bin/lame --mp3input --decode - -
    
The `$1` represents the first command line argument to
`mp3_url_src.sh`, and the `|` (pipe) is saying that the
output stream of curl should be sent to the  input stream
of lame. The output stream of lame will end up being the
output stream of the overall command.

Create another file called `audio_sink.sh`, and give it the contents:

    #!/bin/bash
    ../local/bin/sox  - -d
    
This sox command will play audio coming in over its input stream,
and it will inherit its input from the overall `audio_sink.sh` input
stream.

Save both files, and as before, be very careful about line endings on windows.
_If weird things are happening, try doing `cat -v your_file_name.sh`,
and check that there aren't any special characters at the end of the line.

We will now mark these scripts as executable, so that they
can be used as programs:

    chmod u+x mp3_url_src.sh audio_sink.sh
    
This command modifies the permissions for the user (`u`),
adding (`+`) the execute (`x`) permission. If you do a `ls -la`,
you should now see the files have the `x` attribute (on cygwin,
you may find _everything_ has the `x` attribute).

Now, with `audio` as your current directory, do:

    ./mp3_url_src.sh http://cas.ee.ic.ac.uk/people/dt10/teaching/2013/hpce/cw2/bn9th_m4.mp3 \
        | ./audio_sink.sh

This is equivalent to the streaming playback we set up in the previous section, but
we have hidden the details of the command line arguments. By wrapping them up in
little scripts, we have hidden the details, but can still connect them together
via their stdin (input stream) and stdout (output stream).

To let you record to an mp3 (useful if you can play via sox, or you
are getting sick of Beethoven), you can create another file
called `mp3_sink.sh`, containing:
    
    #!/bin/bash
    local/bin/lame -r -s 44.1 --signed --bitwidth 16 - $1

This will then let you do commands such as:

    ./mp3_url_src.sh http://cas.ee.ic.ac.uk/people/dt10/teaching/2013/hpce/cw2/bn9th_m4.mp3 \
        | ./mp3_sink.sh tmp.mp3

which would record to tmp.mp3 rather than playing the audio. You should be able to
kill it and listen to the partial mp3, rather than going all the way through.

Streaming from an URL is wasting bandwidth, so download the mp3 by doing:

    curl http://cas.ee.ic.ac.uk/people/dt10/teaching/2013/hpce/cw2/bn9th_m4.mp3 \
        > bn9th_m4.mp3

So we're downloading the file as before, but redirecting the output to
a local file. This performs the same function as using
the `-o` option you used to get the coursework spec. You
can check that the local file is a valid mp3 by playing
it in a normal mp3 player.

(From this point on, feel free to substitute any mp3s while testing the graphs,
or turn the volume down, as otherwise it gets very boring when you're debugging.
You will be explicitly told if you need to work with a particular mp3, or actually
listen to the output.)

Create a new script file called `mp3_file_src.sh`, and give it the body:

    #!/bin/bash
    ../local/bin/lame --mp3input --decode $1 -

You should now be able to do:

    ./mp3_file_src.sh bn9th_m4.mp3  |  ./audio_sink.sh

Here we have kept the same sink (`audio_out.sh`), but we
are using a different source which reads from a file rather
than an url. This ability to swap in and out parts of the
chain is one of the great strengths of the unix pipe
philosophy.

If we want to look at the speed of decoding, without
being constrained to the actual playback speed (the audio
sink will only accept samples at normal audio frequency),
we can redirect the output to a file. However, if we are
only interested in processing speed, we might as well avoid
writing to a real file, so there is no chance that disk speed will
slow us down. For this we can use [/dev/null](http://en.wikipedia.org/wiki//dev/null),
which is a special file which throws away anything written to it.

To time the command, we can use... `time`. This
takes as an argument the command to execute, then says how
long it took.

    time ( ./mp3_file_src.sh bn9th_m4.mp3  > /dev/null )

you'll notice that the CPU usage shoots up to 100\% (at least
on one CPU), and it will probably decode the file in 
a few seconds.

Getting raw data
----------------

The default output for lame when decoding is a [wav](http://en.wikipedia.org/wiki/WAV)
file, containing the raw data from the stream. For example, if you do:

    ./mp3_file_src.sh bn9th_m4.mp3  > ../tmp/dump.wav

then you should be able to play the resulting wav in a standard media player.

The media player can do this because wav files contain meta-data, as well
as the raw sound samples. So the header describes things like the sampling
rate, the number of channels, the bits per sample, and the endian-ness.
We don't want to bother with the header, so for the rest of this coursework,
whenever we pass audio data around it will be:

- Dual channel (stereo).
- 16 bits per sample; signed; little-endian.
- 44.1 KHz.

By default lame will add a wav header, so we need to get rid of that. Sox is
also expecting a wav header so it knows what kind of data it is, so we'll need to
manually specify that instead.

If you look at the documentation for lame, it specifies the [`-t` option](http://lame.cvs.sourceforge.net/viewvc/lame/lame/doc/html/detailed.html#t)
to get raw output, so update both `mp3\_file\_src.sh` and `mp3\_url\_src.sh`
to pass that flag to lame.

The [documentation for sox](http://sox.sourceforge.net/sox.html) details multiple settings which can be used
to specify the input file configuration, you can find it by looking for "Input \& Output File Format Options".
First note that the settings can be applied to either the input or output stream of sox, depending on
which filename it appears before. In this case we want to specify what the format
of the input stream is, so in `audio_sink.sh` insert the flag `-t raw` before the
hyphen representing stdin, along with options to specify the format of the audio
data as described above.

Now try running the same streaming command as before:

    ./mp3_file_src.sh bn9th_m4.mp3  |  ./audio_sink.sh

If all has gone well, the data streaming between them will now be raw binary,
rather than a wav file, but the effect should be exactly the same. If it
sounds weird or distorted, double check that you have set the correct format
on both side.

While you are modifying settings, you may notice that both lame and sox
produce quite a lot of diagnostic information as they run. You may wish
to suppress this in your scripts, using `--silent` and
`--no-show-progress` options, respectively.

A simple pass-through filter
----------------------------

Now we'll now finally start adding our own stuff to the pipeline. You
will find a file in `audio` called `passthrough.c`. Compile it by
doing:

    make passthrough

Note that even though we don't have a makefile in the directory, make
has some [default rules](http://www.gnu.org/software/make/manual/html_node/Catalogue-of-Rules.html)
for common processes. In this case, make knows how to turn a file called
`XXXX.c` into an executable called `XXXX`.

Insert your new filter into the chain:

    ./mp3_file_src.sh bn9th_m4.mp3  | ./passthrough  | ./audio_sink.sh

If all goes well it should sound the same.

However, if you look at the processes in a process manager, you'll most
likely see that `passthrough` is taking up a lot of CPU time, probably
more than lame and sox (though it varies between systems). To make this
effect clearer, use the same approach as before to remove the speed limitations:

    ./mp3_file_src.sh bn9th_m4.mp3 |  ./passthrough  > /dev/null

Depending on your system, you may now see that `passthrough` is taking
up one entire CPU core, while lame is taking less CPU time. At the
very least, `passthrough` will be using a lot of CPU to do not very much.

One possible problem is that we are compiling it with no optimisations.
Create a makefile in the `audio` directory, and add the statements:

    CPPFLAGS += -O2 -Wall
    LDFLAGS += -lm

here we are adding three flags that will be passed to the C compiler:
`-O2` turns on compiler optimisations; `-Wall` enables
warnings (generally a useful thing to have for later stages); and
`-lm` tells it to link to the maths library. If you wish, you could
also add `-std=c99` to the flags, if you want to use C99 constructs.

Now build it again with:

    make passthrough

You will likely find that nothing happened, because from make's point of
view the target `passthrough` (i.e. the executable) already exists, and
has a more recent timestamp than `passthrough.c`. You have two ways to force it to
do the make:

1. Modify the source file `passthrough.c`, i.e. make sure the
   file's modification date is updated to now (which will be more
   recent than the . You could do that by simply
	odifying and saving the C file, or by using the `touch` command.

2. Pass the `-B` flag to make, in order to force it to
   ignore timestamps and build everything. So you could
   do `make -B passthrough`.

If you run the optimised version, you'll still find much the same problem,
with `passthrough` being very slow (at least for the amount of work being done).

The problem here is excessive communication per computation. Passthrough is
pretty much all communication: all it does is read from one pipe and write
to another. The problem is in the fixed-costs versus per-byte costs: there
is quite a lot of OS overhead to call `read` and `write`,
so for very small transfers the per-byte cost is dwarfed by the cost of
setting up the transfer. This is very similar to the argument we used for
vectorisation, where the scheduling cost (i.e. doing a read) is high, while
the calculation cost (actually getting each byte) is relatively cheap.

The solution is that instead of reading just one time sample (i.e. four
bytes), each call to read and write should move multiple samples, using
a larger buffer.

**Task**: Modify passthrough so that instead of processing 1 time sample (4 bytes),
it processes n samples (n*4 bytes). If the executable is given no arguments,
it should use a default of 512 samples. If a positive integer is passed to
passthrough, then that should be the number of samples used to buffer.

You can explore the effect of batch size on performance by
looking at bandwidth using raw data. We've seen `/dev/null`
as a pure "black-hole" sink, but we can also use `/dev/zero` as a
"white-hole" source - it contains an infinite stream of
zeros. Because the stream is inifinite, if you do:

    cat /dev/zero | ./passthrough 16 > /dev/null

it will spin forever (you can kill it with ctrl-c). The
`head` command can be used to return the first few lines
of a stream, but we can also use it to return the first N
bytes of a stream using `head -n N`. So if we do:

    time cat /dev/zero | head -c 1000000 | ./passthrough > /dev/null

tt will estimate the time take to process a million bytes.

We would like to know how the execution time scales
with n, so we could do:

    time cat /dev/zero | head -c 1000000 | ./passthrough 1 > /dev/null
    time cat /dev/zero | head -c 1000000 | ./passthrough 4 > /dev/null
    time cat /dev/zero | head -c 1000000 | ./passthrough 16 > /dev/null

but that involves a lot of copying and pasting, and is
error prone. Wherever possible we want to generate
timings automatically, and with good coverage of the
space.

Bash has a for loop built in, which you can use from the
shell. For example:

    X="1 2 3 4 A B C D";  # Create a list of things to process
    for val in $X; do     # Loop over the list
        echo $val;        # Print each item
    done

We can use that to quickly evaluate the scaling of the program:

    NS="1 2 4 8 16 32 64 128 256 512 1024"; # What to measure over
    for n in $NS; do
        echo $n;
        time -f %e cat /dev/zero | head -c 1000000 | ./passthrough $n > /dev/null
    done

From here it is possible to see how we are approaching
your function timer from the matlab exercise. Instead
of passing functions to functions, we are passing programs
to programs.

Dumping signals
---------------

**Task**: Write a C program called `print_audio.c`, which reads
audio data from stdin, and then prints it as output to stdout
as comma-seperated-value lines containing:
- The sample index (first sample is at time zero).
- The effective time of the sample (first sample is at time zero).
- The left channel in decimal (remember it is signed 16-bit).
- The right channel in decimal


For example:

    cat 200hz.raw | head -c 64 | ./print_audio

Should produce the output:

    0, 0.000000, 0, 0
    1, 0.000023, 854, 854
    2, 0.000045, 1708, 1708
    3, 0.000068, 2561, 2561
    4, 0.000091, 3412, 3412
    5, 0.000113, 4259, 4259
    6, 0.000136, 5104, 5104
    7, 0.000159, 5944, 5944
    8, 0.000181, 6779, 6779
    9, 0.000204, 7609, 7609
    10, 0.000227, 8433, 8433
    11, 0.000249, 9250, 9250
    12, 0.000272, 10059, 10059
    13, 0.000295, 10860, 10860
    14, 0.000317, 11653, 11653
    15, 0.000340, 12435, 12435
    
The exact number of output digits for the "time" column is not
that important, but it should show enough digits that it is possible
to see the time changing.
    
_This task is intentionally easy; experience suggests that people
won't create debugging tools unless they are forced too._

Generating signals
------------------

**Task**: Write a C program called `signal_generator.c` which can synthesise sine waves
of a given frequency (I would suggest copying and modifying `passthrough.c`). This
program should have one argument, which is a floating-point
number giving the desired frequency (`f`). If there is no argument, then the
default frequency should be 200hz. The generator should use a batch size of
512 stereo samples, i.e. each time it writes to stdout it will write 2048 bytes.

If we consider the very first sample output to have time `t`=0, then at
time `t` both left and right output should have the value:

    30000 sin ( t * 2 * PI * f) 
    
rounded to 16 bit. An example segment is given in `200hz.raw`.
There should be no "glitching" in the output - the end
of one set of 512 samples should blend smoothly into the
next.

If you pipe the output of your signal generator to `audio_sink.sh`, then
you should hear a sine wave. It will get annoying quickly.

A tool you may find useful in debugging is `diff`, which lets
you compare two files for differences. The `--binary` mode
will treat them as binary streams (which is what you want).

Merging signals
---------------

**Task**: Write a C program called `audio/merge.c`, which takes two input streams, specified
as files on the command-line, and merges them to a single output stream which is
sent to stdout. The merging function should take an equally weighted blend
from both streams, so if you supply the same input for both arguments, you'll end up
with the same thing back. Unlike before, you'll actually have to open the
two input files, rather than just using stdin. Use a batch size of 512 samples
(2048 bytes) again.

In order to test this program, you'll need two raw files. You can generate them just as:

    ./signal_generator 1000 > ../tmp/sine1000.raw
    ./signal_generator 2000 > ../tmp/sine2000.raw

For each command, let it run for a couple of seconds, then kill it with ctrl-c.
You can now test your program `merge`, by doing:

    ./merge ../tmp/sine1000.raw ../tmp/sine2000.raw
        | ./audio_sink.sh

Going via temporary files means that data is forced onto disk (or
at least to disk cache), but really we'd prefer things to stay
in memory. One way of doing this is to use another feature of
bash called input redirection. Do the command:

    ./merge  <(./signal_generator 1000)  <(./signal_generator 2000) \
        | ./audio_sink.sh

This process can actually be nested, so for example, you could write:

    ./merge \
        <(./merge \
            <(./mp3_file_src.sh bn9th_m4.mp3) \
            <(./merge <(./signal_generator 600)  <(./signal_generator 700)) \
        ) \
        <(./merge \
            <(./merge <(./signal_generator 800)  <(./signal_generator 900)) \
            <(./merge <(./signal_generator 1000)  <(./signal_generator 100)) \
        ) \
        | ./audio_sink.sh

This sounds terrible, and looks terrible, but you could hide it
in a script. What is important is that you have connected
these sequential programs into a single parallel processing graph. There
are no intermediate files, so it can keep going for ever.

The effect of this is more obvious if you redirect the output to `/dev/null`:

    ./merge \
        <(./merge \
            <(./mp3_file_src.sh bn9th_m4.mp3) \
            <(./merge <(./signal_generator 600)  <(./signal_generator 700)) \
        ) \
        <(./merge \
            <(./merge <(./signal_generator 800)  <(./signal_generator 900)) \
            <(./merge <(./signal_generator 1000)  <(./signal_generator 100)) \
        ) \
        > /dev/null

The CPU usage should shoot up, and on my 8-core desktop I get about 6
of the cores fully utilised.

So to re-iterate: you have created a parallel processing pipeline,
which does not touch disk, and can be reconfigured without
any compilation.

FIR filtering
-------------

The final function we'll add is [discrete time FIR filtering](http://en.wikipedia.org/wiki/Finite_impulse_response).
FIRs are examples of useful but time consuming filters that need to be applied in
real-time streaming systems, but bear in mind I'm not a DSP expert -- feel free
to laugh at the naivete of my coefficients.

We can represent one channel of our discrete-time input audio as
the sequence x_1,x_2,... and we'll filter it with a k-tap FIR filter.
The filter has k real coefficients, c_0,..c_{k-1}, and the output sequence
$x'_1,x'_2,...$ is defined as:

    x'_i = \sum_{j=0}^{k-1} x_{i-j} c_{j}

In the `audio/coeffs` directory you'll find a number of coefficient sets
for notch filters, with filenames of the form `fXXX.csv`, where XXXX is the
centre frequency. Different filters have different orders.

**Task**: Write a program called `audio\fir_filter.c` that takes as an
argument a filename specifying the FIR coefficients, which will apply the
FIR filter to each channel of the data coming from stdin, and write the
transformed signal to stdout. All internal calculations should be in
double-precision, but input and output should be in stereo 16 bit as normal.

So for example, if you write:

    ./merge <(./mp3_file_src.sh bn9th_m4.mp3) <(./signal_generator 800) \
        | ./audio_sink.sh

you'll get audio mixed with a sine wave, but if you do:

    ./merge <(./mp3_file_src.sh bn9th_m4.mp3) <(./signal_generator 800) \
        | ./fir_filter coeffs/f800.csv \
        | ./audio_sink.sh

then hopefully most of the sine-wave disappears. If you double up the filter:

    ./merge <(./mp3_file_src.sh bn9th_m4.mp3) <(./signal_generator 800) \
        | ./fir_filter coeffs/f800.csv \
        | ./fir_filter coeffs/f800.csv \
        | ./audio_sink.sh

then it should be completely gone.

Note that I'm not looking for bit-exact results here -- I've deliberately
left things ambiguous enough to give you some freedom of implementation
(e.g. things like buffering), so don't worry if you get slightly different
results as me. As long as the effect is correct from a signal processing
point of view (i.e. does the 800Hz signal get attenuated?), then my tools
will detect that. I won't required exact per sample matches.

Some benchmarking
-----------------

We're now going to benchmark two different ways of using our FIRs: first
by using intermediate files, then by using direct streaming. 

**Task**: Create a script called `audio/corrupter.sh`, which takes an audio
stream as input, mixes it with sine waves, and produces an output. This script
should be streaming, i.e. it can run forever as long as it keeps getting input.
The ratios should be:

| Source |  Weight |
|--------|---------|
| Input  |     25% |
| 500hz  |   12.5% |
| 600hz  |   12.5% |
| 800hz  |   12.5% |
| 1000hz |   12.5% |
| 1200hz |   12.5% |
| 1400hz |   12.5% |

Hint: _This script could look very similar to the merge script we
saw before, which merged together multiple sin waves with a signal
from an mp3 and send it to the audio device. In this case, we want
the input to come from the stdin of the script, and the output to
go to the stdout. To get the stdin of the script, you can try
"grabbing" it using `<(cat -)`, which gives you a stream
containing stdin that you can pass in place of the mp3 stream._

**Task**: Create a file called `all_firs_direct.sh`. This should
take an audio stream from stdin, and produce on stdout
another stream that has had applied a notch filter at
500, 600, 800, 1000, 1200, and 1400 hz (using the
f500,f600,...,f1400, coefficient files provided). This
script should not use any intermediate files.

Hint: _this can be a pretty simple pipeline of fir filters, each connected to
the next, with the first one taking the stdin of the script, and the last
one producing the stdout._

**Task**: Create another file called `all_firs_staged.sh`. This will do exactly
the same job as `all_firs_direct.sh`, except each stage will read input from
a named file, and write to a named file. We _may_ wish to call this script
in parallel with itself, so try be careful about what the intermediate named files
are called.

A useful pattern within the script may be to use [mktemp](http://unixhelp.ed.ac.uk/CGI/man-cgi?mktemp),
so for example:

    T1=$(mktemp ../tmp/XXXXXXXX);
    ./mp3_file_src.sh bn9th_m4.mp3 > $T1;
    cat $T1 | ./audio_src.sh

will create temporary file and store the name in variable T1, then
decode the entire file to T1, then send it to the audio source.

Hint: _your script could start with something like_:

    #!/bin/sh

    T1=`mktemp ../tmp/XXXXXXX`;
    ./fir_filter coeffs/f500.csv > $T1;

    T2=`mktemp ../tmp/XXXXXXX`;
    cat $T1 | ./fir_filter coeffs/f600.csv > $T2;
    
    ...

_where the first filter is taking stdin from the script's stdin,
and the next one reads it from the temporary file identified
by T1._


Once you have written these three scripts, you can then try to
work out how much time is saved by avoiding disk, by doing:

    time (./mp3_file_src.sh bn9th_m4.mp3 | ./corrupter.sh | ./all_firs_direct.sh > /dev/null )

versus:

    time (./mp3_file_src.sh bn9th_m4.mp3 | ./corrupter.sh | ./all_firs_staged.sh > /dev/null )

You may want to use a short mp3 file, unless your FIR is blazingly fast.

Exact results will vary with your system, but what you'll probably see
is that in the direct case, all six fir filters are working together.
If you've got two CPUs, both should be at 100\%; for four CPUs
there is enough work to occupy all of them; and for eight CPUs,
you'll see some of the fir\_filters with more taps working flat-out,
while some of the filters with fewer taps are operating a little
under load.

In the staged case, which may appear the more natural approach if you have
a bunch of discrete tools to use together, each of the stages in turn
will occupy 100\% of just one CPU. As only one thing is being done at
once, you lose the ability to exploit the extra cores, and on my eight-core
desktop it takes just over six times longer than the streaming method.

Conclusion
----------

**Task**: Add the following to the end of `./audio/makefile`:

    filters : merge fir_filter passthrough signal_generator

This will allow users to go into the `audio` directory and
type `make filters`, and all your files will be updated. Also
add the following to the end of `./makefile`:

    filters :
        cd audio && $(MAKE) 

    all : tools filters

which means that from the base directory you can can type:

    make all
    
and it will build all the tools and all the audio filters
(and if you do `make -j 4` it will use up to 4 parallel
processes to do so).

**Task**: Once it is all working, do another commit of
your source files (don't forget to add/stage the new .c and .sh files).
Add a tag to the repository called `done_B` to record this
point.

Submission
==========

**Task**: To prepare this coursework for submission, go
into the root directory and do:

    ./prepare_submissions.sh

This should create a submission tarball in the directory below
your work. Note that it will include the git repository (.git),
which will contain the history of your work.

Before submitting, you should do a number of checks to make sure
it works:

1. Extract the tarball to a fresh directory.
2. `make all` in the base of the submission to build everything.
3. Go into the audio directory and run `make tools`.
4. Choose an mp3, and `./mp3_file_src.sh your_mp3.mp3 | ./corrupter.sh | ./all_firs_direct.sh > /dev/null`.

If that all works, submit your tarball via blackboard.

Congratulations! You now know how to:

1. Build and install random software packages without being root.
2. Automate the creation of build environments.
3. Declare dependency graphs using makefiles.
4. Perform parallel processing using makefiles.
5. Exploit recursive parallelism (Remember that sox and lame will get built together).
6. Integrate together multiple disparate tools using pipes.
7. Exploit streaming parallelism using pipes.

Endnotes
========

Environments
------------

Lame and sox should (!) compile and work everywhere, though
sox may refuse to play audio in some environments. If
necessary, record to an mp3 or wav (there is no real need
to listen, except to prove to yourself it is streaming).


### Ubuntu/Debian : Private installation

By default the headers and libs for ALSA sound are not
installed in all distributions, though the libraries are. You
need to install `libasound2-dev` using whatever package manager
you used.

