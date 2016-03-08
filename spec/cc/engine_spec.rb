require "spec_helper"

module CC
  describe Engine do
    describe ".each_issue" do
      it "yields foodcritic issues in .rb files" do
        Dir.chdir("spec/fixtures") do
          checks = []

          capture_io do
            Engine.each_issue do |issue|
              json = JSON.parse(issue.to_json)
              checks << json["check_name"]
            end
          end

          expect(checks).to eq [
            "FoodCritic/FC005",
            "FoodCritic/FC031",
            "FoodCritic/FC045",
          ]
        end
      end
    end

    describe Engine::Config do
      describe "#cookbook_paths" do
        it "can be explicity specified via config" do
          Tempfile.open("config.json") do |tmp|
            tmp.write(%{ {"config":{"cookbook_paths":["foo","bar"]}} })
            tmp.rewind

            config = Engine::Config.new(tmp.path)

            expect(config.cookbook_paths).to eq %w[foo bar]
          end
        end

        it "expands and filters include_paths into .rb files" do
          within_temp_directory do
            create_file("README.md")
            create_file("foo.rb")
            create_file("bar.rb")
            create_file("foo/bar.rb")
            create_file("foo/baz.py")
            create_file("baz.hs")

            Tempfile.open("config.json") do |tmp|
              tmp.write(%{ {"include_paths":["README.md","foo.rb","foo/","baz.hs"]} })
              tmp.rewind

              config = Engine::Config.new(tmp.path)

              expect(config.cookbook_paths).to eq %w[foo.rb foo/bar.rb]
            end
          end
        end
      end

      describe "#tags" do
        it "has a sane default" do
          config = Engine::Config.new
          expect(config.tags).not_to be_empty
        end

        it "allows overrides via config" do
          Tempfile.open("config.json") do |tmp|
            tmp.write(%{ {"config":{"tags":["foo","bar"]}} })
            tmp.rewind

            config = Engine::Config.new(tmp.path)

            expect(config.tags).to eq %w[foo bar]
          end
        end
      end
    end

    describe Engine::Rules do
      it "has sane defaults" do
        rules = Engine::Rules.new

        expect(rules.summary("code")).not_to be_nil
        expect(rules.categories("code")).not_to be_empty
        expect(rules.remediation_points("code")).not_to be_zero
      end

      it "reads rule definitions from a rules file" do
        Tempfile.open("rules.yml") do |tmp|
          tmp.write(<<-EOM)
            F01:
              summary: "f-01 summary"
              categories:
              - cat1
              - cat2
              remediation_points: 10
            F02:
              summary: "f-02 summary"
              categories:
              - cat3
              - cat4
              remediation_points: 20
          EOM
          tmp.rewind

          rules = Engine::Rules.new(tmp.path)

          expect(rules.summary("F01")).to eq "f-01 summary"
          expect(rules.summary("F02")).to eq "f-02 summary"
          expect(rules.categories("F01")).to eq %w[cat1 cat2]
          expect(rules.categories("F02")).to eq %w[cat3 cat4]
          expect(rules.remediation_points("F01")).to eq 10
          expect(rules.remediation_points("F02")).to eq 20
        end
      end
    end

    describe Engine::Issue do
      it "converts a FoodCritic::Lint to an Issue" do
        rule = double(code: "F01", name: "Some check")
        lint = double(rule: rule, match: { filename: "foo.rb", line: 42 })
        issue = Engine::Issue.new(lint, Engine::Rules.new)
        json = JSON.parse(issue.to_json)

        expect(json["type"]).to eq "issue"
        expect(json["check_name"]).to eq "FoodCritic/F01"
        expect(json["description"]).to eq "Some check"
        expect(json["categories"]).to eq ["Style"]
        expect(json["location"]["path"]).to eq "foo.rb"
        expect(json["location"]["lines"]["begin"]).to eq 42
        expect(json["location"]["lines"]["end"]).to eq 42
        expect(json["content"]["body"]).not_to be_nil
        expect(json["remediation_points"]).to eq 50_000
      end
    end

    def capture_io
      $stdout = StringIO.new
      $stderr = StringIO.new

      yield

      [$stdout, $stderr].map(&:string)
    ensure
      $stdout = STDOUT
      $stderr = STDERR
    end

    def within_temp_directory(&block)
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp, &block)
      end
    end

    def create_file(path, content = "")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end
  end
end
