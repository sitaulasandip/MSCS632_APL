

## Run C++

Requires a C++17 compiler (g++ 8+, clang++, `zig c++`, or MSVC 2017+). From `assignment_5`:

```powershell
g++ -std=c++17 -Wall -Wextra -o cpp/ride_sharing cpp/ride_sharing.cpp
./cpp/ride_sharing
```

With MSVC, from a Developer PowerShell: `cl /std:c++17 /EHsc cpp\ride_sharing.cpp`

## Run Smalltalk

Requires Pharo 12 (https://pharo.org/download). From `assignment_5`, headless:

```powershell
PharoConsole --headless Pharo.image st --quit smalltalk/RideSharing.st
```

Or open Pharo, drag `smalltalk/RideSharing.st` onto the window, and choose "File in entire file";
the demo output appears in the Transcript.

