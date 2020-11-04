from setuptools import setup, find_packages
setup(
    name='namespace/cachito-sample-pip-package',
    version='1.0.0',
    install_requires=['requests'],
    packages=find_packages(),
)
