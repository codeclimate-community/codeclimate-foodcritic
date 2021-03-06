Code Climate Engine to run [Foodcritic][]

[foodcritic]: http://www.foodcritic.io/

## Usage

**.codeclimate.yml**

```yml
engines:
  foodcritic:
    enabled: true
```

## Configuration

This engine accepts `tags`, `cookbook_paths` and `include_rules` in its
configuration. All values are optional:

```yml
engines:
  foodcritic:
    enabled: true
    config:
      tags:
      - "~FC011"
      - "~FC033"
      cookbook_paths:
      - libraries/mysql.rb
      - libraries/docker.rb
      include_rules:
      - rules/my_custom_rule.rb
      - rules/my_other_custom_rule.rb
```

**NOTE**: `cookbook_paths`, when defined, are passed directly to Foodcritic and
any computed `include_paths` (which take into account your configured
`exclude_paths`) are ignored.
