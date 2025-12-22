# SSH ControlMaster Setup Guide

This guide shows you how to configure SSH ControlMaster to avoid entering your password multiple times when using the FreeSurfer download/upload scripts or any other SSH operations to your remote server.

## What is ControlMaster?

SSH ControlMaster allows you to reuse a single SSH connection for multiple sessions. Instead of authenticating separately for each `ssh` or `rsync` command, you authenticate once and all subsequent connections share that authenticated session.

**Benefits:**
- ✅ Enter password/2FA only once per session
- ✅ Dramatically faster connection times
- ✅ Works transparently with `ssh`, `rsync`, `scp`, and `sftp`
- ✅ Automatic cleanup after idle timeout

## Setup Instructions

### 1. Create SSH Sockets Directory

First, create a directory to store the control sockets:

```bash
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets
```

### 2. Configure SSH Config File

Edit your SSH config file:

```bash
nano ~/.ssh/config
# or
vim ~/.ssh/config
```

Add the following configuration for your remote server:

```ssh
Host login.sherlock.stanford.edu
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 10m
```

**Explanation of each line:**
- `Host login.sherlock.stanford.edu` - Replace with your actual server hostname
- `ControlMaster auto` - Automatically create master connection if none exists
- `ControlPath ~/.ssh/sockets/%r@%h-%p` - Where to store the socket file
  - `%r` = remote username
  - `%h` = remote hostname
  - `%p` = remote port
- `ControlPersist 10m` - Keep connection alive for 10 minutes after last use

### 3. Set Correct Permissions

Ensure your SSH config has the correct permissions:

```bash
chmod 600 ~/.ssh/config
```

## Usage

### Normal Workflow

Now when you use the FreeSurfer scripts (or any SSH/rsync commands):

1. **First command:** You'll be prompted for password/2FA
2. **All subsequent commands (within 10 minutes):** No password needed!

Example:

```bash
# First command - asks for password
./toolbox/download_freesurfer.sh --server login.sherlock.stanford.edu \
  --user mysunetid --remote-dir /path/to/study --subjects sub-001,sub-002,sub-003

# Downloads sub-001 - password prompt
# Downloads sub-002 - no password (reuses connection)
# Downloads sub-003 - no password (reuses connection)
```

### Manual Control

You can manually control the master connection:

**Check connection status:**
```bash
ssh -O check login.sherlock.stanford.edu
```

**Stop the master connection:**
```bash
ssh -O stop login.sherlock.stanford.edu
```

**Start a new master connection without running a command:**
```bash
ssh -Nf login.sherlock.stanford.edu
```
- `-N` = Don't execute a remote command
- `-f` = Go to background

## Verification

### Test That It's Working

1. Connect to your server:
   ```bash
   ssh mysunetid@login.sherlock.stanford.edu
   ```
   Enter your password/2FA when prompted.

2. Open a **new terminal window** and check the socket:
   ```bash
   ls -la ~/.ssh/sockets/
   ```
   You should see a socket file like: `mysunetid@login.sherlock.stanford.edu-22`

3. In the new terminal, connect again:
   ```bash
   ssh mysunetid@login.sherlock.stanford.edu
   ```
   **You should NOT be prompted for a password!** It should connect instantly.

4. Check connection status:
   ```bash
   ssh -O check login.sherlock.stanford.edu
   ```
   Output: `Master running (pid=12345)`

## Advanced Configuration

### Multiple Servers

You can configure ControlMaster for multiple servers:

```ssh
Host login.sherlock.stanford.edu
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 10m

Host login.farmshare.stanford.edu
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 10m
```

### Wildcard Configuration

Apply ControlMaster to all servers (less secure, but convenient):

```ssh
Host *
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 10m
```

### Longer Persistence

Increase the timeout for longer work sessions:

```ssh
Host login.sherlock.stanford.edu
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 1h  # Keeps connection alive for 1 hour
```

Time units: `s` (seconds), `m` (minutes), `h` (hours), `d` (days)

## Troubleshooting

### "ControlPath too long" Error

If you get this error, use a shorter socket path:

```ssh
Host login.sherlock.stanford.edu
  ControlMaster auto
  ControlPath ~/.ssh/cm-%C
  ControlPersist 10m
```

`%C` creates a hash of `%l%h%p%r` (shorter but unique).

### Stale Socket Files

If you get "Control socket connect: Connection refused":

```bash
# Remove stale sockets
rm ~/.ssh/sockets/*

# Or remove specific socket
rm ~/.ssh/sockets/mysunetid@login.sherlock.stanford.edu-22
```

### Permission Denied

Ensure correct permissions:

```bash
chmod 700 ~/.ssh
chmod 700 ~/.ssh/sockets
chmod 600 ~/.ssh/config
```

### Connection Hangs

If a master connection becomes unresponsive:

```bash
# Force kill the master
ssh -O exit login.sherlock.stanford.edu

# Or manually kill the socket
rm ~/.ssh/sockets/mysunetid@login.sherlock.stanford.edu-22
```

## Security Considerations

### Pros
- ✅ Reduces password entry frequency (less shoulder surfing risk)
- ✅ Only you can access socket files (mode 700 directory)
- ✅ Automatic timeout prevents indefinite access
- ✅ Master connection terminates when you log out

### Cons
- ⚠️ Anyone with access to your account can use active sockets
- ⚠️ Longer `ControlPersist` = longer window of reuse

### Best Practices

1. **Use appropriate timeout values:**
   - Short sessions: 10m (default)
   - Long sessions: 1h
   - Avoid: Very long timeouts (>4h)

2. **Lock your computer** when stepping away

3. **Manual cleanup** when done with sensitive work:
   ```bash
   ssh -O exit login.sherlock.stanford.edu
   ```

4. **Don't use wildcards** for production/sensitive servers

## Integration with FreeSurfer Scripts

The `download_freesurfer.sh` and `upload_freesurfer.sh` scripts work seamlessly with ControlMaster:

**Without ControlMaster (3 subjects):**
- Password prompt × 1 (directory check)
- Password prompt × 3 (each subject)
- **Total: 4 password prompts**

**With ControlMaster (3 subjects):**
- Password prompt × 1 (first connection)
- Remaining connections reuse socket
- **Total: 1 password prompt** ✨

### Example Session

```bash
# Setup (one-time)
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets

# Configure ~/.ssh/config (see above)

# Use scripts normally - first command asks for password
./toolbox/download_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user shawnsch \
  --remote-dir /oak/stanford/groups/awagner/yaams-haams/derivatives/fmriprep-24.0.1/sourcedata \
  --subjects sub-001,sub-002,sub-003

# Later commands within 10 minutes use same connection (no password!)
./toolbox/upload_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user shawnsch \
  --remote-dir /oak/stanford/groups/awagner/yaams-haams/derivatives/fmriprep-24.0.1/sourcedata \
  --subjects sub-001
```

## References

- [OpenSSH ControlMaster Documentation](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing)
- [SSH Config Man Page](https://man.openbsd.org/ssh_config)
- Stanford Research Computing SSH Documentation (if available)

---

**Questions or issues?** Check the troubleshooting section above or contact your system administrator.
