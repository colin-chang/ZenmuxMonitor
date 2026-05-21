# ZenmuxMonitor

## Release Process

1. Commit all changes to `main`.
2. Tag and push — CI handles everything else:
   ```
   git commit -m "Release vX.Y.Z: <summary>"
   git tag -a vX.Y.Z -m "vX.Y.Z: <summary>"
   git push origin main && git push origin vX.Y.Z
   ```

The `release.yml` workflow automatically:
- Syncs `CFBundleShortVersionString` and `CFBundleVersion` in Info.plist from the tag
- Builds the Release configuration
- Creates and uploads the DMG
- Publishes the GitHub release with commit log notes

No manual Info.plist editing needed.
