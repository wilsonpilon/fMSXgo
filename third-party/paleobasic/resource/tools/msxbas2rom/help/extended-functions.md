# Extended Functions

Functions provide powerful ways to retrieve information or extend MSX BASIC behavior.

---

## Why Use Extended Functions?
- Simplify complex routines;
- Provide compiler-optimized alternatives.

---

## Examples
- `HEAP()` — return the RAM free area start address;
- `MSX()` — return the machine MSX version;
- `COLLISION(s1,s2)` — sprite collision helper.

---

## Complete List

### **General Functions**

```text
    - FRE() return free RAM size only (doesnt accept parameters);
    - HEAP() return first free RAM address;
    - TILE(x,y) return character from position (screens mode 0-2, text coords);
    - MSX() return current machine version (0: MSX1, 1: MSX2,
      2: MSX2+, 3: MSXturboR);
    - NTSC() return true to a NTSC (or PAL-M) machine and false to a PAL one;
    - TURBO() return true to cpu turbo mode (R800 or 5.37mhz) or false
      to standard mode (Z80/3.57mhz). Use with CMD TURBO...
    - VDP() without parameters return VDP version (0: TMS9918A, 1: V9938,
      2: V9958, x: VDP ID);
    - MAKER() return the manufacturer ID [1:ASCII/Microsoft, 2:Canon, 3:Casio,
      4:Fujitsu, 5:General, 6:Hitachi, 7:Kyocera, 8:Matsushita (Panasonic),
      9:Mitsubishi, 10:NEC, 11:Nippon Gakki (Yamaha), 12:JVC, 13:Philips,
      14:Pioneer, 15:Sanyo, 16:Sharp, 17:SONY, 18:Spectravideo, 19:Toshiba,
      20:Mitsumi, 21:Telematica, 22:Gradiente, 23:Sharp Brazil,
      24:GoldStar(LG), 25:Daewoo, 26:Samsung,
      212:1chipMSX/Zemmix Neo(KdL firmware)];
      Works only in some MSX2 machines;
```

### **Data Functions**

```text
    - INKEY() is an alternative to INKEY$, but returning an integer instead;
    - IPEEK()/IPOKE is similar to PEEK()/POKE, but applied for integer data; 
    - USING$(format$, number) works just like PRINT USING statement;
```

### **Music Functions**

```text
    AKM PLAYER STATUS (bit 7 = end of song reached, bit 0 = loop status)

       <STATUS> = PLYSTATUS()

    Read PSG register

       n = PSG( <register number> )
```

### **Sprite Collision Detection Functions**

```text
    - COLLISION() return if any sprite collided with another sprite, else
      return -1;
    - COLLISION(<n>) return if a sprite <n> collided with another sprite,
      else return -1;
    - COLLISION(<n1>,<n2>) return n2 if sprite n1 collided with n2, else
      return -1;

    <-1=no collision|collided sprite number> = COLLISION( <-1=any sprite | sprite1> [, <sprite2> ] )
```

Examples

```text
       Beep if any sprite collided with each other:
          SN# = COLLISION(-1)
          IF SN# >= 0 THEN BEEP
       Beep if any sprite collided with sprite 2:
          SN# = COLLISION(2)
          IF SN# >= 0 THEN BEEP
       Beep if sprite 4 collided with sprite 5:
          SN# = COLLISION(5)
          IF SN# = 4 THEN BEEP
       Beep if sprite 5 collided with sprite 4 (direct test):
          SN# = COLLISION( 5, 4 )
          IF SN# >= 0 THEN BEEP
       Beep if sprite 0 collided with sprite 1 (direct test):
          SN# = COLLISION( 0, 1 )
          IF SN# >= 0 THEN BEEP
```

Notes

- Sprites with same X and Y position are considered the same object, thus there's no collision in this case.

### **Resource Functions**

```text
    Get resource data address

       <address> = RESOURCE(<rsn>)
       - RESOURCE(number) return resource start address (use with COPY);

    Get resource data size

      <size> = RESOURCESIZE(<rsn>)
```

### **Deprecated Functions (for tokenized mode)**

```text
    Resource number

       <address> = USR0(<rsn>)

    Resource size

       <size> = USR1(<rsn>)

    PLAY() function alternative

       <0=false> = USR2(0)

    INKEY$ function alternative (for tokenized mode)

       <ASC> = USR2(1)

    INPUT$(1) function alternative (for tokenized mode)

       <ASC> = USR2(2)

    Sprite collision

       <-1=no collision|collided sprite number> = USR3( <-1=any sprite | sprite1 | &h1122> )

    Arkos Tracker Status

       <STATUS> = USR2(3)

```

---

See also [Arkos Tracker Music Support](https://github.com/amaurycarvalho/msxbas2rom/wiki/Music-Support).

