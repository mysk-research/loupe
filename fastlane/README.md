fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload App Store text metadata (name, subtitle, keywords, promo text, description) to App Store Connect.

### ios release_notes

```sh
[bundle exec] fastlane ios release_notes
```

Upload only the What's New (release notes) for the current version to App Store Connect.

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture localized App Store screenshots on the simulator (reads fastlane/Snapfile).

### ios screenshots_upload

```sh
[bundle exec] fastlane ios screenshots_upload
```

Upload the captured screenshots in fastlane/screenshots to App Store Connect.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
