License Scanning Guidance

Options for license scanning:
- FOSSology: full license discovery and reporting (heavy install)
- ScanCode Toolkit: fast license detection with SPDX output (recommended for labs)

ScanCode quick usage (docker):

```bash
docker run --rm -v $PWD:/src:ro nexB/scancode-toolkit scancode --format json --output /src/scancode-report.json /src
```

You can then archive `scancode-report.json` as a build artifact and fail builds if disallowed licenses are found.

Map license policies to allowed/disallowed and implement a Jenkins step to parse the JSON and fail accordingly.
