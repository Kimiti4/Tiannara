# 🚀 Tiannara WSL2 Development Workflow

This guide outlines the optimal way to develop the Tiannara project using WSL2. To achieve maximum performance and avoid file-locking issues, **all build and execution processes must happen on the Linux filesystem**, while editing can still be done in Windows.

## 🛠️ Quick Start Guide

### 1. Initial Setup (One-time)
Open a PowerShell window and enter WSL:
```powershell
wsl
```

Once inside the Linux terminal, copy the project from Windows to the Linux home directory:
```bash
mkdir -p ~/projects
cp -r /mnt/c/Users/user/Tiannara/Tiannara-MindCache-Prosthetic ~/projects/tiannara
cd ~/projects/tiannara
```

### 2. Run the Automated Setup
Run the provided setup script to configure the environment and compile the project:
```bash
chmod +x scripts/wsl2_setup.sh
./scripts/wsl2_setup.sh
```

### 3. Run Phase 5 Campaign
Once compiled, launch the Evolution Alpha 2 campaign:
```bash
mix run scripts/evolution_alpha_2.exs
```

---

## 🔄 Daily Workflow

### Option A: The "Pure Linux" Approach (Recommended)
1. Open VS Code.
2. Install the **WSL extension**.
3. Click the green button in the bottom-left corner $\rightarrow$ **Connect to WSL**.
4. Open the folder `~/projects/tiannara`.
5. Use the integrated terminal for all `mix` commands.

### Option B: The "Hybrid" Approach
1. Edit files in Windows VS Code (using the `C:\Users\user\...` path).
2. Run commands in a separate WSL terminal (using the `~/projects/tiannara` path).
3. **Note**: You must sync changes from Windows to Linux if you aren't using the WSL extension.
   ```bash
   # Sync from Windows to Linux (run inside WSL)
   rsync -av --exclude '_build' /mnt/c/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/ ~/projects/tiannara/
   ```

---

## ⚡ Performance Tips

| Action | Windows Path (`/mnt/c/...`) | Linux Path (`~/...`) | Why? |
| :--- | :---: | :---: | :--- |
| **`mix compile`** | 🐌 Slow | 🚀 Fast | Linux native I/O is significantly faster for many small files. |
| **`mix test`** | 🐌 Slow | 🚀 Fast | Reduced overhead for test artifact creation. |
| **File Editing** | ✅ Great | ✅ Great | VS Code handles both seamlessly. |
| **Git Operations** | ⚠️ Mixed | ✅ Great | Git is much faster on native Linux filesystems. |

---

## 📂 Accessing Files

- **From Windows to Linux**: Open File Explorer and type `\\wsl$\Ubuntu\home\yourusername\projects\tiannara` in the address bar.
- **From Linux to Windows**: Your Windows C: drive is available at `/mnt/c/`.

---

## 📊 Phase 5 Testing Checklist

When running the Phase 5 campaign, verify the following exit criteria in the final summary:

- [ ] **Repair Success Rate**: $> 20\%$
- [ ] **Knowledge Reuse Rate**: $> 10\%$
- [ ] **Transfer Success Rate**: $> 5\%$
- [ ] **Adaptation Velocity**: $> 0$ (Positive trend)

If any of these fail, analyze the `runs/` directory for the specific generation that caused the regression.