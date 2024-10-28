# Koha-Suomi plugin Auto Framework Code

A Koha plugin to automatically figure out what framework code should be used
for a record. Plugin looks at record's leader's (000) character positions. For example if there is 'a' in leader's character position 06 a framework code 'KIR' is selected.

## Example configuration

```
---
- 000/06 + 000/07:
   a+s: SER
- 000/06:
   a: KIR
   c: NUO
   e: MAP
   g: VR
   j: CDA
   r: LAU
   t: KIR
- 008/26 + 000/06:
   g+m: KP
```
Example from Vaski-kirjastot:

```
- 000/06 + 000/07:
   a+s: SER
   j+a: MUO
- 000/06 + 007/00-01:
   a+cr: EKIR
- 000/06 + 008/26:
   m+g: KP
   r+g: LAU
- 000/06 + 008/22:
   i+f: CELI
- 000/06:
   a: KIR
   c: NUO
   e: MAP
   g: VR
   i: AUD
   j: SR
   o: MONI
   r: ESI
   t: KIR
```

Example from OUTI-kirjastot
```
---
- 000/06 + 000/07:
   a+s: SER
- 000/06:
   a: KIR
   c: NUO
   e: MAP
   g: VR
   j: CDA
   t: KIR
- 008/26 + 000/06:
   g+m: KP
- 008/33 + 000/06:
   g+r: LAU
```

Please check that you have the same framework codes in your database and change them here accordingly. If you add here codes that have no correspondence in your frameworks will the biblios on and items using these codes look "empty" when editing.
