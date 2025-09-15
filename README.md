# Invistegos

Undetectable steganographic disk encryption

## What

Invistegos is an implementation of the project described by Dominic Schaub in his presentation
[Perfectly Deniable Steganographic Disk Encryption](https://www.blackhat.com/eu-18/briefings/schedule/#perfectly-deniable-steganographic-disk-encryption-12745).
The goal is to create two full operating systems, the cover and the hidden, on the same disk such
that the cover system can function with no awareness of the hidden system without any unusual
software or configurations; a default installation.

## Why

Because despite my - admittedly, perhaps subpar - efforts to find any source code, I have found
nothing. Ever since, this project has haunted me. I had found the magnum opus of steganographic FDE,
seen it working, and yet it was just out of reach. So I guess I'm making it now.

## How

See Schaub's [presentation](./eu-18-Schaub-Perfectly-Deniable-Steganographic-Disk-Encryption.pdf)

## Project Layout

```text
invistegos
├── loader - initial executable that decodes and loads bootstrap from disk
├── bootstrap - userspace executable that emulates kernel module
└── kernmod - LKM that manages encryption, ECC, and system isolation
```
