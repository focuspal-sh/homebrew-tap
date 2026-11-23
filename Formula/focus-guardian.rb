class FocusGuardian < Formula
  desc "Multi-browser distraction blocker & deep work engine for macOS"
  homepage "https://github.com/ShireenAzadSyed/focus-guardian"
  version "1.0.6"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/ShireenAzadSyed/homebrew-focus-guardian/releases/download/v1.0.6/focuspal-v1.0.6-arm64.tar.gz"
    sha256 "2e9129f0c728804a80ea1f24b672b7b15efaef80b6f8be246d63e5b9d09049f1"
  end

  head "https://github.com/ShireenAzadSyed/focus-guardian.git", branch: "main"

  def install
    # Install all files into libexec
    libexec.install Dir["*"]

    # Symlink or create the CLI wrapper in bin
    if (libexec/"bin/focus-guardian").exist?
      bin.install_symlink libexec/"bin/focus-guardian"
    else
      (bin/"focus-guardian").write <<~EOS
        #!/bin/bash
        cd "#{libexec}"
        case "$1" in
          status)  exec ./scripts/status.sh ;;
          permissions|perms|check) shift; exec ./scripts/verify-permissions.sh "$@" ;;
          install) exec ./scripts/install.sh ;;
          reload)  exec ./scripts/reload.sh ;;
          start)   shift; exec ./scripts/start.sh "$@" ;;
          test)    exec ./scripts/start.sh --foreground ;;
          install-root) exec sudo ./scripts/install-root-daemon.sh ;;
          stop|uninstall) exec ./scripts/uninstall.sh ;;
          *)
            echo "Usage: focus-guardian {status|start|test|reload|permissions|install|install-root|stop}"
            ;;
        esac
      EOS
      chmod 0755, bin/"focus-guardian"
    end
  end

  # Called automatically by `brew upgrade focus-guardian`
  def post_install
    # Restart the brew service so it picks up the new binary/code immediately
    # This covers both hot-reload (trigger file) and full process restart via launchd
    system_command "brew", args: ["services", "restart", "focus-guardian"],
                   print_stderr: false
    ohai "Focus Guardian service restarted — new version active immediately."
  rescue => e
    # Fallback: write reload trigger file for in-process hot-reload
    begin
      reload_trigger = Pathname.new(Dir.home)/".focus-guardian/config/reload.trigger"
      reload_trigger.parent.mkpath
      reload_trigger.write("")
      ohai "Focus Guardian hot-reload triggered — new version active."
    rescue => e2
      opoo "Could not trigger reload: #{e2.message}"
    end
  end

  service do
    if File.exist?("#{opt_libexec}/bin/focus-guardian-engine")
      run [opt_libexec/"bin/focus-guardian-engine"]
    else
      run [which("python3") || "/usr/bin/python3", opt_libexec/"daemon/guardian.py"]
    end
    keep_alive true
    run_type :immediate
    working_dir opt_libexec
    log_path var/"log/focus-guardian.log"
    error_log_path var/"log/focus-guardian.log"
    # Trigger a hot-reload on service start/restart so daemon always boots fresh
    environment_variables FOCUS_GUARDIAN_BREW: "1"
  end

  def caveats
    <<~EOS
      🛡️ Focus Guardian installed successfully!

      To start the 24/7 background service:
        brew services start focus-guardian

      To check status:
        focus-guardian status

      To reload after a config change:
        focus-guardian reload

      To lock as an anti-tamper root daemon (cannot be quit in Activity Monitor):
        focus-guardian install-root

      To attempt stopping (triggers anti-tamper friction shield):
        focus-guardian stop
    EOS
  end

  test do
    system "#{bin}/focus-guardian", "status"
  end
end
