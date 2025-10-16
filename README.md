# ADL

adl (pronounced "Addle") is a tool for managing ADRs (architecture decision records) in a directory (ideally inside of a repo).

adl helps generate markdown files for capturing information in an ADR and generates a README in your `adr` directory to help catalogue everything. The README also provides information on how to use `adl` to manage your `adr`s.

## How to use

Install adl and add it to your path. **Do not run copy/paste this script. Read it, and run only the parts that you need.**

```bash
# Use the appropriate binary for your OS and Arch
binary="adl_linux_arm"    # linux arm
binary="adl_linux_x86"    # linux x86
binary="adl_mac_arm"      # mac arm 
binary="adl_mac_x86"      # mac x86
binary="adl_windows_x86"  # windows

# curl, follow redirects, output to "adl", download target latest release
curl -L -o adl https://github.com/bradcypert/adl/releases/latest/download/$binary

# You _may_ need to update permissions for adl
chmod 744 adl

# You probably also want to move this to a place that exists in your path
mv adl /usr/local/bin
```

As of now, `adl` ships with two commands.

### Generating a new ADR

`adl create Deno as a platform`

This will create a new README in your `adr` directory (creating that directory if necessary) and a README that begins with a series of 0-padded numbers and args after `create`. For example, if this was your first ADR, it would create the file `YOUR_PROJECT_ROOT/adr/00000-Deno-as-a-platform.md`. It would then generate a README in the same directory and start cataloguing your ADRs for you.

### Regenerating the README

`adl regen`

There may come a time where you need to regenerate the readme without creating a new `adr`. The above command will do just that.
