import os
import re

def path_as_module_path(path):
    if re.search(r"^(app|spec|lib/tasks|test|web)\/", path):
        return re.sub(r"^([a-z-]+\/){2}", "", path)
    else:
        return re.sub(r"^([a-z-]+\/){1}", "", path)

def path_without_extension(path):
    split_path = path.split(".")
    del split_path[-1]
    return ".".join(split_path)

def path_as_module_name(path, separator):
    path = path.title()
    path = re.sub("_", "", path)
    return re.sub("/", separator, path)
