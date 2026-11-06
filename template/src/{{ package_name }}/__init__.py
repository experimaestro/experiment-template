try:
    from ._version import __version__
except ImportError:  # not installed (no version file generated)
    __version__ = "0.0.0"
