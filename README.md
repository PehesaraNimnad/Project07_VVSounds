# Project07 Vanilla Vehicle Sounds

A lightweight, high-performance FiveM resource that dynamically replaces vehicle engine sounds with custom audio files. Built with advanced network synchronization and intelligent vehicle detection for a seamless multiplayer experience.

## 🎯 Features

- **🔄 Network Synchronized** - Engine sounds synced across all clients using FiveM's StateBag system
- **🚗 Smart Vehicle Detection** - Automatically detects and applies sounds to newly spawned vehicles
- **🏎️ Garage/PDM Compatible** - Handles vehicles that take time to become networked
- **⚙️ Easy Configuration** - Simple Lua table-based model-to-sound mapping
- **🔄 Auto-Retry Logic** - Retries up to 5 seconds for vehicles that load slowly
- **🧹 Memory Efficient** - Automatic cleanup of destroyed vehicles every 30 seconds
- **🐛 Debug Mode** - Optional console logging for troubleshooting
- **⚡ Low Resource Usage** - Minimal performance impact with non-blocking threads

## 📋 Requirements

- FiveM Server
- Lua 5.4+ support
- `set sv_stateBagStrictMode false` in server.cfg (REQUIRED)
- Custom engine sound files in your resources

## 📥 Installation

1. **Download & Place**
   - Download the resource
   - Place it in your FiveM resources folder (e.g., `resources/Project07_VVehicleSounds`)

2. **Configure Server**
   - Open your `server.cfg`
   - Add these lines:
   ```cfg
   ensure Project07_VVehicleSounds
   set sv_stateBagStrictMode false
   ```

3. **Start the Resource**
   - Restart your server, or
   - Use console command: `start Project07_VVehicleSounds`

## ⚙️ Configuration

Edit `config.lua` to map vehicle models to engine sounds:

```lua
Config = {}

-- Map vehicle models to engine sound files
Config.EngineSounds = {
    ['sultan']   = 'lg87skodar5rally',    -- Vehicle model = Audio file
    ['zr390']    = 'nisgtr35',
    ['bf400']    = '2strkbeng',
    -- Add more vehicles below
}

-- Network timeout for operations (milliseconds)
Config.NetworkWaitTimeout = 5000

-- Enable debug logging in console
Config.Debug = false
```

### Configuration Guide

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `EngineSounds` | Table | - | Map of vehicle models to audio file names |
| `NetworkWaitTimeout` | Integer | 5000 | Maximum time to wait for network operations (ms) |
| `Debug` | Boolean | false | Enable debug console output |

## 🔧 How It Works

### 1. **Entity Detection**
- Monitors for new vehicle entities spawning
- Applies sounds when vehicles are created

### 2. **Network Synchronization**
- Uses FiveM's StateBag system to sync sounds across all clients
- Ensures all players hear the same engine sounds

### 3. **Retry Logic**
- Retries for up to 5 seconds for vehicles that take time to become networked
- Handles garage/PDM/dealership vehicles that spawn slowly

### 4. **Periodic Scanning**
- Scans for newly spawned vehicles every 2 seconds
- Catches vehicles that may have been missed by entity events

### 5. **Memory Cleanup**
- Automatically removes destroyed vehicle entries every 30 seconds
- Prevents memory leaks from long-running servers

## 🐛 Debugging

Enable debug mode in `config.lua`:

```lua
Config.Debug = true
```

Then check server console for output like:
```
[Project07_VehicleSounds] Applied sultan -> lg87skodar5rally
[Project07_VehicleSounds] Synced sound: nisgtr35
```

## ⚡ Performance Tips

- **Minimal Impact**: Uses efficient non-blocking threads
- **Selective Mapping**: Only configure vehicles you need
- **No Impact on Unmapped Vehicles**: Vehicles without sound mappings are ignored
- **Automatic Cleanup**: Memory is reclaimed when vehicles are destroyed


## 🎮 Vehicle Sound Mapping

To add custom sounds:

1. Place your audio files in a resource folder
2. Add the mapping to `Config.EngineSounds` in `config.lua`:
   ```lua
   ['vehiclemodelname'] = 'youraudiofilename',
   ```
3. Restart the resource or server

## 🆘 Troubleshooting

### Sounds Not Applying
- Ensure `set sv_stateBagStrictMode false` is in server.cfg
- Check vehicle model names are correct (use `Config.Debug = true`)
- Verify audio files exist and are properly registered

### Console Errors
- Enable debug mode to see detailed logs
- Check that audio files are valid
- Ensure vehicle models exist in GTA V

### Memory Issues
- Resource automatically cleans up every 30 seconds
- If issues persist, restart the resource

## 💬 Support & Issues

- **Found a Bug?** Open a ticket on our [Discord](https://discord.gg/h7wcTFnt4q)
- **Have Suggestions?** Let us know on Discord!
- **Need Help?** Check the debug output first

## 👤 Author

**Pehesara**

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for full details.


## 📦 Version

**v0.1.0** - Initial Release
