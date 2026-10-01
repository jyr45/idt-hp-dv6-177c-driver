# IDT 92HD81B1C audio driver for HP 6360t / Pavilion dv6 (SUBSYS_103C177C)

HP's IDT driver (sp65008, 6.10.6498) with `HDAUDIO\FUNC_01&VEN_111D&DEV_7605&SUBSYS_103C177C` added to
`STWRT64.INF` and `stwrt64.ini` (mapped to `WRT_M11-6E.INI`, same as SUBSYS_103C17CE).
This makes the mute button LED work on Windows 11.

The INF/INI changes invalidate HP's signature, so Windows must be in test-signing mode:

1. Admin PowerShell: `bcdedit /set testsigning on`, then reboot.
2. Copy `driver` to `C:\IDT_177C`.
3. Admin PowerShell: `powershell -ExecutionPolicy Bypass -File firmar_e_instalar_idt.ps1`
   (creates a self-signed test cert, trusts it, signs a catalog, runs `pnputil /add-driver`).

Revert: `pnputil /delete-driver oemXX.inf /uninstall /force`, `bcdedit /set testsigning off`, remove the
"IDT177C Test Signing" cert in `certlm.msc`.

Binaries are property of HP / IDT (now Renesas); redistributed unmodified apart from the two text files above.

## Quick install (release zip)
Download `IDT-177C-installer.zip` from Releases, extract, run `instalar.cmd` (it asks for admin). First run enables test-signing and asks you to reboot; run it again after rebooting.

