# Symbolicate IPS

A shell script to symbolicate `.ips` crash files using `.dSYM` files.

## Features

- **Auto Tool Discovery**: Automatically finds the `symbolicatecrash` tool in your Xcode installation
- **Environment Handling**: Sets `DEVELOPER_DIR` automatically
- **Timestamped Output**: Creates unique output files to avoid overwriting previous analyses
- **Error Feedback**: Clear error messages if UUIDs don't match

## Usage

```bash
cd symbolicate-ips
chmod +x symbolicate.sh
./symbolicate.sh <path_to_ips> <path_to_dsym>
```

### Example

```bash
./symbolicate.sh ~/Downloads/osee2unifiedRelease-2026-03-11-104704.ips ~/Downloads/output.app.dSYM
```

## Output

The script creates a file named `symbolicated_crash_YYYYMMDD_HHMMSS.txt` with the symbolicated crash log.

## Troubleshooting

If symbolication fails with "UUID mismatch":

1. Run `dwarfdump --uuid <your.dSYM>` to get the dSYM UUID
2. Compare it to the UUID in the "Binary Images" section of your `.ips` file
3. Make sure you have the correct dSYM for the build that produced the crash

## Requirements

- macOS
- Xcode installed in `/Applications/Xcode.app`
