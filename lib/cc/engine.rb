require "foodcritic"
require "json"
require "yaml"

module CC
  module Engine
    def self.each_issue
      rules = Rules.new

      get_warnings.each do |lint|
        yield Issue.new(lint, rules)
      end
    end

    def self.get_warnings
      config = Config.new
      options = {
        cookbook_paths: config.cookbook_paths,
        progress: false,
        tags: config.tags,
      }

      $stderr.puts "foodcritic options: #{options.inspect}"
      linter = FoodCritic::Linter.new
      linter.check(options).warnings
    end

    class Config
      DEFAULT_INCLUDE_PATHS = ["./"]
      DEFAULT_TAGS = ["~FC011", "~FC033"]

      def initialize(path = "/config.json")
        if File.exists?(path)
          @config = JSON.parse(File.read(path))
        else
          @config = {}
        end
      end

      def cookbook_paths
        engine_config.fetch("cookbook_paths") { expand_include_paths }
      end

      def tags
        engine_config.fetch("tags", DEFAULT_TAGS)
      end

      private

      attr_reader :config

      def engine_config
        config.fetch("config", {})
      end

      def expand_include_paths
        include_paths = config.fetch("include_paths", DEFAULT_INCLUDE_PATHS)
        include_paths.flat_map do |path|
          if path.end_with?("/")
            Dir.glob("#{path}**/*.rb")
          elsif path.end_with?(".rb")
            [path]
          else
            []
          end
        end
      end
    end

    class Rules
      def initialize(path = "/rules.yml")
        if File.exists?(path)
          @config = YAML.load_file(path)
        else
          @config = {}
        end
      end

      def summary(code)
        @config.fetch(code, {}).fetch("summary", "")
      end

      def categories(code)
        @config.fetch(code, {}).fetch("categories", ["Style"])
      end

      def remediation_points(code)
        @config.fetch(code, {}).fetch("remediation_points", 50_000)
      end
    end

    class Issue
      def initialize(lint, rules)
        @lint = lint
        @rules = rules
      end

      def filename
        lint.match[:filename]
      end

      def to_json
        {
          "type" => "issue",
          "check_name" => "FoodCritic/#{lint.rule.code}",
          "description" => lint.rule.name,
          "categories" => rules.categories(lint.rule.code),
          "location" => {
            "path" => filename,
            "lines" => {
              "begin" => lint.match[:line],
              "end" => lint.match[:line],
            }
          },
          "content" => { "body" => rules.summary(lint.rule.code) },
          "remediation_points" => rules.remediation_points(lint.rule.code),
        }.to_json
      end

      private

      attr_reader :lint, :rules
    end
  end
end
