packer {
  required_plugins {
    tart = {
      version = ">= 1.2.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "macos_version" {
  type = string
}

variable "xcode_version" {
  type = string
}

variable "android_sdk_tools_version" {
  type    = string
  default = "11076708" # https://developer.android.com/studio/#command-tools
}

source "tart-cli" "tart" {
  vm_base_name = "${var.macos_version}-base"
  vm_name      = "${var.macos_version}-xcode:${var.xcode_version}"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 90
  headless     = true
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew --version",
      "brew update",
      "brew upgrade",
      "brew install curl wget unzip zip ca-certificates"
//      "sudo softwareupdate --install-rosetta --agree-to-license"
    ]
  }

  // Re-install the GitHub Actions runner
  provisioner "shell" {
    script = "scripts/install-actions-runner.sh"
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install homebrew/cask-versions/temurin17",
      "brew install rustup-init",
      "rustup-init -y",
      "source ~/.cargo/env",
      "cargo install sccache typeshare-cli"
    ]
  }

  provisioner "file" {
    source      = "/Volumes/QuickMac/Downloads/Xcode_15.2.xip" // pathexpand("~/Downloads/Xcode_${var.xcode_version}.xip")
    destination = "/Users/admin/Downloads/Xcode_${var.xcode_version}.xip"
  }

  provisioner "shell" {
    inline = [
      "echo 'export PATH=/usr/local/bin/:$PATH' >> ~/.zprofile",
      "source ~/.zprofile",
      "brew install xcodesorg/made/xcodes",
      "xcodes version",
      "xcodes install ${var.xcode_version} --experimental-unxip --path /Users/admin/Downloads/Xcode_${var.xcode_version}.xip --select --empty-trash",
      "xcodebuild -downloadPlatform iOS",
      // "xcodebuild -downloadAllPlatforms",
      "xcodebuild -runFirstLaunch",
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install libimobiledevice ideviceinstaller ios-deploy fastlane carthage",
      "sudo gem update",
      "sudo gem install cocoapods",
      "sudo gem uninstall --ignore-dependencies ffi && sudo gem install ffi -- --enable-libffi-alloc"
    ]
  }

  # useful utils for mobile development
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install graphicsmagick imagemagick",
      "brew install wix/brew/applesimutils"
    ]
  }

  # inspired by https://github.com/actions/runner-images/blob/fb3b6fd69957772c1596848e2daaec69eabca1bb/images/macos/provision/configuration/configure-machine.sh#L33-L61
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "sudo security delete-certificate -Z FF6797793A3CD798DC5B2ABEF56F73EDC9F83A64 /Library/Keychains/System.keychain",
      "curl -o add-certificate.swift https://raw.githubusercontent.com/actions/runner-images/fb3b6fd69957772c1596848e2daaec69eabca1bb/images/macos/provision/configuration/add-certificate.swift",
      "swiftc add-certificate.swift",
      "sudo mkdir -p /usr/local/bin",
      "sudo mv ./add-certificate /usr/local/bin/add-certificate",
      "curl -o AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer",
      "curl -o DeveloperIDG2CA.cer https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer",
      "sudo add-certificate AppleWWDRCAG3.cer",
      "sudo add-certificate DeveloperIDG2CA.cer",
      "rm add-certificate* *.cer"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
    ]
  }
}
