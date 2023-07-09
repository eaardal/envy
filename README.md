# Envy

Environment variables management script.

## How it works

Uses a yaml file to store groups of environment variables. The script acts as a CLI for interacting with the yaml file.

### How to get started

1. Put the `envy` bash script in this repo in a directory that's included in your PATH.
2. Add `export ENVY_DIR=your/path/to/envy/dir` to your .bashrc, .zshrc or similar.
3. Either put the `bin` directory with `jq` and `yq` in this repo as a sub-directory to wherever you placed the `envy` script, or set `ENVY_JQ` and `ENVY_YQ` to your own versions of those programs.

See [Configuration options](#configuration-options) for further (optional) setup.

Then start using it by running one of the commands listed below.

See [How to use](#how-to-use) for more info.

### Commands

| Command                                       | Description                                                                                                                                                              |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `source envy export <env>`                    | Export the given environment variables. Remember to source the statement for the changes to stick.                                                                       |
| `source envy unexport <env>`                  | Unset the given environment variables. Remember to source the statement for the changes to stick.                                                                        |
| `envy ls` or `envy list`                      | List available environments names. These can be used in commands with <env> as a parameter.                                                                              |
| `envy show <env> [<key>]`                     | Print environment variables in the given environment (won't set them). Specify the optional <key> argument to only print the value of one specific environment variable. |
| `envy set <env> <key> <value>`                | Set the environment value key and value at the given path in the yaml. Path can be dot-separated.                                                                        |
| `envy yaml` or `envy yaml --raw`              | Print the entire Envy yaml file containing all environment variables.                                                                                                    |
| `envy verify <env>`                           | Verifies that each environment variable key found in Envy for the given <env> is set in the current shell and that the shell's values matches the ones in Envy.          |
| `envy export-dotenv <env> <out-file-path>`    | Export environment variables to the given file path in a dotenv (.env) format: `key=value`.                                                                              |
| `envy export-bash <env> <out-file-path>`      | Export environment variables to the given file path in a bash (.sh) format: `export key=value`.                                                                          |
| `envy import-dotenv <dotenv-file-path> <env>` | Import a .env file and save all environment variables into envy.yaml.                                                                                                    |
| `envy import-bash`                            | Import a .sh file with `export key=value` lines and save all environemnt variables into envy.yaml.                                                                       |

## Configuration options

Set these environment variables to override defaults.

| Variable          | Description                                                                 | Defaults to                                                      |
| ----------------- | --------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `ENVY_DIR`        | Path to the directory where the `envy.yaml` (or `$ENVY_FILE`) is located    | [Required] You must set this in your .zshrc, .bashrc or similar. |
| `ENVY_JQ`         | Path to the `jq` executable to use.                                         | `$ENVY_DIR/bin/jq`                                               |
| `ENVY_YQ`         | Path to the `yq` executable to use.                                         | `$ENVY_DIR/bin/yq`                                               |
| `ENVY_FILE`       | Name of the yaml file containing environment variables                      | `envy.yaml`                                                      |
| `ENVY_YAML`       | Full path to the yaml file containing environment variables                 | `$ENVY_DIR/$ENVY_FILE`                                           |
| `ENVY_TEMP_DIR`   | Path to the temp dir where temporary files will be stored for some commands | `$ENVY_DIR/tmp`                                                  |
| `ENVY_BACKUP_DIR` | Path to the backup dir where old versions of `envy.yaml` will be stored     | `$ENVY_DIR/backup`                                               |

## How to use

If `envy.yaml` (the yaml file where all your environment variables are stored) doesn't exist, running any command or just invoking the `envy` script will create an empty yaml file. If you want to create it manually, it needs this at the very minimum:

```yaml
names:
```

and here is something more to get started with:

```yaml
names:
  - hello.demo
hello:
  demo:
    FOO: bar
    BAR: foo
```

Inspect available environment variable keys:

```
$ envy ls

- hello.demo
```

Show environment variables for a key:

```
$ envy show hello.demo

FOO: bar
BAR: foo
```

Check if environment variables are active:

```
$ envy verify hello.demo

MISSING: FOO is not an active environment variable
MISSING: BAR is not an active environment variable
```

Set environment variables in your shell:

```
$ source envy export hello.demo

hello.demo environment variables exported

$ echo $FOO

bar

$ echo $BAR

foo
```

Verify that environment variables are now active:

```
$ envy verify hello.demo

OK: FOO matches Envy value bar
OK: BAR matches Envy value foo
```

> Use `.` instead of `source` for shorthand notation.

### More details

#### `jq` and `yq`

Envy requires `jq` and `yq` under the hood. The default versions are bundled in the `bin` folder. They can be overridden using the configuration options listed above.

#### Keeping the `names` list in sync

The list of `names` must contain all paths of keys found in the file that you want to use.

Example:

If you have this in your yaml file:

```yaml
names:
  - hello.demo
hello:
  demo:
    FOO: bar
    BAR: foo
other:
  envs:
    SOMETHING: else
```

You won't see or be able to use `other.envs` with the `envy` commands because the key does not exist in the list of `names`. It should be:

```yaml
names:
  - hello.demo
  - other.envs
```

Using envy's commands such as `envy set`, `envy import-dotenv` or `envy import-bash` will update `names` accordingly. If you modify the yaml file manually, you'll have to keep `names` in sync yourself.

# YAML tips

## Re-use sections with references

- Use `&variable-name` to name something.
- Use `*variable-name` to reference something.
- Combine several references by using a list:

```yaml
something:
  <<:
    - *first-var
    - *second-var
```

Full references example:

```yaml
projects:
  myapp:
    defaults: &myapp-defaults
      HOST_NAME: &myapp-host http://foo.com
      LOG_LEVEL: info
      LOG_FORMAT: json
    dev:
      <<: *myapp-defaults
    test:
      <<:
        - *myapp-defaults
      LOG_LEVEL: error
    prod:
      <<:
        - *myapp-defaults
      BASE_URL: *myapp-host
```

Produces the computed yaml:

```yaml
projects:
  myapp:
    defaults:
      HOST_NAME: http://foo.com
      LOG_LEVEL: info
      LOG_FORMAT: json
    dev:
      HOST_NAME: http://foo.com
      LOG_LEVEL: info
      LOG_FORMAT: json
    test:
      HOST_NAME: http://foo.com
      LOG_FORMAT: json
      LOG_LEVEL: error
    prod:
      HOST_NAME: http://foo.com
      LOG_LEVEL: info
      LOG_FORMAT: json
      BASE_URL: http://foo.com
```
