# The server programs of Agentiik beside the command line: the API, the controller and, on Linux, the runner.
#
# A runner is a Linux host, since it measures the host from /proc, which macOS does not have, so
# agk-runner is built on Linux alone: on a Mac it could only refuse to join.
#
# The API and the controller are the control plane, and a host running them needs PostgreSQL and
# a NATS server with JetStream. The service runs a server on this Mac alone: nats-server, the API
# and the controller under one wrapper, agentiik-server, since Homebrew gives a formula one service
# and the three are one installation. nats-server is a dependency because the service runs it;
# PostgreSQL is not, because the service does not run it and whichever PostgreSQL answers on /tmp
# will do. agentiik-setup prepares everything once, the service runs agentiik-api migrate at every
# start, so that brew upgrade and a restart are the whole of an upgrade, and the settings are files
# in etc/agentiik, which Homebrew keeps across upgrades. The scripts and the settings are in server/
# in this tap.
#
# Built from the tagged source, as agk is, so that go build stamps the version from the tag. The API
# serves the web console from its own binary, which embeds the console's build, so the console is built
# first, with Node, which is needed for the build alone, as Go is.
class Agentiik < Formula
  desc "Server programs: API, controller and, on Linux, runner, with the agk command-line tool"
  homepage "https://agentiik.github.io/docs"
  url "https://github.com/agentiik/agentiik.git",
      tag:      "v0.5.0",
      revision: "b5496bc4b160ddd9898e3561c3fd097d14238bf4"
  license "AGPL-3.0-or-later"
  head "https://github.com/agentiik/agentiik.git", branch: "main"

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "agentiik/tap/agk"
  depends_on "nats-server"

  def install
    programs = %w[agentiik-api agentiik-controller]
    programs << "agk-runner" if OS.linux?
    programs.select! { |p| (buildpath/"cmd"/p).directory? }
    odie "this source holds none of the server programs" if programs.empty?

    # The console, where the source holds one, from v0.6.0: built into console/dist before agentiik-api,
    # which embeds what it finds there, and named with the version the programs record, which a build of
    # the smallest of them reads, as the engine's release names the console of its images.
    if (buildpath/"console/package.json").exist?
      probe = buildpath/"version-probe"
      system "go", "build", "-o", probe, "./cmd/agk-helper"
      recorded = Utils.safe_popen_read("go", "version", "-m", probe)[/^\s*mod\s+\S+\s+(\S+)/, 1]
      odie "agk-helper records no version" if recorded.nil?
      cd "console" do
        system "npm", "ci"
        with_env(AGK_VERSION: recorded.delete_prefix("v")) do
          system "npm", "run", "build"
        end
      end
      odie "the console's build wrote no console/dist/index.html" unless (buildpath/"console/dist/index.html").exist?
    end
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
      agentiik-setup prints the two lines that point agk at the server, the second with the bootstrap
      token, whose one lasting use is creating the first administrator, with a login no namespace has
      (https://agentiik.github.io/docs/#first-run):
        agk user create LOGIN --admin
      A server set up before is upgraded by brew services restart agentiik/tap/agentiik, which migrates.
      Settings: #{etc}/agentiik (https://agentiik.github.io/docs/#configuration)
      Logs:     #{var}/log/agentiik

      A runner is a Linux host, so agk-runner is installed on Linux alone:
      https://agentiik.github.io/docs/#installing-a-runner
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
    # The bootstrap token is operator-token.env's, which migrate alone is given: serve refuses it.
    refute_match(/^AGK_OPERATOR_TOKEN=/, (etc/"agentiik/api.env").read)

    # The API serves the console from its own binary, from the release that has one.
    if version.head? || version >= Version.new("0.6.0")
      assert_match '<div id="console">', File.binread(bin/"agentiik-api")
    end

    %w[agentiik-api agentiik-controller agk-runner].each do |program|
      next unless (bin/program).exist?

      # Every program refuses to start with no configuration, naming what is missing.
      verb = (program == "agentiik-controller") ? "" : " serve"
      output = shell_output("#{bin}/#{program}#{verb} 2>&1", 1)
      assert_match "AGK_", output
    end
  end
end
