// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  ISC License - see included file LICENSE
// ********************************************************

{$define B0	     := $00000000}
{$define B50     := $00000001}
{$define B75     := $00000002}
{$define B110    := $00000003}
{$define B134    := $00000004}
{$define B150    := $00000005}
{$define B200    := $00000006}
{$define B300    := $00000007}
{$define B600    := $00000008}
{$define B1200	 := $00000009}
{$define B1800	 := $0000000a}
{$define B2400	 := $0000000b}
{$define B4800	 := $0000000c}
{$define B9600	 := $0000000d}
{$define B19200	 := $0000000e}
{$define B38400	 := $0000000f}
{$define B57600  := $00000010}
{$define B115200 := $00000020}

{$define BRKINT  := $00000100}
{$define ICRNL	 := $00000200}
{$define IGNBRK	 := $00000400}
{$define IGNCR	 := $00000800}
{$define IGNPAR	 := $00001000}
{$define INLCR	 := $00002000}
{$define INPCK	 := $00004000}
{$define ISTRIP  := $00008000}
{$define IXOFF	 := $00010000}
{$define IXON    := $00020000}
{$define PARMRK	 := $00040000}

{$define OPOST	 := $00000100}

{$define CLOCAL	 := $00000100}
{$define CREAD	 := $00000200}
{$define CS5     := $00000000}
{$define CS6     := $00000400}
{$define CS7     := $00000800}
{$define CS8     := $00000c00}
{$define CSIZE	 := $00000c00}
{$define CSTOPB	 := $00001000}
{$define HUPCL	 := $00002000}
{$define PARENB	 := $00004000}
{$define PARODD	 := $00008000}

{$define ECHO    := $00000100}
{$define ECHOE	 := $00000200}
{$define ECHOK	 := $00000400}
{$define ECHONL	 := $00000800}
{$define ICANON	 := $00001000}
{$define IEXTEN	 := $00002000}
{$define ISIG    := $00004000}
{$define NOFLSH	 := $00008000}
{$define TOSTOP	 := $00010000}

{$define TCIFLUSH   :=  1}
{$define TCOFLUSH   :=  2}
{$define TCIOFLUSH  :=  3}
{$define TCOOFF     :=  1}
{$define TCOON      :=  2}
{$define TCIOFF     :=  3}
{$define TCION      :=  4}

{$define TCSADRAIN  :=  1}
{$define TCSAFLUSH  :=  2}
{$define TCSANOW    :=  3}

{$define VEOF       :=  1}
{$define VEOL       :=  2}
{$define VERASE	    :=  3}
{$define VINTR	    :=  4}
{$define VKILL	    :=  5}
{$define VMIN       :=  6}
{$define VQUIT	    :=  7}
{$define VSTART	    :=  8}
{$define VSTOP	    :=  9}
{$define VSUSP	    := 10}
{$define VTIME	    := 11}
{$define NCCS       := 12}

type
  cc_t = Longword;
  speed_t = Longword;
  tcflag_t = Longword;

type
  termios = record
    c_cc     : array [1..NCCS] of cc_t;
    c_cflag  : tcflag_t;
    c_iflag  : tcflag_t;
    c_lflag  : tcflag_t;
    c_oflag  : tcflag_t;
    c_ispeed : speed_t;
    c_ospeed : speed_t;
end;

type
  Ptermios = ^termios;
  
function cfgetispeed(const _termios_p : Ptermios) : speed_t; external;
function cfgetospeed(const _termios_p : Ptermios) : speed_t; external;
function cfsetispeed(_termios_p : Ptermios; _speed : speed_t) : Integer; external;
function cfsetospeed(_termios_p : Ptermios; _speed : speed_t) : Integer; external;
function tcdrain(_fildes : Integer) : Integer; external;
function tcflow(_fildes, _action : Integer) : Integer; external;
function tcflush(_fildes, _queue_selector : Integer) : Integer; external;
function tcsendbreak(_fildes, _duration : Integer) : Integer; external;
//function tcgetattr(_fildes : Integer; _termios_p : Ptermios) : Integer; external;
//function tcsetattr(_fildes, _optional_actions : Integer; const _termios_p : Ptermios) : Integer; external;

{$ifndef _POSIX_SOURCE}

// Input flags 
{$define IMAXBEL := $01000000}	// ring bell on input queue full

// Local flags 
{$define ECHOKE	 := $01000000}	// visual erase for line kill
{$define ECHOCTL := $02000000}	// echo control chars as ^x

// Output flags 
{$define ONLCR	 := $00000200}	// map NL to CRNL
{$define OCRNL	 := $00000400}	// map CR to NL
{$define ONOEOT	 := $00000800}	// discard EOT's (^D) on output

// Compatibility 
procedure cfmakeraw(_termios_p : Ptermios); external;
function cfsetspeed(_termios_p : Ptermios; _speed : speed_t) : Integer; external;

{$endif}

