<img width="100" height="100" src="https://github.com/user-attachments/assets/1c42dda2-b778-4342-9f94-8f852c3ad652" />

# Reynard Browser

Reynard is a **Gecko-based** web browser for iOS 12+.

Unlike other browsers on iOS that are forced to use Apple's **WebKit** engine (including Safari and all third-party browsers), Reynard uses **Gecko**. This is the same engine that powers the Firefox browser on desktop and Android devices.

This project is mainly for users on older iOS versions who are stuck with an outdated version of WebKit. Because WebKit is bundled with the OS, these devices cannot receive engine updates and often fail to load modern websites. By using Gecko, which is kept up to date independently, Reynard allows these sites to work again. Users on newer iOS versions can also use the browser if they want an alternative to WebKit, including Firefox add-ons and other Gecko-exclusive features.

## Installation

The latest builds are available for download on the [Releases](https://github.com/minh-ton/reynard-browser/releases) page. Please note that this project is still in an early experimental state, so expect bugs and missing features.

### TrollStore (iOS 14 - 16)

For the best experience, I'd recommend sideloading Reynard via [TrollStore](https://github.com/opa334/TrollStore) using the `Reynard-TrollStore.tipa` build. This gives you automatic JIT enablement, better performance, and automatic app updates.

> [!NOTE]
> - For automatic app updates, make sure that the **URL Scheme Enabled** option is turned on in TrollStore.
> - The TrollStore build does not work correctly on **iOS 17.0**. Users on this version should use alternative sideloading methods.

### AltStore or SideStore (iOS 17+)

You should use [AltStore](https://altstore.io/) or [SideStore](https://sidestore.io/) to sideload the `Reynard.ipa` build when TrollStore is not available, especially on newer iOS versions. Please note that you must select the **Keep App Extensions** option during installation, as Reynard relies on its extensions to function and will not work without them. 

You can also [click here](https://stikstore.app/altdirect/?url=https://github.com/minh-ton/reynard-browser/releases/download/0.0.1-a1/source.json&exclude=livecontainer,stikstore,trollapps,feather) to add the AltSource for Reynard to AltStore or SideStore.

> [!IMPORTANT]
> - **LiveContainer is not supported** due to its own limitations.
> - Sideloading methods that use a distribution certificate for signing are **not supported**.⁠
> - Other sideloading methods are **untested**, and **no support will be provided** for issues arising from them.

After sideloading, enable JIT by following the guide below. 

<details>
  <summary><b>Manually enabling JIT on Reynard Browser</b></summary>

### Why Enable JIT?

Modern websites run a lot of JavaScript, and that code needs to be fast. Instead of repeatedly reading JavaScript line by line, every browser speeds things up by using JIT to turn frequently used code into machine code that the computer runs directly. This helps complex websites feel smooth instead of slow or laggy.

Although Reynard can work without JIT, performance will be noticeably slower and some websites may not function correctly.

### Setting Up

Due to Apple’s restrictions, only Safari is allowed to use JIT by default. To enable JIT in Reynard, we’ll need a few extra steps: a loopback VPN, a pairing file from your computer, and a quick toggle in Reynard’s settings.

#### Step 1: Download LocalDevVPN

1. Download the [LocalDevVPN](https://apps.apple.com/us/app/localdevvpn/id6755608044) app from the App Store on your device.
2. Open the app and press **Connect**.
3. The first time you connect, an alert will ask whether you want to add a VPN configuration. Tap **Allow**.
<p>
  <img height="400" src="https://github.com/user-attachments/assets/d10f46e2-d340-4c6d-9ce0-d481b434b071" />
  <img height="400" src="https://github.com/user-attachments/assets/96732a8f-dde8-442e-83c0-fd0f195fa4f7" />
</p>

#### Step 2: Create a Pairing File

1. On your computer, download the `iloader` tool: https://iloader.app/
2. Connect your iPhone or iPad to your computer using a USB cable.
3. In iloader, select your device from the list, then click **Manage Pairing File**.
<p>
  <img width="350" src="https://github.com/user-attachments/assets/7e674d76-66af-4587-9461-65596b266c63" />
  <img width="350" src="https://github.com/user-attachments/assets/69147ab2-636b-4279-9215-dd19f38e9bdd" />
</p>

4. Click **Export** to save the file. Then transfer the created `pairingFile.plist` to your device, e.g. via AirDrop.
<p><img width="400" src="https://github.com/user-attachments/assets/faaf8ec5-6644-4e2e-9094-751c4f422b4f" /></p>

#### Step 3: Enabling JIT in Reynard

1. On your device, open Reynard and go to **Settings** by tapping the three-dot menu (on iPhone) or opening the sidebar (on iPad).
2. Tap **Import Pairing File** and select the `pairingFile.plist` you transferred in the previous step.
<p>
  <img height="400" src="https://github.com/user-attachments/assets/39cd3871-5d90-46a8-8129-938889481843" />
  <img height="400" src="https://github.com/user-attachments/assets/200d1a7b-ecf8-4f8d-92bd-37c266265b9c" />
</p>

3. Toggle the **Enable JIT** switch. The first time you do this, the app will download the Developer Disk Image files needed for JIT. Once the download finishes, restart the browser for changes to take effect.
<p>
  <img height="400" src="https://github.com/user-attachments/assets/75e6deeb-c31d-4734-b783-ce7723bf5f04" />
  <img height="400" src="https://github.com/user-attachments/assets/03e1d93e-ecb8-4064-b19a-591357972ac3" />
</p>

### Important Notice

You must be connected to **Wi-Fi** and have **LocalDevVPN turned on** whenever you want to use the browser with JIT.

If either is missing when you launch Reynard, or disconnects while you’re browsing, the app will prompt you to activate **JIT-Less Mode**. This lets you keep browsing without JIT until the next time you relaunch the app.

<p>
  <img height="400" src="https://github.com/user-attachments/assets/97e5994b-0d7f-44b0-97ca-52e1211bc9e5" />
  <img height="400" src="https://github.com/user-attachments/assets/3a257141-28af-4ad9-a7d5-70dabbe22c74" />
</p>

</details>

### Jailbroken (iOS 12 - 13)

Sideload the `Reynard-Jailbroken.ipa` build using [Filza File Manager](https://www.tigisoftware.com/default/?page_id=78) with [AppSync Unified](https://github.com/akemin-dayo/AppSync) on a **jailbroken device**. You will also benefit from automatic JIT enablement and better performance.

## Preview

### iOS 14 (iPhone 6S Plus, 14.1)

These sites are known to break or render incorrectly on iOS 14. The screenshots below compare how they load in Safari versus Reynard.

<table>
  <tr>
    <th colspan="2">github.com</th>
    <th colspan="2">chatgpt.com</th>
    <th colspan="2">apple.com</th>
  </tr>
  <tr>
    <td align="center">Safari</td>
    <td align="center">Reynard</td>
    <td align="center">Safari</td>
    <td align="center">Reynard</td>
    <td align="center">Safari</td>
    <td align="center">Reynard</td>
  </tr>
  <tr>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/d89f4385-c478-4aea-aa9d-6c9fca72252b"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/917ee435-39cb-469d-835f-8e69f9e13d03"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/1a68024e-83d4-489c-a576-26d5ea43011c"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/6880b1ac-63f9-421f-a373-5d69c5745cd7"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/d237118e-be3b-43d1-b14c-032784b43571"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/9f799569-d712-44d0-918a-21d523874c6e"><br>
    </td>
  </tr>
</table>

### iOS 15 (iPhone 7, 15.8.6)

<table>
  <tr>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/a7f1b302-51b6-4afe-a2ce-35b518e5b761"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/f5dbfba5-c1a8-4729-bd7d-b96a7ace1237"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/986c8cfb-7979-4f4b-9305-73ebd1a87b19"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/544ff493-6807-4b2f-b526-6d34f029e1d3"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/31ef9486-8631-4d0e-ad9a-1281d513151f"><br>
    </td>
  </tr>
</table>

### iOS 26 (iPhone 13 mini, 26.1)

Reynard also works great on the latest version of iOS!

<table>
  <tr>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/974e8ce1-f798-4bef-bac1-621ee535c5ee"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/1429c985-f439-4e58-9385-0eefef4add4c"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/a9eeaf68-828f-4ead-b619-8b9914e0ed2c"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/bbc08422-4bf3-4928-933e-71cdad551fed"><br>
    </td>
    <td>
      <img width=150 src="https://github.com/user-attachments/assets/cf01d298-a8d2-49ea-a557-7b1bbd1d893a"><br>
    </td>
  </tr>
</table>

## Building

> [!WARNING]
> Build instructions are included below for reference. Please be aware that I **do not** provide support for issues or errors encountered during the build process.

To build the project, you'll need Xcode, [Python 3](https://www.python.org/downloads/), [Rust and Cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html), and [ldid](https://formulae.brew.sh/formula/ldid).

Clone the repository.

```bash
git clone --recursive https://github.com/minh-ton/reynard-browser
cd reynard-browser
```

Download Gecko and apply patches.

```bash
./tools/development/update-gecko.sh
./tools/development/apply-patches.sh
```

Build dependencies and the Gecko engine.

```bash
./tools/development/build-idevice.sh
./tools/development/build-gecko.sh
```

To run Reynard, open `Reynard.xcodeproj` in Xcode and build/run it from there.

## Notes

This project initially started out of curiosity. I wanted to see if I could get Gecko to run without the [BrowserEngineKit](https://developer.apple.com/documentation/browserenginekit) framework, so it could be further modified to run on iOS versions as far back as possible. I got it working, and since then, I’ve been focusing on developing engine patches for better UIKit integration, fixing bugs, and turning this into a full, usable browser.

If you’ve come across this repository and find it interesting, I’d love to get help or collaborate on it. I’m learning as I go here and don’t have much prior experience with iOS app development or with Gecko itself, so any contributions, feedback, or pointers would be greatly appreciated.

## Acknowledgements
- [LiveContainer](https://github.com/LiveContainer/LiveContainer): app extension handling and NSExtension usage.
- [StikDebug](https://github.com/StephenDev0/StikDebug) and [idevice](https://github.com/jkcoxson/idevice): pairing-based JIT enablement support.
- [TrollStore](https://github.com/opa334/TrollStore): spawning a binary as root and JIT enablement.
- [Amethyst-iOS](https://github.com/AngelAuraMC/Amethyst-iOS) and [dolphin-ios](https://github.com/OatmealDome/dolphin-ios): Various utility functions, numerous private API usage, and memory mapping stuff.
- [Pre-existing work](https://bugzilla.mozilla.org/show_bug.cgi?id=1882872) on bringing Gecko to iOS using BrowserEngineKit: most of the difficult engine integration. 

## License

This project is licensed under the [GNU General Public License v3.0](https://github.com/minh-ton/reynard-browser/blob/main/LICENSE), except for the `patches` directory containing the modifications to the Firefox Gecko engine and therefore is licensed under the [Mozilla Public License 2.0](https://github.com/minh-ton/reynard-browser/blob/main/LICENSE.firefox).
