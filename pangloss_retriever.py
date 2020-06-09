import argparse
from pathlib import Path
import urllib.request
import re
import xml.etree.ElementTree


parser = argparse.ArgumentParser()
parser.add_argument("language", type=str, help="ISO 639-3 language code (3 letters).")
parser.add_argument("--target", type=str, default="downloaded data", help="""Target folder the data will be stored in. (Default: "downloaded data")""")
parser.add_argument("--non-ecologic", type=bool, nargs="?", const=True, default=False, help="Download a file even if it exists already (with same name), do it only if you know that the data were updated! (Default: False)")
parser.add_argument("--limit", type=int, default=None, help="Limit the data downloaded, interesting if you just plan to test! (Default: no limit)")


def retrieve_files(arguments):
    data = get_data_from_pangloss(arguments.language)
    files = get_files_from_data(data)
    download_files(files, arguments.target, not arguments.non_ecologic, arguments.limit)

def get_data_from_pangloss(language):
    query = f"""
    PREFIX edm: <http://www.europeana.eu/schemas/edm/>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREFIX ebucore: <http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#>
    SELECT DISTINCT ?audioFile ?textFile ?lg ?cho WHERE {{
        ?aggr edm:aggregatedCHO  ?cho .
        ?cho a edm:ProvidedCHO.
        ?cho dc:subject ?lg FILTER regex(str(?lg), "^http://lexvo.org/id/iso639-3/{language}$")
        ?cho dc:subject ?lg FILTER regex(str(?audioFile), "\\\\.version\\\\d+$")
        ?cho edm:isGatheredInto <http://cocoon.huma-num.fr/pub/COLLECTION_cocoon-af3bd0fd-2b33-3b0b-a6f1-49a7fc551eb1> .
        ?aggr edm:hasView ?transcript .
        ?transcript  dcterms:conformsTo <http://cocoon.huma-num.fr/pub/CHO_cocoon-49aefa90-8c1f-3ba8-a099-0ebefc6a2aa7> .
        ?transcript foaf:primaryTopic ?textFile .
        ?aggr edm:hasView ?recording .
        ?recording foaf:primaryTopic ?audioFile .
    }}
    """.replace("\n", "")
    link = f"""https://cocoon.huma-num.fr/sparql?default-graph-uri=&query={urllib.parse.quote(query)}&format=application%2Fsparql-results%2Bxml&timeout=0&debug=on&log_debug_info=on"""
    with urllib.request.urlopen(link) as response:
        xml_data = response.read()
    root = xml.etree.ElementTree.fromstring(xml_data)
    return root

def get_files_from_data(root):
    namespaces = {"results": re.match(r"{(?P<namespace>.+)}", root.tag).group("namespace")}
    audio_nodes = root.findall("*/results:result/results:binding[@name='audioFile']/results:uri", namespaces)
    text_nodes = root.findall("*/results:result/results:binding[@name='textFile']/results:uri", namespaces)
    audio_files = [audio_node.text for audio_node in audio_nodes]
    text_files = [text_node.text for text_node in text_nodes]
    assert len(audio_files) == len(text_files)
    files = {Path(text_file).stem: {"text": text_file, "audio": audio_file} for text_file, audio_file in zip(text_files, audio_files)}
    return files

def download_files(files, target_folder, ecologic=True, limit=None):
    target_folder = Path(target_folder)
    target_folder.mkdir(exist_ok=True)
    size = len(files)
    for index, (name, files) in enumerate(files.items(), 1):
        print(f"Data {index}/{size}: {name}:")
        download_file(files["text"], (target_folder / name).with_suffix(".xml"), ecologic)
        download_file(files["audio"], (target_folder / name).with_suffix(".wav"), ecologic)
        if limit and index == limit:
            break

def download_file(link, path, ecologic):
    if ecologic and path.exists():
        print(f"\t{path.name} already downloaded!")
    else:
        with urllib.request.urlopen(link) as response:
            raw_data = response.read()
        with open(path, "wb") as file:
            file.write(raw_data)


if __name__ == "__main__":
    arguments = parser.parse_args()
    print(f"Arguments: {arguments}")
    retrieve_files(arguments)
