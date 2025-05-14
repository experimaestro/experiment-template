from experimaestro.experiments import ConfigurationBase, ExperimentHelper, configuration


@configuration
class Configuration(ConfigurationBase):
    my_param: int
    """An experimental parameter"""


def run(xp: ExperimentHelper, cfg: Configuration):
    # Setup your experimental plan here
    pass
