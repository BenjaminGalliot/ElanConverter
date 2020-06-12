import re
import yaml
from pathlib import Path
from pprint import pprint

def configure(identifier, source_format, target_format, input_path=None, output_path=None):
    general_data = get_general_data()
    source_data = get_source_data()
    style_path = get_conversion_file(general_data, source_format, target_format)
    input_path = Path(input_path if input_path else general_data["paths"]["source"])
    output_path = Path(output_path if output_path else general_data["paths"]["conversion"])
    errors = []
    if not input_path.exists():
        errors.append(f"""The path "{input_path}" does not exist!""")
    for format in [source_format, target_format]:
        if format not in general_data["formats"]:
            errors.append(f"""The "{format}" format is unknown!""")
    if not style_path.exists():
        errors.append(f"""The {source_format} to {target_format} conversion is not implemented yet!""")
    if identifier not in source_data:
        errors.append(f"""The "{identifier} identifier is unknown (please see "data.yml" file)!""")
    if not errors:
        configuration = {
        "input path": input_path,
        "output path": output_path,
        "input extensions": general_data["formats"][source_format]["source extensions"],
        "output extension": general_data["formats"][target_format]["target extension"],
        "style path": style_path,
        "xsl version": general_data["xsl version"],
        "data": source_data[identifier]}
        print("Configuration:")
        pprint(configuration)
        return configuration
    else:
        raise Exception("""Errors occurred during configuration:\n%s""" % "\n".join(errors))

def get_conversion_file(general_data, source_format, target_format):
    basename = general_data["conversions"]["template"].replace("source", source_format).replace("target", target_format)
    path = (general_data["paths"]["templates"] / basename).with_suffix(".xsl")
    return path

def get_general_data(source_file="configuration.yml"):
    with open(source_file) as file:
        configuration = yaml.load(file, Loader=yaml.FullLoader)
    for name, path in configuration["paths"].items():
        configuration["paths"][name] = Path(path)
    return configuration

def get_source_data(source_file="data.yml"):
    with open(source_file) as file:
        data = yaml.load(file, Loader=yaml.FullLoader)
    return data
