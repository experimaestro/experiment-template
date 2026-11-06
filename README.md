# experiment-template

[Copier](https://copier.readthedocs.io) template for
[experimaestro](https://experimaestro-python.readthedocs.io) experiments: an
installable package in `src/`, experiments with their YAML specifications in
`experiments/`, and the uv, ruff, pre-commit and Conventional Commits tooling.

> Use `copier copy` rather than GitHub's "Use this template" button, which
> would copy the unrendered template.

```bash
uvx copier copy gh:experimaestro/experiment-template my-experiment
cd my-experiment
git init && uv sync && uv run pre-commit install
```

## Questions

As well as the project name, the Python package name, the author and the license,
Copier asks for:

| Question | Effect |
|---|---|
| `releases` | Off (default): a plain version in `__init__.py`. On: the version comes from git tags (hatch-vcs), with a git-cliff `cliff.toml` |
| `flavor` | `basic` (experimaestro only), `torch` (adds PyTorch, xpm-torch and a `pre_experiment.py` that mocks heavy modules when planning) or `ir` (adds experimaestro-ir and datamaestro on top of `torch`) |
| `torch_index` | The PyTorch wheels to use on Linux (`torch` and `ir` only) |
| `carbon` | Tracks the energy use and carbon emissions of the jobs |
| `mlboard` | The monitoring services to set up: `tensorboard`, `tables`, `wandb` |
| `experiment_name` | The first experiment, in `experiments/<experiment_name>/` |
| `specifications` | One YAML file per name in this folder (by default `debug` and `full`) |

`xpm-torch` always installs TensorBoard, so the `torch` and `ir` flavors get it
even when `tensorboard` isn't selected; the option then only controls whether the
service is set up in `run.py`.

## Updating a generated project

```bash
uvx copier update
```

The project must be a git repository with a clean working tree. `copier update`
only changes the tooling: `experiments/`, `src/<package_name>/tasks.py`,
`docs/experiments.md` and `README.md` are left as they are.

## Checking the template

[`scripts/check-template.sh`](scripts/check-template.sh) generates a project and
then checks it: linting, tests, a real run of every specification with
experimaestro, and `copier update`. The CI runs it for several combinations of
answers.

```bash
scripts/check-template.sh basic
scripts/check-template.sh torch --mlboard '[tensorboard, tables]' --carbon --releases
```
