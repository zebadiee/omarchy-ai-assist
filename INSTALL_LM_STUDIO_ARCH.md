# LM Studio Installation Guide for Arch Linux (Omarchy + RTX 2050)

## 🚀 Complete Setup Script

Save this as `install-lm-studio-arch.sh` and run it:

```bash
#!/bin/bash
# LM Studio + NVIDIA setup script for Arch Linux (Omarchy, HP Omen, RTX 2050)

# 1. Download latest LM Studio AppImage
cd ~/Downloads
LMSTUDIO_URL=$(curl -s https://api.github.com/repos/lmstudio-ai/lmstudio/releases/latest | grep "browser_download_url.*AppImage" | cut -d '"' -f 4)
wget "$LMSTUDIO_URL" -O LM_Studio-latest.AppImage

# 2. Make it executable
chmod +x LM_Studio-latest.AppImage

# 3. Install NVIDIA drivers, CUDA and cuDNN (if not already installed)
sudo pacman -Syu --needed nvidia nvidia-utils nvidia-settings cuda cudnn

# 4. Reboot is sometimes required for new driver activation (prompt user)
echo "If this is your first time installing NVIDIA drivers, please reboot after this script."

# 5. Run LM Studio
echo "Launching LM Studio..."
./LM_Studio-latest.AppImage

# 6. Print CUDA device info for verification
echo "Your NVIDIA GPU info:"
nvidia-smi
```

## 🔧 Usage Instructions

### **Step 1: Installation**
```bash
chmod +x install-lm-studio-arch.sh
./install-lm-studio-arch.sh
```

### **Step 2: Configure LM Studio for Omarchy AI Team**

Once LM Studio launches, set up the Local Knowledge:

1. **Open LM Studio Settings**
2. **Navigate to "Local Knowledge"**
3. **Add Knowledge Folder**: `/home/zebadiee/Documents/omarchy-ai-assist/knowledge-outbox/`
4. **Enable "Monitor Folder"** (if available)

### **Step 3: Complete Manual Workflow**

```bash
# Export AI team knowledge
node /home/zebadiee/Documents/omarchy-ai-assist/lm-studio-integration.js export --session=daily

# LM Studio will automatically detect new files
# Run analysis in LM Studio desktop app
# Save results to knowledge-outbox/lm-studio-notes/

# Import LM Studio insights back to AI team
node /home/zebadiee/Documents/omarchy-ai-assist/lm-studio-integration.js import
```

## 🎯 Hardware Verification

### **Check NVIDIA GPU Support:**
```bash
nvidia-smi
# Should show your RTX 2050 with CUDA capabilities

# Verify CUDA installation
nvcc --version
# Should show CUDA compiler version

# Check cuDNN
cat /usr/include/cudnn_version.h | grep CUDNN_MAJOR -A 2
# Should show cuDNN version information
```

### **Expected Output for RTX 2050:**
```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 550.78                 Driver Version: 550.78       CUDA Version: 12.4     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ...  On   | 00000000:01:00.0 Off |                  N/A |
| 30%   35C    P8    15W /  90W |    446MiB /  4096MiB |      0%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
```

## 🔄 Integration with Omarchy AI Team

### **Perfect Hardware Match:**
- **RTX 2050**: Excellent for local LLM inference
- **CUDA Support**: Full GPU acceleration for LM Studio
- **4GB VRAM**: Sufficient for models up to 7B parameters
- **Arch Linux**: Native support with NVIDIA proprietary drivers

### **Performance Expectations:**
- **Small Models (1-3B)**: Excellent performance, real-time responses
- **Medium Models (4-7B)**: Good performance with quantization
- **Large Models (8B+)**: Possible with optimized quantization

### **Recommended Models for RTX 2050:**
- **Llama 3.2 3B**: Fast, efficient, good for analysis
- **Mistral 7B**: Balanced performance, good for reasoning
- **Phi-3 Mini**: Excellent for code analysis and technical content
- **Qwen 2.5 3B**: Great for structured data analysis

## 🎛️ LM Studio Configuration for AI Team Analysis

### **Optimal Settings:**
```
GPU Layers: Use maximum available (usually 30-35 for RTX 2050)
Context Length: 4096 tokens (good for analyzing AI team sessions)
Temperature: 0.7 (balanced creativity and accuracy)
Top P: 0.9 (good for diverse insights)
```

### **Memory Management:**
- **GPU Offload**: Enable for faster inference
- **CPU Offload**: Use remaining VRAM efficiently
- **System RAM**: Ensure sufficient for larger models

## 📊 Workflow Automation (Future CLI)

When LM Studio CLI becomes available, the current manual commands will seamlessly transition:

### **Current (Manual):**
```bash
node lm-studio-integration.js export
# → Use LM Studio desktop app
# → Manual analysis and insight generation
node lm-studio-integration.js import
```

### **Future (CLI Automation):**
```bash
# Same export command - no changes needed!
node lm-studio-integration.js export

# Future CLI automation (when available):
lmstudio-cli chat "analyze AI team patterns" --input ./knowledge-outbox/ --output ./knowledge-outbox/lm-studio-notes/

# Same import command - no changes needed!
node lm-studio-integration.js import
```

## 🔧 Troubleshooting

### **Common Issues:**

**NVIDIA Driver Issues:**
```bash
# Reinstall NVIDIA drivers
sudo pacman -Syu nvidia nvidia-utils

# Rebuild for current kernel
sudo pacman -S linux-headers
sudo dkms autoinstall
```

**CUDA Not Detected:**
```bash
# Check CUDA installation
ls /usr/local/cuda/
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

**LM Studio Won't Start:**
```bash
# Check AppImage dependencies
ldd LM_Studio-latest.AppImage

# Run with debugging
./LM_Studio-latest.AppImage --appimage-extract
./squashfs-root/AppRun
```

**Poor Performance:**
```bash
# Check GPU utilization
nvidia-smi -l 1

# Monitor system resources
htop
```

## 🎯 Success Verification

### **Installation Success:**
- ✅ LM Studio launches without errors
- ✅ NVIDIA GPU detected in LM Studio
- ✅ CUDA available for GPU acceleration
- ✅ Can load and run small models

### **Integration Success:**
- ✅ Knowledge export creates files in `knowledge-outbox/`
- ✅ LM Studio detects and indexes exported files
- ✅ Analysis generates meaningful insights
- ✅ Import successfully integrates insights with AI team

### **Performance Success:**
- ✅ GPU utilization during inference
- ✅ Reasonable response times (<10 seconds)
- ✅ Stable operation without crashes
- ✅ Memory usage within GPU limits

---

## 🚀 Ready to Go!

With this setup, you have:

1. **✅ LM Studio running with GPU acceleration**
2. **✅ Complete manual workflow for AI team knowledge enhancement**
3. **✅ Seamless path to future CLI automation**
4. **✅ Hardware optimized for your RTX 2050**
5. **✅ Integration ready for Omarchy AI team collaboration**

**Your AI team now has both real-time capabilities AND deep analytical insights from LM Studio!** 🎉