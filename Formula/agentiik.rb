# The server programs of Agentiik beside the command line: the API, the controller and the runner.
#
# The API and the controller are the control plane, and a host running them needs PostgreSQL and
# a NATS server with JetStream. The service runs a server on this Mac alone: nats-server, the API
# and the controller under one wrapper, agentiik-server, since Homebrew gives a formula one service
# and the three are one installation. nats-server is a dependency because the service runs it;
# PostgreSQL is not, because the service does not run it and whichever PostgreSQL answers on /tmp
# will do. agentiik-setup prepares everything once, and the settings are files in etc/agentiik,
# which Homebrew keeps across upgrades. The scripts and the settings are in server/ in this tap.
#
# Built from the tagged source, as agk is, so that go build stamps the version from the tag.
class Agentiik < Formula
  desc "Server programs: API, controller and runner, with the agk command-line tool"
  homepage "https://agentiik.github.io/docs"
  url "https://github.com/agentiik/agentiik.git",
      tag:      "v0.2.2",
      revision: "d3a58fe5b0ebca23c389821de54fc17bdcb11e6b"
  license "AGPL-3.0-or-later"
  head "https://github.com/agentiik/agentiik.git", branch: "main"

  depends_on "go" => :build
  depends_on "agentiik/tap/agk"
  depends_on "nats-server"

  def install
    programs = %w[agentiik-api agentiik-controller agk-runner].select { |p| (buildpath/"cmd"/p).directory? }
    odie "this source holds none of the server programs" if programs.empty?
    programs.each do |program|
      system "go", "build", *std_go_args(output: bin/program, ldflags: "-s -w"), "./cmd/#{program}"
    end

    # Copied out of the tap rather than installed from it, since install moves what it is given.
    server = tap.path/"server"
    %w[agentiik-server agentiik-setup].each do |script|
      (buildpath/script).write (server/script).read.gsub("@HOMEBREW_PREFIX@", HOMEBREW_PREFIX.to_s)
      bin.install buildpath/script
    end
    %w[api.env controller.env nats-server.conf].each do |file|
      (buildpath/file).write (server/file).read.gsub("@HOMEBREW_PREFIX@", HOMEBREW_PREFIX.to_s)
    end
    # etc keeps a file somebody changed, and writes the new one beside it as name.default.
    (etc/"agentiik").install "api.env", "controller.env", "nats-server.conf"
  end

  def caveats
    <<~EOS
      To run a server on this Mac, once:
        brew install postgresql@17
        brew services start postgresql@17
        agentiik-setup
        brew services start agentiik/tap/agentiik
      agentiik-setup prints the operator token once, and the two lines that point agk at the server.
      Settings: #{etc}/agentiik (https://agentiik.github.io/docs/#configuration)
      Logs:     #{var}/log/agentiik

      A runner is a Linux host: https://agentiik.github.io/docs/#installing-a-runner
    EOS
  end

  service do
    run opt_bin/"agentiik-server"
    environment_variables PATH: std_service_path_env
    keep_alive successful_exit: false
    log_path var/"log/agentiik/server.log"
    error_log_path var/"log/agentiik/server.log"
  end

  test do
    assert_match "agentiik-setup remove", shell_output("#{bin}/agentiik-setup --help")
    assert_match "AGK_MASTER_KEY_FILE", (etc/"agentiik/api.env").read
    refute_match(/^AGK_MASTER_KEY_FILE/, (etc/"agentiik/controller.env").read)

    %w[agentiik-api agentiik-controller agk-runner].each do |program|
      next unless (bin/program).exist?

      # Every program refuses to start with no configuration, naming what is missing.
      verb = (program == "agentiik-controller") ? "" : " serve"
      output = shell_output("#{bin}/#{program}#{verb} 2>&1", 1)
      assert_match "AGK_", output
    end
  end
end
