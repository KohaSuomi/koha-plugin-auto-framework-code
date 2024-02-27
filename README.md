# Koha-Suomi plugin Auto Framework Code

A Koha plugin to automatically figure out what framework code should be used
for a record.

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

Please check that you have the same framework codes in your database and change them accordingly. If you add here codes that have no correspondence in your frameworks will the biblios on and items using these codes look "empty" when editing.
