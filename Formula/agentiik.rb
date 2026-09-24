# The server programs of Agentiik beside the command line: the API, the controller and the runner.
#
# The API and the controller are the control plane, and a host running them needs PostgreSQL and
# a NATS server with JetStream, which this formula does not pull in: they are as often on another
# machine as on this one. The caveats say how to get both locally.
#
# The server programs are not in a tagged release yet, so until v0.2.0 is tagged this formula
# builds from main only (`brew install --HEAD`), and a stable url is added with the tag.
class Agentiik < Formula
  desc "Server programs: API, controller and runner, with the agk command-line tool"
  homepage "https://agentiik.github.io/docs"
  license "AGPL-3.0-or-later"
  head "https://github.com/agentiik/agentiik.git", branch: "main"

  depends_on "go" => :build
  depends_on "agentiik/tap/agk"

  def install
    programs = %w[agentiik-api agentiik-controller agk-runner].select { |p| (buildpath/"cmd"/p).directory? }
    odie "this source holds none of the server programs" if programs.empty?
    programs.each do |program|
      system "go", "build", *std_go_args(output: bin/program, ldflags: "-s -w"), "./cmd/#{program}"
    end
  end

  def caveats
    <<~EOS
      Each program reads its configuration from AGK_* environment variables, and every secret
      from a file an AGK_*_FILE variable names: https://agentiik.github.io/docs/#configuration

      For a single host, PostgreSQL and NATS with JetStream:
        brew install postgresql@17 nats-server
        brew services start postgresql@17
        nats-server -js

      agk-runner runs containers on a Docker daemon and is meant for a Linux host; on macOS it
      runs only with require_userns_remap = false in its runner.toml.
    EOS
  end

  test do
    %w[agentiik-api agentiik-controller agk-runner].each do |program|
      next unless (bin/program).exist?

      # Every program refuses to start with no configuration, naming what is missing.
      verb = (program == "agentiik-controller") ? "" : " serve"
      output = shell_output("#{bin}/#{program}#{verb} 2>&1", 1)
      assert_match "AGK_", output
    end
  end
end
