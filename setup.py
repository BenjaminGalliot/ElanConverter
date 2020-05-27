#!/usr/bin/env python3

from distutils.core import setup

setup(name='ElanConverter',
      version='0.1',
      description='Converter from Pangloss XML to Elan format',
      author='Benjamin Galliot',
      author_email='b.g01lyon@gmail.com',
      url='',
      packages=['elanconverter'],
      classifiers = [
          'Development Status :: 4 - Beta',
          'Intended Audience :: Developers',
          'Programming Language :: Python',
          'Programming Language :: Python :: 3.7',
          'Programming Language :: Python :: 3.8',
      ],
      install_requires=[
           'pathlib',
      ]
     )
