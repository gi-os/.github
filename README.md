# gi-os/.github

Account-wide defaults for [gi-os](https://github.com/gi-os), and the shared **iOS kit**: reusable
workflows, CI scripts, fastlane lanes, an app template, and Claude Code skills for every gi-os iOS
app. See [ios/README.md](ios/README.md).

## Working from the phone on the Mac mini

`mac/setup.sh` turns a Mac into the place Claude does the work while you drive it from the Claude
app (Remote Control): Xcode tools, every app on the kit cloned into `~/Developer/gi-os` with the
house rules and skills, and with `--always-on` a never-sleeping Mac running `claude remote-control`
as a login service, so the phone can start a session any time.

```sh
gh repo clone gi-os/.github ~/Developer/gi-os/.github
bash ~/Developer/gi-os/.github/mac/setup.sh
cd ~/Developer/gi-os && claude remote-control --name "Mac mini"   # once: answer y, then Ctrl-C
bash ~/Developer/gi-os/.github/mac/setup.sh --always-on
```
