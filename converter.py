import argparse
# import multiprocessing
from pathlib import Path
import re
import subprocess
from sys import platform
import configurer

parser = argparse.ArgumentParser()
parser.add_argument("data", type=str, help="""Source data identifier (from "data.yml" file).""")
parser.add_argument("--source-format", type=str, default="pangloss", help="The source format. (Default: pangloss)")
parser.add_argument("--target-format", type=str, default="elan", help="The target format. (Default: elan)")
parser.add_argument("--inpath", type=str, help="""Pangloss XML path for file (or folder of files) to convert. (Default: see "configuration.yml" file)""")
parser.add_argument("--outpath", type=str, help="""Result folder for converted files. (Default: see "configuration.yml" file)""")

def convert(configuration):
    if configuration["input path"].is_dir:
        input_file_paths = [file for extension in configuration["input extensions"] for file in configuration["input path"].rglob(f"*.{extension}")]
    else:
        input_file_paths = [configuration["input path"]]
    if input_file_paths:
        configuration["output path"].mkdir(exist_ok=True)
        for input_file_path in input_file_paths:
            output_file_path = configuration["output path"] / input_file_path.with_suffix(f""".{configuration["output extension"]}""").name
            xsl_convert(input_file_path, output_file_path, configuration["style path"], configuration["data"], configuration["xsl version"])
            # multiprocessing.Process(target=xsl_convert, args=(input_file_path, output_file_path, configuration["style path"], configuration["data"], configuration["xsl version"]))
    else:
        print(f"""There is no files with {configuration["input extensions"]} extensions in {configuration["input path"]}, please verify your data!""")

def xsl_convert(input_path, output_path, style_path, data, xsl_version="2"):
    if "options" in data and data["options"].get("audio pathname case normalization", False):
        data["audio path"] = input_path.with_suffix(".wav").name
    parameters = " ".join([f'%s="{value}"' % re.sub(r"\s", "_", key) for key, value in data.items() if isinstance(value, str)])
    if platform in ["linux", "linux2"]:
        xslt_command = "saxonb-xslt"
    elif platform == "darwin":
        xslt_command = "saxon"
    if xsl_version == "2":
        command = f"{xslt_command} -s:'{input_path}' -xsl:'{style_path}' -o:'{output_path}' {parameters}"
    else:
        print("Please get an XSLT 2 compiler, like saxonb.")
    print(f"""XSLT command (in "{str(output_path.parent)}" folder):\n{command}""")
    stream = subprocess.run(command, shell=True)

if __name__ == "__main__":
    arguments = parser.parse_args()
    configuration = configurer.configure(arguments.data, arguments.source_format, arguments.target_format, arguments.inpath, arguments.outpath)
    convert(configuration)
