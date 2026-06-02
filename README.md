# 🖼️ DSM Auto Change Wallpaper

<p align="center">
  <img src="https://img.shields.io/badge/DSM-7.2.x%2B-0066CC?style=flat-square&logo=synology&logoColor=white" alt="DSM Version"/>
  <img src="https://img.shields.io/badge/Shell-Script-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="Shell"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/Status-%E2%9C%85%20Stable-brightgreen?style=flat-square" alt="Status"/>
</p>

---

## 📋 项目简介

> **DSM Auto Change Wallpaper** 是一款专为 **群晖 DSM 7.2.x 及以上系统** 设计的壁纸自动更换脚本。  
> 让您的 NAS 桌面和登录界面每天都焕然一新！

---

## ✨ 功能特性

| 特性 | 说明 |
|:-----|:------|
| 🖼️ **双图源支持** | 支持 **本地图片** 或 **必应每日一图** 作为壁纸来源 |
| 👤 **分开配置** | **用户桌面壁纸** 与 **群晖登录壁纸** 可独立设置，互不干扰 |
| 💾 **自动收藏** | 自动收集并保存必应每日一图到指定路径，打造您的专属壁纸库 |
| 📝 **运行反馈** | 执行后打印详细结果，清晰显示图片名称及保存路径 |

---

## 🚀 快速开始

### 1️⃣ 下载脚本

```bash
wget https://raw.githubusercontent.com/your-repo/DSM_AutoChangeWallpaper/main/AutoChangeWallpaper.sh
```

### 2️⃣ 赋予执行权限

```bash
chmod +x AutoChangeWallpaper.sh
```

### 3️⃣ 配置并运行

编辑脚本中的配置参数（图源、壁纸路径等），然后执行：

```bash
./AutoChangeWallpaper.sh
```

> 💡 **建议**：通过群晖 **任务计划程序** 设置定时任务，实现每日自动更换壁纸。

---

## 📦 文件结构

```
DSM_AutoChangeWallpaper/
├── AutoChangeWallpaper.sh   # 主脚本文件
└── README.md                # 本说明文档
```

---

## 📜 更新日志

### 🔖 V1.2

<details open>
<summary><strong>点击展开</strong></summary>

#### ✨ 新增
- **运行结果打印** — 执行后输出图片名称及保存路径，一目了然

#### 🔧 优化
- 重构脚本命令结构，添加详细注释，**可读性大幅提升**

</details>

### 🔖 V1.1

<details>
<summary><strong>点击展开</strong></summary>

#### ✨ 新增
- 支持 **DSM 7.2.x** 版本壁纸替换

</details>

### 🔖 V1.0

<details>
<summary><strong>点击展开</strong></summary>

#### ✨ 新增
- 使用本地图片更新 **用户桌面壁纸**
- 使用本地图片作为 **登录壁纸**

#### 🔧 优化
- 关键参数使用变量管理，**配置更灵活**
- 优化参数命名，**语义更清晰**
- 完善部分脚本代码，**稳定性提升**

</details>

---

## 🤝 贡献

欢迎提交 Issue 或 Pull Request 来帮助改进本项目！

---

<p align="center">
  Made with ❤️ for Synology NAS Users
</p>  
