class Lockin < Formula
  desc "Multi-browser distraction blocker & deep work engine for macOS"
  homepage "https://github.com/lockin-sh/lockin"
  version "1.0.6"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/lockin-sh/homebrew-tap/releases/download/v1.0.6/lockin-v1.0.6-arm64.tar.gz"
    sha256 "190cbc37316d3c71ada2340729672d7c6d1d5713410d3de4e4dce2af102283ed"
  end

  head "https://github.com/ShireenAzadSyed/focus-guardian.git", branch: "main"

  def install
    # Install all files into libexec
    libexec.install Dir["*"]

    # Symlink or create the CLI wrapper in bin
    if (libexec/"bin/lockin").exist?
      bin.install_symlink libexec/"bin/lockin"
    else
      (bin/"lockin").write <<~EOS
        #!/bin/bash
        cd "#{libexec}"
        case "$1" in
          status)  exec ./scripts/status.sh ;;
          reload)  exec ./scripts/reload.sh ;;
          start)   shift; exec ./scripts/start.sh "$@" ;;
          test)    exec ./scripts/start.sh --foreground ;;
          install-root) exec sudo ./scripts/install-root-daemon.sh ;;
          stop|uninstall) exec ./scripts/uninstall.sh ;;
          *)
            echo "Usage: lockin {status|start|test|reload|install-root|stop}"
            ;;
        esac
      EOS
      chmod 0755, bin/"lockin"
    end

    # Backward compatibility alias
    bin.install_symlink bin/"lockin" => "focus-guardian"
  end

  # Called automatically by `brew upgrade lockin`
  def post_install
    system_command "brew", args: ["services", "restart", "lockin"],
                   print_stderr: false
    ohai "Lockin service restarted — new version active immediately."
  rescue => e
    begin
      reload_trigger = Pathname.new(Dir.home)/".lockin/config/reload.trigger"
      reload_trigger.parent.mkpath
      reload_trigger.write("")
      ohai "Lockin hot-reload triggered — new version active."
    rescue => e2
      opoo "Could not trigger reload: #{e2.message}"
    end
  end

  service do
    if File.exist?("#{opt_libexec}/bin/lockin-engine")
      run [opt_libexec/"bin/lockin-engine"]
    elsif File.exist?("#{opt_libexec}/bin/focus-guardian-engine")
      run [opt_libexec/"bin/focus-guardian-engine"]
    else
      run [which("python3") || "/usr/bin/python3", opt_libexec/"daemon/guardian.py"]
    end
    keep_alive true
    run_type :immediate
    working_dir opt_libexec
    log_path var/"log/lockin.log"
    error_log_path var/"log/lockin.log"
    environment_variables LOCKIN_BREW: "1"
  end

  def caveats
    <<~EOS
      🔒 Lockin installed successfully!

      To start the 24/7 background service:
        brew services start lockin

      To check status:
        lockin status

      To reload after a config change:
        lockin reload

      To lock as an anti-tamper root daemon (cannot be quit in Activity Monitor):
        lockin install-root

      To attempt stopping (triggers anti-tamper friction shield):
        lockin stop
    EOS
  end

  test do
    system "#{bin}/lockin", "status"
  end
end

