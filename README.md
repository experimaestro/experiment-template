# experiment-template

This contains the template code for setting up an experiment with [experimaestro].



## Setting up the environment

1. Clone the repository
2. **Re-run when pulling** Within the project directory, run `uv sync` to install all the needed packages. This will also create a `.venv`
3. **Run just once after having cloned** `uv run pre-commit install` (if you want to ensure consistent formatting and code checking)


### Experimaestro configuration

You should setup [some workspace](https://experimaestro-python.readthedocs.io/en/latest/settings/) that specifies where the output of the experiments are located

When running on a SLURM cluster, you might also need to create a `launchers.py` file as documented [here](https://experimaestro-python.readthedocs.io/en/latest/launchers/)

Finally, you can read the [experimaestro tutorial](https://experimaestro-python.readthedocs.io/en/latest/tutorial/)


## Experiments

To run the experiment, use
```sh
uv run experimaestro run-experiment my_project/normal
```
