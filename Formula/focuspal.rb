class Focuspal < Formula
  desc "Multi-browser distraction blocker & deep work companion for macOS"
  homepage "https://github.com/focuspal-sh/focuspal"
  version "1.0.6"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/focuspal-sh/homebrew-tap/releases/download/v1.0.6/focuspal-v1.0.6-arm64.tar.gz"
    sha256 "d42dc3f1a60ffa7c98c42b0a86b2e0626f887abc8e1e7657f8c30e24133cf93f"
  end

  head "https://github.com/ShireenAzadSyed/focus-guardian.git", branch: "main"

  def install
    # Install all files into libexec
    libexec.install Dir["*"]

    # Symlink or create the CLI wrapper in bin
    if (libexec/"bin/focuspal").exist?
      bin.install_symlink libexec/"bin/focuspal"
    else
      (bin/"focuspal").write <<~EOS
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
            echo "Usage: focuspal {status|start|test|reload|permissions|install|install-root|stop}"
            ;;
        esac
      EOS
      chmod 0755, bin/"focuspal"
    end

    # Backward compatibility aliases
    bin.install_symlink bin/"focuspal" => "lockin"
    bin.install_symlink bin/"focuspal" => "focus-guardian"
  end

  # Called automatically by `brew upgrade focuspal` or `brew install focuspal`
  def post_install
    system_command "brew", args: ["services", "start", "focuspal"],
                   print_stderr: false
    ohai "Focus Pal service registered & started with launchd."
  rescue => e
    begin
      reload_trigger = Pathname.new(Dir.home)/".focuspal/config/reload.trigger"
      reload_trigger.parent.mkpath
      reload_trigger.write("")
      ohai "Focus Pal hot-reload triggered — new version active."
    rescue => e2
      opoo "Could not trigger reload: #{e2.message}"
    end
  end

  service do
    if File.exist?("#{opt_libexec}/bin/focuspal-engine")
      run [opt_libexec/"bin/focuspal-engine"]
    elsif File.exist?("#{opt_libexec}/bin/lockin-engine")
      run [opt_libexec/"bin/lockin-engine"]
    elsif File.exist?("#{opt_libexec}/bin/focus-guardian-engine")
      run [opt_libexec/"bin/focus-guardian-engine"]
    else
      run [which("python3") || "/usr/bin/python3", opt_libexec/"daemon/guardian.py"]
    end
    keep_alive true
    run_type :immediate
    working_dir opt_libexec
    log_path var/"log/focuspal.log"
    error_log_path var/"log/focuspal.log"
    environment_variables FOCUSPAL_BREW: "1"
  end

  def caveats
    <<~EOS
      🤝 Focus Pal installed successfully!

      Recommended Next Step (24/7 Tamper-Proof Protection):
        focuspal install-root

      To verify & request macOS Automation permissions:
        focuspal permissions

      To check status:
        focuspal status

      To reload after a config change:
        focuspal reload

      To attempt stopping (triggers commitment pledge):
        focuspal stop
    EOS
  end

  test do
    system "#{bin}/focuspal", "status"
  end
end

