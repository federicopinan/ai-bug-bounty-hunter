# Continuous integration

Workflows run on pushes and pull requests targeting `master`.
They check Markdown, shell, JSON, YAML, local links, and skill metadata.

## Action runtimes

Checkout v6, setup-python v6, and markdownlint-cli2-action v25.0.0 declare
`runs.using: node24`. This is the action runtime, not the dashboard's Node
support policy. GitHub-hosted `ubuntu-latest` runners provide the runtime;
self-hosted runners must satisfy each action's documented minimum version.

Verified provider metadata:

- [Checkout v6](https://github.com/actions/checkout/blob/v6/action.yml)
- [Setup Python v6](https://github.com/actions/setup-python/blob/v6/action.yml)
- [Markdownlint v25.0.0](https://github.com/DavidAnson/markdownlint-cli2-action/blob/v25.0.0/action.yml)

## Link checks

The link job remains offline: it does not visit example bounty targets.
`--exclude-path` omits source documents/directories; `--exclude` matches URLs.
The excluded vendored documents and templates contain upstream-relative links
and placeholder links that are not local project navigation. These exclusions
preserve the existing intended scope rather than suppressing project link errors.

Lychee exit code 2 indicates a failed link check, not the Node runtime warning.
The workflow prints `lychee/out.md` even after a failure, when that file exists.
It does not use `continue-on-error` or disable link checking. Inspect the failing
step and its report for exact broken links before adding exclusions.

For the reported baseline run, public metadata confirms YAML and link failures,
but the exact lychee report requires the run's logs. Ten broken upstream-relative
references were found statically in vendored `.agents/skills/*/README.md` files;
they are candidates, not a proven attribution of that historical failure.

## Local checks

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools/tests -v
yamllint -d '{extends: default, rules: {line-length: disable, document-start: disable, truthy: disable}}' docker-compose.yml .github/workflows/*.yml
python3 tools/validate-skills.py .claude/skills/
```

The Python tests need no added packages. `yamllint` is a separate prerequisite.
Static workflow regressions do not replace running the actual actions, lychee,
or dashboard builds. Never claim the remote run passed before it actually ran.
