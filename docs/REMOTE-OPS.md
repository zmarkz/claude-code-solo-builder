# Remote operations

Run your desktop machine from a phone or laptop for days at a time, with one Claude
session per repo available on demand and no terminal to keep open by hand.

| Need | Use | Requires |
| :-- | :-- | :-- |
| Ask Claude to work in any repo | Remote Control fleet (below), from the Claude app or claude.ai/code | Nothing extra |
| See the screen, use the browser yourself, type a password | The OS screen-sharing tool over a private network such as Tailscale | One toggle at the machine |
| A shell when Claude itself is the problem | SSH over the same private network | One toggle at the machine |

## The fleet

`scripts/remote-fleet.sh` keeps a `claude remote-control` server running for each repo
you list. Starting a session from your phone then just means picking that repo.

```bash
cp settings/remote-fleet.conf.example ~/.claude/remote-fleet.conf   # then list your repos
./install.sh
bash ~/.claude/scripts/remote-fleet.sh install
bash ~/.claude/scripts/remote-fleet.sh status
```

Each config line is `repo <path> <name> <spawn>`. The name is for logs and `status`; the Claude app
labels the environment by its folder name.

- **`worktree`** gives each session its own git worktree, so parallel sessions cannot
  collide. Use it for active repos.
- **`same-dir`** shares the folder. Use it for folders that are not git repos, such as
  a portfolio root that sessions start from to create new projects.

A session in `worktree` mode starts from the default branch on the remote. For a repo
whose real work is on a long-lived branch, set `"worktree": {"baseRef": "head"}` in that
repo's `.claude/settings.local.json`.

Worktrees contain only tracked files. To carry local env files into them, copy
`starter-kit/reference/.worktreeinclude.template` to `.worktreeinclude` in the repo root.

### How it stays up

| Failure | What happens |
| :-- | :-- |
| Network outage over ~10 minutes | The server exits by design; the supervisor restarts it |
| A server crashes | The supervisor restarts it, backing off 60 seconds after a quick death |
| The Terminal window is closed | Servers keep running; the launchd watchdog reopens the supervisor within 5 minutes |
| Chrome or Tailscale is stopped | The watchdog restarts them if `FLEET_KEEP_CHROME` / `FLEET_KEEP_TAILSCALE` is on |
| A folder has not been trusted | Status shows `needs-trust`; it retries every 10 minutes and starts once you accept |

Servers run under Terminal rather than directly under launchd on purpose. macOS privacy
controls refuse launchd jobs access to `~/Documents`, `~/Desktop` and `~/Downloads` unless
they hold Full Disk Access, so a launchd-hosted server fails there with
`Operation not permitted`.

### Things only you can do

Run `claude` once in each repo showing `needs-trust` and accept the prompt. Remote Control
refuses a folder until a person has done this, and it is a check an agent should not
answer for you.

## Seeing the screen

Claude can use the browser's existing signed-in sessions through the Chrome extension, but
it does not type or autofill passwords. When a site asks for one, finish it yourself:

1. On the machine: System Settings → General → Sharing → turn on **Screen Sharing** and
   **Remote Login**.
2. Put every device on the same private network, for example Tailscale with one account.
3. From a Mac, open `vnc://<machine-name>` in Finder (Cmd-K). From a phone, use a VNC client
   over the same network, or Chrome Remote Desktop.

Browser password autofill then works as usual, because it is your session on your screen.
Prefer this to a custom remote-control app: it is encrypted, maintained by the OS vendor,
and adds nothing new for an attacker to find.

## Before you leave

| Risk | Check |
| :-- | :-- |
| Disk encryption | With FileVault on, a power cut stops the machine at the unlock screen and nothing outside can reach it. Use a UPS, or have someone nearby |
| Power cut recovery | `pmset -g \| grep autorestart`; set it to 1 if you want it to restart at all |
| Cloud sign-ins that expire | AWS SSO can be renewed from a phone: `aws sso login --sso-session <name> --use-device-code`, then open the printed link on the phone |
| Your Claude account | It now controls this machine. Use strong sign-in, and turn on Trusted Devices if your plan has it |

## Security model

`FLEET_PERMISSION_MODE` defaults to `default`, which asks before risky actions. Setting it to
`bypassPermissions` plus `FLEET_CHROME=1` means anyone who reaches your Claude account can run
any command on the machine and act in every site the browser is signed in to. Choose that
deliberately. To turn it off, change the config and run `remote-fleet.sh restart`; to remove
the whole thing, run `remote-fleet.sh uninstall`.
