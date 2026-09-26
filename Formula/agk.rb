# The agk command line alone: validate, graph, run a workflow locally, test a brick.
#
# Built from the tagged source rather than downloaded as a binary, so that what a person runs is
# what the tag names and nothing a release job could have swapped. It is cloned at the tag rather
# than fetched as an archive because go build stamps the version from the tag, and agk --version
# then names the release instead of (devel). The static helper a script step
# mounts at /agk/bin/agk is built first, for both architectures a container runs on, and embedded,
# so `agk run --local` gives script steps their helper with no extra download.
class Agk < Formula
  desc "Command-line tool for Agentiik workflows: validate, graph and run them locally"
  homepage "https://agentiik.github.io/docs"
  url "https://github.com/agentiik/agentiik.git",
      tag:      "v0.2.0",
      revision: "6ede6bc7674730750d3d0a1fc9dd4228a3d78976"
  license "AGPL-3.0-or-later"
  head "https://github.com/agentiik/agentiik.git", branch: "main"

  depends_on "go" => :build

  def install
    %w[amd64 arm64].each do |arch|
      with_env(CGO_ENABLED: "0", GOOS: "linux", GOARCH: arch) do
        system "go", "build", "-trimpath", "-o", "cmd/agk/internal/helper/bin/agk-linux-#{arch}", "./cmd/agk-helper"
      end
    end
    system "go", "build", *std_go_args(output: bin/"agk", ldflags: "-s -w"), "./cmd/agk"
  end

  def caveats
    <<~EOS
      agk run --local runs containers on the Docker daemon of this machine, so it needs one:
      Docker Desktop, Colima or OrbStack. Docker Desktop does not remap user namespaces, which
      agk says once when it runs.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/agk --version")
    (testpath/"agentiik.yaml").write <<~YAML
      apiVersion: agentiik.dev/v1
      kind: Workflow
      metadata:
        name: hello
      steps:
        greet:
          image: alpine:3.21
          outputs: [out]
          script:
            - echo hello
    YAML
    assert_match "step_greet", shell_output("#{bin}/agk graph --format mermaid")
  end
end
