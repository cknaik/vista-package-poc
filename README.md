# VistA Package POC

Sample/fake VistA routines used to validate the CI/CD pipeline described in
`docs/VistA-DevOps-POC-Architecture.md`.

## Branching

- One feature branch per change: `feature/<dev>-<change-description>`
- Open a PR against `main`
- Merging to `main` triggers Jenkins (polls this repo every 5 minutes) to
  deploy `routines/*.int` or `routines/*.m` into the shared VistA/IRIS dev instance

## Layout

- `routines/` — the actual package source (`.int` or `.m` files - both accepted, normalized to `.int` automatically at deploy time since that's what IRIS's import expects)
- `build/load-routines.sh` — deploy step Jenkins runs on every merge to `main`
- `build/export-kids.sh` — sprint-end KIDS build export (manual/scheduled, not part of continuous deploy)
- `Jenkinsfile` — pipeline definition

## Local testing before pushing

From your dev VM, with IRIS connection env vars set:

```bash
export IRIS_HOST=<private-ip-of-iris-instance>
export IRIS_USER=<your-iris-user>
export IRIS_PASSWORD=<your-iris-password>
./build/load-routines.sh
```
