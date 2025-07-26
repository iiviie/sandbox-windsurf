# Windsurf in Docker 🚀

## What is this?

This project lets you run **Windsurf** (Codeium's AI-powered code editor) inside a Docker container with full GUI support. Think of it as having Windsurf running in its own isolated environment that won't mess with your main system, but still works just like if you installed it normally.

**Why would you want this?**
- Keep your main system clean (no need to install Windsurf directly)
- Easy to remove completely when you're done
- Works consistently across different Linux systems
- Includes Firefox for web browsing within the container
- Your projects and settings are safely stored in Docker volumes

## What you need before starting

- **Docker** installed on your Linux system
- **Make** utility (usually pre-installed)
- A working display server (X11 or Wayland - the script auto-detects this)

## First time setup 🎯

**Step 1:** Clone or download this project to your computer

**Step 2:** Open a terminal and navigate to the project folder

**Step 3:** Run this command:
```bash
make
```

That's it! The first time will take a while (maybe 10-15 minutes) because it needs to:
- Download the Ubuntu base image
- Install all the necessary software
- Set up Windsurf and Firefox
- Create storage volumes for your data

Once it's done, Windsurf will open in a new window, ready to use!

## Running it after the first time ⚡

After the initial setup, starting Windsurf is much faster:

```bash
make run
```

Or if you prefer the direct approach:
```bash
./run-windsurf.sh
```

This usually takes just a few seconds since everything is already set up.

## Your files and where they live 📁

Don't worry - your work is safe! The container automatically connects to:
- **Your home folder**: Available as `/home/windsurfuser/host-home`
- **Your projects**: The `~/cursor-projects` folder is mounted and accessible
- **Settings & extensions**: Stored in Docker volumes that persist between runs

## When things get full - Cleaning up Docker 🧹

Docker can use quite a bit of disk space over time. Here are your cleanup options:

### Just want to free up some space?
```bash
make clean-image
```
This removes the Windsurf Docker image. Next time you run `make`, it will rebuild it fresh.

### Want to reset everything to factory settings?
```bash
make clean-volume
```
This removes all your Windsurf settings, extensions, and Firefox data. **Warning**: You'll lose any customizations!

### Nuclear option - remove everything:
```bash
make clean-all
```
This removes both the image AND all your data. It's like you never installed it.

### Check what's using space:
```bash
make status
```
This shows you what Docker images and volumes exist for this project.

## Troubleshooting 🔧

**Windsurf window doesn't appear?**
- Make sure you're running this on a Linux desktop (not over SSH)
- The script should auto-detect X11 or Wayland, but if it fails, check that `$DISPLAY` or `$WAYLAND_DISPLAY` is set

**"Permission denied" errors?**
```bash
make prepare
```
This makes sure all scripts have the right permissions.

**Want to force a fresh rebuild?**
```bash
make rebuild
```
This deletes the current image and builds a new one from scratch.

**Container won't start?**
Check if Docker is running:
```bash
sudo systemctl status docker
```

## Available commands summary 📋

| Command | What it does |
|---------|-------------|
| `make` | First-time setup and run |
| `make run` | Start Windsurf (after first setup) |
| `make status` | Show what Docker resources exist |
| `make clean-image` | Remove Docker image (keeps your data) |
| `make clean-volume` | Remove your data/settings (keeps image) |
| `make clean-all` | Remove everything |
| `make rebuild` | Force rebuild the Docker image |
| `make help` | Show all available commands |

## Need help? 🤝

If something isn't working:
1. Try `make status` to see what's there
2. Try `make clean-all` followed by `make` for a fresh start
3. Check that Docker is running and you have enough disk space
4. Make sure you're running on a Linux desktop environment

Enjoy coding with Windsurf! 🎉