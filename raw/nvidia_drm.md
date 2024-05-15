nvidia_drm 是 NVIDIA 的 DRM (Direct Rendering Manager) 内核模块的名称。DRM 是 Linux 内核的一部分，用于支持图形硬件的直接渲染。

NVIDIA 的 DRM 模块（nvidia_drm）是 NVIDIA 显卡驱动的一部分，它允许用户空间的应用程序直接访问显卡的硬件资源，例如显存和渲染引擎；还允许显卡直接管理和控制图形硬件的渲染。
此模块被用于支持如 OpenGL 和 Vulkan 等图形 API 的硬件加速。

如果你在使用如 VFIO 这样的虚拟化技术，并且想要将你的 NVIDIA 显卡传递给一个虚拟机，你可能需要先卸载 `nvidia_drm` 模块。你可以使用如下命令来卸载它：

```shellscript
sudo rmmod nvidia_drm
```

请注意，卸载 `nvidia_drm` 模块可能会影响到正在使用显卡的应用程序，例如正在运行的图形界面。在卸载这个模块之前，你可能需要先关闭这些应用程序。
