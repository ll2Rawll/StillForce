# Stillforce

Stillforce is a standalone Windows x64 client for GeForce NOW, built on OpenNOW 1.0.5. Its desktop menus pair StillCord's black satin artwork with silver controls, a floating glass sidebar and a sculpted sign-in screen.

## Run on Windows

1. Extract the entire Windows ZIP into a folder of your choice.
2. Open `bin\Stillforce.exe`. Keep the folders beside `bin` in place so Qt can find its plugins.
3. Sign in through NVIDIA or your GeForce NOW alliance provider, then open your library or search for a game.

If Windows requests the Microsoft Visual C++ runtime, run the bundled `bin\vc_redist.x64.exe`. You can use Stillforce alongside OpenNOW. Windows settings live under `%APPDATA%\Stillforce`; screenshots and recordings live under `Pictures\Stillforce`. Automatic usage and error reports are off until you opt in. If you enable them, reports go to the OpenNOW developers. To update this portable build, close Stillforce and extract a newer Stillforce release into a fresh folder.

## Inside the app

- Browse games, manage favorites and collections, and switch to the controller layout.
- Change the background and accent in Settings. The menu respects Windows animation preferences and the in-app reduced-motion setting.
- Use **F3** during play for packet loss, jitter, network latency and frame statistics. **Ctrl+G** opens the stream menu. When the server reports it, the overlay also shows your assigned rig. Ultimate gives you priority for an RTX 5080. If your nearest region is full, NVIDIA can assign a 4080 there. [NVIDIA’s rig allocation guide](https://nvidia.custhelp.com/app/answers/detail/a_id/5702)
- Game video uses OpenNOW's native Rust streaming engine. The interface uses Qt Quick, and the Rust core handles settings, authentication, catalog and session requests.

## Build from source

Use a Visual Studio 2022 x64 developer shell with CMake, Rust (MSVC), SDL3 and Qt 6.8 or newer. Install the Qt Quick, Multimedia, Shader Tools and SVG modules and make Qt and SDL3 discoverable through `CMAKE_PREFIX_PATH`.

```powershell
cmake -S opennow-qt -B build/qt -G "Visual Studio 17 2022" -A x64
cmake --build build/qt --config Release --target opennow-qt
cmake --install build/qt --config Release --prefix dist/Stillforce
```

The installed executable is `dist/Stillforce/bin/Stillforce.exe`. Build every target before running the complete native test suite. The Qt acceptance guide covers menu, motion and streaming checks. [Acceptance guide](docs/qt-acceptance.md)

## Credits

The source includes OpenNOW's client and Rust streaming implementation under the MIT license. This fork starts from release `v1.0.5`, commit `a9de957a5902c54186e9d4b44b1562f0b6beb951`. The Windows ZIP combines the rebuilt Stillforce shell and account core with the matching upstream stream runtime and its dependencies. [OpenNOW](https://github.com/OpenCloudGaming/OpenNOW/tree/a9de957a5902c54186e9d4b44b1562f0b6beb951) · [Original documentation](README.upstream.md) · [MIT license](LICENSE) · [Third-party notices](THIRD_PARTY_NOTICES)

The satin artwork comes from ll2Rawll's StillCord. The Stillforce mark and ribbon were made for this fork. NVIDIA and GeForce NOW are trademarks of NVIDIA Corporation. [StillCord](https://github.com/ll2Rawll/StillCord) · [Artwork license](opennow-qt/res/brand/StillCord-LICENSE.txt)
