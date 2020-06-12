import argparse
import os
from pathlib import Path
from sys import platform

parser = argparse.ArgumentParser()
parser.add_argument("infile", help="Pangloss XML file to convert.")


def xsl_convert(input_path, output_path, style_path, data={}, xsl_version="2"):
    template_folder = Path("templates")
    style_path = template_folder / style_path
    parameters = " ".join([f'{key}="{value}"' for key, value in data.items()])
    if platform == "linux" or platform == "linux2":
        if xsl_version == "2":
            command = f"saxonb-xslt -s:{input_path} -xsl:{style_path} -o:{output_path} {parameters}"
        else:
            command = f"xsltproc -o {output_path} {style_path} {input_path}"
    elif platform == "darwin":
        command = f"saxon -s:{input_path} -xsl:{style_path} -o:{output_path} {parameters}"
    print(command)
    stream = os.popen(command)

if __name__ == "__main__":
    args = parser.parse_args()

    input_file = Path(args.infile)
    output_file = Path(input_file.stem + ".eaf")
    style_path = "pangloss_to_elan.xsl"

    xsl_convert(input_file,
                output_file,
                style_path,
                {"author": "Alexis Michaud",
                "version": "2.7",
                "participant": "F4",
                "source_language_code": "nru",
                "translation_language_codes": "fr, zh"})