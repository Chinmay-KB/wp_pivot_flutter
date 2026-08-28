# Contribution

If you want to work on an existing issue, then do comment on the issue and I will assign the issue. If you seek to implement something that is not present in the issues, open a new issue and I will assign you to it.

### Installation
You can view the dart package published [here](https://pub.dev/packages/wp_pivot_flutter).

Use the version shown in the package's [installation instructions](https://pub.dev/packages/wp_pivot_flutter/install).
The repository may contain a newer version that has not yet been published.
Import the package with:

```dart
import 'package:wp_pivot_flutter/wp_pivot_flutter.dart';
```

### Local development and release checks

The library requires Flutter 3.22 / Dart 3.4 or later. Repository development uses
`flutter_lints` 6, which requires Dart 3.8 or later; use a Flutter SDK that includes it.

```sh
flutter pub get
flutter analyze
flutter test --reporter expanded
cd example
flutter pub get
flutter build web --release
```

From the repository root, `./tool/publish_with_pub_readme.sh` validates the package
with the package-facing README and restores the GitHub README afterwards. It is a
dry run unless explicitly passed `--publish`. Update `pubspec.yaml`, `CHANGELOG.md`
and the example's path-dependency lock entry together. `.pubignore` keeps research
and capture artifacts out of the archive; preserve their published provenance.

### Git workflow

```
## Step 1: Fork Repository

## Step 2: Git Set Up & Download
# Clone the repo
$ git clone https://github.com/<User-Name>/<Repo-Name>.git
# Add upstream remote
$ git remote add upstream https://github.com/Chinmay-KB/wp_pivot_flutter.git
# Fetch and merge with upstream/master
$ git fetch upstream
$ git merge upstream/master

## Step 2: Create and Publish Working Branch
$ git checkout -b <type>/<issue|issue-number>/{<additional-fixes>}
$ git push origin <type>/<issue|issue-number>/{<additional-fixes>}

## Types:
# wip - Work in Progress; long term work; mainstream changes;
# feat - New Feature; future planned; non-mainstream changes;
# bug - Bug Fixes
# exp - Experimental; random experiemntal features;
```
### On Task Completion

```
## Committing and pushing your work
# Ensure branch
$ git branch
# Fetch and merge with upstream/master
$ git fetch upstream
$ git merge upstream/master
# Add untracked files
$ git add .
# Commit all changes with appropriate commit message and description
$ git commit -m "your-commit-message" -m "your-commit-description"
# Fetch and merge with upstream/master again
$ git fetch upstream
$ git merge upstream/master
# Push changes to your forked repository
$ git push origin <type>/<issue|issue-number>/{<additional-fixes>}

## Creating the PR using GitHub Website
# Create Pull Request from <type>/<issue|issue-number>/{<additional-fixes>} branch in your forked repository to the master branch in the upstream repository
# After creating PR, add a Reviewer (Any Admin) and yourself as the assignee
# Link Pull Request to appropriate Issue, or Project+Milestone (if no issue created)
# IMPORTANT: Do Not Merge the PR unless specifically asked to by an admin.
```
### After Pull Request is Merged
```
# Delete branch from forked repo
$ git branch -d <type>/<issue|issue-number>/{<additional-fixes>}
$ git push --delete origin <type>/<issue|issue-number>/{<additional-fixes>}
# Fetch and merge with upstream/master
$ git checkout master
$ git pull upstream
$ git push origin
```
### Note
- Always follow [commit message standards](https://chris.beams.io/posts/git-commit/)
- About the [fork-and-branch workflow](https://blog.scottlowe.org/2015/01/27/using-fork-branch-git-workflow/)

