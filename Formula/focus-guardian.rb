class FocusGuardian < Formula
  desc "Multi-browser distraction blocker & deep work engine for macOS"
  homepage "https://github.com/ShireenAzadSyed/focus-guardian"
  version "1.0.2"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/ShireenAzadSyed/homebrew-focus-guardian/releases/download/v1.0.2/focus-guardian-v1.0.2-arm64.tar.gz"
    sha256 "71730464ef11dfe62adb5a8af1bcab6ee222612921b6e0610d86111d7448fccb"
  end

  head "https://github.com/ShireenAzadSyed/focus-guardian.git", branch: "main"

  def install
    # Install binary package or source files into libexec
    libexec.install Dir["*"]

    # Symlink or create the CLI in bin
    if (libexec/"bin/focus-guardian").exist?
      bin.install_symlink libexec/"bin/focus-guardian"
    else
      # Fallback wrapper when building from source head
      (bin/"focus-guardian").write <<~EOS
        #!/bin/bash
        cd "#{libexec}"
        case "$1" in
          status)
            exec ./scripts/status.sh
            ;;
          reload)
            exec ./scripts/reload.sh
            ;;
          start)
            exec ./scripts/start.sh
            ;;
          install-root)
            exec sudo ./scripts/install-root-daemon.sh
            ;;
          stop|uninstall)
            exec ./scripts/uninstall.sh
            ;;
          *)
            echo "Usage: focus-guardian {status|reload|start|install-root|stop|uninstall}"
            ;;
        esac
      EOS
      chmod 0755, bin/"focus-guardian"
    end
  end

  service do
    if File.exist?("#{opt_libexec}/bin/focus-guardian-engine")
      run [opt_libexec/"bin/focus-guardian-engine"]
    else
      run ["/usr/bin/python3", opt_libexec/"daemon/guardian.py"]
    end
    keep_alive true
    run_type :immediate
    working_dir opt_libexec
    log_path var/"log/focus-guardian.log"
    error_log_path var/"log/focus-guardian.log"
  end

  def caveats
    <<~EOS
      🛡️ Focus Guardian installed successfully!

      To start the 24/7 background service:
        brew services start focus-guardian

      To check status:
        focus-guardian status

      To lock as an anti-tamper root daemon (cannot be quit in Activity Monitor):
        focus-guardian install-root

      To attempt stopping or uninstalling (triggers anti-tamper friction shield):
        focus-guardian stop
    EOS
  end

  test do
    system "#{bin}/focus-guardian", "status"
  end
end
